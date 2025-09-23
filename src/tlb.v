module tlb(input clk,
  input kmode, input [11:0]pid,
  input [31:0]addr0, input [31:0]addr1, input [31:0]read_addr,
  input we, input [31:0]write_data, input [7:0]exc_in,

  output [7:0]exc_out0, output [7:0]exc_out1,
  output [17:0]addr0_out, output [17:0]addr1_out, output [5:0]read_addr_out
);
  // pid (12 bits) | addr (20 bits)

  // 32 bits (key) + 6 (value) = 38 bits

  reg [37:0]cache[0:3'h7];
  reg [2:0]eviction_tgt;

  wire [31:0]key0 = {pid, addr0[31:12]};
  wire [31:0]key1 = {pid, addr1[31:12]};

  wire [3:0]addr0_index = 
    (key0 == cache[0][37:6]) ? 4'h0 :
    (key0 == cache[1][37:6]) ? 4'h1 :
    (key0 == cache[2][37:6]) ? 4'h2 :
    (key0 == cache[3][37:6]) ? 4'h3 :
    (key0 == cache[4][37:6]) ? 4'h4 :
    (key0 == cache[5][37:6]) ? 4'h5 :
    (key0 == cache[6][37:6]) ? 4'h6 :
    (key0 == cache[7][37:6]) ? 4'h7 :
    4'hf;

  assign exc_out0 = (addr0_index == 4'hf) ? 
    // tlb miss exception
    ( kmode ? 8'h83 : // kmiss
              8'h82   // umiss
    ) : 8'd0;

  assign exc_out1 = 
  (exc_in != 8'd0) ? exc_in : (
  (addr1_index == 4'hf) ? 
    // tlb miss exception
    ( kmode ? 8'h83 : // kmiss
              8'h82   // umiss
    ) : 8'd0);

  assign addr0_out = 
    {((addr0_index == 4'd0) ? cache[0][5:0] :
    (addr0_index == 4'd1) ? cache[1][5:0] :
    (addr0_index == 4'd2) ? cache[2][5:0] :
    (addr0_index == 4'd3) ? cache[3][5:0] :
    (addr0_index == 4'd4) ? cache[4][5:0] :
    (addr0_index == 4'd5) ? cache[5][5:0] :
    (addr0_index == 4'd6) ? cache[6][5:0] :
    (addr0_index == 4'd7) ? cache[7][5:0] :
    6'd0), addr0[11:0]};

  wire [3:0]addr1_index = 
    (key1 == cache[0][37:6]) ? 4'h0 :
    (key1 == cache[1][37:6]) ? 4'h1 :
    (key1 == cache[2][37:6]) ? 4'h2 :
    (key1 == cache[3][37:6]) ? 4'h3 :
    (key1 == cache[4][37:6]) ? 4'h4 :
    (key1 == cache[5][37:6]) ? 4'h5 :
    (key1 == cache[6][37:6]) ? 4'h6 :
    (key1 == cache[7][37:6]) ? 4'h7 :
    4'hf;

  assign addr1_out = 
    {((addr1_index == 4'd0) ? cache[0][5:0] :
    (addr1_index == 4'd1) ? cache[1][5:0] :
    (addr1_index == 4'd2) ? cache[2][5:0] :
    (addr1_index == 4'd3) ? cache[3][5:0] :
    (addr1_index == 4'd4) ? cache[4][5:0] :
    (addr1_index == 4'd5) ? cache[5][5:0] :
    (addr1_index == 4'd6) ? cache[6][5:0] :
    (addr1_index == 4'd7) ? cache[7][5:0] :
    6'd0), addr1[11:0]};

  wire [3:0]addr2_index = 
    (read_addr == cache[0][37:6]) ? 4'h0 :
    (read_addr == cache[1][37:6]) ? 4'h1 :
    (read_addr == cache[2][37:6]) ? 4'h2 :
    (read_addr == cache[3][37:6]) ? 4'h3 :
    (read_addr == cache[4][37:6]) ? 4'h4 :
    (read_addr == cache[5][37:6]) ? 4'h5 :
    (read_addr == cache[6][37:6]) ? 4'h6 :
    (read_addr == cache[7][37:6]) ? 4'h7 :
    4'hf;

  assign read_addr_out = 
    (read_addr == 4'd0) ? cache[0][5:0] :
    (read_addr == 4'd1) ? cache[1][5:0] :
    (read_addr == 4'd2) ? cache[2][5:0] :
    (read_addr == 4'd3) ? cache[3][5:0] :
    (read_addr == 4'd4) ? cache[4][5:0] :
    (read_addr == 4'd5) ? cache[5][5:0] :
    (read_addr == 4'd6) ? cache[6][5:0] :
    (read_addr == 4'd7) ? cache[7][5:0] :
    6'd0;

  always @(posedge clk) begin
    if (we) begin
      cache[eviction_tgt] <= {read_addr, write_data[5:0]};
      eviction_tgt <= eviction_tgt + 3'd1;
    end
  end

endmodule