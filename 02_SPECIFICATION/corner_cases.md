# D01 · Ca biên và ca kiểm thử (Corner Cases)

Nguồn đọc: `05_VERIFICATION/testbench/d01_core_tb.sv` (20 dòng),
`05_VERIFICATION/golden_model/d01_reference.sv`, `reference_model.py`,
`05_VERIFICATION/simulation.log`.

---

## 0. Trạng thái tổng quát

Mô phỏng RTL **PASS** (`simulation.log`: `D01 core verification PASS`, `$finish` tại `166`
→ đúng **17 cạnh lên** với chu kỳ 10 đơn vị).

Testbench D01 ngắn (20 dòng) nhưng **mật độ thông tin rất cao**: 17 cạnh clock phủ được
4/5 ca bắt buộc của Charter, cả hai biên quấn vòng, và ca ưu tiên. Ca duy nhất thiếu là
**“nạp giữa chừng”** — và nó thiếu vì **chức năng nạp chưa tồn tại** trong RTL
(`functional_spec.md` §0, W-1 và W-3), không phải vì testbench sơ sài.

## 1. Ca bắt buộc của Charter mục 8 — đối chiếu testbench thật

Charter mục 8: *“Đếm lên từ 0 tới tràn · đếm xuống từ 0 (tràn dưới) · nạp giữa chừng · xoá
đồng bộ · giữ khi không cho phép”*.

| Ca Charter | Lý do kỹ thuật phải có ca này | Có? | Bằng chứng |
|---|---|:-:|---|
| **Đếm lên từ 0 tới tràn** | Kiểm chuỗi carry ở **mọi** vị trí bit, đặc biệt chỗ carry lan hết 8 tầng (`FF → 00`). Bắt lỗi thiếu bit, lỗi bão hoà nhầm | ✅ | Dòng 16 đếm lên 5 nhịp; **dòng 17** nạp cưỡng bức `8'hFE` rồi đếm lên 2 nhịp → `FF` rồi `00` |
| **Đếm xuống từ 0 (tràn dưới)** | Kiểm chuỗi **mượn**, vốn là mạch khác với chuỗi carry. Bắt lỗi chỉ hiện thực một chiều | ✅ | Dòng 16 đếm xuống 3 nhịp; **dòng 18** nạp cưỡng bức `8'h01` rồi đếm xuống 2 nhịp → `00` rồi `FF` |
| **Nạp giữa chừng** | Kiểm mux nạp và **ưu tiên** giữa nạp / xoá / đếm — chỗ Charter mục 10 gọi là hay tắc | ❌ | **Không thể kiểm.** Không có cổng `load` (W-1) |
| **Xoá đồng bộ** | Kiểm rằng xoá xảy ra **tại cạnh clock** và thắng mọi tín hiệu khác | ✅ | Dòng 14 (reset khởi động, 2 nhịp) và **dòng 19** (reset khi `enable=1, up=1` — ca ưu tiên) |
| **Giữ khi không cho phép** | Kiểm `enable` thực sự chặn được cả hai chiều đếm | ✅ | Dòng 15: 2 nhịp với `enable = 0` sau khi nhả reset |
| Bổ sung ≥ 2 ca tự xây dựng, có ca biên | — | ✅ | Xem §2 |

**Tỷ lệ phủ ca bắt buộc: 4/5.** Ca còn lại bị chặn bởi W-1, không phải bởi chất lượng
testbench.

## 2. Ca tự xây dựng — kỹ thuật đáng học trong testbench D01

### 2.1 Nạp cưỡng bức qua tên phân cấp — cách tới biên tràn trong 2 chu kỳ

```systemverilog
dut.count = 8'hFE;  ref_i.count_ref = 8'hFE;  up = 1;  check();  check();
dut.count = 8'h01;  ref_i.count_ref = 8'h01;  up = 0;  check();  check();
```

**Vì sao kỹ thuật này đáng học:** muốn kiểm biên tràn trên một cách “tự nhiên”, phải đếm
254 nhịp từ 0 lên `FE` — tốn 254 chu kỳ mô phỏng và 254 dòng waveform vô nghĩa. Ghi thẳng
giá trị qua **tên phân cấp** (`dut.count`) đưa DUT tới sát biên trong **0 chu kỳ**, rồi chỉ
cần 2 nhịp là phủ cả `FE → FF → 00`.

