#include <array>
#include <cctype>
#include <cerrno>
#include <cstring>
#include <cstdint>
#include <cstdlib>
#include <deque>
#include <iomanip>
#include <iostream>
#include <fstream>
#include <cstdio>
#include <optional>
#include <stdexcept>
#include <string>
#include <unordered_map>
#include <vector>

#include <fcntl.h>
#include <termios.h>
#include <unistd.h>

#include <glibmm/main.h>
#include <gtkmm/main.h>

#include "Vdioptase.h"
#include "Vdioptase___024root.h"
#include "verilated.h"

#include "extern/vgasim/bench/cpp/vgasim.h"

namespace {

std::optional<uint8_t> lookup_ps2_scancode(char ch) {
    static const std::unordered_map<char, uint8_t> table = {
        {'a', 0x1C}, {'b', 0x32}, {'c', 0x21}, {'d', 0x23}, {'e', 0x24},
        {'f', 0x2B}, {'g', 0x34}, {'h', 0x33}, {'i', 0x43}, {'j', 0x3B},
        {'k', 0x42}, {'l', 0x4B}, {'m', 0x3A}, {'n', 0x31}, {'o', 0x44},
        {'p', 0x4D}, {'q', 0x15}, {'r', 0x2D}, {'s', 0x1B}, {'t', 0x2C},
        {'u', 0x3C}, {'v', 0x2A}, {'w', 0x1D}, {'x', 0x22}, {'y', 0x35},
        {'z', 0x1A}, {'1', 0x16}, {'2', 0x1E}, {'3', 0x26}, {'4', 0x25},
        {'5', 0x2E}, {'6', 0x36}, {'7', 0x3D}, {'8', 0x3E}, {'9', 0x46},
        {'0', 0x45}, {'-', 0x4E}, {'=', 0x55}, {'`', 0x0E}, {'[', 0x54},
        {']', 0x5B}, {'\\', 0x5D}, {';', 0x4C}, {'\'', 0x52}, {',', 0x41},
        {'.', 0x49}, {'/', 0x4A}, {' ', 0x29}, {'\n', 0x5A}, {'\t', 0x0D},
        {'\b', 0x66}
    };

    if (ch == '\r') {
        ch = '\n';
    }
    if (ch == '\t') {
        ch = '\n';
        return table.at('\n');
    }
    if (ch == '\b' || ch == 0x7F) {
        ch = '\b';
    }
    if (std::isalpha(static_cast<unsigned char>(ch))) {
        ch = static_cast<char>(std::tolower(static_cast<unsigned char>(ch)));
    }
    auto it = table.find(ch);
    if (it == table.end()) {
        return std::nullopt;
    }
    return it->second;
}

struct Options {
    bool use_vga = false;
    bool max_cycles_overridden = false;
    uint64_t max_cycles = 500;
    bool keyboard_via_uart = false;
};

std::string trim_whitespace(const std::string &s) {
    std::size_t start = 0;
    while (start < s.size() && std::isspace(static_cast<unsigned char>(s[start])) != 0) {
        ++start;
    }
    std::size_t end = s.size();
    while (end > start && std::isspace(static_cast<unsigned char>(s[end - 1])) != 0) {
        --end;
    }
    return s.substr(start, end - start);
}

// Build artifacts may include '#label ...' metadata at the end of .hex files.
// Verilog $readmemh rejects '#', so sanitize those files for simulation use.
void sanitize_hex_plusarg(std::vector<std::string> &verilator_args) {
    for (std::string &arg : verilator_args) {
        static const std::string hex_prefix = "+hex=";
        if (arg.rfind(hex_prefix, 0) != 0) {
            continue;
        }

        const std::string input_path = arg.substr(hex_prefix.size());
        std::ifstream in(input_path);
        if (!in.is_open()) {
            continue;
        }

        std::vector<std::string> cleaned_lines;
        cleaned_lines.reserve(8192);
        bool needs_sanitize = false;
        std::string line;
        while (std::getline(in, line)) {
            const std::size_t hash_pos = line.find('#');
            if (hash_pos != std::string::npos) {
                line = line.substr(0, hash_pos);
                needs_sanitize = true;
            }
            line = trim_whitespace(line);
            if (!line.empty()) {
                cleaned_lines.push_back(line);
            }
        }

        if (!needs_sanitize) {
            continue;
        }

        char tmp_template[] = "/tmp/dioptase_hex_XXXXXX";
        const int fd = ::mkstemp(tmp_template);
        if (fd < 0) {
            std::cerr << "Failed to create sanitized hex temp file for " << input_path
                      << ": " << std::strerror(errno) << std::endl;
            std::exit(EXIT_FAILURE);
        }
        ::close(fd);

        std::ofstream out(tmp_template, std::ios::out | std::ios::trunc);
        if (!out.is_open()) {
            std::cerr << "Failed to open sanitized hex temp file for " << input_path
                      << ": " << tmp_template << std::endl;
            std::exit(EXIT_FAILURE);
        }
        for (const std::string &clean : cleaned_lines) {
            out << clean << '\n';
        }
        out.close();

        arg = hex_prefix + std::string(tmp_template);
    }
}

class TerminalRawGuard {
public:
    TerminalRawGuard() {
        if (!::isatty(STDIN_FILENO)) {
            return;
        }
        if (::tcgetattr(STDIN_FILENO, &original_term_) != 0) {
            return;
        }

        struct termios raw = original_term_;
        raw.c_lflag &= ~(ICANON | ECHO);
        raw.c_cc[VMIN] = 0;
        raw.c_cc[VTIME] = 0;
        if (::tcsetattr(STDIN_FILENO, TCSANOW, &raw) != 0) {
            return;
        }

        original_flags_ = ::fcntl(STDIN_FILENO, F_GETFL, 0);
        if (original_flags_ >= 0) {
            ::fcntl(STDIN_FILENO, F_SETFL, original_flags_ | O_NONBLOCK);
        }

        active_ = true;
    }

    ~TerminalRawGuard() {
        if (!active_) {
            return;
        }
        ::tcsetattr(STDIN_FILENO, TCSANOW, &original_term_);
        if (original_flags_ >= 0) {
            ::fcntl(STDIN_FILENO, F_SETFL, original_flags_);
        }
    }

