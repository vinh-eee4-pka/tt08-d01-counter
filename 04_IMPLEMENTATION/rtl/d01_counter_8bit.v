// ============================================================================
// Module : d01_counter_8bit.v
// Đề tài : d01 - Bộ đếm nhị phân 8-bit đa năng (Universal 8-bit Binary Counter)
// Nhóm   : G02
// ============================================================================

module d01_counter_8bit (
    input  wire       clk,        // Xung nhịp hệ thống (100 MHz)
    input  wire       rst_n,      // Reset bất đồng bộ (Active-Low)
    input  wire       en,         // Tín hiệu cho phép đếm (1: Cho phép, 0: Tạm dừng)
    input  wire       up_down,    // Hướng đếm (1: Đếm tiến UP, 0: Đếm lùi DOWN)
    input  wire       load,       // Tín hiệu nạp dữ liệu song song (Active-High)
    input  wire [7:0] d_in,       // Dữ liệu ngõ vào nạp song song 8-bit
    output reg  [7:0] count,      // Giá trị bộ đếm ngõ ra 8-bit
    output wire       max_tick,   // Cờ báo đạt giá trị cực đại 255
    output wire       min_tick    // Cờ báo đạt giá trị cực tiểu 0
);

    // ------------------------------------------------------------------------
    // Mạch đếm chính cập nhật theo cạnh lên xung nhịp clk
    // ------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count <= 8'd0;               // Ưu tiên 1: Reset về 0
        end else if (load) begin
            count <= d_in;                // Ưu tiên 2: Nạp dữ liệu song song
        end else if (en) begin
            if (up_down)
                count <= count + 8'd1;   // Ưu tiên 3a: Đếm tiến (UP)
            else
                count <= count - 8'd1;   // Ưu tiên 3b: Đếm lùi (DOWN)
        end
        // Ngược lại (en = 0): Giữ nguyên giá trị count hiện tại (Hold)
    end

    // ------------------------------------------------------------------------
    // Tạo tín hiệu cờ trạng thái cực đại / cực tiểu
    // ------------------------------------------------------------------------
    assign max_tick = (count == 8'hFF);
    assign min_tick = (count == 8'h00);

endmodule