**Vì sao phải ghi cho CẢ HAI:** `dut.count` **và** `ref_i.count_ref` phải được đặt cùng giá
trị. Quên một trong hai thì hai mô hình lệch pha ngay và assertion sẽ báo sai ở nhịp kế —
một “lỗi” của testbench chứ không phải của thiết kế.

**Cái giá của kỹ thuật này:**

| Ưu | Nhược |
|---|---|
| Tới biên trong 0 chu kỳ | **Phá vỡ tính đóng gói** — testbench phải biết tên biến bên trong DUT |
| Mô phỏng nhanh, waveform ngắn, dễ đọc | **Không chạy được trên netlist** — sau tổng hợp, biến `count` trở thành 8 instance `_82_`…`_89_`, không còn tên `count` để ghi vào |
| Dễ viết | Nếu đổi tên biến trong RTL, testbench **im lặng hỏng** |

⚠️ Hệ quả thực tế rất quan trọng: **testbench này không dùng lại được cho mô phỏng
gate-level** (lớp L4 trong `testplan.md`). Muốn chạy gate-level, hai dòng nạp cưỡng bức
phải được thay bằng việc đếm thật 254 nhịp, **hoặc** bằng cổng `load` — tức chính chức năng
đang thiếu ở W-1. Xem §5.

### 2.2 Ca ưu tiên — một dòng kiểm ba tín hiệu

```systemverilog
enable = 1;  up = 1;  rst_n = 0;  check();
```

Dòng cuối cùng của testbench đặt **cả ba** tín hiệu điều khiển vào trạng thái “tích cực”
rồi kiểm rằng `count` về 0. Đây là ca **ưu tiên** đúng nghĩa: nó chứng minh `rst_n` thắng
`enable`, và (gián tiếp) thắng cả `up`. Nếu ai viết ưu tiên ngược (`if (enable) … else if
(!rst_n) …`), ca này FAIL ngay.

Chỉ một dòng nhưng nó chạm đúng rủi ro mà Charter mục 10 nêu tên.

### 2.3 Ca “reset trước khi có tín hiệu hợp lệ”

```systemverilog
clk=0; rst_n=0; enable=0; up=1;
repeat(2) check();      // ← kiểm NGAY trong lúc còn reset
```

Testbench gọi `check()` **trong** giai đoạn reset, không chỉ sau đó. Điều này kiểm rằng cả
DUT lẫn mô hình chuẩn đều ra `0` ngay từ cạnh đầu tiên — bắt được lỗi “reset cần hai chu kỳ
mới có tác dụng”.

## 3. Phân loại ca theo tiêu chí kỹ thuật riêng của D01

D01 có **ba trục** cần phủ.

**Trục 1 — chế độ hoạt động** (4 hàng của bảng hành vi `functional_spec.md` §3):

| Chế độ | Có ca? | Bằng chứng |
|---|:-:|---|
| Xoá (`rst_n = 0`) | ✅ 2 lần (khởi động + ưu tiên) | dòng 14, 19 |
| Giữ (`enable = 0`) | ✅ | dòng 15 |
| Đếm lên | ✅ | dòng 16, 17 |
| Đếm xuống | ✅ | dòng 16, 18 |
| **Nạp** | ❌ | chưa tồn tại |

**Trục 2 — độ dài chuỗi carry/mượn** (kiểm mạch số học ở mọi độ sâu):

```
  giá trị  →  carry lan qua mấy tầng khi +1
    0x00 → 0x01     1 tầng   ✅ (dòng 16)
    0x01 → 0x02     1 tầng   ✅
    0x03 → 0x04     3 tầng   ✅ (dòng 16, đếm tới 5)
    0x0F → 0x10     5 tầng   ❌
    0x7F → 0x80     8 tầng   ❌  ← nửa dải, carry lan tối đa mà KHÔNG quấn vòng
    0xFE → 0xFF     1 tầng   ✅ (dòng 17)
    0xFF → 0x00     8 tầng   ✅ (dòng 17) ← carry lan tối đa VÀ quấn vòng
```

