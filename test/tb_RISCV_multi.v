// testbench for the RISCV CPU
`timescale 1ns/10ps

module tb_RISCV;

reg clk;
integer i,j;
reg [31:0] regs [0:31];

/**********/ // rename to whichever version of Build
RISCVCPU UUT #(3, 4)(.clock(clk), .done(done), .clock_count(clock_count));

initial begin
	clk = 1'b0;

//	fork : wait_or_timeout
//	begin
//		repeat (1000) @(posedge clk);
//		disable wait_or_timeout;
//	end
//	join
	repeat (100) begin
		@(posedge clk);
	end

//	$display("%d", UUT.DMemory[0]);
	$display("Generated Reseult");
	for (j = 0; j < 32; j = j + 1) begin
		$display("Reg%d %d", j, UUT.Regs[j]);
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