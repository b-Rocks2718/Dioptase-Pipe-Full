`timescale 1ps/1ps

module mem(input clk, input clk_en,
    input [17:0]raddr0, output reg [31:0]rdata0,
    input ren, input [17:0]raddr1, output reg [31:0]rdata1,
    input [3:0]wen, input [17:0]waddr, input [31:0]wdata,
    output ps2_ren, input [15:0]ps2_data_in,
    input [9:0]pixel_x_in, input [9:0]pixel_y_in, output [11:0]pixel,
    output reg [7:0]uart_tx_data, output uart_tx_wen,
    input [7:0]uart_rx_data, output uart_rx_ren,
    output [15:0]interrupts
);
    localparam PS2_REG = 18'h20000;
    localparam HSCROLL_REG = 18'h2fffc;
    localparam VSCROLL_REG = 18'h2fffe;
    localparam SCALE_REG = 18'h2fffb;
    localparam UART_TX_REG = 18'h20002;
    localparam UART_RX_REG = 18'h20003;
    localparam PIT_START = 18'h20004;

    localparam TILEMAP_START = 18'h2a000;
    localparam FRAMEBUFFER_START = 18'h2e000;
    localparam FRAMEBUFFER_END = 18'h2fe00;

    localparam SPRITE_0_START = 18'h26000;
    localparam SPRITE_1_START = 18'h26800;
    localparam SPRITE_2_START = 18'h27000;
    localparam SPRITE_3_START = 18'h27800;
    localparam SPRITE_4_START = 18'h28000;
    localparam SPRITE_5_START = 18'h28800;
    localparam SPRITE_6_START = 18'h29000;
    localparam SPRITE_7_START = 18'h29800;

    localparam SPRITE_0_X = 18'h2ffd0;
    localparam SPRITE_0_Y = 18'h2ffd2;
    localparam SPRITE_1_X = 18'h2ffd4;
    localparam SPRITE_1_Y = 18'h2ffd6;
    localparam SPRITE_2_X = 18'h2ffd8;
    localparam SPRITE_2_Y = 18'h2ffda;
    localparam SPRITE_3_X = 18'h2ffdc;
    localparam SPRITE_3_Y = 18'h2ffde;
    localparam SPRITE_4_X = 18'h2ffe0;
    localparam SPRITE_4_Y = 18'h2ffe2;
    localparam SPRITE_5_X = 18'h2ffe4;
    localparam SPRITE_5_Y = 18'h2ffe6;
    localparam SPRITE_6_X = 18'h2ffe8;
    localparam SPRITE_6_Y = 18'h2ffea;
    localparam SPRITE_7_X = 18'h2ffec;
    localparam SPRITE_7_Y = 18'h2ffee;

    // we got 1800Kb total on the Basys 3
    (* ram_style = "block" *) reg [31:0]ram[0:16'h7fff]; // 1049Kb (0x0000-0x1FFFF)

    // 131Kb (0x26000-0x29FFF)
    reg [31:0]sprite_0_data[0:16'h1ff];
    reg [31:0]sprite_1_data[0:16'h1ff];
    reg [31:0]sprite_2_data[0:16'h1ff];
    reg [31:0]sprite_3_data[0:16'h1ff];
    reg [31:0]sprite_4_data[0:16'h1ff];
    reg [31:0]sprite_5_data[0:16'h1ff];
    reg [31:0]sprite_6_data[0:16'h1ff];
    reg [31:0]sprite_7_data[0:16'h1ff];
    
    (* ram_style = "block" *) reg [31:0]tile_map[0:16'h0fff]; // 131Kb (0x2A000-0x2DFFF)
    (* ram_style = "block" *) reg [31:0]frame_buffer[0:16'h07ff]; // 7.5KB (0x2E000-0x2FDFF)

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
        end
    end

    reg [17:0]raddr0_buf;
    reg [17:0]raddr1_buf;
    reg [17:0]waddr_buf;
    reg ren_buf = 1'b0;

    reg [3:0]wen_buf;

    reg [31:0]ram_data0_out;
    reg [31:0]ram_data1_out;
    reg [31:0]tilemap_data0_out = 0;
    reg [31:0]tilemap_data1_out;
    reg [31:0]framebuffer_data0_out = 0;
    reg [31:0]framebuffer_data1_out;

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

    reg [7:0]scale_reg = 0;
    reg [15:0]vscroll_reg = 0;
    reg [15:0]hscroll_reg = 0;

    integer scroll_lane;
    reg [17:0]scroll_word_base;
    reg [17:0]scroll_byte_addr;
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

    reg use_sprite_0 = 0;
    reg use_sprite_1 = 0;
    reg use_sprite_2 = 0;
    reg use_sprite_3 = 0;
    reg use_sprite_4 = 0;
    reg use_sprite_5 = 0;
    reg use_sprite_6 = 0;                 
    reg use_sprite_7 = 0;

    assign ps2_ren = (raddr1_buf == PS2_REG) && ren_buf;
    assign uart_tx_wen = (waddr_buf[17:2] == UART_TX_REG[17:2]) && wen_buf[waddr_buf[1:0]];
    assign uart_rx_ren = (raddr1_buf == UART_RX_REG) && ren_buf;

    reg [31:0]display_framebuffer_out;
    reg [1:0]display_tile_index;
    reg pixel_index;
    reg [9:0]display_pixel_x;
    reg [8:0]display_pixel_y;
    reg [31:0]display_tilemap_out;

    wire [9:0]pixel_x = (pixel_x_in >> scale_reg) - hscroll_reg[9:0];
    wire [9:0]scaled_pixel_y_wide = pixel_y_in >> scale_reg;
    wire [8:0]pixel_y = scaled_pixel_y_wide[8:0] - vscroll_reg[8:0];

    // Display pixel retrieval
    wire [12:0] display_frame_addr = ({pixel_y[8:3], 7'b0} + {6'b0, pixel_x[9:3]}); // (x / 8 + y / 8 * 128) with 64 rows available
    wire [7:0] display_tile = 
      (display_tile_index == 2'd0) ? display_framebuffer_out[7:0] : 
      (display_tile_index == 2'd1) ? display_framebuffer_out[15:8] :
      (display_tile_index == 2'd2) ? display_framebuffer_out[23:16] :
      display_framebuffer_out[31:24];
    wire [15:0] pixel_idx = {2'b0, display_tile, 6'b0} + {10'b0, display_pixel_y[2:0], 3'b0} + {13'b0, display_pixel_x[2:0]}; // tile_idx * 64 + py % 8 * 8 + px % 8
    wire [31:0] pixel_word = 
      sprite_7_onscreen ? display_sprite_7_out : 
      sprite_6_onscreen ? display_sprite_6_out : 
      sprite_5_onscreen ? display_sprite_5_out : 
      sprite_4_onscreen ? display_sprite_4_out : 
      sprite_3_onscreen ? display_sprite_3_out : 
      sprite_2_onscreen ? display_sprite_2_out : 
      sprite_1_onscreen ? display_sprite_1_out : 
      sprite_0_onscreen ? display_sprite_0_out :
      display_tilemap_out;

    assign pixel = pixel_index ? pixel_word[27:16] : pixel_word[11:0];

    reg [31:0]display_sprite_0_out;
    reg [31:0]display_sprite_1_out;
    reg [31:0]display_sprite_2_out;
    reg [31:0]display_sprite_3_out;
    reg [31:0]display_sprite_4_out;
    reg [31:0]display_sprite_5_out;
    reg [31:0]display_sprite_6_out;
    reg [31:0]display_sprite_7_out;
    
    wire [9:0]display_sprite_addr = {display_pixel_y[4:0], display_pixel_x[4:0]};
    wire not_transparent_0 = ((pixel_index ? display_sprite_0_out[31:28] : display_sprite_0_out[15:12]) == 4'h0);
    wire not_transparent_1 = ((pixel_index ? display_sprite_1_out[31:28] : display_sprite_1_out[15:12]) == 4'h0);
    wire not_transparent_2 = ((pixel_index ? display_sprite_2_out[31:28] : display_sprite_2_out[15:12]) == 4'h0);
    wire not_transparent_3 = ((pixel_index ? display_sprite_3_out[31:28] : display_sprite_3_out[15:12]) == 4'h0);
    wire not_transparent_4 = ((pixel_index ? display_sprite_4_out[31:28] : display_sprite_4_out[15:12]) == 4'h0);
    wire not_transparent_5 = ((pixel_index ? display_sprite_5_out[31:28] : display_sprite_5_out[15:12]) == 4'h0);
    wire not_transparent_6 = ((pixel_index ? display_sprite_6_out[31:28] : display_sprite_6_out[15:12]) == 4'h0);
    wire not_transparent_7 = ((pixel_index ? display_sprite_7_out[31:28] : display_sprite_7_out[15:12]) == 4'h0);
    
    reg use_sprite_0_out;
    reg use_sprite_1_out;
    reg use_sprite_2_out;
    reg use_sprite_3_out;
    reg use_sprite_4_out;
    reg use_sprite_5_out;
    reg use_sprite_6_out;
    reg use_sprite_7_out;
    
    wire sprite_0_onscreen = use_sprite_0_out & not_transparent_0;
    wire sprite_1_onscreen = use_sprite_1_out & not_transparent_1;
    wire sprite_2_onscreen = use_sprite_2_out & not_transparent_2;
    wire sprite_3_onscreen = use_sprite_3_out & not_transparent_3;
    wire sprite_4_onscreen = use_sprite_4_out & not_transparent_4;
    wire sprite_5_onscreen = use_sprite_5_out & not_transparent_5;
    wire sprite_6_onscreen = use_sprite_6_out & not_transparent_6;
    wire sprite_7_onscreen = use_sprite_7_out & not_transparent_7;

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

    wire [31:0]data0_out = ram_data0_out;
    wire [31:0]data1_out =  raddr1_buf < PS2_REG ? ram_data1_out :
      (SPRITE_0_START <= raddr1_buf && raddr1_buf < SPRITE_1_START) ? sprite_0_data1_out :
      (SPRITE_1_START <= raddr1_buf && raddr1_buf < SPRITE_2_START) ? sprite_1_data1_out :
      (SPRITE_2_START <= raddr1_buf && raddr1_buf < SPRITE_3_START) ? sprite_2_data1_out :
      (SPRITE_3_START <= raddr1_buf && raddr1_buf < SPRITE_4_START) ? sprite_3_data1_out :
      (SPRITE_4_START <= raddr1_buf && raddr1_buf < SPRITE_5_START) ? sprite_4_data1_out :
      (SPRITE_5_START <= raddr1_buf && raddr1_buf < SPRITE_6_START) ? sprite_5_data1_out :
      (SPRITE_6_START <= raddr1_buf && raddr1_buf < SPRITE_7_START) ? sprite_6_data1_out :
      (SPRITE_7_START <= raddr1_buf && raddr1_buf < TILEMAP_START) ? sprite_7_data1_out :
      (TILEMAP_START <= raddr1_buf && raddr1_buf < FRAMEBUFFER_START) ? tilemap_data1_out :
      (FRAMEBUFFER_START <= raddr1_buf && raddr1_buf < FRAMEBUFFER_END) ? framebuffer_data1_out :
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
                            raddr1_buf == SCALE_REG ? {24'b0, scale_reg} :
                            raddr1_buf == HSCROLL_REG ? {16'b0, hscroll_reg} :
                            raddr1_buf == VSCROLL_REG ? {vscroll_reg, 16'b0} :
                            raddr1_buf == PS2_REG ? {16'b0, ps2_data_in} :
                            raddr1_buf == UART_RX_REG ? {uart_rx_data, uart_rx_data, uart_rx_data, uart_rx_data} :
                            32'h0;

    wire pit_interrupt;
    // ignore partial writes to counter address
    wire pit_we = wen[0] && wen[1] && wen[2] && wen[3] && waddr == PIT_START;

    pit pit(clk, clk_en,
        pit_we, wdata, pit_interrupt);

    assign interrupts = {15'd0, pit_interrupt};

    wire scroll_debug = ($test$plusargs("scroll_debug") != 0);

    always @(posedge clk) begin
      display_framebuffer_out <= frame_buffer[display_frame_addr[12:2]];
      display_tile_index <= display_frame_addr[1:0];
      display_pixel_x <= pixel_x;
      display_pixel_y <= pixel_y;
      display_tilemap_out <= tile_map[pixel_idx[12:1]];
      pixel_index <= pixel_idx[0];

      display_sprite_0_out <= sprite_0_data[display_sprite_addr[9:1]];
      display_sprite_1_out <= sprite_1_data[display_sprite_addr[9:1]];
      display_sprite_2_out <= sprite_2_data[display_sprite_addr[9:1]];
      display_sprite_3_out <= sprite_3_data[display_sprite_addr[9:1]];
      display_sprite_4_out <= sprite_4_data[display_sprite_addr[9:1]];
      display_sprite_5_out <= sprite_5_data[display_sprite_addr[9:1]];
      display_sprite_6_out <= sprite_6_data[display_sprite_addr[9:1]];
      display_sprite_7_out <= sprite_7_data[display_sprite_addr[9:1]];

      use_sprite_0 <= (sprite_0_x <= pixel_x_in) & (pixel_x_in < sprite_0_x + 10'h20) &
                       (sprite_0_y <= pixel_y_in) & (pixel_y_in < sprite_0_y + 10'h20);
      use_sprite_1 <= (sprite_1_x <= pixel_x_in) & (pixel_x_in < sprite_1_x + 10'h20) &
                       (sprite_1_y <= pixel_y_in) & (pixel_y_in < sprite_1_y + 10'h20);
      use_sprite_2 <= (sprite_2_x <= pixel_x_in) & (pixel_x_in < sprite_2_x + 10'h20) &
                       (sprite_2_y <= pixel_y_in) & (pixel_y_in < sprite_2_y + 10'h20);
      use_sprite_3 <= (sprite_3_x <= pixel_x_in) & (pixel_x_in < sprite_3_x + 10'h20) &
                       (sprite_3_y <= pixel_y_in) & (pixel_y_in < sprite_3_y + 10'h20);
      use_sprite_4 <= (sprite_4_x <= pixel_x_in) & (pixel_x_in < sprite_4_x + 10'h20) &
                       (sprite_4_y <= pixel_y_in) & (pixel_y_in < sprite_4_y + 10'h20);
      use_sprite_5 <= (sprite_5_x <= pixel_x_in) & (pixel_x_in < sprite_5_x + 10'h20) &
                       (sprite_5_y <= pixel_y_in) & (pixel_y_in < sprite_5_y + 10'h20);
      use_sprite_6 <= (sprite_6_x <= pixel_x_in) & (pixel_x_in < sprite_6_x + 10'h20) &
                       (sprite_6_y <= pixel_y_in) & (pixel_y_in < sprite_6_y + 10'h20);
      use_sprite_7 <= (sprite_7_x <= pixel_x_in) & (pixel_x_in < sprite_7_x + 10'h20) &
                       (sprite_7_y <= pixel_y_in) & (pixel_y_in < sprite_7_y + 10'h20);
                     
      use_sprite_0_out <= use_sprite_0;
      use_sprite_1_out <= use_sprite_1;
      use_sprite_2_out <= use_sprite_2;
      use_sprite_3_out <= use_sprite_3;
      use_sprite_4_out <= use_sprite_4;
      use_sprite_5_out <= use_sprite_5;
      use_sprite_6_out <= use_sprite_6;
      use_sprite_7_out <= use_sprite_7;

      if (clk_en) begin
        raddr0_buf <= raddr0;
        raddr1_buf <= raddr1;
        waddr_buf <= waddr;

        wen_buf <= wen;
        ren_buf <= ren;

        ram_data0_out <= ram[raddr0[16:2]];
        ram_data1_out <= ram[raddr1[16:2]];
        sprite_0_data1_out <= sprite_0_data[raddr1[10:2]];
        sprite_1_data1_out <= sprite_1_data[raddr1[10:2]];
        sprite_2_data1_out <= sprite_2_data[raddr1[10:2]];
        sprite_3_data1_out <= sprite_3_data[raddr1[10:2]];
        sprite_4_data1_out <= sprite_4_data[raddr1[10:2]];
        sprite_5_data1_out <= sprite_5_data[raddr1[10:2]];
        sprite_6_data1_out <= sprite_6_data[raddr1[10:2]];
        sprite_7_data1_out <= sprite_7_data[raddr1[10:2]];
        tilemap_data1_out <= tile_map[raddr1[13:2] - TILEMAP_START[13:2]];
        framebuffer_data1_out <= frame_buffer[raddr1[12:2]];

        rdata0 <= data0_out;
        rdata1 <= data1_out;

        //(SPRITE_0_START <= raddr1_buf && raddr1_buf < SPRITE_1_START) ? sprite_0_data1_out :
        //(SPRITE_1_START <= raddr1_buf && raddr1_buf < SPRITE_2_START) ? sprite_1_data1_out :
        //(SPRITE_2_START <= raddr1_buf && raddr1_buf < SPRITE_3_START) ? sprite_2_data1_out :
        //(SPRITE_3_START <= raddr1_buf && raddr1_buf < SPRITE_4_START) ? sprite_3_data1_out :
        //(SPRITE_4_START <= raddr1_buf && raddr1_buf < SPRITE_5_START) ? sprite_4_data1_out :
        //(SPRITE_5_START <= raddr1_buf && raddr1_buf < SPRITE_6_START) ? sprite_5_data1_out :
        //(SPRITE_6_START <= raddr1_buf && raddr1_buf < SPRITE_7_START) ? sprite_6_data1_out :
        //(SPRITE_7_START <= raddr1_buf && raddr1_buf < TILEMAP_START) ? sprite_7_data1_out :

        if (waddr < PS2_REG) begin
            if (wen[0]) ram[waddr[16:2]][7:0]   <= wdata[7:0];
            if (wen[1]) ram[waddr[16:2]][15:8]  <= wdata[15:8];
            if (wen[2]) ram[waddr[16:2]][23:16] <= wdata[23:16];
            if (wen[3]) ram[waddr[16:2]][31:24] <= wdata[31:24];
        end else if (SPRITE_0_START <= waddr && waddr < SPRITE_1_START) begin
            if (wen[0]) sprite_0_data[waddr[10:2]][7:0]   <= wdata[7:0];
            if (wen[1]) sprite_0_data[waddr[10:2]][15:8]  <= wdata[15:8];
            if (wen[2]) sprite_0_data[waddr[10:2]][23:16] <= wdata[23:16];
            if (wen[3]) sprite_0_data[waddr[10:2]][31:24] <= wdata[31:24];
        end else if (SPRITE_1_START <= waddr && waddr < SPRITE_2_START) begin
            if (wen[0]) sprite_1_data[waddr[10:2]][7:0]   <= wdata[7:0];
            if (wen[1]) sprite_1_data[waddr[10:2]][15:8]  <= wdata[15:8];
            if (wen[2]) sprite_1_data[waddr[10:2]][23:16] <= wdata[23:16];
            if (wen[3]) sprite_1_data[waddr[10:2]][31:24] <= wdata[31:24];
        end else if (SPRITE_2_START <= waddr && waddr < SPRITE_3_START) begin
            if (wen[0]) sprite_2_data[waddr[10:2]][7:0]   <= wdata[7:0];
            if (wen[1]) sprite_2_data[waddr[10:2]][15:8]  <= wdata[15:8];
            if (wen[2]) sprite_2_data[waddr[10:2]][23:16] <= wdata[23:16];
            if (wen[3]) sprite_2_data[waddr[10:2]][31:24] <= wdata[31:24];
        end else if (SPRITE_3_START <= waddr && waddr < SPRITE_4_START) begin
            if (wen[0]) sprite_3_data[waddr[10:2]][7:0]   <= wdata[7:0];
            if (wen[1]) sprite_3_data[waddr[10:2]][15:8]  <= wdata[15:8];
            if (wen[2]) sprite_3_data[waddr[10:2]][23:16] <= wdata[23:16];
            if (wen[3]) sprite_3_data[waddr[10:2]][31:24] <= wdata[31:24];
        end else if (SPRITE_4_START <= waddr && waddr < SPRITE_5_START) begin
            if (wen[0]) sprite_4_data[waddr[10:2]][7:0]   <= wdata[7:0];
            if (wen[1]) sprite_4_data[waddr[10:2]][15:8]  <= wdata[15:8];
            if (wen[2]) sprite_4_data[waddr[10:2]][23:16] <= wdata[23:16];
            if (wen[3]) sprite_4_data[waddr[10:2]][31:24] <= wdata[31:24];
        end else if (SPRITE_5_START <= waddr && waddr < SPRITE_6_START) begin
            if (wen[0]) sprite_5_data[waddr[10:2]][7:0]   <= wdata[7:0];
            if (wen[1]) sprite_5_data[waddr[10:2]][15:8]  <= wdata[15:8];
            if (wen[2]) sprite_5_data[waddr[10:2]][23:16] <= wdata[23:16];
            if (wen[3]) sprite_5_data[waddr[10:2]][31:24] <= wdata[31:24];
        end else if (SPRITE_6_START <= waddr && waddr < SPRITE_7_START) begin
            if (wen[0]) sprite_6_data[waddr[10:2]][7:0]   <= wdata[7:0];
            if (wen[1]) sprite_6_data[waddr[10:2]][15:8]  <= wdata[15:8];
            if (wen[2]) sprite_6_data[waddr[10:2]][23:16] <= wdata[23:16];
            if (wen[3]) sprite_6_data[waddr[10:2]][31:24] <= wdata[31:24];
        end else if (SPRITE_7_START <= waddr && waddr < TILEMAP_START) begin
            if (wen[0]) sprite_7_data[waddr[10:2]][7:0]   <= wdata[7:0];
            if (wen[1]) sprite_7_data[waddr[10:2]][15:8]  <= wdata[15:8];
            if (wen[2]) sprite_7_data[waddr[10:2]][23:16] <= wdata[23:16];
            if (wen[3]) sprite_7_data[waddr[10:2]][31:24] <= wdata[31:24];
        end else if (TILEMAP_START <= waddr && waddr < FRAMEBUFFER_START) begin
            if (wen[0]) tile_map[waddr[13:2] - TILEMAP_START[13:2]][7:0]   <= wdata[7:0];
            if (wen[1]) tile_map[waddr[13:2] - TILEMAP_START[13:2]][15:8]  <= wdata[15:8];
            if (wen[2]) tile_map[waddr[13:2] - TILEMAP_START[13:2]][23:16] <= wdata[23:16];
            if (wen[3]) tile_map[waddr[13:2] - TILEMAP_START[13:2]][31:24] <= wdata[31:24];
        end else if (FRAMEBUFFER_START <= waddr && waddr < FRAMEBUFFER_END) begin
            if (wen[0]) frame_buffer[waddr[12:2]][7:0]   <= wdata[7:0];
            if (wen[1]) frame_buffer[waddr[12:2]][15:8]  <= wdata[15:8];
            if (wen[2]) frame_buffer[waddr[12:2]][23:16] <= wdata[23:16];
            if (wen[3]) frame_buffer[waddr[12:2]][31:24] <= wdata[31:24];
        end
        if (scroll_debug && (waddr[17:2] == HSCROLL_REG[17:2])) begin
            $display("[scroll_debug] write scroll base=%h waddr=%h wdata=%h wen=%b", HSCROLL_REG, waddr, wdata, wen);
        end
        scroll_word_base = {waddr[17:2], 2'b00};
        for (scroll_lane = 0; scroll_lane < 4; scroll_lane = scroll_lane + 1) begin
            if (wen[scroll_lane]) begin
                case (scroll_lane)
                    0: begin scroll_byte_addr = scroll_word_base; scroll_byte_data = wdata[7:0]; end
                    1: begin scroll_byte_addr = scroll_word_base + 18'd1; scroll_byte_data = wdata[15:8]; end
                    2: begin scroll_byte_addr = scroll_word_base + 18'd2; scroll_byte_data = wdata[23:16]; end
                    default: begin scroll_byte_addr = scroll_word_base + 18'd3; scroll_byte_data = wdata[31:24]; end
                endcase

                if (scroll_byte_addr == SCALE_REG)
                    scale_reg <= scroll_byte_data;
                else if (scroll_byte_addr == HSCROLL_REG)
                    hscroll_reg[7:0] <= scroll_byte_data;
                else if (scroll_byte_addr == HSCROLL_REG + 18'd1)
                    hscroll_reg[15:8] <= scroll_byte_data;
                else if (scroll_byte_addr == VSCROLL_REG)
                    vscroll_reg[7:0] <= scroll_byte_data;
                else if (scroll_byte_addr == VSCROLL_REG + 18'd1)
                    vscroll_reg[15:8] <= scroll_byte_data;
            end
        end
        if ((waddr[17:2] == UART_TX_REG[17:2]) && wen[waddr[1:0]]) begin
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
      end
    end

endmodule
