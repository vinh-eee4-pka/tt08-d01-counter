# D01 · Sơ đồ hệ thống (System Diagram)

---

## 1. Bối cảnh ứng dụng theo Charter mục 1

> *“Khối đếm sản phẩm đi qua băng chuyền, nạp được giá trị đầu và đếm ngược để báo còn bao
> nhiêu suất.”*

```
   ┌──────────────┐  xung/mức    ┌────────────────┐   enable
   │ Cảm biến quang│─────────────▶│ Bộ đồng bộ +  │────────────┐
   │ trên băng chuyền│ (bất đồng bộ│ tách cạnh     │            │
   └──────────────┘  với clk)     │ (TẦNG NGOÀI)  │            │
                                  └────────────────┘            │
                                                                 │
   ┌──────────────┐                                              │
   │ Bảng điều khiển│──▶ up  (lên = đếm sản phẩm                │
   │ / MCU        │         xuống = đếm ngược suất còn lại)──────┤
   └──────┬───────┘                                              │
          │                                                       │
          │  🔴 load, load_val[7:0]  ── CHƯA CÓ TRONG RTL ────────┤
          │     (Charter mục 4: ui_in[7:0] + uio_in[0])           │
          │                                                       │
          └──▶ rst_n ─────────────────────────────────────────────┤
                                                                   │
                        ╔══════════════════════════════════════════▼═══╗
                        ║              ▓▓▓  D01  ▓▓▓                   ║
                        ║   Bộ đếm nhị phân 8 bit lên/xuống            ║
                        ║   có cho phép và xoá đồng bộ                 ║
                        ║                                              ║
                        ║   count[7:0] ═══════════════════════════════▶║
                        ╚══════════════════════════════════════════════╝
                                              ║
                     ┌────────────────────────╨───────────────────────┐
                     │            Tầng ngoài đọc count                │
                     │  • hiển thị 7 đoạn / LED                       │
                     │  • so với ngưỡng để báo "hết suất"             │
                     │  • 🔴 PHẢI TỰ PHÁT HIỆN QUẤN VÒNG (xem §3)     │
                     └────────────────────────────────────────────────┘
```

> ⚠️ Nhánh `load` / `load_val` trong sơ đồ **chưa tồn tại trong RTL** — xem
> `02_SPECIFICATION/functional_spec.md` §0, W-1 và W-2. Vẽ đủ để thấy khoảng cách.

## 2. Ranh giới khối

| Chức năng | Thuộc D01? | Ghi chú |
|---|:-:|---|
| Cảm biến quang, tạo xung khi có sản phẩm | ❌ | Tầng ngoài |
| **Đồng bộ tín hiệu cảm biến về miền `clk`** | ❌ | **Tầng ngoài.** RTL không có bộ đồng bộ nào — xem §4 |
| **Tách cạnh** (biến mức thành xung một chu kỳ) | ❌ | **Tầng ngoài.** Nếu `enable` giữ mức cao 1000 chu kỳ, D01 đếm 1000 lần — xem §4 |
| Đếm lên / đếm xuống | ✅ | `count + 1` / `count - 1` |
| Giữ khi không cho phép | ✅ | `enable` |
| Xoá về 0 | ✅ | `rst_n`, **đồng bộ** |
| **Nạp giá trị đầu** | 🔴 **ĐÁNG LẼ ✅ — CHƯA CÓ** | Charter mục 4: `ui_in[7:0]` + `uio_in[0]` |
| **Báo quấn vòng / tràn** | ❌ | Không có cổng nào. Charter mục 10 gợi ý 1–2 FF cho cờ tràn nhưng mục 4 không cấp chân cho nó |
| Hiển thị, so ngưỡng, báo động | ❌ | Tầng ngoài |
| Định nghĩa “một suất” = bao nhiêu sản phẩm | ❌ | Tầng ngoài nạp giá trị đầu — mà nạp thì chưa có |

## 3. ⚠️ Hai hợp đồng ẩn mà tầng ngoài phải gánh

