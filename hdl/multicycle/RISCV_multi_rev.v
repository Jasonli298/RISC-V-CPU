`timescale 1ns/10ps

module RISCVCPU
	#(parameter M  = 100,
	  parameter N  = 50,
	  parameter N2 = 2,
	  parameter REG_WIDTH = 32
	  )
	(CLOCK_50,
	 rstn,
	 done,
	 clock_count,
	 instr_cnt
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

	// Parameters for processor stages
	localparam INIT = 0,
			   IF  = 1,
			   ID  = 2,
			   EX  = 3,
			   MEM = 4,
			   WB  = 5;

	localparam EOF = 32'hFFFF_FFFF; // Defined EOF dummy instruction as all ones

	/////////////////////////////////////////// I/O ///////////////////////////////////////////
	input             CLOCK_50;
	input             rstn;
	wire              clk; // system clock
	output reg        done; // signals the end of a program
	output reg [31:0] clock_count, clock_count_c; // total number of clock cycles to run a program
	output reg [31:0] instr_cnt, instr_cnt_c;
	
	// The architecturally visible registers and scratch registers for implementation
	reg                        wr_en, wr_en_c;
	reg        [31:0]          PC, PC_c, ALUOut, ALUOut_c, MDR, MDR_c, rs1, rs2;
	reg        [REG_WIDTH-1:0] Regs [0:31];
	wire       [31:0]          IR;
	reg        [2:0]           state, state_c; // processor state
	reg signed [31:0]          D_entry, D_entry_c;

	wire        [6:0]  opcode; // use to get opcode easily
	wire        [31:0] ImmGen; // used to generate immediate
	wire        [31:0] PC_addr = PC >> 2;
	wire        [31:0] I_Mem_Out;
	wire        [31:0] DMem_addr_w = ALUOut>>2;
	wire signed [31:0] D_out;
	wire signed [31:0] PCOffset = {{22{IR[31]}}, IR[7], IR[30:25], IR[11:8], 1'b0};

	assign             opcode   = IR[6:0]; // opcode is lower 7 bits
	assign             ImmGen   = (opcode == LW) ? IR[31:20] : {IR[31:25], IR[11:7]};

	clk_divid ckd(.clk(CLOCK_50), .rstn(rstn), .out_clk(clk));
	
	RAM #(32, 35, "IMemory.txt") I_Memory(.wr_en(1'b0),
										  .index(PC_addr),
										  .entry(32'b0),
										  .entry_out(IR),
										  .clk(CLOCK_50)
										  );

	RAM #(32, M*N+N*N2+M*N2, "DMemory.txt") D_Memory(.wr_en(wr_en),
													 .index(DMem_addr_w),
													 .entry(D_entry),
													 .entry_out(D_out),
													 .clk(CLOCK_50)
													 );

	
	always @(posedge CLOCK_50) begin
		state <= state_c;
		PC <= PC_c;
		// IR <= IR_c;
		// ALUOut <= ALUOut_c;
		clock_count <= clock_count_c;
		instr_cnt <= instr_cnt_c;
	end

	always @(*) begin
		clock_count_c = clock_count + 1;
		wr_en = 1'b0;
		PC_c = PC;
		ALUOut = 0;
		rs1 = 0; rs2 = 0;
		done = 1'b0;
		MDR = 32'b0;
		D_entry = 0;
		case(state)
			IF: begin
				// IR = I_Mem_Out;
				PC_c = PC + 4;
				state_c = ID;
			end

			ID: begin
				if (IR != EOF) begin
					rs1 = Regs[IR[19:15]];
					rs2 = Regs[IR[24:20]];
					ALUOut = PC + PCOffset;
					state_c = EX;
				end
				else begin
					done = 1'b1;
				end
			end

			EX: begin

			end

			MEM: begin
				
			end

			WB: begin
				
			end


		if (!rstn) begin
			
		end
	end

	endmodule
