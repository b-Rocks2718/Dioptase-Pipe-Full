# Dioptase-Pipe-Full

Pipeline implementation of [Dioptase-Emulator-Full](https://github.com/b-Rocks2718/Dioptase-Emulator-Full)

6 stage pipeline

- fetch a
- fetch b
- decode
- execute
- mem
- writeback

## Usage

Use `make all` or `make sim.vvp` to build the project.
Run it on a hex file with `./sim.vvp +hex=<file.hex>`

Run the tests with `make all`.

The test suite consists of all tests used for verifying the emulator, in addition pipeline-specific tests to ensure forwarding, stalls, and misaligned memory accesses are handled correctly.

I'd like to set up verilator and use it to simulate the VGA output
