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
    output uart_tx,
    output sd_spi_cs,
    output sd_spi_clk,
    output sd_spi_mosi,
    input sd_spi_miso,
    output sd1_spi_cs,
    output sd1_spi_clk,
    output sd1_spi_mosi,
    input sd1_spi_miso,
    output [15:0] LED
`ifdef FPGA_USE_DDR_SRAM_ADAPTER
    ,
    // DDR2 pins are only present when FPGA external-memory mode is enabled.
    output [12:0]ddr2_addr,
    output [2:0]ddr2_ba,
    output ddr2_ras_n,
    output ddr2_cas_n,
    output ddr2_we_n,
    output [0:0]ddr2_ck_p,
    output [0:0]ddr2_ck_n,
    output [0:0]ddr2_cke,
    output [0:0]ddr2_cs_n,
    output [1:0]ddr2_dm,
    output [0:0]ddr2_odt,
    inout [15:0]ddr2_dq,
    inout [1:0]ddr2_dqs_p,
    inout [1:0]ddr2_dqs_n
`endif
`endif
);
    
    // Simulation-only waveform dumping. Vivado synthesis does not support
    // these system tasks and must not see them.
    `ifndef SYNTHESIS
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
    `endif

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
      wire sd_spi_cs;
      wire sd_spi_clk;
      wire sd_spi_mosi;
      reg sd_spi_miso;
      initial sd_spi_miso = 1'b1;
      wire sd1_spi_cs;
      wire sd1_spi_clk;
      wire sd1_spi_mosi;
      reg sd1_spi_miso;
      initial sd1_spi_miso = 1'b1;
      clock c0(clk);
    `endif

    // Memory
    wire [26:0]mem_read0_addr;
    wire [31:0]mem_read0_tag;
    wire mem_read0_valid;
    wire [31:0]mem_read0_data;
    wire [31:0]mem_read0_data_tag;
    wire mem_read0_accepted;
    wire [26:0]mem_read1_addr;
    wire [31:0]mem_read1_data;
    wire [3:0]mem_write_en;
    wire mem_read_en;
    wire [26:0]mem_write_addr;
    wire [31:0]mem_write_data;

    wire clk_en;
    wire pipe_clk_en;



    // CPU
    assign LED = ret_val[15:0];

    wire [31:0]ret_val;
    wire [31:0]cpu_pc;
    wire [3:0]flags;

    wire [15:0]interrupts;
    wire [15:0]mem_interrupts;
    wire [31:0]clock_divider;
    wire ps2_ready_flag;
    wire uart_rx_ready;

    assign interrupts = mem_interrupts | {13'b0, uart_rx_ready, ps2_ready_flag, 1'b0};

    wire icache_stall;
    wire dcache_stall;

    // Minimal memory handshake shim (no cache):
    // - Accept every fetch request when the core clock enable is asserted.
    // - Return a tag delayed by one enabled cycle to align with mem.v's
    //   1-cycle synchronous RAM read latency.
    // - Report no cache-induced stalls.
    //
    // Preconditions:
    // - mem.v uses clk_en to latch raddr0 and update rdata0 on the next cycle.
    // - pipelined_cpu expects mem_read0_data_tag to match the slot id for the
    //   instruction word presented on mem_read0_data.
    //
    // Postconditions:
    // - Frontend queue pairing sees a stable tag match when memory returns data.
    // - No cache stalls are asserted in this minimal configuration.
    //
    // Invariants:
    // - mem_read0_data_tag always equals mem_read0_tag sampled two clk_en cycles ago.
    // - icache_stall/dcache_stall remain deasserted for all cycles.
    //
    // CPU state assumptions:
    // - Single-core, no external cache hierarchy is modeled in this top-level.
    reg [31:0]mem_read0_tag_d0 = 32'd0;
    reg [31:0]mem_read0_tag_d1 = 32'd0;
    always @(posedge clk) begin
      if (clk_en) begin
        mem_read0_tag_d0 <= mem_read0_tag;
        mem_read0_tag_d1 <= mem_read0_tag_d0;
      end
    end
    assign mem_read0_data_tag = mem_read0_tag_d1;
    assign mem_read0_accepted = mem_read0_valid && clk_en;
    assign icache_stall = 1'b0;
    assign dcache_stall = 1'b0;

    pipelined_cpu cpu(
        clk, interrupts, clock_divider,
        mem_read0_addr, mem_read0_tag, mem_read0_valid, mem_read0_data, mem_read0_data_tag, mem_read0_accepted,
        icache_stall, dcache_stall,
        mem_read_en, mem_read1_addr, mem_read1_data,
        mem_write_en, mem_write_addr, mem_write_data,
        ret_val, flags, cpu_pc, clk_en, pipe_clk_en
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
        .clk_100MHz(clk),
        .h_sync_out(vga_h_sync), .v_sync_out(vga_v_sync),
        .pixel_addr_x(pixel_addr_x), .pixel_addr_y(pixel_addr_y),
        .display_out(displaying)
    );

    wire uart_tx_en;
    wire uart_rx_en;
    wire [7:0]uart_tx_data;
    wire [7:0]uart_rx_data;

    uart uart(
        .clk(clk), .baud_clk(clk), 
        .tx_en(uart_tx_en), .tx_data(uart_tx_data), .tx(uart_tx),
        .rx(uart_rx), .rx_en(uart_rx_en), .rx_data(uart_rx_data),
        .rx_ready(uart_rx_ready)
    );

    mem mem(.clk(clk), .clk_en(clk_en),
        .raddr0(mem_read0_addr),
        .rdata0(mem_read0_data),
        .ren(mem_read_en), .raddr1(mem_read1_addr), .rdata1(mem_read1_data),
        .wen(mem_write_en), .waddr(mem_write_addr), .wdata(mem_write_data),
        .ps2_ren(ps2_ren),
        .ps2_data_in(ps2_data_out),
        .pixel_x_in(pixel_addr_x), .pixel_y_in(pixel_addr_y), .pixel(display_pixel),
        .uart_tx_data(uart_tx_data), .uart_tx_wen(uart_tx_en),
        .uart_rx_data(uart_rx_data), .uart_rx_ren(uart_rx_en),
        .sd_spi_cs(sd_spi_cs), .sd_spi_clk(sd_spi_clk), .sd_spi_mosi(sd_spi_mosi), .sd_spi_miso(sd_spi_miso),
        .sd1_spi_cs(sd1_spi_cs), .sd1_spi_clk(sd1_spi_clk), .sd1_spi_mosi(sd1_spi_mosi), .sd1_spi_miso(sd1_spi_miso),
        .interrupts(mem_interrupts),
        .clock_divider(clock_divider)
`ifdef FPGA_USE_DDR_SRAM_ADAPTER
        ,
        .ddr2_addr(ddr2_addr),
        .ddr2_ba(ddr2_ba),
        .ddr2_ras_n(ddr2_ras_n),
        .ddr2_cas_n(ddr2_cas_n),
        .ddr2_we_n(ddr2_we_n),
        .ddr2_ck_p(ddr2_ck_p),
        .ddr2_ck_n(ddr2_ck_n),
        .ddr2_cke(ddr2_cke),
        .ddr2_cs_n(ddr2_cs_n),
        .ddr2_dm(ddr2_dm),
        .ddr2_odt(ddr2_odt),
        .ddr2_dq(ddr2_dq),
        .ddr2_dqs_p(ddr2_dqs_p),
        .ddr2_dqs_n(ddr2_dqs_n)
`endif
    );

endmodule
