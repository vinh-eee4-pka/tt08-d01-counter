# D01 · Giản đồ thời gian (Timing Diagram)

---

## 0. Quy ước đọc giản đồ

- **Cạnh `n`** = cạnh lên thứ `n` của `clk` tính từ đầu mô phỏng.
- Hàng **“trước cạnh n”** = giá trị điều khiển ổn định ngay trước cạnh — đây là giá trị
  flip-flop **thực sự lấy mẫu**.
- Hàng **“sau cạnh n”** = giá trị `Q` sau cạnh đó.
- Testbench dùng `always #5 clk = ~clk` ⇒ chu kỳ **10 đơn vị**, cạnh lên thứ `n` tại thời
  điểm `5 + 10(n−1)`. `$finish` tại `166` ⇒ đúng **17 cạnh lên**.

> ⚠️ **Waveform thu từ mô phỏng hành vi (zero-delay) bằng Icarus Verilog 12.0.** Tín hiệu
> đổi giá trị đúng tại cạnh clock; không có `t_ckq`, không có độ trễ cổng, không có glitch.
> Nó chứng minh **giá trị và số chu kỳ**, và **không** chứng minh gì về độ trễ thật — xem §4.

---

## 1. Toàn bộ giao dịch của testbench — 17 cạnh clock

Lấy **đúng từ** `d01_core_tb.sv`. Năm giai đoạn được đánh dấu bên dưới.

```
 Cạnh số:        1      2  ║   3      4  ║   5      6      7      8      9  ║  10     11     12
 thời điểm:      5     15  ║  25     35  ║  45     55     65     75     85  ║  95    105    115
 clk        ─────↑──────↑──╫───↑──────↑──╫───↑──────↑──────↑──────↑──────↑──╫───↑──────↑──────↑──

 rst_n (trước)   0      0  ║   1      1  ║   1      1      1      1      1  ║   1      1      1
 enable(trước)   0      0  ║   0      0  ║   1      1      1      1      1  ║   1      1      1
 up    (trước)   1      1  ║   1      1  ║   1      1      1      1      1  ║   0      0      0
 ──────────────────────────╫─────────────╫───────────────────────────────────╫──────────────────
 count (sau)    00     00  ║  00     00  ║  01     02     03     04     05  ║  04     03     02
                           ║             ║                                   ║
            ┌── XOÁ ĐB ───┐║┌── GIỮ ────┐║┌────── ĐẾM LÊN 5 nhịp ──────────┐║┌─ ĐẾM XUỐNG 3 ─┐
            │ rst_n = 0   │║│ enable = 0│║│ enable=1, up=1                  │║│ up = 0         │
            │ count ← 0   │║│ count giữ │║│ +1 mỗi cạnh                     │║│ −1 mỗi cạnh    │
            └─────────────┘║└───────────┘║└─────────────────────────────────┘║└────────────────┘
```

```
                         ╔═ nạp cưỡng bức count = FE ═╗       ╔═ nạp cưỡng bức count = 01 ═╗
 Cạnh số:               ║ 13           14             ║      ║ 15           16             ║  17
 thời điểm:             ║125          135             ║      ║145          155             ║ 165
 clk        ────────────╫──↑────────────↑─────────────╫──────╫──↑────────────↑─────────────╫──↑──

 rst_n (trước)          ║  1            1             ║      ║  1            1             ║  0  ◀──
 enable(trước)          ║  1            1             ║      ║  1            1             ║  1
 up    (trước)          ║  1            1             ║      ║  0            0             ║  1
 ───────────────────────╫─────────────────────────────╫──────╫─────────────────────────────╫─────
 count (trước cạnh)     ║ FE           FF             ║      ║ 01           00             ║  FF
 count (sau cạnh)       ║ FF        ⟦ 00 ⟧            ║      ║ 00        ⟦ FF ⟧            ║⟦00⟧
                        ║            ▲                ║      ║            ▲                ║  ▲
                        ║      TRÀN TRÊN              ║      ║      TRÀN DƯỚI              ║  │
                        ║      carry lan hết 8 tầng   ║      ║      mượn lan hết 8 tầng    ║  │
                        ╚═════════════════════════════╝      ╚═════════════════════════════╝  │
                                                                                               │
                                                        XOÁ ĐỒNG BỘ THẮNG enable=1 và up=1 ────┘
```

