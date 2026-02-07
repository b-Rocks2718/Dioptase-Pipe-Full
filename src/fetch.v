`timescale 1ps/1ps

module tlb_fetch(input clk, input clk_en, input stall, input flush,
    input branch, input [31:0]branch_tgt, input interrupt, input [31:0]interrupt_vector,
    input rfe_in_wb, input [31:0]epc,
    output [31:0]fetch_addr, output reg [31:0]pc_out, output reg bubble_out, output reg [7:0]exc_out
  );

  reg [31:0]pc;
  reg was_stall_fetch;

  wire stall_fetch = stall && !interrupt && !rfe_in_wb;
  wire resume_after_stall = !stall_fetch && was_stall_fetch;

  // Full pipeline has one extra stage between fetch address generation and
  // decode consumption, so on a frontend stall we must back up by two words
  // to re-fetch the oldest in-flight instruction.
  //
  // On the first cycle after stall release, emit pc-4 once and hold `pc`.
  // Without this catch-up step, the stream jumps from replayed `pc-8` straight
  // to `pc`, which can skip one instruction word.
  assign fetch_addr = stall_fetch ? pc - 32'h8 :
                      resume_after_stall ? pc - 32'h4 :
                      pc;

  initial begin
    bubble_out = 1;
    pc = 32'h00000400;
    exc_out = 8'd0;
    was_stall_fetch = 1'b0;
  end

  always @(posedge clk) begin
    if (clk_en) begin
      if (!stall_fetch) begin
        pc <=
          interrupt ? interrupt_vector :
          rfe_in_wb ? epc :
          branch ? branch_tgt :
          resume_after_stall ? pc :
          pc + 4;
        bubble_out <= rfe_in_wb || interrupt || branch;
        pc_out <= fetch_addr;

        // misaligned pc exception
        exc_out <= (fetch_addr[1:0] != 2'b0) ? 8'h84 : 8'h0;
      end
      was_stall_fetch <= stall_fetch;
    end
  end
endmodule

module fetch_a(input clk, input clk_en, input stall, input flush, input bubble_in,
    input [31:0]pc_in, input [7:0]exc_in, input [7:0]exc_tlb,
    output reg bubble_out, output reg [31:0]pc_out, output reg [7:0]exc_out
  );

    // fetch is 2 stages because memory is 2-cycle
    // pipelining allows us to average fetching 1 instruction every cycle

    initial begin
      bubble_out = 1;
      exc_out = 8'd0;
    end

    always @(posedge clk) begin 
      if (clk_en) begin
        if (!stall) begin
          bubble_out <= flush ? 1 : bubble_in;
          pc_out <= pc_in;
          exc_out <= (exc_in != 8'd0) ? exc_in : 
                      !bubble_in ? exc_tlb : 8'd0;
        end
      end
    end
endmodule

module fetch_b(input clk, input clk_en, input stall, input flush, input bubble_in,
    input [31:0]pc_in, input [7:0]exc_in,
    output reg bubble_out, output reg [31:0]pc_out, output reg [7:0]exc_out
  );

    // fetch is 2 stages because memory is 2-cycle
    // pipelining allows us to average fetching 1 instruction every cycle

    initial begin
      bubble_out = 1;
      exc_out = 8'd0;
    end

    always @(posedge clk) begin 
      if (clk_en) begin
        if (!stall) begin
          bubble_out <= flush ? 1 : bubble_in;
          pc_out <= pc_in;
          exc_out <= exc_in;
        end
      end
    end
endmodule
