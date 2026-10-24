# D01 · Máy trạng thái (FSM)

---

## 1. D01 có FSM không? — Có, và đây là loại FSM “bộ đếm có điều kiện”

Trong `d01_core.sv` **không có** `case`, không có `typedef enum`, không có biến tên `state`.
Nhưng D01 **có** FSM theo đúng định nghĩa hình thức, và nó khác với C06 ở một điểm quan
trọng.

| Thành phần FSM | Hiện thân trong RTL | Bằng chứng |
|---|---|---|
| **Biến trạng thái** | `count[7:0]` | 8 `dfxtp_1`, netlist `_82_`…`_89_` |
| **Tập trạng thái** | `{S0, S1, …, S255}` — đúng **256** trạng thái | Thanh ghi 8 bit, mọi mã hợp lệ |
| **Hàm chuyển** | Phụ thuộc `rst_n`, `enable`, `up` — **bốn** hành vi khác nhau | dòng 8–15 |
| **Hàm ra** | `count` **chính là** trạng thái — đầu ra Moore tầm thường | dòng 5 |

**Bằng chứng cấu trúc quyết định** (quy tắc kiểm 30 giây): `Q` của các flip-flop có quay
ngược về đường `D` không?

```verilog
// netlist.v — count[4] là đầu vào của cổng tổ hợp sinh ra D của count[7]
sky130_fd_sc_hd__nor2_1  _65_ ( .A(count[4]), .B(up),    .Y(_27_) );
sky130_fd_sc_hd__nor4b_1 _77_ ( .A(count[6]), .B(count[5]), .C(_22_), .D_N(_27_), .Y(_37_) );
sky130_fd_sc_hd__xnor2_1 _80_ ( .A(count[7]), .B(_39_),  .Y(_40_) );
sky130_fd_sc_hd__and2_0  _81_ ( .A(rst_n),    .B(_40_),  .X(_07_) );
sky130_fd_sc_hd__dfxtp_1 _89_ ( .CLK(clk), .D(_07_), .Q(count[7]) );
```

`count[4]`, `count[5]`, `count[6]`, `count[7]` — tất cả đều là `Q` của flip-flop — xuất hiện
làm **đầu vào** của các cổng sinh ra `D` của `count[7]`. **Vòng hồi tiếp có thật ⇒ trạng
thái có thật ⇒ FSM có thật.**

So sánh nội bộ trong cùng bộ hồ sơ:

| Đề | `Q` có quay về `D` không? | Kết luận |
|---|:-:|---|
| **D01** | ✅ (`count[k]` xuất hiện trong cụm logic của `D`) | **Có FSM** |
| **C06** | ✅ (`window_count[k]` tương tự) | **Có FSM** |
| **C07** | ❌ (`disagree` chỉ đi ra cổng ra) | **Không có FSM** — chỉ là thanh ghi đường ống |

## 2. Khác biệt với FSM của C06 — có điều kiện hay vô điều kiện

Cả C06 và D01 đều dùng **bộ đếm làm FSM**. Nhưng:

| | **C06** | **D01** |
|---|---|---|
| Số trạng thái | 256 | 256 |
| Số cung ra từ mỗi trạng thái | **1** (vô điều kiện) | **3** (`giữ` / `+1` / `−1`) + cung reset |
| Đầu vào có ảnh hưởng đường đi không? | **Không** — `sample_in` không xuất hiện trên bất kỳ cung nào | **Có** — `enable` và `up` quyết định cung nào được đi |
| Đồ thị | Một vòng tròn đơn | **Vòng tròn hai chiều + tự vòng tại mỗi nút** |
| Hệ quả | Thời điểm chốt tiên đoán được tuyệt đối | Quỹ đạo phụ thuộc hoàn toàn vào tầng ngoài |

Nói cách khác: FSM của C06 là **đồng hồ**, FSM của D01 là **bộ nhớ có phép cộng**.

## 3. Sơ đồ trạng thái

Không thể vẽ 256 nút, nên vẽ dạng nén với đầy đủ các loại cung:

