// testbench for the RISCV CPU
`timescale 1ns/10ps

module tb_RISCV;

reg clk;
wire done;
wire [31:0] clock_count;
reg signed [31:0] rows, cols;
integer i, j, k;
reg [31:0] regs [0:31];
reg signed [31:0] Matrix [0:1023]; // support maximum 1023 elements in the matrix
reg signed [31:0] Vector [0:1023];
reg signed [31:0] result [0:1023];

/**********/ // rename to whichever version of Build
RISCVCPU UUT(.clk(clk), .done(done), .clock_count(clock_count));

initial begin
	$readmemb("matrix_memory.txt", matrix);
	$readmemb("vector_memory.txt", vector);
	/*
	* The 1st and 2nd location of matrix_memory.txt is reserved for the number of rows and columns of the matrix
	* The 1st location represents the # of rows in the matrix
	* The 2nd location stores the # of columns in the matrix
	*/
	rows = matrix[0];
	cols = matrix[1];
	
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
	for (i = 0; i < rows; i=i+1) begin
		for (j = 0; j < cols; j = j + 1) begin
			$write(matrix[i+j*rows]);
		end
		$write("\n");
	end

	$display("\nVector:");
	for (i = 0; i < cols; i = i + 1) begin
		$display(vector[i]);
	end

	// generate correct answer
	for (i = 0; i < rows; i = i + 1) begin
		result[i] = 0;
		for (j = 0; j < cols; j = j + 1) begin
			res[i] = matrix[i + j * rows] * vector[j];
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

end

endmodule