# D01 · Sơ đồ khối bên trong (Block Diagram)

Vẽ theo **đúng 20 dòng** của `04_IMPLEMENTATION/rtl/d01_core.sv`, đối chiếu từng cell với
`06_GDSII/synthesis/netlist.v` và `06_GDSII/sta/timing_report_max.txt`.

---

## 1. Sơ đồ ASCII

```
                    ┌──────────── PHẦN TỔ HỢP (đường D) ─────────────────┐
                    │                                                     │
   up ─────────────▶│  ┌──────────────────────────────────────┐          │
                    │  │  MẠCH TĂNG/GIẢM 8 BIT                │          │
   count[7:0] ═════▶│  │  up ? count+1 : count−1               │          │
     (hồi tiếp từ Q)│  │  chuỗi carry/mượn đã được abc         │          │
                    │  │  ánh xạ lại thành cây (xem §4)        │          │
                    │  │  → 7×xnor2_1, 2×xor2_1, 3×nor4_1,     │          │
                    │  │    3×nor3_1, 2×mux2i_1, …             │          │
                    │  └───────────────┬──────────────────────┘          │
                    │                  ║ 8 bit                            │
                    │                  ║                                  │
   enable ─────────▶│  ┌───────────────▼──────────────────────┐          │
                    │  │  MUX GIỮ/ĐẾM  (8 bit)                │          │
   count[7:0] ═════▶│  │  enable ? giá_trị_mới : count        │          │
     (hồi tiếp)     │  │  → 5 × o21ai_0 (gộp vào cổng phức)   │          │
                    │  └───────────────┬──────────────────────┘          │
                    │                  ║ 8 bit                            │
                    │                  ║                                  │
   rst_n ──────────▶│  ┌───────────────▼──────────────────────┐          │
                    │  │  CỔNG CHẶN XOÁ ĐỒNG BỘ (8 bit)       │          │
                    │  │  rst_n ? giá_trị : 0                 │          │
                    │  │  → 7 × and2_0 (.A = rst_n)           │          │
                    │  │  + 1 × lpflow_isobufsrc_1 (bit 1)    │          │
                    │  └───────────────┬──────────────────────┘          │
                    └──────────────────╫──────────────────────────────────┘
                                       ║ D[7:0]
     clk ─────────────────────┐        ║
                              ▼        ▼
            ┌──────────────────────────────────────────┐
            │  THANH GHI ĐẾM · 8 × dfxtp_1             │
            │  _82_ _83_ _84_ _85_ _86_ _87_ _88_ _89_ │
            │   ↓    ↓    ↓    ↓    ↓    ↓    ↓    ↓   │
            │  cnt0 cnt1 cnt2 cnt3 cnt4 cnt5 cnt6 cnt7 │
            │                                    ▲      │
            │                        ENDPOINT tới hạn   │
            └───────────────────┬──────────────────────┘
                                ║
                                ╠═══════════════════▶ count[7:0]  (cổng ra)
                                ║
                                ╚════════ hồi tiếp về mạch tăng/giảm và mux giữ

     🔴 THIẾU: tầng MUX NẠP (load ? load_val : …) đáng lẽ nằm giữa
        "MUX GIỮ/ĐẾM" và "CỔNG CHẶN XOÁ" — xem functional_spec.md §9

  Tổng ô nhớ: 8   ✓ khớp synth_stat.txt (dfxtp_1 × 8)
```

**Ba tầng chọn xếp chồng trên đường `D`** — và thứ tự xếp chồng **chính là** thứ tự ưu tiên:

```
   tầng trong cùng  : tăng/giảm      (ưu tiên thấp nhất — `up`)
   tầng giữa        : giữ hay đếm    (`enable`)
   tầng ngoài cùng  : xoá            (ưu tiên cao nhất — `rst_n`, sát flip-flop nhất)
```

Đây là cách đọc ưu tiên **từ netlist** thay vì từ mã nguồn: tín hiệu nào nằm gần flip-flop
nhất thì thắng. Bằng chứng trực tiếp trong netlist — cell cuối cùng trước mỗi flip-flop là
`and2_0` với `.A(rst_n)`:

