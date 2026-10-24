# D01 · Bối cảnh ứng dụng



| | |
|---|---|
| Mã đề | **D01** |
| Tên đề | Bộ đếm nhị phân 8-bit đa năng |
| Nhóm đề | D · Bộ đếm và chia tần |
| Độ khó | Trung bình (nhẹ) |
| Loại mạch | **Tuần tự** |
| Quy mô ước lượng (Charter) | ~110–160 cell · 1×1 tile |
| Nguồn gốc | Project Charter — D01, mục 1 |

---

## 1. Mục tiêu và bối cảnh ứng dụng

Trích nguyên văn Charter mục 1:

> Phân tích khối số “Bộ đếm nhị phân 8-bit đa năng” ở mức khối. Bối cảnh ứng dụng: Khối đếm sản phẩm đi qua băng chuyền, nạp được giá trị đầu và đếm ngược để báo còn bao nhiêu suất.

## 2. Vị trí khối D01 trong hệ thống

```
   ┌──────────────┐      ┌──────────────────────────────┐      ┌──────────────┐
   │  Nguồn tín   │─────▶│      ►►► KHỐI D01 ◄◄◄        │─────▶│  Tầng tiêu   │
   │  hiệu / dữ   │      │  Bộ đếm nhị phân 8-bit đa năn │      │  thụ kết quả │
   │  liệu vào    │      │  Loại mạch: Tuần tự          │      │              │
   └──────────────┘      └──────────────────────────────┘      └──────────────┘
```

> Sơ đồ chi tiết có chú thích: `03_ARCHITECTURE/system_diagram.md`.

## 3. Phân loại analog / digital / mixed

| Khối | Phân loại | Ghi chú |
|---|---|---|
| Cảm biến / nguồn tín hiệu vật lý (nếu có) | Analog | Đại lượng liên tục |
| Chuyển đổi ADC/DAC (nếu có) | Mixed-signal | Ranh giới analog–số |
| **D01 — Bộ đếm nhị phân 8-bit đa năng** | **Digital, tuần tự** | Có ô nhớ, hoạt động theo cạnh clock |
| Tầng xử lý phía sau | Digital | Tiêu thụ kết quả của D01 |

Bằng chứng cho dòng phân loại của D01: tổng hợp thật cho **8 flip-flop**
(`06_GDSII/synthesis/synth_stat.txt`).

---

**Truy vết:** yêu cầu sinh từ tài liệu này được đánh số `REQ-D01-0xx` trong
`01_REQUIREMENT/requirements.md`, và truy vết đến bằng chứng trong `07_TRACEABILITY/RTM.csv`.

*Phiên bản: v1.0 · Ngày: 2026-09-24*
