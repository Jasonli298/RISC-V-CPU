// testbench for the RISCV CPU
`timescale 1ns/10ps

module tb_RISCV;

reg clk;
integer i,j;
reg [31:0] regs [0:31];
wire done; // signals the end of a program
wire [15:0] clock_count; // total number of clock cycles to run a program

/**********/ // rename to whichever version of Build
RISCVCPU #(3, 4)UUT(.clk(clk), .done(done), .clock_count(clock_count));

initial begin
	clk = 1'b0;

//	fork : wait_or_timeout
//	begin
//		repeat (1000) @(posedge clk);
//		disable wait_or_timeout;
//	end
//	join
	repeat (700) begin
		@(posedge clk);
		// $display("Reg 11= %d    Reg 4= %d   Reg 3= %d", UUT.Regs[11],  UUT.Regs[4],  UUT.Regs[3] - 48);
	end

	
	$display("Generated Reseult");
	for (j = 0; j < 32; j = j + 1) begin
		$display("Reg%d %d %h %b", j, UUT.Regs[j], UUT.Regs[j], UUT.Regs[j]);
	end

	for (i = 64; i <= 72; i = i + 4) begin
		$display("Result%d = %d", i, {UUT.D_Memory[i],UUT.D_Memory[i+1],UUT.D_Memory[i+2],UUT.D_Memory[i+3]});
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
