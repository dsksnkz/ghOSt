"""Windowless polling test backend: no filesystem, service or system actions."""
import json

print(json.dumps({"ok": True, "state": {"preferences": {
    "usageTracking": False, "reducedMotion": False, "widgets": {}
}}}))
