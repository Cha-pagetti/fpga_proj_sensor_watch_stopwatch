#!/usr/bin/env python3
"""Create build-only namespaced copies of colliding teammate RTL helpers."""

import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "build" / "generated"


def read_text(path):
    with path.open("r", encoding="utf-8", newline=None) as handle:
        return handle.read()


def write_text(path, data):
    with path.open("w", encoding="utf-8", newline="\n") as handle:
        handle.write(data)


def main():
    OUTPUT.mkdir(parents=True, exist_ok=True)

    fifo_data = read_text(ROOT / "src" / "fifo.v")
    fifo_data = re.sub(r"\bcontrol_unit\b", "fifo_control_unit", fifo_data)
    fifo_data = re.sub(r"^\s*c_state\s*<=\s*EMPTY;\s*$", "", fifo_data, flags=re.MULTILINE)
    fifo_data = re.sub(r"^\s*c_state\s*<=\s*n_state;\s*$", "", fifo_data, flags=re.MULTILINE)
    fifo_data = re.sub(r"^\s*n_state\s*=\s*c_state;\s*$", "", fifo_data, flags=re.MULTILINE)
    write_text(OUTPUT / "fifo_integration.v", fifo_data)

    clock_data = read_text(ROOT / "src" / "clock.v")
    clock_data = re.sub(r"\btime_counter\b", "clock_time_counter", clock_data)
    clock_data = re.sub(r"\btick_gen_100Hz\b", "clock_tick_gen_100Hz", clock_data)
    write_text(OUTPUT / "clock_namespaced.v", clock_data)

    stopwatch_data = read_text(ROOT / "src" / "stopwatch_datapath.v")
    start = stopwatch_data.find("module stopwatch_datapath")
    if start < 0:
        raise RuntimeError("STOPWATCH_MODULE_NOT_FOUND")
    stopwatch_data = stopwatch_data[start:]
    stopwatch_data = re.sub(r"\btime_counter\b", "stopwatch_time_counter", stopwatch_data)
    stopwatch_data = re.sub(r"\btick_gen_100hz\b", "stopwatch_tick_gen_100hz", stopwatch_data)
    stopwatch_data = "`timescale 1ns / 1ps\n\n" + stopwatch_data
    write_text(OUTPUT / "stopwatch_datapath_namespaced.v", stopwatch_data)

    print(f"INTEGRATION_SOURCES_READY: {OUTPUT}")


if __name__ == "__main__":
    main()
