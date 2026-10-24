# D01 · Phần điều khiển (Control)

---

## 1. D01 **có** phần điều khiển, và nó là phần đáng chú ý nhất của đề

Bộ đếm là loại khối hiếm hoi mà **phần điều khiển và phần datapath gần như trùng nhau**:
không có FSM riêng, không có bộ đếm chu kỳ phụ, nhưng có **ba tín hiệu điều khiển xếp
chồng** quyết định mỗi cạnh clock làm gì. Chính việc xếp chồng đó — và **thứ tự** của nó —
là nội dung mà Charter mục 10 gọi là chỗ hay tắc.

## 2. Bảng tín hiệu điều khiển

| Tín hiệu | Nguồn | Ưu tiên | Tác dụng | Dòng RTL | Vị trí trong netlist |
|---|---|:-:|---|---|---|
| `rst_n` | cổng vào | **1 (cao nhất)** | Ép cả 8 FF về 0. **Đồng bộ** — chỉ có tác dụng tại cạnh clock | 8–9 | 7 × `and2_0(.A(rst_n))` + 1 × `lpflow_isobufsrc_1` — **sát flip-flop nhất** |
| `enable` | cổng vào | **2** | `0` = giữ nguyên; `1` = cho phép đếm | 10 | `o21ai_0 × 5`; trên đường tới hạn là `_79_ o21ai_0(.B1(enable))` |
| `up` | cổng vào (fanout **10**) | **3 (thấp nhất)** | `1` = đếm lên; `0` = đếm xuống | 11–14 | `_65_ nor2_1(.A(count[4]), .B(up))` — **đi vào như toán hạng dữ liệu**, xem `datapath.md` §4 |
| `clk` | cổng vào | — | Hạ tầng — mọi thay đổi chỉ xảy ra tại cạnh lên | 7 | chân `CLK` của 8 `dfxtp_1` |
| 🔴 `load` | — | *(đáng lẽ là 2)* | **CHƯA TỒN TẠI** | — | — |

## 3. Bảng ưu tiên — và vì sao nó là rủi ro chính của đề

Charter mục 10: *“Ưu tiên giữa nạp / xoá / đếm không rõ ràng → hành vi khác nhau giữa mô
phỏng và tổng hợp.”*

**Ưu tiên thực tế trong RTL:**

```systemverilog
if (!rst_n)            // ① ưu tiên cao nhất
    count <= 8'd0;
else if (enable) begin // ② 
    if (up)            // ③ ưu tiên thấp nhất
        count <= count + 8'd1;
    else
        count <= count - 8'd1;
end
// ④ không có else cuối → giữ nguyên
```

| Ưu tiên | Điều kiện | Hành động | Rủi ro nếu viết sai |
|:-:|---|---|---|
| 1 | `rst_n = 0` | `count ← 0` | Nếu đặt `enable` lên trước, `enable = 0` sẽ chặn được cả reset — **reset không hoạt động** khi khối đang bị tạm dừng |
| 2 | `rst_n = 1`, `enable = 0` | Giữ nguyên | — |
| 3 | `rst_n = 1`, `enable = 1`, `up = 1` | `count + 1` | — |
| 4 | `rst_n = 1`, `enable = 1`, `up = 0` | `count − 1` | — |

**Vì sao RTL này AN TOÀN trước rủi ro Charter nêu:**

| Điều kiện an toàn | D01 có thoả? | Bằng chứng |
|---|:-:|---|
| Tất cả điều kiện nằm trong **một** khối `always_ff` | ✅ | Chỉ có một `always_ff`, dòng 7–19 |
| Dùng `if / else if` **lồng nhau**, không dùng các `if` song song | ✅ | Dòng 8, 10, 11 |
| Không có `casez`/`casex` (vốn có ngữ nghĩa khác nhau giữa mô phỏng và tổng hợp) | ✅ | Không có `case` nào |
| Nhánh “không làm gì” là **thiếu `else`** trong `always_ff` (hợp lệ, cho ra flip-flop giữ giá trị) | ✅ | Dòng 15: khối kết thúc không có `else` |
| Mọi tổ hợp đầu vào đều có hành vi xác định | ✅ | Bảng `functional_spec.md` §3 phủ 8/8 tổ hợp |

> 🔑 **Nguồn gốc thật của rủi ro mà Charter cảnh báo.** Sự khác biệt “mô phỏng ≠ tổng hợp”
> **không** đến từ việc có nhiều điều kiện, mà đến từ ba thói quen cụ thể: (a) tách điều
> kiện ra nhiều khối `always` khác nhau cùng ghi một biến — mô phỏng cho kết quả phụ thuộc
> thứ tự lập lịch, tổng hợp thì báo lỗi multiple driver hoặc tự chọn; (b) dùng `casex`/`casez`
> với `X`/`Z` — mô phỏng khớp `X`, phần cứng thì không có khái niệm `X`; (c) thiếu nhánh
> trong `always_comb` — mô phỏng giữ giá trị cũ, tổng hợp suy ra **latch**.
> D01 tránh được cả ba.

**Chỗ rủi ro sẽ xuất hiện:** khi thêm `load` (`functional_spec.md` §9). Lúc đó bảng ưu tiên
có **bốn** mức và ba câu hỏi phải chốt trước khi viết một dòng mã nào — đã liệt kê ở
`functional_spec.md` §9.2.

## 4. Đọc bảng ưu tiên **từ netlist**, không từ mã nguồn

Đây là kỹ thuật kiểm chứng độc lập: thay vì tin vào cách đọc `if/else`, đọc thẳng thứ tự
các cổng trên đường `D`. **Tín hiệu nào gần flip-flop hơn thì ưu tiên cao hơn.**

