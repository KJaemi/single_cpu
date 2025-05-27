module DataMemory (
    input  wire        clk,
    input  wire        MemRead,
    input  wire        MemWrite,
    input  wire [31:0] addr,     // byte address
    input  wire [31:0] WD,       // write data
    output reg  [31:0] RD        // read data
);

    // ?? ?? ?? (?? ???)
    wire [9:0] word_addr = addr[11:2];

    // ??? ??: 1024 words (4KB)
    reg [31:0] memory_array [0:1023];

    // ??? ??: ?? ?? ????
    always @(posedge clk) begin
        if (MemWrite) begin
            memory_array[word_addr] <= WD;
        end
    end

    // ??? ??: ?? ???
    always @(*) begin
        if (MemRead) begin
            RD = memory_array[word_addr];
        end else begin
            RD = 32'h00000000;
        end
    end

endmodule