## 2. Năm mốc đáng đọc kỹ

| Mốc | Xảy ra gì | Ý nghĩa |
|---|---|---|
| **Cạnh 1–2** | `rst_n = 0` → `count = 00` ngay từ cạnh **đầu tiên** | Testbench gọi `check()` **trong** lúc còn reset, không chỉ sau đó. Bắt lỗi “reset cần hai chu kỳ mới có tác dụng” |
| **Cạnh 3–4** | `rst_n = 1` nhưng `enable = 0` → `count` **không đổi**, vẫn `00` | Chứng minh `enable` chặn được đếm. Lưu ý `up` vẫn là `1` suốt giai đoạn này — nếu `up` lọt qua `enable`, `count` đã tăng |
| **Cạnh 13–14** ⟦⟧ | `FE → FF → 00` | **Tràn trên.** Cạnh 14 là chuyển tiếp mà carry phải lan qua **cả 8 tầng** — chuyển tiếp tốn thời gian nhất và tốn công suất nhất của cả bài test |
| **Cạnh 15–16** ⟦⟧ | `01 → 00 → FF` | **Tràn dưới.** Cạnh 16 là chuyển tiếp mượn lan hết 8 tầng. Chú ý: đây là **mạch khác** với chuỗi carry ở cạnh 14 — dùng cùng cây nhưng với hằng số `0xFF` thay vì `0x01` (`datapath.md` §4) |
| **Cạnh 17** ⟦⟧ | `enable = 1`, `up = 1`, **`rst_n = 0`** → `count = 00` | **Ca ưu tiên.** Một cạnh clock chứng minh `rst_n > enable > up`. Nếu ưu tiên bị viết ngược, `count` sẽ là `00` (từ `FF + 1`) — **trùng với kết quả đúng một cách tình cờ!** Xem cảnh báo ở §3 |

## 3. ⚠️ Một điểm yếu tinh tế của ca ưu tiên ở cạnh 17

Trước cạnh 17, `count = FF`. Testbench đặt `enable=1, up=1, rst_n=0` và kỳ vọng `count = 00`.

Nhưng nếu ai đó viết ưu tiên **sai** — đặt `enable` lên trước `rst_n` — thì mạch sẽ đếm lên
thay vì xoá, cho `FF + 1 = 00`. **Cùng một kết quả.** Ca kiểm thử này **không phân biệt
được** hai hành vi, vì nó vô tình chạy ở đúng giá trị mà hai nhánh trùng nhau.

Đây là loại lỗ hổng rất khó thấy khi đọc testbench, và nó minh hoạ một nguyên tắc: **một ca
kiểm thử chỉ có giá trị khi hai hành vi cần phân biệt cho hai kết quả khác nhau.**

**Cách sửa (ca TC-B5 ở `corner_cases.md` §4):** đặt `count` về một giá trị khác `FF` trước
khi kiểm ưu tiên — ví dụ `0xA5`. Khi đó nhánh đúng cho `00`, nhánh sai cho `A6`, phân biệt
được rõ ràng. Thêm hai dòng vào testbench:

```systemverilog
dut.count = 8'hA5;  ref_i.count_ref = 8'hA5;
enable = 1;  up = 1;  rst_n = 0;  check();    // phải ra 00, không phải A6
```

Ca này **chưa chạy**. Ghi nhận lại: mô phỏng hiện tại PASS, nhưng riêng khẳng định về **ưu
tiên** thì bằng chứng còn yếu.

## 4. Giản đồ này chứng minh gì và **không** chứng minh gì

