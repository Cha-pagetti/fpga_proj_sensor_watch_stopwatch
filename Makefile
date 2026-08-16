IVERILOG ?= iverilog
VVP ?= vvp
BUILD_DIR := build
SRC := $(wildcard src/*.v)

.PHONY: test test-fifo test-ascii test-control test-sr04 test-top test-top-uart clean

test: test-fifo test-ascii test-control test-sr04 test-top test-top-uart

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

test-fifo: $(BUILD_DIR)
	$(IVERILOG) -g2012 -Wall -s tb_fifo -o $(BUILD_DIR)/tb_fifo src/fifo.v tb/tb_fifo.v
	$(VVP) $(BUILD_DIR)/tb_fifo

test-ascii: $(BUILD_DIR)
	$(IVERILOG) -g2012 -Wall -s tb_ascii_decoder -o $(BUILD_DIR)/tb_ascii src/ascii_decoder.v tb/tb_ascii_decoder.v
	$(VVP) $(BUILD_DIR)/tb_ascii

test-control: $(BUILD_DIR)
	$(IVERILOG) -g2012 -Wall -s tb_control_unit -o $(BUILD_DIR)/tb_control src/control_unit.v tb/tb_control_unit.v
	$(VVP) $(BUILD_DIR)/tb_control

test-sr04: $(BUILD_DIR)
	$(IVERILOG) -g2012 -Wall -s tb_sr04_controller -o $(BUILD_DIR)/tb_sr04 src/sr04_controller.v tb/tb_sr04_controller.v
	$(VVP) $(BUILD_DIR)/tb_sr04

test-top: $(BUILD_DIR)
	$(IVERILOG) -g2012 -Wall -s tb_top_smoke -o $(BUILD_DIR)/tb_top $(SRC) tb/tb_top_smoke.v
	$(VVP) $(BUILD_DIR)/tb_top

test-top-uart: $(BUILD_DIR)
	$(IVERILOG) -g2012 -Wall -s tb_top_uart -o $(BUILD_DIR)/tb_top_uart $(SRC) tb/tb_top_uart.v
	$(VVP) $(BUILD_DIR)/tb_top_uart

clean:
	rm -rf $(BUILD_DIR)
