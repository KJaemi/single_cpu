`timescale 1ns/1ps

module tb_single_cycle_cpu_top;
    // Clock, Reset, Exception Sources
    reg         clk;
    reg         rst;
    reg         expSrc0;
    reg         expSrc1;
    reg         expSrc2;

    // DUT Outputs
    wire [31:0] stat_r_count;
    wire [31:0] stat_i_count;
    wire [31:0] stat_j_count;
    wire [31:0] stat_total_count;
    wire [31:0] hex_out;
    wire [31:0] inst_out;
    wire [5:0]  opcode_out;
    wire        is_syscall_out;
    wire [31:0] a0;

    // Instantiate Device Under Test with named port mapping
    single_cycle_cpu_top uut (
        .clk            (clk),
        .rst            (rst),
        .expSrc0        (expSrc0),
        .expSrc1        (expSrc1),
        .expSrc2        (expSrc2),
        // Instruction Type Statistics Outputs
        .stat_r_count   (stat_r_count),
        .stat_i_count   (stat_i_count),
        .stat_j_count   (stat_j_count),
        .stat_total_count(stat_total_count),
        // Syscall Hex Display Output
        .hex_out        (hex_out),
        // Exposed Test Signals
        .inst_out       (inst_out),
        .opcode_out     (opcode_out),
        .is_syscall_out (is_syscall_out),
        .a0             (a0)
    );

    // Generate clock: 10 ns period
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Reset and stimulus
    initial begin
        // Initialize inputs
        rst     = 1;
        expSrc0 = 0;
        expSrc1 = 0;
        expSrc2 = 0;
        #20;
        rst = 0;

        // Extend simulation time (e.g., 10000 ns)
        #10000;
        $display("[TB] Simulation finished at time %0t ns", $time);
        $finish;
    end

    // Monitor key signals every cycle
    always @(posedge clk) begin
        $display("Time=%0t | PC=0x%08h INST=0x%08h OPCODE=0x%02h SYSCALL=%b A0=0x%08h R=%0d I=%0d J=%0d Total=%0d Hex=0x%08h", 
                  $time, uut.pc, inst_out, opcode_out, is_syscall_out, a0,
                  stat_r_count, stat_i_count, stat_j_count, stat_total_count,
                  hex_out);
    end

endmodule
