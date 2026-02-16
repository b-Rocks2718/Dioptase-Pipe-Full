/*
 * 2-way set-associative write-back cache (32 KiB, 64-byte lines)
 *
 * Purpose:
 * - Provide a cache model with an external SRAM-like backing interface so
 *   higher-level modules can connect one or more caches to shared RAM.
 *
 * Inputs/outputs:
 * - Request: `re` for reads, `we` byte lanes for writes, `addr`, `data`.
 * - Response: `success` pulses high for one cycle when the request completes.
 *   For reads, `data_out` carries the returned word on that pulse.
 *
 * Invariants:
 * - One request in flight at a time.
 * - Cache line size is fixed at 64 bytes (16 words).
 * - Replacement policy is pseudo-LRU via per-set evictee bit.
 * - Cache data arrays are accessed only through synchronous per-way ports to
 *   match BRAM inference templates in FPGA synthesis.
 */
module cache #(
    parameter PRELOAD_ENABLE = 0
)(
    input wire clk,
    input wire [26:0] addr,
    input wire [31:0] data,
    input wire re,
    input wire [3:0] we,
    input wire inv_valid,
    input wire [26:0] inv_addr,
    output reg [31:0] data_out,
    output reg success,
    output reg ram_req,
    output reg ram_we,
    output reg [3:0] ram_be,
    output reg [26:0] ram_addr,
    output reg [31:0] ram_wdata,
    input wire [31:0] ram_rdata,
    input wire ram_ready,
    input wire ram_busy,
    input wire ram_error_oob
);
  localparam [3:0] STATE_IDLE            = 4'd0;
  localparam [3:0] STATE_LOOKUP_RD_REQ   = 4'd1;
  localparam [3:0] STATE_LOOKUP_RD_WAIT  = 4'd2;
  localparam [3:0] STATE_LOOKUP_RESP     = 4'd3;
  localparam [3:0] STATE_WRITEBACK_RD_REQ  = 4'd4;
  localparam [3:0] STATE_WRITEBACK_RD_WAIT = 4'd5;
  localparam [3:0] STATE_WRITEBACK_REQ     = 4'd6;
  localparam [3:0] STATE_WRITEBACK_WAIT    = 4'd7;
  localparam [3:0] STATE_REFILL_REQ      = 4'd8;
  localparam [3:0] STATE_REFILL_WAIT     = 4'd9;

  // Address decomposition for 27-bit physical addresses:
  // [26:14] tag, [13:6] set, [5:2] word-in-line, [1:0] byte.
  localparam integer LINE_WORDS = 16;
  localparam [3:0] LINE_LAST_WORD_IDX = 4'd15;
  localparam integer WAY_WORDS = 4096; // 256 sets * 16 words/line

  reg evictee [0:255]; // next victim: 0 => way0, 1 => way1

  // Cache data arrays. BRAM mapping depends on synchronous read/write template.
  (* ram_style = "block" *) reg [31:0] way0_words [0:WAY_WORDS-1];
  reg valid0 [0:255];
  reg dirty0 [0:255];
  reg [12:0] tags0 [0:255];
  reg [511:0] preload_way0 [0:255];
  reg [13:0] preload_tagv0 [0:255];

  (* ram_style = "block" *) reg [31:0] way1_words [0:WAY_WORDS-1];
  reg valid1 [0:255];
  reg dirty1 [0:255];
  reg [12:0] tags1 [0:255];
  reg [511:0] preload_way1 [0:255];
  reg [13:0] preload_tagv1 [0:255];

  // Per-way synchronous data-port controls.
  reg way0_re;
  reg way0_we;
  reg [11:0] way0_addr;
  reg [31:0] way0_wdata;
  reg [31:0] way0_q;

  reg way1_re;
  reg way1_we;
  reg [11:0] way1_addr;
  reg [31:0] way1_wdata;
  reg [31:0] way1_q;

  // Latched request.
  reg [3:0] req_we;
  reg [26:0] req_addr;
  reg [31:0] req_wdata;

  reg [3:0] state;
  reg victim_way;
  reg [12:0] victim_tag;
  reg [3:0] burst_word_idx;
  // Response handshake guard:
  // - `data_out` is registered on completion.
  // - `success` pulses one cycle later so external logic samples settled data.
  reg success_pending;

  wire req_we_any = req_we[0] | req_we[1] | req_we[2] | req_we[3];
  wire [12:0] req_tag = req_addr[26:14];
  wire [7:0] req_set = req_addr[13:6];
  wire [3:0] req_word = req_addr[5:2];
  wire [12:0] inv_tag = inv_addr[26:14];
  wire [7:0] inv_set = inv_addr[13:6];

  wire hit_way0 = valid0[req_set] && (tags0[req_set] == req_tag);
  wire hit_way1 = valid1[req_set] && (tags1[req_set] == req_tag);
  wire lookup_hit = hit_way0 || hit_way1;

  // Preconditions:
  // - `byte_en` lanes match little-endian byte order.
  // Postconditions:
  // - Returns merged write data for byte-enable store semantics.
  function [31:0] merge_write_bytes;
    input [31:0] old_word;
    input [31:0] new_word;
    input [3:0] byte_en;
    begin
      merge_write_bytes = old_word;
      if (byte_en[0]) merge_write_bytes[7:0] = new_word[7:0];
      if (byte_en[1]) merge_write_bytes[15:8] = new_word[15:8];
      if (byte_en[2]) merge_write_bytes[23:16] = new_word[23:16];
      if (byte_en[3]) merge_write_bytes[31:24] = new_word[31:24];
    end
  endfunction

  integer i;
  integer j;
  reg [31:0] hit_word;
  reg [31:0] merged_word;
  reg [31:0] completed_word;
  initial begin
    data_out = 32'd0;
    success = 1'b0;
    req_we = 4'd0;
    req_addr = 27'd0;
    req_wdata = 32'd0;
    state = STATE_IDLE;
    victim_way = 1'b0;
    victim_tag = 13'd0;
    burst_word_idx = 4'd0;
    success_pending = 1'b0;
    ram_req = 1'b0;
    ram_we = 1'b0;
    ram_be = 4'd0;
    ram_addr = 27'd0;
    ram_wdata = 32'd0;
    way0_re = 1'b0;
    way0_we = 1'b0;
    way0_addr = 12'd0;
    way0_wdata = 32'd0;
    way0_q = 32'd0;
    way1_re = 1'b0;
    way1_we = 1'b0;
    way1_addr = 12'd0;
    way1_wdata = 32'd0;
    way1_q = 32'd0;
    hit_word = 32'd0;
    merged_word = 32'd0;
    completed_word = 32'd0;

    for (i = 0; i < WAY_WORDS; i = i + 1) begin
      way0_words[i] = 32'd0;
      way1_words[i] = 32'd0;
    end
    for (i = 0; i < 256; i = i + 1) begin
      evictee[i] = 1'b0;
      valid0[i] = 1'b0;
      dirty0[i] = 1'b0;
      tags0[i] = 13'd0;
      valid1[i] = 1'b0;
      dirty1[i] = 1'b0;
      tags1[i] = 13'd0;
      preload_way0[i] = 512'd0;
      preload_way1[i] = 512'd0;
      preload_tagv0[i] = 14'd0;
      preload_tagv1[i] = 14'd0;
    end

    // Optional FPGA boot path:
    // - preload I-cache arrays directly from files generated from bios.hex.
    // - dcache instances keep PRELOAD_ENABLE=0 and remain cold at reset.
    if (PRELOAD_ENABLE) begin
