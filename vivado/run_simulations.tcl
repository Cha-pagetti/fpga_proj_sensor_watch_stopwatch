# Run the five required XSim behavioral simulations against the existing GUI
# project. Per-test compile, elaboration, and simulation logs are preserved.
set script_dir [file dirname [file normalize [info script]]]
set repo_root  [file normalize [file join $script_dir ..]]
set report_dir [file join $repo_root build vivado simulation_logs]
file mkdir $report_dir

source [file join $script_dir create_project.tcl]

proc read_text_if_present {path} {
    if {![file isfile $path]} {
        return ""
    }
    set handle [open $path r]
    set data [read $handle]
    close $handle
    return $data
}

proc archive_log {source_path destination_path} {
    if {[file isfile $source_path]} {
        file copy -force $source_path $destination_path
    }
}

set test_tops {
    tb_sr04_controller
    tb_control_unit
    tb_top_smoke
    tb_top_uart
    tb_top_sr04_uart
}

array set pass_markers {
    tb_sr04_controller {SR04 TEST PASS}
    tb_control_unit {CONTROL UNIT TEST PASS}
    tb_top_smoke {TOP SMOKE TEST PASS}
    tb_top_uart {TOP UART RX INTEGRATION TEST PASS}
    tb_top_sr04_uart {TOP SR04 CONTROL INTEGRATION TEST PASS}
}

set project_dir  [get_property DIRECTORY [current_project]]
set project_name [get_property NAME [current_project]]
set xsim_dir [file join $project_dir ${project_name}.sim sim_1 behav xsim]
set failed_tops {}

foreach test_top $test_tops {
    puts "SIMULATION_START: $test_top"
    set_property top $test_top [get_filesets sim_1]
    update_compile_order -fileset sim_1

    set launch_failed [catch {
        launch_simulation -mode behavioral
    } launch_message launch_options]

    # xsim.simulate.runtime is "all", so launch_simulation performs the run
    # through the testbench's $finish. Calling run all again would restart an
    # event-driven design with a free-running clock and never return.
    set run_failed $launch_failed
    if {!$launch_failed} {
        catch {close_sim}
    }

    set compile_log [file join $xsim_dir compile.log]
    set elaborate_log [file join $xsim_dir elaborate.log]
    set simulate_log [file join $xsim_dir simulate.log]

    archive_log $compile_log [file join $report_dir ${test_top}_compile.log]
    archive_log $elaborate_log [file join $report_dir ${test_top}_elaboration.log]
    archive_log $simulate_log [file join $report_dir ${test_top}_simulation.log]

    set simulation_text [read_text_if_present $simulate_log]
    set marker_found [expr {
        [string first $pass_markers($test_top) $simulation_text] >= 0
    }]

    if {$launch_failed} {
        puts "SIM_RESULT: $test_top COMPILE=FAIL ELABORATION=FAIL SIMULATION=NOT_RUN PASS_MARKER=NO"
        puts "SIM_LAUNCH_ERROR: $launch_message"
        lappend failed_tops $test_top
    } elseif {$run_failed || !$marker_found} {
        puts "SIM_RESULT: $test_top COMPILE=PASS ELABORATION=PASS SIMULATION=FAIL PASS_MARKER=[expr {$marker_found ? {YES} : {NO}}]"
        if {$run_failed} {
            puts "SIM_RUN_ERROR: $launch_message"
        }
        lappend failed_tops $test_top
    } else {
        puts "SIM_RESULT: $test_top COMPILE=PASS ELABORATION=PASS SIMULATION=PASS PASS_MARKER=YES"
    }
    puts "SIMULATION_COMPLETE: $test_top"
}

# Leave the GUI project with the requested default simulation top.
set_property top tb_sr04_controller [get_filesets sim_1]
update_compile_order -fileset sim_1
close_project

if {[llength $failed_tops] > 0} {
    puts "SIMULATION_SUITE_FAIL: $failed_tops"
    exit 1
}

puts "ALL_SIMULATIONS_PASS"
exit 0
