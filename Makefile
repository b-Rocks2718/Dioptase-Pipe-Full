# Directories
CPU_TESTS_DIR    := tests/asm
EMU_TESTS_DIR    := ../../Dioptase-Emulators/Dioptase-Emulator-Full/tests/asm
SRC_DIR      		 := src
HEX_DIR					 := tests/hex
OUT_DIR      		 := tests/out

# Tools
ASSEMBLER    := ../../Dioptase-Assembler/build/assembler
EMULATOR     := ../../Dioptase-Emulators/Dioptase-Emulator-Full/target/release/Dioptase-Emulator-Full
IVERILOG     := iverilog
VVP          := vvp

# All test sources
VERILOG_SRCS   := $(wildcard $(SRC_DIR)/*.v)
VERILATOR_EXCLUDE := $(SRC_DIR)/clock.v $(SRC_DIR)/dioptase.v
VERILATOR_SRCS := $(SRC_DIR)/dioptase.v $(filter-out $(VERILATOR_EXCLUDE), $(VERILOG_SRCS)) extern/vgasim/bench/cpp/vgasim.cpp sim_main.cpp
GTKMM_CFLAGS   := $(shell pkg-config --cflags gtkmm-3.0)
GTKMM_LIBS		 := $(shell pkg-config --libs gtkmm-3.0)

CPU_TESTS_SRCS   := $(wildcard $(CPU_TESTS_DIR)/*.s)
# some emu tests run forever and use i/o
EMU_TESTS_EXCLUDE := $(EMU_TESTS_DIR)/cdiv.s $(EMU_TESTS_DIR)/colors.s $(EMU_TESTS_DIR)/green.s $(EMU_TESTS_DIR)/sprite.s $(EMU_TESTS_DIR)/uart.s $(EMU_TESTS_DIR)/sleep.s $(EMU_TESTS_DIR)/ps2.s $(EMU_TESTS_DIR)/uart_rx.s
EMU_TESTS_SRCS := $(filter-out $(EMU_TESTS_EXCLUDE),$(wildcard $(EMU_TESTS_DIR)/*.s))
ASM_SRCS         := $(CPU_TESTS_SRCS) $(EMU_TESTS_SRCS)

HEXES        := $(patsubst %.s,$(HEX_DIR)/%.hex,$(notdir $(ASM_SRCS)))
EMUOUTS      := $(patsubst %.hex,$(OUT_DIR)/%.emuout,$(notdir $(HEXES)))
VOUTS        := $(patsubst %.hex,$(OUT_DIR)/%.vout,$(notdir $(HEXES)))
VCDS 				 := $(patsubst %.hex,$(OUT_DIR)/%.vcd,$(notdir $(HEXES)))

TOTAL            := $(words $(ASM_SRCS))

.PRECIOUS: %.hex %.vout %.emuout %.vcd

all: sim.vvp

# no idea why this doesnt work
verilator: $(VERILATOR_SRCS)
	verilator --cc --exe --build $(VERILATOR_SRCS) \
    --CFLAGS "$(GTKMM_CFLAGS)" --LDFLAGS "$(GTKMM_LIBS) -lpthread" \
    -o dioptase

# Compile Verilog into sim.vvp once
sim.vvp: $(wildcard $(SRC_DIR)/*.v)
	$(IVERILOG) -DSIMULATION -o sim.vvp $^

$(OUT_DIR)/%.vcd: $(HEX_DIR)/%.hex sim.vvp | dirs
	$(VVP) sim.vvp +hex=$< +vcd=$@

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
	$(VVP) sim.vvp +hex=$< > $@

# Run Emulator -> .emuout
$(OUT_DIR)/%.emuout: $(HEX_DIR)/%.hex $(EMULATOR) | dirs
	$(EMULATOR) $< > $@

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
	  $(ASSEMBLER) $(EMU_TESTS_DIR)/$$t.s -o $(HEX_DIR)/$$t.hex && \
	  $(EMULATOR) $(HEX_DIR)/$$t.hex > $(OUT_DIR)/$$t.emuout && \
	  $(VVP) sim.vvp +hex=$(HEX_DIR)/$$t.hex +vcd=$(OUT_DIR)/$$t.vcd 2>/dev/null \
  		| grep -v "VCD info:" > $(OUT_DIR)/$$t.vout ; \
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
	  $(ASSEMBLER) $(CPU_TESTS_DIR)/$$t.s -o $(HEX_DIR)/$$t.hex -nostart && \
	  $(EMULATOR) $(HEX_DIR)/$$t.hex > $(OUT_DIR)/$$t.emuout && \
	  $(VVP) sim.vvp +hex=$(HEX_DIR)/$$t.hex +vcd=$(OUT_DIR)/$$t.vcd 2>/dev/null \
  		| grep -v "VCD info:" > $(OUT_DIR)/$$t.vout ; \
	  if cmp --silent $(OUT_DIR)/$$t.emuout $(OUT_DIR)/$$t.vout; then \
	    echo "$$GREEN PASS $$NC"; passed=$$((passed+1)); \
	  else \
	    echo "$$RED FAIL $$NC"; \
	  fi; \
	done; \
	echo; \
	echo "Summary: $$passed / $$total tests passed."

# Main test target
test_verilator: $(ASM_SRCS) $(VERILOG_SRCS) | dirs
	@GREEN="\033[0;32m"; \
	RED="\033[0;31m"; \
	YELLOW="\033[0;33m"; \
	NC="\033[0m"; \
	passed=0; total=$(TOTAL); \
	verilator --cc --exe --build $(VERILATOR_SRCS) \
    --CFLAGS "$(GTKMM_CFLAGS)" --LDFLAGS "$(GTKMM_LIBS) -lpthread" \
    -o dioptase; \
	echo "Running $(words $(EMU_TESTS_SRCS)) instruction tests:"; \
	for t in $(basename $(notdir $(EMU_TESTS_SRCS))); do \
	  printf "%s %-20s " '-' "$$t"; \
	  $(ASSEMBLER) $(EMU_TESTS_DIR)/$$t.s -o $(HEX_DIR)/$$t.hex && \
	  $(EMULATOR) $(HEX_DIR)/$$t.hex > $(OUT_DIR)/$$t.emuout && \
	  ./obj_dir/dioptase +hex=$(HEX_DIR)/$$t.hex --noinfo 2>/dev/null | head -n 1 > $(OUT_DIR)/$$t.vout ; \
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
	  $(ASSEMBLER) $(CPU_TESTS_DIR)/$$t.s -o $(HEX_DIR)/$$t.hex -nostart && \
	  $(EMULATOR) $(HEX_DIR)/$$t.hex > $(OUT_DIR)/$$t.emuout && \
	  ./obj_dir/dioptase +hex=$(HEX_DIR)/$$t.hex --noinfo 2>/dev/null | head -n 1 > $(OUT_DIR)/$$t.vout ; \
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
