`timescale 1ps/1ps

module fetch_a(input clk, input stall, input flush,
    input branch, input [31:0]branch_tgt, input interrupt, input [31:0]interrupt_vector,
    output [31:0]fetch_addr, output reg [31:0]pc_out, output reg bubble_out, output reg [7:0]exc_out
  );

  reg [31:0]pc;

  // -4 is a hack to save a cycle on branches
  assign fetch_addr = 
    interrupt ? interrupt_vector :
    branch ? branch_tgt : 
    (stall ? pc - 32'h4 : pc);

  initial begin
    bubble_out = 1;
    pc = 32'h00000400;
  end

  always @(posedge clk) begin
    if (!stall) begin
      pc <= 
        interrupt ?
          interrupt_vector + 4 :
          (branch ? 
            branch_tgt + 4 : 
            pc + 4); // +4 is a hack to save a cycle on branches
      bubble_out <= 0;
      pc_out <= fetch_addr;

      // misaligned pc exception
      exc_out <= (fetch_addr[1:0] == 2'b0) ? 8'h84 : 8'h0;
    end
  end
endmodule

module fetch_b(input clk, input stall, input flush, input bubble_in,
    input [31:0]pc_in, input [7:0]exc_in, input [7:0]exc_tlb,
    output reg bubble_out, output reg [31:0]pc_out, output reg [7:0]exc_out
  );

    // fetch is 2 stages because memory is 2-cycle
    // pipelining allows us to average fetching 1 instruction every cycle

    initial begin
      bubble_out = 1;
    end

    always @(posedge clk) begin 
      if (!stall) begin
        bubble_out <= flush ? 1 : bubble_in;
        pc_out <= pc_in;
        exc_out <= (exc_in != 8'd0) ? exc_in : exc_tlb;
      end
    end
endmodule