# 01. Yêu cầu thiết kế (Requirements)

## 1. Mục tiêu
Thiết kế bộ đếm nhị phân 8-bit đa năng (8-Bit Universal Counter) đáp ứng đầy đủ các tiêu chuẩn đóng gói vi mạch của **Tiny Tapeout 08 (TT08)** trên quy trình OpenLane 2 / Sky130A PDK.

## 2. Yêu cầu chức năng (Functional Requirements)
1. **Asynchronous Reset:** Khi `rst_n = 0`, bộ đếm lập tức đưa giá trị đầu ra về `8'h00` bất chấp xung clock.
2. **Parallel Data Load:** Khi `en = 1` và `load = 1`, nạp giá trị trực tiếp từ bus đầu vào `d_in[7:0]` vào thanh ghi đếm tại sườn lên `clk`.
3. **Up Counting:** Khi `en = 1`, `load = 0`, `up_down = 1`, tăng giá trị đếm lên 1 đơn vị sau mỗi chu kỳ clock (tràn từ `255` về `0`).
4. **Down Counting:** Khi `en = 1`, `load = 0`, `up_down = 0`, giảm giá trị đếm đi 1 đơn vị sau mỗi chu kỳ clock (tràn từ `0` về `255`).
5. **Hold Mode:** Khi `en = 0`, giữ nguyên giá trị đếm hiện tại.

## 3. Giới hạn tài nguyên (Constraints)
- **Diện tích:** 1 Tile (1x1) trên khuôn đế Tiny Tapeout 08.
- **Ngôn ngữ mô tả phần cứng:** Standard Verilog HDL (IEEE 1364-2001).
