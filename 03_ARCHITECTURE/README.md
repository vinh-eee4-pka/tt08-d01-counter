# 03. Kiến trúc thiết kế (Architecture)

## 1. Các khối chức năng chính
- **Control Unit (Mạch chọn chế độ):** Quyết định giá trị tiếp theo của bộ đếm dựa trên các tín hiệu điều khiển load, up_down.
- **Datapath (Thanh ghi 8-bit):** Lưu giữ giá trị đếm hiện tại, cập nhật tại sườn lên xung clk.
