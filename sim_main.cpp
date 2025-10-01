#include <array>
#include <cctype>
#include <cerrno>
#include <cstdint>
#include <cstdlib>
#include <deque>
#include <iomanip>
#include <iostream>
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
#include "verilated.h"

#include "extern/vgasim/bench/cpp/vgasim.h"

namespace {

struct Options {
    bool use_vga = false;
    bool max_cycles_overridden = false;
    uint64_t max_cycles = 500;
};

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
            if (!clk_high_) {
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

class KeyboardInput {
public:
    explicit KeyboardInput(TerminalRawGuard &guard)
        : guard_(guard), debug_(std::getenv("PS2_DEBUG") != nullptr) {}

    void poll(Ps2Transmitter &tx) {
        if (!guard_.active()) {
            while (std::cin.good() && std::cin.rdbuf()->in_avail() > 0) {
                const char ch = static_cast<char>(std::cin.get());
                if (!std::cin.good()) {
                    break;
                }
                emit_character(ch, tx);
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
                emit_character(buffer[idx], tx);
            }
        }
    }

private:
    void emit_character(char ch, Ps2Transmitter &tx) {
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

        tx.enqueue_sequence(*sequence);
        if (debug_) {
            for (uint8_t value : *sequence) {
                std::cerr << "[ps2] enqueue 0x" << std::hex << std::setw(2) << std::setfill('0')
                          << static_cast<int>(value) << std::dec << std::setfill(' ')
                          << " ('" << ch << "')" << std::endl;
            }
        }
    }

    std::optional<std::vector<uint8_t>> encode_character(char ch) const {
        auto sc = lookup_scancode(ch);
        if (!sc) {
            return std::nullopt;
        }
        return std::vector<uint8_t>{*sc};
    }

    TerminalRawGuard &guard_;
    bool warned_unknown_ = false;
    bool reported_read_error_ = false;
    bool debug_ = false;

private:
    static std::optional<uint8_t> lookup_scancode(char ch) {
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
            return 0x0D;
        }
        if (ch == '\b' || ch == 0x7F) {
            return 0x66;
        }
        if (ch == '\n') {
            return 0x5A;
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
};

class UartConsole {
public:
    UartConsole() : debug_(std::getenv("UART_DEBUG") != nullptr) {}

    void after_posedge(Vdioptase &top) {
        const uint8_t write_ptr = static_cast<uint8_t>(top.dioptase__DOT__uart__DOT__tx_buf__DOT__write_ptr);

        if (!initialized_) {
            prev_write_ptr_ = write_ptr;
            initialized_ = true;
        } else if (write_ptr != prev_write_ptr_) {
            const char ch = static_cast<char>(top.dioptase__DOT__uart_tx_data);
            std::cout << ch << std::flush;
            if (debug_) {
                const uint32_t addr = static_cast<uint32_t>(top.dioptase__DOT__mem__DOT__waddr_buf);
                const uint32_t raw = top.dioptase__DOT__cpu__DOT__store_data;
                const uint8_t wen = static_cast<uint8_t>(top.dioptase__DOT__mem__DOT__wen_buf);
                const uint16_t ps2_val = top.dioptase__DOT__ps2__DOT__keyboard_reg;
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

class SimPeripherals {
public:
    SimPeripherals() : keyboard_(guard_) {}

    void attach(Vdioptase &top) {
        ps2_.reset(top);
        top.uart_rx = 1;
    }

    void before_cycle(Vdioptase &top) {
        keyboard_.poll(ps2_);
        top.uart_rx = 1;
        ps2_.tick(top);
    }

    void after_posedge(Vdioptase &top) {
        uart_.after_posedge(top);
        ps2_.tick(top);
    }

    void after_cycle() {}

private:
    TerminalRawGuard guard_;
    Ps2Transmitter ps2_;
    KeyboardInput keyboard_;
    UartConsole uart_;
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
    DioptaseSim(Vdioptase &top, VGAWIN &window, uint64_t max_cycles)
        : top_(top), window_(window), max_cycles_(max_cycles) {
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

        const uint8_t clk_div = top_.dioptase__DOT__vga__DOT__clk_div;
        if (clk_div_prev_ != 0 && clk_div == 0) {
            update_vga();
        }
        clk_div_prev_ = clk_div;

        top_.clk = 0;
        top_.eval();
        if (Verilated::gotFinish()) {
            return false;
        }

        peripherals_.after_cycle();

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
    SimPeripherals peripherals_ {};
    const uint64_t max_cycles_;
    uint64_t cycle_count_ = 0;
    uint8_t clk_div_prev_ = 0;
};

bool run_headless(Vdioptase &top, uint64_t max_cycles, uint64_t &cycles_executed) {
    SimPeripherals peripherals;
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

        peripherals.after_cycle();

        ++cycles_executed;
        if (max_cycles != 0 && cycles_executed >= max_cycles) {
            return false;
        }
    }
}

void run_with_vga(Vdioptase &top, uint64_t max_cycles) {
    VGAWIN window("640 656 752 800", "480 490 492 524");
    DioptaseSim sim(top, window, max_cycles);

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
        run_with_vga(top, opts.max_cycles);
        top.final();
    } else {
        Vdioptase top;
        uint64_t cycles_executed = 0;
        bool finished = run_headless(top, opts.max_cycles, cycles_executed);
        if (!finished && opts.max_cycles != 0) {
            std::cout << "Headless simulation stopped after " << cycles_executed
                      << " cycles without $finish." << std::endl;
        }
        top.final();
    }

    return 0;
}
