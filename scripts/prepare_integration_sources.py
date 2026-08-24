#!/usr/bin/env python3
"""Prepare the build/generated/ directory for namespaced RTL copies.

No teammate RTL currently has colliding module names, so there is nothing to
namespace right now. This script is kept as a hook: if a future collision
reappears (e.g. two files declaring the same helper module name), add the
read/regex/write steps back here, matching vivado/prepare_integration_sources.tcl.
"""

from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "build" / "generated"


def main():
    OUTPUT.mkdir(parents=True, exist_ok=True)
    print(f"INTEGRATION_SOURCES_READY: no namespaced copies needed ({OUTPUT})")


if __name__ == "__main__":
    main()