```verilog
sky130_fd_sc_hd__and2_0 _81_ ( .A(rst_n), .B(_40_), .X(_07_) );
sky130_fd_sc_hd__dfxtp_1 _89_ ( .CLK(clk), .D(_07_), .Q(count[7]) );
```

## 2. Ánh xạ cấu trúc RTL → phần cứng sinh ra

| Dòng RTL | Cấu trúc | Phần cứng sinh ra | Bằng chứng netlist |
|---|---|---|---|
| 7 | `always_ff @(posedge clk)` | 8 flip-flop kích cạnh lên | `dfxtp_1 × 8` (`_82_`…`_89_`) |
| 8 | `if (!rst_n)` **không có** `posedge rst_n` | **Xoá đồng bộ**: `rst_n` đi vào cửa tổ hợp trên đường `D` | `and2_0 × 7` với `.A(rst_n)` + `lpflow_isobufsrc_1 _48_` với `.A(rst_n), .SLEEP(_13_)`. FF là `dfxtp_1` — **không có chân reset** |
| 10 | `else if (enable)` | Mux giữ/đếm 8 bit, gộp vào cổng phức | `o21ai_0 × 5`; trên đường tới hạn, `_79_ o21ai_0` có chân `.B1(enable)` |
| 11–14 | `if (up) count+1 else count-1` | **Một** mạch tăng/giảm có chọn chiều, không phải hai mạch riêng | `xnor2_1 × 7` + `xor2_1 × 2` sinh bit tổng; `mux2i_1 × 2` chọn chiều ở vài bit; `nor4_1 × 3`, `nor3_1 × 3`, `nor4b_1`, `or4_1`, `nand4_1` tạo **cây carry/mượn** |
| 11 vs 13 | Hai biểu thức số học dùng chung `count` | Chuỗi carry và chuỗi mượn **chia sẻ phần lớn logic** — `up` chỉ là một tín hiệu vào của cùng một cây | Tổng chỉ 49 cell; hai mạch cộng/trừ 8 bit riêng biệt sẽ tốn nhiều hơn đáng kể |

> 🔎 **Điểm đáng chú ý nhất của bảng trên:** RTL viết hai biểu thức riêng (`count + 1` và
> `count - 1`) nhưng Yosys/abc **không** dựng hai mạch. Vì `−1` bằng `+ 0xFF` trong số học
> modulo 256, cả hai phép đều là “cộng với hằng số”, và hai hằng số đó chỉ khác nhau ở giá
> trị các bit. `up` trở thành một **đầu vào dữ liệu của cùng một cây carry**, không phải một
> tín hiệu chọn giữa hai cây. Đó là lý do một bộ đếm lên/xuống 8 bit chỉ tốn 49 cell.

## 3. Bằng chứng cấu trúc cho “xoá ĐỒNG BỘ” — trả lời Charter mục 2 câu 2

Đây là câu hỏi Charter đặt ra và D01 trả lời được bằng bằng chứng netlist cụ thể nhất trong
cả bộ hồ sơ.

| | **Xoá ĐỒNG BỘ (D01 đang dùng)** | Xoá BẤT ĐỒNG BỘ |
|---|---|---|
| Mã RTL | `always_ff @(posedge clk)` + `if (!rst_n)` | `always_ff @(posedge clk or negedge rst_n)` |
| Cell flip-flop được chọn | **`sky130_fd_sc_hd__dfxtp_1`** — chân `CLK`, `D`, `Q` · **không có chân reset** | `sky130_fd_sc_hd__dfrtp_1` — thêm chân **`RESET_B`** |
| `rst_n` xuất hiện ở đâu trong netlist | **Trong cụm logic tổ hợp trên đường `D`** — 7 × `and2_0(.A(rst_n), .B(giá_trị_mới))` + 1 × `lpflow_isobufsrc_1` | **Trên chân `RESET_B` của từng FF**, không xuất hiện trong cụm `D` |
| Chi phí logic tổ hợp | **+8 cell** (≈ **16 %** của 49 cell) | 0 cell thêm, nhưng cell FF lớn hơn |
| Tác dụng khi clock **đứng yên** | **KHÔNG xoá được** | **Xoá ngay**, không cần clock |
| Ràng buộc timing của `rst_n` | Setup/hold bình thường như một tín hiệu dữ liệu | Cần **recovery/removal** — kiểm tra riêng trong STA |
| `rst_n` có nằm trên đường tới hạn không | **Có** — nó là cell cuối cùng (`_81_`) trước flip-thay `_89_` | Không |

