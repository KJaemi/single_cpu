`timescale 1ns/1ps

//------------------------------------------------------------------------------
// ALU with Integrated Operations and Adder32/Subtractor32 Submodules
//------------------------------------------------------------------------------
module ALU (
    input  wire [31:0] x,         // operand X
    input  wire [31:0] y,         // operand Y
    input  wire [3:0]  sel,       // operation select

    output reg  [31:0] result,    // primary result
    output reg  [31:0] result2,   // secondary result (e.g., high of multiply, remainder)
    output reg         OF,        // signed overflow flag
    output reg         CF,         // carry/borrow flag
	output wire        equal 
);
    // Internal wires for each operation
    wire [4:0] shift_amt = y[4:0];
    wire [31:0] shl_lo   = x << shift_amt;                  // logical left shift
    wire [31:0] shr_la   = $signed(x) >>> shift_amt;       // arithmetic right shift
    wire [31:0] shr_lu   = x >> shift_amt;                  // logical right shift
    wire [63:0] prod     = $unsigned(x) * $unsigned(y);     // unsigned multiply
    wire [31:0] mul_lo   = prod[31:0];                      // low 32-bit of product
    wire [31:0] mul_hi   = prod[63:32];                     // high 32-bit of product
    wire [31:0] quot     = x / y;                           // quotient
    wire [31:0] rem      = x % y;                           // remainder
    wire [31:0] and_o    = x & y;
    wire [31:0] or_o     = x | y;
    wire [31:0] xor_o    = x ^ y;
    wire [31:0] nor_o    = ~(x | y);
    // 1-bit comparators
    wire comp_s1 = ($signed(x) < $signed(y));  // signed compare, 1-bit output
    wire comp_u1 = (x < y);                   // unsigned compare, 1-bit output
	assign equal = (x == y);
    // Adder/Subtractor submodules
    wire [31:0] sum;
    wire        cf_sum, of_sum;
    Adder32 adu (
        .A     (x),
        .B     (y),
        .Cin   (1'b0),
        .Result(sum),
        .CF    (cf_sum),
        .OF    (of_sum)
    );

    wire [31:0] diff;
    wire        cf_sub, of_sub;
    Subtractor32 sbu (
        .A     (x),
        .B     (y),
        .Bin   (1'b0),
        .Result(diff),
        .CF    (cf_sub),
        .OF    (of_sub)
    );

    // Main result multiplexer
    always @(*) begin
        case (sel)
            4'd0:  result = shl_lo;
            4'd1:  result = shr_la;
            04'd2:  result = shr_lu;
            4'd3:  result = mul_lo;
            4'd4:  result = quot;
            4'd5:  result = sum;
            4'd6:  result = diff;
            4'd7:  result = and_o;
            4'd8:  result = or_o;
            4'd9:  result = xor_o;
            4'd10: result = nor_o;
            4'd11: result = {31'b0, comp_s1};
            4'd12: result = {31'b0, comp_u1};
            default: result = 32'b0;
        endcase
    end

    // Secondary result multiplexer (high product, remainder)
    always @(*) begin
        case (sel)
            4'd3:  result2 = mul_hi;
            4'd4:  result2 = rem;
            default: result2 = 32'b0;
        endcase
    end

    // Flag multiplexers
    always @(*) begin
        case (sel)
            4'd5: begin OF = of_sum; CF = cf_sum; end  // adder flags
            4'd6: begin OF = of_sub; CF = cf_sub; end  // subtractor flags
            default: begin OF = 1'b0; CF = 1'b0; end
        endcase
    end
endmodule

//------------------------------------------------------------------------------
// 32-bit Adder with Carry-in, Carry-out (CF) and Overflow (OF) Detection
//------------------------------------------------------------------------------
module Adder32 (
    input  wire [31:0] A,
    input  wire [31:0] B,
    input  wire        Cin,    // initial carry-in
    output wire [31:0] Result, // sum output
    output wire        CF,     // Carry Flag (unsigned overflow)
    output wire        OF      // Overflow Flag (signed overflow)
);
    // ?? ?? ??
    wire [30:0] sum_lo;       // bits [30:0]
    wire        carry_lo;     // carry from bit 30 to 31
    wire        carry_hi;     // carry out from bit 31

    // 0~30?? ??
    assign {carry_lo, sum_lo} = A[30:0] + B[30:0] + Cin;

    // 31?? ??
    assign {carry_hi, Result[31]} = A[31] + B[31] + carry_lo;

    // ?? 31:0 ?? ??
    assign Result[30:0] = sum_lo;

    // CF: ??? ?? ??? ????
    assign CF = carry_hi;

    // OF: bit30->31 ??? bit31->out ??? xor
    assign OF = carry_lo ^ carry_hi;
endmodule


//------------------------------------------------------------------------------
// 32-bit Subtractor with Borrow-in, Borrow-out (CF) and Overflow (OF) Detection
//------------------------------------------------------------------------------
//------------------------------------------------------------------------------
// 32-bit Subtractor with Borrow Chain (Logisim-style)
//------------------------------------------------------------------------------
module Subtractor32 (
    input  wire [31:0] A,
    input  wire [31:0] B,
    input  wire        Bin,      // initial borrow-in (usually 1 for two's complement, but treated as 0 if floating)
    output wire [31:0] Result,   // difference output
    output wire        CF,       // Borrow Flag (unsigned underflow)
    output wire        OF        // Overflow Flag (signed overflow)
);
    // Borrow chain across all bits
    wire [32:0] borrow;
    assign borrow[0] = Bin;  // initial borrow-in (0 if floating)

    genvar i;
    generate
        for (i = 0; i < 32; i = i + 1) begin : BIT_SLICE
            wire ai = A[i];
            wire bi = B[i];
            wire bi_in = borrow[i];
            // Difference bit: ai - bi - bi_in = ai ^ bi ^ bi_in
            assign Result[i] = ai ^ bi ^ bi_in;
            // Borrow-out computation:
            // borrow-out = (~ai & (bi | bi_in)) | (bi & bi_in)
            assign borrow[i+1] = (~ai & (bi | bi_in)) | (bi & bi_in);
        end
    endgenerate

    // Final borrow-out is CF
    assign CF = borrow[32];
    // Signed overflow: borrow into MSB ^ borrow out of MSB
    assign OF = borrow[31] ^ borrow[32];
endmodule

