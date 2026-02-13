`timescale 1ps/1ps

// Purpose: SD SPI command/data sequencer for single-block CMD17/CMD24 flows.
// Inputs:
// - start: pulse to launch a transaction using cmd_buffer_in/data_buffer_in.
// - clk_en: controller advances only when asserted.
// - spi_miso: sampled on SPI clock high phase.
// Outputs:
// - cmd_buffer_out(+valid): latched response bytes (R1 + optional trailing bytes).
// - data_buffer_out(+valid): 512-byte read payload for CMD17.
// - busy/interrupt: busy while active; interrupt pulses on transaction completion.
// - spi_*: SPI pins (mode 0 style phasing in this controller).
// Invariants:
// - one active transaction at a time.
// - response bytes are packed little-endian by byte index into cmd_buffer_out.
// - write transactions wait for SD busy release after data response.
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
    localparam STATE_WAIT_WRITE_BUSY = 4'd12;

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

    // Purpose: replace one byte in a 48-bit response register by byte index.
    // Inputs: current packed response, byte index, new byte.
    // Output: updated packed response with only index byte replaced.
    function [47:0] set_resp_byte;
        input [47:0] data;
        input [2:0] index;
        input [7:0] value;
        begin
            set_resp_byte = data;
            case (index)
                3'd0: set_resp_byte[7:0]   = value;
                3'd1: set_resp_byte[15:8]  = value;
                3'd2: set_resp_byte[23:16] = value;
                3'd3: set_resp_byte[31:24] = value;
                3'd4: set_resp_byte[39:32] = value;
                3'd5: set_resp_byte[47:40] = value;
                default: begin end
            endcase
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
    reg [2:0] cmd_byte_index = 3'd0;
    reg [2:0] resp_index = 3'd0;
    reg [8:0] data_index = 9'd0;
    reg [1:0] crc_index = 2'd0;
    reg [7:0] wait_counter = 8'd0;
    wire bit_complete = (bit_phase == 1'b1) && (bit_count == 3'd7);
    wire [7:0] rx_shift_next = {rx_shift[6:0], spi_miso};

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
                        end else begin
                            bit_count <= bit_count + 3'd1;
                        end
                    end

                    if (bit_complete) begin
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
                        end else begin
                            bit_count <= bit_count + 3'd1;
                        end
                    end

                    if (bit_complete) begin
                        wait_counter <= wait_counter + 8'd1;
                        if (rx_shift_next != 8'hFF) begin
                            cmd_response <= set_resp_byte(cmd_response, 3'd0, rx_shift_next);
                            if (extra_resp_bytes != 3'd0) begin
                                resp_index <= 3'd0;
                                state <= STATE_READ_RESP;
                                tx_shift <= 8'hFF;
                            end else if (is_read_block) begin
                                state <= STATE_WAIT_TOKEN;
                                wait_counter <= 8'd0;
                                tx_shift <= 8'hFF;
                            end else if (is_write_block) begin
                                state <= STATE_SEND_TOKEN;
                                tx_shift <= DATA_TOKEN;
                            end else begin
                                state <= STATE_DONE;
                                cmd_buffer_out <= set_resp_byte(cmd_response, 3'd0, rx_shift_next);
                                cmd_buffer_out_valid <= 1'b1;
                                interrupt <= 1'b1;
                                spi_cs <= 1'b1;
                                spi_clk <= 1'b0;
                                spi_mosi <= 1'b1;
                                busy <= 1'b0;
                            end
                        end else if (wait_counter == 8'hFF) begin
                            cmd_response <= set_resp_byte(cmd_response, 3'd0, 8'hFF);
                            state <= STATE_DONE;
                            cmd_buffer_out <= set_resp_byte(cmd_response, 3'd0, 8'hFF);
                            cmd_buffer_out_valid <= 1'b1;
                            interrupt <= 1'b1;
                            spi_cs <= 1'b1;
                            spi_clk <= 1'b0;
                            spi_mosi <= 1'b1;
                            busy <= 1'b0;
                            tx_shift <= 8'hFF;
                        end
                        if (rx_shift_next == 8'hFF && wait_counter != 8'hFF) begin
                            tx_shift <= 8'hFF;
                        end
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
                        end else begin
                            bit_count <= bit_count + 3'd1;
                        end
                    end

                    if (bit_complete) begin
                        resp_index <= resp_index + 3'd1;
                        cmd_response <= set_resp_byte(cmd_response, resp_index + 3'd1, rx_shift_next);
                        if (resp_index + 3'd1 == extra_resp_bytes) begin
                            if (is_read_block) begin
                                state <= STATE_WAIT_TOKEN;
                                wait_counter <= 8'd0;
                            end else if (is_write_block) begin
                                state <= STATE_SEND_TOKEN;
                                tx_shift <= DATA_TOKEN;
                            end else begin
                                state <= STATE_DONE;
                                cmd_buffer_out <= set_resp_byte(cmd_response, resp_index + 3'd1, rx_shift_next);
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
                        end else begin
                            bit_count <= bit_count + 3'd1;
                        end
                    end

                    if (bit_complete) begin
                        wait_counter <= wait_counter + 8'd1;
                        if (rx_shift_next == DATA_TOKEN) begin
                            state <= STATE_READ_DATA;
                            data_index <= 9'd0;
                            tx_shift <= 8'hFF;
                        end else if (wait_counter == 8'hFF) begin
                            state <= STATE_DONE;
                            cmd_response <= set_resp_byte(cmd_response, 3'd0, 8'h05);
                            cmd_buffer_out <= set_resp_byte(cmd_response, 3'd0, 8'h05);
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
                        end else begin
                            bit_count <= bit_count + 3'd1;
                        end
                    end

                    if (bit_complete) begin
                        data_capture[data_index*8 +: 8] <= rx_shift_next;
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
                        end else begin
                            bit_count <= bit_count + 3'd1;
                        end
                    end

                    if (bit_complete) begin
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
                        end else begin
                            bit_count <= bit_count + 3'd1;
                        end
                    end

                    if (bit_complete) begin
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
                        end else begin
                            bit_count <= bit_count + 3'd1;
                        end
                    end

                    if (bit_complete) begin
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
                        end else begin
                            bit_count <= bit_count + 3'd1;
                        end
                    end

                    if (bit_complete) begin
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
                        end else begin
                            bit_count <= bit_count + 3'd1;
                        end
                    end

                    if (bit_complete) begin
                        cmd_response <= set_resp_byte(cmd_response, 3'd0, rx_shift_next);
                        state <= STATE_WAIT_WRITE_BUSY;
                        wait_counter <= 8'd0;
                        tx_shift <= 8'hFF;
                    end
                end

                // SD cards hold MISO low while internal write/program is in progress.
                // Completion is signaled by receiving 0xFF again after the data response.
                STATE_WAIT_WRITE_BUSY: begin
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
                        end else begin
                            bit_count <= bit_count + 3'd1;
                        end
                    end

                    if (bit_complete) begin
                        wait_counter <= wait_counter + 8'd1;
                        if (rx_shift_next == 8'hFF || wait_counter == 8'hFF) begin
                            state <= STATE_DONE;
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
