`timescale 1ns/1ps

// --------------------------------------------------
// Instruction Memory (reads from hex file)
// --------------------------------------------------
module InstMem #(
    parameter ADDR_WIDTH = 10,                          // 2^10 words
    parameter DATA_WIDTH = 32,                          // 32-bit instruction
    parameter ROM_FILE  = "C:/Users/PC/Desktop/logiccircuit/instruction/rom1.hex"
)(
    input  wire [31:0]              addr,               // byte-address from PC
    output reg  [DATA_WIDTH-1:0]    instr               // fetched instruction
);
    localparam DEPTH = (1 << ADDR_WIDTH);
    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    initial begin
        // load the entire array from the ASCII hex file
        $readmemh(ROM_FILE, mem);
    end

    always @(*) begin
        // drop the low 2 bits to convert byte?word index
        instr = mem[ addr[31:2] ];
    end
endmodule


// --------------------------------------------------
// Mux to switch between two ROMs based on sel
// --------------------------------------------------
`timescale 1ns/1ps

module InstMemMux #(
    parameter ADDR_WIDTH = 10,
    parameter DATA_WIDTH = 32
)(
    input  wire                   sel,      // 0?rom1, 1?rom2
    input  wire [31:0]            addr,     // byte address
    output wire [DATA_WIDTH-1:0]  instr
);
    wire [DATA_WIDTH-1:0] instr0, instr1;

    // rom1 instance
    InstMem #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .ROM_FILE("C:/Users/PC/Desktop/logiccircuit/instruction/rom1.hex")
    ) rom0 (
        .addr(addr),
        .instr(instr0)
    );

    // rom2 instance
    InstMem #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .ROM_FILE("C:/Users/PC/Desktop/logiccircuit/instruction/rom2.hex")
    ) rom1 (
        .addr(addr),
        .instr(instr1)
    );

    // final output
    assign instr = sel ? instr1 : instr0;
endmodule

