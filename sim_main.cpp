#include "Vcpu.h"
#include "verilated.h"

int main(int argc, char **argv) {
    Verilated::commandArgs(argc, argv);
    Vcpu* top = new Vcpu;

    // Run for N cycles
    for (int i = 0; i < 1000; i++) {
        top->clk = 0;
        top->eval();

        top->clk = 1;
        top->eval();
    }

    delete top;
    return 0;
}
