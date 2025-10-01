`timescale 1ps/1ps

module dioptase(
`ifndef SIMULATION
    input clk,
    input ps2_clk, input ps2_data,
    output vga_h_sync, vga_v_sync,
    output [3:0]vga_red,
    output [3:0]vga_green,
    output [3:0]vga_blue,
    input uart_rx,
    output uart_tx
`endif
);
    
    reg [1023:0] vcdfile;
    initial begin
      if ($value$plusargs("vcd=%s", vcdfile)) begin
        $dumpfile(vcdfile);
        $dumpvars(0, dioptase);
      end else begin
        $dumpfile("cpu.vcd");
        `ifdef SIMULATION
          $dumpvars(0, dioptase);
        `endif
      end
    end

    `ifdef SIMULATION
      wire clk;
      wire ps2_clk = 0;
      wire ps2_data = 0;
      wire vga_h_sync; 
      wire vga_v_sync;
      wire [3:0]vga_red;
      wire [3:0]vga_green;
      wire [3:0]vga_blue;
      wire uart_rx = 0;
      wire uart_tx;
      clock c0(clk);
    `endif

    // Memory
    wire [17:0]mem_read0_addr;
    wire [31:0]mem_read0_data;
    wire [17:0]mem_read1_addr;
    wire [31:0]mem_read1_data;
    wire [3:0]mem_write_en;
    wire [17:0]mem_write_addr;
    wire [31:0]mem_write_data;

    wire clk_en;

    // CPU
    wire [31:0]ret_val;
    wire [31:0]cpu_pc;
    wire [3:0]flags;

    wire [15:0]interrupts;
    wire [15:0]mem_interrupts;
    wire ps2_ready_flag;

    assign interrupts = mem_interrupts | {14'b0, ps2_ready_flag, 1'b0};

    pipelined_cpu cpu(
        clk, interrupts,
        mem_read0_addr, mem_read0_data,
        mem_read1_addr, mem_read1_data,
        mem_write_en, mem_write_addr, mem_write_data,
        ret_val, flags, cpu_pc, clk_en
    );

     // PS/2
    wire ps2_ren;
    wire [15:0]ps2_data_out;
    ps2 ps2(.ps2_clk(ps2_clk), .ps2_data(ps2_data), .clk(clk), .ren(ps2_ren), .data(ps2_data_out), .ready(ps2_ready_flag));

    // VGA
    wire [9:0]pixel_addr_x;
    wire [9:0]pixel_addr_y;
    wire displaying;
    wire [11:0]display_pixel;
    wire [11:0]pixel = displaying ? display_pixel : 12'h000;
    assign vga_red = pixel[3:0];
    assign vga_green = pixel[7:4];
    assign vga_blue = pixel[11:8];

    vga vga(
        .clk(clk), .clk_100MHz(clk),
        .h_sync_out(vga_h_sync), .v_sync_out(vga_v_sync),
        .pixel_addr_x(pixel_addr_x), .pixel_addr_y(pixel_addr_y),
        .display_out(displaying)
    );

    wire uart_tx_en;
    wire uart_rx_en;
    wire [7:0]uart_tx_data;
    wire [7:0]uart_rx_data;

    // TODO: baud_clk may need to be different than clk
    // clk will be the slower clock for the pc
    // but baud_clk should be the 100MHz clock

    uart uart(
        .clk(clk), .baud_clk(clk), 
        .tx_en(uart_tx_en), .tx_data(uart_tx_data), .tx(uart_tx),
        .rx(uart_rx), .rx_en(uart_rx_en), .rx_data(uart_rx_data)
    );

    mem mem(.clk(clk), .clk_en(clk_en),
        .raddr0(mem_read0_addr), .rdata0(mem_read0_data),
        .raddr1(mem_read1_addr), .rdata1(mem_read1_data),
        .wen(mem_write_en), .waddr(mem_write_addr), .wdata(mem_write_data),
        .ps2_ren(ps2_ren),
        .ps2_data_in(ps2_data_out),
        .pixel_x_in(pixel_addr_x), .pixel_y_in(pixel_addr_y), .pixel(display_pixel),
        .uart_tx_data(uart_tx_data), .uart_tx_wen(uart_tx_en),
        .uart_rx_data(uart_rx_data), .uart_rx_ren(uart_rx_en),
        .interrupts(mem_interrupts)
    );

endmodule