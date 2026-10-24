module d01_core (
    input  logic       clk,
    input  logic       rst_n,
    input  logic       enable,
    input  logic       up,
    output logic [7:0] count
);
    always_ff @(posedge clk) begin
        if (!rst_n)
            count <= 8'd0;
        else if (enable) begin
            if (up)
                count <= count + 8'd1;
            else
                count <= count - 8'd1;
        end
    end
endmodule
