# FPGA Flow (Nexys A7)

This directory contains a Vivado project flow for the full pipeline core.

## Files

- `fpga/dioptase_fpga_top.v`: board-level wrapper that instantiates `dioptase`.
- `fpga/create_project.tcl`: batch script to create/run Vivado project.
- `fpga/nexys_a7_template.xdc`: constraints template to fill from Digilent master XDC.
- `scripts/gen_icache_preload.py`: converts `bios.hex` into direct I-cache preload files.
- `scripts/sync_pipeline_to_windows.sh`: WSL script to mirror this repo to Windows.

## Important Notes

- Pin mapping is board-level and currently implementation-defined in this repo.
  You must fill `nexys_a7_template.xdc` with real `PACKAGE_PIN` values.
- `CPU_RESETN` is reserved in the wrapper, but the current SoC does not yet
  expose an explicit reset port.
- Simulation-only waveform system tasks are guarded with `` `ifndef SYNTHESIS ``
  in `src/dioptase.v` so Vivado can synthesize cleanly.
- `create_project.tcl` adds `data/scan_decode.mem` as a memory initialization
  file for `src/ps2.v`.
- `create_project.tcl` enables `FPGA_ICACHE_PRELOAD=1` and requires:
  `data/icache_way0.mem`, `data/icache_way1.mem`, `data/icache_tagv0.mem`,
  `data/icache_tagv1.mem`.

## 1. Generate I-Cache Preload From BIOS

From WSL:

```bash
cd Dioptase-CPUs/Dioptase-Pipe-Full
./scripts/gen_icache_preload.py --input ../../Dioptase-OS/build/bios.hex --out-dir ./data
```

## 2. Sync From WSL To Windows Mirror

Mirror this project to your Windows filesystem:

```bash
cd Dioptase-CPUs/Dioptase-Pipe-Full
./scripts/sync_pipeline_to_windows.sh --dest /mnt/c/Users/<you>/Dioptase/Dioptase-CPUs/Dioptase-Pipe-Full
```

Optional flags:

- `--dry-run`: preview copy/delete actions.
- `--include-git`: include `.git` in the mirror.
- environment fallback: `DIOPTASE_PIPELINE_WIN_MIRROR=/mnt/c/...`

## 3. Fill Constraints

1. Open `fpga/nexys_a7_template.xdc` in the Windows mirror.
2. Copy pin names from the official Digilent Nexys A7 master XDC.
3. Uncomment and fill each `PACKAGE_PIN` entry for used ports.
4. Keep the clock constraint (`create_clock`) at 100 MHz.

## 4. Create Vivado Project

From Windows terminal or Tcl console in Vivado:

```powershell
cd C:\Users\<you>\Dioptase\Dioptase-CPUs\Dioptase-Pipe-Full
vivado -mode batch -source .\fpga\create_project.tcl
```

This runs synthesis only by default.

To run implementation + bitstream as well:

```powershell
vivado -mode batch -source .\fpga\create_project.tcl -tclargs .\build\vivado 1
```

If Vivado crashes during synthesis on Windows, reduce parallelism:

```powershell
vivado -mode batch -source .\fpga\create_project.tcl -tclargs .\build\vivado 1 1
```

The third argument is `run_jobs`; use `1` for maximum stability.

To isolate preload-related crashes, disable direct I-cache preload temporarily:

```powershell
vivado -mode batch -source .\fpga\create_project.tcl -tclargs .\build\vivado 1 1 0
```

The fourth argument is `enable_icache_preload` (1=on, 0=off).

To switch backing memory from `ram.v` to an external Digilent-style
DDR->SRAM bridge module (`ddr_sram_adapter`):

```powershell
vivado -mode batch -source .\fpga\create_project.tcl -tclargs .\build\vivado 1 1 1 1
```

The fifth argument is `enable_ddr_adapter` (1=use `ddr_sram_adapter`,
0=use in-repo `ram.v`).

To keep VGA tile/sprite output but remove the large pixel framebuffer path
(for FPGA fit/resource reduction), pass a sixth argument of `0`:

```powershell
vivado -mode batch -source .\fpga\create_project.tcl -tclargs .\build\vivado 1 1 1 1 0
```

With in-repo RAM (no DDR adapter), use:

```powershell
vivado -mode batch -source .\fpga\create_project.tcl -tclargs .\build\vivado 1 1 1 0 0
```

The sixth argument is `enable_pixel_fb` (1=keep pixel framebuffer,
0=disable pixel framebuffer MMIO storage and use tile/sprite-only VGA composition).

When `enable_ddr_adapter=1`, `create_project.tcl` expects the Digilent files in:

- `ram2ddr_refcomp/Ram2Ddr_RefComp/Source/Ram2Ddr_RefComp/ram2ddr.vhd`
- `ram2ddr_refcomp/Ram2Ddr_RefComp/Source/Ram2Ddr_RefComp/ipcore_dir/ddr/user_design/rtl/*`
- `ram2ddr_refcomp/Ram2Ddr_RefComp/Source/Ram2Ddr_RefComp/ipcore_dir/ddr/user_design/constraints/ddr.xdc`

The script auto-adds those files and also enables `FPGA_USE_DDR_SRAM_ADAPTER=1`.

Important integration note:
- The Digilent `ram2ddr` core was generated for a 200 MHz system clock input.
- The current wrapper feeds the SoC clock to the adapter; if your design clock
  is 100 MHz, regenerate MIG/adapter settings or add a proper clocking stage.
- In `FPGA_USE_DDR_SRAM_ADAPTER` builds, CPU reads from sprite/tile/frame/pixel
  backing MMIO arrays are intentionally disabled (readback returns `0`) to keep
  display memories in a BRAM-friendly topology for implementation.

## 5. Open Project In GUI (Optional)

After batch creation:

1. Open `build/vivado/dioptase_pipe_full.xpr` in Vivado GUI.
2. Review timing and DRC.
3. Program device with generated bitstream.
