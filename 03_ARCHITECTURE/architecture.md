# KIẾN TRÚC HỆ THỐNG (ARCHITECTURE) - D01

## 1. Sơ đồ Kiến trúc Tổng quan
![Sơ đồ khối kiến trúc](./block_diagram.png)

## 2. Phân tích Các Khối Chức năng
1. **Khối Thanh ghi 8-bit (8-bit Register)**: Lưu trữ giá trị đếm hiện tại, cập nhật ở cạnh lên xung nhịp `clk`.
2. **Khối Logic Chọn Chế độ (Mode Multiplexer)**: Tầng Mux ưu tiên xử lý các chế độ theo thứ tự: `Reset` > `Load` > `Enable (Up/Down)` > `Hold`.
3. **Khối Cộng/Trừ (8-bit Adder/Subtractor)**: Thực hiện phép toán `+1` khi `up_down = 1` và `-1` khi `up_down = 0`.
4. **Khối Giải mã Cờ tràn (Status Flags)**: 
   - `max_tick = 1` khi `count == 8'hFF`.
   - `min_tick = 1` khi `count == 8'h00`.