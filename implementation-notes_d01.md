# D01 — Bộ đếm nhị phân 8-bit đa năng · Ghi chú thực hiện

> ⚠️ **Đọc trước:** RTL trong hồ sơ hiện thực **ba trong bốn** chức năng của một bộ đếm
> “đa năng”: đếm lên/xuống ✅, cho phép ✅, xoá ✅, **nạp song song ❌**. Danh sách đầy đủ
> 6 điểm CHƯA THOẢ ở `02_SPECIFICATION/functional_spec.md` §0. RTL **không bị sửa**.

---

## 1. Bài toán này thực chất là gì

Bộ đếm là **khối tuần tự đơn giản nhất còn có ý nghĩa**, và chính vì thế nó là đề mẫu tốt
nhất để luyện một kỹ năng cụ thể: **đọc số ô nhớ trong báo cáo và giải thích được từng ô**.
Charter mục 10 nói thẳng điều đó — *“Đề mẫu để luyện đếm ô nhớ.”*

Nhìn từ góc lý thuyết, D01 là một **máy trạng thái 256 trạng thái mà trạng thái chính là
dữ liệu người dùng**. Điều này phân biệt nó với C06 trong cùng bộ hồ sơ: ở C06,
`window_count` cũng là bộ đếm 8 bit 256 trạng thái, nhưng ở đó trạng thái chỉ dùng để **đo
thời gian**, còn dữ liệu nằm chỗ khác. Hệ quả rất thực tế: nếu một bit của C06 bị lật, máy
**tự phục hồi** trong ≤ 256 chu kỳ; nếu một bit của D01 bị lật, **giá trị sai vĩnh viễn**
cho tới lần reset. Cùng một cấu trúc, hai đặc tính chịu lỗi khác hẳn nhau.

Từ góc ứng dụng (Charter mục 1: đếm sản phẩm trên băng chuyền, nạp giá trị đầu rồi đếm
ngược để báo còn bao nhiêu suất), bài toán đòi **bốn** chế độ: nạp, đếm lên, đếm xuống,
giữ — cộng xoá. Chữ **“đa năng”** trong tên đề chính là bốn chế độ đó. RTL hiện có ba.

Cái khó thật của đề không phải phép cộng, mà là **thứ tự ưu tiên giữa các chế độ**. Charter
mục 10 nêu đúng: *“Ưu tiên giữa nạp / xoá / đếm không rõ ràng → hành vi khác nhau giữa mô
phỏng và tổng hợp.”*

## 2. Bản chất kỹ thuật — cơ chế hoạt động

### 2.1 Ba tầng chọn xếp chồng — và thứ tự xếp chồng **là** thứ tự ưu tiên

Đường `D` của mỗi flip-flop đi qua ba tầng:

```
  count(Q) ─▶[① tăng/giảm: up]─▶[② mux giữ: enable]─▶[③ chặn xoá: rst_n]─▶ D ─▶ FF ─┐
     ▲                                                                                │
     └────────────────────────── vòng hồi tiếp ───────────────────────────────────────┘
```

Tầng nào **gần flip-flop hơn** thì ưu tiên cao hơn. Đây là cách đọc ưu tiên **từ netlist**,
độc lập với việc tin vào cách đọc `if/else`. STA xác nhận đúng thứ tự đó trên đường tới hạn:
`up` vào tại cell 1 (`_65_`), `enable` vào tại cell 3 (`_79_`), `rst_n` vào tại cell 5
(`_81_`) — ngay sát flip-flop `_89_`.

Vòng hồi tiếp `Q → D` là thứ làm D01 thành mạch tuần tự **thật**. So với C07 trong cùng bộ
hồ sơ, nơi `Q` của flip-flop duy nhất **không** quay lại: C07 chỉ là mạch tổ hợp có đăng ký
đầu ra, còn D01 có trạng thái thật.

### 2.2 Cơ chế đáng ngạc nhiên nhất: `up` **không phải** tín hiệu chọn

Đọc RTL thấy `if (up) count+1; else count-1;` và kết luận tự nhiên là: *có hai mạch số học,
`up` là mux chọn giữa hai kết quả*. **Netlist nói khác.**

Lập luận toán học: trong số học modulo 256, `count − 1 ≡ count + 0xFF`. Vậy **cả hai** nhánh
là “cộng với một hằng số”, chỉ khác giá trị hằng. `up` không cần chọn giữa hai **cây carry**
— nó chỉ cần thay đổi **giá trị đầu vào** của cùng một cây.

Bằng chứng trực tiếp trong netlist — cell đầu tiên trên đường tới hạn:

```verilog
sky130_fd_sc_hd__nor2_1 _65_ ( .A(count[4]), .B(up), .Y(_27_) );
```

