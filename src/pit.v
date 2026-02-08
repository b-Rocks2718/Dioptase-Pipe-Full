`timescale 1ps/1ps

// Programmable interval timer.
//
// Contract:
// - Runs from base `clk` (100MHz domain), not the CPU `clk_en` domain.
// - `we` reloads the timer period immediately.
// - `interrupt` is a one-cycle pulse each time the programmed period expires.
module pit(
  input clk,
  input we, input [31:0]wdata,
  output reg interrupt
);

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
    if (we) begin
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
