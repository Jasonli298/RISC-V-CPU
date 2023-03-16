module RISCVALU#(parameter REG_WIDTH = 32) (ALUCtl, A, B, ALUOut, IsLessThan);

    input [3:0] ALUCtl;
    input [31:0] A, B;
    output reg [REG_WIDTH-1:0] ALUOut;
    output IsLessThan;

    assign IsLessThan = (ALUOut == 1); // Zero is 1 if ALUOut is 0; goes everywhere
    // assign Zero = (ALUut == 0);

    always @(ALUCtl, A, B) begin
        case (ALUCtl)
            4'b0000 : ALUOut <= A & B;
            4'b0001 : ALUOut <= A | B;
            4'b0010 : ALUOut <= A + B;
            4'b0110 : ALUOut <= A - B;
            4'b0111 : ALUOut <= A < B ? 1 : 0; // blt
            4'b1100 : ALUOut <= ~(A | B); //  NOR
            default : ALUOut <= 0; // should not happen
        endcase
    end

endmodule