`timescale 1ps/1ps

// Top-level full pipeline core.
//
// Stage order:
//   tlb_fetch -> fetch_a -> fetch_b -> decode -> execute ->
//   tlb_memory -> memory_a -> memory_b -> writeback
//
// Control invariants:
// - `flush` removes younger work after redirects/exceptions/sleep transitions.
// - `frontend_issue_stop` gates new fetch issue on backend stalls/queue pressure.
// - Decode consumes from a frontend packet queue so in-flight returns stay
//   paired with their metadata across stall windows.
// - Halt/sleep are latched architectural state derived from writeback/execute.
module pipelined_cpu(
  input clk, input [15:0]interrupts, input [31:0]clock_divider,
  output [26:0]mem_read0_addr, output [31:0]mem_read0_tag,
  output icache_req_valid,
  input [31:0]mem_read0_data, input [31:0]mem_read0_data_tag,
  input mem_read0_accepted,
  input icache_stall, input dcache_stall,
  output mem_re, output [26:0]mem_read1_addr, input [31:0]mem_read1_data,
  output [3:0]mem_we, output [26:0]mem_write_addr, output [31:0]mem_write_data,
  output [31:0]ret_val, output [3:0]flags, output [31:0]curr_pc,
  output reg clk_en, output pipe_clk_en
);

    wire [31:0]interrupt_state;
    wire [31:0]epc_curr;
    wire [31:0]efg_curr;
    // Cache misses pause pipeline stage advancement without stopping memory-side
    // cache refill progression in mem.v.
    assign pipe_clk_en = clk_en && !icache_stall && !dcache_stall;

    reg [31:0]clk_div_count;
    initial begin
      clk_en = 1;
      clk_div_count = 32'd0;
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
    wire [31:0]mem_out_0;
    wire [31:0]fetch_addr;
    wire [26:0]tlb_out_0;
    wire [26:0]tlb_out_1;
    wire [31:0]mem_out_1;

    wire [31:0]exec_result_out_1;
    wire [31:0]exec_result_out_2;
    wire [31:0]addr;
    wire [31:0]store_data;

    wire [31:0]reg_write_data_1;
    wire [31:0]reg_write_data_2;
    wire reg_we_1;
    wire reg_we_2;
    wire wb_no_alias_1;
    wire wb_no_alias_2;

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

    assign mem_read0_addr = tlb_out_0;
    assign mem_read0_tag = tlb_fetch_slot_id_out;
    assign mem_read1_addr = tlb_out_1;
    assign mem_out_0 = mem_read0_data;
    assign mem_out_1 = mem_read1_data;
    assign mem_write_addr = tlb_out_1;
    assign mem_write_data = store_data;

    wire stall;
    wire decode_stage_stall;
    wire decode_stall = decode_stage_stall | icache_stall;
    wire halt_pending;
    wire exception_in_pipe;
    localparam FRONTQ_DEPTH = 8;
    localparam FRONTQ_PTR_W = 3;
    localparam FRONTQ_COUNT_W = 4;
    localparam [FRONTQ_COUNT_W-1:0] FRONTQ_STOP_LEVEL = 4'd6;
    // Frontend queue stores fully paired fetch packets at decode boundary.
    reg [31:0]frontq_instr[0:FRONTQ_DEPTH-1];
    reg [31:0]frontq_pc[0:FRONTQ_DEPTH-1];
    reg [31:0]frontq_slot[0:FRONTQ_DEPTH-1];
    reg [7:0]frontq_exc[0:FRONTQ_DEPTH-1];
    reg frontq_bubble[0:FRONTQ_DEPTH-1];
    reg [FRONTQ_PTR_W-1:0]frontq_rptr = 0;
    reg [FRONTQ_PTR_W-1:0]frontq_wptr = 0;
    reg [FRONTQ_COUNT_W-1:0]frontq_count = 0;
    // Last enqueued fetch slot id, used to suppress stale duplicate packets
    // that can appear during replay/redirect recovery.
    reg frontq_last_slot_valid = 1'b0;
    reg [31:0]frontq_last_slot = 32'd0;
    // Accepted-request tags from mem.v are pipelined alongside fetch metadata
    // so frontq enqueue only occurs for requests that were actually issued.
    reg fetch_accept_a = 1'b0;
    reg fetch_accept_b = 1'b0;
    reg [31:0]fetch_tag_a = 32'd0;
    reg [31:0]fetch_tag_b = 32'd0;
    // Replay redirects can leave one or two younger pre-flush fetch packets
    // transiently visible at fetch_b. Those packets are stale and must not
    // trigger another replay redirect, or decode can skip/duplicate slots.
    reg [1:0]frontend_replay_suppress = 2'd0;
    reg decode_stall_prev = 1'b0;
    wire frontq_empty = (frontq_count == 0);
    wire frontq_full = (frontq_count == FRONTQ_DEPTH);
    wire frontq_almost_full = (frontq_count >= FRONTQ_STOP_LEVEL);
    // Stop new fetch issue on backend stalls or queue pressure.
    // In-flight fetch packets are still absorbed by the frontend queue.
    wire frontend_issue_stop =
      stall | decode_stall | frontq_almost_full | halt_or_sleep | halt_pending;
    wire fetch_redirect;
    wire [31:0]fetch_redirect_tgt;
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
    wire mem_re_pipe;
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
    wire [31:0]frontq_instr_head = frontq_instr[frontq_rptr];
    wire [31:0]frontq_pc_head = frontq_pc[frontq_rptr];
    wire [31:0]frontq_slot_head = frontq_slot[frontq_rptr];
    wire [7:0]frontq_exc_head = frontq_exc[frontq_rptr];
    wire frontq_bubble_head = frontq_bubble[frontq_rptr];
    wire [31:0]decode_instr_in = frontq_empty ? 32'd0 : frontq_instr_head;
    wire decode_bubble_in = frontq_empty ? 1'b1 : frontq_bubble_head;
    wire [31:0]decode_pc_in = frontq_empty ? 32'd0 : frontq_pc_head;
    wire [31:0]decode_slot_in = frontq_empty ? 32'd0 : frontq_slot_head;
    wire [7:0]decode_exc_in = frontq_empty ? 8'd0 : frontq_exc_head;

    tlb_fetch tlb_fetch(clk, pipe_clk_en, frontend_issue_stop, mem_read0_accepted, fetch_redirect, fetch_redirect_tgt,
      exc_in_wb, mem_out_1, rfe_in_wb, epc_curr, 
      fetch_addr, tlb_fetch_pc_out, tlb_fetch_slot_id_out, tlb_fetch_bubble_out, tlb_fetch_exc_out
    );

    wire fetch_b_bubble_out;
    wire [31:0]fetch_b_pc_out;
    wire [7:0]fetch_b_exc_out;

    fetch_a fetch_a(clk, pipe_clk_en, flush, tlb_fetch_bubble_out, tlb_fetch_pc_out, tlb_fetch_slot_id_out,
      tlb_fetch_exc_out, exc_tlb_0,
      fetch_a_bubble_out, fetch_a_pc_out, fetch_a_slot_id_out, fetch_a_exc_out
    );

    fetch_b fetch_b(clk, pipe_clk_en, flush, fetch_a_bubble_out, fetch_a_pc_out, fetch_a_slot_id_out,
      fetch_a_exc_out,
      fetch_b_bubble_out, fetch_b_pc_out, fetch_b_slot_id_out, fetch_b_exc_out
    );
    // Enqueue live frontend packets:
    // - exception slots always enqueue (no instruction word dependency),
    // - normal instruction slots enqueue when response tag matches slot id.
    //   Tag matching is the authoritative pairing signal across stalls.
    wire frontq_slot_exc = (fetch_b_exc_out != 8'd0);
    wire frontq_slot_instr = !fetch_b_bubble_out && !frontq_slot_exc;
    wire frontq_slot_live = frontq_slot_instr || frontq_slot_exc;
    wire frontq_tag_match = (fetch_tag_b == mem_read0_data_tag);
    wire frontq_in_valid = frontq_slot_exc ||
      (fetch_accept_b && frontq_slot_instr && frontq_tag_match);
    // If a normal fetch slot reaches fetch_b but was not accepted by mem.v,
    // replay that PC to avoid silently skipping instructions.
    wire frontend_replay_raw = frontq_slot_instr && !fetch_accept_b;
    wire frontend_replay = frontend_replay_raw &&
      (frontend_replay_suppress == 2'd0) && pipe_clk_en;
    assign fetch_redirect = branch || frontend_replay;
    assign fetch_redirect_tgt = branch ? branch_tgt : fetch_b_pc_out;
    // Decode consumes a queued frontend slot when:
    // - execute is not stalling decode, and
    // - decode is not in steady-state atomic crack hold.
    // The decode_stall rising edge (atomic start) still consumes one slot.
    wire decode_front_take = !frontq_empty && !stall &&
      !(halt_or_sleep || halt_pending) &&
      (!decode_stall || !decode_stall_prev);
    wire frontq_pop = decode_front_take && !flush;
    // Allow enqueue on a full cycle if decode also pops this cycle.
    wire frontq_dup_slot = frontq_in_valid && frontq_last_slot_valid &&
      (fetch_b_slot_id_out == frontq_last_slot);
    wire frontq_push = frontq_in_valid && !frontq_dup_slot && !flush &&
      (!frontq_full || frontq_pop);
    // tlb_fetch drives a real I-fetch request only when it is not taking a
    // redirect/interrupt path and backend flow-control is open.
    assign icache_req_valid =
      !exc_in_wb && !rfe_in_wb && !fetch_redirect && !frontend_issue_stop;

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

    decode decode(clk, pipe_clk_en, flush, halt_or_sleep || halt_pending,
      decode_instr_in, decode_bubble_in, decode_pc_in, decode_slot_in,
      reg_we_1, mem_b_tgt_out_1, reg_write_data_1,
      reg_we_2, mem_b_tgt_out_2, reg_write_data_2,
      wb_no_alias_1, wb_no_alias_2,
      mem_b_tgts_cr_out,
      stall,
      decode_exc_in,

      epc_source, {28'b0, mem_b_flags_out}, flags, tlb_addr_for_creg,
      exc_in_wb, tlb_exc_in_wb, interrupts,
      interrupt_in_wb, rfe_in_wb, rfi_in_wb,
      pid, epc_curr, efg_curr, kmode, decode_exc_out,
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
      decode_stage_stall
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
    wire wb_is_load_out;

    wire [3:0]exec_flags_out;

    wire exec_tgts_cr_out;
    wire [4:0]exec_priv_type_out; 
    wire [1:0]exec_crmov_mode_type_out;
    wire [7:0]exec_exc_out; 
    wire [31:0]exec_pc_out;
    wire [31:0]exec_op1_out; 
    wire [31:0]exec_op2_out;
    wire tlb_mem_bubble_out;
    wire mem_a_bubble_out;
    wire mem_b_bubble_out;
    wire tlb_mem_is_load_out;
    wire mem_a_is_load_out;
    wire mem_b_is_load_out;
    wire tlb_mem_is_store_out;
    wire mem_a_is_store_out;
    wire mem_b_is_store_out;
    wire tlb_mem_no_alias_1;
    wire mem_a_no_alias_1;
    wire mem_b_no_alias_1;

    // When a sleep op is already in-flight (reflected by exec_is_sleep_out),
    // freeze execute immediately so the next younger slot cannot advance.
    execute execute(clk, pipe_clk_en, (halt_or_sleep || exec_is_sleep_out), decode_bubble_out, 
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
      tlb_mem_tgts_cr_out, mem_a_tgts_cr_out, mem_b_tgts_cr_out, wb_tgts_cr_out,
      tlb_mem_no_alias_1, mem_a_no_alias_1, mem_b_no_alias_1, wb_no_alias_1,
      wb_is_load_out,
      decode_pc_out, decode_slot_id_out,
      decode_is_load_out, decode_is_store_out, decode_is_branch_out, 
      tlb_mem_bubble_out, tlb_mem_is_load_out,
      mem_a_bubble_out, mem_a_is_load_out, 
      mem_b_bubble_out, mem_b_is_load_out,
      decode_is_post_inc_out, decode_tgts_cr_out, decode_priv_type_out,
      decode_crmov_mode_type_out, decode_exc_out, exc_in_wb, efg_curr, rfe_in_wb,
      kmode,
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

    wire [7:0]tlb_mem_exc_out;
    wire [7:0]mem_a_exc_out;
    wire [7:0]mem_b_exc_out;
    wire [4:0]tlb_mem_priv_type_out;
    wire [4:0]mem_a_priv_type_out;
    wire [4:0]mem_b_priv_type_out;
    wire [1:0]tlb_mem_crmov_mode_type_out;
    wire [1:0]mem_a_crmov_mode_type_out;
    wire [1:0]mem_b_crmov_mode_type_out;
    // Kernel-mode r31 accesses alias ksp except for crmov instructions.
    // Forwarding/hazard logic uses these tags to avoid mixing alias classes.
    assign tlb_mem_no_alias_1 = kmode && !tlb_mem_bubble_out &&
      !tlb_mem_tgts_cr_out &&
      (tlb_mem_opcode_out == 5'd31) && (tlb_mem_priv_type_out == 5'd1) &&
      ((tlb_mem_crmov_mode_type_out == 2'd1) || (tlb_mem_crmov_mode_type_out == 2'd3));
    assign mem_a_no_alias_1 = kmode && !mem_a_bubble_out &&
      !mem_a_tgts_cr_out &&
      (mem_a_opcode_out == 5'd31) && (mem_a_priv_type_out == 5'd1) &&
      ((mem_a_crmov_mode_type_out == 2'd1) || (mem_a_crmov_mode_type_out == 2'd3));
    assign mem_b_no_alias_1 = kmode && !mem_b_bubble_out &&
      !mem_b_tgts_cr_out &&
      (mem_b_opcode_out == 5'd31) && (mem_b_priv_type_out == 5'd1) &&
      ((mem_b_crmov_mode_type_out == 2'd1) || (mem_b_crmov_mode_type_out == 2'd3));
    // Sleep must not squash older backend stages; only architectural halt does.
    tlb_memory tlb_memory(clk, pipe_clk_en, halt,
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
      mem_re_pipe, store_data, mem_we
    );

    memory memory_a(clk, pipe_clk_en, halt,
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

    memory memory_b(clk, pipe_clk_en, halt,
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

    writeback writeback(clk, pipe_clk_en, halt, mem_b_bubble_out, mem_b_tgt_out_1, mem_b_tgt_out_2,
      mem_b_is_load_out, mem_b_is_store_out,
      mem_b_opcode_out,
      mem_b_result_out_1, mem_b_result_out_2, mem_out_1, mem_b_addr_out,
      mem_b_exc_out, mem_b_tgts_cr_out, mem_b_priv_type_out, mem_b_crmov_mode_type_out,
      
      reg_write_data_1, reg_write_data_2,
      reg_we_1, wb_tgt_out_1, wb_result_out_1,
      reg_we_2, wb_tgt_out_2, wb_result_out_2,
      wb_no_alias_1, wb_no_alias_2,
      wb_tgts_cr_out, wb_is_load_out,
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

    tlb tlb(clk, pipe_clk_en, kmode, pid_for_tlb,
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
    // Exception/interrupt entry jumps through IVT[exc_code].
    // Keep memory port 1 read-enabled while an exception is in flight so
    // mem_out_1 is refreshed with the IVT entry even without an explicit load.
    assign mem_re = mem_re_pipe || exception_in_pipe;
    wire wb_redirect = exc_in_wb || rfe_in_wb || wb_halt || wb_sleep;
    // Frontend replay redirects fetch only; full pipeline flush remains tied to
    // architectural redirects (branch/exception/rfe/halt/sleep).
    assign flush = branch || wb_redirect ||
      exec_is_sleep_out || exception_in_pipe;
    assign halt_pending = kmode && !rfe_in_wb && !exception_in_pipe && (
      decode_has_halt || exec_has_halt || tlb_mem_has_halt ||
      mem_a_has_halt || mem_b_has_halt || wb_halt
    );

    // Frontend packet queue update.
    // This decouples fetch return timing from decode stalls and keeps
    // instruction/pc/slot/exception packets paired.
    always @(posedge clk) begin
      if (pipe_clk_en) begin
        if (flush) begin
          frontq_rptr <= 0;
          frontq_wptr <= 0;
          frontq_count <= 0;
          frontq_last_slot_valid <= 1'b0;
          frontq_last_slot <= 32'd0;
          fetch_accept_a <= 1'b0;
          fetch_accept_b <= 1'b0;
          fetch_tag_a <= 32'd0;
          fetch_tag_b <= 32'd0;
          // Preserve suppression countdown across flush so stale packets that
          // are already in flight do not immediately retrigger replay.
          if (frontend_replay) begin
            frontend_replay_suppress <= 2'd2;
          end else if (frontend_replay_suppress != 2'd0) begin
            frontend_replay_suppress <= frontend_replay_suppress - 2'd1;
          end
        end else begin
          fetch_accept_a <= mem_read0_accepted;
          fetch_accept_b <= fetch_accept_a;
          fetch_tag_a <= mem_read0_tag;
          fetch_tag_b <= fetch_tag_a;
          if (frontend_replay) begin
            frontend_replay_suppress <= 2'd2;
          end else if (frontend_replay_suppress != 2'd0) begin
            frontend_replay_suppress <= frontend_replay_suppress - 2'd1;
          end
          if (frontq_push) begin
            frontq_instr[frontq_wptr] <= mem_out_0;
            frontq_pc[frontq_wptr] <= fetch_b_pc_out;
            frontq_slot[frontq_wptr] <= fetch_b_slot_id_out;
            frontq_exc[frontq_wptr] <= fetch_b_exc_out;
            frontq_bubble[frontq_wptr] <= fetch_b_bubble_out;
            frontq_last_slot_valid <= 1'b1;
            frontq_last_slot <= fetch_b_slot_id_out;
            if ($test$plusargs("frontq_watch") &&
                (fetch_b_pc_out >= 32'h000216C0) && (fetch_b_pc_out <= 32'h00021700)) begin
              $display("[frontq_watch][push] pc=%h sid=%0d instr=%h exc=%h bub=%b facc_b=%b tag_b=%0d data_tag=%0d tag_match=%b",
                fetch_b_pc_out, fetch_b_slot_id_out, mem_out_0, fetch_b_exc_out, fetch_b_bubble_out,
                fetch_accept_b, fetch_tag_b, mem_read0_data_tag, frontq_tag_match);
            end
          end
          if ($test$plusargs("frontq_watch") &&
              (fetch_b_pc_out >= 32'h000216C0) && (fetch_b_pc_out <= 32'h00021700) &&
              !frontq_push && frontq_slot_live) begin
            $display("[frontq_watch][drop] pc=%h sid=%0d exc=%h bub=%b facc_b=%b tag_b=%0d data_tag=%0d in_valid=%b dup=%b flush=%b full=%b pop=%b",
              fetch_b_pc_out, fetch_b_slot_id_out, fetch_b_exc_out, fetch_b_bubble_out,
              fetch_accept_b, fetch_tag_b, mem_read0_data_tag, frontq_in_valid,
              frontq_dup_slot, flush, frontq_full, frontq_pop);
          end
          case ({frontq_push, frontq_pop})
            2'b10: begin
              frontq_wptr <= frontq_wptr + 1'b1;
              frontq_count <= frontq_count + 1'b1;
            end
            2'b01: begin
              frontq_rptr <= frontq_rptr + 1'b1;
              frontq_count <= frontq_count - 1'b1;
            end
            2'b11: begin
              frontq_wptr <= frontq_wptr + 1'b1;
              frontq_rptr <= frontq_rptr + 1'b1;
            end
            default: begin
            end
          endcase
        end
        decode_stall_prev <= flush ? 1'b0 : decode_stall;
      end
    end

    always @(posedge clk) begin
      if (pipe_clk_en) begin
`ifdef SIMULATION
        if ($test$plusargs("cpu_debug")) begin
          $display("[cpu] dpc=%h dop=%0d dt1=%0d dt2=%0d db=%b de=%h | eop=%0d et1=%0d et2=%0d eb=%b ee=%h | mbo=%0d mbt1=%0d mbr1=%h mbb=%b wbt1=%0d wwe=%b wr1=%h | wb_exc=%b rfe=%b fstop=%b",
            decode_pc_out, decode_opcode_out, decode_tgt_out_1, decode_tgt_out_2, decode_bubble_out, decode_exc_out,
            exec_opcode_out, exec_tgt_out_1, exec_tgt_out_2, exec_bubble_out, exec_exc_out,
            mem_b_opcode_out, mem_b_tgt_out_1, mem_b_result_out_1, mem_b_bubble_out, wb_tgt_out_1, reg_we_1, reg_write_data_1,
            exc_in_wb, rfe_in_wb, frontend_issue_stop);
        end