`up` đi vào chân `.B` của một `nor2_1`, **ngang hàng** với `count[4]` — tức nó là một toán
hạng dữ liệu bình thường. Nếu `up` thực sự là tín hiệu chọn, ta sẽ thấy nó ở chân `S` của
8 cell `mux2i_1`; netlist chỉ có **2** cell `mux2i_1` trong toàn bộ 49 cell.

**Hệ quả số lượng:** không phải dựng hai cây số học rồi ghép mux 8 bit ⇒ chỉ **49 cell**.
Đây nhiều khả năng là một phần nguyên nhân khiến kết quả thấp hơn hẳn ước lượng 110–160 của
Charter.

> **Bài học tổng quát:** *đừng suy ra cấu trúc phần cứng từ hình dạng `if/else` trong RTL.*
> Trình tổng hợp làm việc trên **hàm logic**, không trên cú pháp.

### 2.3 Cơ chế quan trọng thứ hai: chuỗi carry 8 bit chỉ còn **2 tầng**

Một bộ đếm ripple “sách giáo khoa” có carry lan qua 7–8 tầng nối tiếp. STA thật cho thấy
MSB chỉ cách `up` **5 cell logic**, tổng **0,64 ns**.

Lý do có tính nguyên lý: carry vào bit `k` của phép `+1` là **hàm AND thuần** của các bit
thấp hơn (`c_k = x[0] AND x[1] AND … AND x[k−1]`). Mà AND thì **gom được thành cây**. `abc`
dùng cell 4 đầu vào — netlist có tổng cộng **8** cell loại đó (`nor4_1 × 3`, `nor4b_1`,
`or4_1`, `nand4_1`, …) — mỗi cell xử lý 4 bit cùng lúc, nên độ sâu giảm từ 8 xuống 2.

Ví dụ cụ thể trên đường tới hạn:

```verilog
sky130_fd_sc_hd__nor4b_1 _77_ ( .A(count[6]), .B(count[5]), .C(_22_), .D_N(_27_), .Y(_37_) );
//                                 ▲ gom BỐN tín hiệu trong MỘT cell
```

So sánh trực tiếp với **A01** trong cùng bộ hồ sơ: ở A01, tên đề chỉ định “ripple-carry”
nên RTL mô tả chuỗi full adder **tường minh**, và công cụ buộc phải giữ 8 tầng nối tiếp. Ở
D01, RTL dùng toán tử `+`/`-` nên công cụ **được tự do** — và nó chọn cây.

> *Mô tả hành vi cho trình tổng hợp quyền chọn cấu trúc; mô tả cấu trúc tường minh thì tước
> quyền đó.* Hai đề dạy hai mặt của cùng nguyên lý, và STA là nơi thấy khác biệt bằng số.

## 3. Đọc mã nguồn: RTL làm gì, từng dòng quan trọng

Toàn bộ thiết kế là **20 dòng**. Đoạn quan trọng:

```systemverilog
always_ff @(posedge clk) begin        // ① KHÔNG có `or negedge rst_n`
    if (!rst_n)                        // ② ưu tiên 1
        count <= 8'd0;
    else if (enable) begin             // ③ ưu tiên 2
        if (up)                        // ④ ưu tiên 3
            count <= count + 8'd1;
        else
            count <= count - 8'd1;
    end                                // ⑤ KHÔNG có else cuối → giữ nguyên
end
```

**① Danh sách nhạy chỉ có `posedge clk`** — đây là dòng quyết định rằng reset là **đồng
bộ**. Nếu viết `@(posedge clk or negedge rst_n)`, Yosys sẽ chọn cell `dfrtp_1` có chân
`RESET_B` thay vì `dfxtp_1`. Một từ khoá trong danh sách nhạy đổi hẳn loại cell được dùng.

**② → ③ → ④: `if / else if` lồng nhau trong MỘT khối `always_ff`.** Đây là lý do D01 **miễn
nhiễm** với rủi ro mà Charter mục 10 cảnh báo. Sự khác biệt “mô phỏng ≠ tổng hợp” đến từ ba
thói quen cụ thể mà D01 đều tránh: (a) tách điều kiện ra nhiều khối `always` cùng ghi một
biến; (b) dùng `casex`/`casez` với `X`/`Z`; (c) thiếu nhánh trong `always_comb` → suy ra
latch.

**⑤ Thiếu `else` cuối là HỢP LỆ và ĐÚNG ở đây.** Trong `always_ff`, thiếu nhánh có nghĩa
“flip-flop giữ giá trị cũ” — chính xác là hành vi mong muốn. (Ngược lại, thiếu nhánh trong
`always_comb` sẽ suy ra **latch**, một lỗi thật.) Netlist xác nhận không có latch nào:
`synth_stat.txt` chỉ có `dfxtp_1`.

**Và đây là điều RTL *không* làm:** không nạp, không báo tràn, không đồng bộ tín hiệu vào,
không tách cạnh cho `enable`.

## 4. Vì sao chọn kiến trúc này

