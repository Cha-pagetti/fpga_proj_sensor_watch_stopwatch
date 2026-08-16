IVERILOG ?= iverilog
VVP ?= vvp
PYTHON ?= python3
BUILD_DIR := build
GENERATED_DIR := $(BUILD_DIR)/generated

TOP_SRC := \
	src/btn_debouncer.v \
	src/uart_tx.v \
	src/uart_rx.v \
	$(GENERATED_DIR)/fifo_integration.v \
	src/ascii_decoder.v \
	$(GENERATED_DIR)/clock_namespaced.v \
	$(GENERATED_DIR)/stopwatch_datapath_namespaced.v \
	src/dht11_controller.v \
	src/integration_ila_stub.v \
	src/integration_uart_rx_bridge.v \
	src/sr04_controller.v \
	src/control_unit.v \
	src/project_fnd_controller.v \
	src/top.v

.PHONY: test prepare-integration test-control test-sr04 test-top \
	test-top-uart test-top-sr04-uart clean

# Scope-clean verification: only SR04, project Control Unit, and Top integration.
test: test-control test-sr04 test-top test-top-uart test-top-sr04-uart

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

prepare-integration: $(BUILD_DIR)
	$(PYTHON) scripts/prepare_integration_sources.py

test-control: $(BUILD_DIR)
	$(IVERILOG) -g2012 -Wall -s tb_control_unit -o $(BUILD_DIR)/tb_control src/control_unit.v tb/tb_control_unit.v
	$(VVP) $(BUILD_DIR)/tb_control

test-sr04: $(BUILD_DIR)
	$(IVERILOG) -g2012 -Wall -s tb_sr04_controller -o $(BUILD_DIR)/tb_sr04 src/sr04_controller.v tb/tb_sr04_controller.v
	$(VVP) $(BUILD_DIR)/tb_sr04

test-top: prepare-integration
	$(IVERILOG) -g2012 -Wall -s tb_top_smoke -o $(BUILD_DIR)/tb_top $(TOP_SRC) tb/tb_top_smoke.v
	$(VVP) $(BUILD_DIR)/tb_top

test-top-uart: prepare-integration
	$(IVERILOG) -g2012 -Wall -s tb_top_uart -o $(BUILD_DIR)/tb_top_uart $(TOP_SRC) tb/tb_top_uart.v
	$(VVP) $(BUILD_DIR)/tb_top_uart

test-top-sr04-uart: prepare-integration
	$(IVERILOG) -g2012 -Wall -s tb_top_sr04_uart -o $(BUILD_DIR)/tb_top_sr04_uart $(TOP_SRC) tb/tb_top_sr04_uart.v
	$(VVP) $(BUILD_DIR)/tb_top_sr04_uart

clean:
	rm -rf $(BUILD_DIR)
