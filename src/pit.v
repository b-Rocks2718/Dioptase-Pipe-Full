module pit(input clk, input clk_en,
  input we, input [31:0]wdata,
  output reg interrupt);

  reg [31:0]count;
  reg [31:0]limit;

  always @(posedge clk) begin
    if (we && clk_en) limit <= wdata;

    if (count >= limit) begin
      count <= 32'd0;
      interrupt <= 1;
    end else begin
      count <= count + 32'd1;
      interrupt <= 0;
    end
  end

endmodule