    TerminalRawGuard(const TerminalRawGuard &) = delete;
    TerminalRawGuard &operator=(const TerminalRawGuard &) = delete;

    bool active() const { return active_; }

private:
    struct termios original_term_ {};
    int original_flags_ = -1;
    bool active_ = false;
};

class Ps2Transmitter {
public:
    void reset(Vdioptase &top) {
        sending_ = false;
        phase_counter_ = 0;
        idle_ticks_remaining_ = 0;
        clk_high_ = true;
        data_high_ = true;
        top.ps2_clk = 1;
        top.ps2_data = 1;
    }

    void enqueue_sequence(const std::vector<uint8_t> &bytes) {
        for (uint8_t value : bytes) {
            pending_scancodes_.push_back(value);
        }
    }

    void tick(Vdioptase &top) {
        if (!sending_) {
            if (idle_ticks_remaining_ > 0) {
                --idle_ticks_remaining_;
                clk_high_ = true;
                data_high_ = true;
                apply(top);
                return;
            }
            if (!pending_scancodes_.empty()) {
                begin_frame(pending_scancodes_.front());
                pending_scancodes_.pop_front();
            } else {
                clk_high_ = true;
                data_high_ = true;
                apply(top);
                return;
            }
        }

        if (++phase_counter_ >= half_period_ticks_) {
            phase_counter_ = 0;
            clk_high_ = !clk_high_;
            if (clk_high_) {
                ++bit_index_;
                if (bit_index_ >= frame_bits_) {
                    sending_ = false;
                    clk_high_ = true;
                    data_high_ = true;
                    idle_ticks_remaining_ = inter_frame_ticks_;
                } else {
                    data_high_ = current_frame_[bit_index_];
                }
            }
        }

        apply(top);
    }

private:
    void apply(Vdioptase &top) const {
        top.ps2_clk = clk_high_ ? 1 : 0;
        top.ps2_data = data_high_ ? 1 : 0;
    }

    void begin_frame(uint8_t value) {
        current_frame_[0] = 0;
        int ones = 0;
        for (int i = 0; i < 8; ++i) {
            const uint8_t bit = static_cast<uint8_t>((value >> i) & 0x1);
            current_frame_[1 + i] = bit;
            ones += bit;
        }
        current_frame_[9] = (ones % 2 == 0) ? 1 : 0;
        current_frame_[10] = 1;

        bit_index_ = 0;
        phase_counter_ = 0;
        sending_ = true;
        clk_high_ = true;
        data_high_ = current_frame_[0];
    }

    static constexpr int frame_bits_ = 11;
    static constexpr int half_period_ticks_ = 500;
    static constexpr int inter_frame_ticks_ = 5000;

    std::array<uint8_t, frame_bits_> current_frame_ {};
    std::deque<uint8_t> pending_scancodes_;
    int bit_index_ = 0;
    int phase_counter_ = 0;
    bool sending_ = false;
    bool clk_high_ = true;
    bool data_high_ = true;
    int idle_ticks_remaining_ = 0;
};

enum class KeyboardRoute {
    Ps2,
    Uart
};

class UartStimulus {
public:
    UartStimulus() : debug_(std::getenv("UART_DEBUG") != nullptr) {}

    void reset(Vdioptase &top) {
        pending_bytes_.clear();
        sending_ = false;
        bit_index_ = 0;
        ticks_in_bit_ = 0;
        line_state_ = true;
        current_frame_.fill(1);
        top.uart_rx = 1;
    }

    void enqueue_byte(uint8_t value) {
        pending_bytes_.push_back(value);
        if (debug_) {
            std::cerr << "[uart] schedule rx 0x" << std::hex << std::setw(2) << std::setfill('0')
                      << static_cast<int>(value) << std::dec << std::setfill(' ')
                      << " ('" << (std::isprint(value) ? static_cast<char>(value) : '?')
                      << "')" << std::endl;
        }
    }

    void tick(Vdioptase &top) {
        if (!sending_) {
            if (!pending_bytes_.empty()) {
                begin_frame(pending_bytes_.front());
                pending_bytes_.pop_front();
            } else {
                line_state_ = true;
                top.uart_rx = 1;
                return;
            }
        }

        top.uart_rx = line_state_ ? 1 : 0;

        if (++ticks_in_bit_ >= ticks_per_bit_) {
            ticks_in_bit_ = 0;
            ++bit_index_;
            if (bit_index_ >= frame_bits_) {
                sending_ = false;
                bit_index_ = 0;
                line_state_ = true;
                if (debug_) {
                    std::cerr << "[uart] frame complete" << std::endl;
                }
            } else {
                line_state_ = current_frame_[bit_index_] != 0;
            }
        }
    }

private:
    void begin_frame(uint8_t value) {
        current_frame_[0] = 0;
        for (int i = 0; i < 8; ++i) {
            current_frame_[1 + i] = static_cast<uint8_t>((value >> i) & 0x1);
        }
        current_frame_[9] = 1;

        sending_ = true;
        bit_index_ = 0;
        ticks_in_bit_ = 0;
        line_state_ = current_frame_[0] != 0;
    }

    static constexpr int frame_bits_ = 10;
    static constexpr int ticks_per_bit_ = 10416;

    std::array<uint8_t, frame_bits_> current_frame_ {};
    std::deque<uint8_t> pending_bytes_;
    int bit_index_ = 0;
    int ticks_in_bit_ = 0;
    bool sending_ = false;
    bool line_state_ = true;
    bool debug_ = false;
};

class KeyboardInput {
public:
    KeyboardInput(TerminalRawGuard &guard, Ps2Transmitter &ps2, UartStimulus &uart,
                  KeyboardRoute &route)
        : guard_(guard), ps2_(ps2), uart_(uart), route_(route),
          ps2_debug_(std::getenv("PS2_DEBUG") != nullptr),
          uart_debug_(std::getenv("UART_DEBUG") != nullptr) {}

