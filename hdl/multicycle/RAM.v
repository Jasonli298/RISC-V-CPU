module RAM
	#(parameter ENTRY_WIDTH = 8,
      parameter SIZE = 1024,
      parameter FILE_NAME = ""
	  )
	(wr_en,
	 index0,
	 index1,
	 index2,
	 index3,
	 entry0,
	 entry1,
	 entry2,
	 entry3,
	 entry_out0,
	 entry_out1,
	 entry_out2,
	 entry_out3
	);

input                        wr_en;
input  [31:0]                index0, index1, index2, index3;
input [ENTRY_WIDTH - 1:0]    entry0, entry1, entry2, entry3;
output reg [ENTRY_WIDTH-1:0] entry_out0, entry_out1, entry_out2, entry_out3;

reg signed [ENTRY_WIDTH - 1:0] mem [SIZE-1:0];

initial begin
	if (FILE_NAME != "") begin
		$readmemb(FILE_NAME, mem);
	end
end

always @(index0 or index1 or index2 or index3 or wr_en) begin
	if (wr_en) begin
		mem[index0] = entry0;
		mem[index1] = entry1;
		mem[index2] = entry2;
		mem[index3] = entry3;
	end else begin
		entry_out0 = mem[index0];
		entry_out1 = mem[index1];
		entry_out2 = mem[index2];
		entry_out3 = mem[index3];
	end
end

endmodule
