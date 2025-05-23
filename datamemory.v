

module DataMemory (
    input  wire        clk,
    input  wire        MemRead,
    input  wire        MemWrite,
    input  wire [31:0] addr,     // ?? (byte ??)
    input  wire [31:0] WD,       // Write Data
    output reg  [31:0] RD        // Read Data
);

    // ??? ???: 1024?? ?? (4KB ???)
    reg [31:0] mem [0:1023];

    // Read: ???
    always @(*) begin
        if (MemRead)
            RD = mem[addr[11:2]];  // word ?? ?? ??
        else
            RD = 32'h00000000;
    end

    // Write: ?? ?????? ??
    always @(posedge clk) begin
        if (MemWrite)
            mem[addr[11:2]] <= WD;  // word ?? ??
    end

endmodule