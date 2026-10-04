#!/usr/bin/env python3
"""Bounded read-only shell CPU/RSS sample; no compositor or device setters."""
import argparse
import json
import os
from pathlib import Path
import subprocess
import time


def process_counters(process):
    # The parenthesized process name can contain spaces; numeric fields follow it.
    fields = (process / "stat").read_text().rsplit(")", 1)[1].split()
    return int(fields[11]) + int(fields[12]), int(fields[19])


def rendering(instance):
    if not instance:
        return None
    result = subprocess.check_output([
        "quickshell", "ipc", "-i", instance, "call", "bar", "rendering"
    ], text=True, timeout=3)
    return json.loads(result)


def state_signature(state):
    # Phases should move; compare visibility/backend, not an animated value.
    if state is None:
        return None
    return [(output["screen"], output["calendar"]["active"],
             output["calendar"]["reducedMotion"],
             [(meter["backend"], meter["moving"]) for meter in output["calendar"]["meters"]])
            for output in state]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("pid", type=int)
    parser.add_argument("--seconds", type=float, default=8)
    parser.add_argument("--label", default="shell")
    parser.add_argument("--instance", help="Optional native IPC visibility/backend guard")
    args = parser.parse_args()
    if args.pid <= 0 or not 1 <= args.seconds <= 30:
        parser.error("Use a positive PID and a sample between 1 and 30 seconds")

    process = Path("/proc") / str(args.pid)
    state_before = rendering(args.instance)
    before, process_start = process_counters(process)
    started = time.monotonic()
    time.sleep(args.seconds)
    after, final_start = process_counters(process)
    elapsed = time.monotonic() - started
    if process_start != final_start:
        raise SystemExit("The PID was reused; discard this sample")
    state_after = rendering(args.instance)
    cpu = 100 * (after - before) / os.sysconf("SC_CLK_TCK") / elapsed
    rss = next((int(row.split()[1]) for row in (process / "status").read_text().splitlines()
                if row.startswith("VmRSS:")), None)
    print(json.dumps({
        "label": args.label,
        "seconds": round(elapsed, 3),
        "cpu_percent_one_core": round(cpu, 2),
        "rss_kib": rss,
        "same_state_at_endpoints": state_signature(state_before) == state_signature(state_after),
        "rendering_before": state_before,
        "rendering_after": state_after,
    }))


if __name__ == "__main__":
    main()
