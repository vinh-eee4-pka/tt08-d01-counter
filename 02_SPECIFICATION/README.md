# 02. Đặc tả kỹ thuật (Specification)

## 1. Chuẩn giao tiếp I/O (Tiny Tapeout 08)
- ui[7:0]: Input Bus 8-bit (ui[0]=en, ui[1]=up_down, ui[2]=load)
- uio[7:0]: Bidirectional Bus (cấu hình Input d_in[7:0])
- uo[7:0]: Output Bus 8-bit (giá trị count[7:0])

## 2. Đặc tính thời gian
- Hoạt động đồng bộ theo sườn lên xung nhịp clk (posedge clk).
- Reset bất đồng bộ tích cực mức thấp (negedge rst_n).
