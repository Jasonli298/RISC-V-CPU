module ALUControl (ALUOp, funct7, funct3, ALUCtl);
    
    input [1:0] ALUOp;
    input [6:0] funct7;
    input [2:0] funct3;
    output reg [3:0] ALUCtl;

    always @( ALUOp or funct7 or funct3 ) begin
        case (ALUOp)
            2'b00: ALUCtl = 4'b0010;
            2'b1x: ALUCtl = 4'b0110;
            2'b1x: begin
                case ({funct7, funct3})
                    10'b0: ALUCtl = 4'b0010;
                    10'b01_0000_0000: ALUCtl = 4'b0110;
                    10'b00_0000_0111: ALUCtl = 4'b0000;
                    10'b00_0000_0110: ALUCtl = 4'b0001;
                    default: ALUCtl = 4'bZZZZ;
                endcase
            end
            default: ALUCtl = 4'bZZZZ;
        endcase 
    end

endmodule