    void poll() {
        if (!guard_.active()) {
            while (std::cin.good() && std::cin.rdbuf()->in_avail() > 0) {
                const char ch = static_cast<char>(std::cin.get());
                if (!std::cin.good()) {
                    break;
                }
                emit_character(ch);
            }
            return;
        }

        char buffer[32];
        while (true) {
            const ssize_t read_bytes = ::read(STDIN_FILENO, buffer, sizeof(buffer));
            if (read_bytes <= 0) {
                if (read_bytes < 0 && errno != EAGAIN && errno != EWOULDBLOCK) {
                    if (!reported_read_error_) {
                        std::perror("read");
                        reported_read_error_ = true;
                    }
                }
                break;
            }

            for (ssize_t idx = 0; idx < read_bytes; ++idx) {
                emit_character(buffer[idx]);
            }
        }
    }

private:
    void emit_character(char ch) {
        if (route_ == KeyboardRoute::Ps2) {
            emit_via_ps2(ch);
        } else {
            emit_via_uart(ch);
        }
    }

    void emit_via_ps2(char ch) {
        const auto sequence = encode_character(ch);
        if (!sequence) {
            if (!warned_unknown_ && ch != '\r' && ch != '\n') {
                if (std::isprint(static_cast<unsigned char>(ch))) {
                    std::cerr << "No PS/2 mapping for character '" << ch << "'." << std::endl;
                } else {
                    std::cerr << "No PS/2 mapping for byte 0x" << std::hex << std::uppercase
                              << static_cast<int>(static_cast<unsigned char>(ch))
                              << std::nouppercase << std::dec << "." << std::endl;
                }
                warned_unknown_ = true;
            }
            return;
        }

        ps2_.enqueue_sequence(*sequence);
        if (ps2_debug_) {
            for (uint8_t value : *sequence) {
                std::cerr << "[ps2] enqueue 0x" << std::hex << std::setw(2) << std::setfill('0')
                          << static_cast<int>(value) << std::dec << std::setfill(' ')
                          << " ('" << ch << "')" << std::endl;
            }
        }
    }

    void emit_via_uart(char ch) {
        unsigned char value = static_cast<unsigned char>(ch);
        if (ch == '\r') {
            value = static_cast<unsigned char>('\n');
        }
        if (value == 0x7F) {
            value = static_cast<unsigned char>('\b');
        }
        uart_.enqueue_byte(value);
        if (uart_debug_) {
            std::cerr << "[uart] enqueue rx 0x" << std::hex << std::setw(2) << std::setfill('0')
                      << static_cast<int>(value) << std::dec << std::setfill(' ')
                      << " ('" << (std::isprint(value) ? static_cast<char>(value) : '?')
                      << "')" << std::endl;
        }
    }

    std::optional<std::vector<uint8_t>> encode_character(char ch) const {
        auto sc = lookup_ps2_scancode(ch);
        if (!sc) {
            return std::nullopt;
        }
        return std::vector<uint8_t>{*sc, 0xF0, *sc};
    }

    TerminalRawGuard &guard_;
    Ps2Transmitter &ps2_;
    UartStimulus &uart_;
    KeyboardRoute &route_;
    bool warned_unknown_ = false;
    bool reported_read_error_ = false;
    bool ps2_debug_ = false;
    bool uart_debug_ = false;

};

class UartConsole {
public:
    UartConsole() : debug_(std::getenv("UART_DEBUG") != nullptr) {}

    void after_posedge(Vdioptase &top) {
        const uint8_t write_ptr = static_cast<uint8_t>(top.rootp->dioptase__DOT__uart__DOT__tx_buf__DOT__write_ptr);

        if (!initialized_) {
            prev_write_ptr_ = write_ptr;
            initialized_ = true;
        } else if (write_ptr != prev_write_ptr_) {
            const char ch = static_cast<char>(top.rootp->dioptase__DOT__uart_tx_data);
            std::cout << ch << std::flush;
            if (debug_) {
                const uint32_t addr = static_cast<uint32_t>(top.rootp->dioptase__DOT__mem__DOT__waddr_buf);
                const uint32_t raw = 0; // broken and idk verilator names top.rootp->dioptase__DOT__store_data;
                const uint8_t wen = static_cast<uint8_t>(top.rootp->dioptase__DOT__mem__DOT__wen_buf);
                const uint16_t ps2_val = top.rootp->dioptase__DOT__ps2__DOT__keyboard_reg;
                std::cerr << "[uart] addr=0x" << std::hex << addr
                          << " wen=0x" << static_cast<int>(wen)
                          << " data=0x" << raw
                          << " ps2=0x" << ps2_val
                          << " byte=0x" << std::setw(2) << std::setfill('0')
                          << static_cast<int>(static_cast<uint8_t>(ch))
                          << std::dec << std::setfill(' ') << " ('" << ch << "')" << std::endl;
            }
        }

        prev_write_ptr_ = write_ptr;
    }

private:
    uint8_t prev_write_ptr_ = 0;
    bool initialized_ = false;
    bool debug_ = false;
};

class SdCardSpiDevice {
public:
    void reset(Vdioptase &top) {
        prev_clk_ = false;
        prev_cs_ = true;
        mode_ = Mode::Command;
        cmd_byte_index_ = 0;
        in_bit_index_ = 0;
        out_bit_index_ = 0;
        current_in_byte_ = 0;
        current_out_byte_ = 0xFF;
        write_bytes_received_ = 0;
        crc_bytes_received_ = 0;
        pending_block_ = 0;
        awaiting_app_cmd_ = false;
        idle_ = true;
        initialized_ = false;
        high_capacity_ = false;
        out_fifo_.clear();
        storage_.clear();
        set_miso(top, true);
    }

