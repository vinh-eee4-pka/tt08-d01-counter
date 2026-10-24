# D01 · Phân tích đánh đổi (Trade-off)

Mọi con số lấy từ `06_GDSII/synthesis/synth_stat.txt`, `06_GDSII/sta/timing_report_max.txt`,
`06_GDSII/power/power_report.txt` của **chính lần chạy này**. Chỗ chưa có số đo ghi ⬜.

---

## 1. Số liệu nền

| Chỉ số | Giá trị đo | Nguồn |
|---|---:|---|
| Tổng cell | **49** | `synth_stat.txt` |
| Flip-flop | **8** | `synth_stat.txt` (`dfxtp_1 × 8`) |
| Diện tích | **427,9104 µm²** | `synth_stat.txt` |
| Data arrival | **1,64 ns** (trong đó **1,00 ns** là `set_input_delay`) | `timing_report_max.txt` |
| Data required | **9,88 ns** (= 10,00 − 0,12 setup) | `timing_report_max.txt` |
| Slack | **8,24 ns** (MET) · WNS/TNS 0,00 | `timing_report_max.txt` |
| Công suất | **5,41e-05 W** · tuần tự **74,4 %** · tổ hợp 25,6 % | `power_report.txt` |
| Charter ước lượng quy mô | ~110–160 cell | Charter metadata |

**Ba con số đáng dừng lại:**

1. **Logic chỉ tốn 0,64 ns** (1,64 − 1,00). Slack 8,24 ns trên chu kỳ 10 ns nghĩa là D01
   **dư thừa rất nhiều** về timing — đây là thiết kế có chỗ để thêm chức năng.
2. **49 cell so với ước lượng 110–160 của Charter.** Chênh lệch hơn 2× và có **hai** nguyên
   nhân cộng lại: (a) thiếu hẳn phần nạp (W-1 trong `functional_spec.md` §0), (b) `up` được
   trình tổng hợp hạ cấp thành **dữ liệu** thay vì tín hiệu chọn giữa hai mạch số học, nên
   không phải dựng hai cây carry (`datapath.md` §4).
3. **Công suất tuần tự 74,4 %.** Với 8 FF trong 49 cell (16 %), flip-flop vẫn chiếm ba phần
   tư năng lượng. Hệ quả: **tối ưu cell tổ hợp gần như vô ích** cho D01; muốn giảm công
   suất phải giảm hoạt động chuyển mạch của flip-flop (clock gating khi `enable = 0`).

---

## 2. So sánh kiến trúc bộ đếm: đồng bộ ↔ ripple ↔ LFSR ↔ Gray

Ba phương án thay thế, so với kiến trúc đang dùng.

**P0 — hiện tại: bộ đếm đồng bộ, mô tả hành vi (`count + 1` / `count - 1`).**
Tất cả 8 flip-flop dùng **chung một clock**; logic kế tiếp là một cây carry.

**P1 — bộ đếm ripple (asynchronous counter).**
`Q` của bit `k` làm **clock** cho bit `k+1`. Kinh điển trong mạch TTL rời.

**P2 — LFSR (thanh ghi dịch hồi tiếp tuyến tính).**
Đếm qua một hoán vị giả ngẫu nhiên của 255 trạng thái.

**P3 — bộ đếm Gray.**
Mỗi bước chỉ **một** bit đổi. Charter mục 3 xếp vào **ngoài phạm vi** (đó là đề D05).