**(a) Quấn vòng trông giống hệt reset.** `count` đi từ `255` lên `0` và từ `0` xuống `255`
mà **không báo gì**. Với bối cảnh “đếm sản phẩm”, dây chuyền chạy quá 255 sản phẩm sẽ làm
số đếm về 0 và tầng ngoài không phân biệt được với việc ai đó vừa bấm reset. Tầng ngoài
**phải tự** theo dõi quấn vòng bằng cách so `count` hiện tại với `count` chu kỳ trước — tức
phải nhân đôi một phần chức năng của D01. Đây là hệ quả trực tiếp của việc không có cờ tràn
(`functional_spec.md` INV-9, W-4).

**(b) `enable` là MỨC, không phải XUNG.** D01 đếm **mỗi chu kỳ clock** mà `enable = 1`.
Nếu cảm biến quang giữ mức cao trong suốt thời gian sản phẩm che tia, và thời gian đó dài
1000 chu kỳ clock, thì **một** sản phẩm bị đếm thành **1000**. Tầng ngoài phải tách cạnh
trước khi đưa vào `enable`. Điều này không được ghi ở bất kỳ file sinh tự động nào và là
hiểu lầm dễ mắc nhất khi tích hợp D01.

## 4. Nghĩa vụ đồng bộ hoá — vì sao đáng lo với D01

Bối cảnh Charter mục 1 nói tín hiệu đến từ **cảm biến vật lý trên băng chuyền**, tức từ thế
giới bất đồng bộ. RTL D01 **không có** bộ đồng bộ nào (đọc `d01_core.sv`: 20 dòng, không có
tầng flip-flop nào cho `enable` hay `up`).

Hậu quả nếu tầng ngoài quên đồng bộ: `enable` đổi giá trị đúng vào cửa sổ setup/hold của 8
flip-flop → chúng có thể **vào metastability độc lập với nhau** → một số bit lấy giá trị cũ,
một số bit lấy giá trị mới → `count` nhảy sang một giá trị **hoàn toàn sai**, không phải
`±1`. Đây là lỗi hiếm, không tái lập được, và không mô phỏng RTL nào bắt được.

Nghĩa vụ này cùng loại với nghĩa vụ đồng bộ ở C07 (hai kênh cảm biến) — cả hai đều là phần
mà RTL lõi cố ý không làm, và cả hai đều phải được ghi vào tài liệu tích hợp.

## 5. Phân loại khối

| Tiêu chí | Kết luận | Bằng chứng |
|---|---|---|
| Analog / Digital / Mixed | **Digital thuần** | 49 cell đều là standard cell `sky130_fd_sc_hd`; nhóm Macro = 0 W |
| Tổ hợp / Tuần tự | **Tuần tự** | 8 `dfxtp_1`; công suất nhóm Sequential **74,4 %** |
| Đồng bộ / Bất đồng bộ | **Đồng bộ một miền clock**, **reset đồng bộ** | Một `create_clock`; `dfxtp_1` **không có chân reset** — xem `block_diagram.md` §3 |
| Có FSM? | **Có, dạng bộ đếm 256 trạng thái có điều kiện** | Xem `fsm.md` |

Tỷ lệ công suất tuần tự **74,4 %** / tổ hợp 25,6 % phù hợp với một bộ đếm: phần lớn năng
lượng đi vào 8 flip-flop chuyển mạch mỗi chu kỳ, logic tổ hợp chỉ là một tầng tăng/giảm
mỏng. (So sánh: C06 92,8 % tuần tự với 27 FF; C07 chỉ 10,8 % với 1 FF.)

## 6. Sơ đồ vòng đời RTL → GDSII, trạng thái thật

Lấy từ `06_GDSII/physical_report.md` §1 và BRIEF D01.

