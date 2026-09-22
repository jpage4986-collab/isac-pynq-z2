set repo_root [file normalize [file join [file dirname [info script]] ..]]
set build_root [file normalize [file join $repo_root .. build fft_roundtrip_sim]]
create_project fft_roundtrip_sim $build_root -part xc7z020clg400-1 -force
add_files [file join $repo_root fpga rtl fft64_axis_wrapper.v]
add_files [file join $repo_root fpga rtl cp_insert_axis.v]
add_files [file join $repo_root fpga rtl cp_remove_axis.v]
add_files [file join $repo_root fpga rtl isac_top.v]
add_files [file join $repo_root fpga rtl ofdm_frame_source.v]
add_files [file join $repo_root fpga rtl ofdm_frame_checker.v]
add_files -fileset sim_1 [file join $repo_root fpga tb tb_fft64_roundtrip.v]
create_ip -name xfft -vendor xilinx.com -library ip -version 9.1 -module_name xfft_64
set_property -dict [list CONFIG.transform_length {64} CONFIG.input_width {16} CONFIG.output_ordering {natural_order} CONFIG.throttle_scheme {nonrealtime} CONFIG.scaling_options {scaled} CONFIG.data_format {fixed_point} CONFIG.run_time_configurable_transform_length {false} CONFIG.aresetn {true}] [get_ips xfft_64]
generate_target all [get_ips xfft_64]
set_property top tb_fft64_roundtrip [get_filesets sim_1]
launch_simulation -mode behavioral
run all
close_sim
