#include <cstdint>
#include <cstdlib>
#include <iostream>
#include <stdexcept>
#include <string>
#include <vector>

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
        top_.clk = 0;
        top_.eval();
        if (Verilated::gotFinish()) {
            return false;
        }

        top_.clk = 1;
        top_.eval();
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
    const uint64_t max_cycles_;
    uint64_t cycle_count_ = 0;
    uint8_t clk_div_prev_ = 0;
};

bool run_headless(Vdioptase &top, uint64_t max_cycles, uint64_t &cycles_executed) {
    top.clk = 0;
    top.eval();

    cycles_executed = 0;

    while (true) {
        if (Verilated::gotFinish()) {
            return true;
        }

        top.clk = 0;
        top.eval();
        if (Verilated::gotFinish()) {
            return true;
        }

        top.clk = 1;
        top.eval();
        if (Verilated::gotFinish()) {
            return true;
        }

        top.clk = 0;
        top.eval();
        if (Verilated::gotFinish()) {
            return true;
        }

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
