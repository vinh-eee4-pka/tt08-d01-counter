// ============================================================================
// Testbench : tb_d01_counter_8bit.v
// Đề tài    : d01 - Bộ đếm nhị phân 8-bit đa năng
// Nhóm      : G02
// ============================================================================

`timescale 1ns / 1ps

module tb_d01_counter_8bit;

    reg        clk;
    reg        rst_n;
    reg        en;
    reg        up_down;
    reg        load;
    reg  [7:0] d_in;
    wire [7:0] count;
    wire       max_tick;
    wire       min_tick;

    // Kết nối với Module RTL
    d01_counter_8bit uut (
        .clk(clk),
        .rst_n(rst_n),
        .en(en),
        .up_down(up_down),
        .load(load),
        .d_in(d_in),
        .count(count),
        .max_tick(max_tick),
        .min_tick(min_tick)
    );

    // Tạo xung nhịp 100MHz (Chu kỳ 10ns)
    always #5 clk = ~clk;

    initial begin
        // 1. Khởi tạo tín hiệu
        clk = 0; rst_n = 0; en = 0; up_down = 1; load = 0; d_in = 8'd0;

        // 2. Kiểm tra Reset
        #15 rst_n = 1;

        // 3. Kiểm tra Đếm tiến (Up Count)
        #10; en = 1; up_down = 1;
        #50;

        // 4. Kiểm tra Tạm dừng đếm (Hold)
        en = 0;
        #30;

        // 5. Kiểm tra Nạp dữ liệu song song (Parallel Load val = 250)
        load = 1; d_in = 8'd250;
        #10; load = 0; en = 1; up_down = 1;

        // 6. Đếm tiến cho tràn sang max_tick
        #70;

        // 7. Kiểm tra Đếm lùi (Down Count)
        up_down = 0;
        #50;

        $display("=== MO PHONG DE TAI D01 HOAN TAT TOTT ===");
        $finish;
    end

endmodule