`timescale 1ps/1ps

module regfile(input clk,
    input [4:0]raddr0, output reg [31:0]rdata0,
    input [4:0]raddr1, output reg [31:0]rdata1,
    input wen0, input [4:0]waddr0, input [31:0]wdata0, 
    input wen1, input [4:0]waddr1, input [31:0]wdata1,
    input stall, output [31:0]ret_val);

  reg [31:0]regfile[0:5'b11111];

  // compiler puts return value in r3
  // expose it here to allow for testing
  assign ret_val = regfile[5'd3];

  always @(posedge clk) begin
    if (wen0) begin
        regfile[waddr0] <= wdata0;
    end
    if (wen1 && waddr0 != waddr1) begin // load data takes precedence over address
        // 2nd write port used for pre/post increment memory operations
        regfile[waddr1] <= wdata1;
    end

    if (!stall) begin
      rdata0 <= (raddr0 == 0) ? 32'b0 : regfile[raddr0];
      rdata1 <= (raddr1 == 0) ? 32'b0 : regfile[raddr1];
    end

  end

endmodule

module cregfile(input clk,
    input [4:0]raddr0, output reg [31:0]rdata0,
    input wen0, input [4:0]waddr0, input [31:0]wdata0,
    input stall, input exc_in_wb, input tlb_exc_in_wb, input [31:0]tlb_addr,
    input [31:0]epc, input [31:0]efg, input [15:0]interrupts,
    input interrupt_in_wb, input rfe_in_wb, input rfi_in_wb,
    output kmode, output [31:0]cdv_out, output [31:0]interrupt_state);

  reg [31:0]cregfile[0:5'b111];

  initial begin
    cregfile[0] <= 1;
    cregfile[1] <= 0;
    cregfile[2] <= 0;
    cregfile[3] <= 0;
    cregfile[4] <= 0;
    cregfile[5] <= 0;
    cregfile[6] <= 0;
    cregfile[7] <= 0;
  end

  assign cdv_out = cregfile[6];
  assign kmode = (cregfile[0] != 31'd0);

  assign interrupt_state = cregfile[3][31] ?
    (cregfile[2] & cregfile[3]) : 32'd0;

  always @(posedge clk) begin
    if (wen0) begin
      cregfile[waddr0] <= wdata0;
    end

    if (!stall) begin
      if (!exc_in_wb && !rfe_in_wb) begin
        rdata0 <= (raddr0 == 0) ? 32'b0 : cregfile[raddr0];
      end else if (exc_in_wb) begin
        if (tlb_exc_in_wb) begin
          cregfile[7] <= tlb_addr;
        end
        if (interrupt_in_wb) begin
          // disable interrupts
          cregfile[3] <= cregfile[3] & 32'h7FFFFFFF;
        end
        cregfile[4] <= epc;
        cregfile[5] <= efg;

        // increment state
        cregfile[0] <= cregfile[0] + 32'h1;
      end else if (rfe_in_wb) begin
        if (rfi_in_wb) begin
          // re-enable interrupts
          cregfile[3] <= cregfile[3] | 32'h80000000;
        end

        // decrement state
        cregfile[0] <= cregfile[0] - 32'h1;
      end

      // interrupt reg
      cregfile[2] <= cregfile[2] | {16'b0, interrupts};

    end

  end

endmodule