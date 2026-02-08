`timescale 1ps/1ps

module mem(input clk, input clk_en,
    input [26:0]raddr0, output reg [31:0]rdata0,
    input ren, input [26:0]raddr1, output reg [31:0]rdata1,
    input [3:0]wen, input [26:0]waddr, input [31:0]wdata,
    output ps2_ren, input [15:0]ps2_data_in,
    input [9:0]pixel_x_in, input [9:0]pixel_y_in, output [11:0]pixel,
    output reg [7:0]uart_tx_data, output uart_tx_wen,
    input [7:0]uart_rx_data, output uart_rx_ren,
    output sd_spi_cs, output sd_spi_clk, output sd_spi_mosi, input sd_spi_miso,
    output [15:0]interrupts
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

    // Current simple SD controller register surface.
    localparam SD_START_REG = 27'h7FE581C;
    localparam SD_CMD_BASE = 27'h7FE5810;
    localparam SD_CMD_END = 27'h7FE5815;
    localparam SD_DATA_BASE = 27'h7FE5820;
    localparam SD_DATA_END = 27'h7FE583F;

    // Word-addressed RAM backing 0x0000000 .. RAM_END-1.
    localparam [24:0] RAM_WORDS = RAM_END[26:2];
    localparam [24:0] RAM_LAST_WORD = RAM_WORDS - 25'd1;
    (* ram_style = "block" *) reg [31:0]ram[0:RAM_LAST_WORD];

    // Sprite backing storage (sprites 0..15).
    reg [31:0]sprite_0_data[0:16'h1ff];
    reg [31:0]sprite_1_data[0:16'h1ff];
    reg [31:0]sprite_2_data[0:16'h1ff];
    reg [31:0]sprite_3_data[0:16'h1ff];
    reg [31:0]sprite_4_data[0:16'h1ff];
    reg [31:0]sprite_5_data[0:16'h1ff];
    reg [31:0]sprite_6_data[0:16'h1ff];
    reg [31:0]sprite_7_data[0:16'h1ff];
    reg [31:0]sprite_8_data[0:16'h1ff];
    reg [31:0]sprite_9_data[0:16'h1ff];
    reg [31:0]sprite_10_data[0:16'h1ff];
    reg [31:0]sprite_11_data[0:16'h1ff];
    reg [31:0]sprite_12_data[0:16'h1ff];
    reg [31:0]sprite_13_data[0:16'h1ff];
    reg [31:0]sprite_14_data[0:16'h1ff];
    reg [31:0]sprite_15_data[0:16'h1ff];
    
    // Tile map + tile/pixel framebuffer storage for the high MMIO regions.
    (* ram_style = "block" *) reg [31:0]tile_map[0:16'h1fff];
    (* ram_style = "block" *) reg [31:0]frame_buffer[0:16'h095f];
    (* ram_style = "block" *) reg [31:0]pixel_buffer[0:16'h95ff];

    reg [1023:0] hexfile; // buffer for filename

    integer i;
    initial begin
        if (!$value$plusargs("hex=%s", hexfile)) begin
            $display("ERROR: no +hex=<file> argument given!");
            $finish;
        end

        $readmemh(hexfile, ram);  // mem is your instruction/data memory

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
        for (i = 0; i < 16; i = i + 1) begin
          sprite_scale_regs[i] = 8'd0;
        end
        for (i = 0; i < 6; i = i + 1) begin
          sd_cmd_buffer[i] = 8'h00;
        end
        for (i = 0; i < 512; i = i + 1) begin
          sd_data_buffer[i] = 8'h00;
        end
        sd_start_pending = 1'b0;
        sd_start_strobe = 1'b0;
        sd_irq_pending = 1'b0;
        raddr0_buf = 27'd0;
        raddr1_buf = 27'd0;
        waddr_buf = 27'd0;
        ren_buf = 1'b0;
        wen_buf = 4'd0;
        ram_data0_out = 32'd0;
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
        rdata1 = 32'd0;
        uart_tx_data = 8'd0;
        pixel_scale_reg = 8'd0;
        pixel_vscroll_reg = 16'd0;
        pixel_hscroll_reg = 16'd0;
        clock_div_reg = 32'd0;
        pit_cfg_reg = 32'd0;
        vga_frame_count = 32'd0;
        in_vblank_prev = 1'b0;
        frame_start_prev = 1'b0;
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
    end

    reg [26:0]raddr0_buf;
    reg [26:0]raddr1_buf;
    reg [26:0]waddr_buf;
    reg ren_buf = 1'b0;

    reg [3:0]wen_buf;

    reg [31:0]ram_data0_out;
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
    reg frame_start_prev = 1'b0;
    reg vga_vblank_irq = 1'b0;
    reg [7:0]sprite_scale_regs[0:15];

    integer scroll_lane;
    reg [26:0]scroll_word_base;
    reg [26:0]scroll_byte_addr;
    reg [7:0]scroll_byte_data;
    reg [8:0]sd_byte_offset;
    integer sd_copy_idx;

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

    reg [7:0]sd_cmd_buffer[0:5];
    reg [7:0]sd_data_buffer[0:511];
    reg sd_start_pending = 1'b0;
    reg sd_start_strobe = 1'b0;
    reg sd_irq_pending = 1'b0;
    wire [47:0]sd_cmd_buffer_out;
    wire sd_cmd_buffer_out_valid;
    wire [4095:0]sd_data_buffer_out;
    wire sd_data_buffer_out_valid;
    wire sd_busy;
    wire sd_interrupt;
    wire sd_spi_cs_int;
    wire sd_spi_clk_int;
    wire sd_spi_mosi_int;
    wire [47:0]sd_cmd_buffer_in_flat;
    wire [4095:0]sd_data_buffer_in_flat;
    wire [7:0]sd_cmd_buffer_out_bytes[0:5];
    wire [7:0]sd_data_buffer_out_bytes[0:511];
    genvar sd_cmd_i;
    generate
        for (sd_cmd_i = 0; sd_cmd_i < 6; sd_cmd_i = sd_cmd_i + 1) begin : gen_sd_cmd_buffers
            assign sd_cmd_buffer_in_flat[sd_cmd_i*8 +: 8] = sd_cmd_buffer[sd_cmd_i];
            assign sd_cmd_buffer_out_bytes[sd_cmd_i] = sd_cmd_buffer_out[sd_cmd_i*8 +: 8];
        end
    endgenerate

    // PS/2 stream occupies 0x...5800-0x...5801; reading either byte consumes.
    assign ps2_ren = (PS2_REG <= raddr1_buf) && (raddr1_buf < (PS2_REG + 27'd2)) && ren_buf;
    assign uart_tx_wen = (waddr_buf[26:2] == UART_TX_REG[26:2]) && wen_buf[waddr_buf[1:0]];
    assign uart_rx_ren = (raddr1_buf == UART_RX_REG) && ren_buf;

    genvar sd_data_i;
    generate
        for (sd_data_i = 0; sd_data_i < 512; sd_data_i = sd_data_i + 1) begin : gen_sd_data_buffers
            assign sd_data_buffer_in_flat[sd_data_i*8 +: 8] = sd_data_buffer[sd_data_i];
            assign sd_data_buffer_out_bytes[sd_data_i] = sd_data_buffer_out[sd_data_i*8 +: 8];
        end
    endgenerate

    reg [31:0]display_framebuffer_out;
    reg display_tile_entry_sel;
    reg [9:0]display_tile_pixel_x;
    reg [8:0]display_tile_pixel_y;
    reg [31:0]display_tilemap_out;
    reg [31:0]display_pixelbuffer_out;
    reg [9:0]display_bg_pixel_x;
    reg [9:0]display_screen_x;
    reg [9:0]display_screen_y;
    wire vga_in_hblank = (pixel_x_in >= 10'd640);
    wire vga_in_vblank = (pixel_y_in >= 10'd480);
    wire vga_frame_start = (pixel_x_in == 10'd0) && (pixel_y_in == 10'd0);

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
    wire [24:0] ram_word_idx_r0 = raddr0[26:2];
    wire [24:0] ram_word_idx_r1 = raddr1[26:2];
    wire [24:0] ram_word_idx_w = waddr[26:2];
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

    function [7:0]sd_read_byte;
        input [26:0]addr;
        reg [8:0]offset;
        begin
            if (addr == SD_START_REG) begin
                sd_read_byte = {7'b0, sd_busy};
            end else if (SD_CMD_BASE <= addr && addr <= SD_CMD_END) begin
                offset = {6'b0, addr[2:0]} - {6'b0, SD_CMD_BASE[2:0]};
                sd_read_byte = sd_cmd_buffer[offset[2:0]];
            end else if (SD_DATA_BASE <= addr && addr <= SD_DATA_END) begin
                offset = addr[8:0] - SD_DATA_BASE[8:0];
                sd_read_byte = sd_data_buffer[offset];
            end else begin
                sd_read_byte = 8'h00;
            end
        end
    endfunction
    function [31:0]sd_read_word;
        input [26:0]addr;
        reg [26:0]base;
        begin
            base = {addr[26:2], 2'b00};
            sd_read_word = {sd_read_byte(base + 27'd3), sd_read_byte(base + 27'd2),
                            sd_read_byte(base + 27'd1), sd_read_byte(base)};
        end
    endfunction
    wire [31:0]data0_out = ram_data0_out;
    wire sd_window_selected = ren_buf && (SD_CMD_BASE <= raddr1_buf) && (raddr1_buf <= SD_DATA_END);
    wire [31:0]data1_out =  sd_window_selected ? sd_read_word(raddr1_buf) :
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
    // ignore partial writes to counter address
    wire pit_we = wen[0] && wen[1] && wen[2] && wen[3] && waddr == PIT_START;

    pit pit(clk, clk_en,
        pit_we, wdata, pit_interrupt);

    sd_spi_controller sd_ctrl(
        .clk(clk),
        .clk_en(clk_en),
        .start(sd_start_strobe),
        .cmd_buffer_in(sd_cmd_buffer_in_flat),
        .data_buffer_in(sd_data_buffer_in_flat),
        .cmd_buffer_out(sd_cmd_buffer_out),
        .cmd_buffer_out_valid(sd_cmd_buffer_out_valid),
        .data_buffer_out(sd_data_buffer_out),
        .data_buffer_out_valid(sd_data_buffer_out_valid),
        .busy(sd_busy),
        .interrupt(sd_interrupt),
        .spi_cs(sd_spi_cs_int),
        .spi_clk(sd_spi_clk_int),
        .spi_mosi(sd_spi_mosi_int),
        .spi_miso(sd_spi_miso)
    );
    assign sd_spi_cs = sd_spi_cs_int;
    assign sd_spi_clk = sd_spi_clk_int;
    assign sd_spi_mosi = sd_spi_mosi_int;
    // interrupt bits: [4]=VGA vblank, [3]=SD, [0]=PIT
    assign interrupts = {11'd0, vga_vblank_irq, sd_irq_pending, 2'd0, pit_interrupt};

    wire scroll_debug = ($test$plusargs("scroll_debug") != 0);

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
      display_pixelbuffer_out <= pixel_buffer[display_bg_word_idx];
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
      // - Frame counter increments once per frame start.
      // - Interrupt pulses when entering vblank.
      vga_vblank_irq <= 1'b0;
      if (vga_in_vblank && !in_vblank_prev) begin
        vga_vblank_irq <= 1'b1;
      end
      if (vga_frame_start && !frame_start_prev) begin
        vga_frame_count <= vga_frame_count + 32'd1;
      end
      in_vblank_prev <= vga_in_vblank;
      frame_start_prev <= vga_frame_start;

      if (clk_en) begin
        raddr0_buf <= raddr0;
        raddr1_buf <= raddr1;
        waddr_buf <= waddr;

        wen_buf <= wen;
        ren_buf <= ren;

        ram_data0_out <= (raddr0 < RAM_END) ? ram[ram_word_idx_r0] : 32'd0;
        ram_data1_out <= (raddr1 < RAM_END) ? ram[ram_word_idx_r1] : 32'd0;
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
        pixelbuffer_data1_out <= pixel_buffer[pixel_frame_word_idx_r];

        sd_start_strobe <= 1'b0;
        if (sd_cmd_buffer_out_valid) begin
            for (sd_copy_idx = 0; sd_copy_idx < 6; sd_copy_idx = sd_copy_idx + 1) begin
                sd_cmd_buffer[sd_copy_idx] = sd_cmd_buffer_out_bytes[sd_copy_idx];
            end
        end
        if (sd_data_buffer_out_valid) begin
            for (sd_copy_idx = 0; sd_copy_idx < 512; sd_copy_idx = sd_copy_idx + 1) begin
                sd_data_buffer[sd_copy_idx] = sd_data_buffer_out_bytes[sd_copy_idx];
            end
        end
        if (sd_interrupt) begin
            sd_irq_pending <= 1'b1;
        end
        if (sd_start_pending && !sd_busy) begin
            sd_start_strobe <= 1'b1;
            sd_start_pending <= 1'b0;
            sd_irq_pending <= 1'b0;
        end

        rdata0 <= data0_out;
        rdata1 <= data1_out;

        if (pit_we) begin
            pit_cfg_reg <= wdata;
        end

        if (waddr < RAM_END) begin
            if (wen[0]) ram[ram_word_idx_w][7:0]   <= wdata[7:0];
            if (wen[1]) ram[ram_word_idx_w][15:8]  <= wdata[15:8];
            if (wen[2]) ram[ram_word_idx_w][23:16] <= wdata[23:16];
            if (wen[3]) ram[ram_word_idx_w][31:24] <= wdata[31:24];
        end else if (SPRITE_0_START <= waddr && waddr < SPRITE_1_START) begin
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
        end else if (PIXEL_FRAMEBUFFER_START <= waddr && waddr < PIXEL_FRAMEBUFFER_END) begin
            if (wen[0]) pixel_buffer[pixel_frame_word_idx_w][7:0]   <= wdata[7:0];
            if (wen[1]) pixel_buffer[pixel_frame_word_idx_w][15:8]  <= wdata[15:8];
            if (wen[2]) pixel_buffer[pixel_frame_word_idx_w][23:16] <= wdata[23:16];
            if (wen[3]) pixel_buffer[pixel_frame_word_idx_w][31:24] <= wdata[31:24];
        end
        if (scroll_debug && (waddr[26:2] == HSCROLL_REG[26:2])) begin
            $display("[scroll_debug] write scroll base=%h waddr=%h wdata=%h wen=%b", HSCROLL_REG, waddr, wdata, wen);
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
                if (scroll_byte_addr == SD_START_REG) begin
                    sd_start_pending <= 1'b1;
                    sd_irq_pending <= 1'b0;
                end else if (SD_CMD_BASE <= scroll_byte_addr && scroll_byte_addr <= SD_CMD_END) begin
                    sd_byte_offset = {6'b0, scroll_byte_addr[2:0]} - {6'b0, SD_CMD_BASE[2:0]};
                    sd_cmd_buffer[sd_byte_offset[2:0]] <= scroll_byte_data;
                end else if (SD_DATA_BASE <= scroll_byte_addr && scroll_byte_addr <= SD_DATA_END) begin
                    sd_byte_offset = scroll_byte_addr[8:0] - SD_DATA_BASE[8:0];
                    sd_data_buffer[sd_byte_offset] <= scroll_byte_data;
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

endmodule
