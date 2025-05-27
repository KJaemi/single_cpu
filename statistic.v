`timescale 1ns/1ps
//------------------------------------------------------------------------------
// 32-bit Up-Counter Submodule for Total Instruction Count
//------------------------------------------------------------------------------
module TotalCounter (
    input  wire        clk,
    input  wire        reset,
    output reg  [31:0] total_cnt
);
    always @(posedge clk or posedge reset) begin
        if (reset)
            total_cnt <= 32'd0;
        else
            total_cnt <= total_cnt + 1;
    end
endmodule

//------------------------------------------------------------------------------
// InstructionTypeCounter: separates R-, I-, J-type counts and uses TotalCounter
//------------------------------------------------------------------------------
module InstructionTypeCounter (
    input         clk,
    input         reset,
    input  [5:0]  opcode,
    output reg [31:0] r_count,
    output reg [31:0] i_count,
    output reg [31:0] j_count,
    output     [31:0] total_count
);

    // Type detection flags
    wire r_type_flag;
    wire i_type_flag;
    wire j_type_flag;

    assign r_type_flag = (opcode == 6'b000000);
    assign j_type_flag = (opcode == 6'b000010) || (opcode == 6'b000011);
    assign i_type_flag = ~(r_type_flag || j_type_flag);

    // Instantiate total counter
    TotalCounter total_counter_inst (
        .clk       (clk),
        .reset     (reset),
        .total_cnt (total_count)
    );

    // Individual type counters
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            r_count <= 32'd0;
            i_count <= 32'd0;
            j_count <= 32'd0;
        end else begin
            if (r_type_flag) r_count <= r_count + 1;
            if (i_type_flag) i_count <= i_count + 1;
            if (j_type_flag) j_count <= j_count + 1;
        end
    end

endmodule
