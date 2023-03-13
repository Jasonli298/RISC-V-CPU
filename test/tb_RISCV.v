// testbench for the RISCV CPU
`timescale 1ns/10ps

module tb_RISCV;

// The following localparams should be changed in sync with the parameters passed to the CPU
// Change to relfect the sizes of the input matrices
localparam  M  = 2; // number of rows in matrix1
localparam  N  = 2; // number of columns in matrix1 and rows in matrix2
localparam  N2 = 2; // number of columns in matrix2

reg     clk;
reg     rstn;
integer i,j,k;
real    ClockCount; // used to convert wire to floating number for division to get CPI
real    InstrCount; // used to convert wire to floating number for division to get CPI

wire        done;        // signals the end of a program
wire [31:0] clock_count; // total number of clock cycles to run a program
wire [31:0] instr_cnt;   // total number of instructions executed
wire [31:0] ID_count;
reg         comparison;  // flag to indicate whether the result from CPU is correct
wire [9:0]  LEDR;

reg signed [31:0] word; // temporary placeholder to store the word from data memory to display as signed number

reg signed [31:0] data    [0:M*N+N*N2-1]; // array to store the content from the initialization file of data memory
reg signed [31:0] matrix1 [0:M*N-1];
reg signed [31:0] matrix2 [0:N*N2-1];
reg signed [31:0] res     [0:M*N2-1]; // array to store the result matrix calulated in TB for comparison

/*******/ // Rename to whichever version of build
RISCV #(M, N, N2, 32) UUT(.CLOCK_50(clk),             // 1st parameter is number of rows in matrix1
							 .rstn(rstn),
							 .done(done),                // 2nd parameter is number of columns in matrix1 and rows in matrix2
							 .clock_count(clock_count),  // 3rd parameter is number of columns in matrix2
							 .instr_cnt(instr_cnt)
							//  .ID_count(ID_count),
							);    // 4th parameter is size of the registers in register file of CPU

initial begin
	clk = 1'b0;
	rstn = 1'b0;
	#20 
	rstn = 1'b1;

	$readmemb("DMemory.txt", data);
	for (i = 0; i < M*N; i = i + 1) begin
		matrix1[i] = data[i];
	end
	for (i = 0; i < N*N2; i = i + 1) begin
		matrix2[i] = data[i+M*N];
	end

	fork : wait_or_timeout
	begin
		repeat (500) @(posedge clk);
		disable wait_or_timeout;
	end
	begin
		@(posedge done);
		disable wait_or_timeout;
	end
	join	
	
	// Uncomment the following 3 lines to display the contents in the register file in the CPU
	for (i = 0; i < 32; i = i + 1) begin
		$display("Reg%d: D:%d H:%h B:%b", i, UUT.Regs[i], UUT.Regs[i], UUT.Regs[i]);
	end

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

	$display("Generated Reseult:");
	for (i = M*N+N*N2; i < M*N+N*N2+M*N2; i = i + N2) begin
		for (j = 0; j < N2; j = j + 1) begin
			word = UUT.D_Memory.mem[i + j];
			$write("%d ", word);
		end
		$display();
	end

	comparison = 1'b0;
	for (i = 0; i < M; i = i + 1) begin
		if (res[N2*i+j] != UUT.D_Memory.mem[i*N2+M*N+N*N2+j]) begin
			$display("Mismatch at indices [%1.1d,%1.1d]", i, j);
			comparison = 1'b1;
		end
	end
	
	if (comparison == 1'b0) begin
		$display("\nSuccess AYYYYYYYY\n");
	end

	// $display("enter IF %d times", UUT.IF_count);
	// $display("enter ID %d times", ID_count);
	// $display("enter MEM %d times", UUT.MEM_count);
	// $display("enter WB %d times", UUT.WB_count);
	$display("done:%b", done);

	ClockCount = clock_count;
	InstrCount = instr_cnt;
	if (InstrCount == 0) begin
		$display("Error, No instructions executed.");
		$display("total clock cycles:%d", clock_count);
	end else begin
		$display("total clock cycles: %d", clock_count);
		$display("total # of instructions executed: %d", instr_cnt);
		$display("CPI=%f", ClockCount/InstrCount);
	end

	$stop; // End simulation	
end
	

always begin
	clk = #10 ~clk;
end

endmodule