Trục 2 phủ hai đầu (1 tầng và 8 tầng) nhưng **bỏ trống khoảng giữa**. Điểm `0x7F → 0x80`
đặc biệt đáng có vì nó làm carry lan hết 8 tầng **mà không** quấn vòng — nếu ai hiện thực
nhầm “quấn vòng” thành “bão hoà”, ca `FF → 00` sẽ bắt được, nhưng nếu nhầm ở bit 7 thì chỉ
ca `7F → 80` mới bắt được.

**Trục 3 — chuyển tiếp giữa các chế độ:**

| Chuyển tiếp | Có ca? |
|---|:-:|
| reset → giữ | ✅ (dòng 14→15) |
| giữ → đếm lên | ✅ (dòng 15→16) |
| đếm lên → đếm xuống | ✅ (dòng 16) |
| đếm xuống → đếm lên | 🟡 gián tiếp (qua nạp cưỡng bức) |
| đếm → reset | ✅ (dòng 19) |
| **đảo `up` giữa chừng khi `enable = 0`** | ❌ — kiểm rằng `up` bị bỏ qua hoàn toàn |

## 4. Ca cần bổ sung — đề xuất, **chưa chạy**

**Nhóm A — chạy được NGAY với RTL hiện tại:**

| ID | Ca | Phát hiện lỗi gì | Ưu tiên |
|---|---|---|:-:|
| **TC-B1** | Nạp cưỡng bức `8'h7F`, đếm lên 1 nhịp → phải ra `8'h80` | Điểm nửa dải: carry lan hết 8 tầng **không** quấn vòng. Bắt lỗi ở riêng bit 7 | **Cao** |
| **TC-B2** | **Khả nghịch (INV-4):** từ `0x00` đếm xuống 1 nhịp (→ `FF`) rồi lên 1 nhịp (→ `00`) | Chứng minh mạch cộng và mạch trừ **thật sự đối nghịch**, kể cả qua biên | **Cao** |
| **TC-B3** | `enable = 0` trong lúc **đảo `up`** liên tục vài nhịp | Kiểm `up` bị bỏ qua hoàn toàn khi không cho phép. Bắt lỗi `up` lọt qua `enable` | **Cao** |
| **TC-B4** | Đếm lên đủ **256 nhịp** liên tục, kiểm `count` trở về đúng giá trị ban đầu | Quét toàn dải qua RTL. Hiện mô hình Python quét vét cạn nhưng **RTL thì chưa** | Trung bình |
| **TC-B5** | Reset **giữa chừng** khi `count` đang ở giá trị bất kỳ khác 0 (ví dụ `0xA5`) | Bắt lỗi reset chỉ xoá được một số bit. Hiện ca reset ở dòng 19 chạy khi `count` đang là `FF` — giá trị toàn 1, không phân biệt được bit nào | Trung bình |
| **TC-B6** | **Dừng clock** trong lúc `rst_n = 0`, rồi kiểm `count` **không** đổi | Chứng minh bằng mô phỏng rằng reset là **đồng bộ**. Đây là ca dạy học rất mạnh cho Charter mục 2 câu 2 | Trung bình |

**Nhóm B — chỉ chạy được SAU khi bổ sung cổng `load`** (cần thầy duyệt):

| ID | Ca | Ứng với ca Charter nào |
|---|---|---|
| **TC-C1** | Nạp `0xA5` giữa lúc đang đếm lên → `count` phải là `0xA5` ngay cạnh đó | “nạp giữa chừng” |
| **TC-C2** | `load = 1` và `enable = 1` cùng lúc → **nạp thắng** | Ưu tiên (Charter mục 10) |
| **TC-C3** | `load = 1` và `rst_n = 0` cùng lúc → **xoá thắng** | Ưu tiên |
| **TC-C4** | Nạp `0xFF` rồi đếm lên → quấn vòng ngay nhịp sau | Kết hợp nạp + biên |
| **TC-C5** | Nạp một giá trị rồi đếm xuống tới 0 — đúng bối cảnh Charter mục 1 (*“còn bao nhiêu suất”*) | Kiểm ứng dụng thật |

