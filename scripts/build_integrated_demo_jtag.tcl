# Build the integrated OFDM communication-and-sensing demo with an ILA.
# The probes make the board acceptance result reproducible: they observe both
# the communication hard-decision counters and the sensing range result.
set repo_root [file normalize [file join [file dirname [info script]] ..]]
set build_root [file normalize [file join $repo_root .. build pynq_z2_integrated_demo_jtag]]
file mkdir $build_root

create_project pynq_z2_integrated_demo_jtag $build_root -part xc7z020clg400-1 -force
foreach name {isac_integrated_top ofdm_frame_source ofdm_frame_checker digital_delay_channel_axis axis_complex_rotator delay5_equalizer_axis ofdm_training_broadcaster training_channel_estimator_axis range_peak_detector cp_insert_axis cp_remove_axis fft64_axis_wrapper} {
    add_files [file join $repo_root fpga rtl ${name}.v]
}
create_ip -name xfft -vendor xilinx.com -library ip -version 9.1 -module_name xfft_64
set_property -dict [list CONFIG.transform_length {64} CONFIG.input_width {16} CONFIG.output_ordering {natural_order} CONFIG.throttle_scheme {nonrealtime} CONFIG.scaling_options {scaled} CONFIG.data_format {fixed_point} CONFIG.run_time_configurable_transform_length {false} CONFIG.aresetn {true}] [get_ips xfft_64]
generate_target all [get_ips xfft_64]
set local_xdc [file join $build_root pynq_z2_integrated_demo_jtag.xdc]
file copy -force [file join $repo_root fpga constraints pynq_z2.xdc] $local_xdc
add_files -fileset constrs_1 $local_xdc
set_property top isac_integrated_top [current_fileset]
update_compile_order -fileset sources_1

launch_runs synth_1 -jobs 4
wait_on_run synth_1
if {![string match {*Complete*} [get_property STATUS [get_runs synth_1]]]} {
    error "Synthesis failed: [get_property STATUS [get_runs synth_1]]"
}
open_run synth_1

create_debug_core u_integrated_ila ila
set_property C_DATA_DEPTH 1024 [get_debug_cores u_integrated_ila]
set clk_net [get_nets clk_IBUF_BUFG]
if {[llength $clk_net] != 1} { error "ILA clock net not found uniquely: $clk_net" }
connect_debug_port u_integrated_ila/clk $clk_net

set probe_index 0
foreach {signal width} {frame_count 32 data_frame_count 32 bit_count 32 bit_errors 32 range_frame_valid 1 peak_bin 6 peak_magnitude 17} {
    if {$probe_index > 0} { create_debug_port u_integrated_ila probe }
    set port [get_debug_ports u_integrated_ila/probe${probe_index}]
    set_property port_width $width $port
    if {$width == 1} {
        set nets [get_nets $signal]
    } else {
        set nets {}
        for {set bit 0} {$bit < $width} {incr bit} {
            set net [get_nets [format {%s[%d]} $signal $bit]]
            if {[llength $net] != 1} { error "Net not found uniquely: $signal bit $bit: $net" }
            lappend nets $net
        }
    }
    if {[llength $nets] != $width} { error "Net width mismatch for $signal: $nets" }
    connect_debug_port $port $nets
    incr probe_index
}

save_constraints -force
set_property NEEDS_REFRESH false [get_runs synth_1]
launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1
if {![string match {*Complete*} [get_property STATUS [get_runs impl_1]]]} {
    error "Implementation failed: [get_property STATUS [get_runs impl_1]]"
}
open_run impl_1
set bitstream [file join $build_root pynq_z2_integrated_demo_jtag.runs impl_1 isac_integrated_top.bit]
set probes [file join $build_root isac_integrated_top.ltx]
write_debug_probes -force $probes
puts "BITSTREAM=$bitstream"
puts "PROBES=$probes"
