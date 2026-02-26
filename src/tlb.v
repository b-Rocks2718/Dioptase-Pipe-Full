`timescale 1ps/1ps

// Fully-associative TLB used by the full pipeline.
//
// Behavior summary:
// - `addr0` is instruction-side translation/permission check.
// - `addr1` is data-side translation/permission check (read or write).
// - `read_addr` is lookup key for tlbr/tlbw/tlbi control operations.
// - Permission faults return ISA exception 0x82/0x83 depending on mode.
module tlb(
  input clk, input clk_en,
  input kmode, input [31:0]pid,
  input [31:0]addr0, input [31:0]addr1, input [31:0]read_addr,
  input we, input [31:0]write_data, input invalidate, input [7:0]exc_in, input clear,
  input exc_commit,
  input addr1_read_req, input addr1_write_req,
  output reg [7:0]exc_out0, output reg [7:0]exc_out1,
  output reg [26:0]addr0_out, output reg [26:0]addr1_out,
  output reg [26:0]read_addr_out
);
  // Keep entry count explicit so scaling does not require width/loop rewrites.
  localparam integer TLB_ENTRIES = 16;
  localparam integer TLB_INDEX_W = 4;

  // TLB entry format (ISA-visible):
  //   key   = PID[31:0] + VPN[19:0]
  //   value = PPN[14:0] + FLAGS[11:0]
  // FLAGS low bits are G/U/X/W/R at [4:0].
  reg cache_valid[0:TLB_ENTRIES-1];
  reg [31:0]cache_pid[0:TLB_ENTRIES-1];
  reg [19:0]cache_vpn[0:TLB_ENTRIES-1];
  reg [26:0]cache_val[0:TLB_ENTRIES-1];

  reg [TLB_INDEX_W-1:0]eviction_tgt;
  // Sticky exception-vector selector for data port1.
  // This decouples vector fetch from one-cycle `exc_out1` transitions and
  // avoids redirecting data-side reads/writes away from their true address.
  reg [7:0]exc_vector_pending;
  integer i;

  initial begin
    for (i = 0; i < TLB_ENTRIES; i = i + 1) begin
      cache_valid[i] = 1'b0;
      cache_pid[i] = 32'd0;
      cache_vpn[i] = 20'd0;
      cache_val[i] = 27'd0;
    end
    eviction_tgt = {TLB_INDEX_W{1'b0}};
    exc_out0 = 8'd0;
    exc_out1 = 8'd0;
    exc_vector_pending = 8'd0;
    addr0_out = 27'd0;
    addr1_out = 27'd0;
    read_addr_out = 27'd0;
  end

  wire [19:0]vpn0 = addr0[31:12];
  wire [19:0]vpn1 = addr1[31:12];
  wire [19:0]vpn_read = read_addr[31:12];

  wire bypass_addr0 = kmode && (addr0[31:27] == 5'd0);
  wire bypass_addr1 = kmode && (addr1[31:27] == 5'd0);
  wire addr1_active = addr1_read_req || addr1_write_req;

  reg match0_hit;
  reg [26:0]match0_value;
  reg match1_hit;
  reg [26:0]match1_value;
  reg read_hit;
  reg [26:0]read_value;

  integer li;
  always @(*) begin
    // Match order mirrors emulator behavior:
    // 1) PID-private entries
    // 2) global entries for same VPN
    match0_hit = 1'b0;
    match0_value = 27'd0;
    match1_hit = 1'b0;
    match1_value = 27'd0;
    read_hit = 1'b0;
    read_value = 27'd0;

    for (li = 0; li < TLB_ENTRIES; li = li + 1) begin
      if (!match0_hit && cache_valid[li] && (cache_pid[li] == pid) && (cache_vpn[li] == vpn0)) begin
        match0_hit = 1'b1;
        match0_value = cache_val[li];
      end
      if (!match1_hit && cache_valid[li] && (cache_pid[li] == pid) && (cache_vpn[li] == vpn1)) begin
        match1_hit = 1'b1;
        match1_value = cache_val[li];
      end
      if (!read_hit && cache_valid[li] && (cache_pid[li] == pid) && (cache_vpn[li] == vpn_read)) begin
        read_hit = 1'b1;
        read_value = cache_val[li];
      end
    end

    for (li = 0; li < TLB_ENTRIES; li = li + 1) begin
      if (!match0_hit && cache_valid[li] && cache_val[li][4] && (cache_vpn[li] == vpn0)) begin
        match0_hit = 1'b1;
        match0_value = cache_val[li];
      end
      if (!match1_hit && cache_valid[li] && cache_val[li][4] && (cache_vpn[li] == vpn1)) begin
        match1_hit = 1'b1;
        match1_value = cache_val[li];
      end
      if (!read_hit && cache_valid[li] && cache_val[li][4] && (cache_vpn[li] == vpn_read)) begin
        read_hit = 1'b1;
        read_value = cache_val[li];
      end
    end
  end

  wire fetch_perm_ok = (kmode || match0_value[3]) && match0_value[2];
  wire fetch_fault = !bypass_addr0 && (!match0_hit || !fetch_perm_ok);

  wire data_perm_ok = addr1_write_req ? match1_value[1] : match1_value[0];
  wire data_user_ok = kmode || match1_value[3];
  wire data_fault = addr1_active && !bypass_addr1 &&
    (!match1_hit || !data_user_ok || !data_perm_ok);

  wire [7:0]exc0_next = fetch_fault ? (kmode ? 8'h83 : 8'h82) : 8'd0;
  wire [7:0]exc1_next = (exc_in != 8'd0) ? exc_in :
    (data_fault ? (kmode ? 8'h83 : 8'h82) : 8'd0);
  wire pending_vector_valid = (exc_vector_pending != 8'd0);
  // Exception vector fetch must win immediately when a trap appears on this
  // cycle (`exc1_next`), otherwise writeback can consume stale `mem_out_1` and
  // redirect to a non-IVT address.
  wire live_vector_valid = (exc1_next != 8'd0);
  wire [7:0]vector_code_now = live_vector_valid ? exc1_next : exc_vector_pending;
  wire use_exc_vector = live_vector_valid || pending_vector_valid;

  // Physical memory bus is 27-bit in this FPGA pipeline implementation.
  // ISA TLB value stores PPN[14:0] in value[26:12].
  wire [26:0]translated_addr0 = {match0_value[26:12], addr0[11:0]};
  wire [26:0]translated_addr1 = {match1_value[26:12], addr1[11:0]};

  wire [26:0]addr0_phys_next = bypass_addr0 ? addr0[26:0] :
    (match0_hit ? translated_addr0 : 27'd0);
  wire [26:0]addr1_phys_next = bypass_addr1 ? addr1[26:0] :
    (match1_hit ? translated_addr1 : addr1[26:0]);

  reg write_match_found;
  reg [TLB_INDEX_W-1:0]write_match_idx;
  always @(*) begin
    write_match_found = 1'b0;
    write_match_idx = {TLB_INDEX_W{1'b0}};

    // Global writes replace existing global VPN entries.
    // Private writes replace existing PID+VPN private entries.
    if (write_data[4]) begin
      for (li = 0; li < TLB_ENTRIES; li = li + 1) begin
        if (!write_match_found && cache_valid[li] && cache_val[li][4] &&
            (cache_vpn[li] == vpn_read)) begin
          write_match_found = 1'b1;
          write_match_idx = li[TLB_INDEX_W-1:0];
        end
      end
    end else begin
      for (li = 0; li < TLB_ENTRIES; li = li + 1) begin
        if (!write_match_found && cache_valid[li] && !cache_val[li][4] &&
            (cache_pid[li] == pid) && (cache_vpn[li] == vpn_read)) begin
          write_match_found = 1'b1;
          write_match_idx = li[TLB_INDEX_W-1:0];
        end
      end
    end
  end

  wire [TLB_INDEX_W-1:0]write_idx = write_match_found ? write_match_idx : eviction_tgt;

  always @(posedge clk) begin
    if (clk_en) begin
`ifdef SIMULATION
      if ($test$plusargs("tlb_debug")) begin
        if (we) begin
          $display("[tlb] write pid=%h vpn=%h val=%h idx=%0d repl=%b", pid, vpn_read, write_data[26:0], write_idx, !write_match_found);
        end
        if (invalidate) begin
          $display("[tlb] invalidate pid=%h vpn=%h", pid, vpn_read);
        end
        if (exc0_next != 8'd0 || exc1_next != 8'd0) begin
          $display("[tlb] fault exc0=%h exc1=%h kmode=%b pid=%h addr0=%h addr1=%h hit0=%b hit1=%b val0=%h val1=%h read_req=%b write_req=%b",
            exc0_next, exc1_next, kmode, pid, addr0, addr1, match0_hit, match1_hit, match0_value, match1_value,
            addr1_read_req, addr1_write_req);
        end
      end
