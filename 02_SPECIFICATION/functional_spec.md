# D01 · Đặc tả chức năng (Functional Specification)

---

## 0. ⚠️ CẢNH BÁO ĐỐI CHIẾU RTL ↔ CHARTER

Đọc hết mục này trước khi dùng hồ sơ để chấm bài. RTL **không bị sửa** — chênh lệch được
ghi nhận, không được che.

| # | Yêu cầu Charter | Thực tế trong RTL | Phán xử |
|---|---|---|---|
| **W-1** | Mục 4: `ui_in[7:0]` = **giá trị nạp** và `uio_in[0]` = **nạp** | `d01_core` có đúng **4 cổng vào**: `clk`, `rst_n`, `enable`, `up`. **Không có cổng nạp, không có cổng giá trị nạp** | **REQ-D01-002 CHƯA THOẢ.** Thiếu 9 bit vào so với ánh xạ chân của Charter |
| **W-2** | Mục 1 + tên đề: bộ đếm **“đa năng”**; bối cảnh ứng dụng là *“nạp được giá trị đầu và đếm ngược để báo còn bao nhiêu suất”* | Không nạp được giá trị đầu | **REQ-D01-001 CHƯA THOẢ.** Bối cảnh ứng dụng của Charter mục 1 **không thực hiện được** với RTL hiện tại: không thể “nạp giá trị đầu”, chỉ đếm xuống từ 0 (tràn dưới về 255) |
| **W-3** | Mục 8: ca bắt buộc **“nạp giữa chừng”** | Testbench không có ca nạp | **CHƯA THOẢ — và không thể thoả** chừng nào W-1 chưa được sửa. Không có gì để kiểm |
| **W-4** | Mục 10, dấu hiệu làm đúng: *8 ô nhớ + **1–2 cho cờ tràn*** (tức 9–10) | `synth_stat.txt`: `dfxtp_1 × 8` | 🟡 **Một phần.** Đúng **8** FF cho bộ đếm, nhưng **không có cờ tràn** nào. Lưu ý: Charter mục 4 **cũng không** yêu cầu cổng ra cờ tràn — hai mục của Charter không nhất quán với nhau ở điểm này. Cần thầy chốt |
| **W-5** | Metadata: quy mô ~**110–160 cell** | **49 cell**, 427,9104 µm² | **CHƯA THOẢ** — hệ quả trực tiếp của W-1. Một bộ mux nạp 8 bit cộng logic ưu tiên sẽ đưa con số này lên đáng kể |
| **W-6** | — | `02_SPECIFICATION/interface.md` §2 (file sinh tự động) ghi “**Không có reset**” | **Sai so với RTL.** `rst_n` tồn tại, tích cực mức thấp, **đồng bộ**. Lỗi của bộ sinh tự động; bảng cổng ngay phía trên nó lại ghi đúng |

**Cái mà RTL hiện tại thực sự là:** một **bộ đếm nhị phân 8 bit lên/xuống có cho phép và
xoá đồng bộ** — đúng, gọn, và làm tốt ba trong bốn chức năng của một bộ đếm “đa năng”
(đếm lên, đếm xuống, giữ, xoá). Chức năng thứ tư — **nạp song song** — chưa có.

Phần đặc tả bên dưới mô tả **đúng cái RTL đang làm**. Phần nạp được đặc tả riêng ở §9 và
đánh dấu rõ là **chưa hiện thực**.

---

## 1. Phát biểu bài toán (phạm vi RTL hiện tại)

Khối giữ một giá trị 8 bit không dấu. Mỗi cạnh lên của `clk`, giá trị đó hoặc bị xoá về 0
(nếu đang reset), hoặc giữ nguyên (nếu không được cho phép), hoặc tăng 1, hoặc giảm 1.
Phép tăng/giảm **quấn vòng** theo số học modulo 256.

## 2. Định nghĩa toán học

Đặt `c[n]` là giá trị `count` **sau** cạnh lên thứ `n`, và `rst_n[n]`, `en[n]`, `up[n]` là
giá trị các tín hiệu điều khiển **tại** cạnh đó.

```
 c[n] = 0                         nếu  rst_n[n] = 0
 c[n] = c[n-1]                    nếu  rst_n[n] = 1 và en[n] = 0
 c[n] = (c[n-1] + 1) mod 256      nếu  rst_n[n] = 1 và en[n] = 1 và up[n] = 1
 c[n] = (c[n-1] − 1) mod 256      nếu  rst_n[n] = 1 và en[n] = 1 và up[n] = 0
```