```
                 ┌──────────────── rst_n = 0 (đồng bộ) — từ MỌI trạng thái ───────────┐
                 │                                                                     │
                 ▼                                                                     │
           ╔═══════════╗    en·up     ╔═══════════╗    en·up     ╔═══════════╗        │
    ══════▶║    S0     ║─────────────▶║    S1     ║─────────────▶║    S2     ║─▶ ...  │
  (sau     ║ count = 0 ║◀─────────────║ count = 1 ║◀─────────────║ count = 2 ║        │
   reset)  ╚═════╤═════╝    en·up̄     ╚═════╤═════╝    en·up̄     ╚═════╤═════╝        │
                 │ ↺ ēn                     │ ↺ ēn                     │ ↺ ēn          │
                 │                          │                          │               │
                 │                          ...                        │               │
                 │                                                     │               │
                 │              ╔═══════════╗    en·up   ╔═══════════╗ │               │
                 │              ║   S254    ║───────────▶║   S255    ║◀┘               │
                 │              ║count = 254║◀───────────║count = 255║                 │
                 │              ╚═══════════╝    en·up̄   ╚═════╤═════╝                 │
                 │                                    ↺ ēn     │                       │
                 │                                             │ en·up  (QUẤN VÒNG TRÊN)│
                 │◀────────────────────────────────────────────┘                       │
                 │                                                                     │
                 └──▶ en·up̄ (QUẤN VÒNG DƯỚI) ──────────────────────────▶ S255          │
                                                                                        │
                 └────────────────────────────────────────────────────────────────────┘

  Chú thích:  en·up  = enable=1, up=1  (tiến)
              en·up̄  = enable=1, up=0  (lùi)
              ↺ ēn   = enable=0        (tự vòng — GIỮ)
              Mọi trạng thái đều có cung reset về S0.
```

**Ba loại cung, và mỗi loại ứng với một hàng của bảng hành vi:**

| Loại cung | Điều kiện | Số cung trong toàn đồ thị |
|---|---|---:|
| Tiến (`S_k → S_(k+1 mod 256)`) | `rst_n=1, enable=1, up=1` | 256 |
| Lùi (`S_k → S_(k−1 mod 256)`) | `rst_n=1, enable=1, up=0` | 256 |
| Tự vòng (`S_k → S_k`) | `rst_n=1, enable=0` | 256 |
| Reset (`S_k → S_0`) | `rst_n=0` | 256 |

Tổng **1024 cung** — đúng bằng số trạng thái mà mô hình Python quét vét cạn
(`reference_model.py` dòng 14–19: 256 giá trị × 2 `enable` × 2 `up` = 1024). **Mô hình chuẩn
Python phủ 100 % đồ thị trạng thái** (trừ các cung reset, được kiểm riêng ở dòng 8).

Đây là một điểm mạnh đáng nêu: với D01, việc “kiểm vét cạn FSM” là khả thi và **đã được
làm** — ở mức mô hình. Mức RTL thì chưa (testbench chỉ đi 17 cung; ca TC-B4 ở
`corner_cases.md` §4 đề xuất quét đủ 256).

## 4. Bảng chuyển trạng thái

| Trạng thái hiện tại | `rst_n` | `enable` | `up` | Trạng thái kế | Loại cung |
|---|:-:|:-:|:-:|---|---|
| `S_k` (bất kỳ) | **0** | × | × | `S0` | Reset |
| `S_k` | 1 | **0** | × | `S_k` | Tự vòng (giữ) |
| `S_k`, k < 255 | 1 | 1 | **1** | `S_(k+1)` | Tiến |
| **`S255`** | 1 | 1 | **1** | **`S0`** | Tiến — **quấn vòng trên** |
| `S_k`, k > 0 | 1 | 1 | **0** | `S_(k−1)` | Lùi |
| **`S0`** | 1 | 1 | **0** | **`S255`** | Lùi — **quấn vòng dưới** |

Hai hàng in đậm là hai ca biên bắt buộc của Charter mục 8, và cả hai **đã được kiểm**
(testbench dòng 17, 18 — xem `corner_cases.md` §1).

## 5. Mealy hay Moore

**Moore, và ở dạng tầm thường nhất:** đầu ra `count` **chính là** thanh ghi trạng thái.

Chứng minh từ mã: `output logic [7:0] count` được gán **trực tiếp** trong `always_ff`; không
có `always_comb` nào sinh ra đầu ra từ tổ hợp (trạng thái, đầu vào). Bằng chứng netlist:
mạng `count[k]` nối thẳng từ `.Q()` của flip-flop ra cổng ra, không qua cổng nào.

Hệ quả thực tế:

| Tính chất | Vì là Moore thuần |
|---|---|
| `count` **không bao giờ có glitch** | Nó là `Q` của flip-flop, không có logic tổ hợp giữa FF và cổng ra |
| `count` ổn định suốt cả chu kỳ | Tầng ngoài đọc lúc nào cũng được, không cần canh cạnh |
| Không có đường tổ hợp nào xuyên qua khối | Đường `in → out` không tồn tại; mọi đường đều kết thúc ở flip-flop |
| Trả giá | Không có — với bộ đếm, Moore là lựa chọn duy nhất hợp lý |

## 6. Mã hoá trạng thái và trạng thái bất hợp lệ