| Tiêu chí | **P0 (đang dùng)** | P1 — ripple | P2 — LFSR | P3 — Gray |
|---|---|---|---|---|
| Flip-flop | **8** (đo) | 8 | 8 | 8 |
| Logic tổ hợp | Cây carry: 49 cell tổng (đo) | **Gần như không có** — chỉ đảo | Vài cổng XOR — **ít nhất** | Nhiều hơn P0 |
| Diện tích | **427,9104 µm²** (đo) | ⬜ chưa chạy — dự đoán nhỏ hơn | ⬜ — dự đoán nhỏ nhất | ⬜ — dự đoán lớn hơn P0 |
| Số miền clock | **1** | **8** — mỗi bit một clock riêng! | 1 | 1 |
| STA có phân tích được không? | ✅ dễ | ❌ **rất khó** — clock bắt nguồn từ dữ liệu | ✅ | ✅ |
| Tất cả bit đổi **cùng lúc**? | ✅ | ❌ — lệch dần, `FF → 00` đi qua trạng thái trung gian sai | ✅ | ✅ |
| Đọc được giá trị bất kỳ lúc nào? | ✅ | ❌ — phải chờ ổn định | ✅ | ✅ |
| Đếm được **xuống**? | ✅ | 🟡 khó | ❌ (LFSR ngược cần đa thức khác) | ✅ |
| Giá trị có phải **nhị phân tự nhiên**? | ✅ | ✅ | ❌ — phải tra bảng để biết đã đếm bao nhiêu | ❌ — phải giải mã |
| Số trạng thái | 256 | 256 | **255** (thiếu trạng thái toàn 0 hoặc toàn 1) | 256 |
| Công suất chuyển mạch mỗi bước | Trung bình ~2 bit đổi; **xấu nhất 8 bit** (`FF→00`) | Tương tự nhưng trải theo thời gian | ~4 bit (ngẫu nhiên) | **Đúng 1 bit** — thấp nhất |
| Khi nào nên dùng | **Mặc định cho mọi thiết kế đồng bộ** | Chỉ khi cực kỳ thiếu diện tích và không cần đọc chính xác | Đếm số lần xảy ra mà không cần biết giá trị (ví dụ watchdog) | Khi giá trị phải **vượt miền clock** — 1 bit đổi mỗi bước nên không có mã trung gian sai |
| Trong đề này | ✅ | ⛔ vi phạm nguyên tắc đồng bộ | ⛔ sai ngữ nghĩa (Charter đòi **nhị phân**) | ⛔ Charter mục 3: **ngoài phạm vi** (đề D05) |

**Vì sao P1 (ripple) bị loại dứt khoát dù tốn ít logic nhất:** dùng `Q` làm clock biến dữ
liệu thành clock, khiến (a) STA không phân tích nổi (clock không xác định được từ SDC),
(b) các bit lệch pha nên `FF → 00` đi qua các giá trị trung gian **sai** (`FE`, `FC`, `F8`…)
— nếu tầng ngoài đọc đúng lúc đó sẽ được giá trị vô nghĩa, (c) không có CTS nào xử lý được.
Với quy trình RTL→GDSII bằng công cụ tự động, ripple counter là kiến trúc **không dùng
được**, bất kể nó tiết kiệm bao nhiêu cổng.

**P3 (Gray) đáng nhắc riêng** vì nó giải đúng vấn đề mà D01 **đang** có: nếu `count` phải
được đọc bởi một khối ở miền clock khác, bộ đếm nhị phân là nguy hiểm (8 bit đổi cùng lúc
tại `FF → 00`, bộ đồng bộ phía nhận có thể bắt được một tổ hợp bit hoàn toàn sai). Gray chỉ
đổi 1 bit nên tổ hợp sai xấu nhất cũng chỉ lệch 1 đơn vị. Nhưng Charter mục 3 chốt Gray là
đề D05, nên với D01 **nghĩa vụ đồng bộ thuộc về tầng ngoài** (`control.md` §7).

---

## 3. Đánh đổi trong phạm vi: xoá ĐỒNG BỘ ↔ xoá BẤT ĐỒNG BỘ

Đây là đánh đổi **có số đo thật**, và nó trả lời trực tiếp câu 2 của Charter mục 2.

