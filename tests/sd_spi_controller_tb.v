`timescale 1ns/1ps

// Purpose: self-checking verification for sd_spi_controller SPI sequencing.
// Inputs/outputs covered:
// - command response packing (R1 and extended response bytes)
// - write path completion timing (must wait for SD busy release)
// Invariants checked:
// - cmd_buffer_out reflects the byte sampled in the same terminal cycle
// - CMD24 completion does not occur before the busy-release byte (0xFF)
module sd_spi_controller_tb;
  localparam STATE_IDLE            = 4'd0;
  localparam STATE_WAIT_RESP       = 4'd2;
  localparam STATE_READ_RESP       = 4'd3;
  localparam STATE_DATA_RESPONSE   = 4'd10;
  localparam STATE_WAIT_WRITE_BUSY = 4'd12;

  reg clk = 1'b0;
  reg clk_en = 1'b1;
  reg start = 1'b0;
  reg [47:0] cmd_buffer_in = 48'd0;
  reg [4095:0] data_buffer_in = 4096'd0;
  wire [47:0] cmd_buffer_out;
  wire cmd_buffer_out_valid;
  wire [4095:0] data_buffer_out;
  wire data_buffer_out_valid;
  wire busy;
  wire interrupt;
  wire spi_cs;
  wire spi_clk;
  wire spi_mosi;
  reg spi_miso = 1'b1;

  integer failures;
  integer i;
  reg timed_out;

  reg seen_cmd_valid;
  reg seen_data_valid;
  reg seen_interrupt;
  reg [47:0] last_cmd_out;

  // Scripted response streams by state.
  reg [7:0] cfg_wait_resp [0:7];
  reg [7:0] cfg_read_resp [0:7];
  integer cfg_wait_resp_len;
  integer cfg_read_resp_len;
  reg [7:0] cfg_data_response;
  integer cfg_write_busy_low_bytes;

  // Runtime SPI MISO byte-selection state.
  integer rt_wait_idx;
  integer rt_read_idx;
  integer rt_busy_idx;
  integer bit_idx;
  reg [7:0] current_miso_byte;
  reg [3:0] prev_state;

  sd_spi_controller dut(
    .clk(clk),
    .clk_en(clk_en),
    .start(start),
    .cmd_buffer_in(cmd_buffer_in),
    .data_buffer_in(data_buffer_in),
    .cmd_buffer_out(cmd_buffer_out),
    .cmd_buffer_out_valid(cmd_buffer_out_valid),
    .data_buffer_out(data_buffer_out),
    .data_buffer_out_valid(data_buffer_out_valid),
    .busy(busy),
    .interrupt(interrupt),
    .spi_cs(spi_cs),
    .spi_clk(spi_clk),
    .spi_mosi(spi_mosi),
    .spi_miso(spi_miso)
  );

  always #5 clk = ~clk;

  always @(posedge clk) begin
    if (cmd_buffer_out_valid) begin
      seen_cmd_valid <= 1'b1;
      last_cmd_out <= cmd_buffer_out;
    end
    if (data_buffer_out_valid) begin
      seen_data_valid <= 1'b1;
    end
    if (interrupt) begin
      seen_interrupt <= 1'b1;
    end
  end

  task step;
    begin
      @(posedge clk);
      #1;
    end
  endtask

  task check_true;
    input cond;
    input [8*96-1:0] msg;
    begin
      if (!cond) begin
        failures = failures + 1;
        $display("FAIL: %0s", msg);
      end else begin
        $display("PASS: %0s", msg);
      end
    end
  endtask

  task clear_observers;
    begin
      seen_cmd_valid = 1'b0;
      seen_data_valid = 1'b0;
      seen_interrupt = 1'b0;
      last_cmd_out = 48'd0;
    end
  endtask

  task reset_scripts;
    begin
      cfg_wait_resp_len = 0;
      cfg_read_resp_len = 0;
      cfg_data_response = 8'hFF;
      cfg_write_busy_low_bytes = 0;
      for (i = 0; i < 8; i = i + 1) begin
        cfg_wait_resp[i] = 8'hFF;
        cfg_read_resp[i] = 8'hFF;
      end
    end
  endtask

  task set_cmd_index;
    input [5:0] idx;
    begin
      cmd_buffer_in = 48'd0;
      cmd_buffer_in[7:0] = 8'h40 | {2'b00, idx};
    end
  endtask

  task pulse_start;
    begin
      start = 1'b1;
      step;
      start = 1'b0;
      step;
    end
  endtask

  task wait_for_idle;
    input integer max_cycles;
    output reg did_timeout;
    integer k;
    begin : wait_idle_block
      did_timeout = 1'b1;
      for (k = 0; k < max_cycles; k = k + 1) begin
        step;
        if ((busy === 1'b0) && (dut.state == STATE_IDLE)) begin
          did_timeout = 1'b0;
          disable wait_idle_block;
        end
      end
    end
  endtask

  task wait_for_state;
    input [3:0] target_state;
    input integer max_cycles;
    output reg did_timeout;
    integer k;
    begin : wait_state_block
      did_timeout = 1'b1;
      for (k = 0; k < max_cycles; k = k + 1) begin
        step;
        if (dut.state == target_state) begin
          did_timeout = 1'b0;
          disable wait_state_block;
        end
      end
    end
  endtask

  // Simple scripted SD card MISO model.
  // - For states that consume response bytes, output bytes from configured streams.
  // - Other states default to 0xFF.
  // - For write busy-release, output cfg_write_busy_low_bytes copies of 0x00 then 0xFF.
  always @(negedge clk) begin
    if (!clk_en) begin
      spi_miso = 1'b1;
    end else begin
      if (dut.state != prev_state) begin
        prev_state = dut.state;
        bit_idx = 7;
        case (dut.state)
          STATE_WAIT_RESP: begin
            rt_wait_idx = 0;
            if (cfg_wait_resp_len > 0) begin
              current_miso_byte = cfg_wait_resp[0];
              rt_wait_idx = 1;
            end else begin
              current_miso_byte = 8'hFF;
            end
          end
          STATE_READ_RESP: begin
            rt_read_idx = 0;
            if (cfg_read_resp_len > 0) begin
              current_miso_byte = cfg_read_resp[0];
              rt_read_idx = 1;
            end else begin
              current_miso_byte = 8'hFF;
            end
          end
          STATE_DATA_RESPONSE: begin
            current_miso_byte = cfg_data_response;
          end
          STATE_WAIT_WRITE_BUSY: begin
            rt_busy_idx = 0;
            if (cfg_write_busy_low_bytes > 0) begin
              current_miso_byte = 8'h00;
              rt_busy_idx = 1;
            end else begin
              current_miso_byte = 8'hFF;
            end
          end
          default: begin
            current_miso_byte = 8'hFF;
          end
        endcase
      end

      if (dut.bit_phase == 1'b1) begin
        spi_miso = current_miso_byte[bit_idx];
        if (bit_idx == 0) begin
          bit_idx = 7;
          case (dut.state)
            STATE_WAIT_RESP: begin
              if (rt_wait_idx < cfg_wait_resp_len) begin
                current_miso_byte = cfg_wait_resp[rt_wait_idx];
                rt_wait_idx = rt_wait_idx + 1;
              end else begin
                current_miso_byte = 8'hFF;
              end
            end
            STATE_READ_RESP: begin
              if (rt_read_idx < cfg_read_resp_len) begin
                current_miso_byte = cfg_read_resp[rt_read_idx];
                rt_read_idx = rt_read_idx + 1;
              end else begin
                current_miso_byte = 8'hFF;
              end
            end
            STATE_DATA_RESPONSE: begin
              current_miso_byte = 8'hFF;
            end
            STATE_WAIT_WRITE_BUSY: begin
              if (rt_busy_idx < cfg_write_busy_low_bytes) begin
                current_miso_byte = 8'h00;
                rt_busy_idx = rt_busy_idx + 1;
              end else begin
                current_miso_byte = 8'hFF;
              end
            end
            default: begin
              current_miso_byte = 8'hFF;
            end
          endcase
        end else begin
          bit_idx = bit_idx - 1;
        end
      end
    end
  end

  initial begin
    failures = 0;
    prev_state = STATE_IDLE;
    bit_idx = 7;
    current_miso_byte = 8'hFF;
    rt_wait_idx = 0;
    rt_read_idx = 0;
    rt_busy_idx = 0;

    clear_observers();
    reset_scripts();
    repeat (4) step;

    // Case 1: single-byte response (CMD0-style), checks response packing.
    clear_observers();
    reset_scripts();
    set_cmd_index(6'd0);
    cfg_wait_resp_len = 2;
    cfg_wait_resp[0] = 8'hFF;
    cfg_wait_resp[1] = 8'h01;
    pulse_start();
    wait_for_idle(12000, timed_out);
    check_true(!timed_out, "CMD0 transaction reaches idle");
    check_true(seen_cmd_valid, "CMD0 emits cmd_buffer_out_valid");
    check_true(last_cmd_out[7:0] == 8'h01, "CMD0 captures the terminal R1 byte");

    // Case 2: extended response (CMD8/CMD58-style), checks multi-byte packing.
    clear_observers();
    reset_scripts();
    set_cmd_index(6'd8);
    cfg_wait_resp_len = 1;
    cfg_wait_resp[0] = 8'h01;
    cfg_read_resp_len = 4;
    cfg_read_resp[0] = 8'hAA;
    cfg_read_resp[1] = 8'hBB;
    cfg_read_resp[2] = 8'hCC;
    cfg_read_resp[3] = 8'hDD;
    pulse_start();
    wait_for_idle(16000, timed_out);
    check_true(!timed_out, "CMD8 transaction reaches idle");
    check_true(seen_cmd_valid, "CMD8 emits cmd_buffer_out_valid");
    check_true(last_cmd_out[7:0] == 8'h01, "CMD8 R1 byte captured");
    check_true(last_cmd_out[15:8] == 8'hAA, "CMD8 response byte[1] captured");
    check_true(last_cmd_out[23:16] == 8'hBB, "CMD8 response byte[2] captured");
    check_true(last_cmd_out[31:24] == 8'hCC, "CMD8 response byte[3] captured");
    check_true(last_cmd_out[39:32] == 8'hDD, "CMD8 response byte[4] captured");

    // Case 3: write flow (CMD24) must wait for busy release after data response.
    clear_observers();
    reset_scripts();
    set_cmd_index(6'd24);
    for (i = 0; i < 512; i = i + 1) begin
      data_buffer_in[i*8 +: 8] = i[7:0];
    end
    cfg_wait_resp_len = 1;
    cfg_wait_resp[0] = 8'h00;
    cfg_data_response = 8'h05;
    cfg_write_busy_low_bytes = 3;
    pulse_start();
    wait_for_state(STATE_WAIT_WRITE_BUSY, 120000, timed_out);
    check_true(!timed_out, "CMD24 reaches write-busy wait state");
    repeat (40) step;
    check_true(busy === 1'b1, "CMD24 remains busy before busy-release byte");
    wait_for_idle(16000, timed_out);
    check_true(!timed_out, "CMD24 reaches idle after busy release");
    check_true(seen_interrupt, "CMD24 raises completion interrupt");
    check_true(seen_cmd_valid, "CMD24 emits cmd_buffer_out_valid");
    check_true(last_cmd_out[7:0] == 8'h05, "CMD24 reports data response token");
    check_true(!seen_data_valid, "CMD24 does not emit read data valid");

    if (failures == 0) begin
      $display("TEST_RESULT=PASS");
      $finish;
    end else begin
      $display("TEST_RESULT=FAIL (%0d checks failed)", failures);
      $fatal(1, "sd_spi_controller_tb failed");
    end
  end
endmodule
