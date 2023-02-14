module RISCVCPU (clock);
    // parameter  LW = 7'b000_0011, 
    //         SW = 7'b010_0011, 
    //         BEQ = 7'b110_0011, 
    //         ALUop = 7'b011_0011,
    //         ADDI = 7'b001_0011,
    //         JAL = 7'b110_1111,
    //         SUB = 7'b011_0011,

    //         ra = 1;

    parameter R_I = 7'b0110011;
                I_I = 7'b0010011;
                S_I = 7'b0100011;
                B_I = 7'b1100011;
                U_I = 7'b0110111;
                J_I = 7'b1101111;






            
    input clock; //the clock is an external input
    // The architecturally visible registers and scratch registers for implementation
    reg [31:0] PC, Regs[0:31], ALUOut, MDR, rs1, rs2, imm;
    reg [31:0] Memory [0:1023], IR;
    reg [2:0] state; // processor state
    wire [6:0] opcode; // use to get opcode easily
    wire [31:0] ImmGen; // used to generate immediate
    assign opcode = IR[6:0]; // opcode is lower 7 bits
    assign ImmGen = (opcode == LW) ? {{53{IR[31]}}, IR[30:20]} :
    /* (opcode == SW) */{{53{IR[31]}}, IR[30:25], IR[11:7]};
    assign PCOffset = {{52{IR[31]}}, IR[7], IR[30:25], IR[11:8], 1'b0};
    // set the PC to 0 and start the control in state 1
    integer i;
    initial begin
        for (i = 0; i <= 31; i = i + 1) Regs[i] = i;
        $readmemb("IMemory.txt", Memory);
        PC = 0; state = 1;
    end
    // The state machine--triggered on a rising clock
    always @(posedge clock) begin
        Regs[0] <= 0; // shortcut way to make sure R0 is always 0
        case (state) //action depends on the state
            1: begin // first step: fetch the instruction, increment PC, go to next state
                IR <= Memory[PC >> 2];
                PC <= PC + 4;
                state <= 2; // next state
            end

            2: begin // second step: Instruction decode, register fetch, also compute branch address
                rs1 <= Regs[IR[19:15]];
                rs2 <= Regs[IR[24:20]];
                ALUOut <= PC + PCOffset; // compute PC-relative branch target
                state <= 3;
            end

            3: begin // third step: Load-store execution, ALU execution, Branch completion
                case(opcode)

                    R_I:begin
                    end




                endcase

                // if ((opcode == LW) || (opcode == SW)) begin
                //     ALUOut <= rs1 + ImmGen; // compute effective address
                //     state <= 4;
                // end
                // else if (opcode == ALUop) begin
                //     // $display("testing: A= %b   B= %b",A , B );
                //     case (IR[31:25]) // case for the various R-type instructions
                //         0: ALUOut <= rs1 + rs2; // add operation
                //         default: ; // other R-type operations: subtract, SLT, etc.
                //     endcase
                //     state <= 4;
                // end
                // else if (opcode == BEQ) begin
                //     if (rs1 == rs2) begin
                //         PC <= ALUOut; // branch taken--update PC
                //     end
                //     state <= 1;
                // end
                // else if(opcode == ADDI) begin
                //     //addi rd，rs1，imm(IR[31:20])   rd = (rs1 + imm)
                //     ALUOut <= rs1 + IR[31:20];
                //     state <= 4;
                //     // $display("testing: rs1= %d, imm= %d,   ALUOut= %d",rs1 , IR[31:20],  ALUOut );
                // end
                // else if(opcode == SUB) begin
                //     ALUOut <= rs1 - rs2;
                //     state <= 4;
                //     $display("rs1= %d   rs2= %d   AlUOUT= %d \n", rs1, rs2, ALUOut);
                // end

                else if(opcode == JAL) begin
                    Regs[ra] <= PC + 4;
                    // PC = PC + {imm, 1b'0}
                    PC <= PC + {IR[31:12], 1'b0};
                end
            end

            4: begin
                if (opcode == R) begin // ALU Operation
                    Regs[IR[11:7]] <= ALUOut; // write the result
                    state <= 1;
                end // R-type finishes
                else if(opcode == ADDI) begin
                    Regs[IR[11:7]] <= ALUOut;
                    state <= 1;
                    // $display("testing: Regs[IR[11:7]]= %d\n",Regs[IR[11:7]] );
                end
                else if (opcode == LW) begin // load instruction
                    MDR <= Memory[ALUOut >> 2]; // read the memory
                    state <= 5; // next state
                end
                else if (opcode == SW) begin // store instruction
                    Memory[ALUOut >> 2] <= rs2; // write the memory
                    state <= 1; // return to state 1
                end
                else if(opcode == SUB) begin
                    Regs[IR[11:7]] <= ALUOut;
                    state <= 1;
                end
                // else if(opcode == JAL) begin
                //     state <= 1;
                // end
            end
            5: begin // LW is the only instruction still in execution
                Regs[IR[11:7]] <= MDR; // write the MDR to the register
                state <= 1;
            end // complete an LW instruction
        endcase
    end
endmodule