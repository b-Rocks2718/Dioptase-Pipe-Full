`timescale 1ps/1ps
`ifdef FPGA_USE_DDR_SRAM_ADAPTER

/*
 * ddr_sram_adapter
 *
 * Purpose:
 * - Bridge the SoC SRAM-like request/ready contract used by `mem.v` to the
 *   Digilent `ram2ddr` interface (asynchronous 16-bit SRAM bus facade).
 *
 * Preconditions:
 * - At most one request is in flight (enforced by this module via `busy`).
 * - Requests are byte-addressed and naturally aligned to word accesses by the
 *   cache/memory subsystem.
 * - External `ram2ddr` must be added to the Vivado project.
 *
 * Postconditions:
 * - `ready` pulses for one cycle when the request completes.
 * - `busy` is asserted while a request is being translated/executed.
 * - `rdata` is valid in the same cycle as `ready` for reads.
 *
 * Implementation-defined behavior:
 * - `ram2ddr` exposes no explicit per-transaction ready signal. This bridge
 *   waits a conservative fixed number of cycles per 16-bit sub-transaction.
 *   This is safe but not throughput-optimal.
 */
module ddr_sram_adapter(
    input wire clk,
    input wire rst,

    input wire req,
    input wire we,
    input wire [3:0] be,
    input wire [26:0] addr,
    input wire [31:0] wdata,

    output reg [31:0] rdata,
    output reg ready,
    output wire busy,
    output wire error_oob,

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
);
    // Clocking contract for Digilent ram2ddr:
    // - ram2ddr expects a 200MHz reference on clk_200MHz_i.
    // - The SoC runs from the board 100MHz clock, so this adapter generates a
    //   dedicated 200MHz clock locally using an MMCM + BUFG.
    // - ram2ddr reset is held asserted until the MMCM locks.
    wire ddr_clk_200_raw;
    wire ddr_clk_200;
    wire ddr_clk_fb;
    wire ddr_clk_locked;
    wire ddr_rst;

    assign ddr_rst = rst | ~ddr_clk_locked;

    MMCME2_BASE #(
        .BANDWIDTH("OPTIMIZED"),
        .CLKFBOUT_MULT_F(10.000),
        .CLKFBOUT_PHASE(0.000),
        .CLKIN1_PERIOD(10.000),
        .CLKOUT0_DIVIDE_F(5.000),
        .CLKOUT0_DUTY_CYCLE(0.500),
        .CLKOUT0_PHASE(0.000),
        .DIVCLK_DIVIDE(1),
        .REF_JITTER1(0.010),
        .STARTUP_WAIT("FALSE")
    ) ddr_clk_mmcm (
        .CLKIN1(clk),
        .CLKFBIN(ddr_clk_fb),
        .RST(rst),
        .PWRDWN(1'b0),
        .CLKFBOUT(ddr_clk_fb),
        .CLKOUT0(ddr_clk_200_raw),
        .CLKOUT0B(),
        .CLKOUT1(),
        .CLKOUT1B(),
        .CLKOUT2(),
        .CLKOUT2B(),
        .CLKOUT3(),
        .CLKOUT3B(),
        .CLKOUT4(),
        .CLKOUT5(),
        .CLKOUT6(),
        .LOCKED(ddr_clk_locked)
    );

    BUFG ddr_clk_bufg (
        .I(ddr_clk_200_raw),
        .O(ddr_clk_200)
    );

    localparam [2:0] ST_IDLE = 3'd0;
    localparam [2:0] ST_ASSERT = 3'd1;
    localparam [2:0] ST_WAIT = 3'd2;
    localparam [2:0] ST_CAPTURE = 3'd3;
    localparam [2:0] ST_DONE = 3'd4;

    // Conservative wait for each 16-bit access over the Digilent SRAM facade.
    // If needed, tune this after hardware bring-up.
    localparam integer HALFWORD_WAIT_CYCLES = 24;
    localparam integer HALFWORD_WAIT_BITS =
        (HALFWORD_WAIT_CYCLES <= 1) ? 1 : $clog2(HALFWORD_WAIT_CYCLES);

    reg [2:0] state;
    reg [HALFWORD_WAIT_BITS-1:0] wait_ctr;

    reg latched_we;
    reg [3:0] latched_be;
    reg [26:0] latched_addr;
    reg [31:0] latched_wdata;
    reg [31:0] read_accum;

    reg do_lower;
    reg do_upper;
    reg curr_upper;

    // Digilent SRAM bus controls (active low).
    reg [26:0] ram_a;
    reg [15:0] ram_dq_i;
    wire [15:0] ram_dq_o;
    reg ram_cen;
    reg ram_oen;
    reg ram_wen;
    reg ram_ub;
    reg ram_lb;

    assign busy = (state != ST_IDLE);
    assign error_oob = 1'b0;

    wire [1:0] active_be =
        curr_upper ? latched_be[3:2] : latched_be[1:0];
    wire [15:0] active_wdata =
        curr_upper ? latched_wdata[31:16] : latched_wdata[15:0];
    wire [26:0] active_addr =
        curr_upper ? (latched_addr + 27'd2) : latched_addr;

    ram2ddr ram2ddr_i(
        .clk_200MHz_i(ddr_clk_200),
        .rst_i(ddr_rst),
        .device_temp_i(12'd0),
        .ram_a(ram_a),
        .ram_dq_i(ram_dq_i),
        .ram_dq_o(ram_dq_o),
        .ram_cen(ram_cen),
        .ram_oen(ram_oen),
        .ram_wen(ram_wen),
        .ram_ub(ram_ub),
        .ram_lb(ram_lb),
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

    always @(posedge clk) begin
        ready <= 1'b0;

        if (rst) begin
            state <= ST_IDLE;
            wait_ctr <= {HALFWORD_WAIT_BITS{1'b0}};
            latched_we <= 1'b0;
            latched_be <= 4'd0;
            latched_addr <= 27'd0;
            latched_wdata <= 32'd0;
            read_accum <= 32'd0;
            rdata <= 32'd0;
            do_lower <= 1'b0;
            do_upper <= 1'b0;
            curr_upper <= 1'b0;
            ram_a <= 27'd0;
            ram_dq_i <= 16'd0;
            ram_cen <= 1'b1;
            ram_oen <= 1'b1;
            ram_wen <= 1'b1;
            ram_ub <= 1'b1;
            ram_lb <= 1'b1;
        end else begin
            case (state)
                ST_IDLE: begin
                    // SRAM bus idle defaults.
                    ram_cen <= 1'b1;
                    ram_oen <= 1'b1;
                    ram_wen <= 1'b1;
                    ram_ub <= 1'b1;
                    ram_lb <= 1'b1;
                    ram_a <= 27'd0;
                    ram_dq_i <= 16'd0;

                    if (req) begin
                        latched_we <= we;
                        latched_be <= be;
                        latched_addr <= addr;
                        latched_wdata <= wdata;
                        read_accum <= 32'd0;

                        do_lower <= we ? (|be[1:0]) : 1'b1;
                        do_upper <= we ? (|be[3:2]) : 1'b1;

                        if (we && !(|be)) begin
                            // Degenerate write with zero byte enables: consume
                            // request without touching memory.
                            ready <= 1'b1;
                            rdata <= 32'd0;
                        end else begin
                            curr_upper <= we ? !(|be[1:0]) : 1'b0;
                            state <= ST_ASSERT;
                        end
                    end
                end

                ST_ASSERT: begin
                    ram_a <= active_addr;
                    ram_dq_i <= active_wdata;
                    ram_cen <= 1'b0;

                    if (latched_we) begin
                        ram_wen <= 1'b0;
                        ram_oen <= 1'b1;
                        ram_lb <= ~active_be[0];
                        ram_ub <= ~active_be[1];
                    end else begin
                        ram_wen <= 1'b1;
                        ram_oen <= 1'b0;
                        ram_lb <= 1'b0;
                        ram_ub <= 1'b0;
                    end

                    wait_ctr <= HALFWORD_WAIT_CYCLES - 1;
                    state <= ST_WAIT;
                end

                ST_WAIT: begin
                    ram_a <= active_addr;
                    ram_dq_i <= active_wdata;
                    ram_cen <= 1'b0;

                    if (latched_we) begin
                        ram_wen <= 1'b0;
                        ram_oen <= 1'b1;
                        ram_lb <= ~active_be[0];
                        ram_ub <= ~active_be[1];
                    end else begin
                        ram_wen <= 1'b1;
                        ram_oen <= 1'b0;
                        ram_lb <= 1'b0;
                        ram_ub <= 1'b0;
                    end

                    if (wait_ctr != 0) begin
                        wait_ctr <= wait_ctr - 1'b1;
                    end else begin
                        state <= ST_CAPTURE;
                    end
                end

                ST_CAPTURE: begin
                    // Release SRAM request phase for this halfword.
                    ram_cen <= 1'b1;
                    ram_oen <= 1'b1;
                    ram_wen <= 1'b1;
                    ram_lb <= 1'b1;
                    ram_ub <= 1'b1;

                    if (!latched_we) begin
                        if (curr_upper) begin
                            read_accum[31:16] <= ram_dq_o;
                        end else begin
                            read_accum[15:0] <= ram_dq_o;
                        end
                    end

                    if (!curr_upper && do_upper) begin
                        curr_upper <= 1'b1;
                        state <= ST_ASSERT;
                    end else begin
                        state <= ST_DONE;
                    end
                end

                ST_DONE: begin
                    ready <= 1'b1;
                    rdata <= latched_we ? 32'd0 : read_accum;
                    state <= ST_IDLE;
                end

                default: begin
                    state <= ST_IDLE;
                end
            endcase
        end
    end
endmodule
`endif