    void tick(Vdioptase &top) {
        const bool cs = top.sd_spi_cs != 0;
        const bool clk = top.sd_spi_clk != 0;
        const bool mosi = top.sd_spi_mosi != 0;

        if (cs) {
            if (!prev_cs_) {
                mode_ = Mode::Command;
                cmd_byte_index_ = 0;
                in_bit_index_ = 0;
                out_bit_index_ = 0;
                current_in_byte_ = 0;
                current_out_byte_ = 0xFF;
                out_fifo_.clear();
            }
            set_miso(top, true);
        } else {
            if (prev_cs_) {
                in_bit_index_ = 0;
                cmd_byte_index_ = 0;
                current_in_byte_ = 0;
                out_bit_index_ = 0;
                current_out_byte_ = 0xFF;
                drive_next_bit(top);
            }

            if (prev_clk_ && !clk) {
                drive_next_bit(top);
            }

            if (!prev_clk_ && clk) {
                current_in_byte_ = static_cast<uint8_t>((current_in_byte_ << 1) | (mosi ? 1 : 0));
                ++in_bit_index_;
                if (in_bit_index_ == 8) {
                    handle_received_byte(current_in_byte_);
                    current_in_byte_ = 0;
                    in_bit_index_ = 0;
                }
            }
        }

        prev_clk_ = clk;
        prev_cs_ = cs;
    }

private:
    enum class Mode {
        Command,
        DataToken,
        DataBytes,
        DataCrc,
    };

    static constexpr uint32_t kOcrBase = 0x00FF8000u;

    void set_miso(Vdioptase &top, bool level) {
        top.sd_spi_miso = level ? 1 : 0;
    }

    void drive_next_bit(Vdioptase &top) {
        if (out_bit_index_ == 0) {
            if (!out_fifo_.empty()) {
                current_out_byte_ = out_fifo_.front();
                out_fifo_.pop_front();
            } else {
                current_out_byte_ = 0xFF;
            }
        }

        const int bit_pos = 7 - out_bit_index_;
        const bool level = ((current_out_byte_ >> bit_pos) & 0x1) != 0;
        set_miso(top, level);

        out_bit_index_ = (out_bit_index_ + 1) & 7;
        if (out_bit_index_ == 0 && out_fifo_.empty()) {
            current_out_byte_ = 0xFF;
        }
    }

    void enqueue_byte(uint8_t value) {
        out_fifo_.push_back(value);
    }

    void enqueue_bytes(const uint8_t *data, size_t len) {
        for (size_t i = 0; i < len; ++i) {
            out_fifo_.push_back(data[i]);
        }
    }

    uint8_t status_byte() const {
        return idle_ ? 0x01 : 0x00;
    }

    uint32_t argument() const {
        return (static_cast<uint32_t>(cmd_buffer_[1]) << 24) |
               (static_cast<uint32_t>(cmd_buffer_[2]) << 16) |
               (static_cast<uint32_t>(cmd_buffer_[3]) << 8) |
               static_cast<uint32_t>(cmd_buffer_[4]);
    }

    void process_command() {
        const uint8_t cmd = cmd_buffer_[0] & 0x3F;
        const uint32_t arg = argument();

        if (cmd != 55 && cmd != 41) {
            awaiting_app_cmd_ = false;
        }

        switch (cmd) {
        case 0: // CMD0
            idle_ = true;
            initialized_ = false;
            high_capacity_ = false;
            awaiting_app_cmd_ = false;
            enqueue_byte(0x01);
            break;
        case 8: { // CMD8
            const uint8_t status = status_byte();
            enqueue_byte(status);
            enqueue_byte(cmd_buffer_[1]);
            enqueue_byte(cmd_buffer_[2]);
            enqueue_byte(cmd_buffer_[3]);
            enqueue_byte(cmd_buffer_[4]);
            break;
        }
        case 55: // CMD55
            awaiting_app_cmd_ = true;
            enqueue_byte(status_byte());
            break;
        case 41: // ACMD41
            if (!awaiting_app_cmd_) {
                enqueue_byte(0x05);
            } else {
                awaiting_app_cmd_ = false;
                initialized_ = true;
                idle_ = false;
                high_capacity_ = (arg & (1u << 30)) != 0;
                enqueue_byte(status_byte());
            }
            break;
        case 58: { // CMD58
            const uint8_t status = status_byte();
            uint32_t ocr = kOcrBase;
            if (high_capacity_) {
                ocr |= (1u << 30);
            } else {
                ocr &= ~(1u << 30);
            }
            enqueue_byte(status);
            enqueue_byte(static_cast<uint8_t>((ocr >> 24) & 0xFF));
            enqueue_byte(static_cast<uint8_t>((ocr >> 16) & 0xFF));
            enqueue_byte(static_cast<uint8_t>((ocr >> 8) & 0xFF));
            enqueue_byte(static_cast<uint8_t>(ocr & 0xFF));
            break;
        }
        case 17: { // CMD17
            if (!initialized_) {
                enqueue_byte(0x05);
                break;
            }
            if (!high_capacity_ && (arg & 0x1FF) != 0) {
                enqueue_byte(0x05);
                break;
            }
            const uint32_t block_idx = high_capacity_ ? arg : (arg >> 9);
            auto &block = storage_[block_idx];
            enqueue_byte(0x00);
            enqueue_byte(0xFE);
            enqueue_bytes(block.data(), block.size());
            enqueue_byte(0xFF);
            enqueue_byte(0xFF);
            break;
        }
        case 24: { // CMD24
            if (!initialized_) {
                enqueue_byte(0x05);
                break;
            }
            if (!high_capacity_ && (arg & 0x1FF) != 0) {
                enqueue_byte(0x05);
                break;
            }
            pending_block_ = high_capacity_ ? arg : (arg >> 9);
            write_bytes_received_ = 0;
            crc_bytes_received_ = 0;
            mode_ = Mode::DataToken;
            enqueue_byte(0x00);
            break;
        }
        default:
            enqueue_byte(0x05);
            break;
        }
    }