| Quyết định | Lý do |
|---|---|
| **Bộ đếm đồng bộ** (một clock cho cả 8 FF) | Bắt buộc với quy trình RTL→GDSII tự động. Bộ đếm ripple (dùng `Q` làm clock) khiến STA không phân tích được, CTS không xử lý được, và các bit lệch pha nên `FF → 00` đi qua các giá trị trung gian **sai** |
| **Mô tả hành vi** (`+`, `-`) thay vì mô tả cấu trúc | Cho `abc` quyền dựng cây carry. Kết quả đo: 5 tầng logic, 0,64 ns cho MSB |
| **Xoá đồng bộ** | Miễn nhiễm với glitch trên `rst_n` (bị flip-flop lọc); không cần kiểm recovery/removal. Giá: +8 cell (16 %) và +0,13 ns (20 % logic) |
| **Ưu tiên `rst_n` > `enable` > `up`** | Reset phải là lối thoát tuyệt đối. Nếu `enable` lên trước, `enable = 0` sẽ chặn được cả reset |
| **Quấn vòng**, không bão hoà | Đặc tả chốt số học modulo 256. Bão hoà là hành vi khác, thuộc đề khác |

## 5. Cách thực hiện — lộ trình 8 bước từ đặc tả tới GDSII

| Bước | Việc | Đầu ra | Trạng thái |
|:-:|---|---|:-:|
| 1 | Lập **bảng hành vi 4 hàng** phủ toàn bộ 8 tổ hợp `(rst_n, enable, up)`; chốt bảng ưu tiên | `functional_spec.md` §3 | ✅ |
| 2 | Viết mô hình chuẩn Python **quét vét cạn** 256 × 2 × 2 = 1024 trạng thái | `reference_model.py` — PASS | ✅ |
| 3 | Viết RTL: một `always_ff`, `if/else if` lồng nhau | `d01_core.sv` (20 dòng) | 🟡 **thiếu chức năng NẠP** |
| 4 | Viết testbench so song song với mô hình chuẩn SV; dùng nạp cưỡng bức để tới biên tràn | `d01_core_tb.sv` — **PASS**, 17 cạnh | 🟡 phủ **4/5** ca bắt buộc |
| 5 | Tổng hợp; **đếm FF và giải thích từng ô** | 49 cell · **8 FF** · 427,9104 µm² | ✅ |
| 6 | SDC + STA; đọc kỹ dòng `input external delay` | arrival 1,64 ns · slack 8,24 ns | ✅ |
| 7 | Ước lượng công suất; đọc tỷ lệ tuần tự/tổ hợp | 5,41e-05 W · tuần tự 74,4 % | ✅ |
| 8 | P&R bằng LibreLane + PDK sky130A, rồi STA **sau routing** | — | ⬜ **CHƯA CHẠY** |

**Bước 5 là mục đích tồn tại của đề này.** Dự đoán từ RTL: 8 FF cho `count`, không có thanh
ghi nào khác ⇒ **8**. Yosys cho **8**. Khớp tuyệt đối. Nếu lệch, hoặc đọc RTL sai, hoặc có
tín hiệu bị suy ra latch — cả hai đều là lỗi đáng tìm.

**Bước 8 chưa chạy là lý do câu hỏi 3 của Charter mục 2 chưa trả lời được** — xem §7.

## 6. Số liệu thật đã đo được và cách đọc chúng

| Chỉ số | Giá trị | Công cụ |
|---|---:|---|
| Mô hình Python (vét cạn 1024 trạng thái) | PASS | CPython 3 |
| Mô phỏng RTL (17 cạnh, so với `d01_reference`) | **PASS** | Icarus Verilog 12.0 |
| Số cell | **49** | Yosys 0.33 |
| Flip-flop | **8** | Yosys 0.33 |
| Diện tích | **427,9104 µm²** | Yosys 0.33 |
| Đường tới hạn | `up` → `_89_` (= `count[7]`), **6 cell** | OpenSTA 3.1.0 |
| Data arrival | **1,64 ns** | OpenSTA 3.1.0 |
| Data required | **9,88 ns** (= 10,00 − 0,12 setup) | OpenSTA 3.1.0 |
| Slack | **8,24 ns** (MET) · WNS/TNS 0,00 | OpenSTA 3.1.0 |
| Công suất | **5,41e-05 W** · tuần tự **74,4 %** · tổ hợp 25,6 % | OpenSTA 3.1.0 |

**Những số này CHỨNG MINH được:** bộ đếm lên/xuống có enable và xoá đồng bộ hoạt động đúng
trên 17 cạnh đã thử, kể cả cả hai biên quấn vòng; nó tổng hợp được thành 49 standard cell
sky130 với **đúng 8** ô nhớ; và với ràng buộc giả định, đường dài nhất còn dư 8,24 ns.

**Những số này KHÔNG chứng minh:**

