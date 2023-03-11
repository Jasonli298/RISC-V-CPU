`timescale 1ns/10ps

module RISCVCPU
    #(parameter M         = 100,
      parameter N         = 50,
      parameter N2        = 2,
      parameter REG_WIDTH = 32
     )
    (CLOCK_50,
     rst,
     done,
     clock_count,
     instr_count,
     );
    
    // Parameters for opcodes
	localparam R_I   = 7'b011_0011,
			   I_I   = 7'b000_0011,
			   Imm_I = 7'b001_0011,
			   S_I   = 7'b010_0011,
			   B_I   = 7'b110_0011,
			   U_I   = 7'b011_0111,
			   J_I   = 7'b110_1111,
			   AUIPC = 7'b001_0111,
			   LW    = 7'b000_0011; // also I type

    input CLOCK_50;
    input rst;
    wire clk;
    
    reg [2:0] state, state_c;
    
    
    wire        [6:0]  opcode; // use to get opcode easily
	wire        [31:0] ImmGen; // used to generate immediate
	wire        [31:0] PC_addr = PC >> 2;
	wire        [31:0] I_Mem_Out;
	wire        [31:0] DMem_addr_w = ALUOut>>2;
	wire signed [31:0] D_out;
	wire signed [31:0] PCOffset = {{22{IR[31]}}, IR[7], IR[30:25], IR[11:8], 1'b0};

    assign             clk      = CLOCK_50;
	assign             opcode   = IR[6:0]; // opcode is lower 7 bits
	assign             ImmGen   = (opcode == LW) ? IR[31:20] : {IR[31:25], IR[11:7]};



endmodule