# Program the connected PYNQ-Z2 with the self-contained range demonstration.
set bitstream [file normalize [file join [file dirname [info script]] .. .. build pynq_z2_range_demo pynq_z2_range_demo.runs impl_1 range_demo_top.bit]]
if {![file exists $bitstream]} { error "Bitstream not found: $bitstream" }

open_hw_manager
connect_hw_server -url localhost:3121
open_hw_target
set device [lindex [get_hw_devices xc7z020_1] 0]
if {$device eq ""} { error "xc7z020 device not found. Check USB-JTAG connection." }
current_hw_device $device
refresh_hw_device $device
set_property PROGRAM.FILE $bitstream $device
program_hw_devices $device
refresh_hw_device $device
puts "PROGRAMMED=$bitstream"
