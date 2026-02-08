`timescale 1ps/1ps

// Execute stage.
//
// Purpose:
// - Apply GPR/CR forwarding and load-use hazard detection.
// - Run ALU operations and branch resolution.
// - Form memory requests (address, byte-lane write mask, store data).
// - Track replay dedup so stale post-stall copies are converted to bubbles.
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
    input mem_a_tgts_cr, input mem_b_tgts_cr, input wb_tgts_cr,
    
    input [31:0]decode_pc_out, input [31:0]slot_id,
    input [4:0]mem_a_opcode_out,
    input [4:0]mem_b_opcode_out,

    input is_load, input is_store, input is_branch, 
    input tlb_mem_bubble, input tlb_mem_is_load,
    input mem_a_bubble, input mem_a_load, 
    input mem_b_bubble, input mem_b_load,
    input is_post_inc, input tgts_cr,
    input [4:0]priv_type, input [1:0]crmov_mode_type,
    input [7:0]exc_in, input exc_in_wb, input [31:0]flags_restore, input rfe_in_wb,
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
    last_opcode_sig = 5'd0;
    last_slot_id_sig = 32'd0;
    last_s1_sig = 5'd0;
    last_s2_sig = 5'd0;
    last_tgt1_sig = 5'd0;
    last_tgt2_sig = 5'd0;
    last_alu_op_sig = 5'd0;
    last_branch_code_sig = 5'd0;
    last_imm_sig = 32'd0;
    last_is_load_sig = 1'b0;
    last_is_store_sig = 1'b0;
    last_is_branch_sig = 1'b0;
    last_is_post_inc_sig = 1'b0;
    last_priv_type_sig = 5'd0;
    last_crmov_mode_sig = 2'd0;
    last_is_atomic_sig = 1'b0;
    last_is_fetch_add_atomic_sig = 1'b0;
    last_atomic_step_sig = 2'd0;
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
  reg replay_dedup_active;
  reg stall_prev;
  reg [4:0]last_opcode_sig;
  reg [31:0]last_slot_id_sig;
  reg [4:0]last_s1_sig;
  reg [4:0]last_s2_sig;
  reg [4:0]last_tgt1_sig;
  reg [4:0]last_tgt2_sig;
  reg [4:0]last_alu_op_sig;
  reg [4:0]last_branch_code_sig;
  reg [31:0]last_imm_sig;
  reg last_is_load_sig;
  reg last_is_store_sig;
  reg last_is_branch_sig;
  reg last_is_post_inc_sig;
  reg [4:0]last_priv_type_sig;
  reg [1:0]last_crmov_mode_sig;
  reg last_is_atomic_sig;
  reg last_is_fetch_add_atomic_sig;
  reg [1:0]last_atomic_step_sig;
  reg [31:0]atomic_base_buf;
  reg [31:0]atomic_data_buf;
  reg [31:0]atomic_fadd_sum_buf;
  reg stall_hist_1;
  reg stall_hist_2;
  wire stall_buf_valid = stall || stall_hist_1 || stall_hist_2;

  wire is_mem_w = (5'd3 <= opcode && opcode <= 5'd5);
  wire is_mem_d = (5'd6 <= opcode && opcode <= 5'd8);
  wire is_mem_b = (5'd9 <= opcode && opcode <= 5'd11);

  // Forwarding priority is newest-to-oldest pipeline producer, then local
  // stall history buffers, then regfile output.
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
    (stall_buf_valid && reg_tgt_buf_a_1 == s_1 && s_1 != 5'b0) ? reg_data_buf_a_1 :
    (stall_buf_valid && reg_tgt_buf_a_2 == s_1 && s_1 != 5'b0) ? reg_data_buf_a_2 :
    (stall_buf_valid && reg_tgt_buf_b_1 == s_1 && s_1 != 5'b0) ? reg_data_buf_b_1 :
    (stall_buf_valid && reg_tgt_buf_b_2 == s_1 && s_1 != 5'b0) ? reg_data_buf_b_2 :
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
    (stall_buf_valid && reg_tgt_buf_a_1 == s_2 && s_2 != 5'b0) ? reg_data_buf_a_1 :
    (stall_buf_valid && reg_tgt_buf_a_2 == s_2 && s_2 != 5'b0) ? reg_data_buf_a_2 :
    (stall_buf_valid && reg_tgt_buf_b_1 == s_2 && s_2 != 5'b0) ? reg_data_buf_b_1 :
    (stall_buf_valid && reg_tgt_buf_b_2 == s_2 && s_2 != 5'b0) ? reg_data_buf_b_2 :
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
  wire is_crmov = (opcode == 5'd31) && (priv_type == 5'd1);
  wire crmov_reads_creg = is_crmov &&
    (crmov_mode_type == 2'd1 || crmov_mode_type == 2'd2);
  wire [4:0]dep_s1 = crmov_reads_creg ? 5'd0 : s_1;
  wire [4:0]dep_s2 = is_crmov ? 5'd0 : s_2;
  wire decode_live = !bubble_in && !exc_in_wb && !rfe_in_wb;

  wire ex_dep_hit =
    (((tgt_out_1 == dep_s1 || tgt_out_1 == dep_s2) && tgt_out_1 != 5'd0) ||
     ((tgt_out_2 == dep_s1 || tgt_out_2 == dep_s2) && tgt_out_2 != 5'd0));
  wire tlb_mem_dep_hit =
    (((tlb_mem_tgt_1 == dep_s1 || tlb_mem_tgt_1 == dep_s2) && tlb_mem_tgt_1 != 5'd0) ||
     ((tlb_mem_tgt_2 == dep_s1 || tlb_mem_tgt_2 == dep_s2) && tlb_mem_tgt_2 != 5'd0));
  wire mem_a_dep_hit =
    (((mem_a_tgt_1 == dep_s1 || mem_a_tgt_1 == dep_s2) && mem_a_tgt_1 != 5'd0) ||
     ((mem_a_tgt_2 == dep_s1 || mem_a_tgt_2 == dep_s2) && mem_a_tgt_2 != 5'd0));
  wire mem_b_dep_hit =
    (((mem_b_tgt_1 == dep_s1 || mem_b_tgt_1 == dep_s2) && mem_b_tgt_1 != 5'd0) ||
     ((mem_b_tgt_2 == dep_s1 || mem_b_tgt_2 == dep_s2) && mem_b_tgt_2 != 5'd0));

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
    mem_a_cr_hit ? mem_a_result_out_1 :
    mem_b_cr_hit ? mem_b_result_out_1 :
    wb_cr_hit ? wb_result_out_1 :
    buf_a_cr_hit ? reg_data_buf_a_1 :
    buf_b_cr_hit ? reg_data_buf_b_1 :
    reg_out_cr;

  wire opening_after_stall = stall_prev && !stall && !bubble_in && !exc_in_wb && !rfe_in_wb;
  // Replay dedup:
  // - enabled only after a stall opens, then cleared once decode advances.
  // - slot id is the primary identity key; payload fields remain as safety
  //   backstop in case an upstream bug mislabels slot ids.
  wire same_replay_slot =
    (slot_id == last_slot_id_sig) &&
    (opcode == last_opcode_sig) &&
    (s_1 == last_s1_sig) &&
    (s_2 == last_s2_sig) &&
    (tgt_1 == last_tgt1_sig) &&
    (tgt_2 == last_tgt2_sig) &&
    (alu_op == last_alu_op_sig) &&
    (branch_code == last_branch_code_sig) &&
    (imm == last_imm_sig) &&
    (is_load == last_is_load_sig) &&
    (is_store == last_is_store_sig) &&
    (is_branch == last_is_branch_sig) &&
    (is_post_inc == last_is_post_inc_sig) &&
    (priv_type == last_priv_type_sig) &&
    (crmov_mode_type == last_crmov_mode_sig) &&
    (is_atomic == last_is_atomic_sig) &&
    (is_fetch_add_atomic == last_is_fetch_add_atomic_sig) &&
    (atomic_step == last_atomic_step_sig);
  wire exec_dup = replay_dedup_active && !opening_after_stall &&
    !bubble_in && !stall && !exc_in_wb && !rfe_in_wb && same_replay_slot;

  // nonsense to make subtract immediate work how i want
  wire [31:0]lhs = (opcode == 5'd1 && alu_op == 5'd16) ? imm : atomic_op1;
  wire [31:0]rhs = ((opcode == 5'd1 && alu_op != 5'd16) || (opcode == 5'd2) || 
                  (5'd3 <= opcode && opcode <= 5'd11) || (opcode == 5'd22)) ? 
                    imm : (opcode == 5'd1 && alu_op == 5'd16) ? atomic_op1 : atomic_op2;

  wire we_bit = is_store && !bubble_in && !exc_in_wb
                && !rfe_in_wb && (exc_out == 8'd0) && !stall && !exec_dup;

  wire [31:0]alu_rslt;
  ALU ALU(clk, clk_en, opcode, alu_op, lhs, rhs, decode_pc_out, bubble_in, 
    flags_restore, rfe_in_wb,
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
      reg_tgt_buf_b_1 <= 5'd0;
      reg_tgt_buf_b_2 <= 5'd0;
      reg_data_buf_b_1 <= 32'd0;
      reg_data_buf_b_2 <= 32'd0;
      tgts_cr_buf_b <= 1'b0;
      atomic_base_buf <= 32'd0;
      atomic_data_buf <= 32'd0;
      atomic_fadd_sum_buf <= 32'd0;
      replay_dedup_active <= 1'b0;
      stall_prev <= 1'b0;
      last_opcode_sig <= 5'd0;
      last_slot_id_sig <= 32'd0;
      last_s1_sig <= 5'd0;
      last_s2_sig <= 5'd0;
      last_tgt1_sig <= 5'd0;
      last_tgt2_sig <= 5'd0;
      last_alu_op_sig <= 5'd0;
      last_branch_code_sig <= 5'd0;
      last_imm_sig <= 32'd0;
      last_is_load_sig <= 1'b0;
      last_is_store_sig <= 1'b0;
      last_is_branch_sig <= 1'b0;
      last_is_post_inc_sig <= 1'b0;
      last_priv_type_sig <= 5'd0;
      last_crmov_mode_sig <= 2'd0;
      last_is_atomic_sig <= 1'b0;
      last_is_fetch_add_atomic_sig <= 1'b0;
      last_atomic_step_sig <= 2'd0;
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
      mem_re <= is_load && !slot_kill && (exc_out == 8'd0);
      store_data <= slot_kill ? 32'd0 : store_data_next;
      we <= slot_kill ? 4'd0 : we_next;

      is_load_out <= slot_kill ? 1'b0 : is_load;
      is_store_out <= slot_kill ? 1'b0 : is_store;
      tgts_cr_out <= slot_kill ? 1'b0 : tgts_cr;
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
      end else if (replay_dedup_active && !stall && !bubble_in && !same_replay_slot) begin
        replay_dedup_active <= 1'b0;
      end

      if (!stall && !bubble_in && !exc_in_wb && !rfe_in_wb && !exec_dup) begin
        last_opcode_sig <= opcode;
        last_slot_id_sig <= slot_id;
        last_s1_sig <= s_1;
        last_s2_sig <= s_2;
        last_tgt1_sig <= tgt_1;
        last_tgt2_sig <= tgt_2;
        last_alu_op_sig <= alu_op;
        last_branch_code_sig <= branch_code;
        last_imm_sig <= imm;
        last_is_load_sig <= is_load;
        last_is_store_sig <= is_store;
        last_is_branch_sig <= is_branch;
        last_is_post_inc_sig <= is_post_inc;
        last_priv_type_sig <= priv_type;
        last_crmov_mode_sig <= crmov_mode_type;
        last_is_atomic_sig <= is_atomic;
        last_is_fetch_add_atomic_sig <= is_fetch_add_atomic;
        last_atomic_step_sig <= atomic_step;
      end

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

  assign branch = !bubble_in && !exc_in_wb && !rfe_in_wb && taken && is_branch;
  
  assign branch_tgt = 
            (opcode == 5'd12) ? decode_pc_out + (imm << 2) + 32'h4 :
            (opcode == 5'd13) ? atomic_op1 :
            (opcode == 5'd14) ? decode_pc_out + atomic_op1 + 32'h4 : 
            decode_pc_out + 32'h4;

endmodule
