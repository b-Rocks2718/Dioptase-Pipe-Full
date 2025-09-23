`timescale 1ps/1ps

module execute(input clk, input halt, 
    input bubble_in,
    input [4:0]opcode, input [4:0]s_1, input [4:0]s_2, input [4:0]cr_s,
    input [4:0]tgt_1, input [4:0]tgt_2, input [4:0]tgt_cr, 
    input [4:0]alu_op, input [31:0]imm, input [4:0]branch_code,
    
    input [4:0]mem_tgt_1, input [4:0]mem_tgt_2, input [4:0]mem_tgt_cr, 
    input [4:0]wb_tgt_1, input [4:0]wb_tgt_2, input [4:0]wb_tgt_cr,
    
    input [31:0]reg_out_1, input [31:0]reg_out_2, input [31:0]reg_out_cr,

    input [31:0]mem_result_out_1, input [31:0]mem_result_out_2,
    input [31:0]wb_result_out_1, input [31:0]wb_result_out_2,
    input mem_tgts_cr, input wb_tgts_cr,
    
    input [31:0]decode_pc_out,
    input [4:0]mem_opcode_out,

    input is_load, input is_store, input is_branch, input mem_bubble, input is_load_mem,
    input is_post_inc, input tgts_cr,
    input [4:0]priv_type, input [1:0]crmov_mode_type,
    input [7:0]exc_in, input exc_in_wb, input [31:0]flags_restore, input flags_we,
    input [31:0]tlb_read,

    output reg [31:0]result_1, output reg [31:0]result_2, output reg [31:0]result_cr,
    output [31:0]exc_addr, output [31:0]addr, output [31:0]store_data, output [3:0]we, output reg [31:0]addr_out,
    output reg [4:0]opcode_out, 
    output reg [4:0]tgt_out_1, output reg [4:0]tgt_out_2, output reg [4:0]tgt_out_cr,
    
    output reg bubble_out,
    output branch, output [31:0]branch_tgt,
    output [3:0]flags,

    output stall, 

    output reg is_load_out, output reg is_store_out, output reg was_misaligned,
    output reg tgts_cr_out, output reg [4:0]priv_type_out, output reg [1:0]crmov_mode_type_out,
    output reg [7:0]exc_out, output reg [31:0]pc_out,
    output reg [31:0]op1_out, output reg [31:0]op2_out
  );

  initial begin
    bubble_out = 1;
    tgt_out_1 = 5'd0;
    tgt_out_2 = 5'd0;
    reg_tgt_buf_a_1 = 5'd0;
    reg_tgt_buf_a_2 = 5'd0;
    reg_tgt_buf_b_1 = 5'd0;
    reg_tgt_buf_b_2 = 5'd0;
    tgts_cr_buf_a = 0;
    tgts_cr_buf_b = 0;

    exc_out <= 5'd0;
  end

  reg [4:0]reg_tgt_buf_a_1;
  reg [4:0]reg_tgt_buf_a_2;
  reg [4:0]reg_tgt_buf_b_1;
  reg [4:0]reg_tgt_buf_b_2;
  reg [31:0]reg_data_buf_a_1;
  reg [31:0]reg_data_buf_a_2;
  reg [31:0]reg_data_buf_b_1;
  reg [31:0]reg_data_buf_b_2;
  reg tgts_cr_buf_a;
  reg tgts_cr_buf_b;

  wire [31:0]op1;
  wire [31:0]op2;

  wire is_mem_w = (5'd3 <= opcode && opcode <= 5'd5);
  wire is_mem_d = (5'd6 <= opcode && opcode <= 5'd8);
  wire is_mem_b = (5'd9 <= opcode && opcode <= 5'd11);

  assign op1 = 
    (tgt_out_1 == s_1 && s_1 != 5'b0) ? result_1 :
    (tgt_out_2 == s_1 && s_1 != 5'b0) ? result_2 :
    (mem_tgt_1 == s_1 && s_1 != 5'b0) ? mem_result_out_1 : 
    (mem_tgt_2 == s_1 && s_1 != 5'b0) ? mem_result_out_2 : 
    (wb_tgt_1 == s_1 && s_1 != 5'b0) ? wb_result_out_1 :
    (wb_tgt_2 == s_1 && s_1 != 5'b0) ? wb_result_out_2 :
    (reg_tgt_buf_a_1 == s_1 && s_1 != 5'b0) ? reg_data_buf_a_1 :
    (reg_tgt_buf_a_2 == s_1 && s_1 != 5'b0) ? reg_data_buf_a_2 :
    (reg_tgt_buf_b_1 == s_1 && s_1 != 5'b0) ? reg_data_buf_b_1 :
    (reg_tgt_buf_b_2 == s_1 && s_1 != 5'b0) ? reg_data_buf_b_2 :
    reg_out_1;

  assign op2 = 
    (tgt_out_1 == s_2 && s_2 != 5'b0) ? result_1 :
    (tgt_out_2 == s_2 && s_2 != 5'b0) ? result_2 :
    (mem_tgt_1 == s_2 && s_2 != 5'b0) ? mem_result_out_1 : 
    (mem_tgt_2 == s_2 && s_2 != 5'b0) ? mem_result_out_2 : 
    (wb_tgt_1 == s_2 && s_2 != 5'b0) ? wb_result_out_1 :
    (wb_tgt_2 == s_2 && s_2 != 5'b0) ? wb_result_out_2 :
    (reg_tgt_buf_a_1 == s_2 && s_2 != 5'b0) ? reg_data_buf_a_1 :
    (reg_tgt_buf_a_2 == s_2 && s_2 != 5'b0) ? reg_data_buf_a_2 :
    (reg_tgt_buf_b_1 == s_2 && s_2 != 5'b0) ? reg_data_buf_b_1 :
    (reg_tgt_buf_b_2 == s_2 && s_2 != 5'b0) ? reg_data_buf_b_2 :
    reg_out_2;

  assign cr_op = 
    (tgt_out_1 == cr_s && tgts_cr_out) ? result_1 :
    (mem_tgt_1 == cr_s && mem_tgts_cr) ? mem_result_out_1 : 
    (wb_tgt_1 == cr_s && wb_tgts_cr) ? wb_result_out_1 :
    (reg_tgt_buf_a_1 == cr_s && tgts_cr_buf_a) ? reg_data_buf_a_1 :
    (reg_tgt_buf_b_1 == cr_s && tgts_cr_buf_b) ? reg_data_buf_b_1 :
    reg_out_cr;

  reg [31:0]addr_buf;
  reg [31:0]data_buf;

  wire is_misaligned = ( 
    (is_mem_d && addr[1] && addr[0]) ||
    (is_mem_w && (addr[1] || addr[0]))
  ) && !bubble_in && !was_misaligned;

  assign stall = 
   // dependencies on a lw can cause stalls
   ((((tgt_out_1 == s_1 ||
     tgt_out_1 == s_2) &&
     tgt_out_1 != 5'd0) || 
     ((tgt_out_2 == s_1 ||
     tgt_out_2 == s_2) &&
     tgt_out_2 != 5'd0)) &&
     is_load_out && 
     !bubble_in && !bubble_out) ||
  ((((mem_tgt_1 == s_1 ||
     mem_tgt_1 == s_2) &&
     mem_tgt_1 != 5'd0) || 
     ((mem_tgt_2 == s_1 ||
     mem_tgt_2 == s_2) &&
     mem_tgt_2 != 5'd0)) &&
     is_load_mem &&
     !bubble_in && !mem_bubble) ||
    // misaligned memory can cause stalls
    is_misaligned;

  // nonsense to make subtract immediate work how i want
  wire [31:0]lhs = (opcode == 5'd1 && alu_op == 5'd16) ? imm : op1;
  wire [31:0]rhs = ((opcode == 5'd1 && alu_op != 5'd16) || (opcode == 5'd2) || (5'd3 <= opcode && opcode <= 5'd11)) ? 
                    imm : (opcode == 5'd1 && alu_op == 5'd16) ? op1 : op2;

  // memory stuff
  assign store_data = 
    is_mem_w ? (
      was_misaligned ? (
        (!addr_buf[1] && !addr_buf[0]) ? 32'h0 :
        (!addr_buf[1] && addr_buf[0]) ? (op2 >> 24) :
        (addr_buf[1] && !addr_buf[0]) ? (op2 >> 16) :
        (addr_buf[1] && addr_buf[0]) ? (op2 >> 8) :
        32'h0
      ) : (
        (!addr[1] && !addr[0]) ? op2 :
        (!addr[1] && addr[0]) ? (op2 << 8) :
        (addr[1] && !addr[0]) ? (op2 << 16) :
        (addr[1] && addr[0]) ? (op2 << 24) :
        32'h0
      )
    ) :
    is_mem_d ? (
      was_misaligned ? (
        (!addr_buf[1] && !addr_buf[0]) ? 32'h0 :
        (!addr_buf[1] && addr_buf[0]) ? 32'h0 :
        (addr_buf[1] && !addr_buf[0]) ? 32'h0 :
        (addr_buf[1] && addr_buf[0]) ? ((op2 & 32'hffff) >> 8) :
        32'h0
      ) : (
        (!addr[1] && !addr[0]) ? (op2 & 32'hffff) :
        (!addr[1] && addr[0]) ? ((op2 & 32'hffff) << 8) :
        (addr[1] && !addr[0]) ? ((op2 & 32'hffff) << 16) :
        (addr[1] && addr[0]) ? ((op2 & 32'hffff) << 24) :
        32'h0
      )
    ) :
    is_mem_b ? (
      (!addr[1] && !addr[0]) ? (op2 & 32'hff) :
      (!addr[1] && addr[0]) ? ((op2 & 32'hff) << 8) :
      (addr[1] && !addr[0]) ? ((op2 & 32'hff) << 16) :
      (addr[1] && addr[0]) ? ((op2 & 32'hff) << 24) :
      32'h0
    ) :
    32'h0;

  wire we_bit = is_store && !bubble_in && !exc_in_wb && !exc_out && (!stall || is_misaligned);

  assign we = 
    is_mem_w ? (
      was_misaligned ? (
        (!addr_buf[1] && !addr_buf[0]) ? 4'b0 :
        (!addr_buf[1] && addr_buf[0]) ? {3'b0, we_bit} :
        (addr_buf[1] && !addr_buf[0]) ? {2'b0, {2{we_bit}}} :
        (addr_buf[1] && addr_buf[0]) ? {1'b0, {3{we_bit}}} :
        4'h0
      ) : (
        (!addr[1] && !addr[0]) ? {4{we_bit}} :
        (!addr[1] && addr[0]) ? {{3{we_bit}}, 1'b0} :
        (addr[1] && !addr[0]) ? {{2{we_bit}}, 2'b0} :
        (addr[1] && addr[0]) ? {we_bit, 3'b0} :
        4'h0
      )
    ) : 
    is_mem_d ? (
      was_misaligned ? (
        (!addr_buf[1] && !addr_buf[0]) ? 4'b0 :
        (!addr_buf[1] && addr_buf[0]) ? 4'b0 :
        (addr_buf[1] && !addr_buf[0]) ? 4'b0 :
        (addr_buf[1] && addr_buf[0]) ? {3'b0, we_bit} :
        4'h0
      ) : (
        (!addr[1] && !addr[0]) ? {2'b0, {2{we_bit}}} :
        (!addr[1] && addr[0]) ? {1'b0, {2{we_bit}}, 1'b0} :
        (addr[1] && !addr[0]) ? {{2{we_bit}}, 2'b0} :
        (addr[1] && addr[0]) ? {we_bit, 3'b0} :
        4'h0
      )
    ) :
    is_mem_b ? (
      (!addr[1] && !addr[0]) ? {3'b0, we_bit} :
      (!addr[1] && addr[0]) ? {2'b0, we_bit, 1'b0} :
      (addr[1] && !addr[0]) ? {1'b0, we_bit, 2'b0} :
      (addr[1] && addr[0]) ? {we_bit, 3'b0} :
      4'h0
    ) :
    4'h0;

  assign addr = was_misaligned ? addr_buf : 
    (opcode == 5'd3 || opcode == 5'd6 || opcode == 5'd9) ? (is_post_inc ? op1 : alu_rslt) : // absolute mem
    (opcode == 5'd4 || opcode == 5'd7 || opcode == 5'd10) ? alu_rslt + decode_pc_out + 32'h4 : // relative mem
    (opcode == 5'd5 || opcode == 5'd8 || opcode == 5'd11) ? alu_rslt + decode_pc_out + 32'h4 : // relative immediate mem
    32'h0;

  wire [31:0]alu_rslt;
  ALU ALU(clk, opcode, alu_op, lhs, rhs, bubble_in, 
    flags_restore, flags_we,
    alu_rslt, flags);

  always @(posedge clk) begin
    if (~halt) begin
                  // jump and link
      result_1 <= (opcode == 5'd13 || opcode == 5'd14) ? decode_pc_out + 32'd4 : 
                  // crmov reading from control reg
                  (opcode == 5'd31 && priv_type == 5'd1 && crmov_mode_type <= 2'd1) ? reg_out_cr :
                  // tlbr
                  (opcode == 5'd31 && priv_type == 5'd0 && crmov_mode_type == 2'd0) ? tlb_read :
                  // everything else
                  alu_rslt;

      result_2 <= alu_rslt;
      tgt_out_1 <= (exc_in_wb || stall) ? 5'd0 : tgt_1;
      tgt_out_2 <= (exc_in_wb || stall) ? 5'd0 : tgt_2;
      opcode_out <= opcode;
      bubble_out <= (exc_in_wb || (stall && !is_misaligned)) ? 1 : bubble_in;

      addr_out <= addr;
      
      was_misaligned <= is_misaligned;
      addr_buf <= addr + 32'h4;
      data_buf <= store_data;

      is_load_out <= is_load;
      is_store_out <= is_store;
      tgts_cr_out <= tgts_cr;
      priv_type_out <= priv_type;
      crmov_mode_type_out <= crmov_mode_type;

      exc_out <= exc_in;

      pc_out <= decode_pc_out;
      op1_out <= op1;
      op2_out <= op2;

      if (stall) begin
        reg_tgt_buf_a_1 <= stall ? wb_tgt_1 : 0;
        reg_tgt_buf_a_2 <= stall ? wb_tgt_2 : 0;
        reg_data_buf_a_1 <= wb_result_out_1;
        reg_data_buf_a_2 <= wb_result_out_2;
        tgts_cr_buf_a <= wb_tgts_cr;
        reg_tgt_buf_b_1 <= stall ? reg_tgt_buf_a_1 : 0;
        reg_tgt_buf_b_2 <= stall ? reg_tgt_buf_a_2 : 0;
        reg_data_buf_b_1 <= reg_data_buf_a_1;
        reg_data_buf_b_2 <= reg_data_buf_a_2;
        tgts_cr_buf_b <= tgts_cr_buf_a;
      end
    end
  end

  wire taken;
  assign taken = (branch_code == 5'd0) ? 1 : // br
                 (branch_code == 5'd1) ? flags[1] : // bz
                 (branch_code == 5'd2) ? !flags[1] : // bnz
                 (branch_code == 5'd3) ? flags[2] : // bs
                 (branch_code == 5'd4) ? !flags[2] : // bns
                 (branch_code == 5'd5) ? flags[0] : // bc
                 (branch_code == 5'd6) ? !flags[0] : // bnc
                 (branch_code == 5'd7) ? flags[3] : // bo
                 (branch_code == 5'd8) ? !flags[3] : // bno
                 (branch_code == 5'd9) ? !flags[1] && !flags[2] : // bps
                 (branch_code == 5'd10) ? flags[1] || flags[2] : // bnps
                 (branch_code == 5'd11) ? flags[2] == flags[3] && !flags[1] : // bg
                 (branch_code == 5'd12) ? flags[2] == flags[3] : // bge
                 (branch_code == 5'd13) ? flags[2] != flags[3] && !flags[1] : // bl
                 (branch_code == 5'd14) ? flags[2] != flags[3] || flags[1] : // ble
                 (branch_code == 5'd15) ? !flags[1] && flags[0] : // ba
                 (branch_code == 5'd16) ? flags[0] || flags[1] : // bae
                 (branch_code == 5'd17) ? !flags[0] && !flags[1] : // bb
                 (branch_code == 5'd18) ? !flags[0] || flags[1] : // bbe
                 0;

  assign branch = !bubble_in && !exc_in_wb && taken && is_branch;
  
  assign branch_tgt = 
            (opcode == 5'd12) ? decode_pc_out + imm + 32'h4 :
            (opcode == 5'd13) ? op1 :
            (opcode == 5'd14) ? decode_pc_out + op1 + 32'h4 : 
            decode_pc_out + 32'h4;

endmodule