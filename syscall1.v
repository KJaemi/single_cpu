
module Comparator8 (
    input  wire [7:0] a,
    input  wire [7:0] b,
    output wire       eq
);
    assign eq = (a == b);
endmodule

module Mux2 (
    input  wire sel,   // Enable
    input  wire in0,   // 
    input  wire in1,   // q
    output wire out
);
    assign out = sel ? in1 : in0;
endmodule

module HaltDecoder (
    input  wire [7:0] v0,   
    input  wire       enable,  
    output wire       halt     
);
    wire eq_result;

    Comparator8 cmp (
        .a(v0),
        .b(8'd10),
        .eq(eq_result)
    );

   
    Mux2 mux (
        .sel(enable),
        .in0(1'b0),
        .in1(eq_result),
        .out(halt)
    );
endmodule

module HexOutput(
    input  wire        clk,
    input  wire        enable,
    input  wire [7:0]  v0,    
    input  wire [31:0] a0,   
    output reg  [31:0] hex_out 
);

    always @(posedge clk) begin
        if (enable && v0 == 8'd1) begin
            hex_out <= a0;
        end
    end

endmodule


module SyscallDecoderFull (
    input  wire        clk,
    input  wire        enable,
    input  wire [7:0]  v0,
    input  wire [31:0] a0,
    output wire        halt,
    output wire [31:0] hex_out
);

   
    HaltDecoder halt_unit (
        .v0(v0),
        .enable(enable),
        .halt(halt)
    );

  
    HexOutput hex_unit (
        .clk(clk),
        .enable(enable),
        .v0(v0),
        .a0(a0),
        .hex_out(hex_out)
    );

endmodule