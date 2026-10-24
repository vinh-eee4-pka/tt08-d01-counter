# D01 · Đường dữ liệu (Datapath)

---

## 1. Datapath của D01 là một **vòng kín**

Khác với A01 (dữ liệu chảy một chiều từ cổng vào ra cổng ra) và khác với C07 (cũng một
chiều), D01 có **vòng hồi tiếp**: giá trị `count` quay lại làm đầu vào cho chính phép tính
sinh ra nó.

```
            ┌──────────────────────── vòng hồi tiếp ────────────────────────┐
            │                                                                │
            ▼                                                                │
     ┌─────────────┐   ┌──────────┐   ┌───────────┐   ┌──────────────┐      │
     │ tăng/giảm   │──▶│ mux giữ  │──▶│ chặn xoá  │──▶│  8 × dfxtp_1 │──────┴──▶ count[7:0]
     │ (up)        │   │ (enable) │   │ (rst_n)   │   │              │
     └─────────────┘   └──────────┘   └───────────┘   └──────────────┘
            ▲                                                ▲
            │                                                │
        count[7:0] (Q)                                      clk
```

Vòng hồi tiếp này chính là **định nghĩa** của một mạch tuần tự có trạng thái thật: `Q` của
flip-flop quay về `D` qua logic tổ hợp. So sánh nhanh với C07 cùng bộ hồ sơ — ở đó `Q` của
flip-flop duy nhất **không** quay lại, nên C07 chỉ là mạch tổ hợp có đăng ký đầu ra.

**Hệ quả về timing:** vì có vòng hồi tiếp, D01 có đường **reg→reg** thật (`count → logic →
count`), và đường đó mới là thứ quyết định tần số tối đa. Xem §6.

## 2. Bảng các đường dữ liệu

| Đường | Độ rộng | Từ | Đến | Bản chất |
|---|---:|---|---|---|
| `count[7:0]` (Q) | 8 | 8 flip-flop | **(a)** mạch tăng/giảm, **(b)** mux giữ, **(c)** cổng ra | **Trạng thái** — vừa là dữ liệu vừa là đầu vào của chính mình |
| `up` | 1 | cổng vào (fanout **10**) | **đầu vào dữ liệu** của cây carry | Xem §4 — **không** phải tín hiệu chọn giữa hai mạch |
| `enable` | 1 | cổng vào | chân chọn của mux giữ/đếm | Điều khiển thật |
| `rst_n` | 1 | cổng vào | **cổng chặn sát flip-flop** (7 × `and2_0`) | Điều khiển, ưu tiên cao nhất |
| giá trị tăng/giảm | 8 | mạch tăng/giảm | mux giữ | Trung gian |
| `D[7:0]` | 8 | cổng chặn xoá | chân `D` của 8 flip-flop | Trạng thái kế |
| `clk` | 1 | cổng vào | chân `CLK` của 8 flip-flop | Hạ tầng |
| 🔴 `load_val[7:0]`, `load` | 9 | — | — | **CHƯA TỒN TẠI** (`functional_spec.md` W-1) |

## 3. Đồ thị phụ thuộc trong một chu kỳ

```
  mức 0    count[7:0] (Q của FF, sẵn sàng ngay sau t_ckq)      up      enable     rst_n
              │  │  │  │  │  │  │  │                            │        │         │
              └──┴──┴──┴──┴──┴──┴──┼────────────────────────────┘        │         │
                                    │                                     │         │
  mức 1..2   ┌────────────────────▼─────────────────────┐                │         │
             │  CÂY CARRY/MƯỢN                          │                │         │
             │  gom nhiều bit mỗi tầng (nor4_1, nor4b_1,│                │         │
             │  or4_1, nand4_1 — cell 4 đầu vào)        │                │         │
             └────────────────────┬─────────────────────┘                │         │
                                   │                                      │         │
  mức 3      ┌───────────────────▼──────────────────────────────────────▼──┐      │
             │  MUX GIỮ/ĐẾM   (o21ai_0 × 5)                                │      │
             └───────────────────┬──────────────────────────────────────────┘      │
                                  │                                                 │
  mức 4      ┌───────────────────▼────────────┐                                    │
             │  bit tổng (xnor2_1 / xor2_1)   │                                    │
             └───────────────────┬────────────┘                                    │
                                  │                                                 │
  mức 5      ┌───────────────────▼────────────────────────────────────────────────▼┐
             │  CHẶN XOÁ ĐỒNG BỘ  (and2_0 × 7 + lpflow_isobufsrc_1)                │
             └───────────────────┬─────────────────────────────────────────────────┘
                                  ▼
  mức 6                    D của 8 flip-flop
```

**Độ sâu logic của từng bit:**

