# Dioptase-Pipe-Full

Pipeline implementation of [Dioptase-Emulator-Full](https://github.com/b-Rocks2718/Dioptase-Emulator-Full)

6 stage pipeline

- fetch a
- fetch b
- decode
- execute
- mem
- writeback

The I/O verilog for this project build off the code written by [Paul Bailey](https://github.com/PaulBailey-1) for the [JPEB project](https://github.com/PaulBailey-1/JPEB)

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
Run the tests with `verilator` using `make test_verilator`.  

The test suite consists of all tests used for verifying the emulator, in addition pipeline-specific tests to ensure forwarding, stalls, and misaligned memory accesses are handled correctly.

I'm using [VGASIM](https://github.com/ZipCPU/vgasim) to test I/O

## Getting verilator to compile

Install dependencies
```bash
sudo apt update
sudo apt install libgtkmm-3.0-dev
sudo apt install bc
```

In `/usr/share/verilator/include/verilated_threads.h`, after the
```cpp
#ifndef _VERILATED_THREADS_H_
#define _VERILATED_THREADS_H_
```
add this snippet:
```cpp
// Patch missing Verilator thread macros
#ifndef VL_CPU_RELAX
#include <thread>   // make sure std::this_thread::yield() is visible
#include <atomic>
#define VL_CPU_RELAX() std::this_thread::yield()
#endif

#ifndef VL_LOCK_SPINS
#define VL_LOCK_SPINS 1000
#endif
```
