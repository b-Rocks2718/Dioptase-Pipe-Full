// Purpose: model SD DMA control/status sequencing and memory-side request strobes.
// Inputs:
// - mem_start_addr/sd_block_start_addr/num_blocks: programmed DMA parameters.
// - ctrl_data/ctrl_write: control register write; bit0 START, bit1 DIR, bit2 IRQ_EN.
// - status_clear: clears sticky status fields.
// - mem_ready_set: handshake that one memory beat completed.
// - sd_ready_set: handshake that SD-side processing completed for the current block.
// - mem_data_in: memory read data for RAM->SD direction.
// Outputs:
// - ctrl/status/error_code: visible MMIO register state.
// - mem_request_*: memory-side request address/data and direction.
// Invariants:
// - busy gates transfer progress; each mem_ready_set advances one 32-bit beat.
// - after each 512-byte block, transfer progress stalls until sd_ready_set is pulsed.
// - mem_ready_set pulses observed during an SD-side stall are latched and replayed.
// - request direction signals are combinationally derived from busy + direction.
module sd_dma_controller(
  input clk,
  input [31:0] mem_start_addr,
  input [31:0] sd_block_start_addr,
  input [31:0] num_blocks,
  input [31:0] ctrl_data,
  input ctrl_write,
  input status_clear,
  input mem_ready_set,
  input sd_ready_set,
  input [31:0] mem_data_in,
  output [31:0] ctrl,
  output [31:0] status,
  output reg [31:0] error_code,
  output reg [31:0] mem_request_addr_out,
  output reg [31:0] mem_request_data,
  output mem_request_read,
  output mem_request_write
  // TODO: output commands to sd card
);

  reg busy;
  reg done;
  reg error;
  reg mem_ready;
  reg waiting_for_sd_ready;
  reg mem_ready_pending;

  localparam [31:0] SD_DMA_ERR_BUSY = 32'd1;
  localparam [31:0] SD_DMA_ERR_ZERO_LEN = 32'd2;
  localparam [31:0] WORDS_PER_BLOCK = 32'd128;  // 512 bytes / 4 bytes per beat
  localparam [6:0] BLOCK_LAST_WORD_INDEX = 7'd127;

  reg [31:0] ctrl_state;
  reg [31:0] mem_request_addr;
  reg [31:0] transfer_words_remaining;

  reg [31:0] data_buffer[0:127];  // One 512-byte SD block buffer (128 words).
  reg [6:0] buffer_index;  // 0..127 word index into the staging buffer.

  wire direction = ctrl_state[1];  // (0 = SD -> RAM, 1 = RAM -> SD)
  wire irq_en = ctrl_state[2];  // Interrupt enable

  // MMIO register mirrors.
  assign ctrl = ctrl_state;
  assign status = {29'b0, error, done, busy};

  // Memory-side direction strobes.
  assign mem_request_read = busy && (direction == 1);
  assign mem_request_write = busy && (direction == 0);

  initial begin
    ctrl_state = 0;

    busy = 0;
    done = 0;
    error = 0;

    error_code = 0;

    mem_request_addr = 0;
    mem_request_addr_out = 0;
    mem_request_data = 0;
    transfer_words_remaining = 0;
    buffer_index = 0;
    waiting_for_sd_ready = 0;
    mem_ready_pending = 0;

    mem_ready = 0;
  end

  // Sequential transfer engine.
  // Preconditions:
  // - Caller drives ctrl_write with valid ctrl_data for register writes.
  // - Caller pulses mem_ready_set once per completed memory beat.
  // Postconditions:
  // - On START while idle, busy becomes 1 and transfer state resets.
  // - While busy && mem_ready, one beat is transferred and address increments by 4.
  // - At terminal beat, done is set and busy clears.
  always @(posedge clk) begin
    if (ctrl_write) begin
      ctrl_state <= {29'b0, ctrl_data[2:1], 1'b0};
      if (ctrl_data[0]) begin
        // start command
        mem_ready <= 0;
        mem_ready_pending <= 0;
        if (busy) begin
          // If already busy, set error.
          error <= 1;
          error_code <= SD_DMA_ERR_BUSY;
        end else begin
          // START while idle. Length is defined as a count of SD blocks.
          if (num_blocks == 0) begin
            busy <= 0;
            done <= 1;
            error <= 1;
            error_code <= SD_DMA_ERR_ZERO_LEN;
          end else begin
            busy <= 1;
            error <= 0;
            done <= 0;
            error_code <= 0;

            buffer_index <= 0;
            transfer_words_remaining <= num_blocks * WORDS_PER_BLOCK;
            mem_request_addr <= mem_start_addr;
            mem_request_addr_out <= mem_start_addr;
            waiting_for_sd_ready <= 0;
          end
        end
      end
    end

    if (mem_ready_set) begin
      if (waiting_for_sd_ready) begin
        mem_ready_pending <= 1;
      end else begin
        mem_ready <= 1;
      end
    end
    if (sd_ready_set && busy && waiting_for_sd_ready) begin
      waiting_for_sd_ready <= 0;
    end
    if (busy && !waiting_for_sd_ready && mem_ready_pending) begin
      mem_ready <= 1;
      mem_ready_pending <= 0;
    end

    if (status_clear) begin
      // Status clear only clears DONE/ERR and error code. BUSY is unaffected.
      error <= 0;
      done <= 0;
      error_code <= 0;
    end

    if (busy && mem_ready && !waiting_for_sd_ready) begin
      mem_ready <= 0;
      if (direction == 0) begin
        // SD -> RAM: write data to memory.
        // For now, assuming data buffer has already been filled.
        mem_request_data <= data_buffer[buffer_index];
        buffer_index <= buffer_index + 1'b1;
        mem_request_addr <= mem_request_addr + 4;  // 32-bit words.
        mem_request_addr_out <= mem_request_addr;
        if (transfer_words_remaining == 32'd1) begin
          busy <= 0;
          done <= 1;
          transfer_words_remaining <= 0;
          waiting_for_sd_ready <= 0;
        end else begin
          transfer_words_remaining <= transfer_words_remaining - 1'b1;
          if (buffer_index == BLOCK_LAST_WORD_INDEX) begin
            buffer_index <= 0;
            waiting_for_sd_ready <= 1;
          end
        end
      end else begin
        // RAM -> SD: read data from memory.
        data_buffer[buffer_index] <= mem_data_in;
        buffer_index <= buffer_index + 1'b1;
        mem_request_addr <= mem_request_addr + 4;  // 32-bit words.
        mem_request_addr_out <= mem_request_addr;
        if (transfer_words_remaining == 32'd1) begin
          busy <= 0;
          done <= 1;
          transfer_words_remaining <= 0;
          waiting_for_sd_ready <= 0;
        end else begin
          transfer_words_remaining <= transfer_words_remaining - 1'b1;
          if (buffer_index == BLOCK_LAST_WORD_INDEX) begin
            buffer_index <= 0;
            waiting_for_sd_ready <= 1;
          end
        end
      end
    end
  end

endmodule
