#!/usr/bin/env python3
"""AirPods status and controls over Apple's accessory protocol (AAP), as librepods does.

Runs while the Bluetooth menu shows a connected Apple headset. Prints one JSON line
whenever something changes and reads commands on stdin:
  mode off|anc|transparency|adaptive    conversation on|off
BlueZ alone cannot see per-bud and case battery or the listening mode; the buds
report them only on this channel. Nothing here pairs, connects or changes BlueZ.
"""
import json
import os
import re
import select
import socket
import subprocess
import sys

PSM = 0x1001
HANDSHAKE = bytes.fromhex("00000400010002000000000000000000")
FEATURES = bytes.fromhex("040004004d00d700000000000000")
NOTIFICATIONS = bytes.fromhex("040004000f00ffffffffff")
CONTROL = bytes.fromhex("040004000900")
BATTERY = bytes.fromhex("040004000400")
EAR = bytes.fromhex("040004000600")
METADATA = bytes.fromhex("040004001d")
# Apple model numbers sent in the metadata packet, as mapped by omarchy-pods and librepods.
MODELS = {
    **dict.fromkeys(("A1523", "A1722"), "AirPods"), **dict.fromkeys(("A2032", "A2031"), "AirPods 2"),
    **dict.fromkeys(("A2565", "A2564"), "AirPods 3"), **dict.fromkeys(("A3053", "A3050", "A3054"), "AirPods 4"),
    **dict.fromkeys(("A3056", "A3055", "A3057"), "AirPods 4 ANC"), **dict.fromkeys(("A2084", "A2083"), "AirPods Pro"),
    **dict.fromkeys(("A2931", "A2699", "A2698", "A3047", "A3048", "A3049"), "AirPods Pro 2"),
    **dict.fromkeys(("A3063", "A3064", "A3065"), "AirPods Pro 3"),
    **dict.fromkeys(("A2096", "A3184"), "AirPods Max"), "A3454": "AirPods Max 2",
}
NOISE, CONVERSATION = 0x0D, 0x28
MODES = {1: "off", 2: "anc", 3: "transparency", 4: "adaptive"}
PARTS = {0x01: "headset", 0x02: "right", 0x04: "left", 0x08: "case"}
EAR_STATES = {0: "ear", 1: "out", 2: "case"}


def apple(address):
    """Apple's Bluetooth vendor ID is 0x004C."""
    try:
        info = subprocess.run(["bluetoothctl", "info", address], capture_output=True, text=True, timeout=5).stdout
    except (OSError, subprocess.TimeoutExpired):
        return False
    return re.search(r"Modalias: bluetooth:v004C", info, re.I) is not None


def control(identifier, value):
    return CONTROL + bytes([identifier, value, 0, 0, 0])


def parse(packet, state):
    """Update state from one packet; returns True when something changed."""
    before = json.dumps(state, sort_keys=True)
    if packet.startswith(BATTERY) and len(packet) > 6:
        battery = {}
        for index in range(packet[6]):
            offset = 7 + index * 5
            if offset + 4 >= len(packet):
                break
            kind, level, status = packet[offset], packet[offset + 2], packet[offset + 3]
            # Status 4 means the part is not there, such as a bud left at home.
            if kind in PARTS and status != 4:
                battery[PARTS[kind]] = {"level": level, "charging": status == 1}
        state["battery"] = battery
    elif packet.startswith(METADATA) and len(packet) > len(METADATA) + 6:
        # Six bytes, then the device name and the model number, each NUL-terminated.
        strings = packet[len(METADATA) + 6:].split(b"\0")
        if len(strings) > 1:
            number = strings[1].decode(errors="replace")
            state["model"] = MODELS.get(number, number)
    elif packet.startswith(EAR) and len(packet) > 7:
        state["ear"] = [EAR_STATES.get(packet[6], "unknown"), EAR_STATES.get(packet[7], "unknown")]
    elif packet.startswith(CONTROL) and len(packet) > 7:
        if packet[6] == NOISE and packet[7] in MODES:
            state["mode"] = MODES[packet[7]]
        elif packet[6] == CONVERSATION and packet[7] in (1, 2):
            state["conversation"] = packet[7] == 1
    return json.dumps(state, sort_keys=True) != before


def emit(state):
    print(json.dumps(state), flush=True)


def command(line):
    words = line.split()
    if len(words) == 2 and words[0] == "mode" and words[1] in MODES.values():
        return control(NOISE, next(key for key, name in MODES.items() if name == words[1]))
    if len(words) == 2 and words[0] == "conversation" and words[1] in ("on", "off"):
        return control(CONVERSATION, 1 if words[1] == "on" else 2)
    return None


def main():
    if len(sys.argv) != 2 or not re.fullmatch(r"([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}", sys.argv[1]):
        sys.exit("usage: airpods.py ADDRESS")
    address = sys.argv[1]
    if not apple(address):
        emit({"apple": False})
        return
    state = {"apple": True, "connected": False}
    try:
        link = socket.socket(socket.AF_BLUETOOTH, socket.SOCK_SEQPACKET, socket.BTPROTO_L2CAP)
        link.settimeout(5)
        link.connect((address, PSM))
        for packet in (HANDSHAKE, FEATURES, NOTIFICATIONS):
            link.send(packet)
        link.settimeout(None)
    except OSError as error:
        state["error"] = "Could not reach the buds: " + (error.strerror or str(error))
        emit(state)
        return
    state["connected"] = True
    emit(state)
    stdin = sys.stdin.fileno()
    try:
        while True:
            ready, _, _ = select.select([link, stdin], [], [])
            if link in ready:
                packet = link.recv(1024)
                if not packet:
                    break
                if parse(packet, state):
                    emit(state)
            if stdin in ready:
                line = os.read(stdin, 256).decode(errors="replace")
                if not line:
                    break  # The menu closed.
                for request in line.splitlines():
                    packet = command(request)
                    if packet:
                        link.send(packet)
    except OSError:
        pass
    finally:
        link.close()
    state["connected"] = False
    emit(state)


if __name__ == "__main__":
    main()
