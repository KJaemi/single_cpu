module SyscallDecoderFull (
    input  wire        clk,
    input  wire        enable,       // syscall active
    input  wire [7:0]  v0,           // syscall code
    input  wire [31:0] a0,           // argument register
    output wire        halt,         // true when enable and v0 == 10
    output reg  [31:0] hex_out = 32'b0  // initialize to zero
);

    // Halt when enabled and v0 equals 10
    assign halt = enable ? (v0 == 8'd10) : 1'b0;

    // Hex output: latch a0 whenever enable is asserted on posedge clk
    always @(posedge clk) begin
        if (enable)
            hex_out <= a0;
    end

endmodule