| Bit | Hàm kế tiếp | Độ sâu ước tính |
|---|---|---|
| `count[0]` | Chỉ **đảo** (`~count[0]` khi đếm, cả lên lẫn xuống) + mux + chặn xoá | **Nông nhất** — ~3 cell. ⚠️ Ứng viên số 1 cho vi phạm **hold** |
| `count[1..3]` | Cần carry của 1–3 bit thấp | Tăng dần |
| `count[4..6]` | Cần carry của 4–6 bit thấp | — |
| `count[7]` | Cần carry của **7** bit thấp | **Sâu nhất** ⬅ **endpoint tới hạn thật** |

> Tính chất `count[0]` chỉ là phép đảo đúng cho **cả** đếm lên và đếm xuống: `+1` và `−1`
> đều lật bit thấp nhất. Đây là lý do bit 0 của mọi bộ đếm nhị phân là đường ngắn nhất, và
> vì thế là chỗ dễ vi phạm hold nhất khi có clock skew thật.

## 4. `up` là **dữ liệu**, không phải tín hiệu chọn — và đó là lý do D01 rẻ

Đọc RTL, ta thấy hai biểu thức riêng biệt:

```systemverilog
if (up) count <= count + 8'd1;
else    count <= count - 8'd1;
```

Cách đọc ngây thơ: “có **hai** mạch số học, và `up` là mux chọn giữa hai kết quả”. Netlist
nói khác.

**Lập luận toán học:** trong số học modulo 256, `count − 1` ≡ `count + 255` ≡
`count + 8'hFF`. Vậy **cả hai** nhánh đều là “cộng với một hằng số”, chỉ khác giá trị hằng
số: `0x01` và `0xFF`. Hai hằng số này khác nhau ở các bit 1…7 nhưng **giống nhau** ở bit 0
(đều là `1`). Nói cách khác, `up` không cần chọn giữa hai **cây**, nó chỉ cần thay đổi
**giá trị đầu vào** của cùng một cây.

**Bằng chứng trong netlist:** cell đầu tiên trên đường tới hạn là

```verilog
sky130_fd_sc_hd__nor2_1 _65_ ( .A(count[4]), .B(up), .Y(_27_) );
```

`up` đi vào một cổng `nor2_1` **cùng cấp** với `count[4]` — tức nó là một **toán hạng bình
thường**, không phải chân `S` của mux. Nếu `up` là tín hiệu chọn thật, ta sẽ thấy nó ở chân
`S` của 8 cell `mux2i_1`. Netlist chỉ có **2** cell `mux2i_1` trong toàn bộ 49 cell.

**Hệ quả số lượng:** vì không phải dựng hai cây số học rồi ghép mux 8 bit, tổng chỉ còn
**49 cell**. Đối chiếu ngược: nếu quả thật có hai bộ cộng/trừ 8 bit song song cộng một mux
8 bit, con số phải lớn hơn đáng kể — và có lẽ đó là cơ sở cho ước lượng **110–160 cell**
của Charter.

> **Bài học tổng quát:** *đừng suy ra cấu trúc phần cứng từ hình dạng của `if/else` trong
> RTL.* Trình tổng hợp làm việc trên **hàm logic**, không trên cú pháp. Hai nhánh `if/else`
> chia sẻ được bao nhiêu logic là do bản chất toán học của chúng, không do cách viết.

## 5. Dự đoán đường tới hạn **trước khi** xem STA

Lập luận từ RTL: mọi đường `D` đều đi qua ba tầng nối tiếp (carry → mux `enable` → chặn
`rst_n`). Bit nào cần carry của nhiều bit thấp nhất thì sâu nhất ⇒ **`count[7]`**.

Về startpoint, có hai ứng viên:
- `count[0]` — bắt đầu chuỗi carry (đường **reg→reg**).
- `up` — đi vào cây carry ngay tầng đầu (đường **in→reg**, và bị cộng thêm
  `set_input_delay = 1,0 ns`).

Vì SDC đặt `set_input_delay 1.0`, đường xuất phát từ cổng vào **khởi điểm muộn hơn** đường
xuất phát từ flip-flop (vốn chỉ chịu `t_ckq`). Nên dự đoán: **startpoint là một cổng vào,
nhiều khả năng là `up`** (nó có fanout lớn nhất trong ba tín hiệu điều khiển).

Dự đoán đầy đủ: **`up → count[7]`, khoảng 5–8 cell.**

## 6. Đối chiếu với STA thật

| Đại lượng | Đo được | Dự đoán §5 |
|---|---|---|
| Startpoint | **`up`** (fanout 10) | ✅ đúng |
| Endpoint | `_89_` = **`count[7]`** | ✅ đúng |
| Số cell | **6** (5 logic + 1 FF) | ✅ trong khoảng, thậm chí nông hơn dự đoán |
| Data arrival | **1,64 ns** | — |
| Data required | **9,88 ns** (= 10,00 − 0,12 setup) | — |
| Slack | **8,24 ns** (MET) · WNS/TNS 0,00 | — |
| Đường thứ hai trong báo cáo | `up → _88_` (= `count[6]`) | Cùng họ — xác nhận |

