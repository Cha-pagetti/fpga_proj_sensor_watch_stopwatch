set script_dir [file dirname [file normalize [info script]]]
set repo_root  [file normalize [file join $script_dir ..]]
set output_dir [file join $repo_root build vivado output]
set report_dir [file join $repo_root build vivado reports]
file mkdir $output_dir
file mkdir $report_dir

source [file join $script_dir create_project.tcl]

reset_run synth_1
launch_runs synth_1 -jobs 4
wait_on_run synth_1
set synth_status [get_property STATUS [get_runs synth_1]]
if {![string match "*Complete*" $synth_status]} {
    error "SYNTHESIS_FAILED: $synth_status"
}

open_run synth_1
report_utilization -file [file join $report_dir post_synth_utilization.rpt]
report_timing_summary -file [file join $report_dir post_synth_timing.rpt]
report_clocks -file [file join $report_dir post_synth_clocks.rpt]
write_checkpoint -force [file join $report_dir top_post_synth.dcp]
close_design

reset_run impl_1
launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1
set impl_status [get_property STATUS [get_runs impl_1]]
if {![string match "*Complete*" $impl_status]} {
    error "IMPLEMENTATION_FAILED: $impl_status"
}

open_run impl_1
report_utilization -file [file join $report_dir post_impl_utilization.rpt]
report_timing_summary -delay_type min_max -report_unconstrained -check_timing_verbose \
    -max_paths 10 -file [file join $report_dir post_impl_timing_summary.rpt]
report_route_status -file [file join $report_dir post_impl_route_status.rpt]
report_drc -file [file join $report_dir post_impl_drc.rpt]
report_io -file [file join $report_dir post_impl_io.rpt]
report_power -file [file join $report_dir post_impl_power.rpt]
write_checkpoint -force [file join $report_dir top_post_route.dcp]

set bit_files [glob -nocomplain [file join $project_dir ${project_name}.runs impl_1 *.bit]]
if {[llength $bit_files] != 1} {
    error "BITSTREAM_NOT_FOUND: $bit_files"
}
file copy -force [lindex $bit_files 0] [file join $output_dir top_basys3.bit]

puts "SYNTHESIS_STATUS: $synth_status"
puts "IMPLEMENTATION_STATUS: $impl_status"
puts "BITSTREAM_READY: [file join $output_dir top_basys3.bit]"
exit
