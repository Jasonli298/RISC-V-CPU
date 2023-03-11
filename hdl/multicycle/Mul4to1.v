module Mul4to1 (In1, In2, In3, In4, Sel, Out);

    input [31:0] In1, In2, In3, In4;
    input [1:0] Sel;
    output reg [31:0] Out;

    always @(In1, In2, In3, In4, Sel) begin
        case (Sel)
            0: Out <= In1;
            1: Out <= In2;
            2: Out <= In3;
            default: Out <= In4;
        endcase
    end

endmodule