**Cách kiểm trong 10 giây, dùng được cho mọi đề:** mở `synth_stat.txt`, xem tên cell tuần
tự. Thấy `dfxtp_1` (không hậu tố `r`/`s`) ⇒ reset **đồng bộ** hoặc không có reset. Thấy
`dfrtp_1`, `dfstp_1`, `dfbbn_1` ⇒ có chân reset/set **bất đồng bộ**.

Ở D01: `synth_stat.txt` chỉ có `sky130_fd_sc_hd__dfxtp_1 8` ⇒ **xoá đồng bộ**, xác nhận.

## 4. Khối con nào nằm trên đường tới hạn

Đối chiếu với `06_GDSII/sta/timing_report_max.txt` (6 cell, `up → _89_`, arrival 1,64 ns,
required 9,88 ns, slack 8,24 ns):

| # | Instance | Cell | Chân/đầu vào thật | Thuộc khối con | Delay tích luỹ |
|---:|---|---|---|---|---:|
| — | `up` | cổng vào (fanout **10**) | — | — | 1,00 ns *(là `set_input_delay` giả định)* |
| 1 | `_65_` | `nor2_1` | `.A(count[4])`, `.B(up)` | **Cây carry/mượn** — tầng đầu | 1,05 ns |
| 2 | `_77_` | `nor4b_1` | `.A(count[6])`, `.B(count[5])`, `.C(_22_)`, `.D_N(_27_)` | **Cây carry — gom 4 tín hiệu trong 1 cell** | 1,24 ns |
| 3 | `_79_` | `o21ai_0` | `.A1(_37_)`, `.A2(_38_)`, `.B1(**enable**)` | **MUX giữ/đếm** | 1,38 ns |
| 4 | `_80_` | `xnor2_1` | `.A(count[7])`, `.B(_39_)` | Bit tổng của bit 7 | 1,51 ns |
| 5 | `_81_` | `and2_0` | `.A(**rst_n**)`, `.B(_40_)` | **CỔNG CHẶN XOÁ ĐỒNG BỘ** | 1,64 ns |
| 6 | `_89_` | `dfxtp_1` | `.D(_07_)`, `.Q(count[7])` | Thanh ghi đếm, bit 7 | setup 0,12 ns |

**Đọc được ba điều từ bảng này:**

1. **Chỉ 5 cell logic cho MSB của một bộ đếm 8 bit.** Một bộ đếm ripple “sách giáo khoa”
   cần carry lan qua 8 tầng. Ở đây `abc` đã ánh xạ lại thành **cây**: cell `_77_ nor4b_1`
   gom **bốn** tín hiệu (`count[6]`, `count[5]`, và hai mạng trung gian) trong **một** cell.
   Đây là khác biệt cốt lõi so với A01 (bộ cộng ripple-carry 8 tầng tường minh): ở A01 cấu
   trúc bị RTL **ép** phải là ripple, còn ở D01 RTL viết bằng toán tử `+`/`-` nên công cụ
   được tự do chọn cấu trúc — và nó chọn cây.
2. **Ba tầng ưu tiên hiện ra đúng thứ tự trên đường tới hạn.** Cell 1–2 là đếm (`up`), cell
   3 là giữ (`enable`), cell 5 là xoá (`rst_n`) — càng ưu tiên cao càng gần flip-flop.
   Netlist **tự kể lại** bảng ưu tiên của đặc tả.
3. **Xoá đồng bộ nằm trên đường tới hạn.** Cell `_81_` cộng 0,13 ns — khoảng **20 %** của
   0,64 ns độ trễ logic. Nếu dùng reset bất đồng bộ, cell này biến mất khỏi đường `D` nhưng
   đổi lại phải kiểm recovery/removal. Đó là đánh đổi thật, có số đo.

**Khối con KHÔNG trên đường tới hạn:** các bit thấp (`count[0]` chỉ cần một phép đảo — đây
lại là ứng viên số 1 cho vi phạm **hold**, xem `corner_cases.md` §6).

---

*Phiên bản: v1.0 · Ngày: 2026-09-24*
