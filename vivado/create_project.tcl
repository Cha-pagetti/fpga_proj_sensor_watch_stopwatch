# Create the Vivado project on the first run; reopen it in place on later runs
# so repeated builds don't discard synthesis/implementation run history.
set script_dir [file dirname [file normalize [info script]]]
set repo_root  [file normalize [file join $script_dir ..]]

set project_name UART_FIFO_Sensor_Watch_Stopwatch
set project_dir  [file join $repo_root build vivado $project_name]
set project_xpr  [file join $project_dir ${project_name}.xpr]
set expected_part xc7a35tcpg236-1

if {[llength [get_projects -quiet]] > 0} {
    close_project
}

if {[file isfile $project_xpr]} {
    open_project $project_xpr
} else {
    file mkdir $project_dir
    create_project $project_name $project_dir -part $expected_part
}

# Vivado warns while opening a project if its default generated-IP directory
# has not been materialized yet.
file mkdir [file join $project_dir ${project_name}.gen sources_1]

set actual_part [get_property PART [current_project]]
if {$actual_part ne $expected_part} {
    error "UNEXPECTED_FPGA_PART: expected=$expected_part actual=$actual_part"
}

set_property target_language Verilog [current_project]
set_property default_lib xil_defaultlib [current_project]
set_property simulator_language Mixed [current_project]
set_property target_simulator XSim [current_project]

source [file join $script_dir prepare_integration_sources.tcl]

set tb_files [list \
    [file join $repo_root tb tb_sr04_controller.v] \
    [file join $repo_root tb tb_control_unit.v] \
    [file join $repo_root tb tb_top_smoke.v] \
    [file join $repo_root tb tb_top_uart.v] \
    [file join $repo_root tb tb_top_sr04_uart.v]]
set constraint_file [file join $repo_root constraints Basys3.xdc]

foreach required_file [concat $integration_rtl_files $tb_files [list $constraint_file]] {
    if {![file isfile $required_file]} {
        error "REQUIRED_SOURCE_NOT_FOUND: $required_file"
    }
}

proc add_file_if_missing {fileset_name file_path} {
    set normalized_path [file normalize $file_path]
    foreach existing_file [get_files -quiet -of_objects [get_filesets $fileset_name]] {
        if {[file normalize [get_property NAME $existing_file]] eq $normalized_path} {
            return
        }
    }
    add_files -norecurse -fileset $fileset_name $normalized_path
}

foreach design_file $integration_rtl_files {
    add_file_if_missing sources_1 $design_file
}
foreach simulation_file $tb_files {
    add_file_if_missing sim_1 $simulation_file
}
add_file_if_missing constrs_1 $constraint_file

set_property top top [get_filesets sources_1]
set_property top tb_sr04_controller [get_filesets sim_1]
set_property xsim.simulate.runtime all [get_filesets sim_1]

update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

puts "PROJECT_READY: $project_xpr"
puts "DESIGN_TOP: [get_property top [get_filesets sources_1]]"
puts "SIMULATION_TOP: [get_property top [get_filesets sim_1]]"
puts "BOARD_PART: [get_property BOARD_PART [current_project]]"