`endif
      if (clear) begin
        for (i = 0; i < TLB_ENTRIES; i = i + 1) begin
          cache_valid[i] <= 1'b0;
        end
        eviction_tgt <= {TLB_INDEX_W{1'b0}};
        exc_vector_pending <= 8'd0;
      end else if (invalidate) begin
        // Match emulator invalidation behavior: invalidate PID+VPN private
        // entry and any global entry with the same VPN.
        for (i = 0; i < TLB_ENTRIES; i = i + 1) begin
          if (cache_valid[i] &&
              (cache_vpn[i] == vpn_read) &&
              (cache_val[i][4] || (cache_pid[i] == pid))) begin
            cache_valid[i] <= 1'b0;
          end
        end
      end else if (we) begin
        cache_valid[write_idx] <= 1'b1;
        cache_pid[write_idx] <= pid;
        cache_vpn[write_idx] <= vpn_read;
        cache_val[write_idx] <= write_data[26:0];
        if (!write_match_found) begin
          eviction_tgt <= eviction_tgt + 1'b1;
        end
      end

      // Capture any live exception code for vector lookup and hold it until
      // writeback consumes the trap. This prevents stale/non-vector addr1
      // selections on the exact trap-entry cycle.
      if (exc1_next != 8'd0) begin
        exc_vector_pending <= exc1_next;
      end else if (exc_commit) begin
        exc_vector_pending <= 8'd0;
      end

      exc_out0 <= exc0_next;
      exc_out1 <= exc1_next;
      addr0_out <= addr0_phys_next;
      addr1_out <= use_exc_vector ? {17'b0, vector_code_now, 2'b0} : addr1_phys_next;
      read_addr_out <= read_hit ? read_value : 27'd0;

    end
  end

endmodule
