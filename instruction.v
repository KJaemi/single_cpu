`timescale 1ns/1ps

module InstructionMemory (
    input  wire [31:0] pc,       // ??? ?? PC
    input  wire        sel,      // 0?rom1, 1?rom2 (CPU? inst_sel)
    output reg  [31:0] instr     // ???? 32-bit ???
);

    // rom1.hex/rom2.hex ?? ??(???) ??
    localparam DEPTH0 = 336;    // rom1.hex ?? ?
    localparam DEPTH1 =  77;    // rom2.hex ?? ?

    // ?? ?? ??? (PC[10:2])
    wire [8:0] addr = pc[10:2];

    // ROM ?? ??
    reg [31:0] mem0 [0:DEPTH0-1];
    reg [31:0] mem1 [0:DEPTH1-1];

    initial begin
        // ?? ????? rom1.hex, rom2.hex ?? ??
        $readmemh("rom1.hex", mem0);
        $readmemh("rom2.hex", mem1);
    end

    always @(*) begin
        if (sel == 1'b0) begin
            instr = (addr < DEPTH0) ? mem0[addr] : 32'h00000000;
        end else begin
            instr = (addr < DEPTH1) ? mem1[addr] : 32'h00000000;
        end
    end

endmodule

