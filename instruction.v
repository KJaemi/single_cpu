`timescale 1ns/1ps

// --------------------------------------------------
// Instruction Memory
//  - PC[10:2] ? word index
//  - sel ?? ?? ? 0: rom1.hex, 1: rom2.hex
//  - ?? ??? ??, ? ??? 0 (NOP) ??
// --------------------------------------------------
module InstructionMemory (
    input  wire [31:0] pc,    
    input  wire        sel,   
    output reg  [31:0] instr  
);

    // ?? ?? ? (?? ??)
    localparam DEPTH0 = 336;   // rom1.hex lines
    localparam DEPTH1 =  77;   // rom2.hex lines

    // word index
    wire [8:0] addr = pc[10:2]; // 0..511

    // rom1: DEPTH0 ??
    reg [31:0] mem0 [0:DEPTH0-1];
    initial $readmemh("C:/Users/PC/Desktop/logiccircuit/instruction/rom1.hex", mem0);

    // rom2: DEPTH1 ??
    reg [31:0] mem1 [0:DEPTH1-1];
    initial $readmemh("C:/Users/PC/Desktop/logiccircuit/instruction/rom2.hex", mem1);

    always @(*) begin
        if (sel == 1'b0) begin
            // rom1 address in range?
            if (addr < DEPTH0)
                instr = mem0[addr];
            else
                instr = 32'h00000000;  // beyond file ? NOP
        end else begin
            // rom2 address in range?
            if (addr < DEPTH1)
                instr = mem1[addr];
            else
                instr = 32'h00000000;
        end
    end
endmodule
