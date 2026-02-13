# Dioptase-Pipe-Full

Pipelined Verilog implementation of the full Dioptase CPU model, validated
against `Dioptase-Emulator-Full`.

The I/O Verilog in this project builds on work by
[Paul Bailey](https://github.com/PaulBailey-1) for
[JPEB](https://github.com/PaulBailey-1/JPEB).

## Scope

This project is both:

- A simulation harness for ISA/ABI validation against the full emulator.
- The FPGA-oriented full pipeline core with MMIO peripherals and TLB support.

Canonical architecture docs for ISA-visible behavior:

- `../../docs/ISA.md`
- `../../docs/abi.md`
- `../../docs/mem_map.md`

## Pipeline

The core uses a 9-stage in-order pipeline:

1. `tlb_fetch`
2. `fetch_a`
3. `fetch_b`
4. `decode`
5. `execute`
6. `tlb_memory`
7. `memory_a`
8. `memory_b`
9. `writeback`

Stage responsibilities:

- `tlb_fetch`: frontend PC generation, redirect handling (branch/interrupt/rfe),
  and issue-stop handling on backend stalls.
- `fetch_a/fetch_b`: align fetched instruction metadata with memory latency.
- `decode`: instruction parse, immediate generation, regfile/creg reads,
  exception decode, and atomic cracking.
- `execute`: forwarding, hazard detection, ALU ops, branch decision/target,
  and memory request formation.
- `tlb_memory`: applies TLB read/exception results to execute output and keeps
  TLB faults as live slots.
- `memory_a/memory_b`: registered transfer stages to align payload timing into
  writeback.
- `writeback`: lane masking for subword loads, final register writes, and
  control events (exception/rfe/rfi/halt/sleep).

## Frontend Queue And Duplicate Prevention

The frontend uses a decode-boundary packet queue. Fetch stages produce aligned
packets:

- `{instr, pc, slot_id, exc, bubble}`

and `cpu.v` enqueues them before decode consumes them.

### Why this is needed

There are multiple registered stages between fetch issue and decode consume
(`tlb_fetch -> fetch_a -> fetch_b -> decode`). When execute/decode stalls,
instruction returns can still arrive for already-issued requests. The queue
keeps these returns ordered and paired with their PC/slot metadata.

The queue keeps ordering and pairing explicit:

- fetch side pushes complete packets,
- decode side pops only when it truly consumes a frontend slot,
- `flush` clears younger queued packets.

### How duplication can still happen

At a stall-open boundary, the same decode payload can transiently reappear at
execute if pipeline hold state lags by a cycle. Atomic crack completion can
also present a stale frontend copy of the same just-drained atomic slot.

### How duplicates are filtered

- Decode uses `atomic_drain_dup` (keyed by slot id + pc + instr) to drop the
  stale frontend copy immediately after an atomic crack sequence drains.
- Execute applies final dedup with a packed signature register and drops
  repeated decode signatures while a post-stall dedup window is active.

## Hazards, Forwarding, And Atomics

Forwarding priority in `execute` is newest-to-oldest producer:

1. current execute outputs
2. `tlb_memory`
3. `memory_a`
4. `memory_b`
5. writeback
6. local stall-history buffers
7. regfile

Load-use hazards stall decode when dependent operands are not forwardable yet.
Control-register (`crmov`) hazards use dedicated CR forwarding rather than
stalling.

Atomic instructions are cracked in decode:

- `swap`: `load -> store`
- `fetch_add`: `load -> add -> store`

Decode keeps ownership (`decode_stall`) until the micro-op sequence drains.

## TLB And Exceptions

TLB format and behavior follow the emulator/ISA model:

- 16-entry fully-associative TLB.
- Lookup order: PID-private entries first, then global entries.
- Separate instruction-side (`addr0`) and data-side (`addr1`) checks.
- Permission faults produce `0x82`/`0x83` depending on mode.

Pipeline exception handling uses live fault slots (bubble cleared) so writeback
can always observe and drive precise redirect behavior.

## Dependencies

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
- C++ toolchain (`build-essential` on Ubuntu/Debian)

`make test-verilator` performs an explicit dependency check and prints an
actionable error if `pkg-config` / `gtkmm-3.0` are missing.

### Example install commands (Ubuntu/Debian)

```bash
sudo apt update
sudo apt install make iverilog verilator pkg-config libgtkmm-3.0-dev build-essential
```

## Build And Run

Build Icarus simulation image:

```bash
make sim.vvp
```

Run Icarus simulation:

```bash
./sim.vvp +hex=<file.hex> [+cycle_limit=10000] [+vcd=trace.vcd]
```

Build Verilator model:

```bash
make verilator
```

Run Verilator model:

```bash
./obj_dir/dioptase +hex=<file.hex> [--max-cycles=<N>] [--vga] [--uart] [--sd0 <file.bin>] [--sd1 <file.bin>]
# shorthand also works:
./obj_dir/dioptase <file.hex> [--max-cycles=<N>] [--vga] [--uart] [--sd0 <file.bin>] [--sd1 <file.bin>]
```

Verilator flags:

- `--vga`: enable VGA window output.
- `--uart`: route keyboard input to UART path instead of PS/2.
- `--max-cycles=<N>`: cycle cap (`0` means unlimited). Enabling `--vga` also
  removes the default cycle cap.
- `--sd0 <file.bin>`: preload SD card 0 from a raw block image.
- `--sd1 <file.bin>`: preload SD card 1 from a raw block image.

## Tests

Run regression with Icarus:

```bash
make test
```

Run regression with Verilator:

```bash
make test-verilator
```

Test harness behavior:

- Assembles tests into `tests/hex/`.
- Runs emulator + Verilog simulation.
- Compares `tests/out/*.emuout` and `tests/out/*.vout`.
- Includes emulator instruction tests and pipeline-specific hazard tests.

I/O simulation uses [VGASIM](https://github.com/ZipCPU/vgasim).
