set repo_root [file normalize [file join [file dirname [info script]] ..]]
set sim_root [file normalize [file join $repo_root .. build training_range_sim]]
file mkdir $sim_root
create_project training_range_sim $sim_root -part xc7z020clg400-1 -force
foreach name {digital_delay_channel_axis training_channel_estimator_axis range_peak_detector cp_insert_axis cp_remove_axis fft64_axis_wrapper} {
    add_files [file join $repo_root fpga rtl ${name}.v]
}
create_ip -name xfft -vendor xilinx.com -library ip -version 9.1 -module_name xfft_64
set_property -dict [list CONFIG.transform_length {64} CONFIG.input_width {16} CONFIG.output_ordering {natural_order} CONFIG.throttle_scheme {nonrealtime} CONFIG.scaling_options {scaled} CONFIG.data_format {fixed_point} CONFIG.run_time_configurable_transform_length {false} CONFIG.aresetn {true}] [get_ips xfft_64]
generate_target all [get_ips xfft_64]
add_files -fileset sim_1 [file join $repo_root fpga tb tb_training_range_peak.v]
set_property top tb_training_range_peak [get_filesets sim_1]
update_compile_order -fileset sim_1
launch_simulation
run all
close_sim
puts "TRAINING_RANGE_SIM=PASS"