Trích đường tới hạn (`06_GDSII/sta/timing_report_max.txt`, cell 1→6):

```
   up ──▶ _65_ (nor2_1)  ──▶ _77_ (nor4b_1) ──▶ _79_ (o21ai_0) ──▶ _80_ ──▶ _81_ (and2_0) ──▶ _89_ (FF)
          ▲                                      ▲                          ▲
          │                                      │                          │
        up (ưu tiên 3)                    enable (ưu tiên 2)          rst_n (ưu tiên 1)
        xa FF nhất                          ở giữa                  SÁT FF nhất
```

Thứ tự vật lý `up → enable → rst_n` (từ xa tới gần flip-flop) **trùng khớp** với thứ tự ưu
tiên logic `rst_n > enable > up` đọc từ RTL. Netlist tự xác nhận đặc tả.

Đây là cách phán xử ưu tiên **không phụ thuộc vào việc tin người viết mã**, và nó dùng được
cả khi không có mã nguồn.

## 5. Quan hệ điều khiển ↔ datapath

Điểm đặc biệt của D01: **hai tín hiệu điều khiển hành xử rất khác nhau về mặt timing.**

| | `enable`, `rst_n` | `up` |
|---|---|---|
| Vai trò logic | Điều khiển thật — chọn **làm gì** | Chọn **chiều**, nhưng… |
| Vào netlist qua | Chân chọn/chặn của cổng phức (`o21ai_0`, `and2_0`) | **Chân dữ liệu** của cổng `nor2_1`, ngang hàng với `count[4]` |
| Vị trí trên đường tới hạn | Gần flip-flop (tầng 3 và 5) | **Tầng 1** — xa nhất |
| Số mux 2→1 sinh ra | gộp vào cổng phức | chỉ **2** cell `mux2i_1` trong toàn bộ 49 cell |

Nói cách khác: `enable` và `rst_n` là **điều khiển thật** (gating), còn `up` bị trình tổng
hợp “hạ cấp” thành **dữ liệu** vì `+1` và `−1` đều là cộng với hằng số (lập luận đầy đủ ở
`datapath.md` §4). Đây là một ví dụ rất rõ về việc **vai trò kiến trúc của một tín hiệu có
thể khác với vai trò vật lý của nó sau tổng hợp**.

## 6. Cái mà phần điều khiển này **không** làm

| Cơ chế | Có? | Nếu cần thì phải thêm gì |
|---|:-:|---|
| **Nạp song song** | 🔴 **KHÔNG** — Charter mục 4 yêu cầu | +1 cổng vào `load` + 8 cổng vào `load_val` + 1 tầng mux 8 bit. **+0 FF** |
| Báo tràn / quấn vòng | ❌ | +1…2 FF + logic phát hiện. Charter mục 10 gợi ý, mục 4 không cấp chân |
| Bão hoà thay vì quấn vòng | ❌ | Logic chặn khi `count` chạm biên |
| Đếm theo bước khác 1 | ❌ | ⛔ Charter mục 3: **ngoài phạm vi** |
| Modulo tuỳ ý (đếm tới N rồi về 0) | ❌ | +1 mạch so sánh với N. Gần với đề D02 (BCD) |
| Bắt tay `ready`/`valid` | ❌ | Không cần với bộ đếm |
| Đồng bộ hoá tín hiệu vào | ❌ | 2 tầng FF cho mỗi tín hiệu — **nghĩa vụ tầng ngoài**, xem §7 |

## 7. Nghĩa vụ hợp đồng của tầng ngoài

| Nghĩa vụ | Vì sao | Hậu quả nếu vi phạm |
|---|---|---|
| Giữ `rst_n = 0` qua ít nhất một cạnh lên đầy đủ | `dfxtp_1` không có chân reset; xoá chỉ xảy ra tại cạnh clock | 8 FF giữ `X` ở gate-level |
| **Bảo đảm clock đang chạy khi reset** | Reset **đồng bộ** — clock đứng yên thì reset vô tác dụng | Reset “không hoạt động”, rất khó gỡ lỗi |
| **Đồng bộ `enable` và `up` về miền `clk`** | RTL không có bộ đồng bộ. Bối cảnh Charter mục 1 là cảm biến vật lý trên băng chuyền — tức miền bất đồng bộ | Metastability có thể làm **nhiều bit** lấy giá trị khác nhau → `count` nhảy sang giá trị sai, không phải `±1` |
| **Tách cạnh trước khi đưa vào `enable`** | `enable` là **mức**, không phải xung. Mỗi chu kỳ có `enable = 1` là một lần đếm | Một sản phẩm che tia trong 1000 chu kỳ bị đếm thành **1000** |
| **Tự phát hiện quấn vòng** | Không có cờ tràn (`functional_spec.md` INV-9) | `255 → 0` trông giống hệt một lần reset |
| Không đổi `up` trong cùng chu kỳ mà `enable = 1` nếu chưa ổn định | `up → count[7]` là **đường tới hạn thật** | Vi phạm setup → `count` không xác định |
| **Tự nạp giá trị đầu bằng cách khác** | 🔴 Không có cổng `load` | Bối cảnh ứng dụng của Charter mục 1 (*“nạp giá trị đầu và đếm ngược”*) **không thực hiện được** |

Nghĩa vụ cuối là nghiêm trọng nhất: nó không phải một chi tiết tích hợp, mà là **một phần
chức năng của khối bị đẩy ra ngoài mà không có cơ chế nào thay thế**. Xem
`functional_spec.md` §0, W-2.

---

*Phiên bản: v1.0 · Ngày: 2026-09-24*
