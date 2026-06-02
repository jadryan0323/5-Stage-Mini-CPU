# upgraded-memory
This 5-stage pipelined MIPS CPU is built in Verilog for a Xilinx Zybo FPGA. It includes Instruction Fetch, Decode, Execute, Memory, and Write Back stages. The architecture features internal data forwarding and pipeline stall logic to handle hazards, alongside a delayed branch slot. It is verified using a looping test subroutine in ModelSim.
