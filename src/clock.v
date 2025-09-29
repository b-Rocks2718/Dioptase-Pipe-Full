`timescale 1ns/1ps

module clock(output clk);
    reg theClock = 1;

    assign clk = theClock;

`ifndef VERILATOR
    // For Icarus: internal free-running clock
    always begin
        #500 theClock = !theClock;  // 100 MHz
    end
`endif
endmodule
