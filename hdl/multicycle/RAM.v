// Quartus Prime Verilog Template
// Single port RAM with single read/write address 

module RAM 
#(parameter DATA_WIDTH=32, parameter SIZE = 6, FILE_NAME="")
(
	input [(DATA_WIDTH-1):0] entry,
	input [31:0] index,
	input wr_en,
	input clk,
	output [(DATA_WIDTH-1):0] entry_out
);
	
	localparam M = 100;
	localparam N = 50;
	localparam N2 = 2;
	// Declare the RAM variable
	reg [DATA_WIDTH-1:0] mem[SIZE-1:0];

	// Variable to hold the registered read address
	reg [31:0] addr_reg;

	always @ (posedge clk) begin
		if (wr_en) mem[index] <= entry;
		//if (read_en) addr_reg <= index;
      addr_reg <= index;
	end

	// Continuous assignment implies read returns NEW data.
	// This is the natural behavior of the TriMatrix memory
	// blocks in Single Port mode.  
	assign entry_out = mem[addr_reg];
	
	integer i;
	initial begin
		if (FILE_NAME != "") $readmemb(FILE_NAME, mem);
      addr_reg = 0;
		if (SIZE != 35) begin
			for (i = M*N+N*N2; i < SIZE; i = i + 1)  mem[i] = 0;
		end
	end

endmodule
