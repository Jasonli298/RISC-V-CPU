module 41Mux #(parameter REG_WIDTH=32)
(
input [REG_WIDTH-1:0] in0,
input [REG_WIDTH-1:0] in1,
input [REG_WIDTH-1:0] in2,
input [REG_WIDTH-1:0] in3,
input [1:0] sel,
output reg [REG_WIDTH-1:0] out);

always @(in0, in1, in2, in3, sel) begin
	case (sel)
		2'b00: out = in0;
		2'b01: out = in1;
		2'b10: out = in2;
		2'b11: out = in3;
	endcase
end

endmodule
