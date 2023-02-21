module RISCVCPU 
    #(parameter rows,
      parameter cols)
    (clk,
     done,
     clock_count);
    
    // Parameters for opcodes
    localparam R_I = 7'b011_0011,
               I_I = 7'b000_0011,
               Imm_I = 7'b001_0011,
               S_I = 7'b010_0011,
               B_I = 7'b110_0011,
               U_I = 7'b011_0111,
               J_I = 7'b110_1111,
               LW = 7'b000_0011; // also I type

    // Parameters for processor stages
    localparam IF = 1,
               ID = 2,
               EX = 3,
               MEM = 4,
               WB = 5;

    localparam EOF = 32'h1111_1111; // Defined EOF flag as all ones

    input clk; // system clock
    output reg done; // signals the end of a program
    output reg [15:0] clock_count; // total number of clock cycles to run a program
    // The architecturally visible registers and scratch registers for implementation
    reg [31:0] PC, Regs[0:31], ALUOut, MDR, rs1, rs2;
    reg [31:0] Memory [0:1023], IR;
    reg [7:0] D_Memory [0:4095];
    reg [2:0] state; // processor state
    wire [6:0] opcode; // use to get opcode easily
    wire [31:0] ImmGen; // used to generate immediate
    assign opcode = IR[6:0]; // opcode is lower 7 bits
    // assign ImmGen = (opcode == LW) ? {IR[31], IR[30:20]} : {IR[31], IR[30:25], IR[11:7]};
    assign ImmGen = (opcode == LW) ? IR[31:20] : {IR[31:25], IR[11:7]};
    assign PCOffset = {IR[31], IR[7], IR[30:25], IR[11:8], 1'b0};
    // set the PC to 0 and start the control in state 1
    integer i;
    initial begin
        for (i = 0; i <= 31; i = i + 1) Regs[i] = i;
        $readmemb("IMemory.txt", Memory);
        $readmemb("DMemory.txt", D_Memory);
        // $readmemb("Matrix.txt", Matrix);
        // $readmemb("Vector.txt", Vector);
        PC = 0; 
        state = 1;
        clock_count = 0;
    end

    // The state machine--triggered on a rising clock
    always @(posedge clk) begin
        clock_count <= clock_count + 1;
        case (state) //action depends on the state
            IF: begin // first step: fetch the instruction, increment PC, go to next state
                IR <= Memory[PC >> 2];
                PC <= PC + 4;
                state <= ID; // next state
            end

            ID: begin // second step: Instruction decode, register fetch, also compute branch address
                if (IR != 32'h1111_1111) begin
                    rs1 <= Regs[IR[19:15]];
                    rs2 <= Regs[IR[24:20]];
                    ALUOut <= PC + PCOffset; // compute PC-relative branch target
                    state <= EX;
                end else begin
                    done <= 1'b1;
                end
            end
			
			/////////////////////////////////////////////// EX Stage ////////////////////////////////////////////
            EX: begin // third step: Load-store execution, ALU execution, Branch completion
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
                                        $display("ALUOut= %d\n",rs1 - rs2);
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
                            /*
                            3'b000: begin // add
                                ALUOut <= rs1 + rs2;                 
                                state <= 4;
                            end
                            3'b001: begin // sll
                                ALUOut <= rs1 << rs2;
                                state <= 4;
                            end
                            3'b010: begin // slt (Set Less Than)
                                ALUOut <= (rs1 < rs2) ? 1'b1 : 1'b0;
                                state <= 4;
                            end
                            3'b100: begin // xor
                                ALUOut <= rs1 ^ rs2;
                                state <= 4;
                            end
                            3'b101: begin // srl
                                ALUOut <= rs1 >> rs2;
                                state <= 4;
                            end
                            3'b110: begin // or
                                ALUOut <= rs1 || rs2;
                                state <= 4;
                            end
                            3'b111: begin // and
                                ALUOut <= rs1 && rs2;
                                state <= 4;
                            end*/
                        endcase // case(funct7)
                    end

                    Imm_I: begin
                        case (IR[14:12])  // Check funct3
                            3'b000: ALUOut <= rs1 + IR[31:20]; 
                            3'b001: ALUOut <= rs1 << IR[24:20]; // The leftmost 7 bits are funct7. Imm is only 5 bits.
                        endcase
						state <= MEM;
                    end


                    S_I: begin
                        case(IR[14:12])  // Check funct3
                            //***sw***
                            3'b010: ALUOut <= rs1 + ImmGen; // compute effective address
                        endcase
						state <= MEM;
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
                                if(rs1 < rs2) begin
                                    PC <= PC + PCOffset;
                                end
                                state <= IF;
                            end
                        endcase
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
								{D_Memory[ALUOut>>2], D_Memory[(ALUOut>>2)+1], D_Memory[(ALUOut>>2)+2], D_Memory[(ALUOut>>2)+3]} <= rs2;

                                state <= IF; // return to state 1
                            end
                        endcase
                    end // S_I

                    U_I: begin
                        //***lui***
                        //IR[31:12] = imm
                        MDR <= ALUOut;
                        state <= WB;
                    end // U_I

                    I_I: begin
                        case(IR[14:12]) // check func3
                            // ***lw***
                            3'b010: begin
                                // $display("ALUOut= %d\n", ALUOut >> 2);
                                MDR <= {D_Memory[ALUOut>>2], D_Memory[(ALUOut>>2)+1], D_Memory[(ALUOut>>2)+2], D_Memory[ALUOut>>2+3]}; // read the memory
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
        endcase
    end
endmodule
