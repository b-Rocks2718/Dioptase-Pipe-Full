`timescale 1ns/1ps

module cache_tb;
  reg clk = 1'b0;
  reg [26:0] addr = 27'd0;
  reg [31:0] data = 32'd0;
  reg re = 1'b0;
  reg [3:0] we = 4'd0;

  wire [31:0] data_out;
  wire success;
  wire ram_req;
  wire ram_we;
  wire [3:0] ram_be;
  wire [26:0] ram_addr;
  wire [31:0] ram_wdata;
  wire [31:0] ram_rdata;
  wire ram_ready;
  wire ram_busy;
  wire ram_error_oob;

  integer failures = 0;

  localparam [26:0] ADDR_A = 27'h0000000; // set 0, tag 0
  localparam [26:0] ADDR_B = 27'h0004000; // set 0, tag 1
  localparam [26:0] ADDR_C = 27'h0008000; // set 0, tag 2
  localparam [31:0] VAL_A = 32'h1122_3344;
  localparam [31:0] VAL_B = 32'h5566_7788;
  localparam [31:0] VAL_C = 32'h99AA_BBCC;

  cache dut(
    .clk(clk),
    .addr(addr),
    .data(data),
    .re(re),
    .we(we),
    .data_out(data_out),
    .success(success),
    .ram_req(ram_req),
    .ram_we(ram_we),
    .ram_be(ram_be),
    .ram_addr(ram_addr),
    .ram_wdata(ram_wdata),
    .ram_rdata(ram_rdata),
    .ram_ready(ram_ready),
    .ram_busy(ram_busy),
    .ram_error_oob(ram_error_oob)
  );

  ram backing_ram(
    .clk(clk),
    .rst(1'b0),
    .req(ram_req),
    .we(ram_we),
    .be(ram_be),
    .addr(ram_addr),
    .wdata(ram_wdata),
    .rdata(ram_rdata),
    .ready(ram_ready),
    .busy(ram_busy),
    .error_oob(ram_error_oob)
  );

  always #5 clk = ~clk;

  task check_eq;
    input [31:0] got;
    input [31:0] expected;
    input [255:0] msg;
    begin
      if (got !== expected) begin
        failures = failures + 1;
        $display("FAIL: %0s (got=%h expected=%h)", msg, got, expected);
      end else begin
        $display("PASS: %0s", msg);
      end
    end
  endtask

  task wait_success;
    input [255:0] msg;
    integer timeout;
    begin
      timeout = 0;
      while ((timeout < 6000) && !success) begin
        @(negedge clk);
        timeout = timeout + 1;
      end
      if (!success) begin
        failures = failures + 1;
        $display("FAIL: timeout waiting for success (%0s)", msg);
      end
    end
  endtask

  task issue_read;
    input [26:0] a;
    begin
      @(negedge clk);
      addr <= a;
      data <= 32'd0;
      re <= 1'b1;
      we <= 4'd0;
      @(negedge clk);
      re <= 1'b0;
    end
  endtask

  task issue_write;
    input [26:0] a;
    input [31:0] d;
    begin
      @(negedge clk);
      addr <= a;
      data <= d;
      re <= 1'b0;
      we <= 4'b1111;
      @(negedge clk);
      we <= 4'd0;
    end
  endtask

  initial begin
    // 1) Cold miss read should refill and return zero-initialized backing RAM.
    issue_read(ADDR_A);
    wait_success("cold read miss completes");
    check_eq(data_out, 32'd0, "cold read returns zero");

    // 2) Write then read same line should hit and return updated value.
    issue_write(ADDR_A, VAL_A);
    wait_success("write A completes");
    issue_read(ADDR_A);
    wait_success("read A hit completes");
    check_eq(data_out, VAL_A, "read A returns written value");

    // 3) Force same-set evictions to exercise dirty writeback + refill.
    issue_write(ADDR_B, VAL_B);
    wait_success("write B completes");
    issue_write(ADDR_C, VAL_C);
    wait_success("write C completes");

    // 4) Read back all values; evicted lines must have been written to RAM.
    issue_read(ADDR_A);
    wait_success("read back A after evictions");
    check_eq(data_out, VAL_A, "A preserved through writeback");

    issue_read(ADDR_B);
    wait_success("read back B after evictions");
    check_eq(data_out, VAL_B, "B preserved through writeback");

    issue_read(ADDR_C);
    wait_success("read back C after evictions");
    check_eq(data_out, VAL_C, "C preserved through writeback");

    if (failures == 0) begin
      $display("cache_tb PASS");
    end else begin
      $display("cache_tb FAIL (%0d failures)", failures);
      $fatal(1);
    end
    $finish;
  end
endmodule
