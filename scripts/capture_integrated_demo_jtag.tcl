# Program the integrated demo and export its ILA observation to CSV.
set repo_root [file normalize [file join [file dirname [info script]] ..]]
set build_root [file normalize [file join $repo_root .. build pynq_z2_integrated_demo_jtag]]
set bitstream [file join $build_root pynq_z2_integrated_demo_jtag.runs impl_1 isac_integrated_top.bit]
set probes [file join $build_root isac_integrated_top.ltx]
set csv [file join $build_root integrated_capture.csv]
foreach path [list $bitstream $probes] {
    if {![file exists $path]} { error "Required build artifact missing: $path" }
}

open_hw_manager
connect_hw_server -url localhost:3121
open_hw_target
set device [lindex [get_hw_devices xc7z020_1] 0]
if {$device eq ""} { error "xc7z020 device not found. Check USB-JTAG and board power." }
current_hw_device $device
set_property PROGRAM.FILE $bitstream $device
set_property PROBES.FILE $probes $device
program_hw_devices $device
refresh_hw_device $device
set ila [lindex [get_hw_ilas] 0]
if {$ila eq ""} { error "ILA was not discovered after programming." }
run_hw_ila -trigger_now $ila
wait_on_hw_ila -timeout 0.5 $ila
set data [upload_hw_ila_data $ila]
write_hw_ila_data -force -csv_file $csv $data
puts "CAPTURE_CSV=$csv"

# A 1024-cycle ILA window is only 8.2 us at 125 MHz, while the structural
# vibration is sampled at 100 Hz. Take spaced snapshots so the slow sample
# counter and target-gate phase can be observed on the actual board.
for {set index 0} {$index < 12} {incr index} {
    after 100
    run_hw_ila -trigger_now $ila
    wait_on_hw_ila -timeout 0.5 $ila
    set data [upload_hw_ila_data $ila]
    set spaced_csv [file join $build_root [format {integrated_slow_%02d.csv} $index]]
    write_hw_ila_data -force -csv_file $spaced_csv $data
    puts "SLOW_CAPTURE_CSV=$spaced_csv"
}