| Tiêu chí | **Xoá đồng bộ (đang dùng)** | Xoá bất đồng bộ |
|---|---|---|
| Cell flip-flop | `dfxtp_1` (đo: 8 cái) | `dfrtp_1` — có chân `RESET_B` |
| Cell tổ hợp thêm | **+8** (7 × `and2_0` + 1 × `lpflow_isobufsrc_1`) ≈ **16 %** của 49 cell | 0 |
| Diện tích FF | Nhỏ hơn (FF đơn giản hơn) | Lớn hơn mỗi cell |
| Đường tới hạn | `rst_n` **nằm trên** đường tới hạn — cell `_81_` cộng **0,13 ns** trong 0,64 ns logic (**~20 %**) | `rst_n` **không** nằm trên đường `D` |
| Tác dụng khi clock đứng yên | ❌ **KHÔNG xoá được** | ✅ Xoá ngay |
| Khởi tạo lúc cấp nguồn (trước khi clock chạy) | ❌ Phải chờ ít nhất 1 cạnh clock | ✅ Xác định ngay |
| Kiểm tra timing cần thêm | Không — setup/hold thường | **Recovery / removal** — phải kiểm riêng |
| Rủi ro reset "bẩn" (glitch trên `rst_n`) | **Bị flip-flop lọc** — chỉ giá trị tại cạnh clock mới tính | **Glitch đi thẳng vào FF** → reset giả |
| Lọc nhiễu trên `rst_n` | ✅ tự nhiên | ❌ cần bộ lọc riêng |
| Khi nào nên dùng | Mặc định cho khối bên trong chip có clock ổn định | Khi phải bảo đảm trạng thái **trước khi** clock chạy (ví dụ khối quản lý nguồn) |

**Cái giá đo được của xoá đồng bộ ở D01: 8 cell (16 %) và 0,13 ns (20 % độ trễ logic).**
Với slack 8,24 ns, cái giá 0,13 ns hoàn toàn không đáng kể. Còn cái được — miễn nhiễm với
glitch trên `rst_n` và không cần kiểm recovery/removal — là thật.

Nhưng có một rủi ro hệ thống phải ghi vào tài liệu tích hợp: **nếu clock chưa chạy hoặc bị
dừng, reset không có tác dụng.** Với bối cảnh “băng chuyền công nghiệp” (Charter mục 1),
nơi người vận hành có thể bấm reset bất kỳ lúc nào, đây là hành vi dễ gây bất ngờ.

---

## 4. Đánh đổi bắt buộc phải làm: bổ sung chức năng nạp

| Hạng mục | Ước lượng | Cơ sở |
|---|---|---|
| Cổng vào thêm | **+9** (`load` + `load_val[7:0]`) | Charter mục 4 |
| Ngân sách chân sau khi thêm | 11 vào + 8 ra = **19 / 24** — **vẫn vừa** | Charter mục 4 ghi đúng con số này |
| Flip-flop thêm | **+0** | Nạp chỉ cần một tầng mux trước `D` |
| Cell thêm | ⬜ **chưa chạy** | Không được ước lượng |
| Tầng logic thêm trên đường `D` | **+1** (mux 8 bit) | Cấu trúc |
| Slack còn lại | ⬜ chưa chạy — nhưng hiện có **8,24 ns** dư, một tầng mux khó mà dùng hết | Phải chạy STA |
| Ảnh hưởng ưu tiên | ⚠️ **Đây mới là rủi ro thật** — ba câu hỏi ở `functional_spec.md` §9.2 phải chốt trước | Charter mục 10 |

**Kết luận: chi phí kỹ thuật của việc thêm nạp là thấp; rủi ro nằm ở đặc tả, không ở phần
cứng.** Không tốn ô nhớ, chân còn dư, timing còn dư rất nhiều. Cái đắt là phải chốt bảng ưu
tiên bốn mức cho rõ ràng — đúng chỗ Charter mục 10 cảnh báo.

Về **cờ tràn** (W-4): thêm 1 FF là đủ để chốt “đã từng quấn vòng”. Nhưng Charter mục 4
**không cấp chân ra** cho nó (`uo_out[7:0]` đã dành hết cho `count`). Hai mục của Charter
không nhất quán ở điểm này — cần thầy chốt trước khi làm.

---

## 5. Đánh đổi công suất: ba phần tư năng lượng nằm ở flip-flop

| Nhóm | Công suất | Tỷ lệ |
|---|---:|---:|
| Sequential | 4,02e-05 W | **74,4 %** |
| Combinational | 1,39e-05 W | 25,6 % |
| **Tổng** | **5,41e-05 W** | 100 % |

Hệ quả cho việc tối ưu:

