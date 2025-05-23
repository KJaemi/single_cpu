module PC (
    input clk,
    input rst,
    input hasExp,
    input isEret,
    input isCOP0,
    input [31:0] cp0_target_addr,
    input [31:0] pc_plus4,
    output reg [31:0] pc
);
    // ?? ??? ?? ?? ??
    localparam [31:0] EXCEPTION_ADDR = 32'h00000800;

    wire and_cop0_eret = isCOP0 && isEret;
    wire [31:0] mux2_out = and_cop0_eret ? cp0_target_addr : pc_plus4;
    wire [31:0] mux1_out = ~hasExp ? mux2_out : EXCEPTION_ADDR;

    // ?? ?? MUX
    wire clk_sel = hasExp || and_cop0_eret;
    wire gated_clk = clk_sel ? ~clk : clk;

    always @(posedge gated_clk or posedge rst) begin
        if (rst)
            pc <= 32'h00000000; // ?? PC ?
        else
            pc <= mux1_out;
    end
endmodule

