module clk_divid(clk, rstn, out_clk);

    input      clk;
    input      rstn;
    output reg out_clk;

    always @(posedge clk) begin
        if (!rstn) begin
            out_clk <= 1'b0;
        end else begin
            out_clk <= ~out_clk;
        end
    end

endmodule