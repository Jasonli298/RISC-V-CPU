// testbench for the RISCV CPU
`timescale 1ns/1ps

module tb_RISCV;

wire clk;
integer i;

/*****/ // rename to whichever version of Build
RISCV_multi UUT(.clk(clk));

initial begin
	clk = 0;
	

always begin
	clk = #10 ~clk;
end