`default_nettype none

module tt_um_d01_counter (
    input  wire [7:0] ui_in,    // Giá trị nạp song song
    output wire [7:0] uo_out,   // Giá trị bộ đếm xuất ra
    input  wire [7:0] uio_in,   // [0]: load, [1]: up_down, [2]: count_en
    output wire [7:0] uio_out,  // [0]: overflow_flag, [1]: underflow_flag
    output wire [7:0] uio_oe,   // Hướng I/O (1 = Output)
    input  wire       ena,      // Enable toàn cục
    input  wire       clk,      // Xung clock
    input  wire       rst_n     // Reset đồng bộ (tích cực mức thấp)
);

    assign uio_oe = 8'hFF; 

    wire load     = uio_in[0];
    wire up_down  = uio_in[1];
    wire count_en = uio_in[2];

    reg [7:0] count_reg;
    reg       overflow_reg;
    reg       underflow_reg;

    always @(posedge clk) begin
        if (!rst_n) begin
            count_reg     <= 8'd0;
            overflow_reg  <= 1'b0;
            underflow_reg <= 1'b0;
        end else if (ena) begin
            overflow_reg  <= 1'b0;
            underflow_reg <= 1'b0;

            if (load) begin
                count_reg <= ui_in;
            end else if (count_en) begin
                if (up_down) begin
                    if (count_reg == 8'd255) begin
                        count_reg    <= 8'd0;
                        overflow_reg <= 1'b1;
                    end else begin
                        count_reg <= count_reg + 1'b1;
                    end
                end else begin
                    if (count_reg == 8'd0) begin
                        count_reg     <= 8'd255;
                        underflow_reg <= 1'b1;
                    end else begin
                        count_reg <= count_reg - 1'b1;
                    end
                end
            end
        end
    end

    assign uo_out  = count_reg;
    assign uio_out = {6'b000000, underflow_reg, overflow_reg};

endmodule
