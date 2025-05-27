// Control Unit Module (MIPS Single-Cycle)
module ControlUnit (
    input  wire [5:0] OpCode,
    input  wire [5:0] Funct,
    output wire       IsJAL,
    output wire       RegWrite,
    output wire       MemtoReg,
    output wire       IsCOP0,
    output wire       MemWrite,
    output wire       MemRead,
    output wire       IsJR,
    output wire       Branch,
    output wire       BneOrBeq,
    output wire       Jump,
    output wire       ALUSrc,
    output wire       IsShamt,
    output wire       IsSyscall,
    output wire       RegDst,
    output wire       ZeroExtend,
    output wire       ReadRs,
    output wire       ReadRt,
    output wire [3:0]  ALUOp
);

    // Opcode constants
    localparam [5:0]
        OPC_RTYPE = 6'b000000,
        OPC_J     = 6'b000010,
        OPC_JAL   = 6'b000011,
        OPC_BEQ   = 6'b000100,
        OPC_BNE   = 6'b000101,
        OPC_LW    = 6'b100011,
        OPC_SW    = 6'b101011,
        OPC_ANDI  = 6'b001100,
        OPC_ORI   = 6'b001101,
        OPC_XORI  = 6'b001110,
        OPC_ADDI  = 6'b001000,
        OPC_ADDIU = 6'b001001,
        OPC_SLTI  = 6'b001010,
        OPC_COP0  = 6'b010000;

    // Type flags
    wire r_type    = (OpCode == OPC_RTYPE);
    wire lw        = (OpCode == OPC_LW);
    wire sw        = (OpCode == OPC_SW);
    wire beq       = (OpCode == OPC_BEQ);
    wire bne       = (OpCode == OPC_BNE);
    wire jal       = (OpCode == OPC_JAL);
    wire j         = (OpCode == OPC_J);

    // Basic control signals
    assign IsJAL      = jal;
    assign MemtoReg   = lw;
    assign MemWrite   = sw;
    assign MemRead    = lw;
    assign Branch     = beq | bne;
    assign BneOrBeq   = bne;
    assign Jump       = j | jal;
    assign RegDst     = r_type;
    assign ZeroExtend = (OpCode == OPC_ANDI) | (OpCode == OPC_ORI) | (OpCode == OPC_XORI);
    assign IsCOP0     = (OpCode == OPC_COP0);

    // ReadRs conditions: R-type funct or specific I-type
    wire funct_rs =
        (Funct == 6'b000000) | (Funct == 6'b000001) |
        (Funct == 6'b000100) | (Funct == 6'b100000) |
        (Funct == 6'b100001) | (Funct == 6'b100010) |
        (Funct == 6'b100011) | (Funct == 6'b101011) |
        (Funct == 6'b001000);
    wire imm_rs =
        (OpCode == 6'b000100) | (OpCode == 6'b000101) |
        (OpCode == 6'b000110) | (OpCode == 6'b000111) |
        (OpCode == 6'b001000) | (OpCode == 6'b001001) |
        (OpCode == 6'b001010) | (OpCode == 6'b001011);
    assign ReadRs = r_type & funct_rs | (~OpCode[5]&~OpCode[4]&~OpCode[3]&~OpCode[2]&~OpCode[1]&~OpCode[0] & imm_rs);

    // ReadRt conditions: R-type funct or load/store
    wire funct_rt =
        (Funct == 6'b000000) | (Funct == 6'b000010) |
        (Funct == 6'b000011) | (Funct == 6'b001000);
    wire data_rt = lw | sw;
    assign ReadRt = r_type & funct_rt | data_rt;

    // ALUSrc and RegWrite
    assign ALUSrc   = (OpCode == OPC_ADDI) | lw | sw |
                      (OpCode == OPC_ANDI) | (OpCode == OPC_ORI) |
                      (OpCode == OPC_SLTI);
    assign RegWrite = r_type |
                      (OpCode == OPC_ADDI) | (OpCode == OPC_ADDIU) |
                      (OpCode == OPC_SLTI) | (OpCode == OPC_ANDI) |
                      (OpCode == OPC_ORI) | lw | jal | IsCOP0;

    // JR, Shamt, Syscall
    assign IsJR      = r_type & (Funct == 6'b001000);
    assign IsShamt   = r_type & ((Funct == 6'b000000) | (Funct == 6'b000010));
    assign IsSyscall = r_type & (Funct == 6'b001100);

    // ALUOp decoding
    wire temp_ALU0 = (Funct == 6'b100101) | (Funct == 6'b100111) |
                     (Funct == 6'b101010) | (Funct == 6'b101011);
    wire temp_ALU1 = (Funct == 6'b100000) | (Funct == 6'b100001) |
                     (Funct == 6'b100010) | (Funct == 6'b100100) |
                     (Funct == 6'b101011);
    wire temp_ALU2 = (Funct == 6'b100010) | (Funct == 6'b100100) |
                     (Funct == 6'b000010) | (Funct == 6'b100111) |
                     (Funct == 6'b101010);
    wire temp_ALU3 = (Funct == 6'b000011) | (Funct == 6'b100001) |
                     (Funct == 6'b100000) | (Funct == 6'b100100) |
                     (Funct == 6'b101010);

    wire opcode_ALU0 = (OpCode == 6'b001101) | (OpCode == 6'b001010);
    wire opcode_ALU1 = r_type | (OpCode == OPC_ADDI) | lw | sw |
                       (OpCode == OPC_BEQ) | (OpCode == OPC_BNE) |
                       (OpCode == OPC_ANDI) | (OpCode == OPC_ADDIU) |
                       (OpCode == OPC_JAL) | IsCOP0;
    wire opcode_ALU2 = (OpCode == OPC_ANDI) | (OpCode == OPC_SLTI);
    wire opcode_ALU3 = r_type | (OpCode == OPC_ANDI) | (OpCode == OPC_ADDI) |
                       lw | sw | (OpCode == OPC_BEQ) | (OpCode == OPC_BNE) |
                       (OpCode == OPC_SLTI) | (OpCode == OPC_ADDIU) | jal | IsCOP0;

    assign ALUOp[3] = r_type ? temp_ALU0      : opcode_ALU0;
    assign ALUOp[2] = r_type ? temp_ALU1      : opcode_ALU1;
    assign ALUOp[1] = r_type ? temp_ALU2      : opcode_ALU2;
    assign ALUOp[0] = r_type ? temp_ALU3      : opcode_ALU3;

endmodule

