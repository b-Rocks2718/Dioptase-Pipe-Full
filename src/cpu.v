`timescale 1ps/1ps

// Top-level full pipeline core.
//
// Stage order:
//   tlb_fetch -> fetch_a -> fetch_b -> decode -> execute ->
//   tlb_memory -> memory_a -> memory_b -> writeback
//
// Control invariants:
// - `flush` removes younger work after redirects/exceptions/sleep transitions.
// - `frontend_stop` holds fetch/decode when execute hazards or decode crack
//   sequencing require replay/serialization.
// - Halt/sleep are latched architectural state derived from writeback/execute.
module pipelined_cpu(
  input clk, input [15:0]interrupts,
  output [17:0]mem_read0_addr, input [31:0]mem_read0_data,
  output mem_re, output [17:0]mem_read1_addr, input [31:0]mem_read1_data,
  output [3:0]mem_we, output [17:0]mem_write_addr, output [31:0]mem_write_data,
  output [31:0]ret_val, output [3:0]flags, output [31:0]curr_pc,
  output reg clk_en
);

    wire [31:0]clock_divider;
    reg [31:0]clk_count = 32'b0;

    wire [31:0]interrupt_state;
    wire [31:0]epc_curr;
    wire [31:0]efg_curr;

    initial begin
      clk_en = 1;
    end

    wire [31:0]pid;
    wire [3:0]tlb_mem_flags_out;
    wire [3:0]mem_a_flags_out;
    wire [3:0]mem_b_flags_out;
    wire [31:0]tlb_mem_addr_out;
    wire [31:0]mem_a_addr_out;
    wire [31:0]mem_b_addr_out;

    reg halt = 0;
    reg sleep = 0;
    reg [31:0]sleep_pc = 32'd0;
    reg sleep_interrupt_pending = 1'b0;
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
    wire wb_sleep;
    wire exc_in_wb;
    wire tlb_exc_in_wb;
    wire interrupt_in_wb;
    wire rfe_in_wb;
    wire rfi_in_wb;
    wire kmode;
    wire exec_is_sleep_out;

    reg mem_ren = 1;
    assign mem_read0_addr = tlb_out_0;
    assign mem_read1_addr = tlb_out_1;
    assign mem_out_0 = mem_read0_data;
    assign mem_out_1 = mem_read1_data;
    assign mem_write_addr = tlb_out_1;
    assign mem_write_data = store_data;

    wire stall;
    wire decode_stall;
    wire halt_pending;
    wire exception_in_pipe;
    reg stall_d = 1'b0;
    // Stop condition for frontend fetch progression.
    wire frontend_stop = stall | decode_stall | stall_d | halt_or_sleep | halt_pending;
    wire [31:0]branch_tgt;
    wire [31:0]decode_pc_out;
    wire [31:0]tlb_fetch_pc_out;
    wire [31:0]tlb_fetch_slot_id_out;
    wire [31:0]fetch_a_pc_out;
    wire [31:0]fetch_a_slot_id_out;
    wire [31:0]fetch_b_slot_id_out;
    wire tlb_fetch_bubble_out;
    wire fetch_a_bubble_out;
    wire [7:0]tlb_fetch_exc_out;
    wire [7:0]fetch_a_exc_out;

    wire [7:0]exc_tlb_0;
    wire [7:0]exc_tlb_1;
    wire [31:0]tlb_mem_pc_out;
    wire [31:0]mem_a_pc_out;
    wire [31:0]mem_b_pc_out;

    wire [31:0]decode_op1_out;
    wire [31:0]decode_op2_out;
    wire [31:0]exec_op1;
    wire [31:0]exec_op2;

    wire [26:0]tlb_read;

    wire [7:0]decode_exc_out;

    wire decode_tlb_we_out;
    wire decode_tlbi_out;
    wire decode_tlbc_out;
    wire decode_bubble_out;
    wire exec_mem_re;
    wire [31:0]exec_store_data;
    wire [3:0]exec_mem_we;
    wire tlb_addr1_write_req = (exec_mem_we != 4'd0);
    wire [31:0]tlb_mem_op1_out;
    wire [31:0]tlb_mem_op2_out;
    wire [31:0]mem_a_op1_out;
    wire [31:0]mem_a_op2_out;
    wire [31:0]mem_b_op1_out;
    wire [31:0]mem_b_op2_out;

    tlb_fetch tlb_fetch(clk, clk_en, frontend_stop, flush, branch, branch_tgt, 
      exc_in_wb, mem_out_1, rfe_in_wb, epc_curr, 
      fetch_addr, tlb_fetch_pc_out, tlb_fetch_slot_id_out, tlb_fetch_bubble_out, tlb_fetch_exc_out
    );

    wire fetch_b_bubble_out;
    wire [31:0]fetch_b_pc_out;
    wire [7:0]fetch_b_exc_out;

    fetch_a fetch_a(clk, clk_en, frontend_stop, flush, tlb_fetch_bubble_out, tlb_fetch_pc_out, tlb_fetch_slot_id_out,
      tlb_fetch_exc_out, exc_tlb_0,
      fetch_a_bubble_out, fetch_a_pc_out, fetch_a_slot_id_out, fetch_a_exc_out
    );

    fetch_b fetch_b(clk, clk_en, frontend_stop, flush, fetch_a_bubble_out, fetch_a_pc_out, fetch_a_slot_id_out,
      fetch_a_exc_out,
      fetch_b_bubble_out, fetch_b_pc_out, fetch_b_slot_id_out, fetch_b_exc_out
    );

    wire [4:0] decode_opcode_out;
    wire [4:0] decode_s_1_out;
    wire [4:0] decode_s_2_out;
    wire [4:0] decode_tgt_out_1;
    wire [4:0] decode_tgt_out_2;
    wire [4:0] decode_alu_op_out;
    wire [31:0] decode_imm_out;
    wire [31:0]decode_slot_id_out;
    wire [4:0] decode_branch_code_out;

    wire [4:0]tlb_mem_tgt_out_1;
    wire [4:0]tlb_mem_tgt_out_2;
    wire [4:0]mem_a_tgt_out_1;
    wire [4:0]mem_a_tgt_out_2;
    wire [4:0]mem_b_tgt_out_1;
    wire [4:0]mem_b_tgt_out_2;

    wire decode_is_load_out;
    wire decode_is_store_out;
    wire decode_is_branch_out;
    wire decode_is_post_inc_out;
    wire decode_is_atomic_out;
    wire decode_is_fetch_add_atomic_out;
    wire [1:0]decode_atomic_step_out;

    wire [31:0]decode_cr_op_out;
    wire [4:0]decode_cr_s_out;

    wire decode_tgts_cr_out;
    wire [4:0]decode_priv_type_out; 
    wire [1:0]decode_crmov_mode_type_out;

    wire tlb_mem_tgts_cr_out;
    wire mem_a_tgts_cr_out;
    wire mem_b_tgts_cr_out;

    // Exception entry PC uses saved sleep PC when waking from sleep interrupt.
    wire [31:0]epc_source = sleep_interrupt_pending ? sleep_pc :
      ((mem_b_exc_out == 8'h01) ? (mem_b_pc_out + 32'd4) : mem_b_pc_out);
    reg [31:0]tlb_fault_addr_latched = 32'd0;
    wire mem_b_tlb_fault_live = !mem_b_bubble_out &&
      (mem_b_exc_out == 8'h82 || mem_b_exc_out == 8'h83);
    wire [31:0]tlb_addr_for_creg = mem_b_tlb_fault_live ?
      {12'b0, mem_b_addr_out[31:12]} : tlb_fault_addr_latched;

    decode decode(clk, clk_en, flush, halt_or_sleep || halt_pending,
      mem_out_0, fetch_b_bubble_out, fetch_b_pc_out, fetch_b_slot_id_out,
      reg_we_1, mem_b_tgt_out_1, reg_write_data_1,
      reg_we_2, mem_b_tgt_out_2, reg_write_data_2,
      mem_b_tgts_cr_out,
      stall,
      fetch_b_exc_out,

      epc_source, {28'b0, mem_b_flags_out}, tlb_addr_for_creg,
      exc_in_wb, tlb_exc_in_wb, interrupts,
      interrupt_in_wb, rfe_in_wb, rfi_in_wb,
      clock_divider, pid, epc_curr, efg_curr, kmode, decode_exc_out,
      decode_op1_out, decode_op2_out, decode_cr_op_out, decode_pc_out, decode_slot_id_out,
      decode_opcode_out, decode_s_1_out, decode_s_2_out, decode_cr_s_out,
      decode_tgt_out_1, decode_tgt_out_2,
      decode_alu_op_out, decode_imm_out, decode_branch_code_out,
      decode_bubble_out, ret_val,
      decode_is_load_out, decode_is_store_out, decode_is_branch_out,
      decode_is_post_inc_out, decode_tgts_cr_out, 
      decode_priv_type_out, decode_crmov_mode_type_out,
      decode_tlb_we_out, decode_tlbi_out, decode_tlbc_out, interrupt_state,
      decode_is_atomic_out, decode_is_fetch_add_atomic_out, decode_atomic_step_out,
      decode_stall
    );

    wire exec_bubble_out;
    wire [31:0]tlb_mem_result_out_1;
    wire [31:0]tlb_mem_result_out_2;
    wire [31:0]mem_a_result_out_1;
    wire [31:0]mem_a_result_out_2;
    wire [31:0]mem_b_result_out_1;
    wire [31:0]mem_b_result_out_2;
    wire [4:0]exec_opcode_out;
    wire [4:0]exec_tgt_out_1;
    wire [4:0]exec_tgt_out_2;
    wire [4:0]wb_tgt_out_1;
    wire [4:0]wb_tgt_out_2;
    wire [31:0]wb_result_out_1;
    wire [31:0]wb_result_out_2;
    wire [4:0]tlb_mem_opcode_out;
    wire [4:0]mem_a_opcode_out;
    wire [4:0]mem_b_opcode_out;

    wire exec_is_load_out;
    wire exec_is_store_out;
    wire exec_is_tlbr_out;
    
    assign curr_pc = decode_pc_out;

    wire wb_tgts_cr_out;

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
      tlb_mem_tgt_out_1, tlb_mem_tgt_out_2,
      mem_a_tgt_out_1, mem_a_tgt_out_2, 
      mem_b_tgt_out_1, mem_b_tgt_out_2,
      wb_tgt_out_1, wb_tgt_out_2,
      decode_op1_out, decode_op2_out, decode_cr_op_out,
      tlb_mem_result_out_1, tlb_mem_result_out_2,
      mem_a_result_out_1, mem_a_result_out_2, 
      mem_b_result_out_1, mem_b_result_out_2,
      wb_result_out_1, wb_result_out_2, 
      mem_a_tgts_cr_out, mem_b_tgts_cr_out, wb_tgts_cr_out,
      decode_pc_out, decode_slot_id_out, mem_a_opcode_out, mem_b_opcode_out,
      decode_is_load_out, decode_is_store_out, decode_is_branch_out, 
      tlb_mem_bubble_out, tlb_mem_is_load_out,
      mem_a_bubble_out, mem_a_is_load_out, 
      mem_b_bubble_out, mem_b_is_load_out,
      decode_is_post_inc_out, decode_tgts_cr_out, decode_priv_type_out,
      decode_crmov_mode_type_out, decode_exc_out, exc_in_wb, efg_curr, rfe_in_wb,
      decode_is_atomic_out, decode_is_fetch_add_atomic_out, decode_atomic_step_out,

      exec_result_out_1, exec_result_out_2,
      addr, exec_mem_re, exec_store_data, exec_mem_we,
      exec_opcode_out, exec_tgt_out_1, exec_tgt_out_2, exec_bubble_out, 
      branch, branch_tgt, flags, exec_flags_out, stall,
      exec_is_load_out, exec_is_store_out, exec_is_tlbr_out,
      exec_tgts_cr_out, exec_priv_type_out, exec_crmov_mode_type_out,
      exec_exc_out, exec_pc_out,
      exec_op1, exec_op2,
      exec_op1_out, exec_op2_out
    );

    assign exec_is_sleep_out = (exec_opcode_out == 5'd31) &&
      (exec_priv_type_out == 5'd2) &&
      (exec_crmov_mode_type_out == 2'd1) &&
      !exec_bubble_out;

    wire tlb_mem_bubble_out;
    wire mem_a_bubble_out;
    wire mem_b_bubble_out;
    wire tlb_mem_is_load_out;
    wire mem_a_is_load_out;
    wire mem_b_is_load_out;
    wire tlb_mem_is_store_out;
    wire mem_a_is_store_out;
    wire mem_b_is_store_out;

    wire [7:0]tlb_mem_exc_out;
    wire [7:0]mem_a_exc_out;
    wire [7:0]mem_b_exc_out;
    wire [4:0]tlb_mem_priv_type_out;
    wire [4:0]mem_a_priv_type_out;
    wire [4:0]mem_b_priv_type_out;
    wire [1:0]tlb_mem_crmov_mode_type_out;
    wire [1:0]mem_a_crmov_mode_type_out;
    wire [1:0]mem_b_crmov_mode_type_out;
    tlb_memory tlb_memory(clk, clk_en, halt_or_sleep,
      exec_bubble_out, exec_opcode_out, exec_tgt_out_1, exec_tgt_out_2,
      exec_result_out_1, exec_result_out_2, addr,
      exec_is_load_out, exec_is_store_out, exec_is_tlbr_out,
      exec_pc_out, exec_exc_out, exec_tgts_cr_out, exec_priv_type_out, 
      exec_crmov_mode_type_out, exec_flags_out, exec_op1_out, exec_op2_out,
      exc_in_wb, rfe_in_wb, tlb_read, exc_tlb_1, exec_mem_re, exec_store_data, exec_mem_we,

      tlb_mem_tgt_out_1, tlb_mem_tgt_out_2, 
      tlb_mem_result_out_1, tlb_mem_result_out_2,
      tlb_mem_opcode_out, tlb_mem_addr_out, tlb_mem_bubble_out,
      tlb_mem_is_load_out, tlb_mem_is_store_out,
      tlb_mem_pc_out, tlb_mem_exc_out, tlb_mem_tgts_cr_out, tlb_mem_priv_type_out,
      tlb_mem_crmov_mode_type_out, tlb_mem_flags_out, tlb_mem_op1_out, tlb_mem_op2_out,
      mem_re, store_data, mem_we
    );

    memory memory_a(clk, clk_en, halt_or_sleep,
      tlb_mem_bubble_out, tlb_mem_opcode_out, tlb_mem_tgt_out_1, tlb_mem_tgt_out_2,
      tlb_mem_result_out_1, tlb_mem_result_out_2, tlb_mem_addr_out,
      tlb_mem_is_load_out, tlb_mem_is_store_out,
      tlb_mem_pc_out, tlb_mem_exc_out, tlb_mem_tgts_cr_out, tlb_mem_priv_type_out, 
      tlb_mem_crmov_mode_type_out, tlb_mem_flags_out, tlb_mem_op1_out, tlb_mem_op2_out,
      exc_in_wb, rfe_in_wb,

      mem_a_tgt_out_1, mem_a_tgt_out_2, 
      mem_a_result_out_1, mem_a_result_out_2,
      mem_a_opcode_out, mem_a_addr_out, mem_a_bubble_out,
      mem_a_is_load_out, mem_a_is_store_out,
      mem_a_pc_out, mem_a_exc_out, mem_a_tgts_cr_out, mem_a_priv_type_out,
      mem_a_crmov_mode_type_out, mem_a_flags_out, mem_a_op1_out, mem_a_op2_out
    );

    memory memory_b(clk, clk_en, halt_or_sleep,
      mem_a_bubble_out, mem_a_opcode_out, mem_a_tgt_out_1, mem_a_tgt_out_2,
      mem_a_result_out_1, mem_a_result_out_2, mem_a_addr_out,
      mem_a_is_load_out, mem_a_is_store_out,
      mem_a_pc_out, mem_a_exc_out, mem_a_tgts_cr_out, mem_a_priv_type_out, 
      mem_a_crmov_mode_type_out, mem_a_flags_out, mem_a_op1_out, mem_a_op2_out,
      exc_in_wb, rfe_in_wb,

      mem_b_tgt_out_1, mem_b_tgt_out_2, 
      mem_b_result_out_1, mem_b_result_out_2,
      mem_b_opcode_out, mem_b_addr_out, mem_b_bubble_out,
      mem_b_is_load_out, mem_b_is_store_out,
      mem_b_pc_out, mem_b_exc_out, mem_b_tgts_cr_out, mem_b_priv_type_out,
      mem_b_crmov_mode_type_out, mem_b_flags_out, mem_b_op1_out, mem_b_op2_out
    );

    writeback writeback(clk, clk_en, halt_or_sleep, mem_b_bubble_out, mem_b_tgt_out_1, mem_b_tgt_out_2,
      mem_b_is_load_out, mem_b_is_store_out,
      mem_b_opcode_out,
      mem_b_result_out_1, mem_b_result_out_2, mem_out_1, mem_b_addr_out,
      mem_b_exc_out, mem_b_tgts_cr_out, mem_b_priv_type_out, mem_b_crmov_mode_type_out,
      
      reg_write_data_1, reg_write_data_2,
      reg_we_1, wb_tgt_out_1, wb_result_out_1,
      reg_we_2, wb_tgt_out_2, wb_result_out_2,
      wb_tgts_cr_out,
      exc_in_wb, interrupt_in_wb, rfe_in_wb, rfi_in_wb,
      tlb_exc_in_wb,
      wb_halt, wb_sleep
    );

    // TLB keying must observe in-flight PID updates from older crmv ops.
    wire [31:0]pid_for_tlb =
      (exec_tgts_cr_out && (exec_tgt_out_1 == 5'd1)) ? exec_result_out_1 :
      (tlb_mem_tgts_cr_out && (tlb_mem_tgt_out_1 == 5'd1)) ? tlb_mem_result_out_1 :
      (mem_a_tgts_cr_out && (mem_a_tgt_out_1 == 5'd1)) ? mem_a_result_out_1 :
      (mem_b_tgts_cr_out && (mem_b_tgt_out_1 == 5'd1)) ? mem_b_result_out_1 :
      (wb_tgts_cr_out && (wb_tgt_out_1 == 5'd1)) ? wb_result_out_1 :
      pid;

    tlb tlb(clk, clk_en, kmode, pid_for_tlb,
      fetch_addr, addr, exec_op1,
      decode_tlb_we_out, exec_op2, decode_tlbi_out,
      decode_exc_out, decode_tlbc_out,
      exec_mem_re, tlb_addr1_write_req,
      exc_tlb_0, exc_tlb_1,
      tlb_out_0, tlb_out_1, tlb_read
    );

    // Frontend must stop once a halt instruction is already in flight so
    // younger fetch/decode slots cannot observe undefined instruction words.
    wire decode_has_halt = !decode_bubble_out &&
      (decode_opcode_out == 5'd31) &&
      (decode_priv_type_out == 5'd2) &&
      (decode_crmov_mode_type_out == 2'd2);
    wire exec_has_halt = !exec_bubble_out &&
      (exec_opcode_out == 5'd31) &&
      (exec_priv_type_out == 5'd2) &&
      (exec_crmov_mode_type_out == 2'd2);
    wire tlb_mem_has_halt = !tlb_mem_bubble_out &&
      (tlb_mem_opcode_out == 5'd31) &&
      (tlb_mem_priv_type_out == 5'd2) &&
      (tlb_mem_crmov_mode_type_out == 2'd2);
    wire mem_a_has_halt = !mem_a_bubble_out &&
      (mem_a_opcode_out == 5'd31) &&
      (mem_a_priv_type_out == 5'd2) &&
      (mem_a_crmov_mode_type_out == 2'd2);
    wire mem_b_has_halt = !mem_b_bubble_out &&
      (mem_b_opcode_out == 5'd31) &&
      (mem_b_priv_type_out == 5'd2) &&
      (mem_b_crmov_mode_type_out == 2'd2);
    wire decode_exc_live = (decode_exc_out != 8'd0);
    wire exec_exc_live = !exec_bubble_out && (exec_exc_out != 8'd0);
    wire tlb_mem_exc_live = !tlb_mem_bubble_out && (tlb_mem_exc_out != 8'd0);
    wire mem_a_exc_live = !mem_a_bubble_out && (mem_a_exc_out != 8'd0);
    wire mem_b_exc_live = !mem_b_bubble_out && (mem_b_exc_out != 8'd0);
    // Any live exception in-flight keeps halt gating off and forces flush.
    assign exception_in_pipe = decode_exc_live || exec_exc_live ||
      tlb_mem_exc_live || mem_a_exc_live || mem_b_exc_live || exc_in_wb;
    wire wb_redirect = exc_in_wb || rfe_in_wb || wb_halt || wb_sleep;
    assign flush = branch || wb_redirect ||
      exec_is_sleep_out || exception_in_pipe;
    assign halt_pending = kmode && !rfe_in_wb && !exception_in_pipe && (
      decode_has_halt || exec_has_halt || tlb_mem_has_halt ||
      mem_a_has_halt || mem_b_has_halt || wb_halt
    );

    always @(posedge clk) begin
      if (clk_en) begin
`ifdef SIMULATION
        if ($test$plusargs("cpu_debug")) begin
          $display("[cpu] dpc=%h dop=%0d dt1=%0d dt2=%0d db=%b de=%h | eop=%0d et1=%0d et2=%0d eb=%b ee=%h | mbo=%0d mbt1=%0d mbr1=%h mbb=%b wbt1=%0d wwe=%b wr1=%h | wb_exc=%b rfe=%b fstop=%b",
            decode_pc_out, decode_opcode_out, decode_tgt_out_1, decode_tgt_out_2, decode_bubble_out, decode_exc_out,
            exec_opcode_out, exec_tgt_out_1, exec_tgt_out_2, exec_bubble_out, exec_exc_out,
            mem_b_opcode_out, mem_b_tgt_out_1, mem_b_result_out_1, mem_b_bubble_out, wb_tgt_out_1, reg_we_1, reg_write_data_1,
            exc_in_wb, rfe_in_wb, frontend_stop);
        end
`endif
        if (mem_b_tlb_fault_live) begin
          tlb_fault_addr_latched <= {12'b0, mem_b_addr_out[31:12]};
        end
        stall_d <= stall;
        halt <= halt ? 1 : wb_halt;
        sleep <= sleep ? (interrupt_state == 32'b0) : exec_is_sleep_out;
        if (exec_is_sleep_out) begin
          sleep_pc <= decode_pc_out;
        end
        if (interrupt_in_wb) begin
          sleep_interrupt_pending <= 1'b0;
        end else if (sleep && interrupt_state != 32'b0) begin
          sleep_interrupt_pending <= 1'b1;
        end
      end

      // Clock divider creates single-cycle `clk_en` pulses for the whole core.
      if (clk_count >= clock_divider) begin
        clk_count <= 0;
        clk_en <= 1;       // generate enable pulse
      end else begin
        clk_count <= clk_count + 1;
        clk_en <= 0;
      end
    end

endmodule
