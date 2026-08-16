#!/usr/bin/env python3
"""Create build-only namespaced copies of colliding teammate RTL helpers."""

import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "build" / "generated"


def main():
    OUTPUT.mkdir(parents=True, exist_ok=True)

    fifo_data = (ROOT / "src" / "fifo.v").read_text(encoding="utf-8")
    fifo_data = re.sub(r"\bcontrol_unit\b", "fifo_control_unit", fifo_data)
    fifo_data = re.sub(r"^\s*c_state\s*<=\s*EMPTY;\s*$", "", fifo_data, flags=re.MULTILINE)
    fifo_data = re.sub(r"^\s*c_state\s*<=\s*n_state;\s*$", "", fifo_data, flags=re.MULTILINE)
    fifo_data = re.sub(r"^\s*n_state\s*=\s*c_state;\s*$", "", fifo_data, flags=re.MULTILINE)
    (OUTPUT / "fifo_integration.v").write_text(fifo_data, encoding="utf-8")

    clock_data = (ROOT / "src" / "clock.v").read_text(encoding="utf-8")
    clock_data = re.sub(r"\btime_counter\b", "clock_time_counter", clock_data)
    clock_data = re.sub(r"\btick_gen_100Hz\b", "clock_tick_gen_100Hz", clock_data)
    (OUTPUT / "clock_namespaced.v").write_text(clock_data, encoding="utf-8")

    stopwatch_data = (ROOT / "src" / "stopwatch_datapath.v").read_text(encoding="utf-8")
    start = stopwatch_data.find("module stopwatch_datapath")
    if start < 0:
        raise RuntimeError("STOPWATCH_MODULE_NOT_FOUND")
    stopwatch_data = stopwatch_data[start:]
    stopwatch_data = re.sub(r"\btime_counter\b", "stopwatch_time_counter", stopwatch_data)
    stopwatch_data = re.sub(r"\btick_gen_100hz\b", "stopwatch_tick_gen_100hz", stopwatch_data)
    stopwatch_data = "`timescale 1ns / 1ps\n\n" + stopwatch_data
    (OUTPUT / "stopwatch_datapath_namespaced.v").write_text(
        stopwatch_data, encoding="utf-8"
    )

    print(f"INTEGRATION_SOURCES_READY: {OUTPUT}")


if __name__ == "__main__":
    main()
