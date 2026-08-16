set script_dir [file dirname [file normalize [info script]]]
set repo_root  [file normalize [file join $script_dir ..]]
set build_root [file join $repo_root build vivado]
set project_dir [file join $build_root project]
set project_name fpga_sensor_watch

file mkdir $build_root
source [file join $script_dir prepare_integration_sources.tcl]
create_project -force $project_name $project_dir -part xc7a35tcpg236-1

set_property target_language Verilog [current_project]
set_property default_lib xil_defaultlib [current_project]
set_property simulator_language Mixed [current_project]
set_property target_simulator XSim [current_project]

set tb_files [list \
    [file join $repo_root tb tb_control_unit.v] \
    [file join $repo_root tb tb_sr04_controller.v] \
    [file join $repo_root tb tb_top_smoke.v] \
    [file join $repo_root tb tb_top_uart.v] \
    [file join $repo_root tb tb_top_sr04_uart.v]]
add_files -fileset sources_1 $integration_rtl_files
add_files -fileset sim_1 $tb_files
add_files -fileset constrs_1 [file join $repo_root constraints Basys3.xdc]

set_property top top [get_filesets sources_1]
set_property top tb_top_uart [get_filesets sim_1]
set_property xsim.simulate.runtime all [get_filesets sim_1]

update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

puts "PROJECT_READY: [file join $project_dir ${project_name}.xpr]"
