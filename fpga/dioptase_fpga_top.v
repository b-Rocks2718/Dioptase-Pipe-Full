`timescale 1ns/1ps

//------------------------------------------------------------------------------
// dioptase_fpga_top
//
// Purpose:
// - FPGA board wrapper for the Dioptase full pipeline core on Nexys A7.
// - Exposes physical board I/O and instantiates the architecture-level
//   `dioptase` SoC module.
//
// Inputs:
// - CLK100MHZ: board master clock (expected 100 MHz).
// - CPU_RESETN: active-low board reset button input. The current SoC does not
//   yet implement a reset port, so this is reserved for future integration.
// - PS2_CLK/PS2_DATA: keyboard input.
// - uart_rx: UART RX line from USB-UART bridge.
// - sd*_miso: SD card MISO lines.
//
// Outputs:
// - VGA timing + RGB outputs.
// - uart_tx: UART TX line to USB-UART bridge.
// - sd* SPI lines: cs/clk/mosi.
//
//------------------------------------------------------------------------------
module dioptase_fpga_top(
    input wire CLK100MHZ,
    input wire CPU_RESETN,
    input wire PS2_CLK,
    input wire PS2_DATA,
    output wire VGA_HS,
    output wire VGA_VS,
    output wire [3:0] VGA_R,
    output wire [3:0] VGA_G,
    output wire [3:0] VGA_B,
    input wire uart_rx,
    output wire uart_tx,
    output wire sd0_spi_cs,
    output wire sd0_spi_clk,
    output wire sd0_spi_mosi,
    input wire sd0_spi_miso,
    output wire sd1_spi_cs,
    output wire sd1_spi_clk,
    output wire sd1_spi_mosi,
    input wire sd1_spi_miso
`ifdef FPGA_USE_DDR_SRAM_ADAPTER
    ,
    // DDR2 physical interface routed to the onboard memory.
    output wire [12:0] ddr2_addr,
    output wire [2:0] ddr2_ba,
    output wire ddr2_ras_n,
    output wire ddr2_cas_n,
    output wire ddr2_we_n,
    output wire [0:0] ddr2_ck_p,
    output wire [0:0] ddr2_ck_n,
    output wire [0:0] ddr2_cke,
    output wire [0:0] ddr2_cs_n,
    output wire [1:0] ddr2_dm,
    output wire [0:0] ddr2_odt,
    inout wire [15:0] ddr2_dq,
    inout wire [1:0] ddr2_dqs_p,
    inout wire [1:0] ddr2_dqs_n
`endif
);
    // Reserve reset input for future explicit reset wiring.
    wire unused_cpu_resetn = CPU_RESETN;

    dioptase u_dioptase (
        .clk(CLK100MHZ),
        .ps2_clk(PS2_CLK),
        .ps2_data(PS2_DATA),
        .vga_h_sync(VGA_HS),
        .vga_v_sync(VGA_VS),
        .vga_red(VGA_R),
        .vga_green(VGA_G),
        .vga_blue(VGA_B),
        .uart_rx(uart_rx),
        .uart_tx(uart_tx),
        .sd_spi_cs(sd0_spi_cs),
        .sd_spi_clk(sd0_spi_clk),
        .sd_spi_mosi(sd0_spi_mosi),
        .sd_spi_miso(sd0_spi_miso),
        .sd1_spi_cs(sd1_spi_cs),
        .sd1_spi_clk(sd1_spi_clk),
        .sd1_spi_mosi(sd1_spi_mosi),
        .sd1_spi_miso(sd1_spi_miso),
`ifdef FPGA_USE_DDR_SRAM_ADAPTER
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
