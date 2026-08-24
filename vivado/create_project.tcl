# Configure the existing Vivado 2020.2 GUI project in place. This script never
# creates a second project or replaces the user-created XPR.
set script_dir [file dirname [file normalize [info script]]]
set repo_root  [file normalize [file join $script_dir ..]]

set project_name 2026_08_16_UART_FIFO_Sensor_Watch_Stopwatch
set project_dir  [file join $repo_root build vivado $project_name]
set project_xpr  [file join $project_dir ${project_name}.xpr]
set expected_part xc7a35tcpg236-1

if {![file isfile $project_xpr]} {
    error "EXISTING_XPR_NOT_FOUND: $project_xpr"
}

if {[llength [get_projects -quiet]] > 0} {
    close_project
}
open_project $project_xpr

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

proc path_is_listed {file_path allowed_paths} {
    set normalized_path [file normalize $file_path]
    foreach allowed_path $allowed_paths {
        if {$normalized_path eq [file normalize $allowed_path]} {
            return 1
        }
    }
    return 0
}

# Remove stale generated copies and deleted sources from the project filesets.
# The source files themselves are never deleted.
foreach existing_file [get_files -quiet -of_objects [get_filesets sources_1]] {
    set existing_path [get_property NAME $existing_file]
    if {![path_is_listed $existing_path $integration_rtl_files]} {
        remove_files $existing_file
    }
}
foreach existing_file [get_files -quiet -of_objects [get_filesets sim_1]] {
    set existing_path [get_property NAME $existing_file]
    if {![path_is_listed $existing_path $tb_files]} {
        remove_files $existing_file
    }
}
foreach existing_file [get_files -quiet -of_objects [get_filesets constrs_1]] {
    set existing_path [get_property NAME $existing_file]
    if {![path_is_listed $existing_path [list $constraint_file]]} {
        remove_files $existing_file
    }
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

puts "EXISTING_PROJECT_READY: $project_xpr"
puts "DESIGN_TOP: [get_property top [get_filesets sources_1]]"
puts "SIMULATION_TOP: [get_property top [get_filesets sim_1]]"
puts "BOARD_PART: [get_property BOARD_PART [current_project]]"