| Câu hỏi | Waveform hành vi trả lời được? | Cần gì để trả lời |
|---|:-:|---|
| Đếm lên đúng không? | ✅ (cạnh 5–9) | — |
| Đếm xuống đúng không? | ✅ (cạnh 10–12) | — |
| Quấn vòng trên `FF → 00`? | ✅ (cạnh 14) | — |
| Quấn vòng dưới `00 → FF`? | ✅ (cạnh 16) | — |
| `enable = 0` có giữ được không? | ✅ (cạnh 3–4) | — |
| `rst_n` thắng `enable`? | 🟡 **yếu** — xem §3 | Ca TC-B5 với `count = 0xA5` |
| **Xoá là ĐỒNG BỘ hay BẤT ĐỒNG BỘ?** | ❌ — waveform này **không phân biệt được**, vì `rst_n` luôn xuống trùng lúc có clock | Ca **TC-B6**: hạ `rst_n` trong lúc clock **đứng yên**, rồi kiểm `count` **không** đổi. Hoặc đọc netlist (`block_diagram.md` §3) |
| **Có bao nhiêu MHz?** | ❌ | STA **sau routing**, nhiều góc PVT — chưa chạy |
| Dữ liệu có kịp trước cạnh clock? | ❌ | STA: arrival **1,64 ns** vs required **9,88 ns** → slack **8,24 ns** |
| Có vi phạm hold ở `count[0]` không? | ❌ | `timing_report_min.txt` + SDF sau CTS |
| `X` lúc cấp nguồn có bị xoá? | ❌ | Mô phỏng `netlist.v` với FF khởi tạo `X` |

**Nối hai thế giới.** Trong waveform, cạnh 14 (`FF → 00`) là một cột sạch sẽ. Trong thực
tế, đó là lúc **cả 8 bit cùng lật** và carry phải lan qua toàn bộ cây — chuyển tiếp nặng
nhất về cả thời gian lẫn công suất động.

Con số STA tương ứng: đường `up → count[7]` dài **6 cell**, arrival **1,64 ns**, trong đó
**1,00 ns là `set_input_delay` giả định** — phần do mạch gây ra chỉ **0,64 ns**. Với chu kỳ
giả định 10 ns và `library setup time` 0,12 ns, thời gian yêu cầu là 9,88 ns → slack
**8,24 ns**.

Lưu ý quan trọng: **đường tới hạn báo cáo là in→reg (từ `up`), không phải reg→reg.** Đường
reg→reg (`count[k] → count[7]`) dùng gần như cùng cụm cell nhưng không bị cộng 1,00 ns
input delay, nên nó **không xuất hiện** trong top paths. Điều đó **không** có nghĩa nó an
toàn — nó chỉ có nghĩa là với `set_input_delay = 1,0 ns`, đường in→reg đang nặng hơn. Chi
tiết ở `datapath.md` §6.

## 5. Ghi chú về cách viết testbench

| Chi tiết | Nhận xét |
|---|---|
| **Nạp cưỡng bức qua tên phân cấp** (`dut.count = 8'hFE`) | Kỹ thuật tốt để tới biên tràn trong 0 chu kỳ thay vì 254 nhịp. **Nhưng testbench này không chạy được trên netlist** — sau tổng hợp không còn biến `count`, chỉ có 8 instance `_82_`…`_89_`. Xem `corner_cases.md` §2.1 và §6 |
| **Ghi cho cả DUT và mô hình chuẩn** | Bắt buộc. Quên một trong hai thì hai mô hình lệch pha và assertion báo sai ở nhịp kế |
| **Mô hình chuẩn viết ngược thứ tự điều kiện** | `d01_reference.sv` viết `else if (!enable) count_ref <= count_ref;` — ngược với RTL. Cố ý: giảm rủi ro hai mô hình **cùng sai** theo cùng một cách nghĩ (*diverse redundancy*) |
| Đổi tên instance `ref` → `ref_i` | Bắt buộc: `ref` là **từ khoá SystemVerilog** (đối số truyền tham chiếu), Icarus từ chối biên dịch. Xem BRIEF D01, mục “Sửa nguồn tối thiểu” (4 chỗ) |

---

*Phiên bản: v1.0 · Ngày: 2026-09-24*
