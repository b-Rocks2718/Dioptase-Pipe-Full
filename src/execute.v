`timescale 1ps/1ps

// Execute stage.
//
// Purpose:
// - Apply GPR/CR forwarding and load-use hazard detection.
// - Run ALU operations and branch resolution.
// - Form memory requests (address, byte-lane write mask, store data).
// - Register execute outputs with stall-safe forwarding for dependent slots.
//
// Contracts:
// - `stall` means decode must hold its current slot.
// - `slot_kill` must gate every outward payload field so killed slots do not
//   forward partial state into older stages.
// - Atomic cracked micro-ops use buffered operands captured at step 0 so
//   aliasing cases remain architecturally atomic.
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
    input tlb_mem_tgts_cr, input mem_a_tgts_cr, input mem_b_tgts_cr, input wb_tgts_cr,
    input tlb_mem_no_alias_1, input mem_a_no_alias_1, input mem_b_no_alias_1, input wb_no_alias_1,
    input wb_load,
    
    input [31:0]decode_pc_out, input [31:0]slot_id,

    input is_load, input is_store, input is_branch, 
    input tlb_mem_bubble, input tlb_mem_is_load,
    input mem_a_bubble, input mem_a_load, 
    input mem_b_bubble, input mem_b_load,
    input is_post_inc, input tgts_cr,
    input [4:0]priv_type, input [1:0]crmov_mode_type,
    input [7:0]exc_in, input exc_in_wb, input [31:0]flags_restore, input rfe_in_wb,
    input kmode,
    input is_atomic, input is_fetch_add_atomic, input [1:0]atomic_step,

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
    no_alias_buf_a_1 = 0;
    no_alias_buf_b_1 = 0;
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
    replay_dedup_active = 1'b0;
    stall_prev = 1'b0;
    last_decode_sig = {REPLAY_SIG_W{1'b0}};
    atomic_base_buf = 32'd0;
    atomic_data_buf = 32'd0;
    atomic_fadd_sum_buf = 32'd0;
    stall_hist_1 = 1'b0;
    stall_hist_2 = 1'b0;
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
  reg no_alias_buf_a_1;
  reg no_alias_buf_b_1;
  reg replay_dedup_active;
  reg stall_prev;
  // Packed signature for duplicate filtering across stall-release windows. This
  // replaces a large field-by-field
  // register set while preserving the same behavior.
  localparam REPLAY_SIG_W = 114;
  reg [REPLAY_SIG_W-1:0]last_decode_sig;
  reg [31:0]atomic_base_buf;
  reg [31:0]atomic_data_buf;
  reg [31:0]atomic_fadd_sum_buf;
  reg stall_hist_1;
  reg stall_hist_2;
  // Keep forwarding buffers valid for up to two cycles after a stall clears,
  // so repeated slots can still see the most recent writeback values.
  wire stall_buf_valid = stall || stall_hist_1 || stall_hist_2;

  wire is_mem_w = (5'd3 <= opcode && opcode <= 5'd5);
  wire is_mem_d = (5'd6 <= opcode && opcode <= 5'd8);
  wire is_mem_b = (5'd9 <= opcode && opcode <= 5'd11);
  wire s1_nonzero = (s_1 != 5'd0);
  wire s2_nonzero = (s_2 != 5'd0);
  wire is_crmov = (opcode == 5'd31) && (priv_type == 5'd1);
  wire source_no_alias_s1 = kmode && is_crmov && (s_1 == 5'd31);
  wire source_no_alias_s2 = kmode && is_crmov && (s_2 == 5'd31);
  wire ex1_no_alias = kmode && !tgts_cr_out &&
    (opcode_out == 5'd31) && (priv_type_out == 5'd1) &&
    ((crmov_mode_type_out == 2'd1) || (crmov_mode_type_out == 2'd3)) &&
    (tgt_out_1 == 5'd31);
  wire ex1_gpr_valid = !tgts_cr_out;
  wire tlbm1_gpr_valid = !tlb_mem_tgts_cr;
  wire mema1_gpr_valid = !mem_a_tgts_cr;
  wire memb1_gpr_valid = !mem_b_tgts_cr;
  wire wb1_gpr_valid = !wb_tgts_cr;
  wire buf_a1_gpr_valid = !tgts_cr_buf_a;
  wire buf_b1_gpr_valid = !tgts_cr_buf_b;

  // Forwarding priority is newest-to-oldest pipeline producer, then local
  // stall history buffers, then regfile output.
  wire ex1_hit_s1 = s1_nonzero && ex1_gpr_valid && (tgt_out_1 == s_1) &&
    ((s_1 != 5'd31) || (source_no_alias_s1 == ex1_no_alias));
  wire ex2_hit_s1 = s1_nonzero && (tgt_out_2 == s_1);
  wire tlbm1_hit_s1 = s1_nonzero && tlbm1_gpr_valid && (tlb_mem_tgt_1 == s_1) &&
    ((s_1 != 5'd31) || (source_no_alias_s1 == tlb_mem_no_alias_1));
  wire tlbm2_hit_s1 = s1_nonzero && (tlb_mem_tgt_2 == s_1);
  wire mema1_hit_s1 = s1_nonzero && mema1_gpr_valid && (mem_a_tgt_1 == s_1) &&
    ((s_1 != 5'd31) || (source_no_alias_s1 == mem_a_no_alias_1));
  wire mema2_hit_s1 = s1_nonzero && (mem_a_tgt_2 == s_1);
  wire memb1_hit_s1 = s1_nonzero && memb1_gpr_valid && (mem_b_tgt_1 == s_1) &&
    ((s_1 != 5'd31) || (source_no_alias_s1 == mem_b_no_alias_1));
  wire memb2_hit_s1 = s1_nonzero && (mem_b_tgt_2 == s_1);
  wire wb1_hit_s1 = s1_nonzero && wb1_gpr_valid && (wb_tgt_1 == s_1) &&
    ((s_1 != 5'd31) || (source_no_alias_s1 == wb_no_alias_1));
  wire wb2_hit_s1 = s1_nonzero && (wb_tgt_2 == s_1);
  wire buf_a1_hit_s1 = stall_buf_valid && s1_nonzero && buf_a1_gpr_valid && (reg_tgt_buf_a_1 == s_1) &&
    ((s_1 != 5'd31) || (source_no_alias_s1 == no_alias_buf_a_1));
  wire buf_a2_hit_s1 = stall_buf_valid && s1_nonzero && (reg_tgt_buf_a_2 == s_1);
  wire buf_b1_hit_s1 = stall_buf_valid && s1_nonzero && buf_b1_gpr_valid && (reg_tgt_buf_b_1 == s_1) &&
    ((s_1 != 5'd31) || (source_no_alias_s1 == no_alias_buf_b_1));
  wire buf_b2_hit_s1 = stall_buf_valid && s1_nonzero && (reg_tgt_buf_b_2 == s_1);

  wire ex1_hit_s2 = s2_nonzero && ex1_gpr_valid && (tgt_out_1 == s_2) &&
    ((s_2 != 5'd31) || (source_no_alias_s2 == ex1_no_alias));
  wire ex2_hit_s2 = s2_nonzero && (tgt_out_2 == s_2);
  wire tlbm1_hit_s2 = s2_nonzero && tlbm1_gpr_valid && (tlb_mem_tgt_1 == s_2) &&
    ((s_2 != 5'd31) || (source_no_alias_s2 == tlb_mem_no_alias_1));
  wire tlbm2_hit_s2 = s2_nonzero && (tlb_mem_tgt_2 == s_2);
  wire mema1_hit_s2 = s2_nonzero && mema1_gpr_valid && (mem_a_tgt_1 == s_2) &&
    ((s_2 != 5'd31) || (source_no_alias_s2 == mem_a_no_alias_1));
  wire mema2_hit_s2 = s2_nonzero && (mem_a_tgt_2 == s_2);
  wire memb1_hit_s2 = s2_nonzero && memb1_gpr_valid && (mem_b_tgt_1 == s_2) &&
    ((s_2 != 5'd31) || (source_no_alias_s2 == mem_b_no_alias_1));
  wire memb2_hit_s2 = s2_nonzero && (mem_b_tgt_2 == s_2);
  wire wb1_hit_s2 = s2_nonzero && wb1_gpr_valid && (wb_tgt_1 == s_2) &&
    ((s_2 != 5'd31) || (source_no_alias_s2 == wb_no_alias_1));
  wire wb2_hit_s2 = s2_nonzero && (wb_tgt_2 == s_2);
  wire buf_a1_hit_s2 = stall_buf_valid && s2_nonzero && buf_a1_gpr_valid && (reg_tgt_buf_a_1 == s_2) &&
    ((s_2 != 5'd31) || (source_no_alias_s2 == no_alias_buf_a_1));
  wire buf_a2_hit_s2 = stall_buf_valid && s2_nonzero && (reg_tgt_buf_a_2 == s_2);
  wire buf_b1_hit_s2 = stall_buf_valid && s2_nonzero && buf_b1_gpr_valid && (reg_tgt_buf_b_1 == s_2) &&
    ((s_2 != 5'd31) || (source_no_alias_s2 == no_alias_buf_b_1));
  wire buf_b2_hit_s2 = stall_buf_valid && s2_nonzero && (reg_tgt_buf_b_2 == s_2);

  assign op1 = 
    ex1_hit_s1 ? result_1 :
    ex2_hit_s1 ? result_2 :
    tlbm1_hit_s1 ? tlb_mem_result_out_1 :
    tlbm2_hit_s1 ? tlb_mem_result_out_2 :
    mema1_hit_s1 ? mem_a_result_out_1 : 
    mema2_hit_s1 ? mem_a_result_out_2 : 
    memb1_hit_s1 ? mem_b_result_out_1 :
    memb2_hit_s1 ? mem_b_result_out_2 :
    wb1_hit_s1 ? wb_result_out_1 :
    wb2_hit_s1 ? wb_result_out_2 :
    buf_a1_hit_s1 ? reg_data_buf_a_1 :
    buf_a2_hit_s1 ? reg_data_buf_a_2 :
    buf_b1_hit_s1 ? reg_data_buf_b_1 :
    buf_b2_hit_s1 ? reg_data_buf_b_2 :
    reg_out_1;

  assign op2 = 
    ex1_hit_s2 ? result_1 :
    ex2_hit_s2 ? result_2 :
    tlbm1_hit_s2 ? tlb_mem_result_out_1 :
    tlbm2_hit_s2 ? tlb_mem_result_out_2 :
    mema1_hit_s2 ? mem_a_result_out_1 : 
    mema2_hit_s2 ? mem_a_result_out_2 : 
    memb1_hit_s2 ? mem_b_result_out_1 :
    memb2_hit_s2 ? mem_b_result_out_2 :
    wb1_hit_s2 ? wb_result_out_1 :
    wb2_hit_s2 ? wb_result_out_2 :
    buf_a1_hit_s2 ? reg_data_buf_a_1 :
    buf_a2_hit_s2 ? reg_data_buf_a_2 :
    buf_b1_hit_s2 ? reg_data_buf_b_1 :
    buf_b2_hit_s2 ? reg_data_buf_b_2 :
    reg_out_2;

  // Atomic cracked micro-ops use a snapshot of forwarded operands from the
  // first micro-op so aliasing cases observe architecturally atomic behavior.
  wire [31:0]atomic_op1 =
    (is_atomic && is_fetch_add_atomic && atomic_step == 2'd1) ? atomic_data_buf :
    (is_atomic && is_store) ? atomic_base_buf :
    op1;
  wire [31:0]atomic_op2 =
    (is_atomic && !is_fetch_add_atomic && is_store) ? atomic_data_buf :
    op2;
  wire fadd_add_step = is_atomic && is_fetch_add_atomic && (atomic_step == 2'd1);
  wire fadd_store_step = is_atomic && is_fetch_add_atomic && is_store;
  // Decode may present a live trap slot (`bubble_in=0`, `exc_in!=0`) so
  // writeback can retire the exception. Treat it as killed for execute
  // side-effects.
  wire exc_slot = (exc_in != 8'd0);
  wire crmov_reads_creg = is_crmov &&
    (crmov_mode_type == 2'd1 || crmov_mode_type == 2'd2);
  wire [4:0]dep_s1 = crmov_reads_creg ? 5'd0 : s_1;
  wire [4:0]dep_s2 = is_crmov ? 5'd0 : s_2;
  wire decode_live = !bubble_in && !exc_slot && !exc_in_wb && !rfe_in_wb;

  wire ex1_dep_hit = ex1_gpr_valid && (tgt_out_1 != 5'd0) &&
    ((tgt_out_1 != 5'd31) || (source_no_alias_s1 == ex1_no_alias) ||
      (source_no_alias_s2 == ex1_no_alias)) &&
    ((tgt_out_1 == dep_s1) || (tgt_out_1 == dep_s2));
  wire ex2_dep_hit = (tgt_out_2 != 5'd0) &&
    ((tgt_out_2 == dep_s1) || (tgt_out_2 == dep_s2));
  wire tlbm1_dep_hit = tlbm1_gpr_valid && (tlb_mem_tgt_1 != 5'd0) &&
    ((tlb_mem_tgt_1 != 5'd31) || (source_no_alias_s1 == tlb_mem_no_alias_1) ||
      (source_no_alias_s2 == tlb_mem_no_alias_1)) &&
    ((tlb_mem_tgt_1 == dep_s1) || (tlb_mem_tgt_1 == dep_s2));
  wire tlbm2_dep_hit = (tlb_mem_tgt_2 != 5'd0) &&
    ((tlb_mem_tgt_2 == dep_s1) || (tlb_mem_tgt_2 == dep_s2));
  wire mema1_dep_hit = mema1_gpr_valid && (mem_a_tgt_1 != 5'd0) &&
    ((mem_a_tgt_1 != 5'd31) || (source_no_alias_s1 == mem_a_no_alias_1) ||
      (source_no_alias_s2 == mem_a_no_alias_1)) &&
    ((mem_a_tgt_1 == dep_s1) || (mem_a_tgt_1 == dep_s2));
  wire mema2_dep_hit = (mem_a_tgt_2 != 5'd0) &&
    ((mem_a_tgt_2 == dep_s1) || (mem_a_tgt_2 == dep_s2));
  wire memb1_dep_hit = memb1_gpr_valid && (mem_b_tgt_1 != 5'd0) &&
    ((mem_b_tgt_1 != 5'd31) || (source_no_alias_s1 == mem_b_no_alias_1) ||
      (source_no_alias_s2 == mem_b_no_alias_1)) &&
    ((mem_b_tgt_1 == dep_s1) || (mem_b_tgt_1 == dep_s2));
  wire memb2_dep_hit = (mem_b_tgt_2 != 5'd0) &&
    ((mem_b_tgt_2 == dep_s1) || (mem_b_tgt_2 == dep_s2));
  wire ex_dep_hit = ex1_dep_hit || ex2_dep_hit;
  wire tlb_mem_dep_hit = tlbm1_dep_hit || tlbm2_dep_hit;
  wire mem_a_dep_hit = mema1_dep_hit || mema2_dep_hit;
  wire mem_b_dep_hit = memb1_dep_hit || memb2_dep_hit;

  // Load-use stall checks apply only to true GPR dependencies.
  // CR dependencies are handled by dedicated control-register forwarding.
  assign stall = decode_live && (
    // Dependencies on a load or tlbr must stall until a forwardable value exists.
    // With the dedicated tlb_memory stage, load data is not available until writeback.
    (ex_dep_hit && (is_load_out || is_tlbr_out) && !bubble_out) ||
    (tlb_mem_dep_hit && tlb_mem_is_load && !tlb_mem_bubble) ||
    (mem_a_dep_hit && mem_a_load && !mem_a_bubble) ||
    (mem_b_dep_hit && mem_b_load && !mem_b_bubble)
  );

  // Forward CR reads for crmv (rA, crB / crA, crB). This keeps CR RAW
  // dependencies precise without stalling and preserves behavior under
  // prolonged execute stalls via WB-captured buffers.
  wire ex_cr_hit = crmov_reads_creg && (cr_s != 5'd0) &&
    tgts_cr_out && (tgt_out_1 == cr_s);
  wire tlb_mem_cr_hit = crmov_reads_creg && (cr_s != 5'd0) &&
    tlb_mem_tgts_cr && (tlb_mem_tgt_1 == cr_s);
  wire mem_a_cr_hit = crmov_reads_creg && (cr_s != 5'd0) &&
    mem_a_tgts_cr && (mem_a_tgt_1 == cr_s);
  wire mem_b_cr_hit = crmov_reads_creg && (cr_s != 5'd0) &&
    mem_b_tgts_cr && (mem_b_tgt_1 == cr_s);
  wire wb_cr_hit = crmov_reads_creg && (cr_s != 5'd0) &&
    wb_tgts_cr && (wb_tgt_1 == cr_s);
  wire buf_a_cr_hit = crmov_reads_creg && (cr_s != 5'd0) && stall_buf_valid &&
    tgts_cr_buf_a && (reg_tgt_buf_a_1 == cr_s);
  wire buf_b_cr_hit = crmov_reads_creg && (cr_s != 5'd0) && stall_buf_valid &&
    tgts_cr_buf_b && (reg_tgt_buf_b_1 == cr_s);
  wire [31:0]cr_op =
    ex_cr_hit ? result_1 :
    tlb_mem_cr_hit ? tlb_mem_result_out_1 :
    mem_a_cr_hit ? mem_a_result_out_1 :
    mem_b_cr_hit ? mem_b_result_out_1 :
    wb_cr_hit ? wb_result_out_1 :
    buf_a_cr_hit ? reg_data_buf_a_1 :
    buf_b_cr_hit ? reg_data_buf_b_1 :
    reg_out_cr;

  wire opening_after_stall = stall_prev && !stall && !bubble_in && !exc_in_wb && !rfe_in_wb;
  // Duplicate identity includes both payload and slot tag so stale copies are
  // dropped while true new work that happens to share opcode/immediates still retires.
  wire [REPLAY_SIG_W-1:0]decode_sig = {
    slot_id, opcode, s_1, s_2, tgt_1, tgt_2, alu_op, branch_code,
    imm, is_load, is_store, is_branch, is_post_inc, priv_type, crmov_mode_type,
    is_atomic, is_fetch_add_atomic, atomic_step
  };
  // When a load-use stall opens, stale decode copies can reappear in execute.
  // Drop repeated decode signatures until decode advances to new work.
  //
  // Invariant:
  // - `slot_id` is part of `decode_sig`, so true new work is never dropped just
  //   because payload fields match an older slot.
  wire exec_dup = replay_dedup_active && !stall && !bubble_in &&
    !exc_in_wb && !rfe_in_wb && (decode_sig == last_decode_sig);

  // ISA subtract-immediate uses immediate as lhs and register as rhs.
  // This mux keeps ALU op encoding unchanged while honoring that semantic.
  wire [31:0]lhs = (opcode == 5'd1 && alu_op == 5'd16) ? imm : atomic_op1;
  wire [31:0]rhs = ((opcode == 5'd1 && alu_op != 5'd16) || (opcode == 5'd2) || 
                  (5'd3 <= opcode && opcode <= 5'd11) || (opcode == 5'd22)) ? 
                    imm : (opcode == 5'd1 && alu_op == 5'd16) ? atomic_op1 : atomic_op2;

  wire we_bit = is_store && !bubble_in && !exc_slot && !exc_in_wb
                && !rfe_in_wb && !stall && !exec_dup;
  wire crmv_writes_cr = is_crmov &&
    ((crmov_mode_type == 2'd0) || (crmov_mode_type == 2'd2));
  // cr9 (CID) is read-only; suppress architectural control-register writeback.
  wire cr_write_allowed = !((tgt_1 == 5'd9) && crmv_writes_cr);
  wire [31:0]crmv_write_data = crmov_reads_creg ? cr_op : op1;
  // ISA: cr5 is FLG, so crmv writes to cr5 must update live ALU flags.
  wire crmv_write_flg_live = crmv_writes_cr && (tgt_1 == 5'd5) &&
    !bubble_in && !stall && !exc_in_wb && !rfe_in_wb &&
    !halt && !exec_dup && (exc_in == 8'd0);
  wire [31:0]flags_restore_mux = crmv_write_flg_live ? crmv_write_data : flags_restore;
  wire flags_we = rfe_in_wb || crmv_write_flg_live;

  wire [31:0]alu_rslt;
  // Do not let killed/exception slots mutate live flags.
  wire alu_bubble = bubble_in || exc_slot || exc_in_wb || stall || exec_dup || halt;
  ALU ALU(clk, clk_en, opcode, alu_op, lhs, rhs, decode_pc_out, alu_bubble,
    flags_restore_mux, flags_we,
    alu_rslt, flags);

  // A killed execute slot must not forward partial payload into later stages.
  wire slot_kill = bubble_in || exc_in_wb || rfe_in_wb || stall || exec_dup || halt;

  // Memory effective address used by this execute slot.
  // Keep this as a wire so byte/halfword lane selection uses the current
  // instruction address (not the registered `addr` from a previous cycle).
  wire [31:0]mem_addr =
    (opcode == 5'd3 || opcode == 5'd6 || opcode == 5'd9) ? (is_post_inc ? atomic_op1 : alu_rslt) : // absolute mem
    (opcode == 5'd4 || opcode == 5'd7 || opcode == 5'd10) ? alu_rslt + decode_pc_out + 32'h4 : // relative mem
    (opcode == 5'd5 || opcode == 5'd8 || opcode == 5'd11) ? alu_rslt + decode_pc_out + 32'h4 : // relative immediate mem
    32'h0;

  // Byte/halfword stores must target the addressed lane(s) within the word.
  wire [31:0]atomic_store_data = fadd_store_step ? atomic_fadd_sum_buf : atomic_op2;
  wire [31:0]store_data_next =
    is_mem_b ? (
      (!mem_addr[1] && !mem_addr[0]) ? (atomic_store_data & 32'hff) :
      (!mem_addr[1] &&  mem_addr[0]) ? ((atomic_store_data & 32'hff) << 8) :
      ( mem_addr[1] && !mem_addr[0]) ? ((atomic_store_data & 32'hff) << 16) :
      ( mem_addr[1] &&  mem_addr[0]) ? ((atomic_store_data & 32'hff) << 24) :
      32'h0
    ) :
    is_mem_d ? (
      mem_addr[1] ? ((atomic_store_data & 32'hffff) << 16) : (atomic_store_data & 32'hffff)
    ) :
    atomic_store_data;

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
      no_alias_buf_a_1 <= 1'b0;
      reg_tgt_buf_b_1 <= 5'd0;
      reg_tgt_buf_b_2 <= 5'd0;
      reg_data_buf_b_1 <= 32'd0;
      reg_data_buf_b_2 <= 32'd0;
      tgts_cr_buf_b <= 1'b0;
      no_alias_buf_b_1 <= 1'b0;
      atomic_base_buf <= 32'd0;
      atomic_data_buf <= 32'd0;
      atomic_fadd_sum_buf <= 32'd0;
      replay_dedup_active <= 1'b0;
      stall_prev <= 1'b0;
      last_decode_sig <= {REPLAY_SIG_W{1'b0}};
      stall_hist_1 <= 1'b0;
      stall_hist_2 <= 1'b0;
    end else begin
              // jump and link
      result_1 <= slot_kill ? 32'd0 :
                  (opcode == 5'd13 || opcode == 5'd14) ? decode_pc_out + 32'd4 : 
                  // crmov control-register source
                  (is_crmov && crmov_reads_creg) ? cr_op :
                  // crmov general-register source
                  (is_crmov) ? op1 :
                  // everything else
                  alu_rslt;

      result_2 <= slot_kill ? 32'd0 : alu_rslt;
      tgt_out_1 <= (slot_kill || fadd_add_step) ? 5'd0 : tgt_1;
      tgt_out_2 <= slot_kill ? 5'd0 : tgt_2;
      opcode_out <= slot_kill ? 5'd0 : opcode;
      bubble_out <= slot_kill ? 1'b1 : bubble_in;

      addr <= slot_kill ? 32'd0 : mem_addr;
      mem_re <= is_load && !slot_kill;
      store_data <= slot_kill ? 32'd0 : store_data_next;
      we <= slot_kill ? 4'd0 : we_next;

      if ($test$plusargs("heap_watch") && !slot_kill &&
          (((we_next != 4'd0) &&
            (mem_addr == 32'h00200000 || mem_addr == 32'h00200004 ||
             mem_addr == 32'h00200008 || mem_addr == 32'h0020000C ||
             mem_addr == 32'h00200010 || mem_addr == 32'h00200014)) ||
           (decode_pc_out == 32'h0001454C || decode_pc_out == 32'h00014550 ||
            decode_pc_out == 32'h00014554 || decode_pc_out == 32'h00014558))) begin
        $display("[heap_watch][exec] pc=%h op=%0d s1=r%0d s2=r%0d reg1=%h reg2=%h op1=%h op2=%h mem_addr=%h store=%h we=%b",
                 decode_pc_out, opcode, s_1, s_2, reg_out_1, reg_out_2, op1, op2, mem_addr, store_data_next, we_next);
        $display("[heap_watch][exec] s2 hits ex1=%b ex2=%b tlbm1=%b tlbm2=%b mema1=%b mema2=%b memb1=%b memb2=%b wb1=%b wb2=%b ba1=%b ba2=%b bb1=%b bb2=%b",
                 ex1_hit_s2, ex2_hit_s2, tlbm1_hit_s2, tlbm2_hit_s2, mema1_hit_s2, mema2_hit_s2,
                 memb1_hit_s2, memb2_hit_s2, wb1_hit_s2, wb2_hit_s2, buf_a1_hit_s2, buf_a2_hit_s2,
                 buf_b1_hit_s2, buf_b2_hit_s2);
        $display("[heap_watch][exec] tgts ex=(%0d,%0d) tlbm=(%0d,%0d,b=%b,ld=%b) mema=(%0d,%0d,b=%b,ld=%b) memb=(%0d,%0d,b=%b,ld=%b) wb=(%0d,%0d,b=%b,ld=%b)",
                 tgt_out_1, tgt_out_2,
                 tlb_mem_tgt_1, tlb_mem_tgt_2, tlb_mem_bubble, tlb_mem_is_load,
                 mem_a_tgt_1, mem_a_tgt_2, mem_a_bubble, mem_a_load,
                 mem_b_tgt_1, mem_b_tgt_2, mem_b_bubble, mem_b_load,
                 wb_tgt_1, wb_tgt_2, wb_tgts_cr, wb_load);
      end
      if ($test$plusargs("ctx_watch") &&
          (((decode_pc_out >= 32'h000235A0) && (decode_pc_out <= 32'h00023680)) ||
           ((decode_pc_out >= 32'h00021400) && (decode_pc_out <= 32'h00021580)) ||
           ((decode_pc_out >= 32'h000215C0) && (decode_pc_out <= 32'h00021610)) ||
           ((decode_pc_out >= 32'h00023510) && (decode_pc_out <= 32'h00023570)) ||
           ((decode_pc_out >= 32'h00016540) && (decode_pc_out <= 32'h00016C20)) ||
           ((decode_pc_out >= 32'h00011180) && (decode_pc_out <= 32'h000112A0)) ||
           ((decode_pc_out >= 32'h00010780) && (decode_pc_out <= 32'h00010C20))) ) begin
        $display("[ctx_watch][exec] pc=%h op=%0d s1=r%0d s2=r%0d reg1=%h reg2=%h op1=%h op2=%h mem_addr=%h store=%h we=%b stall=%b sk=%b br=%b taken=%b btgt=%h is_br=%b",
                 decode_pc_out, opcode, s_1, s_2, reg_out_1, reg_out_2,
                 op1, op2, mem_addr, store_data_next, we_next, stall, slot_kill,
                 branch, taken, branch_tgt, is_branch);
      end
      if ($test$plusargs("evloop_watch") &&
          (decode_pc_out >= 32'h000215E0) && (decode_pc_out <= 32'h00021840) &&
          is_branch && !bubble_in) begin
        $display("[evloop_watch][exec] pc=%h bcode=%0d taken=%b branch=%b flags=%b excwb=%b rfewb=%b stall=%b",
                 decode_pc_out, branch_code, taken, branch, flags,
                 exc_in_wb, rfe_in_wb, stall);
      end
      if ($test$plusargs("evloop_memwatch") &&
          (decode_pc_out >= 32'h000215E0) && (decode_pc_out <= 32'h00021840) &&
          !bubble_in && (is_load || is_store)) begin
        $display("[evloop_memwatch][exec] pc=%h op=%0d ld=%b st=%b addr=%h we=%b wdata=%h op1=%h op2=%h",
                 decode_pc_out, opcode, is_load, is_store, mem_addr, we_next,
                 store_data_next, op1, op2);
      end
      if ($test$plusargs("evloop_cmp_watch") &&
          (decode_pc_out >= 32'h000216D0) && (decode_pc_out <= 32'h000216E8) &&
          !bubble_in) begin
        $display("[evloop_cmp_watch][exec] pc=%h op=%0d alu=%0d s1=%0d s2=%0d op1=%h op2=%h lhs=%h rhs=%h flags=%b",
                 decode_pc_out, opcode, alu_op, s_1, s_2, op1, op2, lhs, rhs, flags);
      end
      if ($test$plusargs("barrier_watch") &&
          (((decode_pc_out >= 32'h00011190) && (decode_pc_out <= 32'h00011290)) ||
           ((decode_pc_out >= 32'h00016A70) && (decode_pc_out <= 32'h00016AC0)) ||
           ((decode_pc_out >= 32'h00023510) && (decode_pc_out <= 32'h00023530)) ||
           ((decode_pc_out >= 32'h00023540) && (decode_pc_out <= 32'h00023570))) &&
          !bubble_in) begin
        $display("[barrier_watch][exec] pc=%h sid=%0d op=%0d sk=%b dup=%b st=%b exwb=%b rfewb=%b exc=%h at=%b fadd=%b astep=%0d ld=%b stw=%b maddr=%h we=%b wdata=%h",
                 decode_pc_out, slot_id, opcode, slot_kill, exec_dup, stall, exc_in_wb, rfe_in_wb,
                 exc_in, is_atomic, is_fetch_add_atomic, atomic_step, is_load, is_store, mem_addr, we_next, store_data_next);
      end

      is_load_out <= slot_kill ? 1'b0 : is_load;
      is_store_out <= slot_kill ? 1'b0 : is_store;
      tgts_cr_out <= slot_kill ? 1'b0 : (tgts_cr && cr_write_allowed);
      priv_type_out <= slot_kill ? 5'd0 : priv_type;
      crmov_mode_type_out <= slot_kill ? 2'd0 : crmov_mode_type;

      exc_out <= slot_kill ? 8'h0 : exc_in;

      pc_out <= decode_pc_out;
      op1_out <= slot_kill ? 32'd0 : op1;
      op2_out <= slot_kill ? 32'd0 : op2;

      flags_out <= slot_kill ? 4'd0 : flags;

      is_tlbr_out <= !slot_kill &&
        (opcode == 5'd31 && priv_type == 5'd0 && crmov_mode_type == 2'd0);

      if (stall) begin
        reg_tgt_buf_a_1 <= wb_tgt_1;
        reg_tgt_buf_a_2 <= wb_tgt_2;
        reg_data_buf_a_1 <= wb_result_out_1;
        reg_data_buf_a_2 <= wb_result_out_2;
        tgts_cr_buf_a <= wb_tgts_cr;
        no_alias_buf_a_1 <= wb_no_alias_1;
        reg_tgt_buf_b_1 <= reg_tgt_buf_a_1;
        reg_tgt_buf_b_2 <= reg_tgt_buf_a_2;
        reg_data_buf_b_1 <= reg_data_buf_a_1;
        reg_data_buf_b_2 <= reg_data_buf_a_2;
        tgts_cr_buf_b <= tgts_cr_buf_a;
        no_alias_buf_b_1 <= no_alias_buf_a_1;
      end
      if (!stall && !bubble_in && !exc_in_wb && !rfe_in_wb &&
          is_atomic && (atomic_step == 2'd0)) begin
        atomic_base_buf <= op1;
        atomic_data_buf <= op2;
      end
      if (!stall && !bubble_in && !exc_in_wb && !rfe_in_wb && fadd_add_step) begin
        atomic_fadd_sum_buf <= alu_rslt;
      end
      if (exc_in_wb || rfe_in_wb || halt) begin
        replay_dedup_active <= 1'b0;
      end else if (opening_after_stall) begin
        replay_dedup_active <= 1'b1;
      end else if (replay_dedup_active && !stall && !bubble_in &&
          (decode_sig != last_decode_sig)) begin
        replay_dedup_active <= 1'b0;
      end
      if (!stall && !bubble_in && !exc_in_wb && !rfe_in_wb && !exec_dup) begin
        last_decode_sig <= decode_sig;
      end
`ifdef SIMULATION
      if ($test$plusargs("exec_debug")) begin
        $display("[exec] sid=%0d op=%0d pc=%h stall=%b open=%b dedup=%b dup=%b bub=%b exwb=%b rfe=%b",
          slot_id, opcode, decode_pc_out, stall, opening_after_stall, replay_dedup_active,
          exec_dup, bubble_in, exc_in_wb, rfe_in_wb);
      end
`endif

      stall_prev <= stall;
      stall_hist_2 <= stall_hist_1;
      stall_hist_1 <= stall;
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

  assign branch = !slot_kill && taken && is_branch;
  
  assign branch_tgt = 
            (opcode == 5'd12) ? decode_pc_out + (imm << 2) + 32'h4 :
            (opcode == 5'd13) ? atomic_op1 :
            (opcode == 5'd14) ? decode_pc_out + atomic_op1 + 32'h4 : 
            decode_pc_out + 32'h4;

endmodule