1. **Không chứng minh khối thoả đề D01.** Thiếu chức năng nạp — mà đó là chữ “đa năng”
   trong tên đề và là bối cảnh ứng dụng của Charter mục 1.
2. **Không chứng minh tần số tối đa.** Chưa ký sinh RC, chưa CTS (skew = 0), một góc PVT.
3. **Không chứng minh đường reg→reg an toàn.** Cả hai đường đầu bảng đều là **in→reg** từ
   `up`, chỉ vì `set_input_delay = 1,0 ns` lớn hơn `t_ckq`. Đường reg→reg không xuất hiện
   trong top paths **không** có nghĩa nó nhanh.
4. **Không chứng minh ưu tiên được kiểm đủ.** Ca ưu tiên ở cạnh 17 chạy khi `count = FF`,
   nơi nhánh đúng (xoá → `00`) và nhánh sai (đếm lên → `FF+1 = 00`) **cho cùng kết quả** —
   xem `timing_diagram.md` §3.
5. **Công suất là ước lượng với hoạt động mặc định**, không phải VCD thật. Với D01, hoạt
   động thật phụ thuộc rất mạnh vào `enable`.

**Chi tiết hay bị báo sai:** trong 1,64 ns arrival có **1,00 ns là `set_input_delay`** —
một giả định trong SDC. Phần do mạch gây ra chỉ **0,64 ns**. Báo “D01 mất 1,64 ns” là báo
sai **156 %**.

## 7. Trả lời các câu hỏi kỹ thuật của Charter (mục 2)

**Câu 1 — Số ô nhớ dự đoán là 8; nếu báo cáo ra nhiều hơn thì phần dư dùng vào việc gì?**

Dự đoán: **8**. Đo được: **8** (`synth_stat.txt`: `sky130_fd_sc_hd__dfxtp_1 8`). **Không có
phần dư.**

Bóc tách bằng tên instance thật trong netlist:

| FF | Instance | `Q` nối tới |
|---|---|---|
| 1 | `_82_` | `count[0]` |
| 2 | `_83_` | `count[1]` |
| 3 | `_84_` | `count[2]` |
| 4 | `_85_` | `count[3]` |
| 5 | `_86_` | `count[4]` |
| 6 | `_87_` | `count[5]` |
| 7 | `_88_` | `count[6]` |
| 8 | `_89_` | `count[7]` |

**Vì sao không có phần dư — và vì sao đó vừa là điểm tốt vừa là điểm thiếu:**

| Thứ có thể tốn thêm FF | Có trong D01? | Ghi chú |
|---|:-:|---|
| Cờ tràn / quấn vòng | ❌ | Charter mục 10 gợi ý “1–2 cho cờ tràn” nhưng mục 4 **không cấp chân ra** cho nó — hai mục của Charter không nhất quán |
| Thanh ghi giữ `load_val` | ❌ | Không cần — nạp chỉ cần mux, **+0 FF** |
| Thanh ghi đồng bộ hoá `enable`/`up` | ❌ | **Nghĩa vụ tầng ngoài** |
| Thanh ghi pipeline đầu ra | ❌ | Không cần |
| Latch do thiếu nhánh trong `always_comb` | ❌ | Không có `always_comb` nào; netlist chỉ có `dfxtp_1` |

Câu hỏi giả định của Charter (*“nếu nhiều hơn 8”*) có ba đáp án thường gặp: cờ tràn, thanh
ghi đồng bộ hoá, và **latch do lỗi mã**. Đáp án thứ ba là quan trọng nhất về mặt dạy học:
nếu báo cáo ra 9–10 FF mà không giải thích được, khả năng cao là có latch bị suy ra ngoài ý
muốn — kiểm bằng cách tìm cell `dlxtp`/`dlatch` trong `synth_stat.txt`.

**Câu 2 — Xoá đồng bộ khác xoá bất đồng bộ ở chỗ nào trong netlist?**

Đây là câu D01 trả lời được bằng bằng chứng cụ thể nhất.

| | **Đồng bộ (D01 đang dùng)** | Bất đồng bộ |
|---|---|---|
| Mã RTL | `@(posedge clk)` + `if (!rst_n)` | `@(posedge clk or negedge rst_n)` |
| **Cell FF được chọn** | **`sky130_fd_sc_hd__dfxtp_1`** — chân `CLK`, `D`, `Q`; **không có chân reset** | `sky130_fd_sc_hd__dfrtp_1` — thêm chân **`RESET_B`** |
| **`rst_n` nằm ở đâu** | **Trong cụm logic tổ hợp trên đường `D`** | **Trên chân `RESET_B`**, không xuất hiện trong cụm `D` |
| Cell tổ hợp thêm | **+8** (7 × `and2_0` + 1 × `lpflow_isobufsrc_1`) ≈ **16 %** của 49 cell | 0 |
| Có trên đường tới hạn không | **Có** — `_81_` cộng **0,13 ns** (≈ 20 % của 0,64 ns logic) | Không |
| Khi clock đứng yên | **KHÔNG xoá được** | Xoá ngay |
| Kiểm timing thêm | Không | **Recovery / removal** |
| Glitch trên `rst_n` | Bị flip-flop **lọc** | Đi thẳng vào FF → reset giả |

