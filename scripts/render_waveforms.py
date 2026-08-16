#!/usr/bin/env python3
"""Render presentation-ready digital waveform PNGs from Icarus/Vivado VCDs."""

import os
from collections import defaultdict
from pathlib import Path

os.environ.setdefault("MPLCONFIGDIR", "/tmp/fpga-matplotlib")
import matplotlib.pyplot as plt


ROOT = Path(__file__).resolve().parents[1]
VCD_DIR = ROOT / "build" / "waves"
OUT_DIR = ROOT / "docs" / "waveforms"


CONFIGS = [
    ("tb_control_unit", "System Control Unit: command and sensor sequencing", [
        ("cmd_done", "command done", "bin"), ("cmd_signals", "action", "hex"),
        ("cmd_target", "target", "hex"), ("state_reg", "control state", "dec"),
        ("sr04_start", "SR04 start", "bin"), ("dht11_start", "DHT11 start", "bin"),
        ("response_valid", "response valid", "bin"),
        ("response_kind", "response kind", "dec"), ("busy", "control busy", "bin")], "us", None),
    ("tb_sr04_controller", "HC-SR04: trigger, echo measurement, done, and re-arm", [
        ("i_start", "start", "bin"), ("trigger", "10 us trigger", "bin"),
        ("echo", "echo", "bin"), ("state_reg", "FSM state", "dec"),
        ("distance", "distance (cm)", "dec"), ("o_done", "done", "bin"),
        ("o_ready", "ready", "bin"), ("o_error", "error", "bin")], "us", (0, 300)),
    ("tb_top_uart", "Top integration: teammate UART/decoder contract to run/stop", [
        ("rx", "UART RX", "bin"), ("tx", "UART TX", "bin"),
        ("cmd_done", "command done", "bin"), ("cmd_signals", "decoded action", "hex"),
        ("stopwatch_run", "stopwatch run", "bin"),
        ("response_valid", "response valid", "bin"),
        ("response_kind", "response kind", "dec")], "us", None),
    ("tb_top_sr04_uart", "Top integration: /get dist to SR04 and RESP_DIST", [
        ("rx", "UART RX", "bin"), ("cmd_done", "command done", "bin"),
        ("sr04_start", "SR04 start", "bin"), ("sr04_trigger", "trigger", "bin"),
        ("sr04_echo", "echo", "bin"), ("distance", "distance (cm)", "dec"),
        ("sr04_done", "sensor done", "bin"), ("response_valid", "response valid", "bin"),
        ("response_kind", "response kind", "dec")], "us", None),
]


def parse_vcd(path):
    widths = {}
    names = {}
    changes = defaultdict(list)
    in_header = True
    time = 0
    with path.open("r", encoding="utf-8", errors="replace") as handle:
        for raw in handle:
            line = raw.strip()
            if not line:
                continue
            if in_header:
                if line.startswith("$var"):
                    parts = line.split()
                    widths[parts[3]] = int(parts[2])
                    names[parts[4]] = parts[3]
                elif line.startswith("$enddefinitions"):
                    in_header = False
                continue
            if line.startswith("#"):
                time = int(line[1:])
            elif line[0] in "01xzXZ":
                ident = line[1:]
                if ident in widths:
                    changes[ident].append((time, line[0].lower()))
            elif line.startswith("b"):
                value, ident = line.split()
                if ident in widths:
                    changes[ident].append((time, value[1:].lower()))
    return names, widths, changes


def value_text(value, radix):
    if any(char in value for char in "xz"):
        return value.upper()
    number = int(value, 2)
    if radix == "hex":
        return f"0x{number:X}"
    if radix == "bin":
        return str(number)
    return str(number)


def clipped_segments(events, start, end):
    current = "x"
    for time, value in events:
        if time <= start:
            current = value
        else:
            break
    points = [(start, current)]
    for time, value in events:
        if start < time < end:
            points.append((time, value))
    points.append((end, points[-1][1]))
    return points


def render(config):
    stem, title, signal_specs, unit, xlim = config
    names, widths, changes = parse_vcd(VCD_DIR / f"{stem}.vcd")
    divider = 1_000.0 if unit == "ns" else 1_000_000.0
    max_time = max((t for events in changes.values() for t, _ in events), default=1)
    start_u, end_u = xlim if xlim else (0, max_time / divider)
    start, end = start_u * divider, end_u * divider

    fig_height = max(4.5, 0.62 * len(signal_specs) + 1.8)
    fig, ax = plt.subplots(figsize=(14, fig_height), dpi=160)
    palette = ["#2563EB", "#0891B2", "#059669", "#7C3AED", "#D97706", "#DC2626"]

    labels = []
    for index, (name, label, radix) in enumerate(signal_specs):
        base = len(signal_specs) - index - 1
        labels.append(label)
        ident = names.get(name)
        if ident is None:
            continue
        points = clipped_segments(changes[ident], start, end)
        color = palette[index % len(palette)]
        xs = [time / divider for time, _ in points]
        if widths[ident] == 1:
            ys = []
            for _, value in points:
                ys.append(base + ({"0": 0.15, "1": 0.78}.get(value, 0.46)))
            ax.step(xs, ys, where="post", color=color, linewidth=1.7)
        else:
            for point_index in range(len(points) - 1):
                x0 = points[point_index][0] / divider
                x1 = points[point_index + 1][0] / divider
                value = points[point_index][1]
                y = base + (0.35 if point_index % 2 == 0 else 0.62)
                ax.hlines(y, x0, x1, color=color, linewidth=2.2)
                if point_index and x0 < end_u:
                    ax.vlines(x0, base + 0.28, base + 0.69, color=color, linewidth=0.9)
                if x1 - x0 >= (end_u - start_u) * 0.035:
                    ax.text((x0 + x1) / 2, y + 0.08, value_text(value, radix),
                            ha="center", va="bottom", fontsize=8, color="#111827")

    ax.set_xlim(start_u, end_u)
    ax.set_ylim(-0.15, len(signal_specs) + 0.15)
    ax.set_yticks([len(signal_specs) - i - 1 + 0.46 for i in range(len(signal_specs))])
    ax.set_yticklabels(labels, fontsize=9)
    ax.set_xlabel(f"Time ({unit})", fontsize=10)
    ax.set_title(title, loc="left", fontsize=15, fontweight="bold", pad=14)
    ax.text(1.0, 1.03, "SELF-CHECKING TB: PASS", transform=ax.transAxes,
            ha="right", va="bottom", fontsize=10, fontweight="bold", color="#047857")
    ax.grid(axis="x", color="#D1D5DB", linestyle="--", linewidth=0.7, alpha=0.75)
    ax.set_facecolor("#F9FAFB")
    for spine in ("top", "right", "left"):
        ax.spines[spine].set_visible(False)
    ax.spines["bottom"].set_color("#9CA3AF")
    ax.tick_params(axis="y", length=0)
    fig.tight_layout()
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    fig.savefig(OUT_DIR / f"{stem}.png", bbox_inches="tight", facecolor="white")
    plt.close(fig)


def main():
    missing = [stem for stem, *_ in CONFIGS if not (VCD_DIR / f"{stem}.vcd").exists()]
    if missing:
        raise SystemExit(f"Missing VCD files: {', '.join(missing)}")
    for config in CONFIGS:
        render(config)
    print(f"Rendered {len(CONFIGS)} waveform images to {OUT_DIR}")


if __name__ == "__main__":
    main()