Ba lớp mô hình trùng khớp hoàn toàn ở công thức này:

| Lớp | Mã | Ghi chú |
|---|---|---|
| RTL | `if (!rst_n) … else if (enable) … if (up) count+1 else count-1` | `d01_core.sv` |
| Mô hình chuẩn SV | `if (!rst_n) … else if (!enable) count_ref <= count_ref; else if (up) … else …` | `d01_reference.sv` — viết **ngược thứ tự** điều kiện `enable`, cố ý, để giảm rủi ro cùng sai |
| Mô hình chuẩn Python | `(count + 1) & 0xff if up else (count - 1) & 0xff` | `reference_model.py` — che mặt nạ 8 bit **tường minh** |

> **Chi tiết đáng học ở mô hình Python:** nó phải viết `& 0xff` tường minh vì số nguyên
> Python vô hạn bit. RTL và SystemVerilog thì quấn vòng **tự động** vì biến chỉ rộng 8 bit.
> Đây đúng là chỗ mô hình chuẩn viết bằng ngôn ngữ khác dễ lệch với RTL nhất — và ở đây nó
> được xử lý đúng.

## 3. Bảng hành vi đầy đủ

Bảng này có **đúng 4 hàng** và phủ **toàn bộ** không gian đầu vào điều khiển (`rst_n`,
`enable`, `up` — 8 tổ hợp, gộp bằng dấu ×):

| # | `rst_n` | `enable` | `up` | `count` kế | Tên hành vi |
|:-:|:-:|:-:|:-:|---|---|
| 1 | **0** | × | × | `0` | **Xoá đồng bộ** (ưu tiên cao nhất) |
| 2 | 1 | **0** | × | `count` (giữ) | **Giữ** |
| 3 | 1 | 1 | **1** | `count + 1` | **Đếm lên** |
| 4 | 1 | 1 | **0** | `count − 1` | **Đếm xuống** |

**Ưu tiên: `rst_n` > `enable` > `up`.** Thứ tự này là **bắt buộc** và Charter mục 10 nêu
đúng đây là chỗ hay tắc (*“Ưu tiên giữa nạp / xoá / đếm không rõ ràng → hành vi khác nhau
giữa mô phỏng và tổng hợp”*). Trong RTL, ưu tiên được viết bằng `if / else if` lồng nhau
trong **một** khối `always_ff` duy nhất, nên mô phỏng và tổng hợp **không thể** hiểu khác
nhau. Xem `control.md` §3.

## 4. Trạng thái sau reset

`rst_n` tích cực mức thấp, **đồng bộ** — bằng chứng: danh sách nhạy của `always_ff` chỉ có
`posedge clk`, không có `posedge rst_n` hay `negedge rst_n`.

| Tín hiệu | Sau cạnh lên đầu tiên có `rst_n = 0` |
|---|---:|
| `count[7:0]` | `0` |

**Nghĩa vụ tầng ngoài:** giữ `rst_n = 0` qua **ít nhất một cạnh lên đầy đủ** của `clk`. Một
cạnh là đủ vì khi `rst_n = 0` thì đường `D` của cả 8 flip-flop là hằng `0` — bằng chứng
netlist: 7 cell `and2_0` có chân `.A(rst_n)` nằm ngay trước các flip-flop, cộng một cell
`lpflow_isobufsrc_1` làm việc tương tự cho bit 1.

⚠️ Hệ quả quan trọng: **nếu clock ngừng, reset không có tác dụng.** Đây là khác biệt cốt
lõi giữa xoá đồng bộ và xoá bất đồng bộ — xem `implementation-notes_D01.md` §7 câu 2.

## 5. Độ trễ

| Quan hệ | Độ trễ |
|---|---|
| `enable`/`up`/`rst_n` tại cạnh `n` → `count` đổi | **đúng 1 cạnh clock** (chính cạnh đó) |
| Thông lượng | 1 phép đếm / chu kỳ, liên tục |
| Độ trễ khởi động | Không có — bộ đếm đếm ngay từ cạnh đầu tiên sau khi nhả reset, nếu `enable = 1` |

Không có pipeline, không có bắt tay, không có chu kỳ chết.

## 6. Tính chất bất biến (Invariants)

