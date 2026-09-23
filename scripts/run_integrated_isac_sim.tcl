set repo_root [file normalize [file join [file dirname [info script]] ..]]
set sim_root [file normalize [file join $repo_root .. build integrated_isac_sim]]
file mkdir $sim_root
create_project integrated_isac_sim $sim_root -part xc7z020clg400-1 -force
foreach name {isac_integrated_top ofdm_frame_source ofdm_frame_checker digital_delay_channel_axis axis_complex_rotator vibration_phasor_q14 delay5_equalizer_axis ofdm_training_broadcaster training_channel_estimator_axis range_peak_detector range_gate_sampler slow_time_sampler slow_phase_product cp_insert_axis cp_remove_axis fft64_axis_wrapper} {
    add_files [file join $repo_root fpga rtl ${name}.v]
}
create_ip -name xfft -vendor xilinx.com -library ip -version 9.1 -module_name xfft_64
set_property -dict [list CONFIG.transform_length {64} CONFIG.input_width {16} CONFIG.output_ordering {natural_order} CONFIG.throttle_scheme {nonrealtime} CONFIG.scaling_options {scaled} CONFIG.data_format {fixed_point} CONFIG.run_time_configurable_transform_length {false} CONFIG.aresetn {true}] [get_ips xfft_64]
generate_target all [get_ips xfft_64]
add_files -fileset sim_1 [file join $repo_root fpga tb tb_isac_integrated.v]
add_files -fileset sim_1 [file join $repo_root fpga tb tb_isac_dynamic.v]
set_property top tb_isac_integrated [get_filesets sim_1]
update_compile_order -fileset sim_1
launch_simulation
run all
close_sim
set sim_log [file join $sim_root integrated_isac_sim.sim sim_1 behav xsim simulate.log]
set stream [open $sim_log r]
set output [read $stream]
close $stream
if {![string match {*PASS integrated ISAC*} $output] || [string match {*Fatal:*} $output]} {
    error "Static integrated simulation did not pass: $sim_log"
}
set_property top tb_isac_dynamic [get_filesets sim_1]
update_compile_order -fileset sim_1
launch_simulation
run all
close_sim
set stream [open $sim_log r]
set output [read $stream]
close $stream
if {![string match {*PASS dynamic ISAC*} $output] || [string match {*Fatal:*} $output]} {
    error "Dynamic integrated simulation did not pass: $sim_log"
}
puts "INTEGRATED_ISAC_SIM=PASS"
