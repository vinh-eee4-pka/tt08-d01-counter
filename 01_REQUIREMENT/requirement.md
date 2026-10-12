# YÊU CẦU BÀI TOÁN (REQUIREMENT) - ĐỀ TÀI D01

## 1. Tóm tắt Đề tài
- **Mã đề tài**: d01
- **Tên khối thiết kế**: Bộ đếm nhị phân 8-bit đa năng (Universal 8-bit Binary Counter).
- **Mục tiêu**: Thiết kế vi mạch đếm nhị phân 8-bit tích hợp đầy đủ các chức năng: Đếm tiến (Up), Đếm lùi (Down), Nạp dữ liệu song song (Parallel Load), và Tạm dừng đếm (Hold/Disable).

## 2. Thông số Kỹ thuật Bắt buộc
- **Độ rộng bộ đếm**: 8 bit Unsigned (Dải giá trị đếm từ `0` đến `255` / `0x00` đến `0xFF`).
- **Tần số xung nhịp mục tiêu**: 100 MHz (Chu kỳ $T = 10\text{ ns}$).
- **Cơ chế Reset**: Reset bất đồng bộ tích cực mức thấp (Asynchronous Active-Low Reset).
- **Cơ chế nạp & điều khiển**: Đồng bộ theo cạnh lên xung nhịp hệ thống (`clk`).