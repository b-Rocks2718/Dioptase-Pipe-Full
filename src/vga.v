`timescale 1ps/1ps

// Informed by https://github.com/BlagojeBlagojevic/vga_verilog
// and https://github.com/ColtonBeery/Basys3_VGA_Testbench/tree/master

module vga(
    input clk_100MHz,
    output h_sync_out, output v_sync_out,
    output [9:0]pixel_addr_x, output [9:0]pixel_addr_y,
    output display_out
);

    localparam H_ACTIVE = 640;
    localparam H_FRONTPORCH = 16;
    localparam H_SYNC = 96;
    localparam H_BACKPORCH = 48;
    localparam H_TOTAL = H_ACTIVE + H_FRONTPORCH + H_SYNC + H_BACKPORCH;

    localparam V_ACTIVE = 480;
    localparam V_FRONTPORCH = 10;
    localparam V_SYNC = 2;
    localparam V_BACKPORCH = 32;
    localparam V_TOTAL = V_ACTIVE + V_FRONTPORCH + V_SYNC + V_BACKPORCH;

    // Horizontal/vertical pixel counters advance on `pixel_tick`.
    // `pixel_tick` is a clock-enable pulse that fires once every four 100MHz
    // cycles, yielding a 25MHz pixel cadence without creating a derived clock.
    reg [9:0]h_counter = 0;
    reg [9:0]v_counter = 0;
    reg [1:0]clk_div = 0;
    wire pixel_tick = (clk_div == 2'd3);

    always @(posedge clk_100MHz) begin
        clk_div <= clk_div + 1;
        if (pixel_tick) begin
            if (h_counter == H_TOTAL - 1) begin
                h_counter <= 0;
                if (v_counter == V_TOTAL - 1)
                    v_counter <= 0;
                else
                    v_counter <= v_counter + 1;
            end else begin
                h_counter <= h_counter + 1;
            end
        end
    end

    assign h_sync_out = !((h_counter >= H_ACTIVE + H_FRONTPORCH) &&
      (h_counter < H_ACTIVE + H_FRONTPORCH + H_SYNC));
    assign v_sync_out = !((v_counter >= V_ACTIVE + V_FRONTPORCH) &&
      (v_counter < V_ACTIVE + V_FRONTPORCH + V_SYNC));
    assign display_out = h_counter < H_ACTIVE && v_counter < V_ACTIVE;
    assign pixel_addr_x = h_counter;
    assign pixel_addr_y = v_counter;

endmodule
