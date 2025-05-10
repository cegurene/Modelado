## Clock signal
set_property -dict {PACKAGE_PIN E3 IOSTANDARD LVCMOS33} [get_ports clk]
create_clock -period 10.000 -name sys_clk_pin -waveform {0.000 5.000} -add [get_ports clk]

#RST
set_property -dict {PACKAGE_PIN M18 IOSTANDARD LVCMOS33} [get_ports rst]


## Rx
set_property -dict {PACKAGE_PIN C4 IOSTANDARD LVCMOS33} [get_ports rx]
# leds
set_property -dict {PACKAGE_PIN V11 IOSTANDARD LVCMOS33} [get_ports error_recep]



#pulsador sw_ok
set_property -dict {PACKAGE_PIN P18 IOSTANDARD LVCMOS33} [get_ports DATO_RX_OK]






