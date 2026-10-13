# 05. Kiểm thử & Mô phỏng (Verification)

## 1. Phương pháp kiểm thử
Sử dụng bộ công cụ **Cocotb (Python Testbench)** kết hợp trình mô phỏng **Icarus Verilog**:
- Self-checking testbench tự động so sánh dữ liệu với Gold Model.
- Xuất file waveform `tb.vcd` phục vụ phân tích dạng sóng trên **GTKWave**.

## 2. Các trường hợp kiểm thử (Test Cases)
1. **TC_01 (Async Reset):** Kích hoạt `rst_n = 0`, kiểm tra đầu ra về `8'h00`.
2. **TC_02 (Parallel Load):** Nạp ngẫu nhiên dữ liệu từ `d_in[7:0]`.
3. **TC_03 (Up Count):** Đếm tiến liên tục qua điểm tràn `255 -> 0`.
4. **TC_04 (Down Count):** Đếm lùi liên tục qua điểm tràn `0 -> 255`.
5. **TC_05 (Hold Mode):** Đặt `en = 0`, kiểm tra giữ nguyên giá trị đếm.
6. **TC_06 (Random Sequence):** Kiểm thử ngẫu nhiên tổ hợp các chân điều khiển.