| ID | Phát biểu | Bằng chứng hiện có |
|---|---|---|
| **INV-1** | `0 <= count <= 255` ở mọi chu kỳ | Thanh ghi rộng đúng 8 bit — đúng theo cấu trúc |
| **INV-2** | **Quấn vòng trên:** `count = 255` và (`en=1`, `up=1`) ⇒ `count` kế `= 0` | Testbench: nạp cưỡng bức `8'hFE` rồi đếm lên hai nhịp (dòng 17) |
| **INV-3** | **Quấn vòng dưới:** `count = 0` và (`en=1`, `up=0`) ⇒ `count` kế `= 255` | Testbench: nạp cưỡng bức `8'h01` rồi đếm xuống hai nhịp (dòng 18) |
| **INV-4** | **Khả nghịch:** một nhịp lên rồi một nhịp xuống (cùng `en=1`) trả `count` về giá trị cũ, kể cả khi quấn vòng | Suy từ §2. ⬜ Chưa có ca kiểm thử tường minh |
| **INV-5** | `enable = 0` ⇒ `count` **không đổi**, bất kể `up` | Testbench dòng 15 (hai nhịp `enable=0` sau khi nhả reset) |
| **INV-6** | `rst_n = 0` ⇒ `count = 0` **bất kể** `enable` và `up` | Testbench dòng 19: đặt `enable=1, up=1, rst_n=0` cùng lúc rồi kiểm — **ca ưu tiên** |
| **INV-7** | `count` thay đổi **chỉ tại cạnh lên của `clk`** | 8 `dfxtp_1` kích cạnh lên; không có latch nào trong `synth_stat.txt` |
| **INV-8** | Không có tổ hợp `(rst_n, enable, up)` nào cho hành vi không xác định — bảng §3 phủ **toàn bộ** 8 tổ hợp | Bảng §3; mô hình Python quét **vét cạn** 256 × 2 × 2 = 1024 trạng thái (`reference_model.py` dòng 14–19) |
| **INV-9** | **Không có cờ tràn:** khối **không** báo ra việc vừa quấn vòng | Đọc RTL — không có tín hiệu nào ngoài `count`. Xem W-4 |

> INV-9 tuy là phát biểu về cái **không có**, nhưng nó là invariant quan trọng nhất cho
> tầng ngoài: **đếm tới 255 rồi về 0 trông giống hệt như bị reset.** Tầng ngoài không phân
> biệt được hai tình huống đó nếu chỉ nhìn `count`.

## 7. Điều kiện biên và hành vi không xác định

| Tình huống | Hành vi | Trạng thái đặc tả |
|---|---|---|
| `count = 255`, đếm lên | Về `0` (quấn vòng), **không bão hoà, không báo** | ✅ Đã chốt, đã kiểm |
| `count = 0`, đếm xuống | Về `255` (quấn vòng dưới) | ✅ Đã chốt, đã kiểm |
| `enable = 0` trong lúc `up` đổi giá trị | `count` không đổi; `up` bị bỏ qua hoàn toàn | ✅ Xác định |
| `rst_n = 0` cùng lúc `enable = 1` | Xoá thắng | ✅ Đã kiểm (testbench dòng 19) |
| **`clk` ngừng trong khi `rst_n = 0`** | **`count` KHÔNG bị xoá** — giữ nguyên giá trị cũ | ⚠️ **Đúng theo thiết kế nhưng dễ gây bất ngờ.** Hệ quả của xoá đồng bộ |
| `up` đổi giá trị **quá sát** cạnh clock | Vi phạm setup → giá trị không xác định | ⚠️ Nghĩa vụ tầng ngoài. Đây là đường **tới hạn thật** (`up → count[7]`) |
| `enable`, `up`, `rst_n` chứa `X`/`Z` | Lan vào toàn bộ `count` | ⚠️ Không xác định |
| Chưa reset lần nào | 8 FF là `X` ở gate-level | ⚠️ Bắt buộc phải có chuỗi reset |
| Tín hiệu điều khiển đến từ miền clock khác (ví dụ nút bấm) | Không có bộ đồng bộ trong RTL | ⚠️ **Nghĩa vụ tầng ngoài.** Rất đáng lưu ý với D01: bối cảnh “đếm sản phẩm trên băng chuyền” gợi ý `enable` đến từ cảm biến vật lý, tức miền bất đồng bộ |

## 8. Ràng buộc cấu trúc

