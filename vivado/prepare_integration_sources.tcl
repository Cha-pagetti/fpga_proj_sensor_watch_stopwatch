set script_dir [file dirname [file normalize [info script]]]
set repo_root  [file normalize [file join $script_dir ..]]

set integration_rtl_files [list \
    [file join $repo_root src btn_debouncer.v] \
    [file join $repo_root src uart_tx.v] \
    [file join $repo_root src uart_rx.v] \
    [file join $repo_root src fifo.v] \
    [file join $repo_root src ascii_decoder.v] \
    [file join $repo_root src integration_ascii_encoder.v] \
    [file join $repo_root src clock.v] \
    [file join $repo_root src stopwatch_datapath.v] \
    [file join $repo_root src dht11_controller.v] \
    [file join $repo_root src integration_uart_rx_bridge.v] \
    [file join $repo_root src sr04_controller.v] \
    [file join $repo_root src control_unit.v] \
    [file join $repo_root src project_fnd_controller.v] \
    [file join $repo_root src top.v]]

puts "INTEGRATION_SOURCES_READY: [llength $integration_rtl_files] files"
