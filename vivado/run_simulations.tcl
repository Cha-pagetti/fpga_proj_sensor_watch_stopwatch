set script_dir [file dirname [file normalize [info script]]]
set repo_root  [file normalize [file join $script_dir ..]]
set report_dir [file join $repo_root build vivado simulation_logs]
file mkdir $report_dir

source [file join $script_dir create_project.tcl]

set test_tops {
    tb_control_unit
    tb_sr04_controller
    tb_top_smoke
    tb_top_uart
    tb_top_sr04_uart
}

foreach test_top $test_tops {
    puts "SIMULATION_START: $test_top"
    set_property top $test_top [get_filesets sim_1]
    update_compile_order -fileset sim_1
    launch_simulation -mode behavioral
    run all
    close_sim
    puts "SIMULATION_COMPLETE: $test_top"
}

puts "ALL_SIMULATIONS_COMPLETE"
exit
