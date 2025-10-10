`timescale 1ps/1ps

module mem(input clk, input clk_en,
    input [17:0]raddr0, output reg [31:0]rdata0,
    input [17:0]raddr1, output reg [31:0]rdata1,
    input [3:0]wen, input [17:0]waddr, input [31:0]wdata,
    output ps2_ren, input [15:0]ps2_data_in,
    input [9:0]pixel_x_in, input [9:0]pixel_y_in, output [11:0]pixel,
    output reg [7:0]uart_tx_data, output uart_tx_wen,
    input [7:0]uart_rx_data, output uart_rx_ren,
    output [15:0]interrupts
);
    localparam PS2_REG = 18'h20000;
    localparam VSCROLL_REG = 18'h2fffc;
    localparam HSCROLL_REG = 18'h2fffe;
    localparam SCALE_REG = 18'h2fffb;
    localparam UART_TX_REG = 18'h20002;
    localparam UART_RX_REG = 18'h20003;
    localparam PIT_START = 18'h20004;

    localparam TILEMAP_START = 18'h2a000;
    localparam FRAMEBUFFER_START = 18'h2e000;
    localparam FRAMEBUFFER_END = 18'h2f2c0;

    // we got 1800Kb total on the Basys 3
    (* ram_style = "block" *) reg [31:0]ram[0:16'h7fff]; // 1049Kb (0x0000-0x7FFF)
    (* ram_style = "block" *) reg [31:0]sprite_map[0:16'h1000]; // 131Kb (0x26000-0x29FFF)
    (* ram_style = "block" *) reg [31:0]tile_map[0:16'h1000]; // 131Kb (0x2A000-0x2DFFF)
    (* ram_style = "block" *) reg [31:0]frame_buffer[0:16'h0800]; // 65Kb (0x2E000-0x2FFFF)

    reg [1023:0] hexfile; // buffer for filename

    initial begin
        if (!$value$plusargs("hex=%s", hexfile)) begin
            $display("ERROR: no +hex=<file> argument given!");
            $finish;
        end
        $readmemh(hexfile, ram);  // mem is your instruction/data memory
    end

    reg [17:0]raddr0_buf;
    reg [17:0]raddr1_buf;
    reg [17:0]waddr_buf;

    reg [3:0]wen_buf;

    reg [31:0]ram_data0_out;
    reg [31:0]ram_data1_out;
    reg [31:0]tilemap_data0_out = 0;
    reg [31:0]tilemap_data1_out;
    reg [31:0]framebuffer_data0_out = 0;
    reg [31:0]framebuffer_data1_out;

    reg [7:0]scale_reg = 0;
    reg [15:0]vscroll_reg = 0;
    reg [15:0]hscroll_reg = 0;

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


    assign ps2_ren = raddr1_buf == PS2_REG;
    assign uart_tx_wen = (waddr_buf[17:2] == UART_TX_REG[17:2]) && wen_buf[waddr_buf[1:0]];
    assign uart_rx_ren = raddr1_buf == UART_RX_REG;

    reg [31:0]display_framebuffer_out;
    reg [1:0]display_tile_index;
    reg pixel_index;
    reg [9:0]display_pixel_x;
    reg [9:0]display_pixel_y;
    reg [31:0]display_tilemap_out;

    wire [9:0]pixel_x = (pixel_x_in >> scale_reg) - hscroll_reg[9:0];
    wire [9:0]pixel_y = (pixel_y_in >> scale_reg) - vscroll_reg[9:0];

    // Display pixel retrevial
    wire [15:0] display_frame_addr = ({9'b0, pixel_x[9:3]} + {2'b0, pixel_y[9:3], 7'b0}); // (x / 8 + y / 8 * 128)
    wire [7:0] display_tile = 
      (display_tile_index == 2'd0) ? display_framebuffer_out[7:0] : 
      (display_tile_index == 2'd1) ? display_framebuffer_out[15:8] :
      (display_tile_index == 2'd2) ? display_framebuffer_out[23:16] :
      display_framebuffer_out[31:24];
    wire [15:0] pixel_idx = {2'b0, display_tile, 6'b0} + {10'b0, display_pixel_y[2:0], 3'b0} + {13'b0, display_pixel_x[2:0]}; // tile_idx * 64 + py % 8 * 8 + px % 8
    assign pixel = pixel_index ? display_tilemap_out[27:16] : display_tilemap_out[11:0];

    wire [31:0]data0_out =  raddr0_buf < PS2_REG ? ram_data0_out :
      (TILEMAP_START <= raddr0_buf && raddr0_buf < FRAMEBUFFER_START) ? tilemap_data0_out :
      (FRAMEBUFFER_START <= raddr0_buf && raddr0_buf < FRAMEBUFFER_END) ? framebuffer_data0_out :
                            raddr0_buf == SCALE_REG ? {24'b0, scale_reg} :
                            raddr0_buf == HSCROLL_REG ? {16'b0, hscroll_reg} :
                            raddr0_buf == VSCROLL_REG ?{16'b0, vscroll_reg} :
                            raddr0_buf == PS2_REG ? {24'b0, ps2_data_in[7:0]} :
                            raddr0_buf == UART_RX_REG ? {uart_rx_data, uart_rx_data, uart_rx_data, uart_rx_data} :
                            32'h0;
    wire [31:0]data1_out =  raddr1_buf < PS2_REG ? ram_data1_out :
      (TILEMAP_START <= raddr1_buf && raddr1_buf < FRAMEBUFFER_START) ? tilemap_data1_out :
      (FRAMEBUFFER_START <= raddr1_buf && raddr1_buf < FRAMEBUFFER_END) ? framebuffer_data1_out :
                            raddr1_buf == SCALE_REG ? {24'b0, scale_reg} :
                            raddr1_buf == HSCROLL_REG ? {16'b0, hscroll_reg} :
                            raddr1_buf == VSCROLL_REG ? {16'b0, vscroll_reg} :
                            raddr1_buf == PS2_REG ? {24'b0, ps2_data_in[7:0]} :
                            raddr1_buf == UART_RX_REG ? {uart_rx_data, uart_rx_data, uart_rx_data, uart_rx_data} :
                            32'h0;

    wire pit_interrupt;
    // ignore partial writes to counter address
    wire pit_we = wen[0] && wen[1] && wen[2] && wen[3] && waddr == PIT_START;

    pit pit(clk, clk_en,
        pit_we, wdata, pit_interrupt);

    assign interrupts = {15'd0, pit_interrupt};

    always @(posedge clk) begin
      display_framebuffer_out <= frame_buffer[display_frame_addr[13:2]];
      display_tile_index <= display_frame_addr[1:0];
      display_pixel_x <= pixel_x;
      display_pixel_y <= pixel_y;
      display_tilemap_out <= tile_map[pixel_idx[13:1]];
      pixel_index <= pixel_idx[0];

      if (clk_en) begin
        raddr0_buf <= raddr0;
        raddr1_buf <= raddr1;
        waddr_buf <= waddr;

        wen_buf <= wen;

        ram_data0_out <= ram[raddr0[16:2]];
        ram_data1_out <= ram[raddr1[16:2]];
        tilemap_data1_out <= tile_map[raddr1[14:2] - TILEMAP_START[14:2]];
        framebuffer_data1_out <= frame_buffer[raddr1[13:2] - FRAMEBUFFER_START[13:2]];

        rdata0 <= data0_out;
        rdata1 <= data1_out;

        if (waddr < PS2_REG) begin
            if (wen[0]) ram[waddr[16:2]][7:0]   <= wdata[7:0];
            if (wen[1]) ram[waddr[16:2]][15:8]  <= wdata[15:8];
            if (wen[2]) ram[waddr[16:2]][23:16] <= wdata[23:16];
            if (wen[3]) ram[waddr[16:2]][31:24] <= wdata[31:24];
        end else if (TILEMAP_START <= waddr && waddr < FRAMEBUFFER_START) begin
            if (wen[0]) tile_map[waddr[14:2] - TILEMAP_START[14:2]][7:0]   <= wdata[7:0];
            if (wen[1]) tile_map[waddr[14:2] - TILEMAP_START[14:2]][15:8]  <= wdata[15:8];
            if (wen[2]) tile_map[waddr[14:2] - TILEMAP_START[14:2]][23:16] <= wdata[23:16];
            if (wen[3]) tile_map[waddr[14:2] - TILEMAP_START[14:2]][31:24] <= wdata[31:24];
        end else if (FRAMEBUFFER_START <= waddr && waddr < FRAMEBUFFER_END) begin
            if (wen[0]) frame_buffer[waddr[13:2] - FRAMEBUFFER_START[13:2]][7:0]   <= wdata[7:0];
            if (wen[1]) frame_buffer[waddr[13:2] - FRAMEBUFFER_START[13:2]][15:8]  <= wdata[15:8];
            if (wen[2]) frame_buffer[waddr[13:2] - FRAMEBUFFER_START[13:2]][23:16] <= wdata[23:16];
            if (wen[3]) frame_buffer[waddr[13:2] - FRAMEBUFFER_START[13:2]][31:24] <= wdata[31:24];
        end
        if (waddr == SCALE_REG && wen[0]) begin 
            scale_reg <= wdata[7:0];
        end
        if (waddr == HSCROLL_REG) begin
            if (wen[0]) hscroll_reg[7:0] <= wdata[7:0];
            if (wen[1]) hscroll_reg[15:8] <= wdata[15:8];
        end
        if (waddr == VSCROLL_REG) begin
            if (wen[0]) vscroll_reg[7:0] <= wdata[7:0];
            if (wen[1]) vscroll_reg[15:8] <= wdata[15:8];
        end
        if ((waddr[17:2] == UART_TX_REG[17:2]) && wen[waddr[1:0]]) begin
            uart_tx_data <= select_lane_byte(wdata, waddr[1:0]);
        end
      end
    end

endmodule
