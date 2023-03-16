module ALUControl (ALUOp, FuncCode, ALUCtl);
    
    input [1:0] ALUOp;
    input [3:0] FuncCode; // FuncCode = {IR[30], IR[14:12]} or {IR[30], funct3}
    output reg [3:0] ALUCtl;

    always @( ALUOp or FuncCode ) begin
        case (ALUOp)
            2'b00: ALUCtl = 4'b0010;
            2'b01: ALUCtl = 4'b0110;
            2'b1x: begin
                case (FuncCode)
                    4'b0000: ALUCtl = 4'b0010; // add
                    4'b1000: ALUCtl = 4'b0110; // subtract
                    4'b0111: ALUCtl = 4'b0000; // and
                    4'b0110: ALUCtl = 4'b0001; // or
                    4'b1100: ALUCtl = 4'b0111; // blt
                    default: ALUCtl = 4'bZZZZ;
                endcase
            end
            default: ALUCtl = 4'bZZZZ;
        endcase 
    end

endmodule
