// testbench for the RISCV CPU
`timescale 1ns/10ps

module tb_RISCV;

localparam M=3;
localparam N=4;

reg clk;
integer i,j;
real ClockCount, InstrCount;
reg [31:0] regs [0:31];
wire done; // signals the end of a program
wire [15:0] clock_count; // total number of clock cycles to run a program
wire [15:0] instr_cnt;
reg comparison;
reg signed [31:0] word;
reg signed [7:0] data[0:M*N*4+N*4-1];
reg signed [31:0] matrix [0:M*N-1];
reg signed [31:0] vector [0:N-1];
reg signed [31:0] res [0:M*4-1];

/**********/ // rename to whichever version of Build
RISCVCPU #(3, 4)UUT(.CLOCK_50(clk), .done(done), .clock_count(clock_count), .instr_cnt(instr_cnt));

initial begin
	clk = 1'b0;

	$readmemb("DMemory.txt", data);
	for (i = 0; i < M*N; i = i + 1) begin
		matrix[i] = {data[4*i], data[4*i+1], data[4*1+2], data[4*i+3]};
	end
	for (i = 0; i < N; i = i + 1) begin
		vector[i] = {data[4*i+M*N*4], data[4*i+M*N*4+1], data[4*i+M*N*4+2], data[4*i+M*N*4+3]};
	end

	fork : wait_or_timeout
	begin
		repeat (1000) @(posedge clk);
		disable wait_or_timeout;
	end
	begin
		@(posedge done);
		disable wait_or_timeout;
	end
	join	

	$display("Matrix:");
	for (i = 0; i < M; i = i + 1) begin
		for (j = 0; j < N; j = j + 1) begin
			$write("%d ", matrix[i*N+j]);
		end
		$write("\n");
	end

	$display("Vector:");
	for(i = 0; i < N; i = i + 1) begin
		$display("%d", vector[i]);
	end

	$display("Expected Result:");
	for (i = 0; i < M; i = i + 1) begin
		res[i] = 0;
		for (j = 0; j < N; j = j + 1) begin
			res[i] = res[i] + matrix[i*N+j] * vector[j];
		end
		$display("%d", res[i]);
	end

	$display("Generated Reseult");
	for (i = M*N*4+N*4; i <= (M*N*4+N*4+(M-1)*4); i = i + 4) begin
		word = {UUT.D_Memory[i],UUT.D_Memory[i+1],UUT.D_Memory[i+2],UUT.D_Memory[i+3]};
		$display("D_Memory[0x%h]= %d", i, word);
	end

	comparison = 1'b0;
	for (i = 0; i < M; i = i + 1) begin
		word = {UUT.D_Memory[i*4+M*N*4+N*4], UUT.D_Memory[i*4+M*N*4+N*4+1], UUT.D_Memory[i*4+M*N*4+N*4+2], UUT.D_Memory[4*i+M*N*4+N*4+3]};
		if (res[i] != word) begin
			$display("Mismatch at indices [%1.1d]", i);
			comparison = 1'b1;
		end
	end
	if (comparison == 1'b0) begin
		$display("\nsuccess :)");
	end

	ClockCount = clock_count;
	InstrCount = instr_cnt;
	$display("total clock cycles: %d", clock_count);
	$display("total # of instructions executed: %d", instr_cnt);
	$display("CPI=%f", ClockCount/InstrCount);

	$stop; // End simulation	
end
	

always begin
	clk = #10 ~clk;
end


endmodule