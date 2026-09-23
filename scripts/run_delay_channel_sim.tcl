set repo_root [file normalize [file join [file dirname [info script]] ..]]
set sim_root [file normalize [file join $repo_root .. build delay_channel_sim]]
file mkdir $sim_root
create_project delay_channel_sim $sim_root -part xc7z020clg400-1 -force
add_files [file join $repo_root fpga rtl digital_delay_channel_axis.v]
add_files [file join $repo_root fpga rtl cp_insert_axis.v]
add_files [file join $repo_root fpga rtl cp_remove_axis.v]
add_files [file join $repo_root fpga rtl fft64_axis_wrapper.v]
create_ip -name xfft -vendor xilinx.com -library ip -version 9.1 -module_name xfft_64
set_property -dict [list CONFIG.transform_length {64} CONFIG.input_width {16} CONFIG.output_ordering {natural_order} CONFIG.throttle_scheme {nonrealtime} CONFIG.scaling_options {scaled} CONFIG.data_format {fixed_point} CONFIG.run_time_configurable_transform_length {false} CONFIG.aresetn {true}] [get_ips xfft_64]
generate_target all [get_ips xfft_64]
add_files -fileset sim_1 [file join $repo_root fpga tb tb_digital_delay_channel.v]
add_files -fileset sim_1 [file join $repo_root fpga tb tb_delay_fft.v]
set_property top tb_digital_delay_channel [get_filesets sim_1]
update_compile_order -fileset sim_1
launch_simulation
run all
close_sim
set_property top tb_delay_fft [get_filesets sim_1]
update_compile_order -fileset sim_1
launch_simulation
run all
close_sim
puts "DELAY_CHANNEL_SIM=PASS"
