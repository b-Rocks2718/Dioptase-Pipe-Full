// Purpose: model SD DMA control/status sequencing and memory-side request strobes.
// Inputs:
// - mem_start_addr/sd_block_start_addr/num_blocks: programmed DMA parameters.
// - ctrl_data/ctrl_write: control register write; bit0 START, bit1 DIR, bit2 IRQ_EN, bit3 SD_INIT.
// - status_clear: clears sticky status fields.
// - mem_ready_set: handshake that one memory beat completed.
// - sd_ready_set: handshake that SD-side processing completed for init or one block.
// - sd_error_set/sd_error_code_in: SD-side failure completion for init or one block.
// - mem_data_in: memory read data for RAM->SD direction.
// - sd_data_block_in(+valid): completed 512-byte SD->RAM block from SPI side.
// Outputs:
// - ctrl/status/error_code: visible MMIO register state.
// - mem_request_*: memory-side request address/data and direction.
// - sd_data_block_out: current 512-byte RAM->SD staging block for SPI side.
// - waiting_for_sd_ready_out/init_waiting_for_sd_ready/current_sd_block_addr:
//   SD-side orchestration signals for an outer SPI controller.
// Invariants:
// - busy gates transfer progress; each accepted mem_ready_set advances one 32-bit beat.
// - SD->RAM waits for sd_ready_set before each 512-byte block is written to RAM.
// - RAM->SD waits for sd_ready_set after each 512-byte block is read from RAM.
// - mem_ready_set pulses observed during an SD-side stall are latched and replayed.
// - START is rejected until a successful SD_INIT completes.
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
  input sd_error_set,
  input [31:0] sd_error_code_in,
  input [31:0] mem_data_in,
  input [4095:0] sd_data_block_in,
  input sd_data_block_in_valid,
  output [31:0] ctrl,
  output [31:0] status,
  output reg [31:0] error_code,
  output [31:0] mem_request_addr_out,
  output [31:0] mem_request_data,
  output mem_request_read,
  output mem_request_write,
  output [4095:0] sd_data_block_out,
  output waiting_for_sd_ready_out,
  output init_waiting_for_sd_ready,
  output [31:0] current_sd_block_addr
);

  reg busy;
  reg done;
  reg error;
  reg sd_initialized;
  reg doing_init;
  reg waiting_for_sd_ready;
  reg mem_ready_pending;

  localparam [31:0] SD_DMA_ERR_BUSY = 32'd1;
  localparam [31:0] SD_DMA_ERR_ZERO_LEN = 32'd2;
  localparam [31:0] SD_DMA_ERR_NOT_INIT = 32'd3;
  // SD-side command/transfer failures are surfaced by the outer SPI glue.
  localparam [31:0] SD_DMA_ERR_SD_INIT_FAILED = 32'd4;
  localparam [31:0] SD_DMA_ERR_SD_READ_FAILED = 32'd5;
  localparam [31:0] SD_DMA_ERR_SD_WRITE_FAILED = 32'd6;
  localparam [31:0] WORDS_PER_BLOCK = 32'd128;  // 512 bytes / 4 bytes per beat
  localparam [6:0] BLOCK_LAST_WORD_INDEX = 7'd127;

  reg [31:0] ctrl_state;
  reg [31:0] mem_request_addr;
  reg [31:0] transfer_words_remaining;
  reg [31:0] block_index;

  reg [4095:0] data_buffer;  // One 512-byte SD block buffer (128 words).
  reg [6:0] buffer_index;  // 0..127 word index into the staging buffer.

  wire direction = ctrl_state[1];  // (0 = SD -> RAM, 1 = RAM -> SD)
  wire irq_en = ctrl_state[2];  // Interrupt enable

  // MMIO register mirrors.
  assign ctrl = ctrl_state;
  assign status = {29'b0, error, done, busy};
  assign waiting_for_sd_ready_out = busy && waiting_for_sd_ready;
  assign init_waiting_for_sd_ready = busy && doing_init && waiting_for_sd_ready;
  assign current_sd_block_addr = sd_block_start_addr + block_index;
  // Memory request address/data are always derived from the current transfer
  // cursor so each granted beat uses the intended word without one-beat lag.
  assign mem_request_addr_out = mem_request_addr;
  assign mem_request_data = data_buffer[{buffer_index, 5'b0} +: 32];
  assign sd_data_block_out = data_buffer;

  // Memory-side direction strobes.
  assign mem_request_read = busy && !doing_init && !waiting_for_sd_ready && (direction == 1);
  assign mem_request_write = busy && !doing_init && !waiting_for_sd_ready && (direction == 0);

  initial begin
    ctrl_state = 0;

    busy = 0;
    done = 0;
    error = 0;

    error_code = 0;
    sd_initialized = 0;
    doing_init = 0;

    mem_request_addr = 0;
    transfer_words_remaining = 0;
    block_index = 0;
    buffer_index = 0;
    waiting_for_sd_ready = 0;
    mem_ready_pending = 0;

    data_buffer = 4096'd0;
  end

  // Sequential transfer engine.
  // Preconditions:
  // - Caller drives ctrl_write with valid ctrl_data for register writes.
  // - Caller pulses mem_ready_set once per completed memory beat.
  // Postconditions:
  // - On START while idle, busy becomes 1 and transfer state resets.
  // - While busy and a memory beat is accepted, one beat is transferred and
  //   address increments by 4 in the same cycle as mem_ready_set.
  //   This avoids one-beat lag between request issue and DMA cursor update.
  // - At terminal beat, done is set and busy clears.
  reg consume_mem_beat;

  always @(posedge clk) begin
    consume_mem_beat = 1'b0;

    if (ctrl_write) begin
      // START and SD_INIT are self-clearing trigger bits; DIR/IRQ_EN are sticky policy bits.
      ctrl_state <= {29'b0, ctrl_data[2:1], 1'b0};

      if (ctrl_data[3]) begin
        // SD_INIT command.
        mem_ready_pending <= 0;
        if (busy) begin
          // Busy rejection is sticky ERR-only (DONE is not set by this path).
          error <= 1;
          error_code <= SD_DMA_ERR_BUSY;
        end else begin
          busy <= 1;
          done <= 0;
          error <= 0;
          error_code <= 0;
          doing_init <= 1;
          waiting_for_sd_ready <= 1;
          buffer_index <= 0;
          transfer_words_remaining <= 0;
          block_index <= 0;
        end
      end else if (ctrl_data[0]) begin
        // START command.
        mem_ready_pending <= 0;
        if (busy) begin
          // Busy rejection is sticky ERR-only (DONE is not set by this path).
          error <= 1;
          error_code <= SD_DMA_ERR_BUSY;
        end else if (!sd_initialized) begin
          busy <= 0;
          done <= 1;
          error <= 1;
          error_code <= SD_DMA_ERR_NOT_INIT;
          doing_init <= 0;
          waiting_for_sd_ready <= 0;
          transfer_words_remaining <= 0;
        end else begin
          // START while idle. Length is defined as a count of SD blocks.
          if (num_blocks == 0) begin
            busy <= 0;
            done <= 1;
            error <= 1;
            error_code <= SD_DMA_ERR_ZERO_LEN;
            doing_init <= 0;
            waiting_for_sd_ready <= 0;
            transfer_words_remaining <= 0;
          end else begin
            busy <= 1;
            error <= 0;
            done <= 0;
            error_code <= 0;
            doing_init <= 0;

            block_index <= 0;
            buffer_index <= 0;
            transfer_words_remaining <= num_blocks * WORDS_PER_BLOCK;
            mem_request_addr <= mem_start_addr;
            // SD->RAM must fetch a full SD block before issuing memory writes.
            waiting_for_sd_ready <= (ctrl_data[1] == 1'b0);
          end
        end
      end
    end

    if (sd_data_block_in_valid) begin
      data_buffer <= sd_data_block_in;
    end

    if (mem_ready_set) begin
      if (busy && !doing_init && !waiting_for_sd_ready) begin
        consume_mem_beat = 1'b1;
      end else begin
        mem_ready_pending <= 1'b1;
      end
    end
    if (sd_error_set && busy && waiting_for_sd_ready) begin
      // SD-side glue reports command/transfer failure for either SD_INIT or
      // a block transfer. Complete the operation with ERR so software does not
      // treat stale RAM contents as valid payload.
      busy <= 0;
      done <= 1;
      error <= 1;
      if (sd_error_code_in != 32'd0) begin
        error_code <= sd_error_code_in;
      end else if (doing_init) begin
        error_code <= SD_DMA_ERR_SD_INIT_FAILED;
      end else if (direction == 1'b0) begin
        error_code <= SD_DMA_ERR_SD_READ_FAILED;
      end else begin
        error_code <= SD_DMA_ERR_SD_WRITE_FAILED;
      end
      doing_init <= 0;
      waiting_for_sd_ready <= 0;
      transfer_words_remaining <= 0;
      buffer_index <= 0;
      mem_ready_pending <= 0;
    end else if (sd_ready_set && busy && waiting_for_sd_ready) begin
      if (doing_init) begin
        // SD init completes once SD-side glue reports completion.
        busy <= 0;
        done <= 1;
        error <= 0;
        error_code <= 0;
        doing_init <= 0;
        sd_initialized <= 1;
        waiting_for_sd_ready <= 0;
      end else begin
        if (direction == 1'b1 && transfer_words_remaining == 32'd0) begin
          // RAM->SD final block completes only after SD-side transfer finishes.
          busy <= 0;
          done <= 1;
          waiting_for_sd_ready <= 0;
        end else begin
          waiting_for_sd_ready <= 0;
          block_index <= block_index + 1'b1;
        end
      end
    end
    if (!consume_mem_beat && busy && !doing_init && !waiting_for_sd_ready && mem_ready_pending) begin
      consume_mem_beat = 1'b1;
      mem_ready_pending <= 1'b0;
    end

    if (status_clear) begin
      // Status clear only clears DONE/ERR and error code. BUSY is unaffected.
      error <= 0;
      done <= 0;
      error_code <= 0;
    end

    if (busy && !doing_init && !waiting_for_sd_ready && consume_mem_beat) begin
      if (direction == 0) begin
        // SD -> RAM: write data to memory.
        // For now, assuming data buffer has already been filled.
        buffer_index <= buffer_index + 1'b1;
        mem_request_addr <= mem_request_addr + 4;  // 32-bit words.
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
        data_buffer[{buffer_index, 5'b0} +: 32] <= mem_data_in;
        buffer_index <= buffer_index + 1'b1;
        mem_request_addr <= mem_request_addr + 4;  // 32-bit words.
        if (transfer_words_remaining == 32'd1) begin
          transfer_words_remaining <= 0;
          buffer_index <= 0;
          waiting_for_sd_ready <= 1;
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
