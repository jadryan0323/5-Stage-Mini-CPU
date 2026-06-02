# upgraded-memory

A hardware implementation of a 5-stage pipelined MIPS CPU designed in Verilog HDL and targeted for the Xilinx Zybo FPGA platform (XC7Z010-1CLG400C). 

## 🚀 Overview
This project builds a pipelined microprocessor that optimizes instruction throughput by executing multiple instructions concurrently across five classic stages:
1. **Instruction Fetch (IF)**
2. **Instruction Decode (ID)**
3. **Instruction Execute (EXE)**
4. **Memory Access (MEM)**
5. **Write Back (WB)**

## 🛠️ Design Features
* **Hazard Resolution:** Internal data forwarding networks path execution results directly to the ALU, minimizing stall cycles.
* **Pipeline Stalling:** Hardware interlocking freezes the PC and IF/ID registers during load-use dependencies to maintain data integrity.
* **Control Handling:** Implements a single **delayed branch** slot mechanism, resolving branch and jump conditions early in the ID stage.
* **Supported Instructions:** Handles 20 core MIPS instructions covering arithmetic (`add`, `sub`), logic (`and`, `or`, `xor`), shifts, memory references (`lw`, `sw`), and control flow (`j`, `jal`, `jr`, `beq`, `bne`).

## 🧪 Simulation & Verification
The architecture is fully validated using ModelSim timing simulations with a behavioral test bench. 

The design is stress-tested via a **20-instruction routine** that executes a loops-and-sum subroutine over a memory array. This script contains purposeful code patterns to verify that both the internal forwarding logic and structural stalls activate correctly under data and control hazards.

## 📁 Project Contents
* **Verilog Source Code:** Structural hardware descriptions for each discrete pipeline stage, the register file, and control units.
* **Test Bench:** Behavioral verification environment utilizing a `1ns/1ps` timescale.
* **Synthesis & Implementation Assets:** Timing waveforms, RTL schematic maps, I/O planning layouts, and floorplanning snapshots.
