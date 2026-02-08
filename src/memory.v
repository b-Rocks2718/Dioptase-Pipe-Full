`timescale 1ps/1ps

// Pipeline stage between execute and memory_a.
//
// Purpose:
// - Register execute outputs.
// - Merge TLB read value for tlbr.
// - Carry delayed TLB permission faults as live exception slots.
//
// Invariant:
// - If a TLB fault arrives (`tlb_exc_in`), this stage forces bubble=0 so
//   writeback can observe the exception and redirect precisely.
module tlb_memory(
    input clk, input clk_en, input halt,
    input bubble_in,
    input [4:0]opcode_in, input [4:0]tgt_in_1, input [4:0]tgt_in_2, 
    input [31:0]result_in_1, input [31:0]result_in_2,

    input [31:0]addr_in,

    input is_load, input is_store, input is_tlbr,

    input [31:0]exec_pc_out, input [7:0]exc_in,
    input tgts_cr, input [4:0]priv_type, input [1:0]crmov_mode_type,
    input [3:0]flags_in,
    input [31:0]op1, input [31:0]op2, input exc_in_wb, input rfe_in_wb,
    input [26:0]tlb_read, input [7:0]tlb_exc_in, 
    input exec_mem_re, input [31:0] exec_store_data, input [3:0] exec_mem_we,
    
    output reg [4:0]tgt_out_1, output reg [4:0]tgt_out_2,
    output reg [31:0]result_out_1, output reg [31:0]result_out_2,
    output reg [4:0]opcode_out, output reg [31:0]addr_out,
    output reg bubble_out,

    output reg is_load_out, output reg is_store_out,
    output reg [31:0]mem_pc_out, output reg [7:0]exc_out,
    output reg tgts_cr_out, output reg [4:0]priv_type_out, output reg [1:0]crmov_mode_type_out,
    output reg [3:0]flags_out,
    output reg [31:0]op1_out, output reg [31:0]op2_out,
    output reg mem_re_out, output reg [31:0]store_data_out, output reg [3:0]mem_we_out
  );
  // TLB faults are generated one stage after execute's address request.
  // Keep that fault on a live (non-bubble) slot even if execute is currently
  // in a stall/duplicate window, otherwise writeback can miss the exception.
  wire tlb_fault_live = (tlb_exc_in != 8'd0);

  initial begin
    bubble_out = 1;
    tgt_out_1 = 5'd0;
    tgt_out_2 = 5'd0;

    exc_out = 8'd0;
    mem_re_out = 1'b0;
    store_data_out = 32'd0;
    mem_we_out = 4'd0;
    fault_addr_buf = 32'd0;
  end

  // TLB faults are reported one cycle after the requesting memory op.
  // Keep the most recent live execute-stage memory address so a fault slot
  // carries the correct virtual page into cregfile.tlb.
  reg [31:0]fault_addr_buf;

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
        fault_addr_buf <= 32'd0;
      end else begin
        if (!bubble_in && (is_load || is_store)) begin
          fault_addr_buf <= addr_in;
        end

        tgt_out_1 <= bubble_in ? 5'd0 : tgt_in_1;
        tgt_out_2 <= bubble_in ? 5'd0 : tgt_in_2;
        opcode_out <= bubble_in ? 5'd0 : opcode_in;

        // check for tlbr
        result_out_1 <= bubble_in ? 32'd0 :
          (is_tlbr ? {5'b0, tlb_read} : result_in_1);
        
        result_out_2 <= bubble_in ? 32'd0 : result_in_2;
        bubble_out <= (exc_in_wb || rfe_in_wb || halt) ? 1 :
          (tlb_fault_live ? 1'b0 : bubble_in);
        addr_out <= tlb_fault_live ? fault_addr_buf :
          ((bubble_in && !tlb_fault_live) ? 32'd0 : addr_in);

        mem_pc_out <= exec_pc_out;
        exc_out <= tlb_fault_live ? tlb_exc_in :
          (bubble_in ? 8'h0 : exc_in);
        tgts_cr_out <= tgts_cr && !bubble_in && !exc_in_wb && !rfe_in_wb && !halt;
        priv_type_out <= bubble_in ? 5'd0 : priv_type;
        crmov_mode_type_out <= bubble_in ? 2'd0 : crmov_mode_type;
        flags_out <= bubble_in ? 4'd0 : flags_in;

        op1_out <= bubble_in ? 32'd0 : op1;
        op2_out <= bubble_in ? 32'd0 : op2;

        is_load_out <= bubble_in ? 1'b0 : is_load;
        is_store_out <= bubble_in ? 1'b0 : is_store;

        mem_re_out <= bubble_in ? 1'b0 : exec_mem_re;
        store_data_out <= bubble_in ? 32'd0 : exec_store_data;
        mem_we_out <= bubble_in ? 4'd0 : exec_mem_we;
      end
    end
  end

endmodule

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

  // Generic register stage used for memory_a and memory_b.
  // It does not transform payload fields; it only applies halt/redirect bubble
  // rules and carries metadata toward writeback.
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
        tgt_out_1 <= bubble_in ? 5'd0 : tgt_in_1;
        tgt_out_2 <= bubble_in ? 5'd0 : tgt_in_2;
        opcode_out <= bubble_in ? 5'd0 : opcode_in;
        result_out_1 <= bubble_in ? 32'd0 : result_in_1;
        result_out_2 <= bubble_in ? 32'd0 : result_in_2;
        bubble_out <= (exc_in_wb || rfe_in_wb || halt) ? 1 : bubble_in;
        addr_out <= bubble_in ? 32'd0 : addr_in;

        mem_pc_out <= exec_pc_out;
        exc_out <= bubble_in ? 8'h0 : exc_in;
        tgts_cr_out <= tgts_cr && !bubble_in && !exc_in_wb && !rfe_in_wb && !halt;
        priv_type_out <= bubble_in ? 5'd0 : priv_type;
        crmov_mode_type_out <= bubble_in ? 2'd0 : crmov_mode_type;
        flags_out <= bubble_in ? 4'd0 : flags_in;

        op1_out <= bubble_in ? 32'd0 : op1;
        op2_out <= bubble_in ? 32'd0 : op2;

        is_load_out <= bubble_in ? 1'b0 : is_load;
        is_store_out <= bubble_in ? 1'b0 : is_store;
      end
    end
  end

endmodule
