# 04. Triển khai thiết kế (Implementation)

## 1. Mã nguồn RTL Verilog
Mã nguồn thiết kế vi mạch chính nằm tại: `src/tt_um_d01_counter.v`.

## 2. File cấu hình Tiny Tapeout
File cấu hình tổng hợp vi mạch nằm tại: `info.yaml` (sử dụng `yaml_version: 6`).

## 3. Quy trình đóng gói vi mạch
Dự án được tự động tổng hợp layout vi mạch (GDSII) thông qua luồng **OpenLane CI/CD** trên GitHub Actions.
