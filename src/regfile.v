`timescale 1ps/1ps

// Integer register file.
//
// Interface:
// - Two synchronous read ports.
// - Two write ports (port1 is used for post-increment style address updates).
//
// Invariant:
// - Reads of r0 always return zero regardless of stored array contents.
module regfile(input clk, input clk_en,
    input [4:0]raddr0, output reg [31:0]rdata0,
    input [4:0]raddr1, output reg [31:0]rdata1,
  input wen0, input [4:0]waddr0, input [31:0]wdata0, 
  input wen1, input [4:0]waddr1, input [31:0]wdata1,
  input kmode, input read_no_alias, input write0_no_alias, input write1_no_alias,
  input stall, output [31:0]ret_val);

  reg [31:0]regfile[0:5'b11111];
  reg [31:0]ksp;
  integer i;

  initial begin
    for (i = 0; i < 32; i = i + 1)
      regfile[i] = 32'd0;
    ksp = 32'd0;
  end

  // compiler puts return value in r1
  // expose it here to allow for testing
  assign ret_val = regfile[1];

  always @(posedge clk) begin
    if (wen0) begin
        // ISA: in kernel mode, non-crmv accesses to r31 alias KSP (cr8).
        if (waddr0 != 5'd0) begin
          if (kmode && !write0_no_alias && (waddr0 == 5'd31)) begin
            ksp <= wdata0;
          end else begin
            regfile[waddr0] <= wdata0;
          end
        end
`ifdef SIMULATION
        if ($test$plusargs("reg_debug")) begin
          if (kmode && !write0_no_alias && (waddr0 == 5'd31))
            $display("[reg] w0 ksp=%h", wdata0);
          else
            $display("[reg] w0 r%0d=%h", waddr0, wdata0);
        end
`endif
    end
    if (wen1) begin
        // 2nd write port is used for pre/post increment memory operations.
        // If both write ports target the same register in one cycle, keep
        // the address update so post-increment remains architecturally visible.
        if (waddr1 != 5'd0) begin
          if (kmode && !write1_no_alias && (waddr1 == 5'd31)) begin
            ksp <= wdata1;
          end else begin
            regfile[waddr1] <= wdata1;
          end
        end
`ifdef SIMULATION
        if ($test$plusargs("reg_debug")) begin
          if (kmode && !write1_no_alias && (waddr1 == 5'd31))
            $display("[reg] w1 ksp=%h", wdata1);
          else
            $display("[reg] w1 r%0d=%h", waddr1, wdata1);
        end
`endif
    end

    if (!stall) begin
      if (raddr0 == 5'd0) begin
        rdata0 <= 32'b0;
      end else if (kmode && !read_no_alias && (raddr0 == 5'd31)) begin
        rdata0 <= ksp;
      end else begin
        rdata0 <= regfile[raddr0];
      end

      if (raddr1 == 5'd0) begin
        rdata1 <= 32'b0;
      end else if (kmode && !read_no_alias && (raddr1 == 5'd31)) begin
        rdata1 <= ksp;
      end else begin
        rdata1 <= regfile[raddr1];
      end
    end

  end

endmodule

module cregfile(input clk, input clk_en,
    input [4:0]raddr0, output reg [31:0]rdata0,
    input wen0, input [4:0]waddr0, input [31:0]wdata0,
    input stall, input exc_in_wb, input tlb_exc_in_wb, input [31:0]tlb_addr,
    input [31:0]epc, input [31:0]efg, input [3:0]flags_live, input [15:0]interrupts,
    input interrupt_in_wb, input rfe_in_wb, input rfi_in_wb,
    output kmode, output [31:0]interrupt_state,
    output [31:0]pid, output [31:0]epc_out, output [31:0]efg_out
    );

  // Control register layout:
  // 0=psr(level), 1=pid, 2=isr, 3=imr, 4=epc, 5=flg, 6=efg, 7=tlb_fault_addr,
  // 8=ksp (not yet wired through this module), 9=cid (read-only 0)
  reg [31:0]cregfile[0:5'd31];
  integer i;

  initial begin
    for (i = 0; i < 32; i = i + 1)
      cregfile[i] = 32'd0;
    cregfile[0] = 1;
  end

  assign pid = cregfile[1];
  assign epc_out = cregfile[4];
  assign efg_out = cregfile[6];
  assign kmode = (cregfile[0] != 32'd0);

  // Interrupt delivery is gated by IMR enable bit at bit31.
  assign interrupt_state = cregfile[3][31] ?
    (cregfile[2] & cregfile[3]) : 32'd0;

  wire [31:0]flags_word = {28'b0, flags_live};

  wire [31:0]next_isr = cregfile[2] | {16'b0, interrupts};

  always @(posedge clk) begin
    if (wen0 && clk_en) begin
      // cr9 (cid) is read-only. cr2 has dedicated write logic below.
      if (waddr0 != 5'd2 && waddr0 != 5'd9)
        cregfile[waddr0] <= wdata0;
    end

    if (!stall && clk_en) begin
      if (!exc_in_wb && !rfe_in_wb) begin
        // Keep cr0 and cr9 read-only zero. Expose live ALU flags via cr5.
        rdata0 <= (raddr0 == 5'd0) ? 32'b0 :
                  (raddr0 == 5'd5) ? flags_word :
                  (raddr0 == 5'd9) ? 32'b0 :
                  cregfile[raddr0];
      end else if (exc_in_wb) begin
        // Exception entry snapshots EPC/EFG and increments privilege nesting.
        if (tlb_exc_in_wb) begin
          cregfile[7] <= tlb_addr;
        end
        if (interrupt_in_wb) begin
          // disable interrupts
          cregfile[3] <= cregfile[3] & 32'h7FFFFFFF;
        end
        cregfile[4] <= epc;
        cregfile[6] <= efg;

        // increment state
        cregfile[0] <= cregfile[0] + 32'h1;
      end else if (rfe_in_wb) begin
        // Return-from-exception decrements privilege nesting.
        if (rfi_in_wb) begin
          // re-enable interrupts
          cregfile[3] <= cregfile[3] | 32'h80000000;
        end

        // decrement state
        cregfile[0] <= cregfile[0] - 32'h1;
      end
    end

    // interrupt reg
    if (wen0 && clk_en && waddr0 == 5'd2)
        cregfile[2] <= (wdata0 | {16'b0, interrupts});
    else
        cregfile[2] <= next_isr;

  end

endmodule