`endif
        if ($test$plusargs("ctx_watch") &&
            (flush || branch || wb_redirect || exception_in_pipe) &&
            (
              ((decode_pc_out >= 32'h000213F0) && (decode_pc_out <= 32'h00021580)) ||
              ((exec_pc_out >= 32'h000213F0) && (exec_pc_out <= 32'h00021580)) ||
              ((branch_tgt >= 32'h000213F0) && (branch_tgt <= 32'h00021580)) ||
              ((fetch_b_pc_out >= 32'h000213F0) && (fetch_b_pc_out <= 32'h00021580)) ||
              ((fetch_redirect_tgt >= 32'h000213F0) && (fetch_redirect_tgt <= 32'h00021580)) ||
              ((decode_pc_out >= 32'h00023510) && (decode_pc_out <= 32'h00023570)) ||
              ((exec_pc_out >= 32'h00023510) && (exec_pc_out <= 32'h00023570)) ||
              ((branch_tgt >= 32'h00023510) && (branch_tgt <= 32'h00023570)) ||
              ((fetch_b_pc_out >= 32'h00023510) && (fetch_b_pc_out <= 32'h00023570)) ||
              ((fetch_redirect_tgt >= 32'h00023510) && (fetch_redirect_tgt <= 32'h00023570)) ||
              ((decode_pc_out >= 32'h00016540) && (decode_pc_out <= 32'h00016C20)) ||
              ((exec_pc_out >= 32'h00016540) && (exec_pc_out <= 32'h00016C20)) ||
              ((branch_tgt >= 32'h00016540) && (branch_tgt <= 32'h00016C20)) ||
              ((fetch_b_pc_out >= 32'h00016540) && (fetch_b_pc_out <= 32'h00016C20)) ||
              ((fetch_redirect_tgt >= 32'h00016540) && (fetch_redirect_tgt <= 32'h00016C20)) ||
              ((decode_pc_out >= 32'h00011180) && (decode_pc_out <= 32'h000112A0)) ||
              ((exec_pc_out >= 32'h00011180) && (exec_pc_out <= 32'h000112A0)) ||
              ((branch_tgt >= 32'h00011180) && (branch_tgt <= 32'h000112A0)) ||
              ((fetch_b_pc_out >= 32'h00011180) && (fetch_b_pc_out <= 32'h000112A0)) ||
              ((fetch_redirect_tgt >= 32'h00011180) && (fetch_redirect_tgt <= 32'h000112A0)) ||
              ((decode_pc_out >= 32'h00010780) && (decode_pc_out <= 32'h00010C20)) ||
              ((exec_pc_out >= 32'h00010780) && (exec_pc_out <= 32'h00010C20)) ||
              ((branch_tgt >= 32'h00010780) && (branch_tgt <= 32'h00010C20)) ||
              ((fetch_b_pc_out >= 32'h00010780) && (fetch_b_pc_out <= 32'h00010C20)) ||
              ((fetch_redirect_tgt >= 32'h00010780) && (fetch_redirect_tgt <= 32'h00010C20))
            )) begin
          $display("[ctx_watch][cpu] dpc=%h epc=%h fpc=%h br=%b btgt=%h wb_red=%b ex_pipe=%b exwb=%b rfe=%b wh=%b ws=%b ex_sleep=%b flush=%b fr=%b fr_tgt=%h fpop=%b fpush=%b fq=%0d",
                   decode_pc_out, exec_pc_out, fetch_b_pc_out,
                   branch, branch_tgt, wb_redirect, exception_in_pipe,
                   exc_in_wb, rfe_in_wb, wb_halt, wb_sleep, exec_is_sleep_out,
                   flush, fetch_redirect, fetch_redirect_tgt,
                   frontq_pop, frontq_push, frontq_count);
        end
        if (mem_b_tlb_fault_live) begin
          tlb_fault_addr_latched <= {12'b0, mem_b_addr_out[31:12]};
        end
        halt <= halt ? 1 : wb_halt;
        sleep <= sleep ? (interrupt_state == 32'b0) : exec_is_sleep_out;
        if (exec_is_sleep_out) begin
          // Resume after the sleep instruction that reached execute.
          // Using decode_pc_out here can capture a younger/stale slot PC
          // when decode is stalled or being flushed.
          sleep_pc <= exec_pc_out + 32'd4;
        end
        if (interrupt_in_wb) begin
          sleep_interrupt_pending <= 1'b0;
        end else if (sleep && interrupt_state != 32'b0) begin
          sleep_interrupt_pending <= 1'b1;
        end
      end

      // Memory-mapped clock divider:
      // - 0 => run every cycle.
      // - N => emit one enabled cycle every (N+1) base clocks.
      if (clock_divider == 32'd0) begin
        clk_en <= 1'b1;
        clk_div_count <= 32'd0;
      end else if (clk_div_count >= clock_divider) begin
        clk_en <= 1'b1;
        clk_div_count <= 32'd0;
      end else begin
        clk_en <= 1'b0;
        clk_div_count <= clk_div_count + 32'd1;
      end
    end

endmodule