| Hướng tối ưu | Hiệu quả dự đoán | Trong phạm vi? |
|---|---|---|
| Giảm số cell tổ hợp | **Thấp** — chỉ chạm 25,6 % | ✅ nhưng không đáng |
| **Clock gating khi `enable = 0`** | **Cao** — cắt hẳn chuyển mạch của 8 FF trong các chu kỳ giữ | 🟡 Không bị Charter cấm, nhưng đổi cấu trúc clock |
| Đổi sang bộ đếm Gray (1 bit đổi/bước) | Cao về công suất chuyển mạch | ⛔ Charter mục 3: ngoài phạm vi (đề D05) |
| Giảm tần số clock | Tuyến tính | Quyết định của tầng ngoài |

⚠️ Lưu ý trung thực: con số 5,41e-05 W tính với hoạt động **mặc định**, không phải VCD thật.
Với D01, hoạt động thật phụ thuộc **rất mạnh** vào `enable` — một bộ đếm chạy liên tục tốn
khác hẳn một bộ đếm đếm thưa thớt sản phẩm trên băng chuyền. Muốn con số đáng tin phải thu
VCD từ một ca thật (`corner_cases.md` §6).

---

## 6. Những đánh đổi **KHÔNG được phép** trong đề này

| Việc bị cấm | Nguồn cấm | Vì sao |
|---|---|---|
| Đếm theo **bước khác 1** | Charter mục 3 — ngoài phạm vi | RTL hằng số hoá `+ 8'd1` / `- 8'd1` |
| Đếm **BCD** | Charter mục 3 — đó là đề **D02** | — |
| Đếm **Gray** | Charter mục 3 — đó là đề **D05** | Chỉ được so trên giấy như ở §2 |
| Bộ đếm **ripple** (dùng `Q` làm clock) | Nguyên tắc thiết kế đồng bộ | STA không phân tích được; CTS không xử lý được; bit lệch pha |
| Đổi quấn vòng thành **bão hoà** | Đặc tả chốt quấn vòng (INV-2, INV-3) | Là hành vi khác, thuộc đề khác |
| **Sửa netlist bằng tay** | Charter mục 3 (mọi đề) | Mất truy vết RTL ↔ netlist |
| **Tự làm physical design** | Charter mục 3 | Ngoài phạm vi học phần |
| Tuyên bố **“bộ đếm chạy được ở X MHz”** | Charter mục 3 + `timing.md` §3 | Chưa P&R, chưa RC, chưa CTS, một góc PVT. Charter mục 2 câu 3 hỏi đúng câu này và đáp án đúng là *“chưa lấy được từ dữ liệu hiện có”* |
| **Tự sửa RTL để thêm `load` mà chưa hỏi thầy** | Quy tắc hồ sơ | RTL giữ nguyên bản gốc. Mọi đề nghị ở §4 cần duyệt trước |

---

## 7. Kết luận đánh đổi

1. **Kiến trúc đồng bộ mô tả hành vi là lựa chọn đúng** và không có phương án thay thế nào
   dùng được trong phạm vi: ripple vi phạm nguyên tắc đồng bộ, LFSR sai ngữ nghĩa, Gray bị
   Charter loại.
2. **Viết bằng toán tử `+`/`-` thay vì mô tả cấu trúc là quyết định quan trọng nhất** — nó
   cho `abc` quyền dựng cây carry thay vì chuỗi ripple, và kết quả đo được là **5 tầng
   logic, 0,64 ns** cho MSB của một bộ đếm 8 bit (`datapath.md` §6). Đối chiếu với A01
   (ripple-carry tường minh) để thấy hai mặt của cùng nguyên lý.
3. **Xoá đồng bộ tốn 8 cell và 0,13 ns**, đổi lấy miễn nhiễm glitch và không phải kiểm
   recovery/removal. Với slack 8,24 ns, đây là đánh đổi rõ ràng có lợi — miễn là tài liệu
   tích hợp ghi rõ rằng reset cần clock.
4. **Đánh đổi cấp bách nhất không nằm trong bất kỳ bảng nào trên đây**, mà ở chỗ **chức
   năng nạp còn thiếu**. Chi phí kỹ thuật thấp (+0 FF, chân còn dư, timing còn dư), rủi ro
   nằm ở việc chốt bảng ưu tiên bốn mức.
5. Mọi con số ở đây là **sau tổng hợp**, clock lý tưởng, một góc PVT `tt_025C_1v80`, không
   ký sinh RC.

---

*Phiên bản: v1.0 · Ngày: 2026-09-24*
