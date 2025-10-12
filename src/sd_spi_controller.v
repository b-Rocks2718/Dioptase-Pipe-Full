`timescale 1ps/1ps

module sd_spi_controller(
    input clk,
    input clk_en,
    input start,
    input [47:0] cmd_buffer_in,
    input [4095:0] data_buffer_in,
    output reg [47:0] cmd_buffer_out,
    output reg cmd_buffer_out_valid,
    output reg [4095:0] data_buffer_out,
    output reg data_buffer_out_valid,
    output reg busy,
    output reg interrupt,
    output reg spi_cs,
    output reg spi_clk,
    output reg spi_mosi,
    input spi_miso
);

    localparam STATE_IDLE            = 4'd0;
    localparam STATE_SEND_CMD        = 4'd1;
    localparam STATE_WAIT_RESP       = 4'd2;
    localparam STATE_READ_RESP       = 4'd3;
    localparam STATE_WAIT_TOKEN      = 4'd4;
    localparam STATE_READ_DATA       = 4'd5;
    localparam STATE_READ_CRC        = 4'd6;
    localparam STATE_SEND_TOKEN      = 4'd7;
    localparam STATE_WRITE_DATA      = 4'd8;
    localparam STATE_WRITE_CRC       = 4'd9;
    localparam STATE_DATA_RESPONSE   = 4'd10;
    localparam STATE_DONE            = 4'd11;

    localparam DATA_TOKEN            = 8'hFE;

    function [7:0] get_cmd_byte;
        input [47:0] data;
        input [2:0] index;
        begin
            case (index)
                3'd0: get_cmd_byte = data[7:0];
                3'd1: get_cmd_byte = data[15:8];
                3'd2: get_cmd_byte = data[23:16];
                3'd3: get_cmd_byte = data[31:24];
                3'd4: get_cmd_byte = data[39:32];
                3'd5: get_cmd_byte = data[47:40];
                default: get_cmd_byte = 8'hFF;
            endcase
        end
    endfunction

    function [7:0] get_data_byte;
        input [4095:0] data;
        input [8:0] index;
        begin
            get_data_byte = data[index*8 +: 8];
        end
    endfunction

    reg [3:0] state = STATE_IDLE;
    reg [47:0] cmd_latched = 48'd0;
    reg [47:0] cmd_response = 48'd0;
    reg [4095:0] data_capture = 4096'd0;
    reg [4095:0] data_shadow = 4096'd0;
    reg [5:0] current_cmd = 6'd0;
    reg [31:0] current_arg = 32'd0;
    reg is_read_block = 1'b0;
    reg is_write_block = 1'b0;
    reg [2:0] extra_resp_bytes = 3'd0;

    reg [7:0] tx_shift = 8'hFF;
    reg [7:0] rx_shift = 8'hFF;
    reg [2:0] bit_count = 3'd0;
    reg bit_phase = 1'b0;
    reg byte_ready = 1'b0;
    reg [2:0] cmd_byte_index = 3'd0;
    reg [2:0] resp_index = 3'd0;
    reg [8:0] data_index = 9'd0;
    reg [1:0] crc_index = 2'd0;
    reg [7:0] wait_counter = 8'd0;

    wire [7:0] cmd_byte0 = cmd_buffer_in[7:0];
    wire [7:0] cmd_byte1 = cmd_buffer_in[15:8];
    wire [7:0] cmd_byte2 = cmd_buffer_in[23:16];
    wire [7:0] cmd_byte3 = cmd_buffer_in[31:24];
    wire [7:0] cmd_byte4 = cmd_buffer_in[39:32];
    wire [7:0] cmd_byte5 = cmd_buffer_in[47:40];
    wire [5:0] cmd_index_in = cmd_byte0[5:0];
    wire [31:0] cmd_arg_in = {cmd_byte1, cmd_byte2, cmd_byte3, cmd_byte4};

    initial begin
        busy = 1'b0;
        interrupt = 1'b0;
        spi_cs = 1'b1;
        spi_clk = 1'b0;
        spi_mosi = 1'b1;
        cmd_buffer_out = 48'd0;
        cmd_buffer_out_valid = 1'b0;
        data_buffer_out = 4096'd0;
        data_buffer_out_valid = 1'b0;
    end

    always @(posedge clk) begin
        if (!clk_en) begin
            interrupt <= 1'b0;
            cmd_buffer_out_valid <= 1'b0;
            data_buffer_out_valid <= 1'b0;
        end else begin
            interrupt <= 1'b0;
            cmd_buffer_out_valid <= 1'b0;
            data_buffer_out_valid <= 1'b0;
            byte_ready <= 1'b0;

            case (state)
                STATE_IDLE: begin
                    busy <= 1'b0;
                    spi_cs <= 1'b1;
                    spi_clk <= 1'b0;
                    spi_mosi <= 1'b1;
                    bit_phase <= 1'b0;
                    bit_count <= 3'd0;
                    if (start) begin
                        busy <= 1'b1;
                        spi_cs <= 1'b0;
                        state <= STATE_SEND_CMD;
                        cmd_latched <= cmd_buffer_in;
                        data_shadow <= data_buffer_in;
                        data_capture <= 4096'd0;
                        cmd_response <= 48'd0;
                        current_cmd <= cmd_index_in;
                        current_arg <= cmd_arg_in;
                        extra_resp_bytes <= ((cmd_index_in == 6'd8) || (cmd_index_in == 6'd58)) ? 3'd4 : 3'd0;
                        is_read_block <= (cmd_index_in == 6'd17);
                        is_write_block <= (cmd_index_in == 6'd24);
                        cmd_byte_index <= 3'd0;
                        resp_index <= 3'd0;
                        data_index <= 9'd0;
                        crc_index <= 2'd0;
                        wait_counter <= 8'd0;
                        tx_shift <= cmd_byte0;
                        bit_phase <= 1'b0;
                        bit_count <= 3'd0;
                    end
                end

                STATE_SEND_CMD: begin
                    if (bit_phase == 1'b0) begin
                        spi_clk <= 1'b0;
                        spi_mosi <= tx_shift[7];
                        tx_shift <= {tx_shift[6:0], 1'b0};
                        bit_phase <= 1'b1;
                    end else begin
                        spi_clk <= 1'b1;
                        rx_shift <= {rx_shift[6:0], spi_miso};
                        bit_phase <= 1'b0;
                        if (bit_count == 3'd7) begin
                            bit_count <= 3'd0;
                            byte_ready <= 1'b1;
                        end else begin
                            bit_count <= bit_count + 3'd1;
                        end
                    end

                    if (byte_ready) begin
                        if (cmd_byte_index == 3'd5) begin
                            state <= STATE_WAIT_RESP;
                            tx_shift <= 8'hFF;
                            wait_counter <= 8'd0;
                        end else begin
                            cmd_byte_index <= cmd_byte_index + 3'd1;
                            tx_shift <= get_cmd_byte(cmd_latched, cmd_byte_index + 3'd1);
                        end
                    end
                end

                STATE_WAIT_RESP: begin
                    if (bit_phase == 1'b0) begin
                        spi_clk <= 1'b0;
                        spi_mosi <= tx_shift[7];
                        tx_shift <= {tx_shift[6:0], 1'b0};
                        bit_phase <= 1'b1;
                    end else begin
                        spi_clk <= 1'b1;
                        rx_shift <= {rx_shift[6:0], spi_miso};
                        bit_phase <= 1'b0;
                        if (bit_count == 3'd7) begin
                            bit_count <= 3'd0;
                            byte_ready <= 1'b1;
                        end else begin
                            bit_count <= bit_count + 3'd1;
                        end
                    end

                    if (byte_ready) begin
                        wait_counter <= wait_counter + 8'd1;
                        if (rx_shift != 8'hFF) begin
                            cmd_response[7:0] <= rx_shift;
                            if (extra_resp_bytes != 3'd0) begin
                                resp_index <= 3'd0;
                                state <= STATE_READ_RESP;
                            end else if (is_read_block) begin
                                state <= STATE_WAIT_TOKEN;
                                wait_counter <= 8'd0;
                            end else if (is_write_block) begin
                                state <= STATE_SEND_TOKEN;
                                tx_shift <= DATA_TOKEN;
                            end else begin
                                state <= STATE_DONE;
                                cmd_buffer_out <= cmd_response;
                                cmd_buffer_out_valid <= 1'b1;
                                interrupt <= 1'b1;
                                spi_cs <= 1'b1;
                                spi_clk <= 1'b0;
                                spi_mosi <= 1'b1;
                                busy <= 1'b0;
                            end
                        end else if (wait_counter == 8'hFF) begin
                            cmd_response[7:0] <= 8'hFF;
                            state <= STATE_DONE;
                            cmd_buffer_out <= cmd_response;
                            cmd_buffer_out_valid <= 1'b1;
                            interrupt <= 1'b1;
                            spi_cs <= 1'b1;
                            spi_clk <= 1'b0;
                            spi_mosi <= 1'b1;
                            busy <= 1'b0;
                        end
                        tx_shift <= 8'hFF;
                    end
                end

                STATE_READ_RESP: begin
                    if (bit_phase == 1'b0) begin
                        spi_clk <= 1'b0;
                        spi_mosi <= 1'b1;
                        tx_shift <= {tx_shift[6:0], 1'b0};
                        bit_phase <= 1'b1;
                    end else begin
                        spi_clk <= 1'b1;
                        rx_shift <= {rx_shift[6:0], spi_miso};
                        bit_phase <= 1'b0;
                        if (bit_count == 3'd7) begin
                            bit_count <= 3'd0;
                            byte_ready <= 1'b1;
                        end else begin
                            bit_count <= bit_count + 3'd1;
                        end
                    end

                    if (byte_ready) begin
                        resp_index <= resp_index + 3'd1;
                        cmd_response[(resp_index + 3'd1)*8 +: 8] <= rx_shift;
                        if (resp_index + 3'd1 == extra_resp_bytes) begin
                            if (is_read_block) begin
                                state <= STATE_WAIT_TOKEN;
                                wait_counter <= 8'd0;
                            end else if (is_write_block) begin
                                state <= STATE_SEND_TOKEN;
                                tx_shift <= DATA_TOKEN;
                            end else begin
                                state <= STATE_DONE;
                                cmd_buffer_out <= cmd_response;
                                cmd_buffer_out_valid <= 1'b1;
                                interrupt <= 1'b1;
                                spi_cs <= 1'b1;
                                spi_clk <= 1'b0;
                                spi_mosi <= 1'b1;
                                busy <= 1'b0;
                            end
                        end else begin
                            tx_shift <= 8'hFF;
                        end
                    end
                end

                STATE_WAIT_TOKEN: begin
                    if (bit_phase == 1'b0) begin
                        spi_clk <= 1'b0;
                        spi_mosi <= 1'b1;
                        tx_shift <= {tx_shift[6:0], 1'b0};
                        bit_phase <= 1'b1;
                    end else begin
                        spi_clk <= 1'b1;
                        rx_shift <= {rx_shift[6:0], spi_miso};
                        bit_phase <= 1'b0;
                        if (bit_count == 3'd7) begin
                            bit_count <= 3'd0;
                            byte_ready <= 1'b1;
                        end else begin
                            bit_count <= bit_count + 3'd1;
                        end
                    end

                    if (byte_ready) begin
                        wait_counter <= wait_counter + 8'd1;
                        if (rx_shift == DATA_TOKEN) begin
                            state <= STATE_READ_DATA;
                            data_index <= 9'd0;
                            tx_shift <= 8'hFF;
                        end else if (wait_counter == 8'hFF) begin
                            state <= STATE_DONE;
                            cmd_response[7:0] <= 8'h05;
                            cmd_buffer_out <= cmd_response;
                            cmd_buffer_out_valid <= 1'b1;
                            interrupt <= 1'b1;
                            spi_cs <= 1'b1;
                            spi_clk <= 1'b0;
                            spi_mosi <= 1'b1;
                            busy <= 1'b0;
                        end else begin
                            tx_shift <= 8'hFF;
                        end
                    end
                end

                STATE_READ_DATA: begin
                    if (bit_phase == 1'b0) begin
                        spi_clk <= 1'b0;
                        spi_mosi <= 1'b1;
                        tx_shift <= {tx_shift[6:0], 1'b0};
                        bit_phase <= 1'b1;
                    end else begin
                        spi_clk <= 1'b1;
                        rx_shift <= {rx_shift[6:0], spi_miso};
                        bit_phase <= 1'b0;
                        if (bit_count == 3'd7) begin
                            bit_count <= 3'd0;
                            byte_ready <= 1'b1;
                        end else begin
                            bit_count <= bit_count + 3'd1;
                        end
                    end

                    if (byte_ready) begin
                        data_capture[data_index*8 +: 8] <= rx_shift;
                        data_index <= data_index + 9'd1;
                        if (data_index == 9'd511) begin
                            state <= STATE_READ_CRC;
                            crc_index <= 2'd0;
                            tx_shift <= 8'hFF;
                        end else begin
                            tx_shift <= 8'hFF;
                        end
                    end
                end

                STATE_READ_CRC: begin
                    if (bit_phase == 1'b0) begin
                        spi_clk <= 1'b0;
                        spi_mosi <= 1'b1;
                        tx_shift <= {tx_shift[6:0], 1'b0};
                        bit_phase <= 1'b1;
                    end else begin
                        spi_clk <= 1'b1;
                        rx_shift <= {rx_shift[6:0], spi_miso};
                        bit_phase <= 1'b0;
                        if (bit_count == 3'd7) begin
                            bit_count <= 3'd0;
                            byte_ready <= 1'b1;
                        end else begin
                            bit_count <= bit_count + 3'd1;
                        end
                    end

                    if (byte_ready) begin
                        crc_index <= crc_index + 2'd1;
                        if (crc_index == 2'd1) begin
                            state <= STATE_DONE;
                            data_buffer_out <= data_capture;
                            data_buffer_out_valid <= 1'b1;
                            cmd_buffer_out <= cmd_response;
                            cmd_buffer_out_valid <= 1'b1;
                            interrupt <= 1'b1;
                            spi_cs <= 1'b1;
                            spi_clk <= 1'b0;
                            spi_mosi <= 1'b1;
                            busy <= 1'b0;
                        end else begin
                            tx_shift <= 8'hFF;
                        end
                    end
                end

                STATE_SEND_TOKEN: begin
                    if (bit_phase == 1'b0) begin
                        spi_clk <= 1'b0;
                        spi_mosi <= tx_shift[7];
                        tx_shift <= {tx_shift[6:0], 1'b0};
                        bit_phase <= 1'b1;
                    end else begin
                        spi_clk <= 1'b1;
                        rx_shift <= {rx_shift[6:0], spi_miso};
                        bit_phase <= 1'b0;
                        if (bit_count == 3'd7) begin
                            bit_count <= 3'd0;
                            byte_ready <= 1'b1;
                        end else begin
                            bit_count <= bit_count + 3'd1;
                        end
                    end

                    if (byte_ready) begin
                        state <= STATE_WRITE_DATA;
                        data_index <= 9'd0;
                        tx_shift <= get_data_byte(data_shadow, 9'd0);
                    end
                end

                STATE_WRITE_DATA: begin
                    if (bit_phase == 1'b0) begin
                        spi_clk <= 1'b0;
                        spi_mosi <= tx_shift[7];
                        tx_shift <= {tx_shift[6:0], 1'b0};
                        bit_phase <= 1'b1;
                    end else begin
                        spi_clk <= 1'b1;
                        rx_shift <= {rx_shift[6:0], spi_miso};
                        bit_phase <= 1'b0;
                        if (bit_count == 3'd7) begin
                            bit_count <= 3'd0;
                            byte_ready <= 1'b1;
                        end else begin
                            bit_count <= bit_count + 3'd1;
                        end
                    end

                    if (byte_ready) begin
                        data_index <= data_index + 9'd1;
                        if (data_index == 9'd511) begin
                            state <= STATE_WRITE_CRC;
                            crc_index <= 2'd0;
                            tx_shift <= 8'hFF;
                        end else begin
                            tx_shift <= get_data_byte(data_shadow, data_index + 9'd1);
                        end
                    end
                end

                STATE_WRITE_CRC: begin
                    if (bit_phase == 1'b0) begin
                        spi_clk <= 1'b0;
                        spi_mosi <= tx_shift[7];
                        tx_shift <= {tx_shift[6:0], 1'b0};
                        bit_phase <= 1'b1;
                    end else begin
                        spi_clk <= 1'b1;
                        rx_shift <= {rx_shift[6:0], spi_miso};
                        bit_phase <= 1'b0;
                        if (bit_count == 3'd7) begin
                            bit_count <= 3'd0;
                            byte_ready <= 1'b1;
                        end else begin
                            bit_count <= bit_count + 3'd1;
                        end
                    end

                    if (byte_ready) begin
                        crc_index <= crc_index + 2'd1;
                        if (crc_index == 2'd1) begin
                            state <= STATE_DATA_RESPONSE;
                            tx_shift <= 8'hFF;
                        end else begin
                            tx_shift <= 8'hFF;
                        end
                    end
                end

                STATE_DATA_RESPONSE: begin
                    if (bit_phase == 1'b0) begin
                        spi_clk <= 1'b0;
                        spi_mosi <= 1'b1;
                        tx_shift <= {tx_shift[6:0], 1'b0};
                        bit_phase <= 1'b1;
                    end else begin
                        spi_clk <= 1'b1;
                        rx_shift <= {rx_shift[6:0], spi_miso};
                        bit_phase <= 1'b0;
                        if (bit_count == 3'd7) begin
                            bit_count <= 3'd0;
                            byte_ready <= 1'b1;
                        end else begin
                            bit_count <= bit_count + 3'd1;
                        end
                    end

                    if (byte_ready) begin
                        cmd_response[7:0] <= rx_shift;
                        state <= STATE_DONE;
                        cmd_buffer_out <= cmd_response;
                        cmd_buffer_out_valid <= 1'b1;
                        interrupt <= 1'b1;
                        spi_cs <= 1'b1;
                        spi_clk <= 1'b0;
                        spi_mosi <= 1'b1;
                        busy <= 1'b0;
                    end
                end

                STATE_DONE: begin
                    state <= STATE_IDLE;
                end

                default: begin
                    state <= STATE_IDLE;
                end
            endcase
        end
    end

endmodule
