//Statistics +TypeCycle
module InstructionTypeCounter (
    input         clk,
    input         reset,
    input  [5:0]  opcode,
    output reg [31:0] r_count,
    output reg [31:0] i_count,
    output reg [31:0] j_count,
    output reg [31:0] total_count  // ? ??? ??
);

    wire is_r_type;
    wire is_i_type;
    wire is_j_type;

    // ??? ?? ??
    assign is_r_type = (opcode == 6'b000000);
    assign is_j_type = (opcode == 6'b000010) || (opcode == 6'b000011);
    assign is_i_type = ~(is_r_type || is_j_type);

    // ?? ???
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            r_count      <= 0;
            i_count      <= 0;
            j_count      <= 0;
            total_count  <= 0;
        end else begin
            // ? ??? ?? ?? ??
            total_count <= total_count + 1;

            // ??? ???
            if (is_r_type) r_count <= r_count + 1;
            if (is_i_type) i_count <= i_count + 1;
            if (is_j_type) j_count <= j_count + 1;
        end
    end

endmodule