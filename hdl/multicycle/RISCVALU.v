module RISCVALU(ALUctl, A, B, ALUOut, Zero);

    input [3:0] ALUctl;
    input [31:0] A, B;
    output reg [31:0] ALUOut;
    output Zero;

    assign Zero = (ALUOut == 0); // Zero is 1 if ALUOut is 0; goes everywhere

    always @(ALUctl, A, B) begin
        case (ALUctl)
            4'b0000 : ALUOut <= A & B;
            4'b0001 : ALUOut <= A | B;
            4'b0010 : ALUOut <= A + B;
            4'b0110 : ALUOut <= A - B;
            4'b0111 : ALUOut <= A < B ? 1 : 0;
            4'b1100 : ALUOut <= ~(A | B); //  NOR
            default : ALUOut <= 0; // should not happen
        endcase
    end

endmodule
