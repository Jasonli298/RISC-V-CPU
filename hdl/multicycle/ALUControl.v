module ALUControl (ALUOp, FuncCode, ALUCtl);
    
    input [1:0] ALUOp;
    input [6:0] FuncCode;
    output reg [3:0] ALUCtl;

    always case (FuncCode)
        32: ALUOp <= 2;
        34: ALUOp <= 6;
        36: ALUOp <= 0;
        37: ALUOp <= 1;
        default: ALUOp <= 15;
    endcase

endmodule
