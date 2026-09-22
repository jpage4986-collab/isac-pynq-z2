# PYNQ-Z2 125 MHz 时钟
set_property -dict {PACKAGE_PIN H16 IOSTANDARD LVCMOS33} [get_ports clk]
create_clock -name sys_clk -period 8.000 [get_ports clk]

# PYNQ-Z2 BTN0: pressed = high, reset while held
set_property -dict {PACKAGE_PIN D19 IOSTANDARD LVCMOS33} [get_ports btn0]

# PYNQ-Z2 LED0
set_property -dict {PACKAGE_PIN R14 IOSTANDARD LVCMOS33} [get_ports led0]
set_property -dict {PACKAGE_PIN P14 IOSTANDARD LVCMOS33} [get_ports led1]
set_property -dict {PACKAGE_PIN N16 IOSTANDARD LVCMOS33} [get_ports led2]
set_property -dict {PACKAGE_PIN M14 IOSTANDARD LVCMOS33} [get_ports led3]
