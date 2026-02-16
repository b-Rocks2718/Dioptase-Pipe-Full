`timescale 1ps/1ps

module ps2(input ps2_clk, input ps2_data, input clk, input ren, output [15:0]data, output ready);

    // Convert scan to ascii
    reg [7:0]scan_decode[0:8'hff];

    initial begin
        // Vivado synthesis runs from an out-of-tree build directory, so a
        // relative "./data/..." path is not stable there. Use a short memory
        // filename in synthesis (the file is added via create_project.tcl),
        // while preserving the existing in-repo relative path for simulation.
`ifdef SYNTHESIS
        $readmemh("scan_decode.mem", scan_decode);
`else
        $readmemh("./data/scan_decode.mem", scan_decode);
`endif
    end

    wire [15:0]scan_code;
    wire ready_flag;

    PS2Receiver receiver(
        .clk(clk),
        .kclk(ps2_clk),
        .kdata(ps2_data),
        .keycode(scan_code),
        .oflag(ready_flag)
    );

    reg [15:0]keyboard_reg = 0;
    reg break_pending = 0;
    reg extended_pending = 0;
    assign data = keyboard_reg;
    wire [7:0]ascii = scan_decode[scan_code[7:0]];
    // scan_decode.mem uses 0x07 as an "unmapped/non-printable" sentinel.
    // Treat both 0x00 and 0x07 as invalid so random/unmapped scan codes do
    // not surface as printable keyboard events to software.
    wire ascii_valid = (ascii != 8'h00) && (ascii != 8'h07);
    wire make_ready = ready_flag && !break_pending && ascii_valid;
    assign ready = make_ready;

    always @(posedge clk) begin
        if (ready_flag) begin
            if (scan_code[7:0] == 8'hF0) begin
                break_pending <= 1;
            end else if (scan_code[7:0] == 8'hE0) begin
                extended_pending <= 1;
            end else begin
                if (ascii_valid) begin
                    keyboard_reg <= break_pending ? {8'h01, ascii}
                                                  : {8'h00, ascii};
                end
                break_pending <= 0;
                extended_pending <= 0;
            end
        end else if (ren) begin
            keyboard_reg <= 0;
        end
    end

endmodule

// From demos
// https://github.com/Digilent/Basys-3-HW/blob/63134db53d58a894ba33ce24590ef38bb833772c/src/hdl/PS2Receiver.v

module PS2Receiver(
    input clk,
    input kclk,
    input kdata,
    output reg [15:0] keycode=0,
    output reg oflag
    );
    
    wire kclkf, kdataf;
    reg [7:0]datacur=0;
    reg [7:0]dataprev=0;
    reg [3:0]cnt=0;
    reg flag=0;
    
    debouncer #(
        .COUNT_MAX(19),
        .COUNT_WIDTH(5)
    ) db_clk(
        .clk(clk),
        .I(kclk),
        .O(kclkf)
    );
    debouncer #(
    .COUNT_MAX(19),
    .COUNT_WIDTH(5)
    ) db_data(
        .clk(clk),
        .I(kdata),
        .O(kdataf)
    );
        
    always@(negedge(kclkf))begin
        case(cnt)
        0:;//Start bit
        1:datacur[0]<=kdataf;
        2:datacur[1]<=kdataf;
        3:datacur[2]<=kdataf;
        4:datacur[3]<=kdataf;
        5:datacur[4]<=kdataf;
        6:datacur[5]<=kdataf;
        7:datacur[6]<=kdataf;
        8:datacur[7]<=kdataf;
        9:flag<=1'b1;
        10:flag<=1'b0;
        
        endcase
        if(cnt<=9) cnt<=cnt+1;
        else if(cnt==10) cnt<=0;
    end

    reg pflag;
    always@(posedge clk) begin
        if (flag == 1'b1 && pflag == 1'b0) begin
            keycode <= {dataprev, datacur};
            oflag <= 1'b1;
            dataprev <= datacur;
        end else
            oflag <= 1'b0;
        pflag <= flag;
    end

endmodule

module debouncer(
    input clk,
    input I,
    output reg O
    );
    parameter COUNT_MAX=255, COUNT_WIDTH=8;
    reg [COUNT_WIDTH-1:0] count;
    reg Iv=0;
    always@(posedge clk)
        if (I == Iv) begin
            if (count == COUNT_MAX)
                O <= I;
            else
                count <= count + 1'b1;
        end else begin
            count <= 'b0;
            Iv <= I;
        end
    
endmodule
