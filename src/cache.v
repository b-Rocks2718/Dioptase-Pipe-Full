
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
 */
module cache(
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
  localparam [2:0] STATE_IDLE = 3'd0;
  localparam [2:0] STATE_LOOKUP = 3'd1;
  localparam [2:0] STATE_WRITEBACK = 3'd2;
  localparam [2:0] STATE_REFILL = 3'd3;

  // Address decomposition for 27-bit physical addresses:
  // [26:14] tag, [13:6] set, [5:2] word-in-line, [1:0] byte.
  localparam integer LINE_WORDS = 16;
  localparam [3:0] LINE_LAST_WORD_IDX = 4'd15;

  reg evictee [0:255]; // next victim: 0 => way0, 1 => way1

  reg [511:0] way0 [0:255];
  reg valid0 [0:255];
  reg dirty0 [0:255];
  reg [12:0] tags0 [0:255];

  reg [511:0] way1 [0:255];
  reg valid1 [0:255];
  reg dirty1 [0:255];
  reg [12:0] tags1 [0:255];

  // Latched request.
  reg req_re;
  reg [3:0] req_we;
  reg [26:0] req_addr;
  reg [31:0] req_wdata;

  reg [2:0] state;
  reg victim_way;
  reg [12:0] victim_tag;
  reg victim_dirty;
  reg [511:0] victim_line;
  reg [511:0] refill_line;
  reg [3:0] burst_word_idx;
  reg beat_inflight;
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
  // - `word_idx` is in [0, 15] for a 64-byte line.
  // Postconditions:
  // - Returns the 32-bit word at `word_idx` from `line`.
  function [31:0] line_word_get;
    input [511:0] line;
    input [3:0] word_idx;
    begin
      line_word_get = line[{word_idx, 5'b0} +: 32];
    end
  endfunction

  // Preconditions:
  // - `word_idx` is in [0, 15] for a 64-byte line.
  // Postconditions:
  // - Returns `line` with word `word_idx` replaced by `word_data`.
  function [511:0] line_word_set;
    input [511:0] line;
    input [3:0] word_idx;
    input [31:0] word_data;
    reg [511:0] tmp;
    begin
      tmp = line;
      tmp[{word_idx, 5'b0} +: 32] = word_data;
      line_word_set = tmp;
    end
  endfunction

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
  reg [31:0] hit_word;
  reg [31:0] merged_word;
  reg [511:0] hit_line;
  reg [511:0] new_line;
  reg [511:0] completed_refill_line;
  reg [31:0] completed_word;
  reg selected_way;
  reg selected_dirty;
  reg [12:0] selected_tag;
  reg [511:0] selected_line;
  initial begin
    data_out = 32'd0;
    success = 1'b0;
    req_re = 1'b0;
    req_we = 4'd0;
    req_addr = 27'd0;
    req_wdata = 32'd0;
    state = STATE_IDLE;
    victim_way = 1'b0;
    victim_tag = 13'd0;
    victim_dirty = 1'b0;
    victim_line = 512'd0;
    refill_line = 512'd0;
    burst_word_idx = 4'd0;
    beat_inflight = 1'b0;
    success_pending = 1'b0;
    ram_req = 1'b0;
    ram_we = 1'b0;
    ram_be = 4'd0;
    ram_addr = 27'd0;
    ram_wdata = 32'd0;
    selected_way = 1'b0;
    selected_dirty = 1'b0;
    selected_tag = 13'd0;
    selected_line = 512'd0;

    for (i = 0; i < 256; i = i + 1) begin
      evictee[i] = 1'b0;
      way0[i] = 512'd0;
      valid0[i] = 1'b0;
      dirty0[i] = 1'b0;
      tags0[i] = 13'd0;
      way1[i] = 512'd0;
      valid1[i] = 1'b0;
      dirty1[i] = 1'b0;
      tags1[i] = 13'd0;
    end
  end

  always @(posedge clk) begin
    // Defaults: request pulses are one-cycle.
    // Response pulse is driven from `success_pending` to avoid same-edge
    // producer/consumer races on registered `data_out`.
    ram_req <= 1'b0;
    success <= success_pending;
    success_pending <= 1'b0;

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
          req_re <= re;
          req_we <= we;
          req_addr <= addr;
          req_wdata <= data;
          state <= STATE_LOOKUP;
        end
      end

      STATE_LOOKUP: begin
        if (lookup_hit) begin
          if (hit_way0) begin
            hit_line = way0[req_set];
            hit_word = line_word_get(hit_line, req_word);
            if (req_we_any) begin
              merged_word = merge_write_bytes(hit_word, req_wdata, req_we);
              new_line = line_word_set(hit_line, req_word, merged_word);
              way0[req_set] <= new_line;
              dirty0[req_set] <= 1'b1;
              data_out <= merged_word;
            end else begin
              data_out <= hit_word;
            end
            // Mark way1 as next victim (way0 most recently used).
            evictee[req_set] <= 1'b1;
          end else begin
            hit_line = way1[req_set];
            hit_word = line_word_get(hit_line, req_word);
            if (req_we_any) begin
              merged_word = merge_write_bytes(hit_word, req_wdata, req_we);
              new_line = line_word_set(hit_line, req_word, merged_word);
              way1[req_set] <= new_line;
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
          selected_way = 1'b0;
          selected_tag = 13'd0;
          selected_dirty = 1'b0;
          selected_line = 512'd0;
          if (!valid0[req_set]) begin
            selected_way = 1'b0;
            selected_tag = tags0[req_set];
            selected_dirty = 1'b0;
            selected_line = way0[req_set];
          end else if (!valid1[req_set]) begin
            selected_way = 1'b1;
            selected_tag = tags1[req_set];
            selected_dirty = 1'b0;
            selected_line = way1[req_set];
          end else if (!evictee[req_set]) begin
            selected_way = 1'b0;
            selected_tag = tags0[req_set];
            selected_dirty = dirty0[req_set];
            selected_line = way0[req_set];
          end else begin
            selected_way = 1'b1;
            selected_tag = tags1[req_set];
            selected_dirty = dirty1[req_set];
            selected_line = way1[req_set];
          end

          victim_way <= selected_way;
          victim_tag <= selected_tag;
          victim_dirty <= selected_dirty;
          victim_line <= selected_line;
          burst_word_idx <= 4'd0;
          beat_inflight <= 1'b0;
          refill_line <= 512'd0;

          if (!selected_dirty) begin
            state <= STATE_REFILL;
          end else begin
            state <= STATE_WRITEBACK;
          end
        end
      end

      STATE_WRITEBACK: begin
        // Write back one full cache line (16 words) before refill.
        if (!beat_inflight && !ram_busy) begin
          ram_req <= 1'b1;
          ram_we <= 1'b1;
          ram_be <= 4'b1111;
          ram_addr <= {victim_tag, req_set, burst_word_idx, 2'b00};
          ram_wdata <= line_word_get(victim_line, burst_word_idx);
          beat_inflight <= 1'b1;
`ifdef DEBUG
          if ($test$plusargs("cache_debug")) begin
            $display("[cache %m] wb issue set=%h tag=%h beat=%0d addr=%h wdata=%h",
              req_set, victim_tag, burst_word_idx, {victim_tag, req_set, burst_word_idx, 2'b00},
              line_word_get(victim_line, burst_word_idx));
          end
`endif
        end

        if (beat_inflight && ram_ready) begin
`ifdef DEBUG
          if ($test$plusargs("cache_debug")) begin
            $display("[cache %m] wb done set=%h tag=%h beat=%0d", req_set, victim_tag, burst_word_idx);
          end
`endif
          beat_inflight <= 1'b0;
          if (burst_word_idx == LINE_LAST_WORD_IDX) begin
            burst_word_idx <= 4'd0;
            state <= STATE_REFILL;
          end else begin
            burst_word_idx <= burst_word_idx + 1'b1;
          end
        end
      end

      STATE_REFILL: begin
        // Refill one full cache line from backing RAM.
        if (!beat_inflight && !ram_busy) begin
          ram_req <= 1'b1;
          ram_we <= 1'b0;
          ram_be <= 4'b0000;
          ram_addr <= {req_tag, req_set, burst_word_idx, 2'b00};
          ram_wdata <= 32'd0;
          beat_inflight <= 1'b1;
`ifdef DEBUG
          if ($test$plusargs("cache_debug")) begin
            $display("[cache %m] refill issue set=%h tag=%h beat=%0d addr=%h",
              req_set, req_tag, burst_word_idx, {req_tag, req_set, burst_word_idx, 2'b00});
          end
`endif
        end

        if (beat_inflight && ram_ready) begin
`ifdef DEBUG
          if ($test$plusargs("cache_debug")) begin
            $display("[cache %m] refill done set=%h tag=%h beat=%0d addr=%h rdata=%h",
              req_set, req_tag, burst_word_idx, {req_tag, req_set, burst_word_idx, 2'b00}, ram_rdata);
          end
`endif
          beat_inflight <= 1'b0;
          refill_line <= line_word_set(refill_line, burst_word_idx, ram_rdata);

          if (burst_word_idx == LINE_LAST_WORD_IDX) begin
            completed_refill_line = line_word_set(refill_line, burst_word_idx, ram_rdata);

            // Apply write-on-miss to the refilled line before installation.
            if (req_we_any) begin
              completed_word = line_word_get(completed_refill_line, req_word);
              completed_word = merge_write_bytes(completed_word, req_wdata, req_we);
              completed_refill_line = line_word_set(completed_refill_line, req_word, completed_word);
              data_out <= completed_word;
            end else begin
              data_out <= line_word_get(completed_refill_line, req_word);
            end

            if (!victim_way) begin
              way0[req_set] <= completed_refill_line;
              tags0[req_set] <= req_tag;
              valid0[req_set] <= 1'b1;
              dirty0[req_set] <= req_we_any;
            end else begin
              way1[req_set] <= completed_refill_line;
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
                req_we_any ? completed_word : line_word_get(completed_refill_line, req_word));
            end
`endif
            state <= STATE_IDLE;
            burst_word_idx <= 4'd0;
          end else begin
            burst_word_idx <= burst_word_idx + 1'b1;
          end
        end
      end

      default: begin
        state <= STATE_IDLE;
      end
    endcase
  end
endmodule