`ifdef SYNTHESIS
      $readmemh("icache_way0.mem", preload_way0);
      $readmemh("icache_way1.mem", preload_way1);
      $readmemh("icache_tagv0.mem", preload_tagv0);
      $readmemh("icache_tagv1.mem", preload_tagv1);
`else
      $readmemh("./data/icache_way0.mem", preload_way0);
      $readmemh("./data/icache_way1.mem", preload_way1);
      $readmemh("./data/icache_tagv0.mem", preload_tagv0);
      $readmemh("./data/icache_tagv1.mem", preload_tagv1);
`endif
      for (i = 0; i < 256; i = i + 1) begin
        tags0[i] = preload_tagv0[i][12:0];
        valid0[i] = preload_tagv0[i][13];
        tags1[i] = preload_tagv1[i][12:0];
        valid1[i] = preload_tagv1[i][13];
        for (j = 0; j < LINE_WORDS; j = j + 1) begin
          way0_words[{i[7:0], j[3:0]}] = preload_way0[i][{j[3:0], 5'b0} +: 32];
          way1_words[{i[7:0], j[3:0]}] = preload_way1[i][{j[3:0], 5'b0} +: 32];
        end
      end
    end
  end

  // Way 0 data array port.
  // Invariant:
  // - Access is synchronous; read data appears on `way0_q` one cycle later.
  always @(posedge clk) begin
    if (way0_we) begin
      way0_words[way0_addr] <= way0_wdata;
    end
    if (way0_re) begin
      way0_q <= way0_words[way0_addr];
    end
  end

  // Way 1 data array port.
  // Invariant:
  // - Access is synchronous; read data appears on `way1_q` one cycle later.
  always @(posedge clk) begin
    if (way1_we) begin
      way1_words[way1_addr] <= way1_wdata;
    end
    if (way1_re) begin
      way1_q <= way1_words[way1_addr];
    end
  end

  always @(posedge clk) begin
    // Defaults: request pulses are one-cycle.
    // Response pulse is driven from `success_pending` to avoid same-edge
    // producer/consumer races on registered `data_out`.
    ram_req <= 1'b0;
    ram_we <= 1'b0;
    ram_be <= 4'b0000;
    ram_wdata <= 32'd0;
    success <= success_pending;
    success_pending <= 1'b0;

    way0_re <= 1'b0;
    way0_we <= 1'b0;
    way1_re <= 1'b0;
    way1_we <= 1'b0;

    // External coherency hook:
    // invalidate one line from this cache when DMA writes memory directly.
    if (inv_valid && state == STATE_IDLE) begin
      if (valid0[inv_set] && (tags0[inv_set] == inv_tag)) begin
        valid0[inv_set] <= 1'b0;
        dirty0[inv_set] <= 1'b0;
      end
      if (valid1[inv_set] && (tags1[inv_set] == inv_tag)) begin
        valid1[inv_set] <= 1'b0;
        dirty1[inv_set] <= 1'b0;
      end
    end

    if (ram_error_oob) begin
      $display("[cache] backing RAM out-of-bounds at addr=%h", ram_addr);
    end

    case (state)
      STATE_IDLE: begin
        // Accept new request only when idle.
        // The memory wrapper may hold re/we high until it observes `success`.
        // Mask request capture for one cycle after success to avoid re-latching
        // the just-completed transaction.
        if ((re || (|we)) && !success && !success_pending) begin
          req_we <= we;
          req_addr <= addr;
          req_wdata <= data;
          state <= STATE_LOOKUP_RD_REQ;
        end
      end

      STATE_LOOKUP_RD_REQ: begin
        // Issue synchronous read of candidate hit word from both ways.
        way0_addr <= {req_set, req_word};
        way0_re <= 1'b1;
        way1_addr <= {req_set, req_word};
        way1_re <= 1'b1;
        state <= STATE_LOOKUP_RD_WAIT;
      end

      STATE_LOOKUP_RD_WAIT: begin
        // One-cycle wait for registered BRAM read data.
        state <= STATE_LOOKUP_RESP;
      end

      STATE_LOOKUP_RESP: begin
        if (lookup_hit) begin
          if (hit_way0) begin
            hit_word = way0_q;
            if (req_we_any) begin
              merged_word = merge_write_bytes(hit_word, req_wdata, req_we);
              way0_addr <= {req_set, req_word};
              way0_wdata <= merged_word;
              way0_we <= 1'b1;
              dirty0[req_set] <= 1'b1;
              data_out <= merged_word;
            end else begin
              data_out <= hit_word;
            end
            // Mark way1 as next victim (way0 most recently used).
            evictee[req_set] <= 1'b1;
          end else begin
            hit_word = way1_q;
            if (req_we_any) begin
              merged_word = merge_write_bytes(hit_word, req_wdata, req_we);
              way1_addr <= {req_set, req_word};
              way1_wdata <= merged_word;
              way1_we <= 1'b1;
              dirty1[req_set] <= 1'b1;
              data_out <= merged_word;
            end else begin
              data_out <= hit_word;
            end
            // Mark way0 as next victim (way1 most recently used).
            evictee[req_set] <= 1'b0;
          end

          success_pending <= 1'b1;
          state <= STATE_IDLE;
        end else begin
          // Miss path:
          // - Prefer invalid way.
          // - Otherwise use per-set evictee bit.
          if (!valid0[req_set]) begin
            victim_way <= 1'b0;
            victim_tag <= tags0[req_set];
          end else if (!valid1[req_set]) begin
            victim_way <= 1'b1;
            victim_tag <= tags1[req_set];
          end else if (!evictee[req_set]) begin
            victim_way <= 1'b0;
            victim_tag <= tags0[req_set];
          end else begin
            victim_way <= 1'b1;
            victim_tag <= tags1[req_set];
          end

          burst_word_idx <= 4'd0;
          completed_word <= 32'd0;

          if (!valid0[req_set] || !valid1[req_set]) begin
            state <= STATE_REFILL_REQ;
          end else if (!evictee[req_set]) begin
            if (dirty0[req_set]) begin
              state <= STATE_WRITEBACK_RD_REQ;
            end else begin
              state <= STATE_REFILL_REQ;
            end
          end else begin
            if (dirty1[req_set]) begin
              state <= STATE_WRITEBACK_RD_REQ;
            end else begin
              state <= STATE_REFILL_REQ;
            end
          end
        end
      end

      STATE_WRITEBACK_RD_REQ: begin
        // Stage read of victim line word from cache data RAM.
        if (!ram_busy) begin
          if (!victim_way) begin
            way0_addr <= {req_set, burst_word_idx};
            way0_re <= 1'b1;
          end else begin
            way1_addr <= {req_set, burst_word_idx};
            way1_re <= 1'b1;
          end
          state <= STATE_WRITEBACK_RD_WAIT;
        end
      end

      STATE_WRITEBACK_RD_WAIT: begin
        // One-cycle wait for registered BRAM read data.
        state <= STATE_WRITEBACK_REQ;
      end

      STATE_WRITEBACK_REQ: begin
        // Issue one writeback beat to backing RAM.
        ram_req <= 1'b1;
        ram_we <= 1'b1;
        ram_be <= 4'b1111;
        ram_addr <= {victim_tag, req_set, burst_word_idx, 2'b00};
        ram_wdata <= !victim_way ? way0_q : way1_q;
        state <= STATE_WRITEBACK_WAIT;
`ifdef DEBUG
        if ($test$plusargs("cache_debug")) begin
          $display("[cache %m] wb issue set=%h tag=%h beat=%0d addr=%h wdata=%h",
            req_set, victim_tag, burst_word_idx, {victim_tag, req_set, burst_word_idx, 2'b00},
            !victim_way ? way0_q : way1_q);
        end
`endif
      end

      STATE_WRITEBACK_WAIT: begin
        if (ram_ready) begin
`ifdef DEBUG
          if ($test$plusargs("cache_debug")) begin
            $display("[cache %m] wb done set=%h tag=%h beat=%0d", req_set, victim_tag, burst_word_idx);
          end
`endif
          if (burst_word_idx == LINE_LAST_WORD_IDX) begin
            burst_word_idx <= 4'd0;
            state <= STATE_REFILL_REQ;
          end else begin
            burst_word_idx <= burst_word_idx + 1'b1;
            state <= STATE_WRITEBACK_RD_REQ;
          end
        end
      end

      STATE_REFILL_REQ: begin
        // Refill one cache-line beat from backing RAM.
        if (!ram_busy) begin
          ram_req <= 1'b1;
          ram_we <= 1'b0;
          ram_be <= 4'b0000;
          ram_addr <= {req_tag, req_set, burst_word_idx, 2'b00};
          ram_wdata <= 32'd0;
          state <= STATE_REFILL_WAIT;
`ifdef DEBUG
          if ($test$plusargs("cache_debug")) begin
            $display("[cache %m] refill issue set=%h tag=%h beat=%0d addr=%h",
              req_set, req_tag, burst_word_idx, {req_tag, req_set, burst_word_idx, 2'b00});
          end
`endif
        end
      end

      STATE_REFILL_WAIT: begin
        if (ram_ready) begin
`ifdef DEBUG
          if ($test$plusargs("cache_debug")) begin
            $display("[cache %m] refill done set=%h tag=%h beat=%0d addr=%h rdata=%h",
              req_set, req_tag, burst_word_idx, {req_tag, req_set, burst_word_idx, 2'b00}, ram_rdata);
          end
`endif
          merged_word = ram_rdata;
          if (req_we_any && (burst_word_idx == req_word)) begin
            merged_word = merge_write_bytes(ram_rdata, req_wdata, req_we);
          end

          if (!victim_way) begin
            way0_addr <= {req_set, burst_word_idx};
            way0_wdata <= merged_word;
            way0_we <= 1'b1;
          end else begin
            way1_addr <= {req_set, burst_word_idx};
            way1_wdata <= merged_word;
            way1_we <= 1'b1;
          end

          if (burst_word_idx == req_word) begin
            completed_word <= merged_word;
          end

          if (burst_word_idx == LINE_LAST_WORD_IDX) begin
            data_out <= (burst_word_idx == req_word) ? merged_word : completed_word;

            if (!victim_way) begin
              tags0[req_set] <= req_tag;
              valid0[req_set] <= 1'b1;
              dirty0[req_set] <= req_we_any;
            end else begin
              tags1[req_set] <= req_tag;
              valid1[req_set] <= 1'b1;
              dirty1[req_set] <= req_we_any;
            end

            // Installed way becomes most recently used.
            evictee[req_set] <= !victim_way;
            success_pending <= 1'b1;
`ifdef DEBUG
            if ($test$plusargs("cache_debug")) begin
              $display("[cache %m] install set=%h tag=%h victim_way=%0d req_word=%0d data_out=%h",
                req_set, req_tag, victim_way, req_word,
                (burst_word_idx == req_word) ? merged_word : completed_word);
            end
`endif
            state <= STATE_IDLE;
            burst_word_idx <= 4'd0;
          end else begin
            burst_word_idx <= burst_word_idx + 1'b1;
            state <= STATE_REFILL_REQ;
          end
        end
      end

      default: begin
        state <= STATE_IDLE;
      end
    endcase
  end
endmodule
