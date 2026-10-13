# 05. Kiểm thử & Mô phỏng (Verification)

## 1. Các trường hợp kiểm thử (Test Cases)
1. **TC_01 (Reset):** Cấp rst_n = 0, kiểm tra đầu ra uo == 0x00.
2. **TC_02 (Parallel Load):** Đặt d_in = 0xA5, load = 1, en = 1, kiểm tra đầu ra uo == 0xA5.
3. **TC_03 (Up Count):** Đặt en = 1, load = 0, up_down = 1, kiểm tra đầu ra tăng dần.
4. **TC_04 (Down Count):** Đặt en = 1, load = 0, up_down = 0, kiểm tra đầu ra giảm dần.
5. **TC_05 (Hold):** Đặt en = 0, kiểm tra giá trị đếm không thay đổi.

## 2. Công cụ kiểm thử
- Cocotb (Python Testbench): Nằm tại thư mục test/test.py.
- Icarus Verilog / GTKWave.
