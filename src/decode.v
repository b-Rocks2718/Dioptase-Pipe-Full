`timescale 1ps/1ps

module decode(input clk, input clk_en,
    input flush, input halt,

    input [31:0]mem_out_0, input bubble_in, input [31:0]pc_in,

    input we1, input [4:0]target_1, input [31:0]write_data_1,
    input we2, input [4:0]target_2, input [31:0]write_data_2,
    input cr_we,

    input stall,
    input [7:0]exc_in,
    
    input [31:0]epc, input [31:0]efg, input [31:0]tlb_addr,
    input exc_in_wb, input tlb_exc_in_wb,
    input [15:0]interrupts,

    input interrupt_in_wb, input rfe_in_wb, input rfi_in_wb,
    
    output [31:0]cdv, output [11:0]pid, output kmode, 
    output reg [7:0]exc_out,

    output [31:0]d_1, output [31:0]d_2, output [31:0]cr_d, output reg [31:0]pc_out,
    output reg [4:0]opcode_out, output reg [4:0]s_1_out, output reg [4:0]s_2_out, 
    output reg [4:0]cr_s_out,
    output reg [4:0]tgt_out_1, output reg [4:0]tgt_out_2,
    output reg [4:0]alu_op_out, output reg [31:0]imm_out, output reg [4:0]branch_code_out,
    output reg bubble_out, output [31:0]ret_val,
    output reg is_load_out, output reg is_store_out, output reg is_branch_out,
    output reg is_post_inc_out, output reg tgts_cr_out,
    output reg [4:0]priv_type_out, output reg [1:0]crmov_mode_type_out,
    output reg tlb_we, output reg tlbc, output [31:0]interrupt_state,
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
  reg atomic_drain;
  reg [31:0]atomic_drain_instr;
  reg [31:0]atomic_drain_pc;

  wire use_buf = was_stall || was_decode_stall;
  wire [31:0]front_instr;
  wire [31:0]front_pc;
  wire front_bubble;
  wire [7:0]front_exc;
  wire [31:0]instr_in;
  wire [31:0]pc_decode_in;
  wire bubble_decode_in;
  wire [7:0]exc_decode_in;
  reg [31:0]instr_buf;
  reg [31:0]pc_buf;
  reg bubble_buf;
  reg [7:0]exc_buf;
  assign front_instr = use_buf ? instr_buf : mem_out_0;
  assign front_pc = use_buf ? pc_buf : pc_in;
  assign front_bubble = use_buf ? bubble_buf : bubble_in;
  assign front_exc = use_buf ? exc_buf : exc_in;
  assign instr_in = atomic_active ? atomic_instr : front_instr;
  assign pc_decode_in = atomic_active ? atomic_pc : front_pc;
  assign bubble_decode_in = atomic_active ? 1'b0 : front_bubble;
  assign exc_decode_in = atomic_active ? 8'h0 : front_exc;
  // One-cycle PC/instruction catch-up on stall replay. Guard with was_was_stall
  // so this only applies on the first live cycle after replay.
  wire replay_pc_fix = !atomic_active && was_was_stall && !use_buf && !stall &&
    (pc_in == pc_buf) && (mem_out_0 != instr_buf) && !bubble_in;
  reg replay_pc_fix_d1;
  reg replay_pc_fix_d2;
  reg prev_live_valid;
  reg [31:0]prev_live_instr;
  reg [31:0]prev_live_pc;
  wire replay_fix_drop = replay_pc_fix &&
    (mem_out_0[31:27] == 5'd0) &&
    (prev_live_instr[31:27] == 5'd0);
  wire replay_dup_match = !atomic_active && !stall && !use_buf && !bubble_in &&
    (mem_out_0 == prev_live_instr) && (pc_in == prev_live_pc + 32'd4);
  // After the catch-up cycle, instruction memory can still present one extra
  // duplicate word while PC has already advanced. Drop that duplicate as bubble.
  wire replay_dup_drop = replay_dup_match && replay_pc_fix_d2;
  // Generic frontend replay duplicate filter: if the same live {pc,instr}
  // appears on consecutive cycles, execute it once then bubble repeats.
  wire live_consecutive_dup = !atomic_active && !stall && !use_buf && !bubble_in &&
    prev_live_valid && (pc_in == prev_live_pc) && (mem_out_0 == prev_live_instr);

  wire [4:0]opcode = instr_in[31:27];

  // branch instruction has r_a and r_b in a different spot than normal
  wire [4:0]r_a = (opcode == 5'd13 || opcode == 5'd14) ? instr_in[9:5] : instr_in[26:22];
  wire [4:0]r_b = (opcode == 5'd13 || opcode == 5'd14) ? instr_in[4:0] : instr_in[21:17];
  
  // alu_op location is different for alu-reg and alu-imm instructions
  wire [4:0]alu_op = (opcode == 5'd0) ? instr_in[9:5] : instr_in[16:12];
  
  wire is_bitwise = (alu_op <= 5'd6);
  wire is_shift = (5'd7 <= alu_op && alu_op <= 5'd13);
  wire is_arithmetic = (5'd14 <= alu_op && alu_op <= 5'd18);

  wire [4:0]alu_shift = { instr_in[9:8], 3'b0};

  wire [4:0]r_c = instr_in[4:0];

  wire [4:0]branch_code = instr_in[26:22];

  // bit to distinguish loads from stores
  wire load_bit = (opcode == 5'd5 || opcode == 5'd8 || opcode == 5'd11) ? 
                  instr_in[21] : instr_in[16];

  wire is_mem = (5'd3 <= opcode && opcode <= 5'd11);
  wire is_branch = (5'd12 <= opcode && opcode <= 5'd14);
  wire is_alu = (opcode == 5'd0 || opcode == 5'd1);

  wire is_load = is_mem && load_bit;
  wire is_store = is_mem && !load_bit;

  wire is_syscall = (opcode == 5'd15);

  wire is_priv = (opcode == 5'd31);
  wire [4:0]priv_type = instr_in[16:12]; // type of privileged instruction

  wire tgts_cr = is_priv && (priv_type == 5'd1) && ((crmov_mode_type == 2'd0) || (crmov_mode_type == 2'd2));

  wire [7:0]exc_code = instr_in[7:0];

  wire [1:0]crmov_mode_type = instr_in[11:10];

  wire invalid_instr = 
    (5'd23 <= opcode && opcode <= 5'd30) || // bad opcode
    (is_alu && (((alu_op > 5'd18) && (opcode == 5'd1)) || ((alu_op > 5'd22) && (opcode == 5'd0)))) || // bad alu op
    (is_branch && (branch_code > 5'd18)) || // bad branch code
    (is_syscall && (exc_code != 8'd1)) || // bad syscall
    (is_priv && (priv_type > 5'd3)); // bad privileged instruction

  wire invalid_priv = is_priv && !kmode;

  wire [7:0]exc_priv_instr = bubble_decode_in ? 8'h0 : (
    invalid_instr ? 8'h80 :
    invalid_priv ? 8'h81 : 
    is_syscall ? exc_code :
    0);

  // 0 => offset, 1 => preincrement, 2 => postincrement
  wire [1:0]increment_type = instr_in[15:14];

  wire [1:0]mem_shift = instr_in[13:12];

  // Atomic families are cracked in decode:
  // - fetch-add: load -> add -> store
  // - swap: load -> store
  wire [4:0]front_opcode = front_instr[31:27];
  wire front_is_fetch_add = (front_opcode == 5'd16 || front_opcode == 5'd17 || front_opcode == 5'd18);
  wire front_is_swap_abs = (front_opcode == 5'd19);
  wire front_is_swap_rel = (front_opcode == 5'd20);
  wire front_is_swap_imm = (front_opcode == 5'd21);
  wire front_is_swap = front_is_swap_abs || front_is_swap_rel || front_is_swap_imm;
  wire front_kill = flush || front_bubble || replay_fix_drop || replay_dup_drop || live_consecutive_dup;
  wire start_atomic = !atomic_active && !atomic_drain && !stall && !front_kill &&
    (front_is_fetch_add || front_is_swap);
  wire atomic_inflight = atomic_active || start_atomic;
  wire atomic_fetch_add_mode = atomic_active ? atomic_is_fetch_add : front_is_fetch_add;
  wire [1:0]atomic_step_decode = atomic_active ? atomic_step : 2'd0;
  wire atomic_drain_dup = atomic_drain && !stall && !front_bubble &&
    (front_pc == atomic_drain_pc) && (front_instr == atomic_drain_instr);

  wire is_fetch_add = (opcode == 5'd16 || opcode == 5'd17 || opcode == 5'd18);
  wire is_swap_abs = (opcode == 5'd19);
  wire is_swap_rel = (opcode == 5'd20);
  wire is_swap_imm = (opcode == 5'd21);
  wire is_swap = is_swap_abs || is_swap_rel || is_swap_imm;
  wire is_fetch_add_v = (is_fetch_add == 1'b1);
  wire is_swap_v = (is_swap == 1'b1);

  assign decode_stall = atomic_inflight;

  wire [4:0]swap_mem_opcode = is_swap_abs ? 5'd3 : (is_swap_rel ? 5'd4 : 5'd5);
  // assembler/emulator encoding uses [21:17] for swap data register and
  // [16:12] for absolute/relative swap base.
  wire [4:0]swap_base = (is_swap_abs || is_swap_rel) ? instr_in[16:12] : 5'd0;
  wire [4:0]swap_data = instr_in[21:17];
  wire [31:0]swap_imm = is_swap_imm ?
    { {15{instr_in[16]}}, instr_in[16:0] } :
    { {20{instr_in[11]}}, instr_in[11:0] };
  wire swap_load_step = atomic_inflight && !atomic_fetch_add_mode && (atomic_step_decode == 2'd0);
  wire swap_store_step = atomic_inflight && !atomic_fetch_add_mode && (atomic_step_decode == 2'd1);

  wire fetch_add_load_step = atomic_inflight && atomic_fetch_add_mode && (atomic_step_decode == 2'd0);
  wire fetch_add_add_step = atomic_inflight && atomic_fetch_add_mode && (atomic_step_decode == 2'd1);
  wire fetch_add_store_step = atomic_inflight && atomic_fetch_add_mode && (atomic_step_decode == 2'd2);
  wire [4:0]fetch_add_mem_opcode = (opcode == 5'd16) ? 5'd3 :
                                   (opcode == 5'd17) ? 5'd4 : 5'd5;
  wire [4:0]fetch_add_base = (opcode == 5'd18) ? 5'd0 : instr_in[16:12];
  wire [4:0]fetch_add_data = instr_in[21:17];
  wire [31:0]fetch_add_imm = (opcode == 5'd18) ?
    { {15{instr_in[16]}}, instr_in[16:0] } :
    { {20{instr_in[11]}}, instr_in[11:0] };

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
        stall, ret_val);
        
  cregfile cregfile(clk, clk_en,
        r_b, cr_d,
        cr_we, target_1, write_data_1,
        stall, exc_in_wb, tlb_exc_in_wb,
        tlb_addr, epc, efg, interrupts,
        interrupt_in_wb, rfe_in_wb, rfi_in_wb,
        kmode, cdv, interrupt_state, pid
  );

  wire [31:0]base_imm = 
    (opcode == 5'd1 && is_bitwise) ? { 24'b0, instr_in[7:0] } << alu_shift : // zero extend, then shift
    (opcode == 5'd1 && is_shift) ? { 27'b0, instr_in[4:0] } : // zero extend 5 bit
    (opcode == 5'd1 && is_arithmetic) ? { {20{instr_in[11]}}, instr_in[11:0] } : // sign extend 12 bit
    (opcode == 5'd2) ? {instr_in[21:0], 10'b0} : // shift left 
    opcode == 5'd12 ? { {10{instr_in[21]}}, instr_in[21:0] } : // sign extend 22 bit
    is_absolute_mem ? { {20{instr_in[11]}}, instr_in[11:0] } << mem_shift : // sign extend 12 bit with shift
    (opcode == 5'd4 || opcode == 5'd7 || opcode == 5'd10) ? { {16{instr_in[15]}}, instr_in[15:0] } : // sign extend 16 bit 
    (opcode == 5'd5 || opcode == 5'd8 || opcode == 5'd11) ? { {11{instr_in[20]}}, instr_in[20:0] } : // sign extend 21 bit 
    (opcode == 5'd22) ? { {10{instr_in[21]}}, instr_in[21:0] } : // sign extend 22 bit
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
    is_load_out = 1'b0;
    is_store_out = 1'b0;
    is_branch_out = 1'b0;
    is_post_inc_out = 1'b0;
    tgts_cr_out = 1'b0;
    priv_type_out = 5'd0;
    crmov_mode_type_out = 2'd0;
    bubble_out = 1'b1;
    tlb_we = 1'b0;
    tlbc = 1'b0;
    was_stall = 1'b0;
    was_was_stall = 1'b0;
    was_decode_stall = 1'b0;
    atomic_active = 1'b0;
    atomic_is_fetch_add = 1'b0;
    atomic_step = 2'd0;
    atomic_instr = 32'd0;
    atomic_pc = 32'd0;
    atomic_drain = 1'b0;
    atomic_drain_instr = 32'd0;
    atomic_drain_pc = 32'd0;
    instr_buf = 32'd0;
    pc_buf = 32'd0;
    bubble_buf = 1'b1;
    exc_buf = 8'd0;
    replay_pc_fix_d1 = 1'b0;
    replay_pc_fix_d2 = 1'b0;
    prev_live_valid = 1'b0;
    prev_live_instr = 32'd0;
    prev_live_pc = 32'd0;
    is_atomic_out = 1'b0;
    is_fetch_add_atomic_out = 1'b0;
    atomic_step_out = 2'd0;
  end

  wire priv_instr_tgts_ra = 
    is_priv && (
      (priv_type == 5'd0 && crmov_mode_type == 2'd0) || // tblr
      (priv_type == 5'd1) // cr mov
    );

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

  wire decode_kill = flush || bubble_decode_in || replay_fix_drop || replay_dup_drop ||
    live_consecutive_dup || atomic_drain_dup;

  always @(posedge clk) begin
    if (clk_en) begin
      if (~halt) begin
        if (~stall) begin 
          opcode_out <= decode_kill ? 5'd0 : decode_opcode;
          s_1_out <= decode_kill ? 5'd0 : s_1;
          s_2_out <= decode_kill ? 5'd0 : s_2;
          cr_s_out <= decode_kill ? 5'd0 : r_b;

          tgt_out_1 <= (decode_kill || decode_is_store || alias_postinc_load) ? 5'b0 : r_a;
          tgt_out_2 <= (decode_kill || !decode_is_absolute_mem || increment_type == 2'd0) ? 5'b0 : r_b;

          imm_out <= decode_kill ? 32'd0 : imm;
          branch_code_out <= decode_kill ? 5'd0 : branch_code;
          alu_op_out <= decode_kill ? 5'd0 : decode_alu_op;
          bubble_out <= (flush || replay_fix_drop || replay_dup_drop ||
            live_consecutive_dup || atomic_drain_dup) ? 1 : bubble_decode_in;
          pc_out <= pc_decode_in;
      
          is_load_out <= decode_kill ? 1'b0 : decode_is_load;
          is_store_out <= decode_kill ? 1'b0 : decode_is_store;
          is_branch_out <= decode_kill ? 1'b0 : decode_is_branch;
          is_post_inc_out <= decode_kill ? 1'b0 : (decode_is_absolute_mem && increment_type == 2);
          is_atomic_out <= decode_kill ? 1'b0 : decode_is_atomic;
          is_fetch_add_atomic_out <= decode_kill ? 1'b0 : decode_is_fetch_add_atomic;
          atomic_step_out <= decode_kill ? 2'd0 : decode_atomic_step;
          crmov_mode_type_out <= decode_kill ? 2'd0 : crmov_mode_type;
          priv_type_out <= decode_kill ? 5'd0 : priv_type;
          tgts_cr_out <= decode_kill ? 1'b0 : tgts_cr;

          tlb_we <= (!decode_kill) &&
            (opcode == 5'd31 && priv_type == 5'd0 && crmov_mode_type == 2'd1);
          tlbc   <= (!decode_kill) &&
            (opcode == 5'd31 && priv_type == 5'd0 && crmov_mode_type == 2'd2);

          if (flush || bubble_decode_in) begin
            atomic_active <= 1'b0;
            atomic_is_fetch_add <= 1'b0;
            atomic_step <= 2'd0;
            atomic_drain <= 1'b0;
          end else if (start_atomic) begin
            // Latch one atomic instruction and crack it locally in decode.
            // This decouples micro-op sequencing from frontend replay timing.
            atomic_active <= 1'b1;
            atomic_is_fetch_add <= front_is_fetch_add;
            atomic_step <= 2'd1;
            atomic_instr <= front_instr;
            atomic_pc <= front_pc;
          end else if (atomic_active) begin
            if ((atomic_is_fetch_add && atomic_step == 2'd2) ||
                (!atomic_is_fetch_add && atomic_step == 2'd1)) begin
              atomic_active <= 1'b0;
              atomic_is_fetch_add <= 1'b0;
              atomic_step <= 2'd0;
              atomic_drain <= 1'b1;
              atomic_drain_instr <= atomic_instr;
              atomic_drain_pc <= atomic_pc;
            end else begin
              atomic_step <= atomic_step + 2'd1;
            end
          end else if (atomic_drain && !atomic_drain_dup) begin
            atomic_drain <= 1'b0;
          end

        end

        if (~stall) begin
          exc_out <= (replay_fix_drop || replay_dup_drop || live_consecutive_dup) ? 8'h0 :
                    (interrupt_exc != 8'h0) ? interrupt_exc
                    : (exc_decode_in != 0) ? exc_decode_in : exc_priv_instr;
        end

        // Preserve buffered fetch outputs across execute replay and
        // decode-local crack stalls. Keep the previous execute-stall behavior
        // (hold while `was_stall`), and only add decode-stall hold.
        if (!was_stall && !(decode_stall && was_decode_stall)) begin
          instr_buf <= mem_out_0;
          // On the first cycle stall asserts, instruction memory can already
          // point at the next word while fetch PC is still one word behind.
          // In that case, buffer PC+4 so replay keeps the pair aligned.
          pc_buf <= (stall && prev_live_valid &&
            (pc_in == prev_live_pc) && (mem_out_0 != prev_live_instr)) ?
            (pc_in + 32'd4) : pc_in;
          bubble_buf <= bubble_in;
          exc_buf <= exc_in;
        end
        if (stall || decode_stall || use_buf || flush || bubble_in) begin
          prev_live_valid <= 1'b0;
        end else begin
          prev_live_valid <= 1'b1;
          prev_live_instr <= mem_out_0;
          prev_live_pc <= pc_in;
        end
        replay_pc_fix_d1 <= replay_pc_fix;
        replay_pc_fix_d2 <= replay_pc_fix_d1;
        was_stall <= stall;
        was_was_stall <= was_stall;
        was_decode_stall <= decode_stall;

      end else begin
        exc_out <= interrupt_exc;
      end
    end
  end

endmodule
