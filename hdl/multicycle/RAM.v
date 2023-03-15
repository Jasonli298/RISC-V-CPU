module RAM 
#(parameter DATA_WIDTH=32, parameter SIZE = 256, FILE_NAME="")
(
	input [(DATA_WIDTH-1):0] entry,
	input [31:0] index_r, index_w,
	input wr_en,
	input clk,
	output reg [(DATA_WIDTH-1):0] entry_out
);

	// Declare the RAM variable
	reg [DATA_WIDTH-1:0] mem[SIZE-1:0];

	// Variable to hold the registered read address
	reg [31:0] addr_reg;

	always @ (posedge clk)
	begin
		// Write
		if (wr_en) begin
			mem[index_w] <= entry;
		end

		entry_out <= mem[index_r];
	end

	// Continuous assignment implies read returns NEW data.
	// This is the natural behavior of the TriMatrix memory
	// blocks in Single Port mode.  
	initial begin
		if (FILE_NAME != "") $readmemb(FILE_NAME, mem);
	end

endmodule

