# Directories
CPU_TESTS_DIR    := tests/asm
EMU_TESTS_DIR    := ../../Dioptase-Emulators/Dioptase-Emulator-Full/tests/asm
SRC_DIR      		 := src
HEX_DIR					 := tests/hex
OUT_DIR      		 := tests/out

# Tools
ASSEMBLER    := ../../Dioptase-Assembler/build/debug/basm
EMULATOR     := ../../Dioptase-Emulators/Dioptase-Emulator-Full/target/release/Dioptase-Emulator-Full
IVERILOG     := iverilog
VVP          := vvp

# Simulation limits
CYCLE_LIMIT  ?= 10000
EMULATOR_ARGS ?= --max-cycles=$(CYCLE_LIMIT)

# All test sources
VERILOG_SRCS   := $(wildcard $(SRC_DIR)/*.v)
VERILATOR_EXCLUDE := $(SRC_DIR)/clock.v $(SRC_DIR)/dioptase.v
VERILATOR_SRCS := $(SRC_DIR)/dioptase.v $(filter-out $(VERILATOR_EXCLUDE), $(VERILOG_SRCS)) extern/vgasim/bench/cpp/vgasim.cpp sim_main.cpp
PKG_CONFIG_BIN := $(shell command -v pkg-config 2>/dev/null)
ifeq ($(strip $(PKG_CONFIG_BIN)),)
GTKMM_CFLAGS   :=
GTKMM_LIBS		 :=
GTKMM_FOUND    := 0
else
GTKMM_CFLAGS   := $(shell pkg-config --cflags gtkmm-3.0 2>/dev/null)
GTKMM_LIBS		 := $(shell pkg-config --libs gtkmm-3.0 2>/dev/null)
GTKMM_FOUND    := $(if $(strip $(GTKMM_CFLAGS) $(GTKMM_LIBS)),1,0)
endif
VERILATOR_CFLAGS := $(strip $(GTKMM_CFLAGS))
VERILATOR_LDFLAGS := $(strip $(GTKMM_LIBS) -lpthread)

CPU_TESTS_SRCS   := $(wildcard $(CPU_TESTS_DIR)/*.s)
# some emu tests run forever and use i/o
EMU_TESTS_ALL      := $(wildcard $(EMU_TESTS_DIR)/*.s)
SDCARD_TEST        := $(EMU_TESTS_DIR)/sdcard.s
EMU_TESTS_EXCLUDE := $(EMU_TESTS_DIR)/cdiv.s $(EMU_TESTS_DIR)/colors.s \
											$(EMU_TESTS_DIR)/green.s $(EMU_TESTS_DIR)/sprite.s \
											$(EMU_TESTS_DIR)/uart.s $(EMU_TESTS_DIR)/sleep.s \
											$(EMU_TESTS_DIR)/ps2.s $(EMU_TESTS_DIR)/uart_rx.s \
											$(EMU_TESTS_DIR)/multicore_colors.s $(EMU_TESTS_DIR)/pixels.s \
											$(EMU_TESTS_DIR)/vblank.s $(EMU_TESTS_DIR)/tile_colors.s \
											$(EMU_TESTS_DIR)/multicore_atomic.s $(EMU_TESTS_DIR)/multicore_ipi.s \
											$(EMU_TESTS_DIR)/multicore_race.s
EMU_TESTS_SRCS    := $(filter-out $(EMU_TESTS_EXCLUDE),$(EMU_TESTS_ALL))
EMU_TESTS_SRCS_ICARUS := $(filter-out $(SDCARD_TEST),$(EMU_TESTS_SRCS))
ASM_SRCS         := $(CPU_TESTS_SRCS) $(EMU_TESTS_SRCS)

HEXES        := $(patsubst %.s,$(HEX_DIR)/%.hex,$(notdir $(ASM_SRCS)))
EMUOUTS      := $(patsubst %.hex,$(OUT_DIR)/%.emuout,$(notdir $(HEXES)))
VOUTS        := $(patsubst %.hex,$(OUT_DIR)/%.vout,$(notdir $(HEXES)))
VCDS 				 := $(patsubst %.hex,$(OUT_DIR)/%.vcd,$(notdir $(HEXES)))

TOTAL            := $(words $(ASM_SRCS))

.PRECIOUS: %.hex %.vout %.emuout %.vcd

all: sim.vvp

# no idea why this doesnt work
check-verilator-deps:
ifeq ($(GTKMM_FOUND),0)
	@echo "ERROR: test-verilator requires pkg-config and gtkmm-3.0 development packages."
	@echo "Install dependencies (example Ubuntu): sudo apt install pkg-config libgtkmm-3.0-dev"
	@exit 1
endif

verilator: check-verilator-deps $(VERILATOR_SRCS)
	verilator --cc --exe --build $(VERILATOR_SRCS) \
    -CFLAGS "$(VERILATOR_CFLAGS)" -LDFLAGS "$(VERILATOR_LDFLAGS)" \
    -o dioptase

# Compile Verilog into sim.vvp once
sim.vvp: $(wildcard $(SRC_DIR)/*.v)
	$(IVERILOG) -DSIMULATION -o sim.vvp $^

$(OUT_DIR)/%.vcd: $(HEX_DIR)/%.hex sim.vvp | dirs
	$(VVP) sim.vvp +hex=$< +vcd=$@ +cycle_limit=$(CYCLE_LIMIT)

# Ensure OUT_DIR exists
dirs:
	@mkdir -p $(OUT_DIR)
	@mkdir -p $(HEX_DIR)

# Rules to produce .hex files in HEX_DIR
$(HEX_DIR)/%.hex: $(CPU_TESTS_DIR)/%.s $(ASSEMBLER) | dirs
	$(ASSEMBLER) $< -o $@

$(HEX_DIR)/%.hex: $(EMU_TESTS_DIR)/%.s $(ASSEMBLER) | dirs
	$(ASSEMBLER) $< -o $@ || true

# Run Verilog simulator (vvp) -> .vout
$(OUT_DIR)/%.vout: $(HEX_DIR)/%.hex sim.vvp | dirs
	$(VVP) sim.vvp +hex=$< +cycle_limit=$(CYCLE_LIMIT) \
		| sed '/^VCD info:/d;/\$$finish called/d' > $@

# Run Emulator -> .emuout
$(OUT_DIR)/%.emuout: $(HEX_DIR)/%.hex $(EMULATOR) | dirs
	$(EMULATOR) $(EMULATOR_ARGS) $< > $@

# Main test target
test: $(ASM_SRCS) $(VERILOG_SRCS) | dirs
	@GREEN="\033[0;32m"; \
	RED="\033[0;31m"; \
	YELLOW="\033[0;33m"; \
	NC="\033[0m"; \
	passed=0; total=$(TOTAL); \
	$(IVERILOG) -DSIMULATION -o sim.vvp $(wildcard $(SRC_DIR)/*.v) ; \
	echo "Running $(words $(EMU_TESTS_SRCS)) instruction tests:"; \
	for t in $(basename $(notdir $(EMU_TESTS_SRCS))); do \
	  printf "%s %-20s " '-' "$$t"; \
	  $(ASSEMBLER) $(EMU_TESTS_DIR)/$$t.s -o $(HEX_DIR)/$$t.hex -kernel && \
	  $(EMULATOR) $(EMULATOR_ARGS) $(HEX_DIR)/$$t.hex > $(OUT_DIR)/$$t.emuout && \
	  $(VVP) sim.vvp +hex=$(HEX_DIR)/$$t.hex +vcd=$(OUT_DIR)/$$t.vcd +cycle_limit=$(CYCLE_LIMIT) 2>/dev/null \
  		| sed '/^VCD info:/d;/\$$finish called/d' > $(OUT_DIR)/$$t.vout ; \
	  if cmp --silent $(OUT_DIR)/$$t.emuout $(OUT_DIR)/$$t.vout; then \
	    echo "$$GREEN PASS $$NC"; passed=$$((passed+1)); \
	  else \
	    echo "$$RED FAIL $$NC"; \
	  fi; \
	done; \
	echo; \
	echo "Running $(words $(CPU_TESTS_SRCS)) pipeline tests:"; \
	for t in $(basename $(notdir $(CPU_TESTS_SRCS))); do \
	  printf "%s %-20s " '-' "$$t"; \
	  $(ASSEMBLER) $(CPU_TESTS_DIR)/$$t.s -o $(HEX_DIR)/$$t.hex -kernel && \
	  $(EMULATOR) $(EMULATOR_ARGS) $(HEX_DIR)/$$t.hex > $(OUT_DIR)/$$t.emuout && \
	  $(VVP) sim.vvp +hex=$(HEX_DIR)/$$t.hex +vcd=$(OUT_DIR)/$$t.vcd +cycle_limit=$(CYCLE_LIMIT) 2>/dev/null \
		| sed '/^VCD info:/d;/\$$finish called/d' > $(OUT_DIR)/$$t.vout ; \
	  if cmp --silent $(OUT_DIR)/$$t.emuout $(OUT_DIR)/$$t.vout; then \
	    echo "$$GREEN PASS $$NC"; passed=$$((passed+1)); \
	  else \
	    echo "$$RED FAIL $$NC"; \
	  fi; \
	done; \
	echo; \
	echo "Summary: $$passed / $$total tests passed."

# Main test target
test-verilator: check-verilator-deps $(ASM_SRCS) $(VERILOG_SRCS) | dirs
	@GREEN="\033[0;32m"; \
	RED="\033[0;31m"; \
	YELLOW="\033[0;33m"; \
	NC="\033[0m"; \
	passed=0; total=$(TOTAL); \
	verilator --cc --exe --build $(VERILATOR_SRCS) \
    -CFLAGS "$(VERILATOR_CFLAGS)" -LDFLAGS "$(VERILATOR_LDFLAGS)" \
    -o dioptase; \
	echo "Running $(words $(EMU_TESTS_SRCS)) instruction tests:"; \
	for t in $(basename $(notdir $(EMU_TESTS_SRCS))); do \
	  printf "%s %-20s " '-' "$$t"; \
	  $(ASSEMBLER) $(EMU_TESTS_DIR)/$$t.s -o $(HEX_DIR)/$$t.hex -kernel && \
	  $(EMULATOR) $(EMULATOR_ARGS) $(HEX_DIR)/$$t.hex > $(OUT_DIR)/$$t.emuout && \
	  ./obj_dir/dioptase +hex=$(HEX_DIR)/$$t.hex --noinfo --max-cycles=$(CYCLE_LIMIT) 2>/dev/null | head -n 1 > $(OUT_DIR)/$$t.vout ; \
	  if cmp --silent $(OUT_DIR)/$$t.emuout $(OUT_DIR)/$$t.vout; then \
	    echo "$$GREEN PASS $$NC"; passed=$$((passed+1)); \
	  else \
	    echo "$$RED FAIL $$NC"; \
	  fi; \
	done; \
	echo; \
	echo "Running $(words $(CPU_TESTS_SRCS)) pipeline tests:"; \
	for t in $(basename $(notdir $(CPU_TESTS_SRCS))); do \
	  printf "%s %-20s " '-' "$$t"; \
	  $(ASSEMBLER) $(CPU_TESTS_DIR)/$$t.s -o $(HEX_DIR)/$$t.hex -kernel && \
	  $(EMULATOR) $(EMULATOR_ARGS) $(HEX_DIR)/$$t.hex > $(OUT_DIR)/$$t.emuout && \
	  ./obj_dir/dioptase +hex=$(HEX_DIR)/$$t.hex --noinfo --max-cycles=$(CYCLE_LIMIT) 2>/dev/null | head -n 1 > $(OUT_DIR)/$$t.vout ; \
	  if cmp --silent $(OUT_DIR)/$$t.emuout $(OUT_DIR)/$$t.vout; then \
	    echo "$$GREEN PASS $$NC"; passed=$$((passed+1)); \
	  else \
	    echo "$$RED FAIL $$NC"; \
	  fi; \
	done; \
	echo; \
	echo "Summary: $$passed / $$total tests passed."

.PHONY: test dirs clean

clean:
	rm -f $(OUT_DIR)/*
	rm -f $(HEX_DIR)/*
	rm -f sim.vvp
	rm -rf obj_dir
	rm -f cpu.vcd

.SECONDARY:
