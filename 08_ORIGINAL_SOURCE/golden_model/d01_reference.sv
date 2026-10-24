module d01_reference (
    input logic clk, input logic rst_n, input logic enable, input logic up,
    output logic [7:0] count_ref
);
    always_ff @(posedge clk) begin
        if (!rst_n) count_ref <= 8'd0;
        else if (!enable) count_ref <= count_ref;
        else if (up) count_ref <= count_ref + 8'd1;
        else count_ref <= count_ref - 8'd1;
    end
endmodule