    void handle_received_byte(uint8_t value) {
        switch (mode_) {
        case Mode::Command:
            if (cmd_byte_index_ == 0 && (value & 0x80) != 0) {
                return;
            }
            cmd_buffer_[cmd_byte_index_++] = value;
            if (cmd_byte_index_ == 6) {
                cmd_byte_index_ = 0;
                process_command();
                if (mode_ != Mode::DataToken && mode_ != Mode::DataBytes && mode_ != Mode::DataCrc) {
                    mode_ = Mode::Command;
                }
            }
            break;
        case Mode::DataToken:
            if (value == 0xFE) {
                mode_ = Mode::DataBytes;
                write_bytes_received_ = 0;
            }
            break;
        case Mode::DataBytes:
            if (write_bytes_received_ < write_buffer_.size()) {
                write_buffer_[write_bytes_received_++] = value;
                if (write_bytes_received_ == write_buffer_.size()) {
                    mode_ = Mode::DataCrc;
                    crc_bytes_received_ = 0;
                }
            }
            break;
        case Mode::DataCrc:
            ++crc_bytes_received_;
            if (crc_bytes_received_ >= 2) {
                storage_[pending_block_] = write_buffer_;
                enqueue_byte(0x05);
                enqueue_byte(0xFF);
                mode_ = Mode::Command;
                cmd_byte_index_ = 0;
            }
            break;
        }
    }

    std::deque<uint8_t> out_fifo_;
    bool prev_clk_ = false;
    bool prev_cs_ = true;
    Mode mode_ = Mode::Command;
    uint8_t cmd_byte_index_ = 0;
    uint8_t in_bit_index_ = 0;
    uint8_t out_bit_index_ = 0;
    uint8_t current_in_byte_ = 0;
    uint8_t current_out_byte_ = 0xFF;
    std::array<uint8_t, 6> cmd_buffer_{};
    std::array<uint8_t, 512> write_buffer_{};
    size_t write_bytes_received_ = 0;
    uint8_t crc_bytes_received_ = 0;
    uint32_t pending_block_ = 0;
    bool awaiting_app_cmd_ = false;
    bool idle_ = true;
    bool initialized_ = false;
    bool high_capacity_ = false;
    std::unordered_map<uint32_t, std::array<uint8_t, 512>> storage_;
};

class SimPeripherals {
public:
    explicit SimPeripherals(bool keyboard_via_uart)
        : keyboard_route_(keyboard_via_uart ? KeyboardRoute::Uart : KeyboardRoute::Ps2),
          keyboard_(guard_, ps2_, uart_input_, keyboard_route_),
          pit_debug_(std::getenv("PIT_DEBUG") != nullptr),
          vblank_debug_(std::getenv("VBLANK_DEBUG") != nullptr),
          uart_debug_(std::getenv("UART_DEBUG") != nullptr),
          ps2_debug_(std::getenv("PS2_DEBUG") != nullptr),
          cdiv_debug_(std::getenv("CDIV_DEBUG") != nullptr) {
        const char *boot = std::getenv("UART_BOOT");
        if (boot != nullptr) {
            while (*boot != '\0') {
                initial_uart_bytes_.push_back(static_cast<uint8_t>(*boot));
                ++boot;
            }
        }
        const char *ps2_boot = std::getenv("PS2_BOOT");
        if (ps2_boot != nullptr) {
            bool warned = false;
            while (*ps2_boot != '\0') {
                const char ch = *ps2_boot++;
                auto sc = lookup_ps2_scancode(ch);
                if (sc) {
                    initial_ps2_scancodes_.push_back(*sc);
                    initial_ps2_scancodes_.push_back(0xF0);
                    initial_ps2_scancodes_.push_back(*sc);
                } else if (!warned) {
                    std::cerr << "No PS/2 mapping for bootstrap character ";
                    if (std::isprint(static_cast<unsigned char>(ch))) {
                        std::cerr << "'" << ch << "'";
                    } else {
                        std::cerr << "0x" << std::hex << std::setw(2) << std::setfill('0')
                                  << static_cast<int>(static_cast<unsigned char>(ch))
                                  << std::dec << std::setfill(' ');
                    }
                    std::cerr << "." << std::endl;
                    warned = true;
                }
            }
        }
    }

    void attach(Vdioptase &top) {
        ps2_.reset(top);
        uart_input_.reset(top);
        sd_card_.reset(top);
        for (uint8_t sc : initial_ps2_scancodes_) {
            ps2_.enqueue_sequence(std::vector<uint8_t>{sc});
        }
        for (uint8_t value : initial_uart_bytes_) {
            uart_input_.enqueue_byte(value);
        }
        if (uart_debug_) {
            prev_rx_count_ = static_cast<uint8_t>(top.rootp->dioptase__DOT__uart__DOT__rx_buf__DOT__count);
        }
    }

    void before_cycle(Vdioptase &top) {
        keyboard_.poll();
        uart_input_.tick(top);
        ps2_.tick(top);
        sd_card_.tick(top);
    }

