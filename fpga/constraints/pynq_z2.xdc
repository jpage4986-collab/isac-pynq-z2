# PYNQ-Z2 125 MHz 时钟
set_property -dict {PACKAGE_PIN H16 IOSTANDARD LVCMOS33} [get_ports clk]
create_clock -name sys_clk -period 8.000 [get_ports clk]

# PYNQ-Z2 按键 BTN0，低电平复位
set_property -dict {PACKAGE_PIN D19 IOSTANDARD LVCMOS33} [get_ports rst_n]

# PYNQ-Z2 LED0
set_property -dict {PACKAGE_PIN R14 IOSTANDARD LVCMOS33} [get_ports led0]