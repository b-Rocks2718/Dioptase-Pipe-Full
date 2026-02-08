`timescale 1ps/1ps

// Decode stage.
//
// Purpose:
// - Parse ISA fields from fetched instruction words.
// - Read GPR/CR operands and produce control metadata for execute.
// - Crack atomic fetch-add/swap instructions into decode-local micro-ops.
// - Keep PC/instruction/slot alignment stable across stall windows.
//
// Contracts:
// - `decode_stall` means decode owns frontend progress (atomic crack in flight).
// - `slot_id_out` identifies the logical fetched slot; duplicate frontend
//   copies are aliased to the prior live slot id so execute can deduplicate.
// - Exceptions generated here keep bubble cleared (live faulting slot).
module decode(input clk, input clk_en,
    input flush, input halt,

    input [31:0]mem_out_0, input bubble_in, input [31:0]pc_in, input [31:0]slot_id_in,

    input we1, input [4:0]target_1, input [31:0]write_data_1,
    input we2, input [4:0]target_2, input [31:0]write_data_2,
    input wb_no_alias_1, input wb_no_alias_2,
    input cr_we,

    input stall,
    input [7:0]exc_in,
    
    input [31:0]epc, input [31:0]efg, input [3:0]flags_live, input [31:0]tlb_addr,
    input exc_in_wb, input tlb_exc_in_wb,
    input [15:0]interrupts,

    input interrupt_in_wb, input rfe_in_wb, input rfi_in_wb,
    
    output [31:0]pid, output [31:0]epc_curr, output [31:0]efg_curr, output kmode, 
    output reg [7:0]exc_out,

    output [31:0]d_1, output [31:0]d_2, output [31:0]cr_d, output reg [31:0]pc_out, output reg [31:0]slot_id_out,
    output reg [4:0]opcode_out, output reg [4:0]s_1_out, output reg [4:0]s_2_out, 
    output reg [4:0]cr_s_out,
    output reg [4:0]tgt_out_1, output reg [4:0]tgt_out_2,
    output reg [4:0]alu_op_out, output reg [31:0]imm_out, output reg [4:0]branch_code_out,
    output reg bubble_out, output [31:0]ret_val,
    output reg is_load_out, output reg is_store_out, output reg is_branch_out,
    output reg is_post_inc_out, output reg tgts_cr_out,
    output reg [4:0]priv_type_out, output reg [1:0]crmov_mode_type_out,
    output reg tlb_we, output reg tlbi, output reg tlbc, output [31:0]interrupt_state,
    output reg is_atomic_out, output reg is_fetch_add_atomic_out,
    output reg [1:0]atomic_step_out, output decode_stall
  );

  reg was_stall;
  reg was_was_stall;
  reg was_decode_stall;

  reg atomic_active;
  reg atomic_is_fetch_add;
  reg [1:0]atomic_step;
  reg [31:0]atomic_instr;
  reg [31:0]atomic_pc;
  reg [31:0]atomic_slot_id;
  reg atomic_drain;
  reg [31:0]atomic_drain_instr;
  reg [31:0]atomic_drain_pc;
  reg [31:0]atomic_drain_slot_id;

  // Frontend queue provides stable packet ordering across stalls, so decode no
  // longer needs local buffering for execute/decode stalls.
  wire use_buf = 1'b0;
  wire [31:0]front_instr;
  wire [31:0]front_pc;
  wire [31:0]front_slot_id;
  wire front_bubble;
  wire [7:0]front_exc;
  wire [31:0]instr_in;
  wire [31:0]pc_decode_in;
  wire [31:0]slot_id_decode_in;
  wire bubble_decode_in;
  wire [7:0]exc_decode_in;
  reg [31:0]instr_buf;
  reg [31:0]pc_buf;
  reg [31:0]slot_id_buf;
  reg bubble_buf;
  reg [7:0]exc_buf;
  assign front_instr = use_buf ? instr_buf : mem_out_0;
  assign front_pc = use_buf ? pc_buf : pc_in;
  assign front_slot_id = use_buf ? slot_id_buf : slot_id_in;
  assign front_bubble = use_buf ? bubble_buf : bubble_in;
  assign front_exc = use_buf ? exc_buf : exc_in;
  assign instr_in = atomic_active ? atomic_instr : front_instr;
  assign pc_decode_in = atomic_active ? atomic_pc : front_pc;
  assign slot_id_decode_in = atomic_active ? atomic_slot_id : front_slot_id_aligned;
  assign bubble_decode_in = atomic_active ? 1'b0 : front_bubble;
  assign exc_decode_in = atomic_active ? 8'h0 : front_exc;
  // Duplicate phases around stall release:
  // 1) realign cycle: frontend metadata and memory output can be one word apart.
  // 2) follow-up cycle: memory can present one extra duplicate after realign.
  // 3) steady duplicate: repeated {pc,instr} pairs on adjacent cycles.
  wire replay_realign_cycle = !atomic_active && was_was_stall && !use_buf && !stall &&
    (pc_in == pc_buf) && (mem_out_0 != instr_buf) && !bubble_in;
  reg replay_realign_d1;
  reg replay_realign_d2;
  reg prev_live_valid;
  reg [31:0]prev_live_instr;
  reg [31:0]prev_live_pc;
  reg [31:0]prev_live_slot_id;
  // On stall catch-up, stale ALU words can briefly reappear for the same PC.
  // Drop that single stale decode so dependent instructions observe the
  // architecturally correct stream.
  wire replay_realign_drop = replay_realign_cycle &&
    ((opcode == 5'd1) || (opcode == 5'd0));
  wire replay_followup_match = !atomic_active && !stall && !use_buf && !bubble_in &&
    (mem_out_0 == prev_live_instr) && (pc_in == prev_live_pc + 32'd4);
  // After the catch-up cycle, instruction memory can still present one extra
  // duplicate word while PC has already advanced. Drop that duplicate as bubble.
  wire replay_followup_drop = replay_followup_match && replay_realign_d2;
  // Generic frontend duplicate filter: if the same live {pc,instr}
  // appears on consecutive cycles, execute it once then bubble repeats.
  wire replay_consecutive_drop = !atomic_active && !stall && !use_buf && !bubble_in &&
    prev_live_valid && (pc_in == prev_live_pc) && (mem_out_0 == prev_live_instr);
  wire replay_slot_alias_window = use_buf || was_stall || replay_realign_cycle ||
    replay_realign_d1 || replay_realign_d2 || replay_followup_match;
  // Keep stale duplicate copies attached to the prior live slot id so execute can
  // deduplicate by slot identity instead of full payload matching.
  wire replay_slot_alias = !atomic_active && !stall && !bubble_decode_in &&
    replay_slot_alias_window &&
    prev_live_valid && (instr_in == prev_live_instr) &&
    ((pc_decode_in == prev_live_pc) || (pc_decode_in == (prev_live_pc + 32'd4)));
  wire [31:0]front_slot_id_aligned = replay_slot_alias ? prev_live_slot_id : front_slot_id;
  wire replay_front_drop = replay_realign_drop || replay_followup_drop || replay_consecutive_drop;

  wire [4:0]opcode_raw = instr_in[31:27];
  wire [4:0]front_opcode = front_instr[31:27];

  reg opcode_is_valid;
  reg opcode_is_defined_invalid;
  reg is_mem;
  reg is_branch;
  reg is_alu;
  reg is_syscall;
  reg is_priv;
  reg front_is_fetch_add;
  reg front_is_swap;

  always @(*) begin
    opcode_is_valid = 1'b0;
    opcode_is_defined_invalid = 1'b0;
    is_mem = 1'b0;
    is_branch = 1'b0;
    is_alu = 1'b0;
    is_syscall = 1'b0;
    is_priv = 1'b0;

    case (opcode_raw)
      5'd0, 5'd1: begin
        opcode_is_valid = 1'b1;
        is_alu = 1'b1;
      end
      5'd2: opcode_is_valid = 1'b1;
      5'd3, 5'd4, 5'd5, 5'd6, 5'd7, 5'd8, 5'd9, 5'd10, 5'd11: begin
        opcode_is_valid = 1'b1;
        is_mem = 1'b1;
      end
      5'd12, 5'd13, 5'd14: begin
        opcode_is_valid = 1'b1;
        is_branch = 1'b1;
      end
      5'd15: begin
        opcode_is_valid = 1'b1;
        is_syscall = 1'b1;
      end
      5'd16, 5'd17, 5'd18, 5'd19, 5'd20, 5'd21, 5'd22: opcode_is_valid = 1'b1;
      5'd23, 5'd24, 5'd25, 5'd26, 5'd27, 5'd28, 5'd29, 5'd30: opcode_is_defined_invalid = 1'b1;
      5'd31: begin
        opcode_is_valid = 1'b1;
        is_priv = 1'b1;
      end
    endcase

    front_is_fetch_add = 1'b0;
    front_is_swap = 1'b0;
    case (front_opcode)
      5'd16, 5'd17, 5'd18: front_is_fetch_add = 1'b1;
      5'd19, 5'd20, 5'd21: front_is_swap = 1'b1;
      default: begin
      end
    endcase
  end
  wire opcode_known = opcode_is_valid || opcode_is_defined_invalid;
  // Decode-time sanitization: when frontend presents an unknown instruction
  // word (simulation artifact), decode it as NOP-shaped data so control logic
  // stays deterministic without requiring x-specific squashing rules.
  wire [31:0]instr_dec = opcode_known ? instr_in : 32'd0;
  wire [4:0]opcode = instr_dec[31:27];

  // branch instruction has r_a and r_b in a different spot than normal
  wire [4:0]r_a = (opcode == 5'd13 || opcode == 5'd14) ? instr_dec[9:5] : instr_dec[26:22];
  wire [4:0]r_b = (opcode == 5'd13 || opcode == 5'd14) ? instr_dec[4:0] : instr_dec[21:17];
  
  // alu_op location is different for alu-reg and alu-imm instructions
  wire [4:0]alu_op = (opcode == 5'd0) ? instr_dec[9:5] : instr_dec[16:12];
  
  wire is_bitwise = (alu_op <= 5'd6);
  wire is_shift = (5'd7 <= alu_op && alu_op <= 5'd13);
  wire is_arithmetic = (5'd14 <= alu_op && alu_op <= 5'd18);

  wire [4:0]alu_shift = { instr_dec[9:8], 3'b0};

  wire [4:0]r_c = instr_dec[4:0];

  wire [4:0]branch_code = instr_dec[26:22];

  // bit to distinguish loads from stores
  wire load_bit = (opcode == 5'd5 || opcode == 5'd8 || opcode == 5'd11) ?
                  instr_dec[21] : instr_dec[16];

  wire is_load = is_mem && load_bit;
  wire is_store = is_mem && !load_bit;
  wire [4:0]priv_type = instr_dec[16:12]; // type of privileged instruction
  // ISA: crmv must always access architectural r31 (never ksp alias).
  wire reg_read_no_alias = is_priv && (priv_type == 5'd1);

  wire tgts_cr = is_priv && (priv_type == 5'd1) && ((crmov_mode_type == 2'd0) || (crmov_mode_type == 2'd2));

  wire [7:0]exc_code = instr_dec[7:0];

  wire [1:0]crmov_mode_type = instr_dec[11:10];
  // IPI encodings currently retire as no-ops in this core.
  wire is_ipi_n = is_priv && (priv_type == 5'd4) && (crmov_mode_type == 2'd0);
  wire is_ipi_all = is_priv && (priv_type == 5'd4) && (crmov_mode_type == 2'd1);
  wire is_ipi = is_ipi_n || is_ipi_all;
  wire syscall_exc_ok = (exc_code == 8'd1) && !bubble_decode_in;

  wire invalid_instr =
    opcode_is_defined_invalid || // architecturally invalid opcode values
    (is_alu && (((alu_op > 5'd18) && (opcode == 5'd1)) || ((alu_op > 5'd22) && (opcode == 5'd0)))) || // bad alu op
    (is_branch && (branch_code > 5'd18)) || // bad branch code
    (is_syscall && !syscall_exc_ok) || // bad syscall
    // bad privileged instruction
    (is_priv && ((priv_type > 5'd4) || ((priv_type == 5'd4) && !is_ipi)));

  wire invalid_priv = is_priv && !kmode;

  wire [7:0]exc_priv_instr = bubble_decode_in ? 8'h0 : (
    invalid_instr ? 8'h80 :
    invalid_priv ? 8'h81 : 
    is_syscall ? exc_code :
    0);

  // 0 => offset, 1 => preincrement, 2 => postincrement
  wire [1:0]increment_type = instr_dec[15:14];

  wire [1:0]mem_shift = instr_dec[13:12];

  // Atomic families are cracked in decode:
  // - fetch-add: load -> add -> store
  // - swap: load -> store
  // A frontend slot is not eligible to start a crack sequence if it is already
  // being discarded by redirect/duplicate filters.
  wire front_kill = flush || front_bubble || replay_front_drop;
  wire start_atomic = !atomic_active && !atomic_drain && !stall && !front_kill &&
    (front_is_fetch_add || front_is_swap);
  wire atomic_inflight = atomic_active || start_atomic;
  wire atomic_fetch_add_mode = atomic_active ? atomic_is_fetch_add : front_is_fetch_add;
  wire [1:0]atomic_step_decode = atomic_active ? atomic_step : 2'd0;
  wire atomic_drain_dup = atomic_drain && !stall && !front_bubble &&
    (front_slot_id == atomic_drain_slot_id) &&
    (front_pc == atomic_drain_pc) && (front_instr == atomic_drain_instr);

  wire is_swap_abs = (opcode == 5'd19);
  wire is_swap_rel = (opcode == 5'd20);
  wire is_swap_imm = (opcode == 5'd21);

  assign decode_stall = atomic_inflight;

  wire [4:0]swap_mem_opcode = is_swap_abs ? 5'd3 : (is_swap_rel ? 5'd4 : 5'd5);
  // assembler/emulator encoding uses [21:17] for swap data register and
  // [16:12] for absolute/relative swap base.
  wire [4:0]swap_base = (is_swap_abs || is_swap_rel) ? instr_dec[16:12] : 5'd0;
  wire [4:0]swap_data = instr_dec[21:17];
  wire [31:0]swap_imm = is_swap_imm ?
    { {15{instr_dec[16]}}, instr_dec[16:0] } :
    { {20{instr_dec[11]}}, instr_dec[11:0] };
  wire swap_load_step = atomic_inflight && !atomic_fetch_add_mode && (atomic_step_decode == 2'd0);
  wire swap_store_step = atomic_inflight && !atomic_fetch_add_mode && (atomic_step_decode == 2'd1);

  wire fetch_add_load_step = atomic_inflight && atomic_fetch_add_mode && (atomic_step_decode == 2'd0);
  wire fetch_add_add_step = atomic_inflight && atomic_fetch_add_mode && (atomic_step_decode == 2'd1);
  wire fetch_add_store_step = atomic_inflight && atomic_fetch_add_mode && (atomic_step_decode == 2'd2);
  wire [4:0]fetch_add_mem_opcode = (opcode == 5'd16) ? 5'd3 :
                                   (opcode == 5'd17) ? 5'd4 : 5'd5;
  wire [4:0]fetch_add_base = (opcode == 5'd18) ? 5'd0 : instr_dec[16:12];
  wire [4:0]fetch_add_data = instr_dec[21:17];
  wire [31:0]fetch_add_imm = (opcode == 5'd18) ?
    { {15{instr_dec[16]}}, instr_dec[16:0] } :
    { {20{instr_dec[11]}}, instr_dec[11:0] };

  wire [4:0]decode_opcode =
    atomic_inflight ? (atomic_fetch_add_mode ?
      (fetch_add_add_step ? 5'd0 : fetch_add_mem_opcode) : swap_mem_opcode) :
      opcode;
  wire [4:0]decode_alu_op =
    (atomic_inflight && atomic_fetch_add_mode && fetch_add_add_step) ? 5'd14 : alu_op;

  // possibility of making two writes to regfile (pre/postincremnt)
  wire is_absolute_mem = opcode == 5'd3 || opcode == 5'd6 || opcode == 5'd9;
  wire alias_postinc_load = is_absolute_mem && (increment_type == 2'd2) &&
    is_load && (r_a == r_b);

  // some instructions don't read from r_b
  wire [4:0]base_s_1 = (opcode == 5'd2 || opcode == 5'd5 || opcode == 5'd8
                     || opcode == 5'd11 || opcode == 5'd12 || opcode == 5'd15 ||
                     ((opcode == 5'd0 || opcode == 5'd1) && alu_op == 5'd6)) ? 5'd0 : r_b;
  
  // store instructions read from r_a instead of writing there
  // only alu-reg instructions use r_c as a source
  wire [4:0]base_s_2 = (is_store || is_priv) ? r_a : ((opcode == 5'd0) ? r_c : 5'd0);
  wire [4:0]s_1 =
    atomic_inflight ? (atomic_fetch_add_mode ?
      (fetch_add_add_step ? fetch_add_data : fetch_add_base) : swap_base) :
      base_s_1;
  wire [4:0]s_2 =
    atomic_inflight ? (atomic_fetch_add_mode ?
      (fetch_add_load_step ? fetch_add_data :
       (fetch_add_add_step ? r_a : (fetch_add_store_step ? r_a : 5'd0))) : swap_data) :
      base_s_2;

  regfile regfile(clk, clk_en,
        s_1, d_1,
        s_2, d_2,
        we1, target_1, write_data_1,
        we2, target_2, write_data_2,
        kmode, reg_read_no_alias, wb_no_alias_1, wb_no_alias_2,
        stall, ret_val);
        
  cregfile cregfile(clk, clk_en,
        r_b, cr_d,
        cr_we, target_1, write_data_1,
        stall, exc_in_wb, tlb_exc_in_wb,
        tlb_addr, epc, efg, flags_live, interrupts,
        interrupt_in_wb, rfe_in_wb, rfi_in_wb,
        kmode, interrupt_state, pid, epc_curr, efg_curr
  );

  wire [31:0]base_imm = 
    (opcode == 5'd1 && is_bitwise) ? { 24'b0, instr_dec[7:0] } << alu_shift : // zero extend, then shift
    (opcode == 5'd1 && is_shift) ? { 27'b0, instr_dec[4:0] } : // zero extend 5 bit
    (opcode == 5'd1 && is_arithmetic) ? { {20{instr_dec[11]}}, instr_dec[11:0] } : // sign extend 12 bit
    (opcode == 5'd2) ? {instr_dec[21:0], 10'b0} : // shift left 
    opcode == 5'd12 ? { {10{instr_dec[21]}}, instr_dec[21:0] } : // sign extend 22 bit
    is_absolute_mem ? { {20{instr_dec[11]}}, instr_dec[11:0] } << mem_shift : // sign extend 12 bit with shift
    (opcode == 5'd4 || opcode == 5'd7 || opcode == 5'd10) ? { {16{instr_dec[15]}}, instr_dec[15:0] } : // sign extend 16 bit 
    (opcode == 5'd5 || opcode == 5'd8 || opcode == 5'd11) ? { {11{instr_dec[20]}}, instr_dec[20:0] } : // sign extend 21 bit 
    (opcode == 5'd22) ? { {10{instr_dec[21]}}, instr_dec[21:0] } : // sign extend 22 bit
    32'd0;

  wire [31:0]imm =
    atomic_inflight ? (atomic_fetch_add_mode ?
      (fetch_add_add_step ? 32'd0 : fetch_add_imm) : swap_imm) :
      base_imm;

  wire decode_is_load =
    atomic_inflight ? (atomic_fetch_add_mode ? fetch_add_load_step : swap_load_step) : is_load;
  wire decode_is_store =
    atomic_inflight ? (atomic_fetch_add_mode ? fetch_add_store_step : swap_store_step) : is_store;
  wire decode_is_branch = atomic_inflight ? 1'b0 : is_branch;
  wire decode_is_atomic = atomic_inflight;
  wire decode_is_fetch_add_atomic = atomic_inflight && atomic_fetch_add_mode;
  wire [1:0]decode_atomic_step = atomic_inflight ? atomic_step_decode : 2'd0;
  wire decode_is_absolute_mem =
    !atomic_inflight &&
    (decode_opcode == 5'd3 || decode_opcode == 5'd6 || decode_opcode == 5'd9);

  initial begin
    bubble_out = 1;
    tgt_out_1 = 5'b00000;
    tgt_out_2 = 5'b00000;
    exc_out = 8'd0;
    opcode_out = 5'd0;
    s_1_out = 5'd0;
    s_2_out = 5'd0;
    cr_s_out = 5'd0;
    imm_out = 32'd0;
    branch_code_out = 5'd0;
    alu_op_out = 5'd0;
    pc_out = 32'd0;
    slot_id_out = 32'd0;
    is_load_out = 1'b0;
    is_store_out = 1'b0;
    is_branch_out = 1'b0;
    is_post_inc_out = 1'b0;
    tgts_cr_out = 1'b0;
    priv_type_out = 5'd0;
    crmov_mode_type_out = 2'd0;
    bubble_out = 1'b1;
    tlb_we = 1'b0;
    tlbi = 1'b0;
    tlbc = 1'b0;
    was_stall = 1'b0;
    was_was_stall = 1'b0;
    was_decode_stall = 1'b0;
    atomic_active = 1'b0;
    atomic_is_fetch_add = 1'b0;
    atomic_step = 2'd0;
    atomic_instr = 32'd0;
    atomic_pc = 32'd0;
    atomic_slot_id = 32'd0;
    atomic_drain = 1'b0;
    atomic_drain_instr = 32'd0;
    atomic_drain_pc = 32'd0;
    atomic_drain_slot_id = 32'd0;
    instr_buf = 32'd0;
    pc_buf = 32'd0;
    slot_id_buf = 32'd0;
    bubble_buf = 1'b1;
    exc_buf = 8'd0;
    replay_realign_d1 = 1'b0;
    replay_realign_d2 = 1'b0;
    prev_live_valid = 1'b0;
    prev_live_instr = 32'd0;
    prev_live_pc = 32'd0;
    prev_live_slot_id = 32'd0;
    is_atomic_out = 1'b0;
    is_fetch_add_atomic_out = 1'b0;
    atomic_step_out = 2'd0;
  end

  wire [7:0]interrupt_exc = (interrupt_state != 0) ? (
            interrupt_state[15] ? 8'hFF :
            interrupt_state[14] ? 8'hFE :
            interrupt_state[13] ? 8'hFD :
            interrupt_state[12] ? 8'hFC :
            interrupt_state[11] ? 8'hFB :
            interrupt_state[10] ? 8'hFA :
            interrupt_state[9] ? 8'hF9 :
            interrupt_state[8] ? 8'hF8 :
            interrupt_state[7] ? 8'hF7 :
            interrupt_state[6] ? 8'hF6 :
            interrupt_state[5] ? 8'hF5 :
            interrupt_state[4] ? 8'hF4 :
            interrupt_state[3] ? 8'hF3 :
            interrupt_state[2] ? 8'hF2 :
            interrupt_state[1] ? 8'hF1 :
            interrupt_state[0] ? 8'hF0 :
            8'h0
            ) : 8'h0;

  // Exception priority at decode boundary:
  // 1) duplicate-drop clears exceptions (slot is invalid anyway)
  // 2) interrupt/tlb/priv exceptions keep slot live (bubble=0) for WB trap flow
  wire decode_has_exc = (interrupt_exc != 8'h0) || (exc_decode_in != 8'h0) || (exc_priv_instr != 8'h0);
  wire replay_drop = replay_front_drop || atomic_drain_dup;
  // IPI is intentionally squashed as a no-op in kernel mode for now.
  wire ipi_noop_kill = is_ipi && kmode;
  wire decode_kill = flush || bubble_decode_in || replay_drop || ipi_noop_kill;
  wire decode_slot_kill = decode_kill || decode_has_exc;

  always @(posedge clk) begin
    if (clk_en) begin
      if (~halt) begin
        if (~stall) begin 
          opcode_out <= decode_slot_kill ? 5'd0 : decode_opcode;
          s_1_out <= decode_slot_kill ? 5'd0 : s_1;
          s_2_out <= decode_slot_kill ? 5'd0 : s_2;
          cr_s_out <= decode_slot_kill ? 5'd0 : r_b;

          tgt_out_1 <= (decode_slot_kill || decode_is_store || alias_postinc_load) ? 5'b0 : r_a;
          tgt_out_2 <= (decode_slot_kill || !decode_is_absolute_mem || increment_type == 2'd0) ? 5'b0 : r_b;

          imm_out <= decode_slot_kill ? 32'd0 : imm;
          branch_code_out <= decode_slot_kill ? 5'd0 : branch_code;
          alu_op_out <= decode_slot_kill ? 5'd0 : decode_alu_op;
          // Faulting slots must remain live so writeback can observe exception
          // metadata and drive redirect/trap behavior.
          bubble_out <= decode_has_exc ? 1'b0 :
            (decode_kill ? 1'b1 : bubble_decode_in);
          pc_out <= pc_decode_in;
          slot_id_out <= slot_id_decode_in;
      
          is_load_out <= decode_slot_kill ? 1'b0 : decode_is_load;
          is_store_out <= decode_slot_kill ? 1'b0 : decode_is_store;
          is_branch_out <= decode_slot_kill ? 1'b0 : decode_is_branch;
          is_post_inc_out <= decode_slot_kill ? 1'b0 : (decode_is_absolute_mem && increment_type == 2);
          is_atomic_out <= decode_slot_kill ? 1'b0 : decode_is_atomic;
          is_fetch_add_atomic_out <= decode_slot_kill ? 1'b0 : decode_is_fetch_add_atomic;
          atomic_step_out <= decode_slot_kill ? 2'd0 : decode_atomic_step;
          crmov_mode_type_out <= decode_slot_kill ? 2'd0 : crmov_mode_type;
          priv_type_out <= decode_slot_kill ? 5'd0 : priv_type;
          tgts_cr_out <= decode_slot_kill ? 1'b0 : tgts_cr;

          tlb_we <= (!decode_slot_kill) &&
            (opcode == 5'd31 && priv_type == 5'd0 && crmov_mode_type == 2'd1);
          tlbi   <= (!decode_slot_kill) &&
            (opcode == 5'd31 && priv_type == 5'd0 && crmov_mode_type == 2'd2);
          tlbc   <= (!decode_slot_kill) &&
            (opcode == 5'd31 && priv_type == 5'd0 && crmov_mode_type == 2'd3);

          if (flush || bubble_decode_in) begin
            // Redirects and incoming bubbles cancel any in-flight crack sequence.
            atomic_active <= 1'b0;
            atomic_is_fetch_add <= 1'b0;
            atomic_step <= 2'd0;
            atomic_drain <= 1'b0;
          end else if (start_atomic) begin
            // Latch one atomic instruction and crack it locally in decode.
            // This decouples micro-op sequencing from frontend queue timing.
            atomic_active <= 1'b1;
            atomic_is_fetch_add <= front_is_fetch_add;
            atomic_step <= 2'd1;
            atomic_instr <= front_instr;
            atomic_pc <= front_pc;
            atomic_slot_id <= front_slot_id_aligned;
          end else if (atomic_active) begin
            if ((atomic_is_fetch_add && atomic_step == 2'd2) ||
                (!atomic_is_fetch_add && atomic_step == 2'd1)) begin
              atomic_active <= 1'b0;
              atomic_is_fetch_add <= 1'b0;
              atomic_step <= 2'd0;
              atomic_drain <= 1'b1;
              atomic_drain_instr <= atomic_instr;
              atomic_drain_pc <= atomic_pc;
              atomic_drain_slot_id <= atomic_slot_id;
            end else begin
              atomic_step <= atomic_step + 2'd1;
            end
          end else if (atomic_drain && !atomic_drain_dup) begin
            atomic_drain <= 1'b0;
          end

        end

        if (~stall) begin
          exc_out <= replay_drop ? 8'h0 :
                    (interrupt_exc != 8'h0) ? interrupt_exc
                    : (exc_decode_in != 0) ? exc_decode_in : exc_priv_instr;
        end

        // Preserve buffered fetch outputs across execute-side duplicate windows
        // and decode-local crack stalls. Keep execute-stall hold behavior
        // (hold while `was_stall`), and only add decode-stall hold.
        if (!was_stall && !(decode_stall && was_decode_stall)) begin
          instr_buf <= mem_out_0;
          // On stall entry, memory can already be one word ahead while PC
          // metadata still points at the prior word. Bias buffered PC forward
          // by one instruction in that specific case so packet pairs stay aligned.
          pc_buf <= (stall && prev_live_valid &&
            (pc_in == prev_live_pc) && (mem_out_0 != prev_live_instr)) ?
            (pc_in + 32'd4) : pc_in;
          slot_id_buf <= slot_id_in;
          bubble_buf <= bubble_in;
          exc_buf <= exc_in;
        end
        if (flush || bubble_decode_in) begin
          prev_live_valid <= 1'b0;
        end else if (!stall && !decode_stall && !decode_slot_kill) begin
          prev_live_valid <= 1'b1;
          prev_live_instr <= instr_in;
          prev_live_pc <= pc_decode_in;
          prev_live_slot_id <= slot_id_decode_in;
        end
        replay_realign_d1 <= replay_realign_cycle;
        replay_realign_d2 <= replay_realign_d1;
        was_stall <= stall;
        was_was_stall <= was_stall;
        was_decode_stall <= decode_stall;
`ifdef SIMULATION
        if ($test$plusargs("decode_debug")) begin
          $display("[decode] pc_in=%h pc_dec=%h sid_in=%0d sid_dec=%0d use_buf=%b stall=%b dstall=%b b_in=%b b_dec=%b op=%0d repfix=%b repdup=%b ldup=%b asid=%b kill=%b",
            pc_in, pc_decode_in, slot_id_in, slot_id_decode_in, use_buf, stall, decode_stall,
            bubble_in, bubble_decode_in, opcode, replay_realign_drop, replay_followup_drop,
            replay_consecutive_drop, replay_slot_alias, decode_slot_kill);
        end
`endif

      end else begin
        exc_out <= interrupt_exc;
      end
    end
  end

endmodule
