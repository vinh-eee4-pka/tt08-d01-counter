# NHẬT KÝ VÀ KỊCH BẢN THỰC HIỆN DỰ ÁN - NHÓM G02

## 1. Thông tin Dự án
- **Tên đề tài**: d01 - Thiết kế Vi mạch Bộ đếm Nhị phân 8-bit Đa năng (Universal 8-bit Binary Counter)
- **Nhóm thực hiện**: G02
- **Thành viên**: Lư Quốc Vinh

## 2. Kịch bản Luồng Thiết kế (Design Flow Script)
1. **01_REQUIREMENT**: Phân tích yêu cầu bài toán bộ đếm 8-bit tích hợp Up/Down, Load, Hold.
2. **02_SPECIFICATION**: Định nghĩa Pinout, ưu tiên tín hiệu điều khiển và cờ trạng thái `max_tick`/`min_tick`.
3. **03_ARCHITECTURE**: Thiết kế sơ đồ khối Datapath (Thanh ghi + Bộ cộng/trừ 8-bit) và Controlpath.
4. **04_IMPLEMENTATION**: Lập trình RTL Verilog có chú thích Tiếng Việt, gán ràng buộc SDC (100MHz), chạy Synthesis và xuất Layout GDSII.
5. **05_VERIFICATION**: Viết Testbench kiểm thử đầy đủ các chế độ, xuất báo cáo STA (Slack >= 0) và kiểm tra vật lý DRC/LVS.
6. **08_ORIGINAL_SOURCE**: Lưu trữ tài liệu tham khảo gốc.

## 3. Nhật ký Tiến độ Chi tiết
- **Giai đoạn 1**: Khởi tạo cấu trúc dự án và viết tài liệu SPEC chuẩn Tiếng Việt cho đề tài d01.
- **Giai đoạn 2**: Lập trình khối `d01_counter_8bit.v` và viết Testbench `tb_d01_counter_8bit.v`.
- **Giai đoạn 3**: Tổng hợp logic (Synthesis) thu được `synthesis_report.rpt`.
- **Giai đoạn 4**: Chạy phân tích Timing STA thu được $WNS = +1.12\text{ ns}$ (Đạt).
- **Giai đoạn 5**: Thực hiện Layout vật lý, chạy DRC (0 Error), LVS Match và xuất file `layout.gds`.