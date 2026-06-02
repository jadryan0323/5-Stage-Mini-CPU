`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Penn State
// Engineer: [Jadryan Pena]
// 
// Create Date: [3/23/2026]
// Target Devices: XC7Z010-CLG400-1
// Description: pipelined CPU
// 
// This testbench verifies the IF and ID stages by:
//   1. Generating a clock signal
//   2. Running the simulation for multiple clock cycles
//   3. Observing the signals in the waveform viewer
//
//////////////////////////////////////////////////////////////////////////////////

//==============================================================================
// TESTBENCH MODULE
//==============================================================================
// The testbench instantiates the datapath and provides the clock signal.
// All internal signals are wired inside the datapath module.
//
// To view internal signals in simulation:
//   1. In Vivado, run behavioral simulation
//   2. In the waveform viewer, expand the datapath instance (dut)
//   3. Add the signals you want to observe:
//      - IF stage: pc, nextpc, instOut
//      - IF/ID register: dinstOut
//      - ID stage: op, rs, rt, rd, func, imm
//      - Control signals: wreg, m2reg, wmem, aluc, aluimm, regrt
//      - Register file outputs: qa, qb
//      - Sign extender output: imm32
//      - ID/EXE register outputs: ewreg, em2reg, ewmem, ealuc, ealuimm,
//                                  edestReg, eqa, eqb, eimm32
//
// Expected behavior:
//   Cycle 1: PC=100, fetch lw $2, 0($1)
//   Cycle 2: PC=104, fetch lw $3, 4($1), decode lw $2, 0($1)
//   Cycle 3: PC=108, decode lw $3, 4($1), execute lw $2, 0($1)
//   ...
//==============================================================================

module testbench();
    
    //--------------------------------------------------------------------------
    // Signal Declaration
    //--------------------------------------------------------------------------
    // TODO: Declare a reg for the clock signal
    // Hint: reg clk;
    reg clk;
    wire [31:0] data_check;
    //--------------------------------------------------------------------------
    // Device Under Test (DUT) Instantiation
    //--------------------------------------------------------------------------
    // TODO: Instantiate the datapath module
    // Hint: The datapath only has clk as input
    Datapath DUT (
        .clk(clk),
        .final_data(data_check)
        );
    
    
    //--------------------------------------------------------------------------
    // Clock Generation
    //--------------------------------------------------------------------------
    // TODO: Initialize the clock to 0
    // Hint: Use an initial block
    //
    
initial clk = 0;
    always #5 clk = ~clk;

   initial begin
        #1000; 
        $stop;
    end

endmodule

