# Build the self-contained 5-bin digital-target range demo for PYNQ-Z2.
set repo_root [file normalize [file join [file dirname [info script]] ..]]
set build_root [file normalize [file join $repo_root .. build pynq_z2_range_demo]]
file mkdir $build_root

create_project pynq_z2_range_demo $build_root -part xc7z020clg400-1 -force
foreach name {range_demo_top training_frame_source digital_delay_channel_axis training_channel_estimator_axis range_peak_detector cp_insert_axis cp_remove_axis fft64_axis_wrapper} {
    add_files [file join $repo_root fpga rtl ${name}.v]
}
create_ip -name xfft -vendor xilinx.com -library ip -version 9.1 -module_name xfft_64
set_property -dict [list CONFIG.transform_length {64} CONFIG.input_width {16} CONFIG.output_ordering {natural_order} CONFIG.throttle_scheme {nonrealtime} CONFIG.scaling_options {scaled} CONFIG.data_format {fixed_point} CONFIG.run_time_configurable_transform_length {false} CONFIG.aresetn {true}] [get_ips xfft_64]
generate_target all [get_ips xfft_64]
add_files -fileset constrs_1 [file join $repo_root fpga constraints pynq_z2.xdc]
set_property top range_demo_top [current_fileset]
update_compile_order -fileset sources_1

launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1
set run_status [get_property STATUS [get_runs impl_1]]
if {![string match {*Complete*} $run_status]} {
    error "Implementation failed: $run_status"
}
puts "BITSTREAM=[file join $build_root pynq_z2_range_demo.runs impl_1 range_demo_top.bit]"
