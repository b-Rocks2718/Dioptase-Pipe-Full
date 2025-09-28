module tlb(input clk, input clk_en,
  input kmode, input [11:0]pid,
  input [31:0]addr0, input [31:0]addr1, input [31:0]read_addr,
  input we, input [31:0]write_data, input [7:0]exc_in, input clear,

  output [7:0]exc_out0, output [7:0]exc_out1,
  output [17:0]addr0_out, output [17:0]addr1_out, output [5:0]read_addr_out

);
  // pid (12 bits) | addr (20 bits)

  // 1 bit (valid) + 32 bits (key) + 6 (value) = 39 bits

  reg [38:0]cache[0:3'h7];

  initial begin
    begin
      cache[0] <= 39'b0;
      cache[1] <= 39'b0;
      cache[2] <= 39'b0;
      cache[3] <= 39'b0;
      cache[4] <= 39'b0;
      cache[5] <= 39'b0;
      cache[6] <= 39'b0;
      cache[7] <= 39'b0;
    end
  end

  reg [2:0]eviction_tgt = 3'b0;

  wire [31:0]key0 = {pid, addr0[31:12]};
  wire [31:0]key1 = {pid, addr1[31:12]};

  wire is_bottom_addr0 = addr0 < 18'h30000;
  wire is_bottom_addr1 = addr1 < 18'h30000;

  assign exc_out0 = (addr0_index == 4'hf && !(is_bottom_addr0 && kmode)) ? 
    // tlb miss exception
    ( kmode ? 8'h83 : // kmiss
              8'h82   // umiss
    ) : 8'd0;

  assign exc_out1 = 
  (exc_in != 8'd0) ? exc_in : (
  (addr1_index == 4'hf  && !(is_bottom_addr0 && kmode)) ? 
    // tlb miss exception
    ( kmode ? 8'h83 : // kmiss
              8'h82   // umiss
    ) : 8'd0);

  wire is_exc = exc_out1 != 8'd0;

  wire [3:0]addr0_index = 
    (key0 == cache[0][37:6] && cache[0][38]) ? 4'h0 :
    (key0 == cache[1][37:6] && cache[1][38]) ? 4'h1 :
    (key0 == cache[2][37:6] && cache[2][38]) ? 4'h2 :
    (key0 == cache[3][37:6] && cache[3][38]) ? 4'h3 :
    (key0 == cache[4][37:6] && cache[4][38]) ? 4'h4 :
    (key0 == cache[5][37:6] && cache[5][38]) ? 4'h5 :
    (key0 == cache[6][37:6] && cache[6][38]) ? 4'h6 :
    (key0 == cache[7][37:6] && cache[7][38]) ? 4'h7 :
    4'hf;

  assign addr0_out = (is_bottom_addr0 && kmode) ? addr0[17:0] :
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
    (key1 == cache[0][37:6] && cache[0][38]) ? 4'h0 :
    (key1 == cache[1][37:6] && cache[1][38]) ? 4'h1 :
    (key1 == cache[2][37:6] && cache[2][38]) ? 4'h2 :
    (key1 == cache[3][37:6] && cache[3][38]) ? 4'h3 :
    (key1 == cache[4][37:6] && cache[4][38]) ? 4'h4 :
    (key1 == cache[5][37:6] && cache[5][38]) ? 4'h5 :
    (key1 == cache[6][37:6] && cache[6][38]) ? 4'h6 :
    (key1 == cache[7][37:6] && cache[7][38]) ? 4'h7 :
    4'hf;

  assign addr1_out = (is_bottom_addr1 && kmode) ? addr0[17:0] : (
    is_exc ? {8'b0, exc_out1, 2'b0} : 
    {((addr1_index == 4'd0) ? cache[0][5:0] :
    (addr1_index == 4'd1) ? cache[1][5:0] :
    (addr1_index == 4'd2) ? cache[2][5:0] :
    (addr1_index == 4'd3) ? cache[3][5:0] :
    (addr1_index == 4'd4) ? cache[4][5:0] :
    (addr1_index == 4'd5) ? cache[5][5:0] :
    (addr1_index == 4'd6) ? cache[6][5:0] :
    (addr1_index == 4'd7) ? cache[7][5:0] :
    6'd0), addr1[11:0]});

  wire [3:0]addr2_index = 
    (read_addr == cache[0][37:6] && cache[0][38]) ? 4'h0 :
    (read_addr == cache[1][37:6] && cache[1][38]) ? 4'h1 :
    (read_addr == cache[2][37:6] && cache[2][38]) ? 4'h2 :
    (read_addr == cache[3][37:6] && cache[3][38]) ? 4'h3 :
    (read_addr == cache[4][37:6] && cache[4][38]) ? 4'h4 :
    (read_addr == cache[5][37:6] && cache[5][38]) ? 4'h5 :
    (read_addr == cache[6][37:6] && cache[6][38]) ? 4'h6 :
    (read_addr == cache[7][37:6] && cache[7][38]) ? 4'h7 :
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
    if (clk_en) begin
      if (we && !clear) begin
        cache[eviction_tgt] <= {1'b1, read_addr, write_data[5:0]};
        eviction_tgt <= eviction_tgt + 3'd1;
      end else if (clear) begin
        cache[0] <= 39'b0;
        cache[1] <= 39'b0;
        cache[2] <= 39'b0;
        cache[3] <= 39'b0;
        cache[4] <= 39'b0;
        cache[5] <= 39'b0;
        cache[6] <= 39'b0;
        cache[7] <= 39'b0;
      end
    end
  end

endmodule