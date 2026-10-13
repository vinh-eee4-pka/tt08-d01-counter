# 03. Kiến trúc thiết kế (Architecture)

## 1. Sơ đồ khối tổng quan (Block Diagram)

```text
                 +---------------------------------------+
                 |          tt_um_d01_counter            |
                 |                                       |
    clk -------->|                                       |
  rst_n -------->|  +---------------+   +-------------+  |
                 |  | Control Unit  |   | Datapath    |  |
     en -------->|->| (Mode Select) |-->|  (8-bit MUX |->|===> uo[7:0] (count[7:0])
up_down -------->|  +---------------+   |  + Register)|  |
   load -------->|                      +-------------+  |
                 |                             ^         |
 uio[7:0] ------->|=============================+         |
(d_in[7:0])      +---------------------------------------+
```

## 2. Các khối chức năng chính
- **Next-State Logic MUX Network:** Mạch tổ hợp chọn giá trị tiếp theo cho bộ đếm dựa trên các tín hiệu điều khiển.
- **8-Bit Register:** Lưu giữ trạng thái đếm hiện tại, cập nhật đồng bộ tại `posedge clk` hoặc xóa về `0` khi `negedge rst_n`.
