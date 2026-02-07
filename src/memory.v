`timescale 1ps/1ps

module memory(input clk, input clk_en, input halt,
    input bubble_in,
    input [4:0]opcode_in, input [4:0]tgt_in_1, input [4:0]tgt_in_2, 
    input [31:0]result_in_1, input [31:0]result_in_2,

    input [31:0]addr_in,

    input is_load, input is_store,

    input [31:0]exec_pc_out, input [7:0]exc_in,
    input tgts_cr, input [4:0]priv_type, input [1:0]crmov_mode_type,
    input [3:0]flags_in,
    input [31:0]op1, input [31:0]op2, input exc_in_wb, input rfe_in_wb,
    
    output reg [4:0]tgt_out_1, output reg [4:0]tgt_out_2,
    output reg [31:0]result_out_1, output reg [31:0]result_out_2,
    output reg [4:0]opcode_out, output reg [31:0]addr_out,
    output reg bubble_out,

    output reg is_load_out, output reg is_store_out,
    output reg [31:0]mem_pc_out, output reg [7:0]exc_out,
    output reg tgts_cr_out, output reg [4:0]priv_type_out, output reg [1:0]crmov_mode_type_out,
    output reg [3:0]flags_out,
    output reg [31:0]op1_out, output reg [31:0]op2_out
  );

  initial begin
    bubble_out = 1;
    tgt_out_1 = 5'd0;
    tgt_out_2 = 5'd0;

    exc_out = 8'd0;
  end

always @(posedge clk) begin
    if (clk_en) begin
      if (halt) begin
        tgt_out_1 <= 5'd0;
        tgt_out_2 <= 5'd0;
        opcode_out <= 5'd0;
        result_out_1 <= 32'd0;
        result_out_2 <= 32'd0;
        bubble_out <= 1'b1;
        addr_out <= 32'd0;

        mem_pc_out <= exec_pc_out;
        exc_out <= 8'd0;
        tgts_cr_out <= 1'b0;
        priv_type_out <= 5'd0;
        crmov_mode_type_out <= 2'd0;
        flags_out <= 4'd0;

        op1_out <= 32'd0;
        op2_out <= 32'd0;

        is_load_out <= 1'b0;
        is_store_out <= 1'b0;
      end else begin
        tgt_out_1 <= tgt_in_1;
        tgt_out_2 <= tgt_in_2;
        opcode_out <= opcode_in;
        result_out_1 <= result_in_1;
        result_out_2 <= result_in_2;
        bubble_out <= (exc_in_wb || rfe_in_wb || halt) ? 1 : bubble_in;
        addr_out <= addr_in;
  
        mem_pc_out <= exec_pc_out;
        exc_out <= bubble_in ? 8'h0 : exc_in;
        tgts_cr_out <= tgts_cr && !bubble_in;
        priv_type_out <= priv_type;
        crmov_mode_type_out <= crmov_mode_type;
        flags_out <= flags_in;
  
        op1_out <= op1;
        op2_out <= op2;
  
        is_load_out <= is_load;
        is_store_out <= is_store;
      end
    end
  end

endmodule
