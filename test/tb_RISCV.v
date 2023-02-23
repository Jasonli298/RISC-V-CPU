// testbench for the RISCV CPU
`timescale 1ns/10ps

module tb_RISCV;

localparam ROWS = 3;
localparam COLS = 4;

reg clk;
wire done;
wire [31:0] clock_count;

reg comparison;
integer i, j, k;
reg [31:0] regs [0:31];
reg signed [31:0] Matrix [0:ROWS * COLS]; // support maximum 1023 elements in the matrix
reg signed [31:0] Vector [0:COLS];
reg signed [31:0] result [0:ROWS];

/**********/ // rename to whichever version of Build
RISCVCPU #(ROWs, COLS) UUT(.clk(clk), .done(done), .clock_count(clock_count));

initial begin
	$readmemb("matrix_memory.txt", matrix);
	$readmemb("vector_memory.txt", vector);
	/*
	* The 1st and 2nd location of matrix_memory.txt is reserved for the number of ROWS and columns of the matrix
	* The 1st location represents the # of ROWS in the matrix
	* The 2nd location stores the # of columns in the matrix
	*/
	
	clk = 1'b0;

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

	// Print input matrix and vector
	$display("\nMatrix:");
	for (i = 0; i < ROWS; i=i+1) begin
		for (j = 0; j < COLS; j = j + 1) begin
			$write(matrix[i+j*ROWS]);
		end
		$write("\n");
	end

	$display("\nVector:");
	for (i = 0; i < COLS; i = i + 1) begin
		$display(vector[i]);
	end

	// generate correct answer
	for (i = 0; i < ROWS; i = i + 1) begin
		result[i] = 0;
		for (j = 0; j < COLS; j = j + 1) begin
			res[i] = matrix[i + j * ROWS] * vector[j];
	end

	$display("\n expected result");
	for (i = 0; i < ROWS; i = i + 1) begin
		$display(res[i]);
	end

//	$display("%d", UUT.DMemory[0]);
	$display("Generated Reseult");
	for (i = 0; i < ROWS; i = i + 1) begin
		$display(UUT.OUTRAM[i]);
	end
//	for (i = 0; i < 1024; i = i + 1) begin
//		$display(DMemory[i]);
//	end

	comparison = 1'b0;
	for (i = 0; i < ROWS; i = i + 1) begin
		if (res[i] != UUT.OUTRAM[i]) begin
			$display("Mismatch at indices [%1.1d]", i);
			comparison = 1'b1;
		end
	end

	if (comparison == 1'b0) begin
		$display("\nsuccess :)");
	end

	$display("Total clock cycles = %d", clock_count);

	$stop; // End simulation	
end
	

always begin
	clk = #10 ~clk;
end

end

endmodule