Trích netlist làm bằng chứng:

```verilog
sky130_fd_sc_hd__and2_0  _81_ ( .A(rst_n), .B(_40_), .X(_07_) );   // rst_n như DỮ LIỆU
sky130_fd_sc_hd__dfxtp_1 _89_ ( .CLK(clk), .D(_07_), .Q(count[7]) ); // FF không có chân reset
```

**Cách kiểm trong 10 giây:** mở `synth_stat.txt`, xem tên cell tuần tự. `dfxtp_1` (không
hậu tố) ⇒ reset **đồng bộ** hoặc không có reset. `dfrtp_1`/`dfstp_1` ⇒ có chân reset **bất
đồng bộ**. Ở D01 chỉ có `dfxtp_1 × 8`.

**Câu 3 — Bộ đếm chạy được tối đa bao nhiêu MHz, và con số đó lấy ở đâu ra?**

**Đáp án trung thực: KHÔNG lấy được từ dữ liệu hiện có.** Đây là câu hỏi bẫy hay nhất trong
cả bộ hồ sơ, và đáp án đúng là giải thích **vì sao** chưa trả lời được.

Con số duy nhất đang có là slack **8,24 ns** ở chu kỳ giả định **10 ns**. Phép tính ngây thơ
`1 / (10 − 8,24) ns = 568 MHz` **sai** vì ít nhất bốn lý do:

| Lý do | Chi tiết |
|---|---|
| **Sai loại đường** | Đường được báo là **in→reg** (từ `up`), và nó chứa **1,00 ns `set_input_delay` giả định**. Tần số tối đa của một bộ đếm do đường **reg→reg** (`count → count`) quyết định, mà đường đó **không** xuất hiện trong top paths |
| **Clock lý tưởng** | Chưa CTS ⇒ `clock network delay (ideal)`, `skew = 0`. Skew thật sẽ ăn vào biên |
| **Không có ký sinh RC** | Chưa routing ⇒ chưa có điện trở/điện dung dây. Độ trễ thật sẽ **lớn hơn** |
| **Một góc PVT** | Chỉ `tt_025C_1v80` (typical, 25 °C, 1,80 V). Góc `ss` chậm hơn đáng kể |

**Để có con số thật cần:** chạy P&R (bước 8, ⬜ chưa chạy), rồi STA **sau routing** với SPEF
thật, ở **nhiều góc PVT**, và đọc slack của đường **reg→reg** ở góc chậm nhất. Công thức
đúng:

```
 f_max = 1 / ( t_ckq + t_logic_max + t_setup + t_skew )
```

trong đó mọi số hạng lấy từ góc **xấu nhất**, không phải từ `tt`.

Phát biểu duy nhất được phép từ dữ liệu hiện có: *“Ở góc `tt_025C_1v80`, sau tổng hợp, với
clock lý tưởng và `set_input_delay = 1,0 ns`, đường in→reg dài nhất có arrival 1,64 ns và
slack 8,24 ns so với chu kỳ giả định 10 ns.”*

## 8. Trả lời câu phân tích riêng (Charter mục 9)

> *“Đếm chính xác số flip-flop trong báo cáo sử dụng cell. Nếu nhiều hơn 8, tìm xem số dư
> dùng vào việc gì (thường là chốt cờ tràn).”*

**Kết quả đếm chính xác: đúng 8 flip-flop. Không có số dư.**

| Nguồn bằng chứng | Con số | Trích dẫn |
|---|---:|---|
| `06_GDSII/synthesis/synth_stat.txt` | **8** | `sky130_fd_sc_hd__dfxtp_1        8` |
| `06_GDSII/synthesis/netlist.v` | **8** instance | `_82_`, `_83_`, `_84_`, `_85_`, `_86_`, `_87_`, `_88_`, `_89_` |
| Đọc RTL | **8** | `output logic [7:0] count`, là biến duy nhất trong `always_ff` |
| Loại cell tuần tự khác (latch)? | **0** | Không có `dlxtp`/`dlatch` nào trong `synth_stat.txt` |

Ánh xạ 1-1 giữa instance và bit đã lập ở §7 câu 1 — mọi ô nhớ đều giải thích được, không
còn ô nào không rõ nguồn gốc.

**Ba kết luận rút ra:**

1. **Không có cờ tràn.** Charter mục 9 dự đoán phần dư “thường là chốt cờ tràn”, nhưng ở
   đây không có phần dư vì **không có cờ tràn nào được hiện thực**. Điều này đối chiếu với
   Charter mục 10 (“8 ô nhớ + 1–2 cho cờ tràn” ⇒ 9–10) cho thấy **W-4 CHƯA THOẢ**. Lưu ý
   thêm: Charter mục 4 **cũng không cấp chân ra** cho cờ tràn (`uo_out[7:0]` đã dành hết cho
   `count`), nên hai mục của Charter không nhất quán — **cần thầy chốt**.