TC-C5 đáng nói riêng: nó chính là **kịch bản ứng dụng mà Charter mục 1 mô tả**. Không có
cổng `load` thì kịch bản này không chạy được, nên hiện tại hồ sơ **không chứng minh được**
khối phục vụ được bối cảnh ứng dụng của chính nó.

## 5. Ca **KHÔNG** áp dụng cho đề này

| Ca | Vì sao không áp dụng |
|---|---|
| Đếm theo bước khác 1 | Charter mục 3 — **ngoài phạm vi**. RTL hằng số hoá `+ 8'd1` / `- 8'd1` |
| Đếm **BCD** (modulo 10) | Charter mục 3 — **ngoài phạm vi**, đó là đề **D02** |
| Đếm **Gray** | Charter mục 3 — **ngoài phạm vi**, đó là đề **D05** |
| Ca bão hoà tại 255 / 0 | Đặc tả chốt **quấn vòng**, không bão hoà (INV-2, INV-3). Bão hoà là hành vi khác, thuộc đề khác |
| Ca cờ tràn (`overflow`) | **Không có cổng nào** — xem `functional_spec.md` INV-9 và W-4 |
| Ca glitch trên `count` | `count` là `Q` của flip-flop, không có đường tổ hợp nào ra thẳng cổng ra |
| Ca recovery / removal của reset | Reset là **đồng bộ** — đi vào qua đường `D` như tín hiệu dữ liệu, chỉ chịu setup/hold thông thường. Đây **chính là** nội dung câu 2 Charter mục 2 |
| Ca clock-domain crossing | Một miền clock duy nhất theo SDC. Nếu `enable` đến từ cảm biến vật lý (bối cảnh “băng chuyền”), **bộ đồng bộ phải nằm ở tầng ngoài** |

## 6. Ca cần bổ sung khi chuyển sang gate-level / post-layout

| Ca | Vì sao chỉ có ở gate-level | Cần gì |
|---|---|---|
| **Viết lại testbench không dùng tên phân cấp** | Hai dòng nạp cưỡng bức `dut.count = …` **không chạy được trên netlist** — sau tổng hợp không còn biến `count`, chỉ có 8 instance `_82_`…`_89_`. Xem §2.1 | Thay bằng đếm thật 254 nhịp, hoặc bằng cổng `load` (W-1) |
| **X-propagation lúc cấp nguồn** | Netlist dùng `dfxtp_1` — **không có chân reset**. 8 FF khởi động ở `X` | Mô phỏng `netlist.v` + thư viện `.v`, khởi tạo mọi FF bằng `X`. Phải chứng minh một cạnh với `rst_n = 0` xoá hết |
| **Chứng minh xoá là ĐỒNG BỘ trên netlist** | Bằng chứng cấu trúc đã có (`dfxtp_1` không có chân reset; 7 `and2_0` có `.A(rst_n)`); nhưng bằng chứng **hành vi** thì cần mô phỏng | Mô phỏng gate-level với `rst_n = 0` trong lúc clock **đứng yên** → `count` phải không đổi |
| **Vi phạm setup trên `up`** | RTL zero-delay luôn PASS. Đường thật `up → count[7]` là **1,64 ns** (trong đó 1,00 ns là `set_input_delay`) | SDF back-annotate, hoặc siết chu kỳ SDC tới khi slack âm |
| **Vi phạm hold trên `count[0]`** | Bit 0 chỉ là **một phép đảo** — đường reg→reg ngắn nhất có thể, ứng viên số 1 cho lỗi hold khi có clock skew thật | `timing_report_min.txt` + SDF sau CTS |
| **Công suất thật thay vì ước lượng** | Con số 5,41e-05 W dùng hoạt động **mặc định**. Hoạt động thật phụ thuộc mạnh vào `enable`: bộ đếm chạy liên tục tốn hơn nhiều so với đếm thưa | VCD của một ca thật (TC-B4 đếm 256 nhịp là ca hoạt động cao nhất) |

---

*Phiên bản: v1.0 · Ngày: 2026-09-24*
