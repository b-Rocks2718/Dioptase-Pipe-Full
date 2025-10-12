`timescale 1ps/1ps

module pit(input clk, input clk_en,
  input we, input [31:0]wdata,
  output reg interrupt);

  reg [31:0]count;
  reg [31:0]limit;
  reg active;

  initial begin
    count = 32'd0;
    limit = 32'd0;
    interrupt = 1'b0;
    active = 1'b0;
  end

  always @(posedge clk) begin
    if (!clk_en) begin
      interrupt <= 1'b0;
    end else if (we) begin
      limit <= wdata;
      count <= 32'd0;
      active <= 1'b1;
      interrupt <= 1'b0;
    end else if (active) begin
      if (count >= limit) begin
        count <= 32'd0;
        interrupt <= 1'b1;
      end else begin
        count <= count + 32'd1;
        interrupt <= 1'b0;
      end
    end else begin
      interrupt <= 1'b0;
    end
  end

endmodule
