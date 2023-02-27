// testbench for the RISCV CPU
`timescale 1ns/10ps

module tb_RISCV;

// The following localparams should be changed in sync with the parameters passed to the CPU
// Change to relfect the sizes of the input matrices
localparam  M=2;  // number of rows in matrix1
localparam  N=4;  // number of columns in maatrix1 and rows in matrix2
localparam  N2=2; // number of columns in matrix2

reg         clk;
integer     i,j,k;
real        ClockCount; // used to convert wire to floating number for division to get CPI
real        InstrCount; // used to convert wire to floating number for division to get CPI

wire        done;        // signals the end of a program
wire [15:0] clock_count; // total number of clock cycles to run a program
wire [15:0] instr_cnt;   // total number of instructions executed
reg         comparison;  // flag to indicate whether the result from CPU is correct

reg signed [31:0] word; // temporary placeholder to store the assembled word from data memory

reg signed [7:0]  data    [0:M*N*4+N*N2*4-1]; // array to store the content from the initialization file of data memory
reg signed [31:0] matrix1 [0:M*N-1];
reg signed [31:0] matrix2 [0:N*N2-1];
reg signed [31:0] res     [0:M*N2-1]; // array to store the result matrix calulated in TB for comparison

/*******/ // Rename to whichever version of build
RISCVCPU #(2, 4, 2, 32) UUT(.CLOCK_50(clk),             // 1st parameter is number of rows in matrix1
							.done(done),                // 2nd parameter is number of columns in matrix1 and rows in matrix2
							.clock_count(clock_count),  // 3rd parameter is number of columns in matrix2
							.instr_cnt(instr_cnt));     // 4th parameter is size of the registers in register file of CPU

initial begin
	clk = 1'b0;
  
	$readmemb("DMemory.txt", data);
	for (i = 0; i < M*N; i = i + 1) begin
		matrix1[i] = {data[4*i], data[4*i+1], data[4*i+2], data[4*i+3]};
	end
	for (i = 0; i < N*N2; i = i + 1) begin
		matrix2[i] = {data[4*i+M*N*4], data[4*i+M*N*4+1], data[4*i+M*N*4+2], data[4*i+M*N*4+3]};
	end

	fork : wait_or_timeout
	begin
		repeat (5000) @(posedge clk);
		disable wait_or_timeout;
	end
	begin
		@(posedge done);
		disable wait_or_timeout;
	end
	join	
	
	// Uncomment the following 3 lines to display the contents in the register file in the CPU
	// for (i = 0; i < 32; i = i + 1) begin
	// 	$display("Reg%d: D:%d H:%h B:%b", i, UUT.Regs[i], UUT.Regs[i], UUT.Regs[i]);
	// end

	$display("Matrix1:");
	for (i = 0; i < M; i = i + 1) begin
		for (j = 0; j < N; j = j + 1) begin
			$write("%d ", matrix1[i*N+j]);
		end
		$display();
	end

	$display("Matrix2:");
	for (i = 0; i < N; i = i + 1) begin
		for (j = 0; j < N2; j = j + 1) begin
			$write("%d ", matrix2[i*N2+j]);
		end
		$display();
	end

	$display("Expected Result:");
	for (i = 0; i < M; i = i + 1) begin
		for (j = 0; j < N2; j = j + 1) begin
			res[i*N2+j] = 0;
			for (k = 0; k < N; k = k + 1) begin
				res[i*N2+j] = res[i*N2+j] + matrix1[i*N+k] * matrix2[k*N2+j];
			end
			$write("%d ", res[i*N2+j]);
		end
		$display();
	end

	$display("Generated Reseult");
	for (i = M*N*4+N*N2*4; i <= M*N*4+N*N2*4+(M*N2-1)*4; i = i + 4*N2) begin
		for (j = 0; j < N2; j = j + 1) begin
			word = {UUT.D_Memory[i*N2+j], UUT.D_Memory[i*N2+j+1], UUT.D_Memory[i*N2+j+2], UUT.D_Memory[i*N2+j+3]};
			$write("%d ", word);
		end
		$display();
	end

	comparison = 1'b0;
	for (i = 0; i < M; i = i + 1) begin
		for (j = 0; j < N2; j = j + 1) begin
			word = {UUT.D_Memory[i*4+M*N*4+N*N2*4+j], UUT.D_Memory[i*4+M*N*4+N*N2*4+j+1], UUT.D_Memory[i*4+M*N*4+N2*N*4+j+2], UUT.D_Memory[4*i+M*N*4+N*N2*4+j+3]};
			if (res[N2*i+j] != word) begin
				$display("Mismatch at indices [%1.1d,%1.1d]", i, j);
				comparison = 1'b1;
			end
		end
	end
	
	if (comparison == 1'b0) begin
		$display("\nSuccess AYYYYYYYY\n");
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