    void after_posedge(Vdioptase &top) {
        uart_.after_posedge(top);
        sd_card_.tick(top);
        if (uart_debug_) {
            const uint32_t reg_r5_cur = top.rootp->dioptase__DOT__cpu__DOT__decode__DOT__regfile__DOT__regfile[5];
            const uint8_t rx_count = static_cast<uint8_t>(top.rootp->dioptase__DOT__uart__DOT__rx_buf__DOT__count);
            if (rx_count != prev_rx_count_) {
                std::cerr << "[uart] rx fifo count " << static_cast<int>(prev_rx_count_)
                          << " -> " << static_cast<int>(rx_count) << std::endl;
                if (prev_rx_count_ == 0 && rx_count > 0) {
                    const uint8_t sample = static_cast<uint8_t>(top.rootp->dioptase__DOT__uart__DOT__uart_rx__DOT__shift);
                    std::cerr << "[uart] captured byte 0x" << std::hex << std::setw(2) << std::setfill('0')
                              << static_cast<int>(sample) << std::dec << std::setfill(' ') << std::endl;
                }
                if (prev_rx_count_ > 0 && rx_count == 0) {
                    const uint32_t raddr0 = 0;
                    const uint32_t raddr1 = top.rootp->dioptase__DOT__mem__DOT__raddr1_buf;
                    const uint32_t rdata0 = top.rootp->dioptase__DOT__mem_read0_data;
                    const uint32_t rdata1 = top.rootp->dioptase__DOT__mem_read1_data;
                    const uint32_t wdata1 = top.rootp->dioptase__DOT__cpu__DOT__reg_write_data_1;
                    const uint32_t mem_stage_res = top.rootp->dioptase__DOT__cpu__DOT__mem_b_result_out_1;
                    const uint8_t mem_is_load = top.rootp->dioptase__DOT__cpu__DOT__mem_b_is_load_out;
                    const uint8_t exec_is_load = top.rootp->dioptase__DOT__cpu__DOT__exec_is_load_out;
                    const uint32_t wb_res = top.rootp->dioptase__DOT__cpu__DOT__wb_result_out_1;
                    const uint8_t mem_opcode = static_cast<uint8_t>(top.rootp->dioptase__DOT__cpu__DOT__mem_b_opcode_out);
                    std::cerr << "[uart] r5 now 0x" << std::hex << std::setw(8) << std::setfill('0')
                              << reg_r5_cur << " raddr0=0x" << std::setw(5) << raddr0
                              << " raddr1=0x" << std::setw(5) << raddr1
                              << " rdata0=0x" << std::setw(8) << rdata0
                              << " rdata1=0x" << std::setw(8) << rdata1
                              << " mem_stage=0x" << std::setw(8) << mem_stage_res
                              << " reg_wdata1=0x" << std::setw(8) << wdata1
                              << " exec_is_load=" << static_cast<int>(exec_is_load)
                              << " mem_is_load=" << static_cast<int>(mem_is_load)
                              << " mem_opcode=" << static_cast<int>(mem_opcode)
                              << " wb_result=0x" << std::setw(8) << wb_res
                              << std::dec << std::setfill(' ') << std::endl;
                }
                prev_rx_count_ = rx_count;
            }
            const uint8_t tx_count = static_cast<uint8_t>(top.rootp->dioptase__DOT__uart__DOT__tx_buf__DOT__count);
            if (tx_count != prev_tx_count_) {
                std::cerr << "[uart] tx fifo count " << static_cast<int>(prev_tx_count_)
                          << " -> " << static_cast<int>(tx_count) << std::endl;
                prev_tx_count_ = tx_count;
            }
            if (top.rootp->dioptase__DOT__uart_tx_en) {
                const uint8_t byte = static_cast<uint8_t>(top.rootp->dioptase__DOT__uart_tx_data);
                const uint32_t addr = static_cast<uint32_t>(top.rootp->dioptase__DOT__mem__DOT__waddr_buf << 2);
                std::cerr << "[uart] tx_en byte=0x" << std::hex << std::setw(2) << std::setfill('0')
                          << static_cast<int>(byte) << " addr=0x" << std::setw(8)
                          << addr << std::dec << std::setfill(' ') << std::endl;
            }
            if (reg_r5_cur != prev_r5_) {
                std::cerr << "[uart] reg r5 change -> 0x" << std::hex << std::setw(8) << std::setfill('0')
                          << reg_r5_cur << std::dec << std::setfill(' ') << std::endl;
                prev_r5_ = reg_r5_cur;
            }
        }
        if (ps2_debug_) {
            const uint16_t value = static_cast<uint16_t>(top.rootp->dioptase__DOT__ps2__DOT__keyboard_reg);
            if (value != prev_ps2_value_) {
                std::cerr << "[ps2] keyboard_reg -> 0x" << std::hex << std::setw(4) << std::setfill('0')
                          << value << std::dec << std::setfill(' ') << std::endl;
                prev_ps2_value_ = value;
            }
        }
        if (pit_debug_) {
            const bool pit_irq = top.rootp->dioptase__DOT__mem__DOT__pit_interrupt;
            if (pit_irq && !pit_irq_prev_) {
                const uint32_t color = top.rootp->dioptase__DOT__mem__DOT__ram[355];
                const uint32_t ivt_f0 = top.rootp->dioptase__DOT__mem__DOT__ram[240];
                const uint32_t tile00 = top.rootp->dioptase__DOT__mem__DOT__tile_map[0];
                const uint32_t tile0 = top.rootp->dioptase__DOT__mem__DOT__tile_map[32];
                const uint32_t tile1 = top.rootp->dioptase__DOT__mem__DOT__tile_map[33];
                const uint32_t isr = top.rootp->dioptase__DOT__cpu__DOT__interrupt_state;
                const uint32_t raw_isr = top.rootp->dioptase__DOT__cpu__DOT__decode__DOT__cregfile__DOT__cregfile[2];
                const uint32_t imr = top.rootp->dioptase__DOT__cpu__DOT__decode__DOT__cregfile__DOT__cregfile[3];
                const uint32_t r8 = top.rootp->dioptase__DOT__cpu__DOT__decode__DOT__regfile__DOT__regfile[8];
                const uint32_t pc = top.rootp->dioptase__DOT__cpu__DOT__decode_pc_out;
                const uint32_t last_waddr = top.rootp->dioptase__DOT__mem__DOT__waddr_buf;
                const uint8_t last_wen = static_cast<uint8_t>(top.rootp->dioptase__DOT__mem__DOT__wen_buf);
                const bool sleep = top.rootp->dioptase__DOT__cpu__DOT__sleep;
                const bool in_wb_irq = top.rootp->dioptase__DOT__cpu__DOT__interrupt_in_wb;
                std::cerr << "[pit] interrupt at cycle " << total_cycles_
                          << ", color=0x" << std::hex << std::setw(8)
                          << std::setfill('0') << color
                          << " ivt_f0=0x" << std::setw(8) << ivt_f0
                          << " tile[0]=0x" << std::setw(8) << tile00
                          << " tile[32]=0x" << std::setw(8) << tile0
                          << " tile[33]=0x" << std::setw(8) << tile1
                          << " isr=0x" << std::setw(8) << isr
                          << " raw_isr=0x" << std::setw(8) << raw_isr
                          << " imr=0x" << std::setw(8) << imr
                          << " r8=0x" << std::setw(8) << r8
                          << " waddr=0x" << std::setw(8) << last_waddr
                          << " wen=0x" << std::setw(2) << static_cast<unsigned>(last_wen)
                          << " pc=0x" << std::setw(8) << pc
                          << " sleep=" << std::dec << sleep
                          << " wb_irq=" << in_wb_irq
                          << std::dec << std::setfill(' ') << std::endl;
            }
            pit_irq_prev_ = pit_irq;
        }
        if (vblank_debug_) {
            const bool vblank_irq = top.rootp->dioptase__DOT__mem__DOT__vga_vblank_irq;
            if (vblank_irq && !vblank_irq_prev_) {
                const uint32_t frame = top.rootp->dioptase__DOT__mem__DOT__vga_frame_count;
                const uint32_t r2 = top.rootp->dioptase__DOT__cpu__DOT__decode__DOT__regfile__DOT__regfile[2];
                std::cerr << "[vblank] irq at cycle " << total_cycles_
                          << " frame=" << frame
                          << " r2=0x" << std::hex << std::setw(8) << std::setfill('0') << r2
                          << std::dec << std::setfill(' ') << std::endl;
            }
            if (top.rootp->dioptase__DOT__uart_tx_en) {
                const uint8_t byte = static_cast<uint8_t>(top.rootp->dioptase__DOT__uart_tx_data);
                const uint32_t r2 = top.rootp->dioptase__DOT__cpu__DOT__decode__DOT__regfile__DOT__regfile[2];
                std::cerr << "[vblank] uart tx cycle=" << total_cycles_
                          << " byte=0x" << std::hex << std::setw(2) << std::setfill('0')
                          << static_cast<int>(byte)
                          << " r2=0x" << std::setw(8) << r2
                          << std::dec << std::setfill(' ') << std::endl;
            }
            vblank_irq_prev_ = vblank_irq;
        }
        if (cdiv_debug_) {
            const uint32_t pc = top.rootp->dioptase__DOT__cpu__DOT__decode_pc_out;
            const bool watch_pc = (pc >= 0x00000520u && pc <= 0x00000560u) || (pc < 0x00000100u);
            if (watch_pc) {
                const uint8_t d_op = static_cast<uint8_t>(top.rootp->dioptase__DOT__cpu__DOT__decode_opcode_out);
                const uint8_t e_op = static_cast<uint8_t>(top.rootp->dioptase__DOT__cpu__DOT__exec_opcode_out);
                const uint8_t mb_exc = static_cast<uint8_t>(top.rootp->dioptase__DOT__cpu__DOT__mem_b_exc_out);
                const bool wb_irq = top.rootp->dioptase__DOT__cpu__DOT__interrupt_in_wb;
                const uint32_t isr = top.rootp->dioptase__DOT__cpu__DOT__decode__DOT__cregfile__DOT__cregfile[2];
                const uint32_t imr = top.rootp->dioptase__DOT__cpu__DOT__decode__DOT__cregfile__DOT__cregfile[3];
                const uint32_t r8 = top.rootp->dioptase__DOT__cpu__DOT__decode__DOT__regfile__DOT__regfile[8];
                const uint32_t r10 = top.rootp->dioptase__DOT__cpu__DOT__decode__DOT__regfile__DOT__regfile[10];
                const uint32_t waddr = top.rootp->dioptase__DOT__mem__DOT__waddr_buf;
                const uint8_t wen = static_cast<uint8_t>(top.rootp->dioptase__DOT__mem__DOT__wen_buf);
                const uint32_t mr1 = top.rootp->dioptase__DOT__mem__DOT__raddr1_buf;
                const uint32_t md1 = top.rootp->dioptase__DOT__mem_read1_data;
                std::cerr << "[cdiv] cyc=" << total_cycles_
                          << " pc=0x" << std::hex << std::setw(8) << std::setfill('0') << pc
                          << " d_op=" << std::setw(2) << static_cast<unsigned>(d_op)
                          << " e_op=" << std::setw(2) << static_cast<unsigned>(e_op)
                          << " mb_exc=0x" << std::setw(2) << static_cast<unsigned>(mb_exc)
                          << " clk_en=" << std::dec << static_cast<unsigned>(top.rootp->dioptase__DOT__clk_en)
                          << " wb_irq=" << wb_irq
                          << " isr=0x" << std::hex << std::setw(8) << isr
                          << " imr=0x" << std::setw(8) << imr
                          << " r8=0x" << std::setw(8) << r8
                          << " r10=0x" << std::setw(8) << r10
                          << " waddr=0x" << std::setw(8) << waddr
                          << " wen=0x" << std::setw(2) << static_cast<unsigned>(wen)
                          << " mr1=0x" << std::setw(8) << mr1
                          << " md1=0x" << std::setw(8) << md1
                          << std::dec << std::setfill(' ') << std::endl;
            }
        }
        ++total_cycles_;
        ps2_.tick(top);
    }

