// testbench for the RISCV CPU
`timescale 1ns/1ps

module tb_RISCV;

reg clk;
integer i;

// Input Memory
reg signed [31:0] IMemory [0:1023];
reg signed [31:0] DMemory [0:1023];

/**********/ // rename to whichever version of Build
RISCV_multi UUT(.clk(clk));

initial begin
	$readmemb("IMemory.txt", IMemory);
	$readmemb("DMemory.txt", DMemory);
	clk <= 0;

	fork : wait_or_timeout
	begin
		repeat (1000) @(posedge clk);
		disable wait_or_timeout;
	end
	join

	$display("Generated Reseult")
	for (i = 0; i < 1024; i = i + 1) begin
		$display(DMemory[i]);
	end

	$stop; // End simulation	
end
	

always begin
	clk = #10 ~clk;
end

endmodule
