`timescale 1ps/1ps

// Frontend stage 0: fetch address generation + redirect/issue-stop control.
//
// Purpose:
// - Produce the instruction fetch address for memory/TLB lookup.
// - Emit the corresponding fetch PC and slot id into the frontend pipe.
// - Insert bubbles on redirects (branch/interrupt/rfe).
//
// Issue-stop model:
// - During `stall`, this block holds architectural PC/slot state and emits
//   bubbles so downstream metadata stays aligned with any in-flight fetches.
// - Pairing/ordering is handled by the decode-side frontend queue.
module tlb_fetch(input clk, input clk_en, input stall, input issue_accept,
    input branch, input [31:0]branch_tgt, input interrupt, input [31:0]interrupt_vector,
    input rfe_in_wb, input [31:0]epc,
    output [31:0]fetch_addr, output reg [31:0]pc_out, output reg [31:0]slot_id_out,
    output reg bubble_out, output reg [7:0]exc_out
  );

  reg [31:0]pc;
  reg [31:0]slot_seq;
  wire issue_stop = stall && !interrupt && !rfe_in_wb;
  assign fetch_addr = pc;

  initial begin
    bubble_out = 1;
    pc = 32'h00000400;
    slot_seq = 32'd0;
    slot_id_out = 32'd0;
    exc_out = 8'd0;
    pc_out = 32'h00000400;
  end

  always @(posedge clk) begin
    if (clk_en) begin
      pc_out <= pc;
      slot_id_out <= slot_seq;
      if (interrupt) begin
        pc <= interrupt_vector;
        bubble_out <= 1'b1;
        exc_out <= 8'h0;
      end else if (rfe_in_wb) begin
        pc <= epc;
        bubble_out <= 1'b1;
        exc_out <= 8'h0;
      end else if (branch) begin
        pc <= branch_tgt;
        bubble_out <= 1'b1;
        exc_out <= 8'h0;
      end else if (issue_stop || !issue_accept) begin
        // Hold issue while backend/decode queue backpressure is active.
        // Also hold when mem.v rejected this fetch issue attempt so PC/slot
        // are retried instead of being dropped.
        bubble_out <= 1'b1;
        exc_out <= 8'h0;
      end else begin
        // misaligned pc exception for the instruction being issued this cycle
        exc_out <= (pc[1:0] != 2'b0) ? 8'h84 : 8'h0;
        bubble_out <= 1'b0;
        pc <= pc + 4;
        slot_seq <= slot_seq + 32'd1;
      end
    end
  end
endmodule

module fetch_a(input clk, input clk_en, input flush, input bubble_in,
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
        bubble_out <= flush ? 1 : bubble_in;
        pc_out <= pc_in;
        slot_id_out <= slot_id_in;
        exc_out <= (exc_in != 8'd0) ? exc_in : 
                    !bubble_in ? exc_tlb : 8'd0;
      end
    end
endmodule

module fetch_b(input clk, input clk_en, input flush, input bubble_in,
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
        bubble_out <= flush ? 1 : bubble_in;
        pc_out <= pc_in;
        slot_id_out <= slot_id_in;
        exc_out <= exc_in;
      end
    end
endmodule
