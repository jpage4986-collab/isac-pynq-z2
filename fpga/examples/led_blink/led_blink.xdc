# PYNQ-Z2 125 MHz PL clock, BTN0 (active high), and user LED0.
set_property -dict { PACKAGE_PIN H16 IOSTANDARD LVCMOS33 } [get_ports { clk }]
create_clock -period 8.000 -name clk [get_ports { clk }]

set_property -dict { PACKAGE_PIN D19 IOSTANDARD LVCMOS33 } [get_ports { btn0 }]
set_property -dict { PACKAGE_PIN R14 IOSTANDARD LVCMOS33 } [get_ports { led0 }]