**Ba điều chỉ STA mới nói được:**

**(a) Logic thật chỉ tốn 0,64 ns.** Trong 1,64 ns arrival có **1,00 ns là
`set_input_delay`** — một **giả định** trong `design.sdc`, không phải độ trễ mạch. Phần do
D01 gây ra là **1,64 − 1,00 = 0,64 ns**. Báo “D01 mất 1,64 ns” mà không nói câu này là báo
sai **156 %**.

**(b) Chuỗi carry 8 bit chỉ còn 2 tầng logic.** Đây là phát hiện cấu trúc đáng giá nhất của
D01:

```
  Ripple "sách giáo khoa":   c1 → c2 → c3 → c4 → c5 → c6 → c7    (7 tầng nối tiếp)

  Thực tế abc dựng:          _65_ (nor2, gom count[4] & up)
                                ↓
                             _77_ (nor4b, gom count[6], count[5], _22_, _27_)
                                ↓                    ▲
                             ... tới bit tổng     GOM 4 TÍN HIỆU TRONG 1 CELL
                                                  → 2 tầng thay vì 7
```

Vì carry vào bit `k` của phép `+1` là **hàm AND thuần** của các bit thấp
(`c_k = x[0] AND x[1] AND … AND x[k−1]`), nó gom được thành cây: một cell 4 đầu vào
(`nor4_1`, `nor4b_1`, `or4_1`, `nand4_1` — netlist có tổng cộng **8** cell loại này) xử lý
4 bit cùng lúc. So sánh trực tiếp với **A01** trong cùng bộ hồ sơ: ở đó RTL mô tả
ripple-carry **tường minh** nên công cụ buộc phải giữ 8 tầng nối tiếp; ở D01, RTL dùng toán
tử `+`/`-` nên công cụ **được tự do** và nó chọn cây.

> **Phát biểu đáng nhớ:** *mô tả hành vi (`+`, `-`) cho trình tổng hợp quyền chọn cấu trúc;
> mô tả cấu trúc tường minh (chuỗi full adder) thì tước quyền đó.* Đề A01 cố ý tước (vì tên
> đề chỉ định “ripple-carry”), đề D01 cố ý không tước. Hai đề dạy hai mặt của cùng một
> nguyên lý, và STA là nơi thấy được khác biệt bằng số.

**(c) Đường reg→reg không xuất hiện trong top paths — và điều đó KHÔNG có nghĩa nó an
toàn.** Cả hai đường đầu bảng đều là in→reg từ `up`. Lý do duy nhất: `set_input_delay` 1,00 ns
lớn hơn `t_ckq` của một flip-flop. Nếu tầng ngoài đưa `up` tới sớm hơn (input delay nhỏ),
đường reg→reg `count[k] → count[7]` sẽ leo lên đầu bảng. Đường reg→reg đó dùng **gần như
cùng cụm cell** (`_65_` nhận `count[4]`, `_77_` nhận `count[5]`, `count[6]`, `_80_` nhận
`count[7]`), nên độ trễ logic của nó cũng cỡ 0,6 ns.

**Vì thế: không được kết luận “đường reg→reg của D01 nhanh” từ báo cáo này**, và càng không
được suy ra tần số tối đa từ slack 8,24 ns — xem `implementation-notes_D01.md` §7 câu 3.

## 7. Cơ hội tối ưu và mở rộng — chỉ để thảo luận

Với slack **8,24 ns** trên 10 ns và logic chỉ **0,64 ns**, D01 là thiết kế **dư thừa rất
nhiều** về timing. Không có nhu cầu tối ưu tốc độ.

Ngược lại, có chỗ đáng dùng phần dư đó:

| Hướng | Chi phí đường tới hạn | Chi phí ô nhớ | Ghi chú |
|---|---|---|---|
| **Thêm mux nạp** (`load`, `load_val`) — W-1 | +1 tầng mux 8 bit trên đường `D` | **+0 FF** | Với 8,24 ns slack, thêm một tầng mux gần như chắc chắn vẫn thoả — nhưng phải chạy STA mới kết luận. ⬜ **chưa chạy** |
| Thêm cờ tràn (W-4) | Cần thêm logic phát hiện `FF → 00` / `00 → FF` | **+1…2 FF** | Charter mục 10 gợi ý; mục 4 không cấp chân ra |
| Mở rộng lên 16 bit | Cây carry sâu thêm ~1 tầng (log₄) | +8 FF | Cây gom 4 bit/tầng nên độ sâu tăng rất chậm theo độ rộng |
| Đổi sang reset **bất đồng bộ** | **−1 cell** khỏi đường `D` (bỏ `and2_0`, ≈ −0,13 ns) | 0 | Đổi lại phải kiểm recovery/removal; xem `tradeoff.md` §3 |

---

*Phiên bản: v1.0 · Ngày: 2026-09-24*
