`timescale 1ps/1ps

module execute(input clk, input clk_en, input halt, 
    input bubble_in,
    input [4:0]opcode, input [4:0]s_1, input [4:0]s_2, input [4:0]cr_s,
    input [4:0]tgt_1, input [4:0]tgt_2, 
    input [4:0]alu_op, input [31:0]imm, input [4:0]branch_code,

    input [4:0]tlb_mem_tgt_1, input [4:0]tlb_mem_tgt_2,
    input [4:0]mem_a_tgt_1, input [4:0]mem_a_tgt_2,
    input [4:0]mem_b_tgt_1, input [4:0]mem_b_tgt_2,
    input [4:0]wb_tgt_1, input [4:0]wb_tgt_2,
    
    input [31:0]reg_out_1, input [31:0]reg_out_2, input [31:0]reg_out_cr,

    input [31:0]tlb_mem_result_out_1, input [31:0]tlb_mem_result_out_2,
    input [31:0]mem_a_result_out_1, input [31:0]mem_a_result_out_2,
    input [31:0]mem_b_result_out_1, input [31:0]mem_b_result_out_2,
    input [31:0]wb_result_out_1, input [31:0]wb_result_out_2,
    input mem_a_tgts_cr, input mem_b_tgts_cr, input wb_tgts_cr,
    
    input [31:0]decode_pc_out,
    input [4:0]mem_a_opcode_out,
    input [4:0]mem_b_opcode_out,

    input is_load, input is_store, input is_branch, 
    input tlb_mem_bubble, input tlb_mem_is_load,
    input mem_a_bubble, input mem_a_load, 
    input mem_b_bubble, input mem_b_load,
    input is_post_inc, input tgts_cr,
    input [4:0]priv_type, input [1:0]crmov_mode_type,
    input [7:0]exc_in, input exc_in_wb, input [31:0]flags_restore, input rfe_in_wb,

    output reg [31:0]result_1, output reg [31:0]result_2,
    output reg [31:0]addr, output reg mem_re, output reg [31:0]store_data, output reg [3:0]we,
    output reg [4:0]opcode_out, 
    output reg [4:0]tgt_out_1, output reg [4:0]tgt_out_2,
    
    output reg bubble_out,
    output branch, output [31:0]branch_tgt,
    output [3:0]flags, output reg [3:0]flags_out,

    output stall,

    output reg is_load_out, output reg is_store_out, output reg is_tlbr_out,
    output reg tgts_cr_out, output reg [4:0]priv_type_out, output reg [1:0]crmov_mode_type_out,
    output reg [7:0]exc_out, output reg [31:0]pc_out,
    output [31:0]op1, output [31:0]op2,
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
    reg_data_buf_a_1 = 32'd0;
    reg_data_buf_a_2 = 32'd0;
    reg_data_buf_b_1 = 32'd0;
    reg_data_buf_b_2 = 32'd0;
    result_1 = 32'd0;
    result_2 = 32'd0;
    addr = 32'd0;
    mem_re = 1'b0;
    store_data = 32'd0;
    we = 4'd0;
    opcode_out = 5'd0;
    flags_out = 4'd0;
    is_load_out = 1'b0;
    is_store_out = 1'b0;
    is_tlbr_out = 1'b0;
    tgts_cr_out = 1'b0;
    priv_type_out = 5'd0;
    crmov_mode_type_out = 2'd0;
    exc_out = 8'd0;
    pc_out = 32'd0;
    op1_out = 32'd0;
    op2_out = 32'd0;
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

  wire is_mem_w = (5'd3 <= opcode && opcode <= 5'd5);
  wire is_mem_d = (5'd6 <= opcode && opcode <= 5'd8);
  wire is_mem_b = (5'd9 <= opcode && opcode <= 5'd11);

  assign op1 = 
    (tgt_out_1 == s_1 && s_1 != 5'b0) ? result_1 :
    (tgt_out_2 == s_1 && s_1 != 5'b0) ? result_2 :
    (tlb_mem_tgt_1 == s_1 && s_1 != 5'b0) ? tlb_mem_result_out_1 :
    (tlb_mem_tgt_2 == s_1 && s_1 != 5'b0) ? tlb_mem_result_out_2 :
    (mem_a_tgt_1 == s_1 && s_1 != 5'b0) ? mem_a_result_out_1 : 
    (mem_a_tgt_2 == s_1 && s_1 != 5'b0) ? mem_a_result_out_2 : 
    (mem_b_tgt_1 == s_1 && s_1 != 5'b0) ? mem_b_result_out_1 :
    (mem_b_tgt_2 == s_1 && s_1 != 5'b0) ? mem_b_result_out_2 :
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
    (tlb_mem_tgt_1 == s_2 && s_2 != 5'b0) ? tlb_mem_result_out_1 :
    (tlb_mem_tgt_2 == s_2 && s_2 != 5'b0) ? tlb_mem_result_out_2 :
    (mem_a_tgt_1 == s_2 && s_2 != 5'b0) ? mem_a_result_out_1 : 
    (mem_a_tgt_2 == s_2 && s_2 != 5'b0) ? mem_a_result_out_2 : 
    (mem_b_tgt_1 == s_2 && s_2 != 5'b0) ? mem_b_result_out_1 :
    (mem_b_tgt_2 == s_2 && s_2 != 5'b0) ? mem_b_result_out_2 :
    (wb_tgt_1 == s_2 && s_2 != 5'b0) ? wb_result_out_1 :
    (wb_tgt_2 == s_2 && s_2 != 5'b0) ? wb_result_out_2 :
    (reg_tgt_buf_a_1 == s_2 && s_2 != 5'b0) ? reg_data_buf_a_1 :
    (reg_tgt_buf_a_2 == s_2 && s_2 != 5'b0) ? reg_data_buf_a_2 :
    (reg_tgt_buf_b_1 == s_2 && s_2 != 5'b0) ? reg_data_buf_b_1 :
    (reg_tgt_buf_b_2 == s_2 && s_2 != 5'b0) ? reg_data_buf_b_2 :
    reg_out_2;

  // TODO: account for cr mov instructions
  assign stall = !exc_in_wb && !rfe_in_wb && (
   // Dependencies on a load or tlbr must stall until a forwardable value exists.
   // With the dedicated tlb_memory stage, load data is not available until writeback.
   ((((tgt_out_1 == s_1 ||
     tgt_out_1 == s_2) &&
     tgt_out_1 != 5'd0) || 
     ((tgt_out_2 == s_1 ||
     tgt_out_2 == s_2) &&
     tgt_out_2 != 5'd0)) &&
     (is_load_out || is_tlbr_out) && 
     !bubble_in && !bubble_out) ||
  ((((tlb_mem_tgt_1 == s_1 ||
     tlb_mem_tgt_1 == s_2) &&
     tlb_mem_tgt_1 != 5'd0) ||
     ((tlb_mem_tgt_2 == s_1 ||
     tlb_mem_tgt_2 == s_2) &&
     tlb_mem_tgt_2 != 5'd0)) &&
     tlb_mem_is_load &&
     !bubble_in && !tlb_mem_bubble) ||
  ((((mem_a_tgt_1 == s_1 ||
     mem_a_tgt_1 == s_2) &&
     mem_a_tgt_1 != 5'd0) || 
     ((mem_a_tgt_2 == s_1 ||
     mem_a_tgt_2 == s_2) &&
     mem_a_tgt_2 != 5'd0)) &&
     mem_a_load &&
     !bubble_in && !mem_a_bubble) ||
  ((((mem_b_tgt_1 == s_1 ||
     mem_b_tgt_1 == s_2) &&
     mem_b_tgt_1 != 5'd0) || 
     ((mem_b_tgt_2 == s_1 ||
     mem_b_tgt_2 == s_2) &&
     mem_b_tgt_2 != 5'd0)) &&
     mem_b_load &&
     !bubble_in && !mem_b_bubble));

  // nonsense to make subtract immediate work how i want
  wire [31:0]lhs = (opcode == 5'd1 && alu_op == 5'd16) ? imm : op1;
  wire [31:0]rhs = ((opcode == 5'd1 && alu_op != 5'd16) || (opcode == 5'd2) || 
                  (5'd3 <= opcode && opcode <= 5'd11) || (opcode == 5'd22)) ? 
                    imm : (opcode == 5'd1 && alu_op == 5'd16) ? op1 : op2;

  wire we_bit = is_store && !bubble_in && !exc_in_wb 
                && !rfe_in_wb && (exc_out == 8'd0) && !stall;

  wire [31:0]alu_rslt;
  ALU ALU(clk, clk_en, opcode, alu_op, lhs, rhs, decode_pc_out, bubble_in, 
    flags_restore, rfe_in_wb,
    alu_rslt, flags);

  // Memory effective address used by this execute slot.
  // Keep this as a wire so byte/halfword lane selection uses the current
  // instruction address (not the registered `addr` from a previous cycle).
  wire [31:0]mem_addr =
    (opcode == 5'd3 || opcode == 5'd6 || opcode == 5'd9) ? (is_post_inc ? op1 : alu_rslt) : // absolute mem
    (opcode == 5'd4 || opcode == 5'd7 || opcode == 5'd10) ? alu_rslt + decode_pc_out + 32'h4 : // relative mem
    (opcode == 5'd5 || opcode == 5'd8 || opcode == 5'd11) ? alu_rslt + decode_pc_out + 32'h4 : // relative immediate mem
    32'h0;

  // Byte/halfword stores must target the addressed lane(s) within the word.
  wire [31:0]store_data_next =
    is_mem_b ? (
      (!mem_addr[1] && !mem_addr[0]) ? (op2 & 32'hff) :
      (!mem_addr[1] &&  mem_addr[0]) ? ((op2 & 32'hff) << 8) :
      ( mem_addr[1] && !mem_addr[0]) ? ((op2 & 32'hff) << 16) :
      ( mem_addr[1] &&  mem_addr[0]) ? ((op2 & 32'hff) << 24) :
      32'h0
    ) :
    is_mem_d ? (
      mem_addr[1] ? ((op2 & 32'hffff) << 16) : (op2 & 32'hffff)
    ) :
    op2;

  wire [3:0]we_next =
    is_mem_w ? {4{we_bit}} :
    is_mem_d ? (mem_addr[1] ? {we_bit, we_bit, 2'b0} : {2'b0, we_bit, we_bit}) :
    is_mem_b ? (
      (!mem_addr[1] && !mem_addr[0]) ? {3'b0, we_bit} :
      (!mem_addr[1] &&  mem_addr[0]) ? {2'b0, we_bit, 1'b0} :
      ( mem_addr[1] && !mem_addr[0]) ? {1'b0, we_bit, 2'b0} :
      {we_bit, 3'b0}
    ) :
    4'h0;

always @(posedge clk) begin
  if (clk_en) begin
        if (halt) begin
      result_1 <= 32'd0;
      result_2 <= 32'd0;
      tgt_out_1 <= 5'd0;
      tgt_out_2 <= 5'd0;
      opcode_out <= 5'd0;
      bubble_out <= 1'b1;
      addr <= 32'd0;
      mem_re <= 1'b0;
      store_data <= 32'd0;
      we <= 4'd0;

      is_load_out <= 1'b0;
      is_store_out <= 1'b0;
      is_tlbr_out <= 1'b0;
      tgts_cr_out <= 1'b0;
      priv_type_out <= 5'd0;
      crmov_mode_type_out <= 2'd0;

      exc_out <= 8'd0;

      pc_out <= decode_pc_out;
      op1_out <= 32'd0;
      op2_out <= 32'd0;

      flags_out <= 4'd0;

      reg_tgt_buf_a_1 <= 5'd0;
      reg_tgt_buf_a_2 <= 5'd0;
      reg_data_buf_a_1 <= 32'd0;
      reg_data_buf_a_2 <= 32'd0;
      tgts_cr_buf_a <= 1'b0;
      reg_tgt_buf_b_1 <= 5'd0;
      reg_tgt_buf_b_2 <= 5'd0;
      reg_data_buf_b_1 <= 32'd0;
      reg_data_buf_b_2 <= 32'd0;
      tgts_cr_buf_b <= 1'b0;
    end else begin
              // jump and link
      result_1 <= bubble_in ? 32'd0 :
                  (opcode == 5'd13 || opcode == 5'd14) ? decode_pc_out + 32'd4 : 
                  // crmov reading from control reg
                  (opcode == 5'd31 && priv_type == 5'd1 && crmov_mode_type >= 2'd1) ? reg_out_cr :
                  // crmov reading from normal reg
                  (opcode == 5'd31 && priv_type == 5'd1 && crmov_mode_type == 2'd0) ? op1 :
                  // everything else
                  alu_rslt;

      result_2 <= bubble_in ? 32'd0 : alu_rslt;
      tgt_out_1 <= (bubble_in || exc_in_wb || rfe_in_wb || stall) ? 5'd0 : tgt_1;
      tgt_out_2 <= (bubble_in || exc_in_wb || rfe_in_wb || stall) ? 5'd0 : tgt_2;
      opcode_out <= bubble_in ? 5'd0 : opcode;
      bubble_out <= (exc_in_wb || rfe_in_wb || stall || halt) ? 1 : bubble_in;

      addr <= mem_addr;
      mem_re <= is_load && !bubble_in && !exc_in_wb 
                && !rfe_in_wb && (exc_out == 8'd0) && !stall;
      store_data <= bubble_in ? 32'd0 : store_data_next;
      we <= bubble_in ? 4'd0 : we_next;

      is_load_out <= bubble_in ? 1'b0 : is_load;
      is_store_out <= bubble_in ? 1'b0 : is_store;
      tgts_cr_out <= bubble_in ? 1'b0 : tgts_cr;
      priv_type_out <= bubble_in ? 5'd0 : priv_type;
      crmov_mode_type_out <= bubble_in ? 2'd0 : crmov_mode_type;

      exc_out <= bubble_in ? 8'h0 : exc_in;

      pc_out <= decode_pc_out;
      op1_out <= bubble_in ? 32'd0 : op1;
      op2_out <= bubble_in ? 32'd0 : op2;

      flags_out <= bubble_in ? 4'd0 : flags;

      is_tlbr_out <= !bubble_in &&
        (opcode == 5'd31 && priv_type == 5'd0 && crmov_mode_type == 2'd0);

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

  assign branch = !bubble_in && !exc_in_wb && !rfe_in_wb && taken && is_branch;
  
  assign branch_tgt = 
            (opcode == 5'd12) ? decode_pc_out + (imm << 2) + 32'h4 :
            (opcode == 5'd13) ? op1 :
            (opcode == 5'd14) ? decode_pc_out + op1 + 32'h4 : 
            decode_pc_out + 32'h4;

endmodule
