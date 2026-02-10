`timescale 1ns/1ps

// Purpose: targeted SD DMA controller checks independent of full CPU pipeline.
// This testbench validates key MMIO-visible semantics from docs/mem_map.md.
module sd_dma_controller_tb;
  reg clk = 1'b0;
  reg [31:0] mem_start_addr = 32'd0;
  reg [31:0] sd_block_start_addr = 32'd0;
  reg [31:0] num_blocks = 32'd0;
  reg [31:0] ctrl_data = 32'd0;
  reg ctrl_write = 1'b0;
  reg status_clear = 1'b0;
  reg mem_ready_set = 1'b0;
  reg sd_ready_set = 1'b0;
  reg [31:0] mem_data_in = 32'd0;

  wire [31:0] ctrl;
  wire [31:0] status;
  wire [31:0] error_code;
  wire [31:0] mem_request_addr_out;
  wire [31:0] mem_request_data;
  wire mem_request_read;
  wire mem_request_write;

  integer failures;
  integer beats;
  integer i;
  reg [31:0] addr_snapshot;

  sd_dma_controller dut(
    .clk(clk),
    .mem_start_addr(mem_start_addr),
    .sd_block_start_addr(sd_block_start_addr),
    .num_blocks(num_blocks),
    .ctrl_data(ctrl_data),
    .ctrl_write(ctrl_write),
    .status_clear(status_clear),
    .mem_ready_set(mem_ready_set),
    .sd_ready_set(sd_ready_set),
    .mem_data_in(mem_data_in),
    .ctrl(ctrl),
    .status(status),
    .error_code(error_code),
    .mem_request_addr_out(mem_request_addr_out),
    .mem_request_data(mem_request_data),
    .mem_request_read(mem_request_read),
    .mem_request_write(mem_request_write)
  );

  always #5 clk = ~clk;

  task step;
    begin
      @(posedge clk);
      #1;
    end
  endtask

  task check_true;
    input cond;
    input [8*80-1:0] msg;
    begin
      if (!cond) begin
        failures = failures + 1;
        $display("FAIL: %0s", msg);
      end else begin
        $display("PASS: %0s", msg);
      end
    end
  endtask

  task pulse_start;
    input dir;
    input irq_en;
    begin
      ctrl_data = {29'b0, irq_en, dir, 1'b1};
      ctrl_write = 1'b1;
      step;
      ctrl_write = 1'b0;
      ctrl_data = 32'd0;
      step;
    end
  endtask

  task pulse_status_clear;
    begin
      status_clear = 1'b1;
      step;
      status_clear = 1'b0;
      step;
    end
  endtask

  task pulse_mem_ready;
    begin
      mem_ready_set = 1'b1;
      step;
      mem_ready_set = 1'b0;
      step;
    end
  endtask

  task pulse_sd_ready;
    begin
      sd_ready_set = 1'b1;
      step;
      sd_ready_set = 1'b0;
      step;
    end
  endtask

  task drain_until_idle;
    input integer max_beats;
    output integer beats_seen;
    begin
      beats_seen = 0;
      while ((status[0] === 1'b1) && (beats_seen < max_beats)) begin
        pulse_mem_ready();
        beats_seen = beats_seen + 1;
      end
    end
  endtask

  initial begin
    failures = 0;
    mem_start_addr = 32'h0000_1000;
    sd_block_start_addr = 32'h0000_0002;
    num_blocks = 32'd1;
    mem_data_in = 32'hCAFE_BABE;

    repeat (2) step;

    // Case 1: DIR=0 should request memory writes (SD -> RAM).
    pulse_start(1'b0, 1'b0);
    check_true(status[0] === 1'b1, "busy set after start");
    check_true(mem_request_write === 1'b1, "DIR=0 drives mem_request_write");
    check_true(mem_request_read === 1'b0, "DIR=0 clears mem_request_read");

    // Case 2: status clear should clear DONE/ERR but keep BUSY unchanged.
    pulse_status_clear();
    check_true(status[0] === 1'b1, "status_clear does not clear busy while active");

    // Recover to a known idle state for later cases.
    if (status[0] === 1'b1) begin
      drain_until_idle(700, beats);
    end
    pulse_status_clear();

    // Case 3: DIR=1 should request memory reads (RAM -> SD).
    num_blocks = 32'd2;
    mem_start_addr = 32'h0000_2000;
    mem_data_in = 32'h1234_5678;
    pulse_start(1'b1, 1'b0);
    check_true(status[0] === 1'b1, "busy set after DIR=1 start");
    check_true(mem_request_read === 1'b1, "DIR=1 drives mem_request_read");
    check_true(mem_request_write === 1'b0, "DIR=1 clears mem_request_write");

    // Case 4: after each block, transfer pauses until sd_ready_set.
    for (i = 0; i < 128; i = i + 1) begin
      pulse_mem_ready();
    end
    check_true(status[0] === 1'b1, "after block 1, transfer still busy");
    check_true(status[1] === 1'b0, "after block 1, done is still clear");
    addr_snapshot = mem_request_addr_out;
    for (i = 0; i < 8; i = i + 1) begin
      pulse_mem_ready();
    end
    check_true(mem_request_addr_out === addr_snapshot, "stalls between blocks until sd_ready_set");

    // While stalled, a mem_ready pulse should be queued and replayed after sd_ready_set.
    pulse_mem_ready();
    check_true(mem_request_addr_out === addr_snapshot, "queued mem_ready does not advance during stall");
    pulse_sd_ready();
    repeat (4) step;
    check_true(mem_request_addr_out !== addr_snapshot, "queued mem_ready is replayed after sd_ready_set");

    drain_until_idle(300, beats);
    check_true(status[0] === 1'b0, "transfer eventually becomes idle");
    check_true(status[1] === 1'b1, "done set on transfer completion");
    check_true(beats == 127, "after replay, remaining block needs 127 mem_ready pulses");

    if (failures == 0) begin
      $display("TEST_RESULT=PASS");
      $finish;
    end else begin
      $display("TEST_RESULT=FAIL (%0d checks failed)", failures);
      $fatal(1, "sd_dma_controller_tb failed");
    end
  end
endmodule