2. **Chức năng nạp không làm tăng số ô nhớ.** Đây là điểm dễ hiểu nhầm: thêm `load` và
   `load_val[7:0]` chỉ cần **một tầng mux 8 bit** trước `D`, **+0 flip-flop**. Vì vậy con số
   8 **không** phải bằng chứng cho việc thiếu chức năng nạp — bằng chứng cho W-1 phải lấy từ
   **danh sách cổng** (`d01_core` chỉ có 4 cổng vào), không từ số FF.
3. **Con số 8 là dấu hiệu tốt cho phần đã làm.** Nó chứng minh không có latch bị suy ra
   ngoài ý muốn, không có thanh ghi thừa, và RTL nhất quán với đặc tả.

**Kiểm chứng ngược để chắc chắn:** 49 cell − 8 FF = **41 cell tổ hợp** cho một mạch
tăng/giảm 8 bit + mux `enable` + chặn `rst_n`. Bóc tách sơ bộ: 8 cell chặn `rst_n`
(7 × `and2_0` + 1 × `lpflow_isobufsrc_1`), 5 cell `o21ai_0` cho mux `enable`, 9 cell
`xnor2_1`/`xor2_1` sinh bit tổng, 8 cell 4-đầu-vào (`nor4_1 × 3`, `nor3_1 × 3`, `nor4b_1`,
`or4_1`, `nand4_1`) tạo cây carry, còn lại là cell phụ trợ. Tổng khớp với cấu trúc ba tầng
mô tả ở §2.1 — **không có cụm cell nào không giải thích được**.

## 9. Những chỗ sinh viên hay sai và cách phát hiện

| # | Sai lầm | Hậu quả | Phát hiện bằng bằng chứng nào |
|---|---|---|---|
| 1 | Viết `@(posedge clk or negedge rst_n)` rồi vẫn gọi là “xoá đồng bộ” | Nhầm lẫn khái niệm; kiểm tra timing thiếu recovery/removal | `synth_stat.txt`: xuất hiện `dfrtp_1` thay vì `dfxtp_1` |
| 2 | Đặt ưu tiên `enable` **trước** `rst_n` | `enable = 0` chặn được cả reset — **reset không hoạt động** khi khối đang tạm dừng | Ca ưu tiên với `count` ở giá trị **khác `FF`** (TC-B5). ⚠️ Ca hiện có ở cạnh 17 chạy khi `count = FF` nên **không phân biệt được** — xem `timing_diagram.md` §3 |
| 3 | Dùng hai khối `always_ff` riêng cho reset và cho đếm | Multiple driver — tổng hợp báo lỗi hoặc tự chọn, mô phỏng phụ thuộc thứ tự lập lịch | Log Yosys; hoặc mô phỏng cho kết quả khác nhau giữa hai công cụ |
| 4 | Viết `always_comb` cho logic kế tiếp mà thiếu nhánh | Suy ra **latch** — số “flip-flop” trong báo cáo nhảy lên khó hiểu | `synth_stat.txt`: xuất hiện `dlxtp`/`dlatch` |
| 5 | Tưởng `if (up) …+1 else …-1` sinh ra **hai** mạch số học | Ước lượng diện tích sai gấp đôi; hiểu sai đường tới hạn | Netlist: chỉ **2** cell `mux2i_1` trong 49 cell; `up` đi vào chân dữ liệu `.B` của `nor2_1`, không phải chân `S` |
| 6 | Tưởng carry của bộ đếm 8 bit phải lan qua 8 tầng | Ước lượng độ trễ sai; hoang mang khi thấy slack lớn | STA: chỉ **5 cell logic**, 0,64 ns. `abc` gom carry thành cây (`nor4b_1` gom 4 tín hiệu) |
| 7 | Dùng `enable` như **xung** thay vì **mức** | Một sản phẩm che tia trong 1000 chu kỳ bị đếm thành **1000** | Đọc RTL: không có tách cạnh nào. Ca: giữ `enable = 1` nhiều chu kỳ rồi đếm `count` |
| 8 | Quên đồng bộ `enable`/`up` từ cảm biến vật lý | Metastability làm **nhiều bit** lấy giá trị khác nhau → `count` nhảy sang giá trị sai, không phải `±1` | Đọc RTL: không có tầng đồng bộ. Lỗi hiếm, không tái lập được, mô phỏng RTL **không bắt được** |
| 9 | Tưởng `255 → 0` là do reset | Đếm sai âm thầm; không có cờ tràn để phân biệt | `functional_spec.md` INV-9. Tầng ngoài phải tự so `count` với giá trị chu kỳ trước |
| 10 | Chỉ kiểm đếm lên, không kiểm đếm xuống | Chuỗi mượn không được kiểm | Ca `01 → 00 → FF` (testbench dòng 18) |
| 11 | Chỉ kiểm quanh 0, không kiểm biên tràn | Bỏ sót lỗi ở bit cao | Nạp cưỡng bức `8'hFE` rồi đếm 2 nhịp (testbench dòng 17). Không có kỹ thuật này thì phải đếm 254 nhịp |
| 12 | Quên ghi giá trị nạp cưỡng bức cho **cả** mô hình chuẩn | Hai mô hình lệch pha, assertion báo sai ở nhịp kế — “lỗi” của testbench, không phải của thiết kế | So hai dòng: `dut.count = …` **và** `ref_i.count_ref = …` |
| 13 | Dùng testbench hiện tại cho mô phỏng **gate-level** | Không chạy được — sau tổng hợp không còn biến `count`, chỉ có 8 instance `_82_`…`_89_` | `corner_cases.md` §6. Phải viết lại phần nạp cưỡng bức |
| 14 | Báo “bộ đếm chạy được ở 568 MHz” từ slack 8,24 ns | Phát biểu vượt mức, sai ít nhất bốn lý do | §7 câu 3 |
| 15 | Báo độ trễ là 1,64 ns | Sai **156 %** | 1,00 ns trong đó là `set_input_delay` giả định; phần của mạch là 0,64 ns |

