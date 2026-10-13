# D01 — 8-Bit Universal Counter (Tiny Tapeout 08)

RTL implementation of an 8-bit universal binary counter with up/down counting, parallel loading, and hold functionality for digital logic design and embedded control systems.

This project is developed as part of an RTL-to-GDSII digital design workflow on **Tiny Tapeout 08 (TT08)**, including RTL design, functional verification, synthesis, static timing analysis (STA), physical implementation, and final layout generation using OpenLane 2 and Sky130A PDK.

---

# TÀI LIỆU TIẾNG VIỆT

## 1. Tổng quan
Đây là thiết kế **Bộ đếm nhị phân 8-bit đa năng (8-Bit Universal Counter)** được thực hiện bằng RTL Verilog.

Mục tiêu của project không chỉ là xây dựng mạch thực hiện đúng chức năng logic, mà còn thực hiện toàn bộ quy trình thiết kế vi mạch ASIC chuyên nghiệp từ RTL đến GDSII:

```text
RTL
 ↓
Functional Verification (Cocotb / Icarus Verilog)
 ↓
Synthesis (Yosys)
 ↓
Static Timing Analysis (STA)
 ↓
Floorplan
 ↓
Placement
 ↓
Clock Tree Synthesis (CTS)
 ↓
Routing
 ↓
Post-route STA
 ↓
DRC / LVS / Antenna Checks
 ↓
GDSII
```

Flow ASIC được thực hiện tự động bằng **OpenLane 2.3.10** với công nghệ **Sky130A PDK** thông qua hạ tầng đóng gói Tiny Tapeout 08 (TT08).

*Lưu ý: Project này thực hiện mô phỏng và chạy luồng RTL-to-GDSII bằng công cụ EDA nguồn mở để phục vụ đóng gói và kiểm chứng vi mạch.*

---

## 2. Đặc tả thiết kế

### Bảng giao tiếp tín hiệu (Pinout Table)

| Tín hiệu | Kích thước | Hướng | Chức năng |
|---|:---:|:---:|---|
| `clk` | 1 bit | Input | Xung nhịp hệ thống (Clock) |
| `rst_n` | 1 bit | Input | Reset bất đồng bộ, tích cực mức thấp (`0`) |
| `ui[0]` (`en`) | 1 bit | Input | Cho phép hoạt động (`1`: Enable, `0`: Hold) |
| `ui[1]` (`up_down`) | 1 bit | Input | Chọn hướng đếm (`1`: Up count, `0`: Down count) |
| `ui[2]` (`load`) | 1 bit | Input | Cho phép nạp dữ liệu song song (`1`: Parallel Load) |
| `ui[7:3]` | 5 bit | Input | Unused (được nối logic `0`) |
| `uio[7:0]` (`d_in`) | 8 bit | Input | Dữ liệu nạp song song đầu vào (Parallel Data Input) |
| `uo[7:0]` (`count`) | 8 bit | Output | Giá trị đếm đầu ra 8-bit (`0` đến `255`) |

### Thông số chính
- **Kích thước bộ đếm:** 8 bit (`0x00` đến `0xFF` / `0` đến `255`).
- **Nạp dữ liệu song song (Parallel Load):** Nạp lập tức giá trị `d_in[7:0]` vào thanh ghi đếm tại sườn lên xung `clk` khi `load = 1` và `en = 1`.
- **Xử lý tràn (Overflow / Underflow Wrap-around):**
  - Khi đếm tiến đạt `255` (`0xFF`), chu kỳ tiếp theo tự động quay về `0` (`0x00`).
  - Khi đếm lùi đạt `0` (`0x00`), chu kỳ tiếp theo tự động quay về `255` (`0xFF`).
- **Thứ tự ưu tiên tín hiệu điều khiển:**
  1. `rst_n` (Mức ưu tiên cao nhất - Reset bất đồng bộ).
  2. `en` (Nếu `en = 0`, mạch giữ nguyên giá trị đếm hiện tại).
  3. `load` (Nếu `en = 1` và `load = 1`, thực hiện nạp dữ liệu `d_in`).
  4. `up_down` (Nếu `en = 1` và `load = 0`, thực hiện đếm tiến hoặc đếm lùi).

---

## 3. Kiến trúc

Thiết kế sử dụng phương pháp **MUX-based Next-State Generation** kết hợp thanh ghi DFF 8-bit.

Mạch bao gồm 2 phần chính:
1. **Control Logic & Next-State MUX Network:** Tính toán giá trị đếm tiếp theo (`count_next`) dựa trên các tín hiệu điều khiển (`en`, `load`, `up_down`).
2. **8-Bit State Register:** Dãy 8 D-Flip-Flops lưu giữ giá trị đếm hiện tại, cập nhật đồng bộ tại sườn lên `posedge clk`.

