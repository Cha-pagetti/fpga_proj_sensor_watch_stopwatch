set script_dir [file dirname [file normalize [info script]]]
set repo_root  [file normalize [file join $script_dir ..]]
set output_dir [file join $repo_root build generated]
file mkdir $output_dir

proc read_text {path} {
    set handle [open $path r]
    fconfigure $handle -encoding utf-8 -translation auto
    set data [read $handle]
    close $handle
    return $data
}

proc write_text {path data} {
    set handle [open $path w]
    fconfigure $handle -encoding utf-8 -translation lf
    puts -nonewline $handle $data
    close $handle
}

# The current FIFO source contains three stale references to an undeclared FSM.
# They do not participate in its pointer/flag logic, so omit them from the
# generated integration copy and namespace its generic control_unit name.
set fifo_data [read_text [file join $repo_root src fifo.v]]
regsub -all {\mcontrol_unit\M} $fifo_data {fifo_control_unit} fifo_data
regsub -all -line {^[ \t]*c_state[ \t]*<=[ \t]*EMPTY;[ \t]*$} $fifo_data {} fifo_data
regsub -all -line {^[ \t]*c_state[ \t]*<=[ \t]*n_state;[ \t]*$} $fifo_data {} fifo_data
regsub -all -line {^[ \t]*n_state[ \t]*=[ \t]*c_state;[ \t]*$} $fifo_data {} fifo_data
write_text [file join $output_dir fifo_integration.v] $fifo_data

# clock.v and stopwatch_datapath.v currently declare helpers with the same
# module names. Generate namespaced build copies while keeping both teammate
# source files byte-for-byte unchanged in git.
set clock_data [read_text [file join $repo_root src clock.v]]
regsub -all {\mtime_counter\M} $clock_data {clock_time_counter} clock_data
regsub -all {\mtick_gen_100Hz\M} $clock_data {clock_tick_gen_100Hz} clock_data
write_text [file join $output_dir clock_namespaced.v] $clock_data

set stopwatch_data [read_text [file join $repo_root src stopwatch_datapath.v]]
set start_index [string first {module stopwatch_datapath} $stopwatch_data]
if {$start_index < 0} {
    error "STOPWATCH_MODULE_NOT_FOUND"
}
set stopwatch_data [string range $stopwatch_data $start_index end]
regsub -all {\mtime_counter\M} $stopwatch_data {stopwatch_time_counter} stopwatch_data
regsub -all {\mtick_gen_100hz\M} $stopwatch_data {stopwatch_tick_gen_100hz} stopwatch_data
set stopwatch_data "`timescale 1ns / 1ps\n\n${stopwatch_data}"
write_text [file join $output_dir stopwatch_datapath_namespaced.v] $stopwatch_data

set integration_rtl_files [list \
    [file join $repo_root src btn_debouncer.v] \
    [file join $repo_root src uart_tx.v] \
    [file join $repo_root src uart_rx.v] \
    [file join $output_dir fifo_integration.v] \
    [file join $repo_root src ascii_decoder.v] \
    [file join $output_dir clock_namespaced.v] \
    [file join $output_dir stopwatch_datapath_namespaced.v] \
    [file join $repo_root src dht11_controller.v] \
    [file join $repo_root src integration_ila_stub.v] \
    [file join $repo_root src integration_uart_rx_bridge.v] \
    [file join $repo_root src sr04_controller.v] \
    [file join $repo_root src control_unit.v] \
    [file join $repo_root src project_fnd_controller.v] \
    [file join $repo_root src top.v]]

puts "INTEGRATION_SOURCES_READY: $output_dir"