    void after_cycle(Vdioptase &top) {
        sd_card_.tick(top);
    }

private:
    KeyboardRoute keyboard_route_;
    TerminalRawGuard guard_;
    Ps2Transmitter ps2_;
    UartStimulus uart_input_;
    KeyboardInput keyboard_;
    UartConsole uart_;
    SdCardSpiDevice sd_card_;
    bool pit_debug_ = false;
    bool pit_irq_prev_ = false;
    bool vblank_debug_ = false;
    bool vblank_irq_prev_ = false;
    uint64_t total_cycles_ = 0;
    std::vector<uint8_t> initial_uart_bytes_;
    std::vector<uint8_t> initial_ps2_scancodes_;
    bool uart_debug_ = false;
    bool ps2_debug_ = false;
    bool cdiv_debug_ = false;
    uint8_t prev_rx_count_ = 0;
    uint8_t prev_tx_count_ = 0;
    uint32_t prev_r5_ = 0;
    uint16_t prev_ps2_value_ = 0;
};

Options parse_options(int argc, char **argv, std::vector<std::string> &verilator_args) {
    Options opts;
    verilator_args.clear();
    verilator_args.emplace_back(argv[0]);

    const std::string max_cycles_prefix = "--max-cycles=";

    for (int i = 1; i < argc; ++i) {
        std::string arg(argv[i]);
        if (arg == "--vga" || arg == "--gui") {
            opts.use_vga = true;
            continue;
        }
        if (arg == "--uart") {
            opts.keyboard_via_uart = true;
            continue;
        }
        if (arg.rfind(max_cycles_prefix, 0) == 0) {
            const std::string value = arg.substr(max_cycles_prefix.size());
            try {
                opts.max_cycles = std::stoull(value);
                opts.max_cycles_overridden = true;
            } catch (const std::exception &) {
                std::cerr << "Invalid value for --max-cycles: " << value << std::endl;
                std::exit(EXIT_FAILURE);
            }
            continue;
        }
        verilator_args.emplace_back(arg);
    }

    if (opts.use_vga && !opts.max_cycles_overridden) {
        opts.max_cycles = 0; // unlimited when GUI is enabled
    }

    return opts;
}

class DioptaseSim {
public:
    DioptaseSim(Vdioptase &top, VGAWIN &window, uint64_t max_cycles, bool keyboard_via_uart)
        : top_(top), window_(window), peripherals_(keyboard_via_uart), max_cycles_(max_cycles) {
        peripherals_.attach(top_);
        top_.clk = 0;
        top_.eval();
    }

