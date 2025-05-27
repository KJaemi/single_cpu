`timescale 1ns/1ps

module tb_single_cycle_cpu;
    // Clock and reset
    reg         clk;
    reg         rst;

    // Exception source inputs
    reg         expSrc0;
    reg         expSrc1;
    reg         expSrc2;

    // Outputs from DUT
    wire [31:0] stat_r_count;
    wire [31:0] stat_i_count;
    wire [31:0] stat_j_count;
    wire [31:0] stat_total_count;
    wire [31:0] hex_out;
    wire [31:0] inst_out;
    wire [5:0]  opcode_out;
    wire        is_syscall_out;
    wire [31:0] a0;

    // Instantiate Device Under Test
    single_cycle_cpu_top uut (
        .clk             (clk),
        .rst             (rst),
        .expSrc0         (expSrc0),
        .expSrc1         (expSrc1),
        .expSrc2         (expSrc2),
        .stat_r_count    (stat_r_count),
        .stat_i_count    (stat_i_count),
        .stat_j_count    (stat_j_count),
        .stat_total_count(stat_total_count),
        .hex_out         (hex_out),
        .inst_out        (inst_out),
        .opcode_out      (opcode_out),
        .is_syscall_out  (is_syscall_out),
        .a0              (a0)
    );

    // Clock generation: 10ns period
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Test sequence and monitoring
    initial begin
        rst      = 1;
        expSrc0  = 0;
        expSrc1  = 0;
        expSrc2  = 0;

        // Release reset after 20ns
        #20 rst = 0;

        // Display header
        $display("time    PC    clk inst_out       sel   addr");
        // Monitor clk, inst_out, sel, addr each time they change
        $monitor("%0t    %h    %b    %h    %b    %0d", 
                 $time,
                 uut.pc,
                 clk,
                 inst_out,
                 uut.inst_mem_mux.sel,
                 uut.inst_mem_mux.addr
        );

        // Trigger exception at cycle 38 (optional)
        repeat (38) @(posedge clk);
        expSrc0 = 1;
        @(posedge clk) expSrc0 = 0;

        // Run additional cycles, then finish
        #500;
        $finish;
    end

endmodule

