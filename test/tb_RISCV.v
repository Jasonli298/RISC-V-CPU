// testbench for the RISCV CPU
`timescale 1ns/1ps

module tb_RISCV;

reg clk;
integer i,j;

/**********/ // rename to whichever version of Build
RISCV_multi UUT(.clk(clk));

initial begin
	clk <= 1'b0;

	fork : wait_or_timeout
	begin
		repeat (1000) @(posedge clk);
		disable wait_or_timeout;
	end
	join

	$display("Generated Reseult");
	for (j = 0; j < 32; j = j + 1) begin
		$display(UUT.Regs[j]);
	end
//	for (i = 0; i < 1024; i = i + 1) begin
//		$display(DMemory[i]);
//	end

	$stop; // End simulation	
end
	

always begin
	clk = #10 ~clk;
end

endmodule