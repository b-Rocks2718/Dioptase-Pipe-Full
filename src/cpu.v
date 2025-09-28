`timescale 1ps/1ps

module pipelined_cpu(
  input clk, input [15:0]interrupts,
  output [17:0]mem_read0_addr, input [31:0]mem_read0_data,
  output [17:0]mem_read1_addr, input [31:0]mem_read1_data,
  output [3:0]mem_we, output [17:0]mem_write_addr, output [31:0]mem_write_data,
  output [31:0]ret_val, output [3:0]flags, output [31:0]curr_pc,
  output reg clk_en
);

    wire [31:0]clock_divider;
    reg [31:0]clk_count = 32'b0;

    initial begin
      clk_en <= 1;
    end

    wire [11:0]pid;
    wire [3:0]mem_flags_out;
    wire [31:0]mem_tlbmiss_out;

    reg halt = 0;
    reg sleep = 0;
    wire halt_or_sleep = halt || sleep;

    counter ctr(halt, clk, ret_val);

    // read from memory
    wire [31:0]fetch_instr_out;
    wire [31:0]mem_out_0;
    wire [31:0]fetch_addr;
    wire [17:0]tlb_out_0;
    wire [17:0]tlb_out_1;
    wire [31:0]mem_out_1;

    wire [31:0]exec_result_out_1;
    wire [31:0]exec_result_out_2;
    wire [31:0]addr;
    wire [31:0]store_data;

    wire [31:0]reg_write_data_1;
    wire [31:0]reg_write_data_2;
    wire reg_we_1;
    wire reg_we_2;

    wire branch;
    wire flush;
    wire wb_halt;
    wire exc_in_wb;
    wire tlb_exc_in_wb;
    wire interrupt_in_wb;
    wire rfe_in_wb;
    wire rfi_in_wb;
    wire kmode;
    assign flush = branch || wb_halt || exc_in_wb;

    reg mem_ren = 1;
    assign mem_read0_addr = tlb_out_0;
    assign mem_read1_addr = tlb_out_1;
    assign mem_out_0 = mem_read0_data;
    assign mem_out_1 = mem_read1_data;
    assign mem_write_addr = addr;
    assign mem_write_data = store_data;

    wire stall;
    wire [31:0]branch_tgt;
    wire [31:0]decode_pc_out;
    wire [31:0]fetch_a_pc_out;
    wire fetch_a_bubble_out;
    wire [7:0]fetch_a_exc_out;

    wire [7:0]exc_tlb_0;
    wire [7:0]exc_tlb_1;
    wire [31:0]mem_pc_out;

    wire [31:0] decode_op1_out;
    wire [31:0] decode_op2_out;

    wire [5:0]tlb_read;

    wire [7:0]decode_exc_out;

    wire decode_tlb_we_out; 
    wire decode_tlbc_out;
    tlb tlb(clk, clk_en, kmode, pid,
      fetch_addr, addr, decode_op1_out, 
      decode_tlb_we_out, decode_op2_out, 
      decode_exc_out, decode_tlbc_out,
      exc_tlb_0, exc_tlb_1,
      tlb_out_0, tlb_out_1, tlb_read
    );

    fetch_a fetch_a(clk, clk_en, stall | halt_or_sleep, flush, branch, branch_tgt, exc_in_wb, mem_out_1,
      fetch_addr, fetch_a_pc_out, fetch_a_bubble_out, fetch_a_exc_out);

    wire fetch_b_bubble_out;
    wire [31:0]fetch_b_pc_out;
    wire [7:0]fetch_b_exc_out;

    fetch_b fetch_b(clk, clk_en, stall | halt_or_sleep, flush, fetch_a_bubble_out, fetch_a_pc_out,
      fetch_a_exc_out, exc_tlb_0,
      fetch_b_bubble_out, fetch_b_pc_out, fetch_b_exc_out);

    wire [4:0] decode_opcode_out;
    wire [4:0] decode_s_1_out;
    wire [4:0] decode_s_2_out;
    wire [4:0] decode_tgt_out_1;
    wire [4:0] decode_tgt_out_2;
    wire [4:0] decode_alu_op_out;
    wire [31:0] decode_imm_out;
    wire [4:0] decode_branch_code_out;
    
    wire decode_bubble_out;
    wire [4:0]mem_tgt_out_1;
    wire [4:0]mem_tgt_out_2;

    wire decode_is_load_out;
    wire decode_is_store_out;
    wire decode_is_branch_out;
    wire decode_is_post_inc_out;

    wire [31:0]decode_cr_op_out;
    wire [4:0]decode_cr_s_out;

    wire decode_tgts_cr_out;
    wire [4:0]decode_priv_type_out; 
    wire [1:0]decode_crmov_mode_type_out;

    wire mem_tgts_cr_out;

    decode decode(clk, clk_en, flush, halt_or_sleep,
      mem_out_0, fetch_b_bubble_out, fetch_b_pc_out,
      reg_we_1, mem_tgt_out_1, reg_write_data_1,
      reg_we_2, mem_tgt_out_2, reg_write_data_2,
      mem_tgts_cr_out,
      stall, fetch_b_exc_out, exc_tlb_1,

      mem_pc_out, {28'b0, mem_flags_out}, mem_tlbmiss_out,
      exc_in_wb, tlb_exc_in_wb, interrupts,
      interrupt_in_wb, rfe_in_wb, rfi_in_wb,
      clock_divider, pid, kmode, decode_exc_out,
      decode_op1_out, decode_op2_out, decode_cr_op_out, decode_pc_out,
      decode_opcode_out, decode_s_1_out, decode_s_2_out, decode_cr_s_out,
      decode_tgt_out_1, decode_tgt_out_2,
      decode_alu_op_out, decode_imm_out, decode_branch_code_out,
      decode_bubble_out, ret_val,
      decode_is_load_out, decode_is_store_out, decode_is_branch_out,
      decode_is_post_inc_out, decode_tgts_cr_out, 
      decode_priv_type_out, decode_crmov_mode_type_out,
      decode_tlb_we_out, decode_tlbc_out);

    wire exec_bubble_out;
    wire [31:0]mem_result_out_1;
    wire [31:0]mem_result_out_2;
    wire [4:0]exec_opcode_out;
    wire [4:0]exec_tgt_out_1;
    wire [4:0]exec_tgt_out_2;
    wire [4:0]wb_tgt_out_1;
    wire [4:0]wb_tgt_out_2;
    wire [31:0]wb_result_out_1;
    wire [31:0]wb_result_out_2;
    wire [4:0]mem_opcode_out;
    wire [31:0]exec_addr_out;

    wire exec_is_load_out;
    wire exec_is_store_out;
    wire exec_is_misaligned_out;
    
    assign curr_pc = decode_pc_out;

    wire wb_tgts_cr_out;

    wire [31:0]flags_restore;
    wire [3:0]exec_flags_out;

    wire exec_tgts_cr_out;
    wire [4:0]exec_priv_type_out; 
    wire [1:0]exec_crmov_mode_type_out;
    wire [7:0]exec_exc_out; 
    wire [31:0]exec_pc_out;
    wire [31:0]exec_op1_out; 
    wire [31:0]exec_op2_out;

    execute execute(clk, clk_en, halt_or_sleep, decode_bubble_out, 
      decode_opcode_out, decode_s_1_out, decode_s_2_out, decode_cr_s_out,
      decode_tgt_out_1, decode_tgt_out_2,
      decode_alu_op_out, decode_imm_out, decode_branch_code_out,
      mem_tgt_out_1, mem_tgt_out_2, wb_tgt_out_1, wb_tgt_out_2,
      decode_op1_out, decode_op2_out, decode_cr_op_out,
      mem_result_out_1, mem_result_out_2, wb_result_out_1, wb_result_out_2, 
      mem_tgts_cr_out, wb_tgts_cr_out,
      decode_pc_out, mem_opcode_out,
      decode_is_load_out, decode_is_store_out, decode_is_branch_out, mem_bubble_out, mem_is_load_out,
      decode_is_post_inc_out, decode_tgts_cr_out, decode_priv_type_out,
      decode_crmov_mode_type_out, decode_exc_out, exc_in_wb, flags_restore, rfe_in_wb,
      tlb_read,

      exec_result_out_1, exec_result_out_2,
      addr, store_data, mem_we, exec_addr_out,
      exec_opcode_out, exec_tgt_out_1, exec_tgt_out_2, exec_bubble_out, 
      branch, branch_tgt, flags, exec_flags_out, stall,
      exec_is_load_out, exec_is_store_out, exec_is_misaligned_out,
      exec_tgts_cr_out, exec_priv_type_out, exec_crmov_mode_type_out,
      exec_exc_out, exec_pc_out,
      exec_op1_out, exec_op2_out);

    wire mem_bubble_out;
    wire mem_is_load_out;
    wire mem_is_store_out;
    wire mem_is_misaligned_out;
    wire [31:0]mem_addr_out;

    wire [7:0]mem_exc_out;
    wire [4:0]mem_priv_type_out;
    wire [1:0]mem_crmov_mode_type_out;
    wire [31:0]mem_op1_out;
    wire [31:0]mem_op2_out;

    memory memory(clk, clk_en, halt_or_sleep,
      exec_bubble_out, exec_opcode_out, exec_tgt_out_1, exec_tgt_out_2,
      exec_result_out_1, exec_result_out_2, exec_addr_out,
      exec_is_load_out, exec_is_store_out, exec_is_misaligned_out,
      exec_pc_out, exec_exc_out, exec_tgts_cr_out, exec_priv_type_out, 
      exec_crmov_mode_type_out, exec_flags_out, exec_op1_out, exec_op2_out,
      exc_in_wb,

      mem_tgt_out_1, mem_tgt_out_2, 
      mem_result_out_1, mem_result_out_2,
      mem_opcode_out, mem_addr_out, mem_bubble_out,
      mem_is_load_out, mem_is_store_out, mem_is_misaligned_out,
      mem_pc_out, mem_exc_out, mem_tgts_cr_out, mem_priv_type_out,
      mem_crmov_mode_type_out, mem_flags_out, mem_op1_out, mem_op2_out
      );

    assign curr_pc = mem_pc_out;

    writeback writeback(clk, clk_en, halt_or_sleep, mem_bubble_out, mem_tgt_out_1, mem_tgt_out_2,
      mem_is_load_out, mem_is_store_out, mem_is_misaligned_out,
      mem_opcode_out,
      mem_result_out_1, mem_result_out_2, mem_out_1, mem_addr_out,
      mem_exc_out, mem_tgts_cr_out, mem_priv_type_out, mem_crmov_mode_type_out,
      
      reg_write_data_1, reg_write_data_2,
      reg_we_1, wb_tgt_out_1, wb_result_out_1,
      reg_we_2, wb_tgt_out_2, wb_result_out_2,
      exc_in_wb, interrupt_in_wb, rfe_in_wb, rfi_in_wb,
      wb_halt, wb_sleep);

    always @(posedge clk) begin
      if (clk_en) begin
        halt <= halt ? 1 : wb_halt;
        sleep <= sleep ? (interrupts == 8'b0) : wb_sleep;
      end

      if (clk_count >= clock_divider) begin
        clk_count <= 0;
        clk_en <= 1;       // generate enable pulse
      end else begin
        clk_count <= clk_count + 1;
        clk_en <= 0;
      end
    end

endmodule