| Câu hỏi | Trả lời cho D01 |
|---|---|
| Kiểu mã hoá | **Nhị phân liên tiếp (binary / counter encoding)** — `S_k` mã là `k` |
| Số bit | 8 |
| Số mã dùng | **256 / 256 = 100 %** |
| **Có trạng thái bất hợp lệ không?** | **KHÔNG có mã nào thừa.** Mọi tổ hợp 8 bit đều là trạng thái hợp lệ và đều đạt tới được |
| Nếu một bit bị lật (SEU, nhiễu, X)? | FSM **không treo** — nó vẫn đếm tiếp bình thường từ giá trị mới. Nhưng **giá trị đếm sai vĩnh viễn** cho tới lần reset kế tiếp |
| Có cần nhánh `default` chống treo không? | **Không** — không có mã chết |

> ⚠️ **Nhưng ứng xử với lỗi của D01 tệ hơn C06 nhiều, dù cả hai đều “không treo”.**
>
> | | C06 (`window_count`) | **D01 (`count`)** |
> |---|---|---|
> | Sau khi một bit bị lật | Chỉ **lệch pha** cửa sổ; máy tự phục hồi trong ≤ 256 chu kỳ | **Giá trị đếm sai vĩnh viễn** cho tới lần reset |
> | Vì sao khác nhau | Ở C06, trạng thái chỉ dùng để **đo thời gian**, và mọi trạng thái đều dẫn tới `S255` | Ở D01, trạng thái **chính là dữ liệu người dùng** |
>
> Bài học: *“FSM không có mã bất hợp lệ” không đồng nghĩa với “FSM chịu lỗi tốt”.* Phải hỏi
> thêm: trạng thái mang **thông tin điều khiển** hay mang **dữ liệu**? Với D01, đó là dữ
> liệu, nên nó không có khả năng tự sửa.

## 7. Khử `X` lúc cấp nguồn

Netlist dùng `sky130_fd_sc_hd__dfxtp_1` — **không có chân reset**. Lúc cấp nguồn, cả 8 FF
là `X`.

Một cạnh clock với `rst_n = 0` có đủ xoá không? **Có**, và lập luận dựa vào cấu trúc chứ
không vào cảm giác: khi `rst_n = 0`, RTL gán hằng `0` cho `count` (dòng 9), nên trình tổng
hợp đặt `rst_n` làm cổng chặn trên đường `D` của **mọi** FF. Bằng chứng netlist trực tiếp:

```verilog
sky130_fd_sc_hd__and2_0 _81_ ( .A(rst_n), .B(_40_), .X(_07_) );   // D của count[7]
sky130_fd_sc_hd__and2_0 _44_ ( .A(rst_n), .B(_10_), .X(_00_) );   // D của count[0]
// … 7 cell and2_0 tổng cộng, cộng 1 cell lpflow_isobufsrc_1 cho bit 1
```

Khi `rst_n = 0`, đầu ra của `and2_0` là hằng `0` bất kể `_40_` đang là `X`. Sau một cạnh
lên, `Q = 0` cho cả 8 FF. ✅

**Điều kiện để lập luận còn đúng:** mọi thanh ghi phải được gán trong nhánh `if (!rst_n)`.
Với D01 hiện tại chỉ có một thanh ghi nên không thể sót. Khi thêm `load` hoặc cờ tràn, điều
kiện này phải được kiểm lại — ca kiểm tương ứng ở `corner_cases.md` §6 (**chưa chạy**).

## 8. FSM sẽ thay đổi thế nào khi thêm `load`

Thêm `load` **không** làm tăng số trạng thái (vẫn 256) và **không** tốn thêm flip-flop.
Nó chỉ thêm một **loại cung mới**:

| Loại cung mới | Điều kiện | Đích | Số cung thêm |
|---|---|---|---:|
| Nạp | `rst_n=1, load=1` | `S_(load_val)` — **bất kỳ** trạng thái nào | 256 × 256 = **65 536** |

Đây là khác biệt định tính, không chỉ định lượng: các cung hiện có chỉ nối tới **hàng xóm**
(`k±1`) hoặc về `S0`, còn cung nạp nối **mọi trạng thái tới mọi trạng thái**. Đồ thị trạng
thái chuyển từ “vòng tròn” sang “đồ thị đầy đủ”.

Hệ quả kiểm chứng: số cung nhảy từ 1024 lên hơn 66 000, nên **không thể quét vét cạn nữa**.
Phải chuyển sang chiến lược kiểm theo lớp tương đương (nạp giá trị biên `0x00`, `0xFF`,
`0x7F`, `0x80` và vài giá trị ngẫu nhiên) — xem `corner_cases.md` §4 nhóm B.

---

*Phiên bản: v1.0 · Ngày: 2026-09-24*
