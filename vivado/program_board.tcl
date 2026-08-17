set script_dir [file dirname [file normalize [info script]]]
set repo_root  [file normalize [file join $script_dir ..]]
set bit_file   [file join $repo_root build vivado output top_basys3.bit]

if {![file exists $bit_file]} {
    error "BITSTREAM_NOT_FOUND: run vivado/run_build.tcl first"
}

open_hw_manager
connect_hw_server
open_hw_target
set devices [get_hw_devices xc7a35t_0]
if {[llength $devices] == 0} {
    error "BASYS3_NOT_FOUND: check USB cable, power switch, and driver"
}
set device [lindex $devices 0]
current_hw_device $device
refresh_hw_device -update_hw_probes false $device
set_property PROGRAM.FILE $bit_file $device
program_hw_devices $device
puts "BOARD_PROGRAMMING_PASS: $bit_file"
close_hw_manager
exit
