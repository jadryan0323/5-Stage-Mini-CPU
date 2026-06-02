DATAPATH.V CODE:
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Penn State
// Engineer: [Jadryan]
// 
// Create Date: [3/25/2026]
// Design Name: Lab 3 - Instruction Fetch and Decode
// Module Name: datapath
// Project Name: Lab 3 - Instruction Fetch and Decode
// Target Devices: XC7Z010-CLG400-1
// Description: Implementation of IF and ID stages of a 5-stage pipelined CPU
// 
// Instructions to implement:
//   Address 100: lw $v0, 00($at)  ->  lw $2, 0($1)
//   Address 104: lw $v1, 04($at)  ->  lw $3, 4($1)
//   Assume register $at ($1) has value 0
//
//////////////////////////////////////////////////////////////////////////////////

//==============================================================================
// TOP-LEVEL DATAPATH MODULE
//==============================================================================
// This module connects all the pipeline stages together.
// Input:  clk - clock signal
// Output: None (all signals are internal)
//
// You need to:
// 1. Declare all internal wires to connect the modules
// 2. Instantiate all 9 modules and connect them properly
// 3. Decode the instruction fields (op, rs, rt, rd, func, imm) from dinstOut
//==============================================================================

module Datapath(
    input clk,
    output [31:0] final_data
);

    // TODO: Declare wires for IF stage
    // Hint: You need wires for pc, nextpc, instOut
    wire [31:0] pc, nextpc, instout;
    wire [31:0] dpc4, dinstOut; // dinstOut is the instruction in ID stage
    wire wpcir;
    wire [31:0] pc4;

    // --- ID Stage Decoding ---
   
    wire [5:0] op = dinstOut[31:26];
    wire [4:0] rs = dinstOut[25:21];
    wire [4:0] rt = dinstOut[20:16];
    wire [4:0] rd = dinstOut[15:11];
    wire [5:0] func = dinstOut[5:0];
    wire [15:0] imm = dinstOut[15:0];
    
    
    wire wreg, m2reg, wmem, aluimm, regrt, rsrtequ;
    wire [3:0] aluc;
    wire [1:0] pcsrc;
    wire [31:0] qa, qb, imm32, da, db, bpc, jpc;
    wire [4:0] destReg;

   
    wire ewreg, em2reg, ewmem, ealuimm;
    wire [3:0] ealuc;
    wire [31:0] eqa, eqb, eimm32, ealu_r;
    wire [4:0] edestReg;
    
    wire mwreg, mm2reg, mwmem;
    wire [31:0] malu_r, mqb, m_data_out;
    wire [4:0] mdestReg;
    
    wire wwreg, wm2reg;
    wire [4:0] w_destReg;
    wire [31:0] w_data_out, w_alu_r, w_data;

    // --- Hazard & Forwarding Logic ---
    wire i_rs = (op == 6'h0) || (op == 6'h23) || (op == 6'h8) || (op == 6'h4) || (op == 6'h5) || (op == 6'h8); 
    wire i_rt = (op == 6'h0) || (op == 6'h4) || (op == 6'h5);

    wire stall = ewreg && em2reg && (edestReg != 0) && ((i_rs && (edestReg == rs)) || (i_rt && (edestReg == rt)));
    assign wpcir = !stall;

    // Forwarding muxes to ID stage (for branches)
    assign da = (rs == 0) ? 0 : 
                (rs == edestReg && ewreg) ? ealu_r : 
                (rs == mdestReg && mwreg) ? malu_r : qa;
    assign db = (rt == 0) ? 0 : 
                (rt == edestReg && ewreg) ? ealu_r : 
                (rt == mdestReg && mwreg) ? malu_r : qb;

    assign rsrtequ = ~|(da ^ db);
    assign bpc = dpc4 + { {14{imm[15]}}, imm, 2'b00 }; 
    assign jpc = { dpc4[31:28], dinstOut[25:0], 2'b00 };

   assign nextpc = (pcsrc === 2'bxx) ? pc + 4 :
                (pcsrc == 2'b01)  ? bpc    : 
                (pcsrc == 2'b10)  ? da     : 
                (pcsrc == 2'b11)  ? jpc    : 
                                    pc + 4;
                                    
   wire [31:0] b_val, forwardA, forwardB;
   
   assign forwardA = (rs != 0 && rs == mdestReg && mwreg) ? malu_r :
                  (rs != 0 && rs == w_destReg && wwreg) ? w_data :
                  eqa;

   assign forwardB = (rt != 0 && rt == mdestReg && mwreg) ? malu_r :
                  (rt != 0 && rt == w_destReg && wwreg) ? w_data :
                  eqb;
                  
   assign b_val = ealuimm ? eimm32 : forwardB;

    //==========================================================================
    // STAGE 1: INSTRUCTION FETCH (IF) - Instantiate modules
    //==========================================================================
    
    // TODO: Instantiate PC (Program Counter)
    PC pc_reg (
        .clk(clk),
        .wpcir(wpcir),
        .nextpc(nextpc), 
        .pc(pc)          
        );
    // TODO: Instantiate PCAdd4 (PC + 4 Adder)
    PCAdd4 pc_adder(
    .pc(pc),
    .nextpc(pc4)
    );
    // TODO: Instantiate IM (Instruction Memory)
    IM im (
    .pc(pc),
    .instOut(instout)
    );
    // TODO: Instantiate IFID (IF/ID Pipeline Register)
    IFID if_id (
    .clk(clk),
    .wpcir(wpcir),
    .pc4(pc4),
    .instOut(instout),
    .dpc4(dpc4),
    .dinstOut(dinstOut)
    );


    //==========================================================================
    // STAGE 2: INSTRUCTION DECODE (ID) - Instantiate modules
    //==========================================================================
    
    // TODO: Instantiate CU (Control Unit)
    CU cu (
    .op(op),
    .func(func),
    .rsrtequ(rsrtequ),
    .pcsrc(pcsrc),
    .wreg(wreg),
    .m2reg(m2reg),
    .wmem(wmem),
    .aluc(aluc),
    .aluimm(aluimm),
    .regrt(regrt)
    );
    // TODO: Instantiate Regfile (Register File)
   Regfile rf(
         .clk(clk),
        .rs(rs), .rt(rt),
        .wreg(wwreg),         
        .destReg(w_destReg),  
        .d(w_data),          
        .qa(qa), .qb(qb)
        );
    
    // TODO: Instantiate Mux (Regrt Multiplexer)
    Mux reg_mux (
    .rd(rd),
    .rt(rt),
    .regrt(regrt),
    .destReg(destReg)
    );
    // TODO: Instantiate Ext (Sign Extender)
    Ext ext (
    .imm(imm),
    .imm32(imm32)
    );
    // TODO: Instantiate IDEXE (ID/EXE Pipeline Register)
    IDEXE id_exe (
    .clk(clk),
    .wreg(wreg),
    .m2reg(m2reg),
    .wmem(wmem),
    .daluc(aluc),      
    .aluimm(aluimm),
    .ddestReg(destReg), 
    .qa(da),
    .qb(db),
    .imm32(imm32),
    .ewreg(ewreg),
    .em2reg(em2reg),
    .ewmem(ewmem),
    .ealuc(ealuc),
    .ealuimm(ealuimm),
    .edestReg(edestReg),
    .eqa(eqa),
    .eqb(eqb),
    .eimm32(eimm32)
    );
    
    //Stage 3:
    
    
    ALU alu_unit (
    .a(forwardA),
    .b(b_val),
    .aluc(ealuc),
    .r(ealu_r)
);
   
   EXMEM em_mem_reg(
    .clk(clk),
    .ewreg(ewreg), .em2reg(em2reg), .ewmem(ewmem),
    .ealu_r(ealu_r),    
    .eqb(eqb), 
    .edestReg(edestReg), 
    .mwreg(mwreg), .mm2reg(mm2reg), .mwmem(mwmem),
    .malu_r(malu_r),  
    .mqb(mqb), 
    .mdestReg(mdestReg)
   );
   
   
   // Stage 4 ---> memory
    
    DataMem data_memory(
    .clk(clk),
    .address(malu_r),
    .datain(mqb),
    .wmem(mwmem),
    .dataout(m_data_out)
    );
    
    MEMWB mem_wb_reg (
    .clk(clk),
    .mm2reg(mm2reg), 
    .mwreg(mwreg),
    .malu_r(malu_r),
    .m_data_out(m_data_out),
    .mdestReg(mdestReg), 
    .wwreg(wwreg),
    .wm2reg(wm2reg),
    .w_alu_r(w_alu_r),
    .w_data_out(w_data_out),
    .w_destReg(w_destReg)
    );
    
    // stage 5
    assign w_data = wm2reg ? w_data_out : w_alu_r;
    assign final_data = w_data;
endmodule

//==============================================================================
// STAGE 1: INSTRUCTION FETCH (IF) MODULES
//==============================================================================

//------------------------------------------------------------------------------
// PC - Program Counter
//------------------------------------------------------------------------------
// Holds the address of the current instruction being fetched.
// Starts at address 100 as specified in the lab.
//
// Inputs:
//   clk     - clock signal (update PC on positive edge)
//   nextpc  - the next PC value (PC + 4)
//
// Outputs:
//   pc      - current program counter value (32 bits)
//
// Hints:
//   - Use an initial block to set pc = 100
//   - Use always @(posedge clk) to update pc with nextpc
//   - Use non-blocking assignment (<=) in sequential logic
//------------------------------------------------------------------------------

module PC(
    input clk,
    input wpcir,
    input [31:0] nextpc,
    output reg [31:0] pc
);
    // TODO: Implement the program counter
    // Initialize pc to 100, update to nextpc on each clock edge
    initial begin 
        pc = 32'h0;
    end
    always @(posedge clk) begin
        if (wpcir) pc <= nextpc;
        end
endmodule


//------------------------------------------------------------------------------
// PCAdd4 - PC + 4 Adder
//------------------------------------------------------------------------------
// Calculates the address of the next sequential instruction.
//
// Inputs:
//   pc      - current program counter value (32 bits)
//
// Outputs:
//   nextpc  - next program counter value (pc + 4) (32 bits)
//
// Hints:
//   - This is combinational logic, use always @(*)
//------------------------------------------------------------------------------

module PCAdd4(
    input [31:0] pc,
    output reg [31:0] nextpc
);
    // TODO: Implement the PC + 4 adder
    always @(*) begin
        nextpc = pc + 32'd4;
        end

endmodule


//------------------------------------------------------------------------------
// IM - Instruction Memory
//------------------------------------------------------------------------------
// Stores the program instructions. Read-only memory.
// Address 100 (index 25) and 104 (index 26) contain the lw instructions.
//
// Inputs:
//   pc      - program counter (address to read from) (32 bits)
//
// Outputs:
//   instOut - instruction at the given address (32 bits)
//
// Hints:
//   - Declare a reg array: reg [31:0] instructions [0:127]
//   - Use initial block 
//------------------------------------------------------------------------------

module IM(
    input [31:0] pc,
    output reg [31:0] instOut
);
    // TODO: Declare instruction memory array
    reg [31:0] instructions [0:63];
    // TODO: Initialize instructions at index 25 and 26
    integer i; 

    initial begin
        instructions[6'h00] = 32'h3c010000; // (00) lui $1, 0 
        instructions[6'h01] = 32'h34240050; // (04) ori $4, $1, 80 
        instructions[6'h02] = 32'h0c00001b; // (08) jal sum 
        instructions[6'h03] = 32'h20050004; // (0c) addi $5, $0, 4 (dslot1)
        instructions[6'h04] = 32'hac820000; // (10) sw $2, 0($4) 
        instructions[6'h05] = 32'h8c890000; // (14) lw $9, 0($4) 
        instructions[6'h06] = 32'h01244022; // (18) sub $8, $9, $4 
        instructions[6'h07] = 32'h20050003; // (1c) addi $5, $0, 3 
        instructions[6'h08] = 32'h20a5ffff; // (20) addi $5, $5, -1 
        instructions[6'h09] = 32'h34a8ffff; // (24) ori $8, $5, 0xffff
        instructions[6'h0a] = 32'h39085555; // (28) xori $8, $8, 0x5555
        instructions[6'h0b] = 32'h2009ffff; // (2c) addi $9, $0, -1 
        instructions[6'h0c] = 32'h312affff; // (30) andi $10,$9,0xffff
        instructions[6'h0d] = 32'h01493025; // (34) or $6, $10, $9 
        instructions[6'h0e] = 32'h01494026; // (38) xor $8, $10, $9 
        instructions[6'h0f] = 32'h01463824; // (3c) and $7, $10, $6 
        instructions[6'h10] = 32'h10a00003; // (40) beq $5, $0, shift 
        instructions[6'h11] = 32'h00000000; // (44) nop (dslot2)
        instructions[6'h12] = 32'h08000008; // (48) j loop2 
        instructions[6'h13] = 32'h00000000; // (4c) nop (dslot3)
        instructions[6'h14] = 32'h2005ffff; // (50) addi $5, $0, -1 
        instructions[6'h15] = 32'h000543c0; // (54) sll $8, $5, 15 
        instructions[6'h16] = 32'h00084400; // (58) sll $8, $8, 16 
        instructions[6'h17] = 32'h00084403; // (5c) sra $8, $8, 16 
        instructions[6'h18] = 32'h000843c2; // (60) srl $8, $8, 15 
        instructions[6'h19] = 32'h08000019; // (64) j finish 
        instructions[6'h1a] = 32'h00000000; // (68) nop (dslot4)
        instructions[6'h1b] = 32'h00004020; // (6c) sum: add $8, $0, $0 
        instructions[6'h1c] = 32'h8c890000; // (70) loop: lw $9, 0($4) 
        instructions[6'h1d] = 32'h01094020; // (74) add $8, $8, $9 (stall)
        instructions[6'h1e] = 32'h20a5ffff; // (78) addi $5, $5, -1 
        instructions[6'h1f] = 32'h14a0fffc; // (7c) bne $5, $0, loop 
        instructions[6'h20] = 32'h20840004; // (80) addi $4, $4, 4 (dslot5)
        instructions[6'h21] = 32'h03e00008; // (84) jr $31 
        instructions[6'h22] = 32'h00081000;
            end
    // TODO: Read instruction based on pc (use pc >> 2 or pc / 4 as index)
    always @(*) begin
        instOut = instructions[pc[7:2]];
    end
endmodule


//------------------------------------------------------------------------------
// IFID - IF/ID Pipeline Register
//------------------------------------------------------------------------------
// Stores the instruction fetched in IF stage for use in ID stage.
// Updates on the positive edge of the clock.
//
// Inputs:
//   clk     - clock signal
//   instOut - instruction from instruction memory (32 bits)
//
// Outputs:
//   dinstOut - instruction passed to ID stage (32 bits)
//
// Hints:
//   - Use always @(posedge clk)
//   - Use non-blocking assignment (<=)
//------------------------------------------------------------------------------

module IFID(
    input clk,
    input wpcir,
    input [31:0] pc4,
    input [31:0] instOut,
    output reg [31:0] dpc4,
    output reg [31:0] dinstOut
);
    // TODO: Implement the IF/ID pipeline register
        
    initial begin
        dpc4 = 0;
        dinstOut = 0;
    end
    always @ (posedge clk) begin
        if (wpcir) begin
            dpc4 <= pc4;      
            dinstOut <= instOut;
        end
    end
endmodule


//==============================================================================
// STAGE 2: INSTRUCTION DECODE (ID) MODULES
//==============================================================================

//------------------------------------------------------------------------------
// CU - Control Unit
//------------------------------------------------------------------------------
// Generates control signals based on the opcode and function code.
//
// Inputs:
//   op      - opcode field from instruction (6 bits)
//   func    - function field from instruction (6 bits)
//
// Outputs:
//   wreg    - write enable for register file (1 bit)
//   m2reg   - memory to register (1 = load data from memory) (1 bit)
//   wmem    - write enable for data memory (1 bit)
//   aluc    - ALU control signals (4 bits)
//   aluimm  - ALU source B select (1 = use immediate) (1 bit)
//   regrt   - register destination select (0 = rd, 1 = rt) (1 bit)
//
// Hints:
//   - Use a case statement on the opcode
//   - Add a default case to handle undefined opcodes
//------------------------------------------------------------------------------

module CU(
    input [5:0] op,
    input [5:0] func,
    input rsrtequ,
    output reg[1:0] pcsrc,
    output reg wreg,
    output reg m2reg,
    output reg wmem,
    output reg [3:0] aluc,
    output reg aluimm,
    output reg regrt
);
    // TODO: Implement the control unit using a case statement
    always@(*) begin
        pcsrc = 2'b00; 
        {wreg, m2reg, wmem, aluimm, regrt} = 5'b00000;
        aluc = 4'b0000;
        
        case(op)
            6'b000000: begin
                wreg = 1; regrt = 0; aluimm = 0;
            case (func)
                6'b100000: aluc = 4'b0010;
                6'b100010: aluc = 4'b0110;
                6'b100100: aluc = 4'b0000;
                6'b100101: aluc = 4'b0001; 
                6'b100110: aluc = 4'b0011;
                6'b001000: begin
                    wreg = 0;
                    pcsrc = 2'b10;
                end
                default: aluc = 4'b0000;
            endcase
        end
        
      6'b000010: pcsrc = 2'b11;
      
      6'b100011: begin
            wreg = 1; m2reg = 1; aluimm = 1; regrt = 1; aluc = 4'b0010;
      end
      6'b101011: begin
            wmem = 1; aluimm = 1; regrt = 1; aluc = 4'b0010;
      end
      
      6'b001000: begin
            wreg = 1; aluimm = 1; regrt = 1; aluc = 4'b0010;
      end
      
      6'b000100: begin
            if (rsrtequ) pcsrc = 2'b01; // Branch taken if equal
      end
      6'b000011: begin
        wreg = 1; pcsrc = 2'b11; 
      end
      
      default: begin
        {wreg, m2reg, wmem, aluimm, regrt} = 5'b00000;
         aluc = 4'b0000;
      end
  endcase
  end
      
endmodule


//------------------------------------------------------------------------------
// Regfile - Register File
//------------------------------------------------------------------------------
// Contains 32 general-purpose registers. Provides two read ports.
// All registers should be initialized to 0.
//
// Inputs:
//   rs      - source register 1 address (5 bits)
//   rt      - source register 2 address (5 bits)
//
// Outputs:
//   qa      - data from register rs (32 bits)
//   qb      - data from register rt (32 bits)
//
// Hints:
//   - Declare a reg array: reg [31:0] registers [0:31]
//   - Use a for loop in initial block to set all registers to 0
//   - Use always @(*) for combinational read logic
//------------------------------------------------------------------------------

module Regfile(
    input clk,
    input [4:0] rs, rt,
    input wreg,
    input[4:0] destReg,
    input[31:0] d,
    output [31:0] qa,
    output [31:0] qb
);
    // TODO: Declare register array
    reg [31:0] registers [0:31];
    // TODO: Initialize all 32 registers to 0
    integer i;
    initial begin
        for (i = 0; i < 32; i = i + 1) begin
        registers[0] = 32'h00000000;
    registers[1] = 32'hA00000AA;
    registers[2] = 32'h10000011;
    registers[3] = 32'h20000022;
    registers[4] = 32'h30000033;
    registers[5] = 32'h40000044;
    registers[6] = 32'h50000055;
    registers[7] = 32'h60000066;
    registers[8] = 32'h70000077;
    registers[9] = 32'h80000088;
    registers[10] = 32'h90000099;
    
    // rest = 0
    registers[11] = 0; registers[12] = 0; registers[13] = 0;
    registers[14] = 0; registers[15] = 0; registers[16] = 0;
    registers[17] = 0; registers[18] = 0; registers[19] = 0;
    registers[20] = 0; registers[21] = 0; registers[22] = 0;
    registers[23] = 0; registers[24] = 0; registers[25] = 0;
    registers[26] = 0; registers[27] = 0; registers[28] = 0;
    registers[29] = 0; registers[30] = 0; registers[31] = 0;
        end
    end
    // TODO: Read registers based on rs and rt
     assign qa = registers[rs];
     assign qb = registers[rt];
    
    always @(posedge clk) begin
        if (wreg && (destReg != 5'b0)) begin
            registers[destReg] <= d;
         end
     end
    
endmodule


//------------------------------------------------------------------------------
// Mux - Regrt Multiplexer
//------------------------------------------------------------------------------
// Selects the destination register number.
// For R-type instructions, destination is rd.
// For I-type instructions (like lw), destination is rt.
//
// Inputs:
//   rd      - destination register for R-type (5 bits)
//   rt      - destination register for I-type (5 bits)
//   regrt   - select signal (0 = rd, 1 = rt)
//
// Outputs:
//   destReg - selected destination register (5 bits)
//
// Hints:
//   - Use if-else
//   - When regrt = 0, select rd
//   - When regrt = 1, select rt
//------------------------------------------------------------------------------

module Mux(
    input [4:0] rd,
    input [4:0] rt,
    input regrt,
    output reg [4:0] destReg
);
    // TODO: Implement the multiplexer
    always @(*) begin
        if (regrt == 1'b0) begin
            destReg = rd;
            end
        else begin
            destReg = rt;
            end
        end
endmodule


//------------------------------------------------------------------------------
// Ext - Immediate Extender
//------------------------------------------------------------------------------
// Extends the 16-bit immediate value to 32 bits using sign extension.
//
// Inputs:
//   imm     - 16-bit immediate value from instruction
//
// Outputs:
//   imm32   - 32-bit sign-extended immediate
//
// Hints:
//   - Use concatenation with replication
//   - imm[15] is the sign bit
//   - Replicate the sign bit 16 times and concatenate with original imm
//------------------------------------------------------------------------------

module Ext(
    input [15:0] imm,
    output reg [31:0] imm32
);
    // TODO: Implement sign extension
    always @(*) begin
        imm32 = {{16{imm[15]}}, imm};
        end
endmodule


//------------------------------------------------------------------------------
// IDEXE - ID/EXE Pipeline Register
//------------------------------------------------------------------------------
// Stores all control signals and data from ID stage for use in EXE stage.
// Updates on the positive edge of the clock.
//
// Inputs:
//   clk     - clock signal
//   wreg    - write register enable (1 bit)
//   m2reg   - memory to register (1 bit)
//   wmem    - write memory enable (1 bit)
//   aluc    - ALU control (4 bits)
//   aluimm  - ALU immediate select (1 bit)
//   destReg - destination register (5 bits)
//   qa      - register data A (32 bits)
//   qb      - register data B (32 bits)
//   imm32   - sign-extended immediate (32 bits)
//
// Outputs (active in EXE stage, prefix 'e'):
//   ewreg   - write register enable
//   em2reg  - memory to register
//   ewmem   - write memory enable
//   ealuc   - ALU control
//   ealuimm - ALU immediate select
//   edestReg - destination register
//   eqa     - register data A
//   eqb     - register data B
//   eimm32  - sign-extended immediate
//
// Hints:
//   - Use always @(posedge clk)
//   - Use non-blocking assignments (<=)
//   - Transfer each input to its corresponding output
//------------------------------------------------------------------------------

module IDEXE(
    input clk,
    input wreg,
    input m2reg,
    input wmem,
    input [3:0] daluc,
    input aluimm,
    input [4:0] ddestReg,
    input [31:0] qa,
    input [31:0] qb,
    input [31:0] imm32,
    output reg ewreg,
    output reg em2reg,
    output reg ewmem,
    output reg [3:0] ealuc,
    output reg ealuimm,
    output reg [4:0] edestReg,
    output reg [31:0] eqa,
    output reg [31:0] eqb,
    output reg [31:0] eimm32
);
    // TODO: Implement the ID/EXE pipeline register
    initial begin
        ewreg = 0; em2reg = 0; ewmem = 0; ealuc = 4'b0; ealuimm = 0;
        edestReg = 5'b0; eqa = 32'h0; eqb = 32'h0; eimm32 = 32'h0;
    end

    always @(posedge clk) begin
        ewreg    <= wreg; 
        em2reg   <= m2reg; 
        ewmem    <= wmem; 
        ealuimm  <= aluimm; 
        eqa      <= qa; 
        eqb      <= qb; 
        eimm32   <= imm32;
        ealuc    <= daluc;    
        edestReg <= ddestReg;
        
        end
endmodule

// Lab 4 new modules :)

module ALU(
    input[31:0] a, b,
    input [3:0] aluc,
    output reg[31:0] r
);

    always @(*)
    begin
        case (aluc)
            4'b0010: r = a + b;
            default: r = 32'b0;
        endcase
    end
endmodule

module DataMem(
    input clk, 
    input [31:0] address,
    input [31:0] datain, 
    input wmem,
    output [31:0] dataout
    );
    
    reg [31:0] dmem[0:31];
    integer i;
    
    assign dataout = dmem[address[6:2]];
    
    initial begin
    for (i = 0; i < 32; i = i + 1) dmem[i] = 32'b0;
        dmem[0] = 32'hA00000AA;
        dmem[1] = 32'h10000011;
        dmem[2] = 32'h20000022;
        dmem[3] = 32'h30000033;
        dmem[4] = 32'h40000044;
        dmem[5] = 32'h50000055;
        dmem[6] = 32'h60000066;
        dmem[7] = 32'h70000077;
        dmem[8] = 32'h80000088;
        dmem[9] = 32'h90000099;
    end
    
    
    
    
    always @(posedge clk) begin
        if (wmem) begin
            dmem[address >> 2] <= datain;
        end
    end
endmodule

module EXMEM(
            input clk, ewreg, em2reg, ewmem,
    input [31:0] ealu_r, eqb,
    input [4:0] edestReg,
    output reg mwreg, mm2reg, mwmem,
    output reg [31:0] malu_r, mqb,
    output reg [4:0] mdestReg
    );
    
    initial begin
        malu_r = 32'h0;
        mqb = 32'h0;
        mdestReg = 5'h0;
        mwreg = 0;
        mm2reg = 0;
        mwmem = 0;
    end
    
    always@(posedge clk) begin 
        mwreg    <= ewreg;
        mm2reg   <= em2reg;
        mwmem    <= ewmem;
        malu_r   <= ealu_r;
        mqb      <= eqb;
        mdestReg <= edestReg; 
    end
endmodule
        
module MEMWB(
             input clk, mwreg, mm2reg,
    input [31:0] m_data_out, malu_r,
    input [4:0] mdestReg,
    output reg wwreg, wm2reg,
    output reg [31:0] w_data_out, w_alu_r,
    output reg [4:0] w_destReg
    );
    
    initial begin
        wwreg = 0; wm2reg = 0;
        w_alu_r = 32'h0; w_data_out = 32'h0; w_destReg = 5'b0;
    end
    
    always @(posedge clk) begin
        wwreg <= mwreg; 
        wm2reg <= mm2reg;
        w_data_out <= m_data_out;  
        w_alu_r <= malu_r;        
        w_destReg <= mdestReg; 
        
        end
endmodule
