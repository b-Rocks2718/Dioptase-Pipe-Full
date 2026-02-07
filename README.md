# Dioptase-Pipe-Full

Pipeline implementation of [Dioptase-Emulator-Full](https://github.com/b-Rocks2718/Dioptase-Emulator-Full)

9 stage pipeline

- TLB fetch
- fetch a
- fetch b
- decode
- execute
- TLB memory
- memory a
- memory b
- writeback

The I/O verilog for this project builds off the code written by [Paul Bailey](https://github.com/PaulBailey-1) for the [JPEB project](https://github.com/PaulBailey-1/JPEB)

## Dependencies

This subproject depends on tools both from this repo and from your system.

### Required for `make test` (Icarus flow)

System tools:
- `make`
- `iverilog`
- `vvp`
- `sed`

In-repo binaries (must already be built):
- `../../Dioptase-Assembler/build/debug/basm`
- `../../Dioptase-Emulators/Dioptase-Emulator-Full/target/release/Dioptase-Emulator-Full`

### Required for `make test-verilator` / `make verilator`

Everything above, plus:
- `verilator`
- `pkg-config`
- `gtkmm-3.0` development package (`libgtkmm-3.0-dev` on Ubuntu/Debian)
- C++ toolchain (used by Verilator C++ build)

`test-verilator` now performs an explicit dependency check and prints an actionable
error if `pkg-config`/`gtkmm-3.0` are missing.

### Example install commands (Ubuntu/Debian)

```bash
sudo apt update
sudo apt install make iverilog verilator pkg-config libgtkmm-3.0-dev build-essential
```

## Usage

Use `make all` or `make sim.vvp` to build the project.
Run it on a hex file with `./sim.vvp +hex=<file.hex>`

Build it with verilator using `make verilator`.
Run with verilator using `./obj_dir/dioptase +hex=<file.hex>`

The verilator sim accepts the follwing flags:  
`--vga`: make a window with the VGA output  
`--uart`: route keyboard input to the UART instead of ps/2  
`--max-cycles=<number>`: limit the maximum number of cycles. Default is 500 for now. Use `--max-cycles=0` to run forever. Using `--vga` will also remove any limit on the number of cycles. 

Run the tests with `iverilog` using `make test`.  
Run the tests with `verilator` using `make test-verilator`.  

The test suite consists of all tests used for verifying the emulator, in addition pipeline-specific tests to ensure forwarding, stalls, and misaligned memory accesses are handled correctly.

I'm using [VGASIM](https://github.com/ZipCPU/vgasim) to test I/O
