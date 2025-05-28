// Control Unit Module (MIPS Single-Cycle)
module ControlUnit (
    input  [5:0] OpCode,
    input  [5:0] Funct,
    output       IsJAL,
    output       RegWrite,
    output       MemtoReg,
    output       IsCOP0,
    output       MemWrite,
    output       MemRead,
    output       IsJR,
    output       Branch,
    output       BneOrBeq,
    output       Jump,
    output       ALUSrc,
    output       IsShamt,
    output       IsSyscall,
    output       RegDst,
    output       ZeroExtend,
    output       ReadRs,
    output       ReadRt,
    output [3:0] ALUOp
);
 
    assign IsJAL      = (OpCode == 6'b000011);
    assign MemtoReg   = (OpCode == 6'b100011);
    assign MemWrite   = (OpCode == 6'b101011);
    assign MemRead    = (OpCode == 6'b100011);

    assign Branch     = (OpCode == 6'b000100) ||
                        (OpCode == 6'b000101);
    assign BneOrBeq   = (OpCode == 6'b000101);

    assign Jump       = (OpCode == 6'b000010) || (OpCode == 6'b000011);
    assign RegDst     = (OpCode == 6'b000000);

    assign ZeroExtend = (OpCode == 6'b001100) ||
                        (OpCode == 6'b001101) ||
                        (OpCode == 6'b001110);

    assign IsCOP0     = (OpCode == 6'b010000);
 
    assign ReadRs = ~OpCode[5] & ~OpCode[4] & ~OpCode[3] & ~OpCode[2] & ~OpCode[1] & ~OpCode[0] &
               (
                 (~Funct[5] & ~Funct[4] & ~Funct[3] & ~Funct[2] & ~Funct[1] & ~Funct[0]) |
                 (~Funct[5] & ~Funct[4] & ~Funct[3] & ~Funct[2] & ~Funct[1] &  Funct[0]) |
                 (~Funct[5] & ~Funct[4] & ~Funct[3] &  Funct[2] & ~Funct[1] & ~Funct[0]) |
                 ( Funct[5] & ~Funct[4] & ~Funct[3] & ~Funct[2] & ~Funct[1] & ~Funct[0]) |
                 ( Funct[5] & ~Funct[4] & ~Funct[3] & ~Funct[2] &  Funct[1] &  Funct[0]) |
                 ( Funct[5] & ~Funct[4] & ~Funct[3] &  Funct[2] &  Funct[1] &  Funct[0]) |
                 ( Funct[5] & ~Funct[4] &  Funct[3] & ~Funct[2] &  Funct[1] & ~Funct[0]) |
                 ( Funct[5] & ~Funct[4] &  Funct[3] & ~Funct[2] &  Funct[1] &  Funct[0]) |
                 (~Funct[5] & ~Funct[4] &  Funct[3] & ~Funct[2] & ~Funct[1] & ~Funct[0])
               ) |
               (~OpCode[5] & ~OpCode[4] &  OpCode[3] & ~OpCode[2] & ~OpCode[1] & ~OpCode[0]) |
               (~OpCode[5] & ~OpCode[4] &  OpCode[3] & ~OpCode[2] & ~OpCode[1] &  OpCode[0]) |
               (~OpCode[5] & ~OpCode[4] &  OpCode[3] &  OpCode[2] & ~OpCode[1] & ~OpCode[0]) |
               (~OpCode[5] & ~OpCode[4] &  OpCode[3] &  OpCode[2] & ~OpCode[1] &  OpCode[0]) |
               ( OpCode[5] & ~OpCode[4] & ~OpCode[3] & ~OpCode[2] &  OpCode[1] &  OpCode[0]) |
               (~OpCode[5] & ~OpCode[4] & ~OpCode[3] &  OpCode[2] & ~OpCode[1] & ~OpCode[0]) |
               (~OpCode[5] & ~OpCode[4] & ~OpCode[3] &  OpCode[2] & ~OpCode[1] &  OpCode[0]) |
               (~OpCode[5] & ~OpCode[4] &  OpCode[3] & ~OpCode[2] &  OpCode[1] & ~OpCode[0]) |
               ( OpCode[5] & ~OpCode[4] &  OpCode[3] & ~OpCode[2] &  OpCode[1] &  OpCode[0]);


    assign ReadRt = ~OpCode[5] & ~OpCode[4] & ~OpCode[3] & ~OpCode[2] & ~OpCode[1] & ~OpCode[0] &
               (
                 (~Funct[5] & ~Funct[4] & ~Funct[3] & ~Funct[2] & ~Funct[1] & ~Funct[0]) |
                 (~Funct[5] & ~Funct[4] & ~Funct[3] & ~Funct[2] & ~Funct[1] &  Funct[0]) |
                 (~Funct[5] & ~Funct[4] & ~Funct[3] &  Funct[2] & ~Funct[1] & ~Funct[0]) |
                 ( Funct[5] & ~Funct[4] & ~Funct[3] & ~Funct[2] &  Funct[1] & ~Funct[0]) |
                 ( Funct[5] & ~Funct[4] & ~Funct[3] &  Funct[2] & ~Funct[1] &  Funct[0]) |
                 ( Funct[5] & ~Funct[4] & ~Funct[3] &  Funct[2] &  Funct[1] &  Funct[0]) |
                 ( Funct[5] & ~Funct[4] &  Funct[3] & ~Funct[2] &  Funct[1] & ~Funct[0]) |
                 ( Funct[5] & ~Funct[4] &  Funct[3] & ~Funct[2] &  Funct[1] &  Funct[0]) |
                 ( Funct[5] & ~Funct[4] &  Funct[3] & ~Funct[2] &  Funct[1] & ~Funct[0]) |
                 ( Funct[5] & ~Funct[4] &  Funct[3] & ~Funct[2] &  Funct[1] &  Funct[0])
               ) |
               (~OpCode[5] & ~OpCode[4] & ~OpCode[3] &  OpCode[2] & ~OpCode[1] & ~OpCode[0]) |
               (~OpCode[5] & ~OpCode[4] & ~OpCode[3] &  OpCode[2] & ~OpCode[1] &  OpCode[0]) |
               (~OpCode[5] &  OpCode[4] & ~OpCode[3] & ~OpCode[2] & ~OpCode[1] & ~OpCode[0]) |
               ( OpCode[5] & ~OpCode[4] &  OpCode[3] & ~OpCode[2] &  OpCode[1] &  OpCode[0]);

    assign ALUSrc = (OpCode == 6'b001000) ||
                    (OpCode == 6'b100011) ||
                    (OpCode == 6'b101011) ||
                    (OpCode == 6'b001100) ||
                    (OpCode == 6'b001101) ||
                    (OpCode == 6'b001010) ||
                    (OpCode == 6'b001001);

    assign RegWrite = (OpCode == 6'b000000) ||
                      (OpCode == 6'b001000) ||
                      (OpCode == 6'b001001) ||
                      (OpCode == 6'b001010) ||
                      (OpCode == 6'b001100) ||
                      (OpCode == 6'b001101) ||
                      (OpCode == 6'b100011) ||
                      (OpCode == 6'b000011) ||
                      (OpCode == 6'b010000);

    wire IsSpecial = (OpCode == 6'b000000);


    wire temp_IsSyscall = (Funct == 6'b001100);
    wire temp_IsJR      = (Funct == 6'b001000);
    wire temp_IsShamt   = (Funct == 6'b000000) || (Funct == 6'b000010);

    wire temp_ALU0 = (Funct == 6'b100101) || (Funct == 6'b100111) || (Funct == 6'b101010) || (Funct == 6'b101011);
    wire temp_ALU1 = (Funct == 6'b100000) || (Funct == 6'b100001) || (Funct == 6'b100010) || (Funct == 6'b100100) || (Funct == 6'b101011);
    wire temp_ALU2 = (Funct == 6'b100010) || (Funct == 6'b100100) || (Funct == 6'b000010) || (Funct == 6'b100111) || (Funct == 6'b101010);
    wire temp_ALU3 = (Funct == 6'b000011) || (Funct == 6'b100001) || (Funct == 6'b100000) || (Funct == 6'b100100) || (Funct == 6'b101010);


    wire opcode_ALU0 = (OpCode == 6'b001101) || (OpCode == 6'b001010);
    wire opcode_ALU1 = (OpCode == 6'b000000) || (OpCode == 6'b001000) || (OpCode == 6'b100011) ||
                       (OpCode == 6'b101011) || (OpCode == 6'b000101) || (OpCode == 6'b000100) ||
                       (OpCode == 6'b001100) || (OpCode == 6'b001001) || (OpCode == 6'b000010) ||
                       (OpCode == 6'b000011) || (OpCode == 6'b010000);
    wire opcode_ALU2 = (OpCode == 6'b001100) || (OpCode == 6'b001010);
    wire opcode_ALU3 = (OpCode == 6'b000000) || (OpCode == 6'b001000) || (OpCode == 6'b100011) ||
                       (OpCode == 6'b101011) || (OpCode == 6'b000101) || (OpCode == 6'b000100) ||
                       (OpCode == 6'b001100) || (OpCode == 6'b001010) || (OpCode == 6'b001001) ||
                       (OpCode == 6'b000010) || (OpCode == 6'b000011) || (OpCode == 6'b010000);

    assign IsSyscall = IsSpecial ? temp_IsSyscall : 1'b0;
    assign IsJR      = IsSpecial ? temp_IsJR      : 1'b0;
    assign IsShamt   = IsSpecial ? temp_IsShamt   : 1'b0;

    assign ALUOp[3]  = IsSpecial ? temp_ALU0      : opcode_ALU0;
    assign ALUOp[2]  = IsSpecial ? temp_ALU1      : opcode_ALU1;
    assign ALUOp[1]  = IsSpecial ? temp_ALU2      : opcode_ALU2;
    assign ALUOp[0]  = IsSpecial ? temp_ALU3      : opcode_ALU3;

endmodule