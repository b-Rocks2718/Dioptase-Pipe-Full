`timescale 1ps/1ps

// Writeback stage.
//
// Purpose:
// - Select final GPR write values (ALU vs load result).
// - Apply byte/halfword lane extraction for subword loads.
// - Emit architectural control events (exception, rfe/rfi, halt, sleep).
//
// Invariants:
// - Exception slots suppress normal register writes.
// - Control events are only asserted for live (non-bubble) slots.
module writeback(input clk, input clk_en, input halt, input bubble_in, 
    input [4:0]tgt_in_1, input [4:0]tgt_in_2, 
    input is_load, input is_store,
    
    input [4:0]opcode, 
    input [31:0]alu_result_1, input [31:0]alu_result_2, input [31:0]mem_result, 
    input [31:0]addr,

    input [7:0]exc_in,
    input tgts_cr, input [4:0]priv_type, input [1:0]crmov_mode_type,

    output [31:0]result_out_1,
    output [31:0]result_out_2,
    
    output we1, output reg [4:0]wb_tgt_out_1, output reg [31:0]wb_result_out_1,
    output we2, output reg [4:0]wb_tgt_out_2, output reg [31:0]wb_result_out_2,
    output reg wb_tgts_cr_out,
    output exc_in_wb, output interrupt_in_wb, output rfe_in_wb, output rfi_in_wb,
    output tlb_exc_in_wb,
    output halt_out, output sleep_out
  );

  initial begin
    wb_tgt_out_1 = 5'd0;
    wb_tgt_out_2 = 5'd0;
    wb_tgts_cr_out = 1'b0;
  end

  reg [31:0]mem_result_buf;
  reg [31:0]addr_buf;

  assign exc_in_wb = (exc_in != 8'd0) && !bubble_in;
  assign interrupt_in_wb = (exc_in[7:4] == 4'hf) && !bubble_in;
  assign rfe_in_wb = opcode == 5'd31 && priv_type == 5'd3 && !bubble_in && !exc_in_wb;
  assign rfi_in_wb = rfe_in_wb && crmov_mode_type[1] == 1'b1 && !bubble_in && !exc_in_wb;
  assign tlb_exc_in_wb = exc_in_wb && (exc_in == 8'h82 || exc_in == 8'h83);
  
  assign halt_out = (opcode == 5'd31) && (priv_type == 5'd2) && (crmov_mode_type == 2'd2) && !bubble_in && !exc_in_wb;
  assign sleep_out = (opcode == 5'd31) && (priv_type == 5'd2) && (crmov_mode_type == 2'd1) && !bubble_in && !exc_in_wb;

  always @(posedge clk) begin
    if (~halt && clk_en) begin
      wb_tgt_out_1 <= tgt_in_1;
      wb_tgt_out_2 <= tgt_in_2;
      wb_result_out_1 <= result_out_1;
      wb_result_out_2 <= result_out_2;
      wb_tgts_cr_out <= tgts_cr && !bubble_in && !exc_in_wb;

      mem_result_buf <= mem_result;
      addr_buf <= addr;
    end
  end

  // Load lane extraction follows effective address byte offset.
  wire [31:0]masked_mem_result = 
    (5'd3 <= opcode && opcode <= 5'd5) ? mem_result :
    (5'd6 <= opcode && opcode <= 5'd8 && !addr[1] && !addr[0]) ? mem_result & 32'hffff :
    (5'd6 <= opcode && opcode <= 5'd8 && !addr[1] && addr[0]) ? (mem_result & 32'hffff00) >> 8 :
    (5'd6 <= opcode && opcode <= 5'd8 && addr[1]) ? mem_result >> 16 :
    (5'd9 <= opcode && opcode <= 5'd11 && !addr[0] && !addr[1]) ? mem_result & 32'hff :
    (5'd9 <= opcode && opcode <= 5'd11 && addr[0] && !addr[1]) ? (mem_result & 32'hff00) >> 8 :
    (5'd9 <= opcode && opcode <= 5'd11 && !addr[0] && addr[1]) ? (mem_result & 32'hff0000) >> 16 :
    (5'd9 <= opcode && opcode <= 5'd11 && addr[0] && addr[1]) ? (mem_result & 32'hff000000) >> 24 :
    32'h0;

  // Stores and immediate branches do not write GPR results.
  assign we1 = (tgt_in_1 != 0) && (!is_store && opcode != 5'd12) && !bubble_in && !tgts_cr && !exc_in_wb;
  assign we2 = (tgt_in_2 != 0) && (opcode != 5'd12) && !bubble_in && !exc_in_wb;
  
  assign result_out_1 = is_load ? masked_mem_result : alu_result_1;
  assign result_out_2 = alu_result_2;

endmodule
