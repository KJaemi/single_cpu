`timescale 1ns/1ps

module tb_single_cycle_cpu_top;
    // Inputs to DUT
    reg         clk;
    reg         rst;
    reg         inst_sel;
    reg         expSrc0;
    reg         expSrc1;
    reg         expSrc2;

    // Monitored signals
    wire [31:0] stat_r_count;
    wire [31:0] stat_i_count;
    wire [31:0] stat_j_count;
    wire [31:0] stat_total_count;
    wire [31:0] tb_instr;
    wire [5:0]  tb_opcode;
    wire        tb_is_syscall;
    wire [31:0] tb_a0;
    wire [31:0] tb_hex_out;

    // Instantiate the Device Under Test
    single_cycle_cpu_top uut (
        .clk(clk),
        .rst(rst),
        .inst_sel(inst_sel),
        .expSrc0(expSrc0),
        .expSrc1(expSrc1),
        .expSrc2(expSrc2),
        .stat_r_count(stat_r_count),
        .stat_i_count(stat_i_count),
        .stat_j_count(stat_j_count),
        .stat_total_count(stat_total_count),
        .hex_out(tb_hex_out),
        .inst_out(tb_instr),
        .opcode_out(tb_opcode),
        .is_syscall_out(tb_is_syscall),
        .a0(tb_a0)
    );

    // Clock generation: 10 ns period
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Reset and control stimuli
    initial begin
        rst      = 1;
        inst_sel = 0;
        expSrc0  = 0;
        expSrc1  = 0;
        expSrc2  = 0;
        #20;
        rst = 0;
    end

    // Waveform dump
    initial begin
        $dumpfile("tb_single_cycle_cpu_top.vcd");
        $dumpvars(0, tb_single_cycle_cpu_top);
    end

    // Monitor outputs and internal signals
    initial begin
        $display("Time | instr       opcode IsSC   a0        hex_out");
        $monitor("%4t | 0x%h %3d    %b    0x%h  0x%h", 
                 $time,
                 tb_instr,
                 tb_opcode,
                 tb_is_syscall,
                 tb_a0,
                 tb_hex_out);
    end

    // Simulation end
    initial begin
        #1000;
        $display("Simulation finished at %0t ns", $time);
        $finish;
    end
endmodule