Tên đề (“Bộ đếm nhị phân 8-bit đa năng”) chỉ định **hai** ràng buộc cấu trúc bắt buộc:

| ID | Ràng buộc | Đo được | Trạng thái |
|---|---|---|:-:|
| S-1 | **Nhị phân** — không phải BCD (đó là D02), không phải Gray (D05) | `count + 1` / `count - 1` là số học nhị phân thuần | ✅ |
| S-2 | **8 bit** | `count[7:0]`, 8 `dfxtp_1` | ✅ |
| S-3 | **Đa năng** — nạp · lên/xuống · cho phép · xoá | Có lên/xuống ✅, cho phép ✅, xoá ✅; **nạp ❌** | ❌ **CHƯA THOẢ** (W-1, W-2) |
| S-4 | Bước đếm phải là **1** (Charter mục 3: bước khác 1 nằm ngoài phạm vi) | `+ 8'd1` / `- 8'd1` | ✅ |
| S-5 | Ô nhớ ≈ 8 + 1–2 cờ tràn | **8**, không có cờ tràn | 🟡 (W-4) |

## 9. Đặc tả phần **CHƯA HIỆN THỰC**: nạp song song

**Toàn bộ mục này là đặc tả mục tiêu, KHÔNG phải mô tả mã hiện có.**

### 9.1 Bảng hành vi mở rộng

| # | `rst_n` | `load` | `enable` | `up` | `count` kế | Ghi chú |
|:-:|:-:|:-:|:-:|:-:|---|---|
| 1 | **0** | × | × | × | `0` | Xoá — ưu tiên **cao nhất** |
| 2 | 1 | **1** | × | × | `load_val` | Nạp — ưu tiên **thứ hai** |
| 3 | 1 | 0 | **0** | × | giữ | |
| 4 | 1 | 0 | 1 | **1** | `count + 1` | |
| 5 | 1 | 0 | 1 | **0** | `count − 1` | |

### 9.2 Ba câu hỏi ưu tiên phải chốt trước khi viết mã

Charter mục 10 cảnh báo đúng chỗ này. Ba câu hỏi, và cả ba **phải được trả lời tường minh
trong đặc tả**, không được để trình tổng hợp tự đoán:

| Câu hỏi | Lựa chọn thường dùng | Lý do |
|---|---|---|
| `load` có thắng `rst_n` không? | **Không** — `rst_n` luôn thắng | Reset phải là lối thoát tuyệt đối từ mọi trạng thái |
| `load` có cần `enable = 1` không? | **Không** — nạp độc lập với `enable` | Nạp là thao tác cấu hình, không phải thao tác đếm. Nếu bắt phụ thuộc `enable`, tầng ngoài phải bật `enable` để nạp rồi tắt ngay — dễ sai |
| Nếu `load = 1` và `enable = 1` cùng lúc thì nạp hay đếm? | **Nạp** (nạp có ưu tiên cao hơn) | Nạp là lệnh tường minh từ tầng ngoài; đếm là hành vi mặc định |

Nếu ba câu này không được chốt, mỗi người viết một kiểu `if/else`, và hai bản RTL trông
giống nhau sẽ cho hai hành vi khác nhau ở đúng các tổ hợp hiếm — loại lỗi chỉ lộ ra ở
tích hợp.

### 9.3 Chi phí ước lượng của phần nạp

| Hạng mục | Ước lượng | Cơ sở |
|---|---|---|
| Cổng vào thêm | **+9** (`load` 1 bit + `load_val` 8 bit) | Charter mục 4 |
| Ngân sách chân sau khi thêm | 11 vào + 8 ra = **19 / 24** | Charter mục 4 ghi đúng con số này — **vẫn vừa** |
| Flip-flop thêm | **0** | Nạp chỉ cần thêm một tầng mux trước `D`, không cần thanh ghi mới |
| Cell thêm | ⬜ **chưa chạy** — phải tổng hợp mới biết | Không được ước lượng |
| Ảnh hưởng đường tới hạn | ⚠️ **Có thể đáng kể** — thêm một tầng mux 8 bit trước `D` | Phải chạy STA mới kết luận |

Chi tiết **+0 flip-flop** đáng nhấn mạnh, vì nó là câu trả lời trực tiếp cho Charter mục 2
câu 1: nạp song song **không** tốn thêm ô nhớ. Nó chỉ tốn chân và logic tổ hợp.

---

*Phiên bản: v1.0 · Ngày: 2026-09-24*
