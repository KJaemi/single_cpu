module PC (
    input  wire        clk,
    input  wire        rst,
    input  wire        hasExp,
    input  wire        isEret,
    input  wire        isCOP0,
    input  wire [31:0] cp0_target_addr,
    input  wire [31:0] pc_plus4,
    output reg  [31:0] pc
);
    localparam [31:0] EXCEPTION_ADDR = 32'h00000800;

    // 예외→ERET→기본 흐름 우선순위로 next_pc 결정
    wire [31:0] next_pc = hasExp                     ? EXCEPTION_ADDR   :
                          (isCOP0 && isEret)        ? cp0_target_addr  :
                                                       pc_plus4;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pc <= 32'h00000000;
        end else begin
            pc <= next_pc;  // 항상 clk에 동기되어, next_pc만 바뀔 뿐
        end
    end
endmodule
