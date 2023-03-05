module clk_divid(clk, rst, out_clk);

    input      clk;
    input      rst;
    output reg out_clk;

    always @(posedge clk) begin
        if (rst) begin
            out_clk <= 1'b0;
        end else begin
            out_clk <= ~out_clk;
        end
    end

endmodule
