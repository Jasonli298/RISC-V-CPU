// multicycle version of the RISCV CPU
module RISCV_multi(clk);

localparam LW = 7'b000_0011;
localparam SW = 7'b010_0011;
localparam BEQ = 7'b110_0011;
localparam NOP = 32'h0000_0013;
localparam ALUop = 7'b001_0011;

input clk;

reg [31:0] PC;
reg [0:31] regs;
reg IDEXA, IDEXB;
reg EXMEMB, EXMEMALUout;
reg MEMWBValue;

endmodule