## 10. Câu hỏi mentor nên đặt khi bảo vệ

| # | Câu hỏi | Đáp án mong đợi |
|---|---|---|
| 1 | Báo cáo có bao nhiêu flip-flop? Chỉ ra từng ô dùng vào việc gì | **8**, ánh xạ `_82_`…`_89_` ↔ `count[0]`…`count[7]`. Không có ô dư |
| 2 | Nếu báo cáo ra 9 hoặc 10 FF thì phần dư có thể là gì? | Cờ tràn, thanh ghi đồng bộ hoá, hoặc **latch do lỗi mã** (thiếu nhánh trong `always_comb`). Kiểm bằng cách tìm `dlxtp`/`dlatch` |
| 3 | Chỉ ra trong netlist chỗ nào cho thấy xoá là **đồng bộ** | FF là `dfxtp_1` — **không có chân reset**; `rst_n` xuất hiện trong cụm logic trên đường `D`: `and2_0 _81_ (.A(rst_n), …)`. Nếu bất đồng bộ sẽ là `dfrtp_1` với chân `RESET_B` |
| 4 | Xoá đồng bộ tốn bao nhiêu? | **+8 cell** (16 % của 49) và **+0,13 ns** (≈ 20 % của 0,64 ns logic). Đổi lại: miễn nhiễm glitch, không cần kiểm recovery/removal |
| 5 | Nếu clock ngừng mà hạ `rst_n` thì `count` có bị xoá không? | **Không.** Đây là hệ quả cốt lõi của xoá đồng bộ, và là rủi ro cần ghi vào tài liệu tích hợp |
| 6 | Bộ đếm này chạy được bao nhiêu MHz? | **Chưa trả lời được.** Đường báo cáo là in→reg và chứa 1,00 ns `set_input_delay`; chưa CTS, chưa routing, một góc PVT. Cần STA sau routing trên đường **reg→reg** ở góc chậm nhất |
| 7 | Vì sao đường tới hạn chỉ có 5 cell logic, không phải 8 tầng carry? | Carry của phép `+1` là **hàm AND thuần** ⇒ gom được thành cây. `abc` dùng cell 4 đầu vào (`nor4b_1` gom 4 tín hiệu). Mô tả hành vi cho công cụ quyền chọn cấu trúc |
| 8 | `up` là tín hiệu chọn giữa hai mạch cộng/trừ, đúng không? | **Không.** `−1 ≡ +0xFF` trong modulo 256 nên cả hai nhánh là “cộng hằng số”; `up` vào như **toán hạng dữ liệu** (`nor2_1 _65_ .B(up)`). Chỉ có 2 cell `mux2i_1` trong 49 cell |
| 9 | Đọc bảng ưu tiên **từ netlist**, không từ RTL | Tín hiệu nào gần FF hơn thì ưu tiên cao hơn: `up` (cell 1) → `enable` (cell 3) → `rst_n` (cell 5, sát FF). Trùng với `rst_n > enable > up` |
| 10 | Ca kiểm ưu tiên ở cuối testbench có đủ mạnh không? | **Không.** Nó chạy khi `count = FF`, nơi nhánh đúng và nhánh sai **cùng cho `00`**. Phải kiểm ở giá trị khác, ví dụ `0xA5` |
| 11 | D01 có FSM không? | **Có** — 256 trạng thái, mã hoá nhị phân đếm, 0 mã thừa. Bằng chứng: `count[k]` (là `Q`) xuất hiện làm đầu vào của cổng sinh `D`. So với C07: ở đó `Q` không quay lại ⇒ không có FSM |
| 12 | Nếu một bit của `count` bị lật do nhiễu thì sao? | Máy **không treo** (0 mã bất hợp lệ) nhưng **giá trị sai vĩnh viễn** tới lần reset. Khác C06: ở đó trạng thái chỉ đo thời gian nên tự phục hồi. “Không có mã bất hợp lệ” ≠ “chịu lỗi tốt” |
| 13 | Thêm chức năng nạp tốn bao nhiêu ô nhớ? | **0.** Chỉ cần một tầng mux 8 bit trước `D`. Chân cũng còn dư (19/24). Cái khó là **chốt bảng ưu tiên 4 mức** |
| 14 | Vì sao 49 cell trong khi Charter ước lượng 110–160? | Hai nguyên nhân: thiếu hẳn phần nạp; và `up` được hạ cấp thành dữ liệu nên không phải dựng hai cây số học |
| 15 | Vì sao không dùng bộ đếm ripple cho rẻ? | Dùng `Q` làm clock ⇒ STA không phân tích được, CTS không xử lý được, các bit lệch pha nên `FF → 00` đi qua giá trị trung gian **sai** |

