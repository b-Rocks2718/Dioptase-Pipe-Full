`timescale 1ps/1ps

module mem(input clk, input clk_en, input pipe_clk_en,
    input [26:0]raddr0, input [31:0]rtag0, output reg [31:0]rdata0, output reg [31:0]rdata0_tag,
    input icache_req_valid,
    output icache_issue_accepted,
    input ren, input [26:0]raddr1, output reg [31:0]rdata1,
    input [3:0]wen, input [26:0]waddr, input [31:0]wdata,
    output ps2_ren, input [15:0]ps2_data_in,
    input [9:0]pixel_x_in, input [9:0]pixel_y_in, output [11:0]pixel,
    output reg [7:0]uart_tx_data, output uart_tx_wen,
    input [7:0]uart_rx_data, output uart_rx_ren,
    output sd_spi_cs, output sd_spi_clk, output sd_spi_mosi, input sd_spi_miso,
    output sd1_spi_cs, output sd1_spi_clk, output sd1_spi_mosi, input sd1_spi_miso,
    output [15:0]interrupts,
    output icache_stall, output dcache_stall,
    output [31:0]clock_divider
`ifdef FPGA_USE_DDR_SRAM_ADAPTER
    ,
    // External DDR2 interface pins exposed when the Digilent-style DDR bridge
    // is selected. These are forwarded to `ddr_sram_adapter`.
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
);
    // Display memory map (physical):
    // - Tile framebuffer: 0x7FBD000..0x7FBF57F (80x60 entries, 2 bytes each).
    // - Pixel framebuffer: 0x7FC0000..0x7FE57FF (320x240 pixels, 2 bytes each).
    localparam TILE_FRAMEBUFFER_START = 27'h7FBD000;
    localparam TILE_FRAMEBUFFER_SIZE = 27'd9600;      // 80 * 60 * 2 bytes
    localparam TILE_FRAMEBUFFER_END = TILE_FRAMEBUFFER_START + TILE_FRAMEBUFFER_SIZE;
    localparam PIXEL_FRAMEBUFFER_START = 27'h7FC0000;
    localparam PIXEL_FRAMEBUFFER_SIZE = 27'd153600;   // 320 * 240 * 2 bytes
    localparam PIXEL_FRAMEBUFFER_END = PIXEL_FRAMEBUFFER_START + PIXEL_FRAMEBUFFER_SIZE;

    // General RAM window: physical low memory up to the display aperture.
    localparam RAM_END = TILE_FRAMEBUFFER_START; // exclusive
    localparam TILEMAP_START = 27'h7FE8000;
    localparam TILEMAP_END = 27'h7FF0000;       // exclusive

    localparam SPRITE_0_START = 27'h7FF0000;
    localparam SPRITE_1_START = 27'h7FF0800;
    localparam SPRITE_2_START = 27'h7FF1000;
    localparam SPRITE_3_START = 27'h7FF1800;
    localparam SPRITE_4_START = 27'h7FF2000;
    localparam SPRITE_5_START = 27'h7FF2800;
    localparam SPRITE_6_START = 27'h7FF3000;
    localparam SPRITE_7_START = 27'h7FF3800;
    localparam SPRITE_8_START = 27'h7FF4000;
    localparam SPRITE_9_START = 27'h7FF4800;
    localparam SPRITE_10_START = 27'h7FF5000;
    localparam SPRITE_11_START = 27'h7FF5800;
    localparam SPRITE_12_START = 27'h7FF6000;
    localparam SPRITE_13_START = 27'h7FF6800;
    localparam SPRITE_14_START = 27'h7FF7000;
    localparam SPRITE_15_START = 27'h7FF7800;
    localparam SPRITE_DATA_END = 27'h7FF8000; // sprites 0..15

    localparam PS2_REG = 27'h7FE5800;
    localparam UART_TX_REG = 27'h7FE5802;
    localparam UART_RX_REG = 27'h7FE5803;
    localparam PIT_START = 27'h7FE5804;

    localparam SPRITE_0_X = 27'h7FE5B00;
    localparam SPRITE_0_Y = 27'h7FE5B02;
    localparam SPRITE_1_X = 27'h7FE5B04;
    localparam SPRITE_1_Y = 27'h7FE5B06;
    localparam SPRITE_2_X = 27'h7FE5B08;
    localparam SPRITE_2_Y = 27'h7FE5B0A;
    localparam SPRITE_3_X = 27'h7FE5B0C;
    localparam SPRITE_3_Y = 27'h7FE5B0E;
    localparam SPRITE_4_X = 27'h7FE5B10;
    localparam SPRITE_4_Y = 27'h7FE5B12;
    localparam SPRITE_5_X = 27'h7FE5B14;
    localparam SPRITE_5_Y = 27'h7FE5B16;
    localparam SPRITE_6_X = 27'h7FE5B18;
    localparam SPRITE_6_Y = 27'h7FE5B1A;
    localparam SPRITE_7_X = 27'h7FE5B1C;
    localparam SPRITE_7_Y = 27'h7FE5B1E;
    localparam SPRITE_8_X = 27'h7FE5B20;
    localparam SPRITE_8_Y = 27'h7FE5B22;
    localparam SPRITE_9_X = 27'h7FE5B24;
    localparam SPRITE_9_Y = 27'h7FE5B26;
    localparam SPRITE_10_X = 27'h7FE5B28;
    localparam SPRITE_10_Y = 27'h7FE5B2A;
    localparam SPRITE_11_X = 27'h7FE5B2C;
    localparam SPRITE_11_Y = 27'h7FE5B2E;
    localparam SPRITE_12_X = 27'h7FE5B30;
    localparam SPRITE_12_Y = 27'h7FE5B32;
    localparam SPRITE_13_X = 27'h7FE5B34;
    localparam SPRITE_13_Y = 27'h7FE5B36;
    localparam SPRITE_14_X = 27'h7FE5B38;
    localparam SPRITE_14_Y = 27'h7FE5B3A;
    localparam SPRITE_15_X = 27'h7FE5B3C;
    localparam SPRITE_15_Y = 27'h7FE5B3E;

    localparam HSCROLL_REG = 27'h7FE5B40;
    localparam VSCROLL_REG = 27'h7FE5B42;
    localparam SCALE_REG = 27'h7FE5B44;
    localparam VGA_STATUS_REG = 27'h7FE5B46;
    localparam VGA_FRAME_REG = 27'h7FE5B48;
    localparam CLOCK_DIV_REG = 27'h7FE5B4C;
    localparam PIXEL_HSCROLL_REG = 27'h7FE5B50;
    localparam PIXEL_VSCROLL_REG = 27'h7FE5B52;
    localparam PIXEL_SCALE_REG = 27'h7FE5B54;
    localparam SPRITE_SCALE_BASE = 27'h7FE5B60;
    localparam SPRITE_SCALE_END = 27'h7FE5B70;

    // SD DMA MMIO register surface (SD card 0 and SD card 1 windows).
    localparam SD0_DMA_MEM_ADDR_REG = 27'h7FE5810;
    localparam SD0_DMA_SD_BLOCK_REG = 27'h7FE5814;
    localparam SD0_DMA_LEN_REG = 27'h7FE5818;
    localparam SD0_DMA_CTRL_REG = 27'h7FE581C;
    localparam SD0_DMA_STATUS_REG = 27'h7FE5820;
    localparam SD0_DMA_ERR_REG = 27'h7FE5824;

    localparam SD1_DMA_MEM_ADDR_REG = 27'h7FE5828;
    localparam SD1_DMA_SD_BLOCK_REG = 27'h7FE582C;
    localparam SD1_DMA_LEN_REG = 27'h7FE5830;
    localparam SD1_DMA_CTRL_REG = 27'h7FE5834;
    localparam SD1_DMA_STATUS_REG = 27'h7FE5838;
    localparam SD1_DMA_ERR_REG = 27'h7FE583C;

    localparam SD_DMA_MMIO_END = 27'h7FE583F;

    localparam [7:0] SD_SPI_CMD0 = 8'h40;
    localparam [7:0] SD_SPI_CMD17 = 8'h51;
    localparam [7:0] SD_SPI_CMD24 = 8'h58;
    localparam [7:0] SD_SPI_CMD55 = 8'h77;
    localparam [7:0] SD_SPI_CMD58 = 8'h7A;
    localparam [7:0] SD_SPI_ACMD41 = 8'h69;
    localparam [7:0] SD_SPI_R1_IDLE = 8'h01;
    localparam [7:0] SD_SPI_R1_READY = 8'h00;
    localparam [7:0] SD_SPI_R1_ILLEGAL = 8'h05;
    localparam [7:0] SD_SPI_INIT_MAX_ACMD41_ATTEMPTS = 8'd32;
    localparam [2:0] SD_INIT_STATE_IDLE = 3'd0;
    localparam [2:0] SD_INIT_STATE_WAIT_CMD0 = 3'd1;
    localparam [2:0] SD_INIT_STATE_WAIT_CMD8 = 3'd2;
    localparam [2:0] SD_INIT_STATE_WAIT_CMD55 = 3'd3;
    localparam [2:0] SD_INIT_STATE_WAIT_ACMD41 = 3'd4;
    localparam [2:0] SD_INIT_STATE_WAIT_CMD58 = 3'd5;
    localparam integer RAM_WORD_ADDR_BITS = 25; // Covers 0x0000000..0x7FBD000 RAM window.
    localparam integer RAM_ACCESS_LATENCY = 1;  // Keep ISA tests within default cycle budget.
    // Sprite backing storage (sprites 0..15).
    (* ram_style = "block" *) reg [31:0]sprite_0_data[0:16'h1ff];
    (* ram_style = "block" *) reg [31:0]sprite_1_data[0:16'h1ff];
    (* ram_style = "block" *) reg [31:0]sprite_2_data[0:16'h1ff];
    (* ram_style = "block" *) reg [31:0]sprite_3_data[0:16'h1ff];
    (* ram_style = "block" *) reg [31:0]sprite_4_data[0:16'h1ff];
    (* ram_style = "block" *) reg [31:0]sprite_5_data[0:16'h1ff];
    (* ram_style = "block" *) reg [31:0]sprite_6_data[0:16'h1ff];
    (* ram_style = "block" *) reg [31:0]sprite_7_data[0:16'h1ff];
    (* ram_style = "block" *) reg [31:0]sprite_8_data[0:16'h1ff];
    (* ram_style = "block" *) reg [31:0]sprite_9_data[0:16'h1ff];
    (* ram_style = "block" *) reg [31:0]sprite_10_data[0:16'h1ff];
    (* ram_style = "block" *) reg [31:0]sprite_11_data[0:16'h1ff];
    (* ram_style = "block" *) reg [31:0]sprite_12_data[0:16'h1ff];
    (* ram_style = "block" *) reg [31:0]sprite_13_data[0:16'h1ff];
    (* ram_style = "block" *) reg [31:0]sprite_14_data[0:16'h1ff];
    (* ram_style = "block" *) reg [31:0]sprite_15_data[0:16'h1ff];
    
    // Tile map + tile/pixel framebuffer storage for the high MMIO regions.
    (* ram_style = "block" *) reg [31:0]tile_map[0:16'h1fff];
    (* ram_style = "block" *) reg [31:0]frame_buffer[0:16'h095f];
`ifdef FPGA_DISABLE_PIXEL_FB
    // FPGA fit mode:
    // - Pixel framebuffer storage is removed to reduce BRAM/LUT pressure.
    // - Tile layer + sprites remain active for VGA output.
    // - Pixel framebuffer MMIO writes are ignored and reads return 0.
`elsif FPGA_USE_DDR_SRAM_ADAPTER
    // Vivado implementation guard:
    // - Disable BRAM cascading for the large pixel buffer in DDR-adapter FPGA
    //   builds. This avoids REQP-1962 cascade ADDR15 DRC failures seen during
    //   place on inferred RAMB36 chains.
    (* ram_style = "block", cascade_height = 0 *) reg [31:0]pixel_buffer[0:16'h95ff];
`else
    (* ram_style = "block" *) reg [31:0]pixel_buffer[0:16'h95ff];
`endif

    integer i;
    initial begin
        for (i = 0; i < 16'h200; i = i + 1) begin
          sprite_0_data[i] = 32'hf000f000;
          sprite_1_data[i] = 32'hf000f000;
          sprite_2_data[i] = 32'hf000f000;
          sprite_3_data[i] = 32'hf000f000;
          sprite_4_data[i] = 32'hf000f000;
          sprite_5_data[i] = 32'hf000f000;
          sprite_6_data[i] = 32'hf000f000;
          sprite_7_data[i] = 32'hf000f000;
          sprite_8_data[i] = 32'hf000f000;
          sprite_9_data[i] = 32'hf000f000;
          sprite_10_data[i] = 32'hf000f000;
          sprite_11_data[i] = 32'hf000f000;
          sprite_12_data[i] = 32'hf000f000;
          sprite_13_data[i] = 32'hf000f000;
          sprite_14_data[i] = 32'hf000f000;
          sprite_15_data[i] = 32'hf000f000;
        end
        // Define deterministic reset state for display-backed memories.
        // cdiv/colors-style programs rely on tile/frame buffers starting clear.
        for (i = 0; i < 16'h2000; i = i + 1) begin
          tile_map[i] = 32'd0;
        end
`ifndef FPGA_DISABLE_PIXEL_FB
        for (i = 0; i < 16'h9600; i = i + 1) begin
          pixel_buffer[i] = 32'd0;
        end
`endif
        for (i = 0; i < 16'h960; i = i + 1) begin
          frame_buffer[i] = 32'd0;
        end
        for (i = 0; i < 16; i = i + 1) begin
          sprite_scale_regs[i] = 8'd0;
        end
        sd0_spi_cmd_buffer = 48'd0;
        sd0_spi_data_buffer = 4096'd0;
        sd0_spi_start_strobe = 1'b0;
        sd0_spi_launch_sent = 1'b0;
        sd0_irq_pending = 1'b0;
        sd0_dma_done_prev = 1'b0;
        sd0_dma_mem_addr_reg = 32'd0;
        sd0_dma_block_reg = 32'd0;
        sd0_dma_len_reg = 32'd0;
        sd0_dma_ctrl_write_pulse = 1'b0;
        sd0_dma_ctrl_write_data = 32'd0;
        sd0_dma_status_clear_pulse = 1'b0;
        sd0_init_state = SD_INIT_STATE_IDLE;
        sd0_init_acmd41_attempts = 8'd0;
        sd0_card_high_capacity = 1'b0;
        sd0_dma_sd_ready_pulse = 1'b0;
        sd0_dma_mem_ready_pulse = 1'b0;
        sd0_dma_mem_data_in = 32'd0;

        sd1_spi_cmd_buffer = 48'd0;
        sd1_spi_data_buffer = 4096'd0;
        sd1_spi_start_strobe = 1'b0;
        sd1_spi_launch_sent = 1'b0;
        sd1_irq_pending = 1'b0;
        sd1_dma_done_prev = 1'b0;
        sd1_dma_mem_addr_reg = 32'd0;
        sd1_dma_block_reg = 32'd0;
        sd1_dma_len_reg = 32'd0;
        sd1_dma_ctrl_write_pulse = 1'b0;
        sd1_dma_ctrl_write_data = 32'd0;
        sd1_dma_status_clear_pulse = 1'b0;
        sd1_init_state = SD_INIT_STATE_IDLE;
        sd1_init_acmd41_attempts = 8'd0;
        sd1_card_high_capacity = 1'b0;
        sd1_dma_sd_ready_pulse = 1'b0;
        sd1_dma_mem_ready_pulse = 1'b0;
        sd1_dma_mem_data_in = 32'd0;
        raddr0_buf = 27'd0;
        raddr1_buf = 27'd0;
        waddr_buf = 27'd0;
        ren_buf = 1'b0;
        wen_buf = 4'd0;
        ram_data0_out = 32'd0;
        ram_data0_tag_out = 32'd0;
        ram_data1_out = 32'd0;
        tilemap_data0_out = 32'd0;
        tilemap_data1_out = 32'd0;
        framebuffer_data0_out = 32'd0;
        framebuffer_data1_out = 32'd0;
        pixelbuffer_data1_out = 32'd0;
        sprite_0_data0_out = 32'd0;
        sprite_0_data1_out = 32'd0;
        sprite_1_data0_out = 32'd0;
        sprite_1_data1_out = 32'd0;
        sprite_2_data0_out = 32'd0;
        sprite_2_data1_out = 32'd0;
        sprite_3_data0_out = 32'd0;
        sprite_3_data1_out = 32'd0;
        sprite_4_data0_out = 32'd0;
        sprite_4_data1_out = 32'd0;
        sprite_5_data0_out = 32'd0;
        sprite_5_data1_out = 32'd0;
        sprite_6_data0_out = 32'd0;
        sprite_6_data1_out = 32'd0;
        sprite_7_data0_out = 32'd0;
        sprite_7_data1_out = 32'd0;
        sprite_8_data0_out = 32'd0;
        sprite_8_data1_out = 32'd0;
        sprite_9_data0_out = 32'd0;
        sprite_9_data1_out = 32'd0;
        sprite_10_data0_out = 32'd0;
        sprite_10_data1_out = 32'd0;
        sprite_11_data0_out = 32'd0;
        sprite_11_data1_out = 32'd0;
        sprite_12_data0_out = 32'd0;
        sprite_12_data1_out = 32'd0;
        sprite_13_data0_out = 32'd0;
        sprite_13_data1_out = 32'd0;
        sprite_14_data0_out = 32'd0;
        sprite_14_data1_out = 32'd0;
        sprite_15_data0_out = 32'd0;
        sprite_15_data1_out = 32'd0;
        rdata0 = 32'd0;
        rdata0_tag = 32'd0;
        rdata1 = 32'd0;
        uart_tx_data = 8'd0;
        pixel_scale_reg = 8'd0;
        pixel_vscroll_reg = 16'd0;
        pixel_hscroll_reg = 16'd0;
        clock_div_reg = 32'd0;
        pit_cfg_reg = 32'd0;
        vga_frame_count = 32'd0;
        in_vblank_prev = 1'b0;
        vga_vblank_irq = 1'b0;
        display_framebuffer_out = 32'd0;
        display_tile_entry_sel = 1'b0;
        display_tile_pixel_x = 10'd0;
        display_tile_pixel_y = 9'd0;
        display_tilemap_out = 32'd0;
        display_pixelbuffer_out = 32'd0;
        display_bg_pixel_x = 10'd0;
        display_screen_x = 10'd0;
        display_screen_y = 10'd0;
        icache_req_pending = 1'b0;
        icache_req_addr = 27'd0;
        icache_req_tag = 32'd0;
        dcache_req_pending = 1'b0;
        dcache_req_is_write = 1'b0;
        dcache_req_src = DCACHE_REQ_SRC_CPU;
        dcache_req_we = 4'd0;
        dcache_req_addr = 27'd0;
        dcache_req_wdata = 32'd0;
        dma_write_req_pending = 1'b0;
        dma_write_req_src = DCACHE_REQ_SRC_CPU;
        dma_write_req_addr = 27'd0;
        dma_write_req_wdata = 32'd0;
        icache_inv_pulse = 1'b0;
        dcache_inv_pulse = 1'b0;
        dma_inv_addr = 27'd0;
    end

    reg [26:0]raddr0_buf;
    reg [26:0]raddr1_buf;
    reg [26:0]waddr_buf;
    reg ren_buf = 1'b0;

    reg [3:0]wen_buf;

    reg [31:0]ram_data0_out;
    reg [31:0]ram_data0_tag_out;
    reg [31:0]ram_data1_out;
    reg [31:0]tilemap_data0_out = 0;
    reg [31:0]tilemap_data1_out;
    reg [31:0]framebuffer_data0_out = 0;
    reg [31:0]framebuffer_data1_out;
    reg [31:0]pixelbuffer_data1_out;

    reg [31:0]sprite_0_data0_out;
    reg [31:0]sprite_0_data1_out;
    reg [31:0]sprite_1_data0_out;
    reg [31:0]sprite_1_data1_out;
    reg [31:0]sprite_2_data0_out;
    reg [31:0]sprite_2_data1_out;
    reg [31:0]sprite_3_data0_out;
    reg [31:0]sprite_3_data1_out;
    reg [31:0]sprite_4_data0_out;
    reg [31:0]sprite_4_data1_out;
    reg [31:0]sprite_5_data0_out;
    reg [31:0]sprite_5_data1_out;
    reg [31:0]sprite_6_data0_out;
    reg [31:0]sprite_6_data1_out;
    reg [31:0]sprite_7_data0_out;
    reg [31:0]sprite_7_data1_out;
    reg [31:0]sprite_8_data0_out;
    reg [31:0]sprite_8_data1_out;
    reg [31:0]sprite_9_data0_out;
    reg [31:0]sprite_9_data1_out;
    reg [31:0]sprite_10_data0_out;
    reg [31:0]sprite_10_data1_out;
    reg [31:0]sprite_11_data0_out;
    reg [31:0]sprite_11_data1_out;
    reg [31:0]sprite_12_data0_out;
    reg [31:0]sprite_12_data1_out;
    reg [31:0]sprite_13_data0_out;
    reg [31:0]sprite_13_data1_out;
    reg [31:0]sprite_14_data0_out;
    reg [31:0]sprite_14_data1_out;
    reg [31:0]sprite_15_data0_out;
    reg [31:0]sprite_15_data1_out;

    reg [7:0]scale_reg = 0;
    reg [15:0]vscroll_reg = 0;
    reg [15:0]hscroll_reg = 0;
    reg [7:0]pixel_scale_reg = 0;
    reg [15:0]pixel_vscroll_reg = 0;
    reg [15:0]pixel_hscroll_reg = 0;
    reg [31:0]clock_div_reg = 0;
    reg [31:0]pit_cfg_reg = 0;
    reg [31:0]vga_frame_count = 0;
    reg in_vblank_prev = 1'b0;
    reg vga_vblank_irq = 1'b0;
    reg [7:0]sprite_scale_regs[0:15];

    integer scroll_lane;
    reg [26:0]scroll_word_base;
    reg [26:0]scroll_byte_addr;
    reg [7:0]scroll_byte_data;

    function [7:0] select_lane_byte;
        input [31:0] data;
        input [1:0] lane;
        begin
            case (lane)
                2'd0: select_lane_byte = data[7:0];
                2'd1: select_lane_byte = data[15:8];
                2'd2: select_lane_byte = data[23:16];
                default: select_lane_byte = data[31:24];
            endcase
        end
    endfunction

    // Expand RGB332 (tile entry color byte) into the internal 0x0BGR 12-bit format.
    function [11:0] expand_rgb332;
        input [7:0] color;
        reg [3:0] r4;
        reg [3:0] g4;
        reg [3:0] b4;
        begin
            r4 = {color[7:5], color[7]};
            g4 = {color[4:2], color[4]};
            b4 = {color[1:0], color[1:0]};
            expand_rgb332 = {b4, g4, r4};
        end
    endfunction

    // Sprite helper: test whether a screen pixel is inside the sprite bounds.
    // Scale register uses 2**n magnification.
    function sprite_visible;
        input [9:0] sx;
        input [9:0] sy;
        input [9:0] px;
        input [9:0] py;
        input [7:0] scale;
        reg [15:0] span;
        begin
            span = 16'd32 << scale[3:0];
            sprite_visible =
                ({6'b0, sx} <= {6'b0, px}) &&
                ({6'b0, px} < ({6'b0, sx} + span)) &&
                ({6'b0, sy} <= {6'b0, py}) &&
                ({6'b0, py} < ({6'b0, sy} + span));
        end
    endfunction

    // Sprite helper: convert screen pixel coordinates into a 32x32 sprite texel address.
    function [9:0] sprite_tex_addr;
        input [9:0] sx;
        input [9:0] sy;
        input [9:0] px;
        input [9:0] py;
        input [7:0] scale;
        reg [9:0] local_x;
        reg [9:0] local_y;
        begin
            local_x = (px - sx) >> scale[3:0];
            local_y = (py - sy) >> scale[3:0];
            sprite_tex_addr = {local_y[4:0], local_x[4:0]};
        end
    endfunction

    reg [9:0]sprite_0_x = 0;
    reg [9:0]sprite_0_y = 0;
    reg [9:0]sprite_1_x = 0;
    reg [9:0]sprite_1_y = 0;
    reg [9:0]sprite_2_x = 0;
    reg [9:0]sprite_2_y = 0;
    reg [9:0]sprite_3_x = 0;
    reg [9:0]sprite_3_y = 0;
    reg [9:0]sprite_4_x = 0;
    reg [9:0]sprite_4_y = 0;
    reg [9:0]sprite_5_x = 0;
    reg [9:0]sprite_5_y = 0;
    reg [9:0]sprite_6_x = 0;
    reg [9:0]sprite_6_y = 0;
    reg [9:0]sprite_7_x = 0;
    reg [9:0]sprite_7_y = 0;
    reg [9:0]sprite_8_x = 0;
    reg [9:0]sprite_8_y = 0;
    reg [9:0]sprite_9_x = 0;
    reg [9:0]sprite_9_y = 0;
    reg [9:0]sprite_10_x = 0;
    reg [9:0]sprite_10_y = 0;
    reg [9:0]sprite_11_x = 0;
    reg [9:0]sprite_11_y = 0;
    reg [9:0]sprite_12_x = 0;
    reg [9:0]sprite_12_y = 0;
    reg [9:0]sprite_13_x = 0;
    reg [9:0]sprite_13_y = 0;
    reg [9:0]sprite_14_x = 0;
    reg [9:0]sprite_14_y = 0;
    reg [9:0]sprite_15_x = 0;
    reg [9:0]sprite_15_y = 0;

    reg use_sprite_0 = 0;
    reg use_sprite_1 = 0;
    reg use_sprite_2 = 0;
    reg use_sprite_3 = 0;
    reg use_sprite_4 = 0;
    reg use_sprite_5 = 0;
    reg use_sprite_6 = 0;                 
    reg use_sprite_7 = 0;
    reg use_sprite_8 = 0;
    reg use_sprite_9 = 0;
    reg use_sprite_10 = 0;
    reg use_sprite_11 = 0;
    reg use_sprite_12 = 0;
    reg use_sprite_13 = 0;
    reg use_sprite_14 = 0;
    reg use_sprite_15 = 0;

    // SD DMA register mirrors and per-device launch state.
    reg [31:0]sd0_dma_mem_addr_reg = 32'd0;
    reg [31:0]sd0_dma_block_reg = 32'd0;
    reg [31:0]sd0_dma_len_reg = 32'd0;
    reg sd0_dma_ctrl_write_pulse = 1'b0;
    reg [31:0]sd0_dma_ctrl_write_data = 32'd0;
    reg sd0_dma_status_clear_pulse = 1'b0;
    reg [47:0]sd0_spi_cmd_buffer = 48'd0;
    reg [4095:0]sd0_spi_data_buffer = 4096'd0;
    reg sd0_spi_start_strobe = 1'b0;
    reg sd0_spi_launch_sent = 1'b0;
    reg sd0_irq_pending = 1'b0;
    reg sd0_dma_done_prev = 1'b0;
    reg [2:0]sd0_init_state = SD_INIT_STATE_IDLE;
    reg [7:0]sd0_init_acmd41_attempts = 8'd0;
    reg sd0_card_high_capacity = 1'b0;
    reg sd0_dma_sd_ready_pulse = 1'b0;
    reg sd0_dma_mem_ready_pulse = 1'b0;
    reg [31:0]sd0_dma_mem_data_in = 32'd0;

    reg [31:0]sd1_dma_mem_addr_reg = 32'd0;
    reg [31:0]sd1_dma_block_reg = 32'd0;
    reg [31:0]sd1_dma_len_reg = 32'd0;
    reg sd1_dma_ctrl_write_pulse = 1'b0;
    reg [31:0]sd1_dma_ctrl_write_data = 32'd0;
    reg sd1_dma_status_clear_pulse = 1'b0;
    reg [47:0]sd1_spi_cmd_buffer = 48'd0;
    reg [4095:0]sd1_spi_data_buffer = 4096'd0;
    reg sd1_spi_start_strobe = 1'b0;
    reg sd1_spi_launch_sent = 1'b0;
    reg sd1_irq_pending = 1'b0;
    reg sd1_dma_done_prev = 1'b0;
    reg [2:0]sd1_init_state = SD_INIT_STATE_IDLE;
    reg [7:0]sd1_init_acmd41_attempts = 8'd0;
    reg sd1_card_high_capacity = 1'b0;
    reg sd1_dma_sd_ready_pulse = 1'b0;
    reg sd1_dma_mem_ready_pulse = 1'b0;
    reg [31:0]sd1_dma_mem_data_in = 32'd0;

    wire [47:0]sd0_cmd_buffer_out;
    wire sd0_cmd_buffer_out_valid;
    wire [4095:0]sd0_data_buffer_out;
    wire sd0_data_buffer_out_valid;
    wire sd0_busy;
    wire sd0_interrupt;
    wire sd0_spi_cs_int;
    wire sd0_spi_clk_int;
    wire sd0_spi_mosi_int;

    wire [47:0]sd1_cmd_buffer_out;
    wire sd1_cmd_buffer_out_valid;
    wire [4095:0]sd1_data_buffer_out;
    wire sd1_data_buffer_out_valid;
    wire sd1_busy;
    wire sd1_interrupt;
    wire sd1_spi_cs_int;
    wire sd1_spi_clk_int;
    wire sd1_spi_mosi_int;

    wire [31:0]sd0_dma_ctrl;
    wire [31:0]sd0_dma_status;
    wire [31:0]sd0_dma_error_code;
    wire [31:0]sd0_dma_mem_request_addr;
    wire [31:0]sd0_dma_mem_request_data;
    wire sd0_dma_mem_request_read;
    wire sd0_dma_mem_request_write;
    wire [4095:0]sd0_dma_sd_data_block_out;
    wire sd0_dma_waiting_for_sd_ready;
    wire sd0_dma_init_waiting_for_sd_ready;
    wire [31:0]sd0_dma_current_sd_block_addr;
    wire sd0_dma_mem_req_active =
      (sd0_dma_mem_request_read || sd0_dma_mem_request_write) &&
      !sd0_dma_waiting_for_sd_ready &&
      !sd0_dma_mem_ready_pulse;
    // CMD17/CMD24 use block addressing for SDHC and byte addressing otherwise.
    wire [31:0] sd0_spi_cmd_arg =
      sd0_card_high_capacity ? sd0_dma_current_sd_block_addr :
      (sd0_dma_current_sd_block_addr << 9);

    wire [31:0]sd1_dma_ctrl;
    wire [31:0]sd1_dma_status;
    wire [31:0]sd1_dma_error_code;
    wire [31:0]sd1_dma_mem_request_addr;
    wire [31:0]sd1_dma_mem_request_data;
    wire sd1_dma_mem_request_read;
    wire sd1_dma_mem_request_write;
    wire [4095:0]sd1_dma_sd_data_block_out;
    wire sd1_dma_waiting_for_sd_ready;
    wire sd1_dma_init_waiting_for_sd_ready;
    wire [31:0]sd1_dma_current_sd_block_addr;
    wire sd1_dma_mem_req_active =
      (sd1_dma_mem_request_read || sd1_dma_mem_request_write) &&
      !sd1_dma_waiting_for_sd_ready &&
      !sd1_dma_mem_ready_pulse;
    wire [31:0] sd1_spi_cmd_arg =
      sd1_card_high_capacity ? sd1_dma_current_sd_block_addr :
      (sd1_dma_current_sd_block_addr << 9);

    // PS/2/UART MMIO side effects must happen exactly once per pipeline
    // advance, not once per base clock. D-cache stalls replay an older memory
    // slot; replaying side effects would duplicate MMIO.
    assign ps2_ren = pipe_clk_en &&
      (PS2_REG <= raddr1_buf) && (raddr1_buf < (PS2_REG + 27'd2)) && ren_buf;
    assign uart_tx_wen = pipe_clk_en &&
      (waddr_buf[26:2] == UART_TX_REG[26:2]) && wen_buf[waddr_buf[1:0]];
    assign uart_rx_ren = pipe_clk_en &&
      (raddr1_buf == UART_RX_REG) && ren_buf;

    reg [31:0]display_framebuffer_out;
    reg display_tile_entry_sel;
    reg [9:0]display_tile_pixel_x;
    reg [8:0]display_tile_pixel_y;
    reg [31:0]display_tilemap_out;
    reg [31:0]display_pixelbuffer_out;
    reg [9:0]display_bg_pixel_x;
    reg [9:0]display_screen_x;
    reg [9:0]display_screen_y;
    // RAM-window accesses are cache-backed and can stall pipeline advancement.
    reg icache_req_pending;
    reg [26:0]icache_req_addr;
    reg [31:0]icache_req_tag;
    wire [31:0]icache_data_out;
    wire icache_success;

    reg dcache_req_pending;
    reg dcache_req_is_write;
    reg [1:0]dcache_req_src;
    reg [3:0]dcache_req_we;
    reg [26:0]dcache_req_addr;
    reg [31:0]dcache_req_wdata;
    // SD->RAM DMA writes bypass dcache and go directly to backing RAM so
    // instruction fetch observes freshly loaded kernel bytes without waiting
    // for dcache dirty eviction (there is no I/D coherence protocol).
    reg dma_write_req_pending;
    reg [1:0]dma_write_req_src;
    reg [26:0]dma_write_req_addr;
    reg [31:0]dma_write_req_wdata;
    reg icache_inv_pulse;
    reg dcache_inv_pulse;
    reg [26:0] dma_inv_addr;
    wire [31:0]dcache_data_out;
    wire dcache_success;
    localparam [1:0] DCACHE_REQ_SRC_CPU = 2'd0;
    localparam [1:0] DCACHE_REQ_SRC_SD0 = 2'd1;
    localparam [1:0] DCACHE_REQ_SRC_SD1 = 2'd2;
    wire cpu_dcache_req_now = dcache_ram_write_access || dcache_ram_read_access;
    // CPU cache-side request issue must only occur when the pipeline memory slot
    // advances. This prevents replaying the same architectural load/store while
    // pipe_clk_en is low due to a cache stall.
    wire cpu_dcache_issue_now = pipe_clk_en && cpu_dcache_req_now;
    wire dcache_req_blocks_cpu = dcache_req_pending && (dcache_req_src != DCACHE_REQ_SRC_CPU);
    wire dma_write_req_blocks_cpu = dma_write_req_pending && cpu_dcache_req_now;
    wire icache_ram_req;
    wire icache_ram_we;
    wire [3:0]icache_ram_be;
    wire [26:0]icache_ram_addr;
    wire [31:0]icache_ram_wdata;
    wire [31:0]icache_ram_rdata;
    wire icache_ram_ready;
    wire icache_ram_busy;
    wire icache_ram_error_oob;
    wire dcache_ram_req;
    wire dcache_ram_we;
    wire [3:0]dcache_ram_be;
    wire [26:0]dcache_ram_addr;
    wire [31:0]dcache_ram_wdata;
    wire [31:0]dcache_ram_rdata;
    wire dcache_ram_ready;
    wire dcache_ram_busy;
    wire dcache_ram_error_oob;

`ifdef FPGA_ICACHE_PRELOAD
    // FPGA builds can request direct I-cache initialization from bios-derived
    // preload files. Simulation regressions leave this disabled by default.
    localparam ICACHE_PRELOAD_ENABLE = 1;
`else
    localparam ICACHE_PRELOAD_ENABLE = 0;
`endif
    wire shared_ram_req;
    wire shared_ram_we;
    wire [3:0]shared_ram_be;
    wire [26:0]shared_ram_addr;
    wire [31:0]shared_ram_wdata;
    wire [31:0]shared_ram_rdata;
    wire shared_ram_ready;
    wire shared_ram_busy;
    wire shared_ram_error_oob;

    wire icache_ram_access = (raddr0 < RAM_END);
    wire dcache_ram_read_access = ren && (raddr1 < RAM_END);
    wire dcache_ram_write_access = (|wen) && (waddr < RAM_END);
    // A fetch request is accepted only when the shared cache issue slot is
    // free and no higher-priority dcache request is competing this cycle.
    assign icache_issue_accepted =
      !icache_req_pending && !dcache_req_pending && !dma_write_req_pending && pipe_clk_en &&
      !cpu_dcache_issue_now && icache_ram_access && icache_req_valid;
    // I-cache miss/in-flight requests stall the pipeline globally.
    // Same-cycle issue arbitration is handled in cpu.v fetch issue-stop logic.
    assign icache_stall = icache_req_pending;
    assign dcache_stall =
      (dcache_req_pending && (dcache_req_src == DCACHE_REQ_SRC_CPU)) ||
      (dcache_req_blocks_cpu && cpu_dcache_req_now) ||
      dma_write_req_blocks_cpu;
    wire vga_in_hblank = (pixel_x_in >= 10'd640);
    wire vga_in_vblank = (pixel_y_in >= 10'd480);

    // Tile layer scroll/scale controls the tile framebuffer overlay.
    wire [9:0]tile_pixel_x = (pixel_x_in >> scale_reg) - hscroll_reg[9:0];
    wire [9:0]tile_scaled_pixel_y_wide = pixel_y_in >> scale_reg;
    wire [8:0]tile_pixel_y = tile_scaled_pixel_y_wide[8:0] - vscroll_reg[8:0];
    wire [6:0]tile_entry_x = tile_pixel_x[9:3];
    wire [5:0]tile_entry_y = tile_pixel_y[8:3];
    // Keep each term at 13 bits so Verilator does not infer implicit widening.
    wire [12:0]tile_entry_idx = {1'b0, tile_entry_y, 6'b0} + {3'b0, tile_entry_y, 4'b0} + {6'b0, tile_entry_x}; // y * 80 + x
    wire [11:0]display_tile_entry_word_idx = tile_entry_idx[12:1];
    wire tile_entry_sel = tile_entry_idx[0];

    // Pixel layer scroll/scale (2^(n+1)) controls the background framebuffer.
    wire [4:0]pixel_scale_shift = pixel_scale_reg[4:0] + 5'd1;
    wire [9:0]bg_pixel_x = (pixel_x_in >> pixel_scale_shift) - pixel_hscroll_reg[9:0];
    wire [9:0]bg_scaled_pixel_y_wide = pixel_y_in >> pixel_scale_shift;
    wire [8:0]bg_pixel_y = bg_scaled_pixel_y_wide[8:0] - pixel_vscroll_reg[8:0];
    // Keep each term at 16 bits so Verilator does not infer implicit widening.
    wire [15:0]display_bg_word_idx = ({bg_pixel_y, 7'b0} + {2'b0, bg_pixel_y, 5'b0}) + {7'b0, bg_pixel_x[9:1]}; // y * 160 + x / 2

    wire [15:0]display_tile_entry =
      display_tile_entry_sel ? display_framebuffer_out[31:16] : display_framebuffer_out[15:0];
    wire [7:0] display_tile = display_tile_entry[7:0];
    wire [7:0] display_tile_color = display_tile_entry[15:8];
    wire [15:0] tile_pixel_idx =
      {2'b0, display_tile, 6'b0} + {10'b0, display_tile_pixel_y[2:0], 3'b0} + {13'b0, display_tile_pixel_x[2:0]};
    wire display_tile_half_sel = tile_pixel_idx[0];
    wire [12:0] display_tile_word_idx = tile_pixel_idx[13:1];
    wire [8:0] sprite_word_idx_r = raddr1[10:2];
    wire [8:0] sprite_word_idx_w = waddr[10:2];
    wire [12:0] tile_word_idx_r = raddr1[14:2];
    wire [12:0] tile_word_idx_w = waddr[14:2];
    wire [11:0] tile_frame_word_idx_r = raddr1[13:2] - TILE_FRAMEBUFFER_START[13:2];
    wire [11:0] tile_frame_word_idx_w = waddr[13:2] - TILE_FRAMEBUFFER_START[13:2];
    // Subtraction produces 17 bits; slice explicitly to the in-range 16-bit window index.
    wire [17:0] pixel_frame_word_idx_r_wide = {1'b0, raddr1[18:2]} - {1'b0, PIXEL_FRAMEBUFFER_START[18:2]};
    wire [17:0] pixel_frame_word_idx_w_wide = {1'b0, waddr[18:2]} - {1'b0, PIXEL_FRAMEBUFFER_START[18:2]};
    wire [15:0] pixel_frame_word_idx_r = pixel_frame_word_idx_r_wide[15:0];
    wire [15:0] pixel_frame_word_idx_w = pixel_frame_word_idx_w_wide[15:0];

    reg [31:0]display_sprite_0_out;
    reg [31:0]display_sprite_1_out;
    reg [31:0]display_sprite_2_out;
    reg [31:0]display_sprite_3_out;
    reg [31:0]display_sprite_4_out;
    reg [31:0]display_sprite_5_out;
    reg [31:0]display_sprite_6_out;
    reg [31:0]display_sprite_7_out;
    reg [31:0]display_sprite_8_out;
    reg [31:0]display_sprite_9_out;
    reg [31:0]display_sprite_10_out;
    reg [31:0]display_sprite_11_out;
    reg [31:0]display_sprite_12_out;
    reg [31:0]display_sprite_13_out;
    reg [31:0]display_sprite_14_out;
    reg [31:0]display_sprite_15_out;
    
    wire [9:0]display_sprite_addr_0 = sprite_tex_addr(sprite_0_x, sprite_0_y, display_screen_x, display_screen_y, sprite_scale_regs[0]);
    wire [9:0]display_sprite_addr_1 = sprite_tex_addr(sprite_1_x, sprite_1_y, display_screen_x, display_screen_y, sprite_scale_regs[1]);
    wire [9:0]display_sprite_addr_2 = sprite_tex_addr(sprite_2_x, sprite_2_y, display_screen_x, display_screen_y, sprite_scale_regs[2]);
    wire [9:0]display_sprite_addr_3 = sprite_tex_addr(sprite_3_x, sprite_3_y, display_screen_x, display_screen_y, sprite_scale_regs[3]);
    wire [9:0]display_sprite_addr_4 = sprite_tex_addr(sprite_4_x, sprite_4_y, display_screen_x, display_screen_y, sprite_scale_regs[4]);
    wire [9:0]display_sprite_addr_5 = sprite_tex_addr(sprite_5_x, sprite_5_y, display_screen_x, display_screen_y, sprite_scale_regs[5]);
    wire [9:0]display_sprite_addr_6 = sprite_tex_addr(sprite_6_x, sprite_6_y, display_screen_x, display_screen_y, sprite_scale_regs[6]);
    wire [9:0]display_sprite_addr_7 = sprite_tex_addr(sprite_7_x, sprite_7_y, display_screen_x, display_screen_y, sprite_scale_regs[7]);
    wire [9:0]display_sprite_addr_8 = sprite_tex_addr(sprite_8_x, sprite_8_y, display_screen_x, display_screen_y, sprite_scale_regs[8]);
    wire [9:0]display_sprite_addr_9 = sprite_tex_addr(sprite_9_x, sprite_9_y, display_screen_x, display_screen_y, sprite_scale_regs[9]);
    wire [9:0]display_sprite_addr_10 = sprite_tex_addr(sprite_10_x, sprite_10_y, display_screen_x, display_screen_y, sprite_scale_regs[10]);
    wire [9:0]display_sprite_addr_11 = sprite_tex_addr(sprite_11_x, sprite_11_y, display_screen_x, display_screen_y, sprite_scale_regs[11]);
    wire [9:0]display_sprite_addr_12 = sprite_tex_addr(sprite_12_x, sprite_12_y, display_screen_x, display_screen_y, sprite_scale_regs[12]);
    wire [9:0]display_sprite_addr_13 = sprite_tex_addr(sprite_13_x, sprite_13_y, display_screen_x, display_screen_y, sprite_scale_regs[13]);
    wire [9:0]display_sprite_addr_14 = sprite_tex_addr(sprite_14_x, sprite_14_y, display_screen_x, display_screen_y, sprite_scale_regs[14]);
    wire [9:0]display_sprite_addr_15 = sprite_tex_addr(sprite_15_x, sprite_15_y, display_screen_x, display_screen_y, sprite_scale_regs[15]);
    wire not_transparent_0 = ((display_sprite_addr_0[0] ? display_sprite_0_out[31:28] : display_sprite_0_out[15:12]) == 4'h0);
    wire not_transparent_1 = ((display_sprite_addr_1[0] ? display_sprite_1_out[31:28] : display_sprite_1_out[15:12]) == 4'h0);
    wire not_transparent_2 = ((display_sprite_addr_2[0] ? display_sprite_2_out[31:28] : display_sprite_2_out[15:12]) == 4'h0);
    wire not_transparent_3 = ((display_sprite_addr_3[0] ? display_sprite_3_out[31:28] : display_sprite_3_out[15:12]) == 4'h0);
    wire not_transparent_4 = ((display_sprite_addr_4[0] ? display_sprite_4_out[31:28] : display_sprite_4_out[15:12]) == 4'h0);
    wire not_transparent_5 = ((display_sprite_addr_5[0] ? display_sprite_5_out[31:28] : display_sprite_5_out[15:12]) == 4'h0);
    wire not_transparent_6 = ((display_sprite_addr_6[0] ? display_sprite_6_out[31:28] : display_sprite_6_out[15:12]) == 4'h0);
    wire not_transparent_7 = ((display_sprite_addr_7[0] ? display_sprite_7_out[31:28] : display_sprite_7_out[15:12]) == 4'h0);
    wire not_transparent_8 = ((display_sprite_addr_8[0] ? display_sprite_8_out[31:28] : display_sprite_8_out[15:12]) == 4'h0);
    wire not_transparent_9 = ((display_sprite_addr_9[0] ? display_sprite_9_out[31:28] : display_sprite_9_out[15:12]) == 4'h0);
    wire not_transparent_10 = ((display_sprite_addr_10[0] ? display_sprite_10_out[31:28] : display_sprite_10_out[15:12]) == 4'h0);
    wire not_transparent_11 = ((display_sprite_addr_11[0] ? display_sprite_11_out[31:28] : display_sprite_11_out[15:12]) == 4'h0);
    wire not_transparent_12 = ((display_sprite_addr_12[0] ? display_sprite_12_out[31:28] : display_sprite_12_out[15:12]) == 4'h0);
    wire not_transparent_13 = ((display_sprite_addr_13[0] ? display_sprite_13_out[31:28] : display_sprite_13_out[15:12]) == 4'h0);
    wire not_transparent_14 = ((display_sprite_addr_14[0] ? display_sprite_14_out[31:28] : display_sprite_14_out[15:12]) == 4'h0);
    wire not_transparent_15 = ((display_sprite_addr_15[0] ? display_sprite_15_out[31:28] : display_sprite_15_out[15:12]) == 4'h0);
    
    reg use_sprite_0_out;
    reg use_sprite_1_out;
    reg use_sprite_2_out;
    reg use_sprite_3_out;
    reg use_sprite_4_out;
    reg use_sprite_5_out;
    reg use_sprite_6_out;
    reg use_sprite_7_out;
    reg use_sprite_8_out;
    reg use_sprite_9_out;
    reg use_sprite_10_out;
    reg use_sprite_11_out;
    reg use_sprite_12_out;
    reg use_sprite_13_out;
    reg use_sprite_14_out;
    reg use_sprite_15_out;
    
    wire sprite_0_onscreen = use_sprite_0_out & not_transparent_0;
    wire sprite_1_onscreen = use_sprite_1_out & not_transparent_1;
    wire sprite_2_onscreen = use_sprite_2_out & not_transparent_2;
    wire sprite_3_onscreen = use_sprite_3_out & not_transparent_3;
    wire sprite_4_onscreen = use_sprite_4_out & not_transparent_4;
    wire sprite_5_onscreen = use_sprite_5_out & not_transparent_5;
    wire sprite_6_onscreen = use_sprite_6_out & not_transparent_6;
    wire sprite_7_onscreen = use_sprite_7_out & not_transparent_7;
    wire sprite_8_onscreen = use_sprite_8_out & not_transparent_8;
    wire sprite_9_onscreen = use_sprite_9_out & not_transparent_9;
    wire sprite_10_onscreen = use_sprite_10_out & not_transparent_10;
    wire sprite_11_onscreen = use_sprite_11_out & not_transparent_11;
    wire sprite_12_onscreen = use_sprite_12_out & not_transparent_12;
    wire sprite_13_onscreen = use_sprite_13_out & not_transparent_13;
    wire sprite_14_onscreen = use_sprite_14_out & not_transparent_14;
    wire sprite_15_onscreen = use_sprite_15_out & not_transparent_15;

    wire [15:0]display_tile_pixel =
      display_tile_half_sel ? display_tilemap_out[31:16] : display_tilemap_out[15:0];
    wire [15:0]display_bg_pixel =
      display_bg_pixel_x[0] ? display_pixelbuffer_out[31:16] : display_pixelbuffer_out[15:0];
    wire tile_transparent = (display_tile_pixel[15:12] == 4'hF);
    wire tile_color_override = (display_tile_pixel[15:12] == 4'hC);
    wire [11:0]display_tile_rgb =
      tile_color_override ? expand_rgb332(display_tile_color) : display_tile_pixel[11:0];
    wire [11:0]display_layer_rgb = tile_transparent ? display_bg_pixel[11:0] : display_tile_rgb;

    wire any_sprite_onscreen =
      sprite_8_onscreen || sprite_9_onscreen || sprite_10_onscreen || sprite_11_onscreen ||
      sprite_12_onscreen || sprite_13_onscreen || sprite_14_onscreen || sprite_15_onscreen ||
      sprite_0_onscreen || sprite_1_onscreen || sprite_2_onscreen || sprite_3_onscreen ||
      sprite_4_onscreen || sprite_5_onscreen || sprite_6_onscreen || sprite_7_onscreen;
    wire [15:0]display_sprite_pixel =
      sprite_15_onscreen ? (display_sprite_addr_15[0] ? display_sprite_15_out[31:16] : display_sprite_15_out[15:0]) :
      sprite_14_onscreen ? (display_sprite_addr_14[0] ? display_sprite_14_out[31:16] : display_sprite_14_out[15:0]) :
      sprite_13_onscreen ? (display_sprite_addr_13[0] ? display_sprite_13_out[31:16] : display_sprite_13_out[15:0]) :
      sprite_12_onscreen ? (display_sprite_addr_12[0] ? display_sprite_12_out[31:16] : display_sprite_12_out[15:0]) :
      sprite_11_onscreen ? (display_sprite_addr_11[0] ? display_sprite_11_out[31:16] : display_sprite_11_out[15:0]) :
      sprite_10_onscreen ? (display_sprite_addr_10[0] ? display_sprite_10_out[31:16] : display_sprite_10_out[15:0]) :
      sprite_9_onscreen ? (display_sprite_addr_9[0] ? display_sprite_9_out[31:16] : display_sprite_9_out[15:0]) :
      sprite_8_onscreen ? (display_sprite_addr_8[0] ? display_sprite_8_out[31:16] : display_sprite_8_out[15:0]) :
      sprite_7_onscreen ? (display_sprite_addr_7[0] ? display_sprite_7_out[31:16] : display_sprite_7_out[15:0]) :
      sprite_6_onscreen ? (display_sprite_addr_6[0] ? display_sprite_6_out[31:16] : display_sprite_6_out[15:0]) :
      sprite_5_onscreen ? (display_sprite_addr_5[0] ? display_sprite_5_out[31:16] : display_sprite_5_out[15:0]) :
      sprite_4_onscreen ? (display_sprite_addr_4[0] ? display_sprite_4_out[31:16] : display_sprite_4_out[15:0]) :
      sprite_3_onscreen ? (display_sprite_addr_3[0] ? display_sprite_3_out[31:16] : display_sprite_3_out[15:0]) :
      sprite_2_onscreen ? (display_sprite_addr_2[0] ? display_sprite_2_out[31:16] : display_sprite_2_out[15:0]) :
      sprite_1_onscreen ? (display_sprite_addr_1[0] ? display_sprite_1_out[31:16] : display_sprite_1_out[15:0]) :
      sprite_0_onscreen ? (display_sprite_addr_0[0] ? display_sprite_0_out[31:16] : display_sprite_0_out[15:0]) :
      16'd0;
    assign pixel = any_sprite_onscreen ? display_sprite_pixel[11:0] : display_layer_rgb;

    wire [9:0]sprite_coord_low = wdata[9:0];
    wire [9:0]sprite_coord_high = wdata[25:16];

    function [31:0]pack_sprite_coord;
        input [9:0]coord;
        input [1:0]lane;
        reg [15:0]coord_ext;
        begin
            coord_ext = {6'b0, coord};
            case (lane)
                2'b00: pack_sprite_coord = {16'b0, coord_ext};
                2'b10: pack_sprite_coord = {coord_ext, 16'b0};
                default: pack_sprite_coord = 32'h0;
            endcase
        end
    endfunction

    // SD DMA readback helper for SD0/SD1 MMIO register windows.
    function [7:0]sd_dma_read_byte;
        input [26:0]addr;
        reg [26:0]base;
        reg [1:0]lane;
        begin
            base = {addr[26:2], 2'b00};
            lane = addr[1:0];
            case (base)
                SD0_DMA_MEM_ADDR_REG: sd_dma_read_byte = select_lane_byte(sd0_dma_mem_addr_reg, lane);
                SD0_DMA_SD_BLOCK_REG: sd_dma_read_byte = select_lane_byte(sd0_dma_block_reg, lane);
                SD0_DMA_LEN_REG: sd_dma_read_byte = select_lane_byte(sd0_dma_len_reg, lane);
                SD0_DMA_CTRL_REG: sd_dma_read_byte = select_lane_byte(sd0_dma_ctrl, lane);
                SD0_DMA_STATUS_REG: sd_dma_read_byte = select_lane_byte(sd0_dma_status, lane);
                SD0_DMA_ERR_REG: sd_dma_read_byte = select_lane_byte(sd0_dma_error_code, lane);
                SD1_DMA_MEM_ADDR_REG: sd_dma_read_byte = select_lane_byte(sd1_dma_mem_addr_reg, lane);
                SD1_DMA_SD_BLOCK_REG: sd_dma_read_byte = select_lane_byte(sd1_dma_block_reg, lane);
                SD1_DMA_LEN_REG: sd_dma_read_byte = select_lane_byte(sd1_dma_len_reg, lane);
                SD1_DMA_CTRL_REG: sd_dma_read_byte = select_lane_byte(sd1_dma_ctrl, lane);
                SD1_DMA_STATUS_REG: sd_dma_read_byte = select_lane_byte(sd1_dma_status, lane);
                SD1_DMA_ERR_REG: sd_dma_read_byte = select_lane_byte(sd1_dma_error_code, lane);
                default: sd_dma_read_byte = 8'h00;
            endcase
        end
    endfunction
    function [31:0]sd_dma_read_word;
        input [26:0]addr;
        reg [26:0]base;
        begin
            base = {addr[26:2], 2'b00};
            sd_dma_read_word = {sd_dma_read_byte(base + 27'd3), sd_dma_read_byte(base + 27'd2),
                                sd_dma_read_byte(base + 27'd1), sd_dma_read_byte(base)};
        end
    endfunction
    wire [31:0]data0_out = ram_data0_out;
    wire sd_window_selected = ren_buf && (SD0_DMA_MEM_ADDR_REG <= raddr1_buf) && (raddr1_buf <= SD_DMA_MMIO_END);
    wire [31:0]data1_out =  sd_window_selected ? sd_dma_read_word(raddr1_buf) :
      (TILE_FRAMEBUFFER_START <= raddr1_buf && raddr1_buf < TILE_FRAMEBUFFER_END) ? framebuffer_data1_out :
      (PIXEL_FRAMEBUFFER_START <= raddr1_buf && raddr1_buf < PIXEL_FRAMEBUFFER_END) ? pixelbuffer_data1_out :
      (SPRITE_0_START <= raddr1_buf && raddr1_buf < SPRITE_1_START) ? sprite_0_data1_out :
      (SPRITE_1_START <= raddr1_buf && raddr1_buf < SPRITE_2_START) ? sprite_1_data1_out :
      (SPRITE_2_START <= raddr1_buf && raddr1_buf < SPRITE_3_START) ? sprite_2_data1_out :
      (SPRITE_3_START <= raddr1_buf && raddr1_buf < SPRITE_4_START) ? sprite_3_data1_out :
      (SPRITE_4_START <= raddr1_buf && raddr1_buf < SPRITE_5_START) ? sprite_4_data1_out :
      (SPRITE_5_START <= raddr1_buf && raddr1_buf < SPRITE_6_START) ? sprite_5_data1_out :
      (SPRITE_6_START <= raddr1_buf && raddr1_buf < SPRITE_7_START) ? sprite_6_data1_out :
      (SPRITE_7_START <= raddr1_buf && raddr1_buf < SPRITE_8_START) ? sprite_7_data1_out :
      (SPRITE_8_START <= raddr1_buf && raddr1_buf < SPRITE_9_START) ? sprite_8_data1_out :
      (SPRITE_9_START <= raddr1_buf && raddr1_buf < SPRITE_10_START) ? sprite_9_data1_out :
      (SPRITE_10_START <= raddr1_buf && raddr1_buf < SPRITE_11_START) ? sprite_10_data1_out :
      (SPRITE_11_START <= raddr1_buf && raddr1_buf < SPRITE_12_START) ? sprite_11_data1_out :
      (SPRITE_12_START <= raddr1_buf && raddr1_buf < SPRITE_13_START) ? sprite_12_data1_out :
      (SPRITE_13_START <= raddr1_buf && raddr1_buf < SPRITE_14_START) ? sprite_13_data1_out :
      (SPRITE_14_START <= raddr1_buf && raddr1_buf < SPRITE_15_START) ? sprite_14_data1_out :
      (SPRITE_15_START <= raddr1_buf && raddr1_buf < SPRITE_DATA_END) ? sprite_15_data1_out :
      (TILEMAP_START <= raddr1_buf && raddr1_buf < TILEMAP_END) ? tilemap_data1_out :
                            raddr1_buf == SPRITE_0_X ? pack_sprite_coord(sprite_0_x, raddr1_buf[1:0]) :
                            raddr1_buf == SPRITE_0_Y ? pack_sprite_coord(sprite_0_y, raddr1_buf[1:0]) :
                            raddr1_buf == SPRITE_1_X ? pack_sprite_coord(sprite_1_x, raddr1_buf[1:0]) :
                            raddr1_buf == SPRITE_1_Y ? pack_sprite_coord(sprite_1_y, raddr1_buf[1:0]) :
                            raddr1_buf == SPRITE_2_X ? pack_sprite_coord(sprite_2_x, raddr1_buf[1:0]) :
                            raddr1_buf == SPRITE_2_Y ? pack_sprite_coord(sprite_2_y, raddr1_buf[1:0]) :
                            raddr1_buf == SPRITE_3_X ? pack_sprite_coord(sprite_3_x, raddr1_buf[1:0]) :
                            raddr1_buf == SPRITE_3_Y ? pack_sprite_coord(sprite_3_y, raddr1_buf[1:0]) :
                            raddr1_buf == SPRITE_4_X ? pack_sprite_coord(sprite_4_x, raddr1_buf[1:0]) :
                            raddr1_buf == SPRITE_4_Y ? pack_sprite_coord(sprite_4_y, raddr1_buf[1:0]) :
                            raddr1_buf == SPRITE_5_X ? pack_sprite_coord(sprite_5_x, raddr1_buf[1:0]) :
                            raddr1_buf == SPRITE_5_Y ? pack_sprite_coord(sprite_5_y, raddr1_buf[1:0]) :
                            raddr1_buf == SPRITE_6_X ? pack_sprite_coord(sprite_6_x, raddr1_buf[1:0]) :
                            raddr1_buf == SPRITE_6_Y ? pack_sprite_coord(sprite_6_y, raddr1_buf[1:0]) :
                            raddr1_buf == SPRITE_7_X ? pack_sprite_coord(sprite_7_x, raddr1_buf[1:0]) :
                            raddr1_buf == SPRITE_7_Y ? pack_sprite_coord(sprite_7_y, raddr1_buf[1:0]) :
                            raddr1_buf == SPRITE_8_X ? pack_sprite_coord(sprite_8_x, raddr1_buf[1:0]) :
                            raddr1_buf == SPRITE_8_Y ? pack_sprite_coord(sprite_8_y, raddr1_buf[1:0]) :
                            raddr1_buf == SPRITE_9_X ? pack_sprite_coord(sprite_9_x, raddr1_buf[1:0]) :
                            raddr1_buf == SPRITE_9_Y ? pack_sprite_coord(sprite_9_y, raddr1_buf[1:0]) :
                            raddr1_buf == SPRITE_10_X ? pack_sprite_coord(sprite_10_x, raddr1_buf[1:0]) :
                            raddr1_buf == SPRITE_10_Y ? pack_sprite_coord(sprite_10_y, raddr1_buf[1:0]) :
                            raddr1_buf == SPRITE_11_X ? pack_sprite_coord(sprite_11_x, raddr1_buf[1:0]) :
                            raddr1_buf == SPRITE_11_Y ? pack_sprite_coord(sprite_11_y, raddr1_buf[1:0]) :
                            raddr1_buf == SPRITE_12_X ? pack_sprite_coord(sprite_12_x, raddr1_buf[1:0]) :
                            raddr1_buf == SPRITE_12_Y ? pack_sprite_coord(sprite_12_y, raddr1_buf[1:0]) :
                            raddr1_buf == SPRITE_13_X ? pack_sprite_coord(sprite_13_x, raddr1_buf[1:0]) :
                            raddr1_buf == SPRITE_13_Y ? pack_sprite_coord(sprite_13_y, raddr1_buf[1:0]) :
                            raddr1_buf == SPRITE_14_X ? pack_sprite_coord(sprite_14_x, raddr1_buf[1:0]) :
                            raddr1_buf == SPRITE_14_Y ? pack_sprite_coord(sprite_14_y, raddr1_buf[1:0]) :
                            raddr1_buf == SPRITE_15_X ? pack_sprite_coord(sprite_15_x, raddr1_buf[1:0]) :
                            raddr1_buf == SPRITE_15_Y ? pack_sprite_coord(sprite_15_y, raddr1_buf[1:0]) :
                            (SPRITE_SCALE_BASE <= raddr1_buf && raddr1_buf < SPRITE_SCALE_END) ?
                              {24'b0, sprite_scale_regs[raddr1_buf[3:0]]} :
                            raddr1_buf == SCALE_REG ? {24'b0, scale_reg} :
                            raddr1_buf == HSCROLL_REG ? {16'b0, hscroll_reg} :
                            raddr1_buf == VSCROLL_REG ? {vscroll_reg, 16'b0} :
                            raddr1_buf == PIXEL_SCALE_REG ? {24'b0, pixel_scale_reg} :
                            raddr1_buf == PIXEL_HSCROLL_REG ? {16'b0, pixel_hscroll_reg} :
                            raddr1_buf == PIXEL_VSCROLL_REG ? {pixel_vscroll_reg, 16'b0} :
                            raddr1_buf == VGA_STATUS_REG ? {30'd0, vga_in_hblank, vga_in_vblank} :
                            (VGA_FRAME_REG <= raddr1_buf && raddr1_buf < (VGA_FRAME_REG + 27'd4)) ? vga_frame_count :
                            (CLOCK_DIV_REG <= raddr1_buf && raddr1_buf < (CLOCK_DIV_REG + 27'd4)) ? clock_div_reg :
                            (PIT_START <= raddr1_buf && raddr1_buf < (PIT_START + 27'd4)) ? pit_cfg_reg :
                            (PS2_REG <= raddr1_buf && raddr1_buf < (PS2_REG + 27'd2)) ? {16'b0, ps2_data_in} :
                            raddr1_buf == UART_RX_REG ? {uart_rx_data, uart_rx_data, uart_rx_data, uart_rx_data} :
                            raddr1_buf < RAM_END ? ram_data1_out :
                            32'h0;

    wire pit_interrupt;
    // PIT config writes are accepted only on enabled core cycles; timer ticks
    // continue on the base clock regardless of CPU clock divider.
    wire pit_we = wen[0] && wen[1] && wen[2] && wen[3] &&
      (waddr == PIT_START) && clk_en;

    pit pit(
        clk,
        pit_we, wdata, pit_interrupt
    );

    // RAM path:
    // - Physical addresses in [0, RAM_END) go through cache->ram model.
    // - MMIO/display/sprite windows stay uncached and use direct logic below.
    cache #(
        .PRELOAD_ENABLE(ICACHE_PRELOAD_ENABLE)
    ) icache(
        .clk(clk),
        .addr(icache_req_addr),
        .data(32'd0),
        .re(icache_req_pending),
        .we(4'd0),
        .inv_valid(icache_inv_pulse),
        .inv_addr(dma_inv_addr),
        .data_out(icache_data_out),
        .success(icache_success),
        .ram_req(icache_ram_req),
        .ram_we(icache_ram_we),
        .ram_be(icache_ram_be),
        .ram_addr(icache_ram_addr),
        .ram_wdata(icache_ram_wdata),
        .ram_rdata(icache_ram_rdata),
        .ram_ready(icache_ram_ready),
        .ram_busy(icache_ram_busy),
        .ram_error_oob(icache_ram_error_oob)
    );

    cache dcache(
        .clk(clk),
        .addr(dcache_req_addr),
        .data(dcache_req_wdata),
        .re(dcache_req_pending && !dcache_req_is_write),
        .we((dcache_req_pending && dcache_req_is_write) ? dcache_req_we : 4'd0),
        .inv_valid(dcache_inv_pulse),
        .inv_addr(dma_inv_addr),
        .data_out(dcache_data_out),
        .success(dcache_success),
        .ram_req(dcache_ram_req),
        .ram_we(dcache_ram_we),
        .ram_be(dcache_ram_be),
        .ram_addr(dcache_ram_addr),
        .ram_wdata(dcache_ram_wdata),
        .ram_rdata(dcache_ram_rdata),
        .ram_ready(dcache_ram_ready),
        .ram_busy(dcache_ram_busy),
        .ram_error_oob(dcache_ram_error_oob)
    );

    // Backing RAM model:
    // - Single-port SRAM-style interface (matches final board direction).
    // - mem.v arbitration guarantees only one cache request is active, so a
    //   simple active-port mux is sufficient.
    // - SD->RAM DMA writes are direct-to-RAM requests to avoid I/D incoherence
    //   when boot code jumps into freshly DMA-loaded kernel text.
    assign shared_ram_req = icache_req_pending ? icache_ram_req :
      dcache_req_pending ? dcache_ram_req :
      dma_write_req_pending ? 1'b1 : 1'b0;
    assign shared_ram_we = icache_req_pending ? icache_ram_we :
      dcache_req_pending ? dcache_ram_we :
      dma_write_req_pending ? 1'b1 : 1'b0;
    assign shared_ram_be = icache_req_pending ? icache_ram_be :
      dcache_req_pending ? dcache_ram_be :
      dma_write_req_pending ? 4'hF : 4'd0;
    assign shared_ram_addr = icache_req_pending ? icache_ram_addr :
      dcache_req_pending ? dcache_ram_addr :
      dma_write_req_pending ? dma_write_req_addr : 27'd0;
    assign shared_ram_wdata = icache_req_pending ? icache_ram_wdata :
      dcache_req_pending ? dcache_ram_wdata :
      dma_write_req_pending ? dma_write_req_wdata : 32'd0;

    assign icache_ram_rdata = shared_ram_rdata;
    assign dcache_ram_rdata = shared_ram_rdata;
    assign icache_ram_ready = icache_req_pending ? shared_ram_ready : 1'b0;
    assign dcache_ram_ready = dcache_req_pending ? shared_ram_ready : 1'b0;
    assign icache_ram_busy = icache_req_pending ? shared_ram_busy : 1'b0;
    assign dcache_ram_busy = dcache_req_pending ? shared_ram_busy : 1'b0;
    assign icache_ram_error_oob = icache_req_pending ? shared_ram_error_oob : 1'b0;
    assign dcache_ram_error_oob = dcache_req_pending ? shared_ram_error_oob : 1'b0;

`ifdef FPGA_USE_DDR_SRAM_ADAPTER
    // FPGA external-memory path:
    // - Expects a board-integrated DDR->SRAM bridge module named
    //   `ddr_sram_adapter` to be available in the Vivado project.
    // - The adapter contract must match this single-port SRAM-like handshake:
    //   req/we/be/addr/wdata -> ready/rdata with busy backpressure.
    // - `error_oob` is not meaningful for external DDR; tie low unless the
    //   adapter explicitly reports address-range violations.
    ddr_sram_adapter backing_ram(
        .clk(clk),
        .rst(1'b0),
        .req(shared_ram_req),
        .we(shared_ram_we),
        .be(shared_ram_be),
        .addr(shared_ram_addr),
        .wdata(shared_ram_wdata),
        .rdata(shared_ram_rdata),
        .ready(shared_ram_ready),
        .busy(shared_ram_busy),
        .error_oob(shared_ram_error_oob),
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
    );
`else
    ram #(
        .ADDR_WIDTH(27),
        .WORD_ADDR_BITS(RAM_WORD_ADDR_BITS),
        .ACCESS_LATENCY(RAM_ACCESS_LATENCY)
    ) backing_ram(
        .clk(clk),
        .rst(1'b0),
        .req(shared_ram_req),
        .we(shared_ram_we),
        .be(shared_ram_be),
        .addr(shared_ram_addr),
        .wdata(shared_ram_wdata),
        .rdata(shared_ram_rdata),
        .ready(shared_ram_ready),
        .busy(shared_ram_busy),
        .error_oob(shared_ram_error_oob)
    );
`endif

    // SD card 0 DMA engine control/state.
    // Memory beats are acknowledged from the shared cache front-end path.
    sd_dma_controller sd_dma0(
        .clk(clk),
        .mem_start_addr(sd0_dma_mem_addr_reg),
        .sd_block_start_addr(sd0_dma_block_reg),
        .num_blocks(sd0_dma_len_reg),
        .ctrl_data(sd0_dma_ctrl_write_data),
        .ctrl_write(sd0_dma_ctrl_write_pulse),
        .status_clear(sd0_dma_status_clear_pulse),
        .mem_ready_set(sd0_dma_mem_ready_pulse),
        .sd_ready_set(sd0_dma_sd_ready_pulse),
        .mem_data_in(sd0_dma_mem_data_in),
        .sd_data_block_in(sd0_data_buffer_out),
        .sd_data_block_in_valid(sd0_data_buffer_out_valid && (sd0_dma_ctrl[1] == 1'b0)),
        .ctrl(sd0_dma_ctrl),
        .status(sd0_dma_status),
        .error_code(sd0_dma_error_code),
        .mem_request_addr_out(sd0_dma_mem_request_addr),
        .mem_request_data(sd0_dma_mem_request_data),
        .mem_request_read(sd0_dma_mem_request_read),
        .mem_request_write(sd0_dma_mem_request_write),
        .sd_data_block_out(sd0_dma_sd_data_block_out),
        .waiting_for_sd_ready_out(sd0_dma_waiting_for_sd_ready),
        .init_waiting_for_sd_ready(sd0_dma_init_waiting_for_sd_ready),
        .current_sd_block_addr(sd0_dma_current_sd_block_addr)
    );

    sd_spi_controller sd0_ctrl(
        .clk(clk),
        .clk_en(clk_en),
        .start(sd0_spi_start_strobe),
        .cmd_buffer_in(sd0_spi_cmd_buffer),
        .data_buffer_in(sd0_spi_data_buffer),
        .cmd_buffer_out(sd0_cmd_buffer_out),
        .cmd_buffer_out_valid(sd0_cmd_buffer_out_valid),
        .data_buffer_out(sd0_data_buffer_out),
        .data_buffer_out_valid(sd0_data_buffer_out_valid),
        .busy(sd0_busy),
        .interrupt(sd0_interrupt),
        .spi_cs(sd0_spi_cs_int),
        .spi_clk(sd0_spi_clk_int),
        .spi_mosi(sd0_spi_mosi_int),
        .spi_miso(sd_spi_miso)
    );

    // SD card 1 engine mirrors SD card 0 behavior on its own SPI bus.
    sd_dma_controller sd_dma1(
        .clk(clk),
        .mem_start_addr(sd1_dma_mem_addr_reg),
        .sd_block_start_addr(sd1_dma_block_reg),
        .num_blocks(sd1_dma_len_reg),
        .ctrl_data(sd1_dma_ctrl_write_data),
        .ctrl_write(sd1_dma_ctrl_write_pulse),
        .status_clear(sd1_dma_status_clear_pulse),
        .mem_ready_set(sd1_dma_mem_ready_pulse),
        .sd_ready_set(sd1_dma_sd_ready_pulse),
        .mem_data_in(sd1_dma_mem_data_in),
        .sd_data_block_in(sd1_data_buffer_out),
        .sd_data_block_in_valid(sd1_data_buffer_out_valid && (sd1_dma_ctrl[1] == 1'b0)),
        .ctrl(sd1_dma_ctrl),
        .status(sd1_dma_status),
        .error_code(sd1_dma_error_code),
        .mem_request_addr_out(sd1_dma_mem_request_addr),
        .mem_request_data(sd1_dma_mem_request_data),
        .mem_request_read(sd1_dma_mem_request_read),
        .mem_request_write(sd1_dma_mem_request_write),
        .sd_data_block_out(sd1_dma_sd_data_block_out),
        .waiting_for_sd_ready_out(sd1_dma_waiting_for_sd_ready),
        .init_waiting_for_sd_ready(sd1_dma_init_waiting_for_sd_ready),
        .current_sd_block_addr(sd1_dma_current_sd_block_addr)
    );

    sd_spi_controller sd1_ctrl(
        .clk(clk),
        .clk_en(clk_en),
        .start(sd1_spi_start_strobe),
        .cmd_buffer_in(sd1_spi_cmd_buffer),
        .data_buffer_in(sd1_spi_data_buffer),
        .cmd_buffer_out(sd1_cmd_buffer_out),
        .cmd_buffer_out_valid(sd1_cmd_buffer_out_valid),
        .data_buffer_out(sd1_data_buffer_out),
        .data_buffer_out_valid(sd1_data_buffer_out_valid),
        .busy(sd1_busy),
        .interrupt(sd1_interrupt),
        .spi_cs(sd1_spi_cs_int),
        .spi_clk(sd1_spi_clk_int),
        .spi_mosi(sd1_spi_mosi_int),
        .spi_miso(sd1_spi_miso)
    );
    assign sd_spi_cs = sd0_spi_cs_int;
    assign sd_spi_clk = sd0_spi_clk_int;
    assign sd_spi_mosi = sd0_spi_mosi_int;
    assign sd1_spi_cs = sd1_spi_cs_int;
    assign sd1_spi_clk = sd1_spi_clk_int;
    assign sd1_spi_mosi = sd1_spi_mosi_int;
    assign clock_divider = clock_div_reg;
    // interrupt bits: [6]=SD1, [4]=VGA vblank, [3]=SD0, [0]=PIT
    assign interrupts = {9'd0, sd1_irq_pending, 1'b0, vga_vblank_irq, sd0_irq_pending, 2'd0, pit_interrupt};

    always @(posedge clk) begin
      // Cache request tracking is intentionally outside clk_en gating so the
      // cache->RAM miss path can complete while the CPU pipeline is paused.
      // DMA mem_ready_set pulses are one-cycle acknowledgements consumed by
      // sd_dma_controller and must be cleared every cycle by default.
      sd0_dma_mem_ready_pulse <= 1'b0;
      sd1_dma_mem_ready_pulse <= 1'b0;
      icache_inv_pulse <= 1'b0;
      dcache_inv_pulse <= 1'b0;

      // Direct SD->RAM DMA write completion acks.
      if (dma_write_req_pending && !icache_req_pending && !dcache_req_pending && shared_ram_ready) begin
        dma_write_req_pending <= 1'b0;
        if (dma_write_req_src == DCACHE_REQ_SRC_SD0) begin
          sd0_dma_mem_ready_pulse <= 1'b1;
        end else if (dma_write_req_src == DCACHE_REQ_SRC_SD1) begin
          sd1_dma_mem_ready_pulse <= 1'b1;
        end
      end

      if (icache_req_pending && icache_success) begin
        icache_req_pending <= 1'b0;
        ram_data0_out <= icache_data_out;
        ram_data0_tag_out <= icache_req_tag;
      end

      if (dcache_req_pending && dcache_success) begin
        dcache_req_pending <= 1'b0;
        if (dcache_req_src == DCACHE_REQ_SRC_CPU) begin
          if (!dcache_req_is_write) begin
            ram_data1_out <= dcache_data_out;
          end
        end else if (dcache_req_src == DCACHE_REQ_SRC_SD0) begin
          if (!dcache_req_is_write) begin
            sd0_dma_mem_data_in <= dcache_data_out;
          end
          sd0_dma_mem_ready_pulse <= 1'b1;
        end else if (dcache_req_src == DCACHE_REQ_SRC_SD1) begin
          if (!dcache_req_is_write) begin
            sd1_dma_mem_data_in <= dcache_data_out;
          end
          sd1_dma_mem_ready_pulse <= 1'b1;
        end
      end

      // Issue one new cache-backed request at a time.
      // Arbitration policy: CPU D-cache > CPU I-cache > SD0 DMA > SD1 DMA.
      if (!icache_req_pending && !dcache_req_pending && !dma_write_req_pending && pipe_clk_en) begin
        if (cpu_dcache_issue_now) begin
          dcache_req_pending <= 1'b1;
          dcache_req_is_write <= dcache_ram_write_access;
          dcache_req_we <= dcache_ram_write_access ? wen : 4'd0;
          dcache_req_addr <= dcache_ram_write_access ? waddr : raddr1;
          dcache_req_wdata <= wdata;
          dcache_req_src <= DCACHE_REQ_SRC_CPU;
        end else if (icache_ram_access && icache_req_valid) begin
          icache_req_pending <= 1'b1;
          icache_req_addr <= raddr0;
          icache_req_tag <= rtag0;
        end else if (sd0_dma_mem_req_active) begin
          if (sd0_dma_mem_request_write) begin
            dma_write_req_pending <= 1'b1;
            dma_write_req_src <= DCACHE_REQ_SRC_SD0;
            dma_write_req_addr <= sd0_dma_mem_request_addr[26:0];
            dma_write_req_wdata <= sd0_dma_mem_request_data;
            dma_inv_addr <= sd0_dma_mem_request_addr[26:0];
            icache_inv_pulse <= 1'b1;
            dcache_inv_pulse <= 1'b1;
          end else begin
            dcache_req_pending <= 1'b1;
            dcache_req_is_write <= 1'b0;
            dcache_req_we <= 4'd0;
            dcache_req_addr <= sd0_dma_mem_request_addr[26:0];
            dcache_req_wdata <= 32'd0;
            dcache_req_src <= DCACHE_REQ_SRC_SD0;
          end
        end else if (sd1_dma_mem_req_active) begin
          if (sd1_dma_mem_request_write) begin
            dma_write_req_pending <= 1'b1;
            dma_write_req_src <= DCACHE_REQ_SRC_SD1;
            dma_write_req_addr <= sd1_dma_mem_request_addr[26:0];
            dma_write_req_wdata <= sd1_dma_mem_request_data;
            dma_inv_addr <= sd1_dma_mem_request_addr[26:0];
            icache_inv_pulse <= 1'b1;
            dcache_inv_pulse <= 1'b1;
          end else begin
            dcache_req_pending <= 1'b1;
            dcache_req_is_write <= 1'b0;
            dcache_req_we <= 4'd0;
            dcache_req_addr <= sd1_dma_mem_request_addr[26:0];
            dcache_req_wdata <= 32'd0;
            dcache_req_src <= DCACHE_REQ_SRC_SD1;
          end
        end
      end
    end

    always @(posedge clk) begin
      // VGA composition pipeline:
      // - Read tile entry and tile pixel from the tile layer.
      // - Read pixel-layer background.
      // - Sprite fetch happens in parallel and overlays in combinational logic.
      display_framebuffer_out <= frame_buffer[display_tile_entry_word_idx];
      display_tile_entry_sel <= tile_entry_sel;
      display_tile_pixel_x <= tile_pixel_x;
      display_tile_pixel_y <= tile_pixel_y;
      display_tilemap_out <= tile_map[display_tile_word_idx];
`ifdef FPGA_DISABLE_PIXEL_FB
      display_pixelbuffer_out <= 32'd0;
`else
      display_pixelbuffer_out <= pixel_buffer[display_bg_word_idx];
`endif
      display_bg_pixel_x <= bg_pixel_x;
      display_screen_x <= pixel_x_in;
      display_screen_y <= pixel_y_in;

      display_sprite_0_out <= sprite_0_data[display_sprite_addr_0[9:1]];
      display_sprite_1_out <= sprite_1_data[display_sprite_addr_1[9:1]];
      display_sprite_2_out <= sprite_2_data[display_sprite_addr_2[9:1]];
      display_sprite_3_out <= sprite_3_data[display_sprite_addr_3[9:1]];
      display_sprite_4_out <= sprite_4_data[display_sprite_addr_4[9:1]];
      display_sprite_5_out <= sprite_5_data[display_sprite_addr_5[9:1]];
      display_sprite_6_out <= sprite_6_data[display_sprite_addr_6[9:1]];
      display_sprite_7_out <= sprite_7_data[display_sprite_addr_7[9:1]];
      display_sprite_8_out <= sprite_8_data[display_sprite_addr_8[9:1]];
      display_sprite_9_out <= sprite_9_data[display_sprite_addr_9[9:1]];
      display_sprite_10_out <= sprite_10_data[display_sprite_addr_10[9:1]];
      display_sprite_11_out <= sprite_11_data[display_sprite_addr_11[9:1]];
      display_sprite_12_out <= sprite_12_data[display_sprite_addr_12[9:1]];
      display_sprite_13_out <= sprite_13_data[display_sprite_addr_13[9:1]];
      display_sprite_14_out <= sprite_14_data[display_sprite_addr_14[9:1]];
      display_sprite_15_out <= sprite_15_data[display_sprite_addr_15[9:1]];

      use_sprite_0 <= sprite_visible(sprite_0_x, sprite_0_y, pixel_x_in, pixel_y_in, sprite_scale_regs[0]);
      use_sprite_1 <= sprite_visible(sprite_1_x, sprite_1_y, pixel_x_in, pixel_y_in, sprite_scale_regs[1]);
      use_sprite_2 <= sprite_visible(sprite_2_x, sprite_2_y, pixel_x_in, pixel_y_in, sprite_scale_regs[2]);
      use_sprite_3 <= sprite_visible(sprite_3_x, sprite_3_y, pixel_x_in, pixel_y_in, sprite_scale_regs[3]);
      use_sprite_4 <= sprite_visible(sprite_4_x, sprite_4_y, pixel_x_in, pixel_y_in, sprite_scale_regs[4]);
      use_sprite_5 <= sprite_visible(sprite_5_x, sprite_5_y, pixel_x_in, pixel_y_in, sprite_scale_regs[5]);
      use_sprite_6 <= sprite_visible(sprite_6_x, sprite_6_y, pixel_x_in, pixel_y_in, sprite_scale_regs[6]);
      use_sprite_7 <= sprite_visible(sprite_7_x, sprite_7_y, pixel_x_in, pixel_y_in, sprite_scale_regs[7]);
      use_sprite_8 <= sprite_visible(sprite_8_x, sprite_8_y, pixel_x_in, pixel_y_in, sprite_scale_regs[8]);
      use_sprite_9 <= sprite_visible(sprite_9_x, sprite_9_y, pixel_x_in, pixel_y_in, sprite_scale_regs[9]);
      use_sprite_10 <= sprite_visible(sprite_10_x, sprite_10_y, pixel_x_in, pixel_y_in, sprite_scale_regs[10]);
      use_sprite_11 <= sprite_visible(sprite_11_x, sprite_11_y, pixel_x_in, pixel_y_in, sprite_scale_regs[11]);
      use_sprite_12 <= sprite_visible(sprite_12_x, sprite_12_y, pixel_x_in, pixel_y_in, sprite_scale_regs[12]);
      use_sprite_13 <= sprite_visible(sprite_13_x, sprite_13_y, pixel_x_in, pixel_y_in, sprite_scale_regs[13]);
      use_sprite_14 <= sprite_visible(sprite_14_x, sprite_14_y, pixel_x_in, pixel_y_in, sprite_scale_regs[14]);
      use_sprite_15 <= sprite_visible(sprite_15_x, sprite_15_y, pixel_x_in, pixel_y_in, sprite_scale_regs[15]);
                     
      use_sprite_0_out <= use_sprite_0;
      use_sprite_1_out <= use_sprite_1;
      use_sprite_2_out <= use_sprite_2;
      use_sprite_3_out <= use_sprite_3;
      use_sprite_4_out <= use_sprite_4;
      use_sprite_5_out <= use_sprite_5;
      use_sprite_6_out <= use_sprite_6;
      use_sprite_7_out <= use_sprite_7;
      use_sprite_8_out <= use_sprite_8;
      use_sprite_9_out <= use_sprite_9;
      use_sprite_10_out <= use_sprite_10;
      use_sprite_11_out <= use_sprite_11;
      use_sprite_12_out <= use_sprite_12;
      use_sprite_13_out <= use_sprite_13;
      use_sprite_14_out <= use_sprite_14;
      use_sprite_15_out <= use_sprite_15;

      // VGA status/frame bookkeeping for MMIO.
      // - Status bits are live from current scan position.
      // - Frame counter increments once per vblank entry.
      // - Interrupt pulses on the same vblank-entry edge.
      vga_vblank_irq <= 1'b0;
      if (vga_in_vblank && !in_vblank_prev) begin
        vga_vblank_irq <= 1'b1;
        vga_frame_count <= vga_frame_count + 32'd1;
      end
      in_vblank_prev <= vga_in_vblank;

      if (clk_en) begin
        raddr0_buf <= raddr0;
        raddr1_buf <= raddr1;
        waddr_buf <= waddr;

        wen_buf <= wen;
        ren_buf <= ren;

`ifdef FPGA_USE_DDR_SRAM_ADAPTER
        // FPGA DDR build: avoid a second CPU read port on large display-backed
        // memories. This keeps these arrays in simple BRAM topologies and
        // avoids LUTRAM blow-up / BRAM cascade DRC failures during place.
        //
        // Architectural contract in this mode:
        // - Display MMIO regions remain writable by CPU and readable by VGA.
        // - CPU readback of sprite/tile/frame/pixel backing arrays returns 0.
        sprite_0_data1_out <= 32'd0;
        sprite_1_data1_out <= 32'd0;
        sprite_2_data1_out <= 32'd0;
        sprite_3_data1_out <= 32'd0;
        sprite_4_data1_out <= 32'd0;
        sprite_5_data1_out <= 32'd0;
        sprite_6_data1_out <= 32'd0;
        sprite_7_data1_out <= 32'd0;
        sprite_8_data1_out <= 32'd0;
        sprite_9_data1_out <= 32'd0;
        sprite_10_data1_out <= 32'd0;
        sprite_11_data1_out <= 32'd0;
        sprite_12_data1_out <= 32'd0;
        sprite_13_data1_out <= 32'd0;
        sprite_14_data1_out <= 32'd0;
        sprite_15_data1_out <= 32'd0;
        tilemap_data1_out <= 32'd0;
        framebuffer_data1_out <= 32'd0;
        pixelbuffer_data1_out <= 32'd0;
`else
        sprite_0_data1_out <= sprite_0_data[sprite_word_idx_r];
        sprite_1_data1_out <= sprite_1_data[sprite_word_idx_r];
        sprite_2_data1_out <= sprite_2_data[sprite_word_idx_r];
        sprite_3_data1_out <= sprite_3_data[sprite_word_idx_r];
        sprite_4_data1_out <= sprite_4_data[sprite_word_idx_r];
        sprite_5_data1_out <= sprite_5_data[sprite_word_idx_r];
        sprite_6_data1_out <= sprite_6_data[sprite_word_idx_r];
        sprite_7_data1_out <= sprite_7_data[sprite_word_idx_r];
        sprite_8_data1_out <= sprite_8_data[sprite_word_idx_r];
        sprite_9_data1_out <= sprite_9_data[sprite_word_idx_r];
        sprite_10_data1_out <= sprite_10_data[sprite_word_idx_r];
        sprite_11_data1_out <= sprite_11_data[sprite_word_idx_r];
        sprite_12_data1_out <= sprite_12_data[sprite_word_idx_r];
        sprite_13_data1_out <= sprite_13_data[sprite_word_idx_r];
        sprite_14_data1_out <= sprite_14_data[sprite_word_idx_r];
        sprite_15_data1_out <= sprite_15_data[sprite_word_idx_r];
        tilemap_data1_out <= tile_map[tile_word_idx_r];
        framebuffer_data1_out <= frame_buffer[tile_frame_word_idx_r];
`ifdef FPGA_DISABLE_PIXEL_FB
        pixelbuffer_data1_out <= 32'd0;
`else
        pixelbuffer_data1_out <= pixel_buffer[pixel_frame_word_idx_r];
`endif
`endif

        sd0_spi_start_strobe <= 1'b0;
        sd0_dma_ctrl_write_pulse <= 1'b0;
        sd0_dma_status_clear_pulse <= 1'b0;
        sd0_dma_ctrl_write_data <= sd0_dma_ctrl;
        sd0_dma_sd_ready_pulse <= 1'b0;

        sd1_spi_start_strobe <= 1'b0;
        sd1_dma_ctrl_write_pulse <= 1'b0;
        sd1_dma_status_clear_pulse <= 1'b0;
        sd1_dma_ctrl_write_data <= sd1_dma_ctrl;
        sd1_dma_sd_ready_pulse <= 1'b0;

        // SD0 orchestration:
        // - During SD_INIT, issue CMD0/CMD8/CMD55/ACMD41/CMD58 and finish on CMD58 response.
        // - During DMA block wait, issue exactly one CMD17/CMD24 and finish on SPI interrupt.
        if (!sd0_dma_waiting_for_sd_ready) begin
            sd0_spi_launch_sent <= 1'b0;
            sd0_init_state <= SD_INIT_STATE_IDLE;
            sd0_init_acmd41_attempts <= 8'd0;
        end else if (sd0_dma_init_waiting_for_sd_ready) begin
            case (sd0_init_state)
                SD_INIT_STATE_IDLE: begin
                    if (sd0_dma_status[0] && !sd0_spi_launch_sent && !sd0_busy) begin
                        sd0_card_high_capacity <= 1'b0;
                        sd0_spi_cmd_buffer[7:0] <= SD_SPI_CMD0;
                        sd0_spi_cmd_buffer[15:8] <= 8'h00;
                        sd0_spi_cmd_buffer[23:16] <= 8'h00;
                        sd0_spi_cmd_buffer[31:24] <= 8'h00;
                        sd0_spi_cmd_buffer[39:32] <= 8'h00;
                        sd0_spi_cmd_buffer[47:40] <= 8'h95;
                        sd0_spi_start_strobe <= 1'b1;
                        sd0_spi_launch_sent <= 1'b1;
                        sd0_init_state <= SD_INIT_STATE_WAIT_CMD0;
                    end
                end
                SD_INIT_STATE_WAIT_CMD0: begin
                    if (sd0_cmd_buffer_out_valid) begin
                        sd0_spi_launch_sent <= 1'b0;
                        sd0_init_state <= SD_INIT_STATE_WAIT_CMD8;
                    end
                end
                SD_INIT_STATE_WAIT_CMD8: begin
                    if (sd0_dma_status[0] && !sd0_spi_launch_sent && !sd0_busy) begin
                        sd0_spi_cmd_buffer[7:0] <= 8'h48;
                        sd0_spi_cmd_buffer[15:8] <= 8'h00;
                        sd0_spi_cmd_buffer[23:16] <= 8'h00;
                        sd0_spi_cmd_buffer[31:24] <= 8'h01;
                        sd0_spi_cmd_buffer[39:32] <= 8'hAA;
                        sd0_spi_cmd_buffer[47:40] <= 8'h87;
                        sd0_spi_start_strobe <= 1'b1;
                        sd0_spi_launch_sent <= 1'b1;
                    end
                    if (sd0_cmd_buffer_out_valid) begin
                        sd0_spi_launch_sent <= 1'b0;
                        sd0_init_acmd41_attempts <= 8'd0;
                        sd0_init_state <= SD_INIT_STATE_WAIT_CMD55;
                    end
                end
                SD_INIT_STATE_WAIT_CMD55: begin
                    if (sd0_dma_status[0] && !sd0_spi_launch_sent && !sd0_busy) begin
                        sd0_spi_cmd_buffer[7:0] <= SD_SPI_CMD55;
                        sd0_spi_cmd_buffer[15:8] <= 8'h00;
                        sd0_spi_cmd_buffer[23:16] <= 8'h00;
                        sd0_spi_cmd_buffer[31:24] <= 8'h00;
                        sd0_spi_cmd_buffer[39:32] <= 8'h00;
                        sd0_spi_cmd_buffer[47:40] <= 8'h65;
                        sd0_spi_start_strobe <= 1'b1;
                        sd0_spi_launch_sent <= 1'b1;
                    end
                    if (sd0_cmd_buffer_out_valid) begin
                        sd0_spi_launch_sent <= 1'b0;
                        if (sd0_cmd_buffer_out[7:0] == SD_SPI_R1_ILLEGAL) begin
                            sd0_init_state <= SD_INIT_STATE_WAIT_CMD58;
                        end else begin
                            sd0_init_state <= SD_INIT_STATE_WAIT_ACMD41;
                        end
                    end
                end
                SD_INIT_STATE_WAIT_ACMD41: begin
                    if (sd0_dma_status[0] && !sd0_spi_launch_sent && !sd0_busy) begin
                        sd0_spi_cmd_buffer[7:0] <= SD_SPI_ACMD41;
                        sd0_spi_cmd_buffer[15:8] <= 8'h40;
                        sd0_spi_cmd_buffer[23:16] <= 8'h00;
                        sd0_spi_cmd_buffer[31:24] <= 8'h00;
                        sd0_spi_cmd_buffer[39:32] <= 8'h00;
                        sd0_spi_cmd_buffer[47:40] <= 8'h77;
                        sd0_spi_start_strobe <= 1'b1;
                        sd0_spi_launch_sent <= 1'b1;
                    end
                    if (sd0_cmd_buffer_out_valid) begin
                        sd0_spi_launch_sent <= 1'b0;
                        if (sd0_cmd_buffer_out[7:0] == SD_SPI_R1_READY ||
                            sd0_init_acmd41_attempts == (SD_SPI_INIT_MAX_ACMD41_ATTEMPTS - 1'b1)) begin
                            sd0_init_state <= SD_INIT_STATE_WAIT_CMD58;
                        end else begin
                            sd0_init_acmd41_attempts <= sd0_init_acmd41_attempts + 1'b1;
                            sd0_init_state <= SD_INIT_STATE_WAIT_CMD55;
                        end
                    end
                end
                SD_INIT_STATE_WAIT_CMD58: begin
                    if (sd0_dma_status[0] && !sd0_spi_launch_sent && !sd0_busy) begin
                        sd0_spi_cmd_buffer[7:0] <= SD_SPI_CMD58;
                        sd0_spi_cmd_buffer[15:8] <= 8'h00;
                        sd0_spi_cmd_buffer[23:16] <= 8'h00;
                        sd0_spi_cmd_buffer[31:24] <= 8'h00;
                        sd0_spi_cmd_buffer[39:32] <= 8'h00;
                        sd0_spi_cmd_buffer[47:40] <= 8'hFD;
                        sd0_spi_start_strobe <= 1'b1;
                        sd0_spi_launch_sent <= 1'b1;
                    end
                    if (sd0_cmd_buffer_out_valid) begin
                        // CMD58 OCR[30] indicates SDHC block addressing mode.
                        sd0_card_high_capacity <= sd0_cmd_buffer_out[14];
                        // Hold launch until DMA drops waiting_for_sd_ready so we
                        // do not emit a stale extra CMD0 one cycle after init completes.
                        sd0_spi_launch_sent <= 1'b1;
                        sd0_init_state <= SD_INIT_STATE_IDLE;
                        sd0_dma_sd_ready_pulse <= 1'b1;
                    end
                end
                default: begin
                    sd0_init_state <= SD_INIT_STATE_IDLE;
                    sd0_spi_launch_sent <= 1'b0;
                end
            endcase
        end else begin
            if (sd0_dma_status[0] && !sd0_spi_launch_sent && !sd0_busy) begin
                sd0_spi_cmd_buffer[7:0] <= sd0_dma_ctrl[1] ? SD_SPI_CMD24 : SD_SPI_CMD17;
                sd0_spi_cmd_buffer[15:8] <= sd0_spi_cmd_arg[31:24];
                sd0_spi_cmd_buffer[23:16] <= sd0_spi_cmd_arg[23:16];
                sd0_spi_cmd_buffer[31:24] <= sd0_spi_cmd_arg[15:8];
                sd0_spi_cmd_buffer[39:32] <= sd0_spi_cmd_arg[7:0];
                sd0_spi_cmd_buffer[47:40] <= 8'h01;
                if (sd0_dma_ctrl[1]) begin
                    // CMD24 consumes the RAM->SD block currently staged in DMA.
                    sd0_spi_data_buffer <= sd0_dma_sd_data_block_out;
                end
                sd0_spi_start_strobe <= 1'b1;
                sd0_spi_launch_sent <= 1'b1;
            end
            if (sd0_interrupt) begin
                sd0_dma_sd_ready_pulse <= 1'b1;
            end
        end

        if (!sd0_dma_done_prev && sd0_dma_status[1] && sd0_dma_ctrl[2]) begin
            sd0_irq_pending <= 1'b1;
        end
        sd0_dma_done_prev <= sd0_dma_status[1];

        // SD1 orchestration mirrors SD0.
        if (!sd1_dma_waiting_for_sd_ready) begin
            sd1_spi_launch_sent <= 1'b0;
            sd1_init_state <= SD_INIT_STATE_IDLE;
            sd1_init_acmd41_attempts <= 8'd0;
        end else if (sd1_dma_init_waiting_for_sd_ready) begin
            case (sd1_init_state)
                SD_INIT_STATE_IDLE: begin
                    if (sd1_dma_status[0] && !sd1_spi_launch_sent && !sd1_busy) begin
                        sd1_card_high_capacity <= 1'b0;
                        sd1_spi_cmd_buffer[7:0] <= SD_SPI_CMD0;
                        sd1_spi_cmd_buffer[15:8] <= 8'h00;
                        sd1_spi_cmd_buffer[23:16] <= 8'h00;
                        sd1_spi_cmd_buffer[31:24] <= 8'h00;
                        sd1_spi_cmd_buffer[39:32] <= 8'h00;
                        sd1_spi_cmd_buffer[47:40] <= 8'h95;
                        sd1_spi_start_strobe <= 1'b1;
                        sd1_spi_launch_sent <= 1'b1;
                        sd1_init_state <= SD_INIT_STATE_WAIT_CMD0;
                    end
                end
                SD_INIT_STATE_WAIT_CMD0: begin
                    if (sd1_cmd_buffer_out_valid) begin
                        sd1_spi_launch_sent <= 1'b0;
                        sd1_init_state <= SD_INIT_STATE_WAIT_CMD8;
                    end
                end
                SD_INIT_STATE_WAIT_CMD8: begin
                    if (sd1_dma_status[0] && !sd1_spi_launch_sent && !sd1_busy) begin
                        sd1_spi_cmd_buffer[7:0] <= 8'h48;
                        sd1_spi_cmd_buffer[15:8] <= 8'h00;
                        sd1_spi_cmd_buffer[23:16] <= 8'h00;
                        sd1_spi_cmd_buffer[31:24] <= 8'h01;
                        sd1_spi_cmd_buffer[39:32] <= 8'hAA;
                        sd1_spi_cmd_buffer[47:40] <= 8'h87;
                        sd1_spi_start_strobe <= 1'b1;
                        sd1_spi_launch_sent <= 1'b1;
                    end
                    if (sd1_cmd_buffer_out_valid) begin
                        sd1_spi_launch_sent <= 1'b0;
                        sd1_init_acmd41_attempts <= 8'd0;
                        sd1_init_state <= SD_INIT_STATE_WAIT_CMD55;
                    end
                end
                SD_INIT_STATE_WAIT_CMD55: begin
                    if (sd1_dma_status[0] && !sd1_spi_launch_sent && !sd1_busy) begin
                        sd1_spi_cmd_buffer[7:0] <= SD_SPI_CMD55;
                        sd1_spi_cmd_buffer[15:8] <= 8'h00;
                        sd1_spi_cmd_buffer[23:16] <= 8'h00;
                        sd1_spi_cmd_buffer[31:24] <= 8'h00;
                        sd1_spi_cmd_buffer[39:32] <= 8'h00;
                        sd1_spi_cmd_buffer[47:40] <= 8'h65;
                        sd1_spi_start_strobe <= 1'b1;
                        sd1_spi_launch_sent <= 1'b1;
                    end
                    if (sd1_cmd_buffer_out_valid) begin
                        sd1_spi_launch_sent <= 1'b0;
                        if (sd1_cmd_buffer_out[7:0] == SD_SPI_R1_ILLEGAL) begin
                            sd1_init_state <= SD_INIT_STATE_WAIT_CMD58;
                        end else begin
                            sd1_init_state <= SD_INIT_STATE_WAIT_ACMD41;
                        end
                    end
                end
                SD_INIT_STATE_WAIT_ACMD41: begin
                    if (sd1_dma_status[0] && !sd1_spi_launch_sent && !sd1_busy) begin
                        sd1_spi_cmd_buffer[7:0] <= SD_SPI_ACMD41;
                        sd1_spi_cmd_buffer[15:8] <= 8'h40;
                        sd1_spi_cmd_buffer[23:16] <= 8'h00;
                        sd1_spi_cmd_buffer[31:24] <= 8'h00;
                        sd1_spi_cmd_buffer[39:32] <= 8'h00;
                        sd1_spi_cmd_buffer[47:40] <= 8'h77;
                        sd1_spi_start_strobe <= 1'b1;
                        sd1_spi_launch_sent <= 1'b1;
                    end
                    if (sd1_cmd_buffer_out_valid) begin
                        sd1_spi_launch_sent <= 1'b0;
                        if (sd1_cmd_buffer_out[7:0] == SD_SPI_R1_READY ||
                            sd1_init_acmd41_attempts == (SD_SPI_INIT_MAX_ACMD41_ATTEMPTS - 1'b1)) begin
                            sd1_init_state <= SD_INIT_STATE_WAIT_CMD58;
                        end else begin
                            sd1_init_acmd41_attempts <= sd1_init_acmd41_attempts + 1'b1;
                            sd1_init_state <= SD_INIT_STATE_WAIT_CMD55;
                        end
                    end
                end
                SD_INIT_STATE_WAIT_CMD58: begin
                    if (sd1_dma_status[0] && !sd1_spi_launch_sent && !sd1_busy) begin
                        sd1_spi_cmd_buffer[7:0] <= SD_SPI_CMD58;
                        sd1_spi_cmd_buffer[15:8] <= 8'h00;
                        sd1_spi_cmd_buffer[23:16] <= 8'h00;
                        sd1_spi_cmd_buffer[31:24] <= 8'h00;
                        sd1_spi_cmd_buffer[39:32] <= 8'h00;
                        sd1_spi_cmd_buffer[47:40] <= 8'hFD;
                        sd1_spi_start_strobe <= 1'b1;
                        sd1_spi_launch_sent <= 1'b1;
                    end
                    if (sd1_cmd_buffer_out_valid) begin
                        // CMD58 OCR[30] indicates SDHC block addressing mode.
                        sd1_card_high_capacity <= sd1_cmd_buffer_out[14];
                        // Hold launch until DMA drops waiting_for_sd_ready so we
                        // do not emit a stale extra CMD0 one cycle after init completes.
                        sd1_spi_launch_sent <= 1'b1;
                        sd1_init_state <= SD_INIT_STATE_IDLE;
                        sd1_dma_sd_ready_pulse <= 1'b1;
                    end
                end
                default: begin
                    sd1_init_state <= SD_INIT_STATE_IDLE;
                    sd1_spi_launch_sent <= 1'b0;
                end
            endcase
        end else begin
            if (sd1_dma_status[0] && !sd1_spi_launch_sent && !sd1_busy) begin
                sd1_spi_cmd_buffer[7:0] <= sd1_dma_ctrl[1] ? SD_SPI_CMD24 : SD_SPI_CMD17;
                sd1_spi_cmd_buffer[15:8] <= sd1_spi_cmd_arg[31:24];
                sd1_spi_cmd_buffer[23:16] <= sd1_spi_cmd_arg[23:16];
                sd1_spi_cmd_buffer[31:24] <= sd1_spi_cmd_arg[15:8];
                sd1_spi_cmd_buffer[39:32] <= sd1_spi_cmd_arg[7:0];
                sd1_spi_cmd_buffer[47:40] <= 8'h01;
                if (sd1_dma_ctrl[1]) begin
                    // CMD24 consumes the RAM->SD block currently staged in DMA.
                    sd1_spi_data_buffer <= sd1_dma_sd_data_block_out;
                end
                sd1_spi_start_strobe <= 1'b1;
                sd1_spi_launch_sent <= 1'b1;
            end
            if (sd1_interrupt) begin
                sd1_dma_sd_ready_pulse <= 1'b1;
            end
        end

        if (!sd1_dma_done_prev && sd1_dma_status[1] && sd1_dma_ctrl[2]) begin
            sd1_irq_pending <= 1'b1;
        end
        sd1_dma_done_prev <= sd1_dma_status[1];

        rdata0 <= data0_out;
        rdata0_tag <= ram_data0_tag_out;
        rdata1 <= data1_out;

        // CPU-originated MMIO writes/read-consume side effects execute only
        // when the CPU pipeline advances this cycle.
        if (pipe_clk_en) begin
        if (pit_we) begin
            pit_cfg_reg <= wdata;
        end

        if (SPRITE_0_START <= waddr && waddr < SPRITE_1_START) begin
            if (wen[0]) sprite_0_data[sprite_word_idx_w][7:0]   <= wdata[7:0];
            if (wen[1]) sprite_0_data[sprite_word_idx_w][15:8]  <= wdata[15:8];
            if (wen[2]) sprite_0_data[sprite_word_idx_w][23:16] <= wdata[23:16];
            if (wen[3]) sprite_0_data[sprite_word_idx_w][31:24] <= wdata[31:24];
        end else if (SPRITE_1_START <= waddr && waddr < SPRITE_2_START) begin
            if (wen[0]) sprite_1_data[sprite_word_idx_w][7:0]   <= wdata[7:0];
            if (wen[1]) sprite_1_data[sprite_word_idx_w][15:8]  <= wdata[15:8];
            if (wen[2]) sprite_1_data[sprite_word_idx_w][23:16] <= wdata[23:16];
            if (wen[3]) sprite_1_data[sprite_word_idx_w][31:24] <= wdata[31:24];
        end else if (SPRITE_2_START <= waddr && waddr < SPRITE_3_START) begin
            if (wen[0]) sprite_2_data[sprite_word_idx_w][7:0]   <= wdata[7:0];
            if (wen[1]) sprite_2_data[sprite_word_idx_w][15:8]  <= wdata[15:8];
            if (wen[2]) sprite_2_data[sprite_word_idx_w][23:16] <= wdata[23:16];
            if (wen[3]) sprite_2_data[sprite_word_idx_w][31:24] <= wdata[31:24];
        end else if (SPRITE_3_START <= waddr && waddr < SPRITE_4_START) begin
            if (wen[0]) sprite_3_data[sprite_word_idx_w][7:0]   <= wdata[7:0];
            if (wen[1]) sprite_3_data[sprite_word_idx_w][15:8]  <= wdata[15:8];
            if (wen[2]) sprite_3_data[sprite_word_idx_w][23:16] <= wdata[23:16];
            if (wen[3]) sprite_3_data[sprite_word_idx_w][31:24] <= wdata[31:24];
        end else if (SPRITE_4_START <= waddr && waddr < SPRITE_5_START) begin
            if (wen[0]) sprite_4_data[sprite_word_idx_w][7:0]   <= wdata[7:0];
            if (wen[1]) sprite_4_data[sprite_word_idx_w][15:8]  <= wdata[15:8];
            if (wen[2]) sprite_4_data[sprite_word_idx_w][23:16] <= wdata[23:16];
            if (wen[3]) sprite_4_data[sprite_word_idx_w][31:24] <= wdata[31:24];
        end else if (SPRITE_5_START <= waddr && waddr < SPRITE_6_START) begin
            if (wen[0]) sprite_5_data[sprite_word_idx_w][7:0]   <= wdata[7:0];
            if (wen[1]) sprite_5_data[sprite_word_idx_w][15:8]  <= wdata[15:8];
            if (wen[2]) sprite_5_data[sprite_word_idx_w][23:16] <= wdata[23:16];
            if (wen[3]) sprite_5_data[sprite_word_idx_w][31:24] <= wdata[31:24];
        end else if (SPRITE_6_START <= waddr && waddr < SPRITE_7_START) begin
            if (wen[0]) sprite_6_data[sprite_word_idx_w][7:0]   <= wdata[7:0];
            if (wen[1]) sprite_6_data[sprite_word_idx_w][15:8]  <= wdata[15:8];
            if (wen[2]) sprite_6_data[sprite_word_idx_w][23:16] <= wdata[23:16];
            if (wen[3]) sprite_6_data[sprite_word_idx_w][31:24] <= wdata[31:24];
        end else if (SPRITE_7_START <= waddr && waddr < SPRITE_8_START) begin
            if (wen[0]) sprite_7_data[sprite_word_idx_w][7:0]   <= wdata[7:0];
            if (wen[1]) sprite_7_data[sprite_word_idx_w][15:8]  <= wdata[15:8];
            if (wen[2]) sprite_7_data[sprite_word_idx_w][23:16] <= wdata[23:16];
            if (wen[3]) sprite_7_data[sprite_word_idx_w][31:24] <= wdata[31:24];
        end else if (SPRITE_8_START <= waddr && waddr < SPRITE_9_START) begin
            if (wen[0]) sprite_8_data[sprite_word_idx_w][7:0]   <= wdata[7:0];
            if (wen[1]) sprite_8_data[sprite_word_idx_w][15:8]  <= wdata[15:8];
            if (wen[2]) sprite_8_data[sprite_word_idx_w][23:16] <= wdata[23:16];
            if (wen[3]) sprite_8_data[sprite_word_idx_w][31:24] <= wdata[31:24];
        end else if (SPRITE_9_START <= waddr && waddr < SPRITE_10_START) begin
            if (wen[0]) sprite_9_data[sprite_word_idx_w][7:0]   <= wdata[7:0];
            if (wen[1]) sprite_9_data[sprite_word_idx_w][15:8]  <= wdata[15:8];
            if (wen[2]) sprite_9_data[sprite_word_idx_w][23:16] <= wdata[23:16];
            if (wen[3]) sprite_9_data[sprite_word_idx_w][31:24] <= wdata[31:24];
        end else if (SPRITE_10_START <= waddr && waddr < SPRITE_11_START) begin
            if (wen[0]) sprite_10_data[sprite_word_idx_w][7:0]   <= wdata[7:0];
            if (wen[1]) sprite_10_data[sprite_word_idx_w][15:8]  <= wdata[15:8];
            if (wen[2]) sprite_10_data[sprite_word_idx_w][23:16] <= wdata[23:16];
            if (wen[3]) sprite_10_data[sprite_word_idx_w][31:24] <= wdata[31:24];
        end else if (SPRITE_11_START <= waddr && waddr < SPRITE_12_START) begin
            if (wen[0]) sprite_11_data[sprite_word_idx_w][7:0]   <= wdata[7:0];
            if (wen[1]) sprite_11_data[sprite_word_idx_w][15:8]  <= wdata[15:8];
            if (wen[2]) sprite_11_data[sprite_word_idx_w][23:16] <= wdata[23:16];
            if (wen[3]) sprite_11_data[sprite_word_idx_w][31:24] <= wdata[31:24];
        end else if (SPRITE_12_START <= waddr && waddr < SPRITE_13_START) begin
            if (wen[0]) sprite_12_data[sprite_word_idx_w][7:0]   <= wdata[7:0];
            if (wen[1]) sprite_12_data[sprite_word_idx_w][15:8]  <= wdata[15:8];
            if (wen[2]) sprite_12_data[sprite_word_idx_w][23:16] <= wdata[23:16];
            if (wen[3]) sprite_12_data[sprite_word_idx_w][31:24] <= wdata[31:24];
        end else if (SPRITE_13_START <= waddr && waddr < SPRITE_14_START) begin
            if (wen[0]) sprite_13_data[sprite_word_idx_w][7:0]   <= wdata[7:0];
            if (wen[1]) sprite_13_data[sprite_word_idx_w][15:8]  <= wdata[15:8];
            if (wen[2]) sprite_13_data[sprite_word_idx_w][23:16] <= wdata[23:16];
            if (wen[3]) sprite_13_data[sprite_word_idx_w][31:24] <= wdata[31:24];
        end else if (SPRITE_14_START <= waddr && waddr < SPRITE_15_START) begin
            if (wen[0]) sprite_14_data[sprite_word_idx_w][7:0]   <= wdata[7:0];
            if (wen[1]) sprite_14_data[sprite_word_idx_w][15:8]  <= wdata[15:8];
            if (wen[2]) sprite_14_data[sprite_word_idx_w][23:16] <= wdata[23:16];
            if (wen[3]) sprite_14_data[sprite_word_idx_w][31:24] <= wdata[31:24];
        end else if (SPRITE_15_START <= waddr && waddr < SPRITE_DATA_END) begin
            if (wen[0]) sprite_15_data[sprite_word_idx_w][7:0]   <= wdata[7:0];
            if (wen[1]) sprite_15_data[sprite_word_idx_w][15:8]  <= wdata[15:8];
            if (wen[2]) sprite_15_data[sprite_word_idx_w][23:16] <= wdata[23:16];
            if (wen[3]) sprite_15_data[sprite_word_idx_w][31:24] <= wdata[31:24];
        end else if (TILEMAP_START <= waddr && waddr < TILEMAP_END) begin
            if (wen[0]) tile_map[tile_word_idx_w][7:0]   <= wdata[7:0];
            if (wen[1]) tile_map[tile_word_idx_w][15:8]  <= wdata[15:8];
            if (wen[2]) tile_map[tile_word_idx_w][23:16] <= wdata[23:16];
            if (wen[3]) tile_map[tile_word_idx_w][31:24] <= wdata[31:24];
        end else if (TILE_FRAMEBUFFER_START <= waddr && waddr < TILE_FRAMEBUFFER_END) begin
            if (wen[0]) frame_buffer[tile_frame_word_idx_w][7:0]   <= wdata[7:0];
            if (wen[1]) frame_buffer[tile_frame_word_idx_w][15:8]  <= wdata[15:8];
            if (wen[2]) frame_buffer[tile_frame_word_idx_w][23:16] <= wdata[23:16];
            if (wen[3]) frame_buffer[tile_frame_word_idx_w][31:24] <= wdata[31:24];
`ifndef FPGA_DISABLE_PIXEL_FB
        end else if (PIXEL_FRAMEBUFFER_START <= waddr && waddr < PIXEL_FRAMEBUFFER_END) begin
            if (wen[0]) pixel_buffer[pixel_frame_word_idx_w][7:0]   <= wdata[7:0];
            if (wen[1]) pixel_buffer[pixel_frame_word_idx_w][15:8]  <= wdata[15:8];
            if (wen[2]) pixel_buffer[pixel_frame_word_idx_w][23:16] <= wdata[23:16];
            if (wen[3]) pixel_buffer[pixel_frame_word_idx_w][31:24] <= wdata[31:24];
`endif
        end
        scroll_word_base = {waddr[26:2], 2'b00};
        for (scroll_lane = 0; scroll_lane < 4; scroll_lane = scroll_lane + 1) begin
            if (wen[scroll_lane]) begin
                case (scroll_lane)
                    0: begin scroll_byte_addr = scroll_word_base; scroll_byte_data = wdata[7:0]; end
                    1: begin scroll_byte_addr = scroll_word_base + 27'd1; scroll_byte_data = wdata[15:8]; end
                    2: begin scroll_byte_addr = scroll_word_base + 27'd2; scroll_byte_data = wdata[23:16]; end
                    default: begin scroll_byte_addr = scroll_word_base + 27'd3; scroll_byte_data = wdata[31:24]; end
                endcase
                if (scroll_byte_addr == SCALE_REG)
                    scale_reg <= scroll_byte_data;
                else if (scroll_byte_addr == HSCROLL_REG)
                    hscroll_reg[7:0] <= scroll_byte_data;
                else if (scroll_byte_addr == HSCROLL_REG + 27'd1)
                    hscroll_reg[15:8] <= scroll_byte_data;
                else if (scroll_byte_addr == VSCROLL_REG)
                    vscroll_reg[7:0] <= scroll_byte_data;
                else if (scroll_byte_addr == VSCROLL_REG + 27'd1)
                    vscroll_reg[15:8] <= scroll_byte_data;
                else if (scroll_byte_addr == PIXEL_SCALE_REG)
                    pixel_scale_reg <= scroll_byte_data;
                else if (scroll_byte_addr == PIXEL_HSCROLL_REG)
                    pixel_hscroll_reg[7:0] <= scroll_byte_data;
                else if (scroll_byte_addr == PIXEL_HSCROLL_REG + 27'd1)
                    pixel_hscroll_reg[15:8] <= scroll_byte_data;
                else if (scroll_byte_addr == PIXEL_VSCROLL_REG)
                    pixel_vscroll_reg[7:0] <= scroll_byte_data;
                else if (scroll_byte_addr == PIXEL_VSCROLL_REG + 27'd1)
                    pixel_vscroll_reg[15:8] <= scroll_byte_data;
                else if (CLOCK_DIV_REG <= scroll_byte_addr && scroll_byte_addr < (CLOCK_DIV_REG + 27'd4))
                    clock_div_reg[(scroll_byte_addr - CLOCK_DIV_REG) * 8 +: 8] <= scroll_byte_data;
                else if (SPRITE_SCALE_BASE <= scroll_byte_addr && scroll_byte_addr < SPRITE_SCALE_END)
                    sprite_scale_regs[scroll_byte_addr[3:0]] <= scroll_byte_data;
                if (SD0_DMA_MEM_ADDR_REG <= scroll_byte_addr && scroll_byte_addr < (SD0_DMA_MEM_ADDR_REG + 27'd4)) begin
                    sd0_dma_mem_addr_reg[(scroll_byte_addr - SD0_DMA_MEM_ADDR_REG) * 8 +: 8] <= scroll_byte_data;
                end else if (SD0_DMA_SD_BLOCK_REG <= scroll_byte_addr && scroll_byte_addr < (SD0_DMA_SD_BLOCK_REG + 27'd4)) begin
                    sd0_dma_block_reg[(scroll_byte_addr - SD0_DMA_SD_BLOCK_REG) * 8 +: 8] <= scroll_byte_data;
                end else if (SD0_DMA_LEN_REG <= scroll_byte_addr && scroll_byte_addr < (SD0_DMA_LEN_REG + 27'd4)) begin
                    sd0_dma_len_reg[(scroll_byte_addr - SD0_DMA_LEN_REG) * 8 +: 8] <= scroll_byte_data;
                end else if (SD0_DMA_CTRL_REG <= scroll_byte_addr && scroll_byte_addr < (SD0_DMA_CTRL_REG + 27'd4)) begin
                    sd0_dma_ctrl_write_pulse <= 1'b1;
                    sd0_dma_ctrl_write_data[(scroll_byte_addr - SD0_DMA_CTRL_REG) * 8 +: 8] <= scroll_byte_data;
                    if ((scroll_byte_addr == SD0_DMA_CTRL_REG) && (scroll_byte_data[0] || scroll_byte_data[3])) begin
                        sd0_irq_pending <= 1'b0;
                    end
                end else if (SD0_DMA_STATUS_REG <= scroll_byte_addr && scroll_byte_addr < (SD0_DMA_STATUS_REG + 27'd4)) begin
                    sd0_dma_status_clear_pulse <= 1'b1;
                    sd0_irq_pending <= 1'b0;
                end else if (SD1_DMA_MEM_ADDR_REG <= scroll_byte_addr && scroll_byte_addr < (SD1_DMA_MEM_ADDR_REG + 27'd4)) begin
                    sd1_dma_mem_addr_reg[(scroll_byte_addr - SD1_DMA_MEM_ADDR_REG) * 8 +: 8] <= scroll_byte_data;
                end else if (SD1_DMA_SD_BLOCK_REG <= scroll_byte_addr && scroll_byte_addr < (SD1_DMA_SD_BLOCK_REG + 27'd4)) begin
                    sd1_dma_block_reg[(scroll_byte_addr - SD1_DMA_SD_BLOCK_REG) * 8 +: 8] <= scroll_byte_data;
                end else if (SD1_DMA_LEN_REG <= scroll_byte_addr && scroll_byte_addr < (SD1_DMA_LEN_REG + 27'd4)) begin
                    sd1_dma_len_reg[(scroll_byte_addr - SD1_DMA_LEN_REG) * 8 +: 8] <= scroll_byte_data;
                end else if (SD1_DMA_CTRL_REG <= scroll_byte_addr && scroll_byte_addr < (SD1_DMA_CTRL_REG + 27'd4)) begin
                    sd1_dma_ctrl_write_pulse <= 1'b1;
                    sd1_dma_ctrl_write_data[(scroll_byte_addr - SD1_DMA_CTRL_REG) * 8 +: 8] <= scroll_byte_data;
                    if ((scroll_byte_addr == SD1_DMA_CTRL_REG) && (scroll_byte_data[0] || scroll_byte_data[3])) begin
                        sd1_irq_pending <= 1'b0;
                    end
                end else if (SD1_DMA_STATUS_REG <= scroll_byte_addr && scroll_byte_addr < (SD1_DMA_STATUS_REG + 27'd4)) begin
                    sd1_dma_status_clear_pulse <= 1'b1;
                    sd1_irq_pending <= 1'b0;
                end
            end
        end
        if ((waddr[26:2] == UART_TX_REG[26:2]) && wen[waddr[1:0]]) begin
            uart_tx_data <= select_lane_byte(wdata, waddr[1:0]);
        end
        if (waddr == SPRITE_0_X) begin
            if (wen[1:0] == 2'b11)
                sprite_0_x <= sprite_coord_low;
            else if (wen[3:2] == 2'b11)
                sprite_0_x <= sprite_coord_high;
        end
        if (waddr == SPRITE_0_Y) begin
            if (wen[1:0] == 2'b11)
                sprite_0_y <= sprite_coord_low;
            else if (wen[3:2] == 2'b11)
                sprite_0_y <= sprite_coord_high;
        end
        if (waddr == SPRITE_1_X) begin
            if (wen[1:0] == 2'b11)
                sprite_1_x <= sprite_coord_low;
            else if (wen[3:2] == 2'b11)
                sprite_1_x <= sprite_coord_high;
        end
        if (waddr == SPRITE_1_Y) begin
            if (wen[1:0] == 2'b11)
                sprite_1_y <= sprite_coord_low;
            else if (wen[3:2] == 2'b11)
                sprite_1_y <= sprite_coord_high;
        end
        if (waddr == SPRITE_2_X) begin
            if (wen[1:0] == 2'b11)
                sprite_2_x <= sprite_coord_low;
            else if (wen[3:2] == 2'b11)
                sprite_2_x <= sprite_coord_high;
        end
        if (waddr == SPRITE_2_Y) begin
            if (wen[1:0] == 2'b11)
                sprite_2_y <= sprite_coord_low;
            else if (wen[3:2] == 2'b11)
                sprite_2_y <= sprite_coord_high;
        end
        if (waddr == SPRITE_3_X) begin
            if (wen[1:0] == 2'b11)
                sprite_3_x <= sprite_coord_low;
            else if (wen[3:2] == 2'b11)
                sprite_3_x <= sprite_coord_high;
        end
        if (waddr == SPRITE_3_Y) begin
            if (wen[1:0] == 2'b11)
                sprite_3_y <= sprite_coord_low;
            else if (wen[3:2] == 2'b11)
                sprite_3_y <= sprite_coord_high;
        end
        if (waddr == SPRITE_4_X) begin
            if (wen[1:0] == 2'b11)
                sprite_4_x <= sprite_coord_low;
            else if (wen[3:2] == 2'b11)
                sprite_4_x <= sprite_coord_high;
        end
        if (waddr == SPRITE_4_Y) begin
            if (wen[1:0] == 2'b11)
                sprite_4_y <= sprite_coord_low;
            else if (wen[3:2] == 2'b11)
                sprite_4_y <= sprite_coord_high;
        end
        if (waddr == SPRITE_5_X) begin
            if (wen[1:0] == 2'b11)
                sprite_5_x <= sprite_coord_low;
            else if (wen[3:2] == 2'b11)
                sprite_5_x <= sprite_coord_high;
        end
        if (waddr == SPRITE_5_Y) begin
            if (wen[1:0] == 2'b11)
                sprite_5_y <= sprite_coord_low;
            else if (wen[3:2] == 2'b11)
                sprite_5_y <= sprite_coord_high;
        end
        if (waddr == SPRITE_6_X) begin
            if (wen[1:0] == 2'b11)
                sprite_6_x <= sprite_coord_low;
            else if (wen[3:2] == 2'b11)
                sprite_6_x <= sprite_coord_high;
        end
        if (waddr == SPRITE_6_Y) begin
            if (wen[1:0] == 2'b11)
                sprite_6_y <= sprite_coord_low;
            else if (wen[3:2] == 2'b11)
                sprite_6_y <= sprite_coord_high;
        end
        if (waddr == SPRITE_7_X) begin
            if (wen[1:0] == 2'b11)
                sprite_7_x <= sprite_coord_low;
            else if (wen[3:2] == 2'b11)
                sprite_7_x <= sprite_coord_high;
        end
        if (waddr == SPRITE_7_Y) begin
            if (wen[1:0] == 2'b11)
                sprite_7_y <= sprite_coord_low;
            else if (wen[3:2] == 2'b11)
                sprite_7_y <= sprite_coord_high;
        end
        if (waddr == SPRITE_8_X) begin
            if (wen[1:0] == 2'b11)
                sprite_8_x <= sprite_coord_low;
            else if (wen[3:2] == 2'b11)
                sprite_8_x <= sprite_coord_high;
        end
        if (waddr == SPRITE_8_Y) begin
            if (wen[1:0] == 2'b11)
                sprite_8_y <= sprite_coord_low;
            else if (wen[3:2] == 2'b11)
                sprite_8_y <= sprite_coord_high;
        end
        if (waddr == SPRITE_9_X) begin
            if (wen[1:0] == 2'b11)
                sprite_9_x <= sprite_coord_low;
            else if (wen[3:2] == 2'b11)
                sprite_9_x <= sprite_coord_high;
        end
        if (waddr == SPRITE_9_Y) begin
            if (wen[1:0] == 2'b11)
                sprite_9_y <= sprite_coord_low;
            else if (wen[3:2] == 2'b11)
                sprite_9_y <= sprite_coord_high;
        end
        if (waddr == SPRITE_10_X) begin
            if (wen[1:0] == 2'b11)
                sprite_10_x <= sprite_coord_low;
            else if (wen[3:2] == 2'b11)
                sprite_10_x <= sprite_coord_high;
        end
        if (waddr == SPRITE_10_Y) begin
            if (wen[1:0] == 2'b11)
                sprite_10_y <= sprite_coord_low;
            else if (wen[3:2] == 2'b11)
                sprite_10_y <= sprite_coord_high;
        end
        if (waddr == SPRITE_11_X) begin
            if (wen[1:0] == 2'b11)
                sprite_11_x <= sprite_coord_low;
            else if (wen[3:2] == 2'b11)
                sprite_11_x <= sprite_coord_high;
        end
        if (waddr == SPRITE_11_Y) begin
            if (wen[1:0] == 2'b11)
                sprite_11_y <= sprite_coord_low;
            else if (wen[3:2] == 2'b11)
                sprite_11_y <= sprite_coord_high;
        end
        if (waddr == SPRITE_12_X) begin
            if (wen[1:0] == 2'b11)
                sprite_12_x <= sprite_coord_low;
            else if (wen[3:2] == 2'b11)
                sprite_12_x <= sprite_coord_high;
        end
        if (waddr == SPRITE_12_Y) begin
            if (wen[1:0] == 2'b11)
                sprite_12_y <= sprite_coord_low;
            else if (wen[3:2] == 2'b11)
                sprite_12_y <= sprite_coord_high;
        end
        if (waddr == SPRITE_13_X) begin
            if (wen[1:0] == 2'b11)
                sprite_13_x <= sprite_coord_low;
            else if (wen[3:2] == 2'b11)
                sprite_13_x <= sprite_coord_high;
        end
        if (waddr == SPRITE_13_Y) begin
            if (wen[1:0] == 2'b11)
                sprite_13_y <= sprite_coord_low;
            else if (wen[3:2] == 2'b11)
                sprite_13_y <= sprite_coord_high;
        end
        if (waddr == SPRITE_14_X) begin
            if (wen[1:0] == 2'b11)
                sprite_14_x <= sprite_coord_low;
            else if (wen[3:2] == 2'b11)
                sprite_14_x <= sprite_coord_high;
        end
        if (waddr == SPRITE_14_Y) begin
            if (wen[1:0] == 2'b11)
                sprite_14_y <= sprite_coord_low;
            else if (wen[3:2] == 2'b11)
                sprite_14_y <= sprite_coord_high;
        end
        if (waddr == SPRITE_15_X) begin
            if (wen[1:0] == 2'b11)
                sprite_15_x <= sprite_coord_low;
            else if (wen[3:2] == 2'b11)
                sprite_15_x <= sprite_coord_high;
        end
        if (waddr == SPRITE_15_Y) begin
            if (wen[1:0] == 2'b11)
                sprite_15_y <= sprite_coord_low;
            else if (wen[3:2] == 2'b11)
                sprite_15_y <= sprite_coord_high;
        end
        end
      end
    end
endmodule