### Bảng chuyển trạng thái (State Transition Table)

| `rst_n` | `en` | `load` | `up_down` | Giá trị tiếp theo (`count_next`) | Chế độ hoạt động (Operation) |
|:---:|:---:|:---:|:---:|:---:|---|
| `0` | `X` | `X` | `X` | `8'h00` | **Asynchronous Reset** |
| `1` | `0` | `X` | `X` | `count` | **Hold / Disable** |
| `1` | `1` | `1` | `X` | `d_in[7:0]` | **Parallel Load** |
| `1` | `1` | `0` | `1` | `count + 1` | **Up Counting** |
| `1` | `1` | `0` | `0` | `count - 1` | **Down Counting** |

---

## 4. Vì sao chọn kiến trúc MUX-based Next-State?

Có hai cách triển khai bộ đếm đa năng 8-bit:

- **Cách 1 — MUX-based Next-State Logic (Được chọn):**
  Dùng một mạng Multiplexer tập trung chọn giữa `count + 1`, `count - 1`, `d_in`, và `count`.
  - **Ưu điểm:** Cấu trúc rõ ràng, đường dữ liệu (Datapath) cân bằng, tối ưu về diện tích cells và dễ dàng cho công cụ Synthesis tối ưu hóa timing slack.
- **Cách 2 — Cascaded Adder/ALU:**
  Dùng khối ALU tổng quát với phép cộng/trừ số có dấu.
  - **Nhược điểm:** Tốn nhiều gate diện tích không cần thiết, tăng đường truyền trễ (critical path delay).

---

## 5. Functional Verification

Testbench được thiết kế theo hướng **self-checking** bằng Python (**Cocotb**) kết hợp **Icarus Verilog**. Testbench tự động so sánh kết quả mô phỏng của bộ đếm RTL với mô hình tham chiếu (Gold Model).

Các trường hợp kiểm thử bao gồm:
1. **Async Reset Test:** Kiểm tra tính đúng đắn của Reset bất đồng bộ (`rst_n = 0`).
2. **Parallel Load Test:** Nạp các giá trị ngẫu nhiên từ `d_in`.
3. **Up-Count Sequence:** Đếm tiến liên tục qua điểm tràn (`254 -> 255 -> 0 -> 1`).
4. **Down-Count Sequence:** Đếm lùi liên tục qua điểm tràn (`1 -> 0 -> 255 -> 254`).
5. **Hold Mode Test:** Ngắt tín hiệu `en = 0` tại các thời điểm ngẫu nhiên để xác minh giá trị đếm được giữ nguyên.
6. **Random Control Mix:** Thay đổi ngẫu nhiên các tín hiệu `en`, `load`, `up_down` để đảm bảo mạch hoạt động đúng theo thứ tự ưu tiên.

---

## 6. RTL-to-GDSII Flow

Project sử dụng OpenLane 2.3.10 và Sky130A PDK với các bước chính:

```text
RTL
 ↓
Synthesis (Yosys)
 ↓
Floorplan
 ↓
Power Planning (PDN)
 ↓
Placement
 ↓
CTS (Clock Tree Synthesis)
 ↓
Routing
 ↓
Parasitic Extraction (SPEF)
 ↓
Post-route STA (OpenSTA)
 ↓
DRC / LVS / Antenna Checks
 ↓
GDSII
```

---

## 7. Cấu trúc thư mục

- [01_REQUIREMENT](./01_REQUIREMENT): Yêu cầu thiết kế chi tiết.
- [02_SPECIFICATION](./02_SPECIFICATION): Đặc tả kỹ thuật & Bảng chân tín hiệu.
- [03_ARCHITECTURE](./03_ARCHITECTURE): Sơ đồ kiến trúc Datapath & Control Unit.
- [04_IMPLEMENTATION](./04_IMPLEMENTATION): Mã nguồn RTL Verilog & Đóng gói TT08.
- [05_VERIFICATION](./05_VERIFICATION): Kịch bản mô phỏng & Kết quả kiểm thử.

---

# ENGLISH DOCUMENTATION

## Specification
- **Input signals:** `clk`, `rst_n`, `ui[0]` (`en`), `ui[1]` (`up_down`), `ui[2]` (`load`), `uio[7:0]` (`d_in`).
- **Output signal:** `uo[7:0]` (`count`).
- **Counter width:** 8 bits (`0` to `255`).
- **Features:** Asynchronous active-low reset, parallel load, up/down counting, hold mode, overflow/underflow wrap-around.

## Architecture
The design uses MUX-based Next-State logic paired with an 8-bit D-flip-flop register:
```text
count_next = (!en)      ? count :
             (load)     ? d_in :
             (up_down)  ? count + 1 : count - 1;
```

## Verification
Self-checking Cocotb testbench verifying Reset, Load, Up/Down counting, Hold mode, and Random Sequences.