## 11. Giới hạn: đã chứng minh được gì, chưa chứng minh được gì

**Đã chứng minh (bằng chứng do chính lần chạy này sinh ra):**

1. Mô hình chuẩn Python độc lập chạy PASS, **quét vét cạn 1024 trạng thái**
   (`python_reference_run.log`).
2. Mô phỏng RTL PASS trên 17 cạnh clock, **so từng chu kỳ với mô hình chuẩn SystemVerilog**
   chạy song song (`simulation.log`). Phủ 4/5 ca bắt buộc của Charter mục 8, kể cả **cả hai
   biên quấn vòng**.
3. RTL tổng hợp được thành 49 standard cell sky130 với **đúng 8** ô nhớ, 427,9104 µm²
   (`synth_stat.txt`).
4. **Bóc tách được toàn bộ 8 FF** về đúng từng bit, khớp tên instance netlist (§8).
5. **Chứng minh được bằng cấu trúc rằng xoá là ĐỒNG BỘ**: `dfxtp_1` không có chân reset;
   `rst_n` nằm trong cụm logic trên đường `D` (§7 câu 2).
6. Đường tới hạn xác định được: `up → count[7]`, 6 cell, arrival 1,64 ns, required 9,88 ns,
   slack 8,24 ns (`timing_report_max.txt`).
7. Tỷ lệ công suất tuần tự / tổ hợp = 74,4 % / 25,6 % (`power_report.txt`).

**Chưa chứng minh:**

1. **Khối chưa thoả đề D01.** Thiếu chức năng **nạp song song** (`ui_in[7:0]` +
   `uio_in[0]` theo Charter mục 4) — tức thiếu chữ “đa năng” trong tên đề, và bối cảnh ứng
   dụng của Charter mục 1 (*“nạp giá trị đầu và đếm ngược”*) **không thực hiện được**.
2. **Ca bắt buộc “nạp giữa chừng” chưa chạy** và không thể chạy cho tới khi bổ sung `load`.
3. **Khẳng định về ưu tiên còn yếu** — ca kiểm hiện có không phân biệt được nhánh đúng với
   nhánh sai (`timing_diagram.md` §3). Cần ca TC-B5.
4. **Chưa chứng minh bằng MÔ PHỎNG rằng reset là đồng bộ.** Bằng chứng hiện có là bằng
   chứng **cấu trúc** (netlist). Ca hành vi tương ứng (TC-B6: hạ `rst_n` khi clock đứng yên)
   **chưa chạy**.
5. **Chưa mô phỏng gate-level.** Và testbench hiện tại **không dùng lại được** cho gate-level
   vì nó ghi qua tên phân cấp `dut.count`.
6. **Chưa chạy P&R.** Mọi số timing là sau tổng hợp, clock lý tưởng (skew = 0), không ký
   sinh RC, một góc PVT `tt_025C_1v80`.
7. **Không có phát biểu nào về tần số tối đa** — đây chính là đáp án cho Charter mục 2
   câu 3, không phải một thiếu sót cần che.
8. **Công suất chưa đo bằng VCD thật**, và với D01 hoạt động thật phụ thuộc rất mạnh vào
   `enable`.
9. **Chưa chạy DRC/LVS, chưa sinh GDSII.** Không có phát biểu nào về sign-off, tape-out,
   chế tạo hay đo sau chế tạo — Charter mục 3 xếp ngoài phạm vi.

RTL **không bị sửa**. Mọi đề nghị bổ sung (`functional_spec.md` §9, `tradeoff.md` §4) là
thiết kế trên giấy và cần thầy duyệt trước khi áp dụng.

---

*Phiên bản: v1.0 · Ngày: 2026-09-24*
