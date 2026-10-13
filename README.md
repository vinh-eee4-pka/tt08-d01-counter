# Project D01: 8-bit Universal Counter (Tiny Tapeout 08)

**Tác giả:** Lưu Quốc Vinh  
**Trường:** Đại học Phenikaa - Ngành Kỹ thuật Điện tử - Viễn thông (Vi mạch bán dẫn)  
**Mục tiêu:** Thiết kế và đóng gói vi mạch Bộ đếm nhị phân 8-bit đa năng trên nền tảng **Tiny Tapeout 08 (TT08)**.

---

## 📌 Giới thiệu chung
Bộ đếm nhị phân 8-bit đa năng (**8-bit Universal Counter**) là khối chức năng xử lý số tích hợp các chế độ hoạt động:
- **Đếm tiến (Up Counting)**
- **Đếm lùi (Down Counting)**
- **Nạp dữ liệu song song (Parallel Load)**
- **Giữ giá trị (Hold / Disable)**
- **Xóa bất đồng bộ (Asynchronous Active-Low Reset)**

---

## 🎛️ Bảng giao tiếp chân tín hiệu (Pinout Table)

| Chân (Pin) | Tên tín hiệu | Hướng (I/O) | Mô tả chức năng |
|---|---|---|---|
| clk | Clock | Input | Xung nhịp hệ thống |
| rst_n | Reset | Input | Tín hiệu Reset tích cực mức thấp (0) |
| ui[0] | en | Input | Cho phép đếm (1: Enable, 0: Hold) |
| ui[1] | up_down | Input | Hướng đếm (1: Up, 0: Down) |
| ui[2] | load | Input | Nạp dữ liệu song song (1: Load từ d_in) |
| uio[7:0] | d_in[7:0] | Input | Dữ liệu nạp đầu vào 8-bit |
| uo[7:0] | count[7:0] | Output | Giá trị đếm đầu ra 8-bit |

---

## 📊 Bảng chức năng (Function Table)

| rst_n | en | load | up_down | Hoạt động (Operation) | Giá trị đếm count[7:0] |
|:---:|:---:|:---:|:---:|---|---|
| 0 | X | X | X | **Reset** | 8'b00000000 |
| 1 | 0 | X | X | **Hold** | Không đổi |
| 1 | 1 | 1 | X | **Parallel Load** | Dữ liệu d_in[7:0] |
| 1 | 1 | 0 | 1 | **Up Count** | count + 1 |
| 1 | 1 | 0 | 0 | **Down Count** | count - 1 |

---

## 📁 Cấu trúc tài liệu dự án
- [01_REQUIREMENT](./01_REQUIREMENT): Yêu cầu thiết kế chi tiết.
- [02_SPECIFICATION](./02_SPECIFICATION): Đặc tả kỹ thuật & chuẩn giao tiếp.
- [03_ARCHITECTURE](./03_ARCHITECTURE): Sơ đồ kiến trúc Datapath & Control Unit.
- [04_IMPLEMENTATION](./04_IMPLEMENTATION): Mã nguồn RTL Verilog & Đóng gói TT08.
- [05_VERIFICATION](./05_VERIFICATION): Kịch bản mô phỏng & Kết quả kiểm thử.
