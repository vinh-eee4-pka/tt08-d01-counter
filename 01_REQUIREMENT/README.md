# 01. Yêu cầu thiết kế (Requirements)

## 1. Mục tiêu
Thiết kế bộ đếm nhị phân 8-bit đa năng (Universal Counter) đáp ứng quy chuẩn đóng gói của Tiny Tapeout 08.

## 2. Yêu cầu chức năng
1. **Reset:** Khi rst_n = 0, bộ đếm lập tức về 0x00.
2. **Nạp dữ liệu:** Khi en = 1 và load = 1, nạp giá trị từ d_in[7:0] vào thanh ghi đếm tại sườn lên xung clk.
3. **Đếm tiến:** Khi en = 1, load = 0, up_down = 1, tăng giá trị đếm lên 1 sau mỗi chu kỳ clock (tràn từ 255 về 0).
4. **Đếm lùi:** Khi en = 1, load = 0, up_down = 0, giảm giá trị đếm đi 1 sau mỗi chu kỳ clock (tràn từ 0 về 255).
5. **Dừng đếm:** Khi en = 0, giữ nguyên giá trị đếm hiện tại.

## 3. Giới hạn tài nguyên
- Diện tích: 1 Tile (1x1) trên khuôn đế Tiny Tapeout 08.
- Ngôn ngữ mô tả phần cứng: Verilog HDL.
