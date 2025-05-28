`timescale 1ns/1ps

module single_cycle_cpu_top (
    input  wire        clk,
    input  wire        rst,
    input  wire        expSrc0,             // exception source 0
    input  wire        expSrc1,             // exception source 1
    input  wire        expSrc2,             // exception source 2

    // Instruction Type Statistics Outputs
    output wire [31:0] stat_r_count,
    output wire [31:0] stat_i_count,
    output wire [31:0] stat_j_count,
    output wire [31:0] stat_total_count,

    // Syscall Hex Display Output
    output wire [31:0] hex_out,

    // Exposed Test Signals
    output wire [31:0] inst_out,
    output wire [5:0]  opcode_out,
    output wire        is_syscall_out,
    output wire [31:0] a0
);

    // Program Counter and Next PC Logic
    wire [31:0] pc;
    wire [31:0] next_pc;
    wire [31:0] pc_plus4 = pc + 32'd4;
	
    // Exception and ERET Signals
    wire        hasExp;
    wire        isEret;

    // CP0 Target PC output
    wire [31:0] PCout;

    // Instruction Memory (word-aligned ??? ?? ROM1/ROM2 ?? ??)
    wire [31:0] instr;
    
    // Expose for testbench
    assign inst_out   = instr;
    assign opcode_out = instr[31:26];

    // Instruction Statistics
    InstructionTypeCounter inst_stat (
        .clk        (clk),
        .reset      (rst),
        .opcode     (opcode_out),
        .r_count    (stat_r_count),
        .i_count    (stat_i_count),
        .j_count    (stat_j_count),
        .total_count(stat_total_count)
    );

    // Control Signals
    wire        IsJAL, RegWrite, MemtoReg, IsCOP0;
    wire        MemWrite, MemRead, IsJR, Branch;
    wire        BneOrBeq, Jump, ALUSrc;
    wire        IsShamt, IsSyscall, RegDst, ZeroExtend;
    wire [3:0]  ALUOp;

    // Expose syscall for testbench
    assign is_syscall_out = IsSyscall;

    // Control Unit
    ControlUnit control (
        .OpCode     (opcode_out),
        .Funct      (instr[5:0]),
        .IsJAL      (IsJAL),
        .RegWrite   (RegWrite),
        .MemtoReg   (MemtoReg),
        .IsCOP0     (IsCOP0),
        .MemWrite   (MemWrite),
        .MemRead    (MemRead),
        .IsJR       (IsJR),
        .Branch     (Branch),
        .BneOrBeq   (BneOrBeq),
        .Jump       (Jump),
        .ALUSrc     (ALUSrc),
        .IsShamt    (IsShamt),
        .IsSyscall  (IsSyscall),
        .RegDst     (RegDst),
        .ZeroExtend (ZeroExtend),
        .ReadRs     (),
        .ReadRt     (),
        .ALUOp      (ALUOp)
    );

    // Program Counter Instance
    PC pc_inst (
        .clk          (clk),
        .rst          (rst),
        .hasExp       (hasExp),
        .isEret       (isEret),
        .isCOP0       (IsCOP0),
        .cp0_target_addr(PCout),
        .pc_plus4     (next_pc),
        .pc           (pc)
    );
// 올바른 예


InstructionMemory inst_mem_mux (
	.sel(pc[11]),
        .pc    (pc),
        .instr (instr)
    );

    // Register File Address Selection for Syscall
    wire [4:0] reg1_addr = IsSyscall ? 5'd2           : instr[25:21];
    wire [4:0] reg2_addr = IsSyscall ? 5'd4           : instr[20:16];
    wire [4:0] write_reg = IsJAL    ? 5'd31           :
                          (RegDst  ? instr[15:11] : instr[20:16]);
    wire [31:0] write_data;

    // Register File and Syscall Inputs
    wire [31:0] RsData, RtData;
    wire [31:0] v0;
    RegFile reg_file (
        .clk        (clk),
        .we         (RegWrite),
        .reg1       (reg1_addr),
        .reg2       (reg2_addr),
        .write_reg  (write_reg),
        .write_data (write_data),
        .R1         (RsData),
        .R2         (RtData),
        .ra         (),
        .s0         (),
        .s1         (),
        .s2         (),
        .a0         (a0),
        .v0         (v0)
    );

    // Sign Extend Immediate and Shift Amount
    wire [31:0] signimm;
    SignExtend sign_ext (
        .imm16      (instr[15:0]),
        .sel_zero   (ZeroExtend),
        .imm32      (signimm)
    );
    wire [4:0] shamt = instr[10:6];

    // ALU Input Selection
    wire [31:0] alu_src_b = IsShamt ? {27'd0, shamt} : (ALUSrc ? signimm : RtData);
    wire [31:0] alu_x     = IsShamt ? RtData       : RsData;

    // ALU Operation
    wire [31:0] alu_result, alu_result2;
    wire        OF, CF, equal;
    ALU alu (
        .x      (alu_x),
        .y      (alu_src_b),
        .sel    (ALUOp),
        .result (alu_result),
        .result2(alu_result2),
        .OF     (OF),
        .CF     (CF),
        .equal  (equal)
    );

    // Data Memory Access (word-addressed)
    wire [31:0] mem_data;
    DataMemory data_mem (
        .clk     (clk),
        .MemRead (MemRead),
        .MemWrite(MemWrite),
        .addr    (alu_result[11:2]),
        .WD      (RtData),
        .RD      (mem_data)
    );

    // CP0 Top-level Module Instantiation
    wire        ExpBlock = 1'b0;
    wire [31:0] Dout;
    CP0_Top cp0_inst (
        .clk        (clk),
        .enable     (IsCOP0),
        .inst       (instr),
        .Din        (RtData),
        .PCin       (pc),
        .expSrc0    (expSrc0),
        .expSrc1    (expSrc1),
        .expSrc2    (expSrc2),
        .ExRegWrite (RegWrite),
        .ExpBlock   (ExpBlock),
        .IsEret     (isEret),
        .HasExp     (hasExp),
        .PCout      (PCout),
        .Dout       (Dout)
    );

    // Write-Back MUX: JAL, CP0, MEM, ALU
    wire [31:0] alu_or_mem = MemtoReg ? mem_data : alu_result;
 assign write_data = IsCOP0 ? Dout : IsJAL ? pc_plus4 : alu_or_mem;



// 3) SyscallDecoderFull 인스턴스
SyscallDecoderFull u_syscall_dec (
    .clk     (clk),
    .enable  (IsSyscall),    // ← 여기 IsSyscall → resultValid
    .v0      (v0[7:0]),        // $v0 코드
    .a0      (a0),    // ← 여기 a0 → displayData
    .halt    (halt),
    .hex_out (hex_out)
);
    // Branch Logic
    wire [31:0] branch_target;
    Adder32 branch_adder (
        .A     (pc_plus4),
        .B     (signimm << 2),
        .Cin   (1'b0),
        .Result(branch_target),
        .CF    (),
        .OF    ()
    );
    wire [31:0] pc_branch = Branch && (BneOrBeq ^ equal)
                             ? branch_target
                             : pc_plus4;

    // JR용 target은 무조건 RsData
    wire [31:0] jr_target   = RsData;
    // J, JAL용 target
    wire [31:0] j_target    = {pc_plus4[31:28], instr[25:0], 2'b00};

    // next_pc 결정: JR 우선 → J/JAL → Branch → PC+4
    assign next_pc = IsJR          ? jr_target
                     : Jump         ? j_target
                     : pc_branch;

endmodule