    bool step() {
        if (Verilated::gotFinish()) {
            return false;
        }

        for (int i = 0; i < cycles_per_idle_; ++i) {
            if (!tick()) {
                return false;
            }
        }
        return true;
    }

    uint64_t cycles() const { return cycle_count_; }

private:
    bool tick() {
        peripherals_.before_cycle(top_);
        top_.clk = 0;
        top_.eval();
        if (Verilated::gotFinish()) {
            return false;
        }

        top_.clk = 1;
        top_.eval();
        peripherals_.after_posedge(top_);
        if (Verilated::gotFinish()) {
            return false;
        }

        const uint8_t clk_div = top_.rootp->dioptase__DOT__vga__DOT__clk_div;
        if (clk_div_prev_ != 0 && clk_div == 0) {
            update_vga();
        }
        clk_div_prev_ = clk_div;

        top_.clk = 0;
        top_.eval();
        if (Verilated::gotFinish()) {
            return false;
        }

        peripherals_.after_cycle(top_);

        ++cycle_count_;
        if (max_cycles_ != 0 && cycle_count_ >= max_cycles_) {
            return false;
        }

        return true;
    }

    void update_vga() {
        const int vsync = top_.vga_v_sync ? 1 : 0;
        const int hsync = top_.vga_h_sync ? 1 : 0;
        const int red = (top_.vga_red & 0xF) * 0x11;
        const int green = (top_.vga_green & 0xF) * 0x11;
        const int blue = (top_.vga_blue & 0xF) * 0x11;

        window_(vsync, hsync, red, green, blue);
    }

    static constexpr int cycles_per_idle_ = 512;

    Vdioptase &top_;
    VGAWIN &window_;
    SimPeripherals peripherals_;
    const uint64_t max_cycles_;
    uint64_t cycle_count_ = 0;
    uint8_t clk_div_prev_ = 0;
};

bool run_headless(Vdioptase &top, uint64_t max_cycles, bool keyboard_via_uart,
                  uint64_t &cycles_executed) {
    SimPeripherals peripherals(keyboard_via_uart);
    peripherals.attach(top);

    top.clk = 0;
    top.eval();
    if (Verilated::gotFinish()) {
        cycles_executed = 0;
        return true;
    }

    cycles_executed = 0;

    while (true) {
        peripherals.before_cycle(top);

        top.clk = 0;
        top.eval();
        if (Verilated::gotFinish()) {
            return true;
        }

        top.clk = 1;
        top.eval();
        peripherals.after_posedge(top);
        if (Verilated::gotFinish()) {
            return true;
        }

        top.clk = 0;
        top.eval();
        if (Verilated::gotFinish()) {
            return true;
        }

        peripherals.after_cycle(top);

        ++cycles_executed;
        if (max_cycles != 0 && cycles_executed >= max_cycles) {
            return false;
        }
    }
}

void run_with_vga(Vdioptase &top, uint64_t max_cycles, bool keyboard_via_uart) {
    // Display the VGA output at 2x scale for easier viewing without changing timing/mode.
    VGAWIN window("640 656 752 800", "480 490 492 524", 2);
    DioptaseSim sim(top, window, max_cycles, keyboard_via_uart);

    auto idle = Glib::signal_idle().connect([&]() -> bool {
        if (!sim.step()) {
            Gtk::Main::quit();
            return false;
        }
        return true;
    });

    Gtk::Main::run(window);
    idle.disconnect();

    if (!Verilated::gotFinish() && max_cycles != 0 && sim.cycles() >= max_cycles) {
        std::cout << "VGA simulation stopped after reaching cycle limit (" << max_cycles << ")." << std::endl;
    }
}

} // namespace

int main(int argc, char **argv) {
    std::vector<std::string> verilator_args;
    Options opts = parse_options(argc, argv, verilator_args);
    sanitize_hex_plusarg(verilator_args);

    const std::string cycle_plusarg = "+cycle_limit=" + std::to_string(opts.max_cycles);
    verilator_args.push_back(cycle_plusarg);

    std::vector<char *> verilator_cargs;
    verilator_cargs.reserve(verilator_args.size());
    for (auto &arg : verilator_args) {
        verilator_cargs.push_back(const_cast<char *>(arg.c_str()));
    }
    Verilated::commandArgs(static_cast<int>(verilator_cargs.size()), verilator_cargs.data());

    if (opts.use_vga) {
        int gtk_argc = 1;
        char *gtk_argv_storage[] = {argv[0], nullptr};
        char **gtk_argv = gtk_argv_storage;
        Gtk::Main gtk(gtk_argc, gtk_argv);

        Vdioptase top;
        run_with_vga(top, opts.max_cycles, opts.keyboard_via_uart);
        top.final();
    } else {
        Vdioptase top;
        uint64_t cycles_executed = 0;
        bool finished = run_headless(top, opts.max_cycles, opts.keyboard_via_uart, cycles_executed);
        if (!finished && opts.max_cycles != 0) {
            std::cout << "Headless simulation stopped after " << cycles_executed
                      << " cycles without $finish." << std::endl;
        }
        top.final();
    }

    return 0;
}
