/*
 * Copyright (c) 2024 Luu Quoc Vinh
 * SP-DX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_d01_counter (
    input  wire [7:0] ui_in,    // Input: [0]=en, [1]=up_down, [2]=load
    output wire [7:0] uo_out,   // Output: 8-bit count value
    input  wire [7:0] uio_in,   // IO Input: [7:0] = d_in (Parallel Load Data)
    output wire [7:0] uio_out,  // IO Output: Không dùng (gán 0)
    output wire [7:0] uio_oe,   // IO Enable: All 0 (chế độ Input)
    input  wire       ena,      // Always 1 khi cấp nguồn
    input  wire       clk,      // Xung Clock
    input  wire       rst_n     // Reset tích cực mức thấp (0)
);

    // Tách tín hiệu điều khiển từ ui_in
    wire en      = ui_in[0];
    wire up_down = ui_in[1];
    wire load    = ui_in[2];
    
    // Tín hiệu nạp dữ liệu từ uio_in
    wire [7:0] d_in = uio_in;

    // Thanh ghi lưu giá trị đếm
    reg [7:0] count_reg;

    // Mạch đếm vạn năng
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count_reg <= 8'b0;
        end else if (en) begin
            if (load) begin
                count_reg <= d_in;
            end else if (up_down) begin
                count_reg <= count_reg + 1'b1;
            end else begin
                count_reg <= count_reg - 1'b1;
            end
        end
    end

    // Gán đầu ra
    assign uo_out  = count_reg;
    assign uio_out = 8'b0;
    assign uio_oe  = 8'b0;

    // Bỏ qua cảnh báo tín hiệu thừa (Unused inputs)
    wire _unused = &{ena, ui_in[7:3], 1'b0};

endmodule
