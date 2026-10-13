# 02. Đặc tả kỹ thuật (Specification)

## 1. Chuẩn giao tiếp I/O (Tiny Tapeout 08)

### Input Bus (`ui[7:0]`)
- `ui[0]`: `en` (Enable - Cho phép đếm)
- `ui[1]`: `up_down` (Chọn hướng đếm `1`: Up, `0`: Down)
- `ui[2]`: `load` (Nạp dữ liệu song song)
- `ui[7:3]`: Unused (Nối logic 0)

### Bidirectional Bus (`uio[7:0]`)
- Được cấu hình làm cổng Input nhận dữ liệu nạp song song `d_in[7:0]`.

### Output Bus (`uo[7:0]`)
- Xuất giá trị đếm 8-bit `count[7:0]`.

## 2. Mức ưu tiên tín hiệu điều khiển
$$\text{rst\_n (Async Reset)} > \text{en (Hold Mode)} > \text{load (Parallel Load)} > \text{up\_down (Up/Down Count)}$$
