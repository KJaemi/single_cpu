module SignExtend (
    input  wire [15:0] imm16,       // 16-bit immediate input
    input  wire        sel_zero,    // 1: zero-extend, 0: sign-extend
    output wire [31:0] imm32        // 32-bit extended output
);

    // Internal extension wires
    wire [31:0] w_signext;          // sign-extended version
    wire [31:0] w_zeroext;          // zero-extended version

    // Perform sign-extension
    assign w_signext = {{16{imm16[15]}}, imm16};

    // Perform zero-extension
    assign w_zeroext = {16'b0, imm16};

    // Select between sign- and zero-extension
    assign imm32 = sel_zero ? w_zeroext : w_signext;

endmodule
