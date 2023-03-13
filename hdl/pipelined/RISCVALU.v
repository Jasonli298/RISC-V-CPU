module RISCVALU(
ALUctl,
A,
B,
ALUOut,
Zero);

input [3:0] ALUctl;
input [REG_WIDTH-1:0] A, B;
