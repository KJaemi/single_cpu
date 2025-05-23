
`timescale 1ns/1ps
//------------------------------------------------------------------------------
// 1. SignalDecode: extracts ERET, sel, ExRegWrite from inst
//------------------------------------------------------------------------------
module SignalDecode(
    input  wire [31:0] inst,
    output wire        IsEret,
    output wire [1:0]  sel,
    output wire        ExRegWrite
);
    assign IsEret     = ~inst[0] & ~inst[1] & ~inst[2] & inst[3] & inst[4] & ~inst[5];
    assign sel        = inst[12:11];
    assign ExRegWrite = ~inst[23];
endmodule
//------------------------------------------------------------------------------
//------------------------------------------------------------------------------
// 2. ExceptionSignals: gating, ExpClick, HasExp
//------------------------------------------------------------------------------
module ExceptionSignals(
    input  wire        clk,           // system clock for hasExp gating
    input  wire        blocksrc0,
    input  wire        blocksrc1,
    input  wire        blocksrc2,
    input  wire        expSrc0,
    input  wire        expSrc1,
    input  wire        expSrc2,
    input  wire        expBlock,     // status[0]
    output wire        expClick,
    output wire        hasExp
);
    // gate exception sources via block selectors
    wire aa = ~blocksrc0 & expSrc0;
    wire bb = ~blocksrc1 & expSrc1;
    wire cc = ~blocksrc2 & expSrc2;
    // one-cycle new-exception pulse: high when source asserted and not already in block
    wire dd = (aa | bb | cc) & ~expBlock;
    assign expClick = dd;

    // FF1: set on rising edge of dd, clear on rising edge of ff2
    reg ee,ff2;
    always @(posedge dd or posedge ff2) begin
        if (ff2)
            ee <= 1'b0;
        else
            ee <= 1'b1;
    end

    // hasExp pulses when ee is high at clk rising edge
    assign hasExp = ee & clk;

    // FF2: set on rising edge of hasExp, async clear when ee deasserts
	wire add ;
	assign add = ~ee;
    always @(negedge hasExp or posedge add) begin
        if (add)
            ff2 <= 1'b0;
        else
            ff2 <= 1'b1;
    end
endmodule

//------------------------------------------------------------------------------
// 3. Registers: EPC, Status, Block, Cause, multiplex PCin/Din
//------------------------------------------------------------------------------
module Registers(
    input  wire        clk,
    input  wire        enable,
    input  wire        ExRegWrite,
    input  wire        hasExp,
    input  wire [31:0] Din,
    input  wire        expSrc0,
    input  wire        expSrc1,
    input  wire        expSrc2,
    input  wire        expClick,
    input  wire [1:0]  sel,
    input  wire [31:0] PCin,
    output wire [31:0] PCout,
    output wire [31:0] Dout,
    output wire        blocksrc0,
    output wire        blocksrc1,
    output wire        blocksrc2,
    output wire        ExpBlock
);
    // one-hot decode of sel: 00->0, 01->1, 10->2, 11->floating
    wire [2:0] onehot = (sel==2'd0)? 3'b001 :
                        (sel==2'd1)? 3'b010 :
                        (sel==2'd2)? 3'b100 :
                                      3'bzzz;
    // control enables
    wire a = onehot[0] & enable & ~ExRegWrite | hasExp; // EPC
    wire b = onehot[1] & enable & ~ExRegWrite;           // Status
    wire c = onehot[2] & enable & ~ExRegWrite;           // Block

    // Registers with initial reset to zero
    reg [31:0] epc;
    reg [31:0] status;
    reg [31:0] block;
    reg [31:0] cause;
    initial begin
        epc    = 32'b0;
        status = 32'b0;
        block  = 32'b0;
        cause  = 32'b0;
    end

    // EPC latch: async load PCin/Din based on hasExp
    always @(posedge clk) begin
        if (a)
            epc <= hasExp ? PCin : Din;
    end
    assign PCout = epc;

    // Status[0] latch: store Din when b
    always @(posedge clk) begin
        if (b)
            status <= Din;
    end
    assign ExpBlock = status[0];

    // Block latch: store Din when c
    always @(posedge clk) begin
        if (c)
            block <= Din;
    end
    assign blocksrc0 = block[0];
    assign blocksrc1 = block[1];
    assign blocksrc2 = block[2];

    // Cause latch: load cause on expClick
    wire [31:0] buf0 = expSrc0 ? 32'h00000001 : 32'bz;
    wire [31:0] buf1 = expSrc1 ? 32'h00000003 : 32'bz;
    wire [31:0] buf2 = expSrc2 ? 32'h00000007 : 32'bz;
    wire [31:0] cause_in = buf0 | buf1 | buf2;
    always @(posedge expClick) begin
        cause <= cause_in;
    end

    // Dout mux
    assign Dout = (sel==2'd0)? epc :
                  (sel==2'd1)? status :
                  (sel==2'd2)? block :
                                cause;
endmodule

//------------------------------------------------------------------------------
// CP0 Top Module: integrates SignalDecode, Registers, ExceptionSignals
//------------------------------------------------------------------------------
module CP0_Top (
    input  wire        clk,         // system clock
    input  wire        enable,      // global enable for CP0 registers
    input  wire [31:0] inst,        // instruction word (from IF stage)
    input  wire [31:0] Din,         // data input (from RegFile D2)
    input  wire [31:0] PCin,        // next PC value
    input  wire        expSrc0,     // exception source 0
    input  wire        expSrc1,     // exception source 1
    input  wire        expSrc2,     // exception source 2

    output wire        ExRegWrite,  // pulse to write EPC/Cause registers
    output wire        ExpBlock,    // status[0] latched exception indicator
    output wire        IsEret,      // ERET instruction flag
    output wire        HasExp,      // exception active flag
    output wire [31:0] PCout,       // output EPC
    output wire [31:0] Dout         // CP0 data output (EPC/Status/Block/Cause)
);
    // Internal connections
    wire [1:0] sel;
    wire        expClick;
    wire        block0, block1, block2;

    // 1) Decode instruction for ERET, sel, ExRegWrite
    SignalDecode u_sigdec (
        .inst       (inst),
        .IsEret     (IsEret),
        .sel        (sel),
        .ExRegWrite (ExRegWrite)
    );

    // 2) Registers: EPC, Status, Block, Cause, and Dout mux
    Registers u_regs (
        .clk        (clk),
        .enable     (enable),
        .ExRegWrite (ExRegWrite),
        .hasExp     (HasExp),
        .Din        (Din),
        .expSrc0    (expSrc0),
        .expSrc1    (expSrc1),
        .expSrc2    (expSrc2),
        .expClick   (expClick),
        .sel        (sel),
        .PCin       (PCin),
        .PCout      (PCout),
        .Dout       (Dout),
        .blocksrc0  (block0),
        .blocksrc1  (block1),
        .blocksrc2  (block2),
        .ExpBlock   (ExpBlock)
    );

    // 3) Exception signal generation: expClick and hasExp
    ExceptionSignals u_excsig (
        .clk        (clk),
        .blocksrc0  (block0),
        .blocksrc1  (block1),
        .blocksrc2  (block2),
        .expSrc0    (expSrc0),
        .expSrc1    (expSrc1),
        .expSrc2    (expSrc2),
        .expBlock   (ExpBlock),
        .expClick   (expClick),
        .hasExp     (HasExp)
    );

endmodule
