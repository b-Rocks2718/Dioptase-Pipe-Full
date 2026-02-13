/*
 * SRAM-like test RAM model
 *
 * Purpose:
 * - Provide a deterministic RAM endpoint for validating a future DDR2->SRAM
 *   bridge on Nexys A7 in simulation.
 * - Emulate fixed-latency memory completion semantics (not zero-cycle BRAM).
 *
 * Interface contract:
 * - Request channel (input): req/we/be/addr/wdata
 * - Completion channel (output): ready/rdata, with busy indicating one in-flight
 *   transaction.
 * - At most one transaction is in flight; req is only accepted when busy=0.
 *
 * Addressing assumptions:
 * - addr is a physical byte address.
 * - The model is word-backed; addr[1:0] is ignored (4-byte aligned accesses).
 * - Out-of-range accesses do not modify memory, set error_oob for one cycle,
 *   and read as zero.
 */
module ram #(
    parameter integer ADDR_WIDTH = 27,
    parameter integer WORD_ADDR_BITS = 20, // 2^20 words = 4 MiB test RAM
    parameter integer ACCESS_LATENCY = 6    // cycles from accept -> ready
)(
    input wire clk,
    input wire rst,

    input wire req,
    input wire we,
    input wire [3:0] be,
    input wire [ADDR_WIDTH-1:0] addr,
    input wire [31:0] wdata,

    output wire [31:0] rdata,
    output reg ready,
    output wire busy,
    output reg error_oob
);
    localparam integer MEM_WORDS = (1 << WORD_ADDR_BITS);
    localparam integer EFFECTIVE_LATENCY = (ACCESS_LATENCY < 1) ? 1 : ACCESS_LATENCY;
    localparam integer LATENCY_BITS = (EFFECTIVE_LATENCY <= 1) ? 1 : $clog2(EFFECTIVE_LATENCY);
    localparam [31:0] LATENCY_MINUS_ONE = EFFECTIVE_LATENCY - 1;

    // One-port word-addressable memory backing.
    reg [31:0] mem [0:MEM_WORDS-1];

    // Captured in-flight request state.
    reg txn_valid;
    reg txn_we;
    reg [3:0] txn_be;
    reg [ADDR_WIDTH-1:0] txn_addr;
    reg [31:0] txn_wdata;
    reg [LATENCY_BITS-1:0] txn_countdown;

    // Decode latched word index. Lower two byte-address bits are ignored.
    wire [ADDR_WIDTH-3:0] txn_word_addr = txn_addr[ADDR_WIDTH-1:2];
    wire txn_oob;
    wire [WORD_ADDR_BITS-1:0] txn_word_idx = txn_addr[WORD_ADDR_BITS+1:2];

    generate
        if ((ADDR_WIDTH - 2) > WORD_ADDR_BITS) begin : gen_oob_check
            assign txn_oob = |txn_word_addr[ADDR_WIDTH-3:WORD_ADDR_BITS];
        end else begin : gen_oob_check_none
            assign txn_oob = 1'b0;
        end
    endgenerate

    assign busy = txn_valid;
    // `rdata` is combinational from the latched in-flight read address so it is
    // stable in the same cycle `ready` is asserted.
    assign rdata = txn_oob ? 32'd0 : mem[txn_word_idx];

    // Byte-lane merge helper for writes.
    function [31:0] merge_write_bytes;
        input [31:0] old_word;
        input [31:0] new_word;
        input [3:0] byte_en;
        begin
            merge_write_bytes = old_word;
            if (byte_en[0]) merge_write_bytes[7:0] = new_word[7:0];
            if (byte_en[1]) merge_write_bytes[15:8] = new_word[15:8];
            if (byte_en[2]) merge_write_bytes[23:16] = new_word[23:16];
            if (byte_en[3]) merge_write_bytes[31:24] = new_word[31:24];
        end
    endfunction

    integer i;
    reg [1023:0] ram_hexfile;
    initial begin
        // Deterministic startup contents for reproducible simulation behavior.
        for (i = 0; i < MEM_WORDS; i = i + 1) begin
            mem[i] = 32'd0;
        end

        // Optional preload for tests:
        //   +ram_hex=<file.hex>
        // Compatibility fallback:
        //   +hex=<file.hex>
        if ($value$plusargs("ram_hex=%s", ram_hexfile) ||
            $value$plusargs("hex=%s", ram_hexfile)) begin
            $readmemh(ram_hexfile, mem);
        end

        ready = 1'b0;
        error_oob = 1'b0;
        txn_valid = 1'b0;
        txn_we = 1'b0;
        txn_be = 4'd0;
        txn_addr = {ADDR_WIDTH{1'b0}};
        txn_wdata = 32'd0;
        txn_countdown = {LATENCY_BITS{1'b0}};
    end

    always @(posedge clk) begin
        // Output pulses are one-cycle flags.
        ready <= 1'b0;
        error_oob <= 1'b0;

        if (rst) begin
            // Postcondition after reset:
            // - No in-flight transaction
            // - No completion pulse asserted
            txn_valid <= 1'b0;
            txn_we <= 1'b0;
            txn_be <= 4'd0;
            txn_addr <= {ADDR_WIDTH{1'b0}};
            txn_wdata <= 32'd0;
            txn_countdown <= {LATENCY_BITS{1'b0}};
        end else begin
            // Accept exactly one request when idle.
            if (!txn_valid && req) begin
                txn_valid <= 1'b1;
                txn_we <= we;
                txn_be <= be;
                txn_addr <= addr;
                txn_wdata <= wdata;
                txn_countdown <= LATENCY_MINUS_ONE[LATENCY_BITS-1:0];
            end

            // Complete the in-flight request after fixed latency.
            if (txn_valid) begin
                if (txn_countdown != 0) begin
                    txn_countdown <= txn_countdown - 1'b1;
                end else begin
                    if (txn_oob) begin
                        error_oob <= 1'b1;
                    end else if (txn_we) begin
                        mem[txn_word_idx] <= merge_write_bytes(mem[txn_word_idx], txn_wdata, txn_be);
                    end

                    ready <= 1'b1;
                    txn_valid <= 1'b0;
                end
            end
        end
    end
endmodule
