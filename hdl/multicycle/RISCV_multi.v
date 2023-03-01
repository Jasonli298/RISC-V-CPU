`timescale 1ns/10ps

module RISCVCPU 
    #(parameter M  = 2,
      parameter N  = 4,
	  parameter N2 = 2,
	  parameter REG_WIDTH = 32
	  )
    (CLOCK_50,
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
    localparam IF  = 1,
               ID  = 2,
               EX  = 3,
               MEM = 4,
               WB  = 5;

    localparam EOF = 32'hFFFF_FFFF; // Defined EOF dummy instruction as all ones

	/////////////////////////////////////////// I/O ///////////////////////////////////////////
	input             CLOCK_50;
    wire              clk = CLOCK_50; // system clock
    output reg        done; // signals the end of a program
    output reg [31:0] clock_count; // total number of clock cycles to run a program
	output reg [31:0] instr_cnt;
	////////////////////////////////// END I/O ////////////////////////////////////////////////

    // The architecturally visible registers and scratch registers for implementation
	reg                        wr_en;
   reg        [31:0]          PC, ALUOut, MDR, rs1, rs2;
	reg        [REG_WIDTH-1:0] Regs [0:31];
	reg        [31:0]          IR;
   reg        [2:0]           state; // processor state
	reg signed [31:0]           D_entry;

	wire        [6:0]  opcode; // use to get opcode easily
   wire        [31:0] ImmGen; // used to generate immediate
	wire        [31:0] PC_addr = PC >> 2;
	wire        [31:0] I_Mem_Out;
	wire        [31:0] DMem_addr_w = ALUOut>>2;
	wire signed [31:0] D_out;
	wire signed [31:0] PCOffset = {{22{IR[31]}}, IR[7], IR[30:25], IR[11:8], 1'b0};


   assign             opcode   = IR[6:0]; // opcode is lower 7 bits
   assign             ImmGen   = (opcode == LW) ? IR[31:20] : {IR[31:25], IR[11:7]};
	
	wire [31:0] shit1, shit2, shit3;
	
	RAM #(32, 35, "IMemory.txt") I_Memory(.wr_en(1'b0),
									      .index(PC_addr),
										  .entry(32'b0),
										  .entry_out(I_Mem_Out)
										  );

	RAM #(32, M*N+N*N2+M*N2, "DMemory.txt") D_Memory(.wr_en(wr_en),
													 .index(DMem_addr_w),
													 .entry(D_entry),
													 .entry_out(D_out)
													 );

	// set the PC to 0 and start the control in state 1
    integer i;
    initial begin
        for (i = 0; i <= 31; i = i + 1) Regs[i] = 32'b0;
        PC = 0; 
        state = IF;
        clock_count = 0;
		instr_cnt = 0;
    end

    // The state machine--triggered on a rising clock
    always @(posedge clk) begin
        clock_count <= clock_count + 1;
		wr_en <= 1'b0;
        case (state) //action depends on the state
            IF: begin // first step: fetch the instruction, increment PC, go to next state
                IR <= I_Mem_Out;
                PC <= PC + 4;
                state <= ID; // next state
            end

            ID: begin // second step: Instruction decode, register fetch, also compute branch address
                if (IR != EOF) begin
                    rs1 <= Regs[IR[19:15]];
                    rs2 <= Regs[IR[24:20]];
                    ALUOut <= PC + PCOffset; // compute PC-relative branch target
					done <= 1'b0;
                    state <= EX;
                end else begin
                    done <= 1'b1;
                end
            end
			
			/////////////////////////////////////////////// EX Stage ////////////////////////////////////////////
            EX: begin // third step: Load-store execution, ALU execution, Branch completion
				instr_cnt <= instr_cnt + 1;
                case(opcode)
                    R_I: begin // R-type
                        case (IR[31:25]) // Check funct7
                            7'b0000000: begin
                                case (IR[14:12]) // Check funct3
                                    // ***add***
                                    3'b000: begin
                                        ALUOut <= rs1 + rs2;                 
                                        state <= MEM;
                                    end
                                endcase
                            end
                            7'b0100000: begin
                                //***sub***
                                case (IR[14:12]) // Check funct3
                                    3'b000: begin
										//***sub***
                                        ALUOut <= rs1 - rs2;    
                                        state <= MEM;
                                        // $display("ALUOut= %d\n",rs1 - rs2);
                                    end
                                endcase
                            end

                            7'b0000001: begin
                                //***mul***
                                case (IR[14:12]) // Check funct3
                                    3'b000: begin
                                        ALUOut <= rs1 * rs2;                 
                                        state <= MEM;
                                    end
                                    default: ;
                                endcase
                            end
                        endcase // case(funct7)
                    end

                    Imm_I: begin
                        case (IR[14:12])  // Check funct3
                            3'b000: ALUOut <= rs1 + IR[31:20]; 
                        endcase
						state <= MEM;
                    end

                    S_I: begin
                        case(IR[14:12])  // Check funct3
                            //***sw***
                            3'b010: ALUOut <= rs1 + ImmGen; // compute effective address
                        endcase
						state <= MEM;
						//wr_en <= 1'b1;
                    end

                    U_I: begin
                        //***lui***
                        //IR[31:12] == imm
                        ALUOut <= {IR[31:12], 12'b0};
                        state <= MEM;
                    end

                    I_I: begin
                        case(IR[14:12]) // check funct3
                            //***lw***
                            //LW rd，offset(rs1), x[rd] = sext ( M [x[rs1] + sext(offset) ] [31:0] )
                            3'b010: begin
                                ALUOut <= rs1 + ImmGen; // compute effective address
                                state <= MEM;
                            end
                        endcase
                    end

                    B_I: begin
                        case(IR[14:12])  // Check funct3
                            //***blt***
                            3'b100: begin
                                if (rs1 < rs2) PC <= ALUOut;
                            end
							//*****beq****
							3'b000: begin
								if (rs1 == rs2) PC <= ALUOut;
							end
                        endcase
						state <= IF;
                    end

					AUIPC: begin
						ALUOut <= PC + {IR[31:12], 12'b0};
					end
                endcase // endcase (opcode)
            end
			////////////////////////////////////////////// END EX ///////////////////////////////////////////////////////

			////////////////////////////////////////////// MEM Stage ///////////////////////////////////////////////////
            MEM: begin
                case(opcode)
                    R_I: begin // R-type
                        case (IR[31:25]) // Check funct7
                            7'b0000000: begin
                                case (IR[14:12]) // Check funct3
                                    //***add***
                                    3'b000: begin
                                        Regs[IR[11:7]] <= ALUOut;
                                        state <= IF;
                                    end

                                    default: ; 
                                endcase
                            end
                            
                            7'b0100000: begin
                                case (IR[14:12]) // Check funct3
                                    // sub
                                    3'b000: begin
                                        Regs[IR[11:7]] <= ALUOut;
                                        state <= IF;
                                    end
                                    default: ;
                                endcase
                            end

                            7'b0000001: begin
                                //***mul***
                                case (IR[14:12]) // Check funct3
                                    3'b000: begin
                                        Regs[IR[11:7]] <= ALUOut;              
                                        state <= IF;
                                    end
                                    default: ;
                                endcase
                            end
                            default: ;
                        endcase // endcase (IR[31:25])
                    end // R_i

                    Imm_I: begin // TO DO: learn how to check if the most significant 7 bits are part of imm or funct7
                        case (IR[14:12]) // Check funct3
                            // ***addi***
                            3'b000: begin
                                Regs[IR[11:7]] <= ALUOut;
                                state <= IF;
                            end
                        endcase
                    end // Imm_I

                    S_I: begin
                        case(IR[14:12])  // Check funct3
                            //***sw***
                            3'b010: begin
                                wr_en <= 1'b1;
							    D_entry <= rs2;
                                state <= IF; // return to state 1
                            end
                        endcase
                    end // S_I

                    U_I: begin
                        //***lui***
                        //IR[31:12] = imm
                        // MDR <= ALUOut;
                        // state <= WB;
                    end // U_I

					AUIPC: begin
						MDR <= ALUOut;
						state <= WB;
					end

                    I_I: begin
                        case(IR[14:12]) // check funct3
                            // ***lw***
                            3'b010: begin
								MDR <= D_out;
                                state <= WB; // next state
                            end
                        endcase
                    end // I_I
                endcase // MEM: case(opcode)
            end // MEM
			/////////////////////////////////////////////// END MEM //////////////////////////////////////////////////////////

            WB: begin // LW is the only instruction still in execution
                Regs[IR[11:7]] <= MDR; // write the MDR to the register
                state <= IF;
            end // complete an LW instruction
        endcase // case(state)
    end
endmodule