```
  ┌────────────────┐
  │ 01 Yêu cầu     │ ✅  từ Charter D01
  └───────┬────────┘
  ┌───────▼────────┐
  │ 02 Đặc tả      │ ✅  (có ghi nhận 6 điểm CHƯA THOẢ ở functional_spec §0)
  └───────┬────────┘
  ┌───────▼────────┐
  │ 03 Kiến trúc   │ ✅  block · datapath · control · fsm · timing_diagram · tradeoff
  └───────┬────────┘
  ┌───────▼────────┐
  │ 04 RTL         │ 🟡 MỘT PHẦN — d01_core.sv (20 dòng); thiếu chức năng NẠP
  └───────┬────────┘
  ┌───────▼────────┐
  │ Mô hình Python │ ✅ PASS   CPython 3 · quét vét cạn 256 × 2 × 2 = 1024 trạng thái
  └───────┬────────┘
  ┌───────▼────────┐
  │ 05 Mô phỏng RTL│ ✅ PASS   Icarus Verilog 12.0 · 17 cạnh clock
  │                │ 🟡 phủ 4/5 ca bắt buộc của Charter mục 8
  └───────┬────────┘
  ┌───────▼────────┐
  │ Tổng hợp logic │ ✅ PASS   Yosys 0.33 → 49 cell · 8 FF · 427,9104 µm²
  └───────┬────────┘
  ┌───────▼────────┐
  │ STA sau tổng hợp│ ✅ PASS  OpenSTA 3.1.0 · arrival 1,64 ns · slack 8,24 ns
  └───────┬────────┘
  ┌───────▼────────┐
  │ Công suất(ướclg)│ ✅      5,41e-05 W (tuần tự 74,4 % · tổ hợp 25,6 %)
  └───────┬────────┘
  ┌───────▼────────┐
  │ Mô phỏng gate  │ ⬜ CHƯA CHẠY  ⚠️ testbench hiện tại KHÔNG dùng lại được
  │                │               (dùng tên phân cấp `dut.count`) — corner_cases §6
  └───────┬────────┘
  ┌───────▼────────┐
  │ Floorplan      │ ⬜ CHƯA CHẠY   cần PDK sky130A + LibreLane
  └───────┬────────┘
  ┌───────▼────────┐
  │ Placement      │ ⬜ CHƯA CHẠY
  └───────┬────────┘
  ┌───────▼────────┐
  │ CTS            │ ⬜ CHƯA CHẠY   ← clock vẫn "ideal", skew = 0
  └───────┬────────┘
  ┌───────▼────────┐
  │ Routing        │ ⬜ CHƯA CHẠY   ← chưa có ký sinh RC
  └───────┬────────┘
  ┌───────▼────────┐
  │ STA sau routing│ ⬜ CHƯA CHẠY   ← chỉ ở đây mới trả lời được câu "bao nhiêu MHz"
  └───────┬────────┘                  của Charter mục 2 câu 3
  ┌───────▼────────┐
  │ DRC / LVS      │ ⬜ CHƯA CHẠY
  └───────┬────────┘
  ┌───────▼────────┐
  │ GDSII          │ ⬜ CHƯA CHẠY
  └───────┬────────┘
  ┌───────▼────────┐
  │ Sign-off       │ ⬛ NGOÀI PHẠM VI  Charter mục 3
  └───────┬────────┘
  ┌───────▼────────┐
  │ Tape-out · chế │ ⬛ NGOÀI PHẠM VI  Charter mục 3
  │ tạo · đo sau CT│
  └────────────────┘
```

**Lưu ý đọc sơ đồ:** bước “STA sau routing” bị bỏ trống chính là lý do câu hỏi số 3 của
Charter mục 2 (*“Bộ đếm chạy được tối đa bao nhiêu MHz, và con số đó lấy ở đâu ra?”*)
**chưa trả lời được bằng số**. Con số duy nhất đang có — slack 8,24 ns ở chu kỳ giả định
10 ns — là **sau tổng hợp**, clock lý tưởng, một góc PVT, không ký sinh RC. Xem
`implementation-notes_D01.md` §7 câu 3.

---

*Phiên bản: v1.0 · Ngày: 2026-09-24*
