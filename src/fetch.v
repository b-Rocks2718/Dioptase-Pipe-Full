`timescale 1ps/1ps

// Frontend stage 0: fetch address generation + redirect/replay control.
//
// Purpose:
// - Produce the instruction fetch address for memory/TLB lookup.
// - Emit the corresponding fetch PC and slot id into the frontend pipe.
// - Insert bubbles on redirects (branch/interrupt/rfe).
//
// Replay model:
// - The full pipeline has two registered frontend stages after this block.
// - When backend asserts `stall`, this block replays older PCs by stepping back
//   by 8 bytes, then emits one catch-up cycle at pc-4 on release.
// - Slot ids follow the same replay shape so downstream dedup sees replay copies
//   as older frontend work, not new instructions.
module tlb_fetch(input clk, input clk_en, input stall,
    input branch, input [31:0]branch_tgt, input interrupt, input [31:0]interrupt_vector,
    input rfe_in_wb, input [31:0]epc,
    output [31:0]fetch_addr, output reg [31:0]pc_out, output reg [31:0]slot_id_out,
    output reg bubble_out, output reg [7:0]exc_out
  );

  reg [31:0]pc;
  reg [31:0]slot_seq;
  reg was_stall_fetch;

  wire stall_fetch = stall && !interrupt && !rfe_in_wb;
  wire resume_after_stall = !stall_fetch && was_stall_fetch;

  // Full pipeline has one extra stage between fetch address generation and
  // decode consumption, so on a frontend stall we must back up by two words
  // to re-fetch the oldest in-flight instruction.
  //
  // On the first cycle after stall release, emit pc-4 once and hold `pc`.
  // Without this catch-up step, the stream jumps from replayed `pc-8` straight
  // to `pc`, which can skip one instruction word.
  assign fetch_addr = stall_fetch ? pc - 32'h8 :
                      resume_after_stall ? pc - 32'h4 :
                      pc;
  // Slot sequence follows the same replay shape as fetch_addr. During replay
  // we intentionally re-emit older slot ids, so downstream stages can drop
  // stale replays using monotonic slot ordering instead of payload matching.
  wire [31:0]fetch_slot_id = stall_fetch ? (slot_seq - 32'd2) :
                             resume_after_stall ? (slot_seq - 32'd1) :
                             slot_seq;

  initial begin
    bubble_out = 1;
    pc = 32'h00000400;
    slot_seq = 32'd0;
    slot_id_out = 32'd0;
    exc_out = 8'd0;
    was_stall_fetch = 1'b0;
  end

  always @(posedge clk) begin
    if (clk_en) begin
      if (!stall_fetch) begin
        pc <=
          interrupt ? interrupt_vector :
          rfe_in_wb ? epc :
          branch ? branch_tgt :
          resume_after_stall ? pc :
          pc + 4;
        slot_seq <= resume_after_stall ? slot_seq : (slot_seq + 32'd1);
        bubble_out <= rfe_in_wb || interrupt || branch;
        pc_out <= fetch_addr;
        slot_id_out <= fetch_slot_id;

        // misaligned pc exception
        exc_out <= (fetch_addr[1:0] != 2'b0) ? 8'h84 : 8'h0;
      end
      was_stall_fetch <= stall_fetch;
    end
  end
endmodule

module fetch_a(input clk, input clk_en, input stall, input flush, input bubble_in,
    input [31:0]pc_in, input [31:0]slot_id_in, input [7:0]exc_in, input [7:0]exc_tlb,
    output reg bubble_out, output reg [31:0]pc_out, output reg [31:0]slot_id_out, output reg [7:0]exc_out
  );

    // Frontend stage 1.
    // Registers fetch metadata so instruction-memory latency is absorbed
    // without reducing steady-state throughput.

    initial begin
      bubble_out = 1;
      exc_out = 8'd0;
    end

    always @(posedge clk) begin 
      if (clk_en) begin
        if (!stall) begin
          bubble_out <= flush ? 1 : bubble_in;
          pc_out <= pc_in;
          slot_id_out <= slot_id_in;
          exc_out <= (exc_in != 8'd0) ? exc_in : 
                      !bubble_in ? exc_tlb : 8'd0;
        end
      end
    end
endmodule

module fetch_b(input clk, input clk_en, input stall, input flush, input bubble_in,
    input [31:0]pc_in, input [31:0]slot_id_in, input [7:0]exc_in,
    output reg bubble_out, output reg [31:0]pc_out, output reg [31:0]slot_id_out, output reg [7:0]exc_out
  );

    // Frontend stage 2.
    // Keeps PC/slot/exception aligned with the instruction word presented to
    // decode on the same cycle.

    initial begin
      bubble_out = 1;
      exc_out = 8'd0;
    end

    always @(posedge clk) begin 
      if (clk_en) begin
        if (!stall) begin
          bubble_out <= flush ? 1 : bubble_in;
          pc_out <= pc_in;
          slot_id_out <= slot_id_in;
          exc_out <= exc_in;
        end
      end
    end
endmodule
