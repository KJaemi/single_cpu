`timescale 1ns/1ps

//------------------------------------------------------------------------------
// Register File with explicit 2-level demux, 32 latches, and reset initialization
//------------------------------------------------------------------------------
module RegFile (
    input  wire        clk,
    input  wire        we,          // global write enable
    input  wire [4:0]  reg1,        // read address 1
    input  wire [4:0]  reg2,        // read address 2
    input  wire [4:0]  write_reg,   // write address
    input  wire [31:0] write_data,  // write data
    output wire [31:0] R1,          // read data 1
    output wire [31:0] R2,          // read data 2
    output wire [31:0] ra,          // register 31
    output wire [31:0] s0,          // register 16
    output wire [31:0] s1,          // register 17
    output wire [31:0] s2,          // register 18
    output wire [31:0] a0,          // register 4
    output wire [31:0] v0           // register 2
);
    // First-level demux: we -> we_group[0..3] using write_reg[4:3]
    wire [3:0] we_group;
    assign we_group = we ? (4'b0001 << write_reg[4:3]) : 4'b0000;

    // Second-level demux: each group -> 8 enables using write_reg[2:0]
    wire [7:0] we_sub [3:0];
    genvar g;
    generate
        for (g = 0; g < 4; g = g + 1) begin : GROUP_DEMUX
            assign we_sub[g] = we_group[g] ? (8'b00000001 << write_reg[2:0]) : 8'b00000000;
        end
    endgenerate

    // 32 latches (registers) with enable from demux outputs and reset initialization
    reg [31:0] regs [31:0];
    integer idx;
    initial begin
        // Initialize all registers to zero
        for (idx = 0; idx < 32; idx = idx + 1)
            regs[idx] = 32'b0;
    end

    genvar i;
    generate
        for (i = 0; i < 32; i = i + 1) begin : REG_LATCH
            wire en = we_sub[i/8][i%8];
            always @(posedge clk) begin
                if (en)
                    regs[i] <= write_data;
            end
        end
    endgenerate

    // Read multiplexers: select reg1 and reg2
    // reg0 always reads 0
    assign R1 = (reg1 == 5'd0) ? 32'b0 : regs[reg1];
    assign R2 = (reg2 == 5'd0) ? 32'b0 : regs[reg2];

    // Named outputs for specific registers
    assign ra = regs[31];
    assign s0 = regs[16];
    assign s1 = regs[17];
    assign s2 = regs[18];
    assign a0 = regs[4];
    assign v0 = regs[2];

endmodule

