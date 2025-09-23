module tlb(
  input kmode, input [11:0]pid,
  input [31:0]addr0, input [31:0]addr1, input [31:0]read_addr,


  output [17:0]addr0_out, output [17:0]addr1_out
);
  // TODO: associative memory
  // pid (12 bits) | addr (20 bits)

  // reg cache

  // ({pid, addr} == cache[0][top:]) ? cache[0][:bottom] : ...

endmodule