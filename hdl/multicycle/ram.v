module ram #(parameter filename = "",
             parameter width = 32)
            (input wr_en,
             input [9:0] addr,
             input reg signed [(width - 1):0] data_in,
             output reg signed [(width - 1):0] data_out
);

reg signed [(width - 1): 0] mem [0:1023];

always @(posedge clk) begin
    if (wr_en) begin
        mem[addr] <= data_in;
    end
    data_out <= mem[addr];
end

initial begin
    if (filename != "") begin
        $readmemb(filename, mem);
    end
end

endmodule
