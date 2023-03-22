// Quartus Prime Verilog Template
// Single port RAM with single read/write address 

module RAM 
#(parameter DATA_WIDTH=32, parameter SIZE = 6, parameter FILE_NAME="")
(
//	input [(DATA_WIDTH-1):0] data,
//	input [31:0] addr,
//	input we, clk,
//	output [(DATA_WIDTH-1):0] q
	
	input             clk,
	input             wr_en,
	input      [31:0] data_in,
	output reg [31:0] data_out,
	input      [31:0] addr_wr,
	input      [31:0] addr_rd
);
	
	// Declare the RAM variable
	reg [DATA_WIDTH-1:0] mem [SIZE-1:0] /* synthesis ramstyle = M10K */;
	
	localparam M = 9, N = 9, N2 = 9;
	integer i;
	
	initial begin
		if (FILE_NAME != "") begin
			$readmemb(FILE_NAME, mem);
//			if (FILE_NAME == "DMemory.txt") begin
//				for (i = M*N+N*N2; i < SIZE; i = i + 1) mem[i] = 32'b0;
//			end
		end
	end

	// Variable to hold the registered read address
//	reg [31:0] addr_reg;

	always @ (posedge clk) begin
		if (wr_en == 1'b1) begin
			mem[addr_wr] <= data_in;
		end
		//if (read_en) addr_reg <= index;
        data_out <= mem[addr_rd];
	end

	// Continuous assignment implies read returns NEW data.
	// This is the natural behavior of the TriMatrix memory
	// blocks in Single Port mode.  
//	assign q = ram[addr_reg];
	
endmodule
