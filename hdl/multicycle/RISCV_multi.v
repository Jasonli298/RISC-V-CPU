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
	localparam IDLE = 0,
               IF   = 1,
			   ID   = 2,
			   EX   = 3,
			   MEM  = 4,
			   WB   = 5;
			   
	localparam EOF = 32'hFFFF_FFFF; // Defined EOF dummy instruction as all ones

	/////////////////////////////////////////// I/O ///////////////////////////////////////////
	input             CLOCK_50;
	input             rstn;
	wire              clk; // system clock
	output reg         done; // signals the end of a program
	output reg  [31:0] clock_count;
	output reg  [31:0] instr_cnt;
	////////////////////////////////// END I/O ////////////////////////////////////////////////

    reg         [REG_WIDTH-1:0] Regs [0:31]; // Register file

    reg         [31:0] clock_count_c, instr_cnt_c;
	reg         [2:0]  state, state_c;
	reg         [31:0] PC, PC_c;
	reg         [31:0] PC_addr;
	reg         [31:0] MDR, MDR_c;

	wire        [31:0] IR, IR_c;
	reg                wr_en;
    //reg                read_en;
	reg         [31:0] ALUOut, rs1, rs2;

	reg signed  [31:0] D_entry;

	wire        [6:0]  opcode; // use to get opcode easily
	wire        [31:0] ImmGen; // used to generate immediate
	
    reg         [31:0] DMem_addr;
    wire        [31:0] DMem_addr_w = DMem_addr;
	wire signed [31:0] D_out;
	wire signed [31:0] PCOffset = {{22{IR[31]}}, IR[7], IR[30:25], IR[11:8], 1'b0};

	assign             opcode   = IR[6:0]; // opcode is lower 7 bits
	assign             ImmGen   = (opcode == LW) ? IR[31:20] : {IR[31:25], IR[11:7]};
	
	RAM #(32, 35, "IMemory.txt") I_Memory(.wr_en(1'b0),
                                          //.read_en(1'b1),
										  .index(PC_addr),
										  .entry(32'b0),
										  .entry_out(IR),
										  .clk(CLOCK_50)
										  );

	RAM #(32, M*N+N*N2+M*N2, "DMemory.txt") D_Memory(.wr_en(wr_en),
                                                     //.read_en(read_en),
													 .index(DMem_addr),
													 .entry(D_entry),
													 .entry_out(D_out),
													 .clk(CLOCK_50)
													 );

	// set the PC to 0 and start the control in state 1
	integer i;
	// initial begin
	// 	for (i = 0; i <= 31; i = i + 1) Regs[i] = 32'b0;
	// 	PC = 0; 
	// 	state = IDLE;
	// 	clock_count = 0;
	// 	instr_cnt = 0;
	// 	PC_addr = 0;
    //     MDR = 0;
	// end

    always @(posedge CLOCK_50) begin
        clock_count   <= clock_count_c;
        instr_cnt     <= instr_cnt_c;
		state         <= state_c;
		PC 			  <= PC_c;
		MDR			  <= MDR_c;

        // Reset logic
        if (!rstn) begin
            for (i = 0; i < 32; i = i + 1) Regs[i] <= 32'b0;
            done <= 0;
            PC <= 0;
            state <= IDLE;
            clock_count <= 0;
            instr_cnt <= 0;
            PC_addr <= 0;
            MDR <= 0;
            DMem_addr = 0;
            ALUOut = 0;
            rs1 = 0;
            rs2 = 0;
        end
	end

	// The state machine--triggered on a rising clock
	always @(*) begin
		clock_count_c = clock_count + 1;
        instr_cnt_c   = instr_cnt;
		state_c 	  = state;
		PC_c 		  = PC;
		MDR_c         = MDR;
		wr_en         = 1'b0;
		D_entry       = 0;
        DMem_addr     = DMem_addr;   

		case(state)
			IDLE:begin
				state_c = IF;
			end

			IF:begin
				PC_c = PC + 4;
				state_c = ID;
			end

			ID:begin
				if (IR != EOF) begin
					
					rs1 = Regs[IR[19:15]];
					rs2 = Regs[IR[24:20]];
					ALUOut = PC + PCOffset; // compute PC-relative branch target
					done = 1'b0;
					state_c = EX;
				end 
				else begin
					done = 1'b1;
				end
			end

			EX:begin
                instr_cnt_c = instr_cnt + 1;
				case(opcode)
					R_I: begin // R-type
						case (IR[31:25]) // Check funct7 
							7'b0000000: begin
								case (IR[14:12]) 
									3'b000: begin // add
										ALUOut = rs1 + rs2;                 
										state_c = MEM;
									end
								endcase
							end
							7'b0100000: begin
								//***sub***
								case (IR[14:12]) 
									3'b000: begin    // sub 
										ALUOut = rs1 - rs2;    
										state_c = MEM;
									end
								endcase
							end
							7'b0000001: begin
								case (IR[14:12]) 
									3'b000: begin   // mul
										ALUOut = rs1 * rs2;                 
										state_c = MEM;
									end
								endcase
							end
						endcase 
					end

					Imm_I: begin
						case (IR[14:12])   // addi
							3'b000: begin 
								ALUOut = rs1 + IR[31:20]; 
								state_c = MEM;
							end
						endcase
					end

					I_I: begin
						case(IR[14:12])
							3'b010: begin // lw 
								ALUOut = rs1 + ImmGen;
                                DMem_addr = ALUOut >> 2;
								state_c = MEM;
							end
						endcase
					end

					B_I: begin
						case(IR[14:12]) 
							3'b100: begin  // blt
								if (rs1 < rs2) begin
									PC_c = ALUOut;
									PC_addr = (PC + PCOffset) >> 2;
								end
								else begin
									PC_addr = PC >> 2;
								end
								state_c = IF;
							end
						endcase
					end

					S_I: begin
						case(IR[14:12]) 
							3'b010: begin
								ALUOut = rs1 + ImmGen; //sw
                                DMem_addr = ALUOut >> 2;
								state_c = MEM;
							end
						endcase
						//wr_en <= 1'b1;
					end

				endcase
			end
			////////////////////////////////////////////// END EX ///////////////////////////////////////////////////////

			////////////////////////////////////////////// MEM Stage ///////////////////////////////////////////////////
			MEM:begin
				case(opcode)
					R_I: begin // R-type
						case (IR[31:25]) 
							7'b0000000: begin
								case (IR[14:12]) 
									3'b000: begin // add 
										Regs[IR[11:7]] = ALUOut;
										PC_addr = PC >> 2; 
										state_c = IF;
									end
								endcase
							end
							7'b0100000: begin
								case (IR[14:12])
									3'b000: begin// sub
										Regs[IR[11:7]] = ALUOut;
										PC_addr = PC >> 2; 
										state_c = IF;
									end
								endcase
							end
							7'b0000001: begin
								case (IR[14:12]) 
									3'b000: begin // mul
										Regs[IR[11:7]] = ALUOut; 
										PC_addr = PC >> 2;             
										state_c = IF;
									end
								endcase
							end
						endcase 
					end 
					Imm_I: begin 
						case (IR[14:12])
							3'b000: begin //addi
								Regs[IR[11:7]] = ALUOut;
								PC_addr = PC >> 2;
								state_c = IF;
							end
						endcase
					end
					I_I: begin
						case(IR[14:12])
							3'b010: begin // lw
								MDR_c = D_out;
								state_c = WB;
							end
						endcase
					end
					S_I: begin
						case(IR[14:12])  
							3'b010: begin //sw
								wr_en = 1'b1;
								D_entry = rs2;
								PC_addr = PC >> 2; 
								state_c = IF; 
							end
						endcase
					end
				endcase
			end

			WB:begin
				Regs[IR[11:7]] = MDR;
				PC_addr = PC >> 2;
				state_c = IF;
			end
		endcase
	end

endmodule
