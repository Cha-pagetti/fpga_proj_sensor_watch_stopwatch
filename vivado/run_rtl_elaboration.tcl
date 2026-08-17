set script_dir [file dirname [file normalize [info script]]]
set repo_root  [file normalize [file join $script_dir ..]]
set report_dir [file join $repo_root build vivado reports]
file mkdir $report_dir

source [file join $script_dir prepare_integration_sources.tcl]

foreach rtl_file $integration_rtl_files {
    read_verilog $rtl_file
}

synth_design -rtl -top top -part xc7a35tcpg236-1 -name rtl_1
read_xdc [file join $repo_root constraints Basys3.xdc]
write_checkpoint -force [file join $report_dir top_rtl_elaborated.dcp]
report_io -file [file join $report_dir rtl_io.rpt]
report_clocks -file [file join $report_dir rtl_clocks.rpt]
puts "RTL_ELABORATION_PASS"
exit
