# ĐẶC TẢ KỸ THUẬT (SPECIFICATION) - D01

## 1. Bảng Cổng Tín hiệu (Pinout Interface)
| Tên tín hiệu | Hướng | Độ rộng | Miền Clock | Mô tả chức năng |
| :--- | :---: | :---: | :---: | :--- |
| `clk` | Input | 1 bit | - | Xung nhịp hệ thống (100 MHz) |
| `rst_n` | Input | 1 bit | `clk` | Reset bất đồng bộ (Active-Low) |
| `en` | Input | 1 bit | `clk` | Tín hiệu cho phép đếm (1: Enable, 0: Hold/Disable) |
| `up_down` | Input | 1 bit | `clk` | Hướng đếm (1: Đếm tiến UP, 0: Đếm lùi DOWN) |
| `load` | Input | 1 bit | `clk` | Tín hiệu nạp dữ liệu song song (Active-High) |
| `d_in` | Input | 8 bit | `clk` | Dữ liệu ngõ vào nạp song song (Parallel Data) |
| `count` | Output | 8 bit | `clk` | Giá trị bộ đếm ngõ ra $Q[7:0]$ |
| `max_tick` | Output | 1 bit | `clk` | Báo bằng 1 khi `count = 255` (0xFF) |
| `min_tick` | Output | 1 bit | `clk` | Báo bằng 1 khi `count = 0` (0x00) |

## 2. Bảng Ưu tiên Mức Điều khiển (Priority Logic Table)
| `rst_n` | `load` | `en` | `up_down` | Hành động ngõ ra `count[7:0]` |
| :---: | :---: | :---: | :---: | :--- |
| `0` | X | X | X | Reset về `8'b0000_0000` ngay lập tức |
| `1` | `1` | X | X | Nạp trực tiếp dữ liệu ngõ vào: `count <= d_in` |
| `1` | `0` | `1` | `1` | Đếm tiến: `count <= count + 1` |
| `1` | `0` | `1` | `0` | Đếm lùi: `count <= count - 1` |
| `1` | `0` | `0` | X | Giữ nguyên giá trị (Hold / Freeze) |