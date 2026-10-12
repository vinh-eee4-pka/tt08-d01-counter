# Khai báo Clock hệ thống 100MHz (Chu kỳ 10ns)
create_clock -name clk -period 10.000 [get_ports clk]

# Độ không đảm bảo xung nhịp (Clock Uncertainty)
set_clock_uncertainty 0.200 [get_clocks clk]

# Ràng buộc thời gian cho cổng ngõ vào và ngõ ra
set_input_delay  -clock clk 2.000 [remove_from_collection [all_inputs] [get_ports clk]]
set_output_delay -clock clk 2.000 [all_outputs]

# Bỏ qua phân tích timing cho chân Reset bất đồng bộ
set_false_path -from [get_ports rst_n]