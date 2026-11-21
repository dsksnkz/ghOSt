#!/usr/bin/env python3
"""Battery details UPower does not give the shell, read from sysfs.

battery.py watch        print one JSON line now and every few seconds
battery.py limit N      stop charging at N% (55-100), asking polkit for rights
"""
import json
import subprocess
import sys
import time
from pathlib import Path

ROOT = Path("/sys/class/power_supply")
# Kernel charge types, as the panel names them.
TYPES = {
    "Trickle": "Slow charging",
    "Standard": "Standard charging",
    "Fast": "Fast charging",
    "Adaptive": "Adaptive charging",
    "Custom": "Charge limit",
    "Long_Life": "Long life",
}


def battery():
    for path in sorted(ROOT.glob("BAT*")):
        if (path / "present").exists() and read(path / "present") == "1":
            return path
    return None


def read(path):
    try:
        return path.read_text().strip()
    except OSError:
        return ""


def number(path, scale=1.0):
    try:
        return int(read(path)) / scale
    except ValueError:
        return None


def snapshot():
    bat = battery()
    if not bat:
        return {"present": False}
    raw = read(bat / "charge_types")
    current = next((t.strip("[]") for t in raw.split() if t.startswith("[")), "")
    full, design = number(bat / "charge_full"), number(bat / "charge_full_design")
    if not full:
        full, design = number(bat / "energy_full"), number(bat / "energy_full_design")
    adapter = any(read(p / "online") == "1" for p in ROOT.iterdir() if read(p / "type") == "Mains")
    return {
        "present": True,
        "cycles": number(bat / "cycle_count"),
        "health": round(100 * full / design) if full and design else None,
        "voltage": number(bat / "voltage_now", 1e6),
        "start": number(bat / "charge_control_start_threshold"),
        "end": number(bat / "charge_control_end_threshold"),
        "type": current,
        "typeName": TYPES.get(current, current.replace("_", " ")),
        "technology": read(bat / "technology"),
        "model": read(bat / "model_name"),
        "adapter": adapter,
    }


def set_limit(end):
    bat = battery()
    if not bat or not (bat / "charge_control_end_threshold").exists():
        sys.exit("This battery has no charge limit")
    end = max(55, min(100, int(end)))
    start = max(50, end - 10)
    old_start = number(bat / "charge_control_start_threshold") or 0
    writes = [("charge_control_end_threshold", end), ("charge_control_start_threshold", start)]
    # The start threshold must stay below the end one at every step.
    if end <= old_start:
        writes.reverse()
    if (bat / "charge_types").exists():
        writes.append(("charge_types", "Custom"))
    # Write directly where a udev rule already allows it; otherwise ask polkit.
    try:
        for name, value in writes:
            (bat / name).write_text(str(value))
        return
    except PermissionError:
        pass
    script = "; ".join(f"echo {value} > {bat / name}" for name, value in writes)
    result = subprocess.run(["pkexec", "/bin/sh", "-c", script], capture_output=True, text=True)
    if result.returncode == 126:
        sys.exit("Cancelled")
    if result.returncode:
        error = result.stderr.strip()
        if "authentication agent" in error:
            sys.exit("No password prompt is running, so the limit can't be changed. Log out and back in, or start polkit-gnome.")
        sys.exit(error or "Could not change the charge limit")


def main():
    if len(sys.argv) > 2 and sys.argv[1] == "limit":
        set_limit(sys.argv[2])
        return
    while True:
        print(json.dumps(snapshot()), flush=True)
        if sys.argv[1:] != ["watch"]:
            return
        time.sleep(3)


if __name__ == "__main__":
    main()
