module Control (
    opcode,
    ALUSrc,
    MemtoReg,
    MemRead,
    MemWrite,
    Branch,
    ALUOp
);

    parameter RI   = 7'b011_0011,
              LW   = 7'b000_0011,
              SW   = 7'b010_0011,
              BEQ  = 7'b110_0011,
              ADDI = 7'b001_0011,
              NOP  = 7'b0;

    input [6:0] opcode;
    output reg ALUSrc, Branch, MemRead, MemWrite, MemtoReg;
    output reg [1:0] ALUOp;

    always @(opcode) begin
        case (opcode)
            RI: begin
                ALUSrc   = 0;
                MemtoReg = 0;
                MemRead  = 0;
                MemWrite = 0;
                Branch   = 0;
                ALUOp    = 2'b10;
            end
            LW: begin
                ALUSrc   = 1;
                MemtoReg = 1;
                MemRead  = 1;
                MemWrite = 0;
                Branch   = 0;
                ALUOp    = 2'b00;
            end 
            SW: begin
                ALUSrc   = 1;
                MemtoReg = 0;
                MemRead  = 0;
                MemWrite = 1;
                Branch   = 0;
                ALUOp    = 2'b00;
            end 
            BEQ: begin
                ALUSrc   = 0;
                MemtoReg = 0;
                MemRead  = 0;
                MemWrite = 0;
                Branch   = 1;
                ALUOp    = 2'b01;
            end
            ADDI: begin
                ALUSrc   = 1;
                MemtoReg = 0;
                MemRead  = 0;
                MemWrite = 0;
                Branch   = 0;
                ALUOp    = 2'b00;
            end
            NOP: begin
                ALUSrc   = 0;
                MemtoReg = 0;
                MemRead  = 0;
                MemWrite = 0;
                Branch   = 0;
                ALUOp    = 2'b00;
            end
        endcase
    end
    
endmodule