#!/usr/bin/env python3
"""Wi-Fi menu helper: connection details, sharing as a QR code, DNS and per-network options.

Every change goes through NetworkManager (nmcli) and applies to the saved
connection, so it survives a reboot and is visible in any other network tool.
"""
import json
from pathlib import Path
import subprocess
import sys
import time

# DNS choices in the menu. Automatic uses whatever the network hands out.
DNS = {
    'auto': [],
    'cloudflare': ['1.1.1.1', '1.0.0.1'],
    'google': ['8.8.8.8', '8.8.4.4'],
    'quad9': ['9.9.9.9', '149.112.112.112'],
    'adguard': ['94.140.14.14', '94.140.15.15'],
}


def nmcli(*arguments):
    result = subprocess.run(['nmcli', *arguments], capture_output=True, text=True, timeout=15)
    if result.returncode:
        raise RuntimeError(result.stderr.strip().splitlines()[-1] if result.stderr.strip() else 'nmcli failed')
    return result.stdout


def wifi_device():
    for line in nmcli('-t', '-f', 'DEVICE,TYPE,STATE,CONNECTION', 'device').splitlines():
        device, kind, state, connection = (line.split(':', 3) + ['', '', ''])[:4]
        if kind == 'wifi':
            return device, connection if state == 'connected' else ''
    return '', ''


def values(text):
    # nmcli -t -g prints one field per line; lists inside a field are " | " separated.
    return [line.replace('\\:', ':') for line in text.splitlines()]


def details():
    device, connection = wifi_device()
    if not connection:
        return {'connected': False}
    address, gateway, dns = (values(nmcli('-t', '-g', 'IP4.ADDRESS,IP4.GATEWAY,IP4.DNS', 'device', 'show', device)) + ['', '', ''])[:3]
    saved = values(nmcli('-t', '-g', 'ipv4.dns,ipv4.ignore-auto-dns,connection.autoconnect,802-11-wireless.cloned-mac-address',
                         'connection', 'show', 'id', connection))
    saved_dns, ignore_auto, autoconnect, mac = (saved + ['', '', '', ''])[:4]
    servers = [server for server in saved_dns.replace(' ', '').split(',') if server]
    provider = 'auto' if ignore_auto != 'yes' or not servers else next(
        (name for name, listed in DNS.items() if listed == servers), 'custom')
    return {'connected': True, 'name': connection, 'device': device,
            'address': address.split(' | ')[0].split('/')[0], 'gateway': gateway,
            'dns': [server for server in dns.split(' | ') if server], 'provider': provider,
            'autoconnect': autoconnect != 'no', 'private': mac in ('random', 'stable')}


def split_fields(line):
    """nmcli -t separates fields with ':' and escapes ':' and '\\' inside them."""
    fields, current, escaped = [], '', False
    for char in line:
        if escaped:
            current += char
            escaped = False
        elif char == '\\':
            escaped = True
        elif char == ':':
            fields.append(current)
            current = ''
        else:
            current += char
    return fields + [current]


def signal_dbm(percent):
    # NetworkManager reports strength as clamp(2 * (dBm + 100)) percent; this is its inverse.
    return round(percent / 2 - 100)


def networks(text, saved):
    """Nearby networks from `nmcli -t -f IN-USE,SSID,SIGNAL,RATE,SECURITY dev wifi list`, strongest first."""
    found = {}
    for line in text.splitlines():
        fields = split_fields(line)
        if len(fields) < 5 or not fields[1]:
            continue
        in_use, name, signal, rate, security = fields[:5]
        try:
            signal = int(signal)
        except ValueError:
            continue
        entry = {'name': name, 'connected': in_use.strip() == '*', 'known': name in saved,
                 'secured': bool(security.strip()) and security.strip() != '--',
                 'signal': signal, 'dbm': signal_dbm(signal),
                 'rate': int(rate.split()[0]) if rate.split() and rate.split()[0].isdigit() else None}
        # One entry per name: the access point in use, otherwise the strongest.
        if name not in found or entry['connected'] or (not found[name]['connected'] and signal > found[name]['signal']):
            found[name] = entry
    return sorted(found.values(), key=lambda n: (not n['connected'], -n['signal'], n['name'].lower()))


def saved_names():
    return {fields[0] for fields in map(split_fields, nmcli('-t', '-f', 'NAME,TYPE', 'connection', 'show').splitlines())
            if len(fields) > 1 and fields[1] == '802-11-wireless'}


def active_device():
    """The device carrying traffic: connected Wi-Fi first, otherwise a wired or other link."""
    connected = [fields for fields in map(split_fields, nmcli('-t', '-f', 'DEVICE,TYPE,STATE', 'device').splitlines())
                 if len(fields) > 2 and fields[2] == 'connected' and fields[1] not in ('loopback', 'wifi-p2p')]
    connected.sort(key=lambda fields: fields[1] != 'wifi')
    return connected[0][0] if connected else ''


def traffic(device):
    base = Path('/sys/class/net') / device / 'statistics'
    try:
        return int((base / 'rx_bytes').read_text()), int((base / 'tx_bytes').read_text())
    except (OSError, ValueError):
        return None


def watch():
    """Once a second while the menu is open: nearby networks and the active link's live speeds."""
    saved = saved_names()
    previous, previous_time, previous_device = None, None, None
    while True:
        listing = nmcli('-t', '-f', 'IN-USE,SSID,SIGNAL,RATE,SECURITY', 'device', 'wifi', 'list', '--rescan', 'no')
        device = active_device()
        result = {'ok': True, 'device': device, 'networks': networks(listing, saved), 'down': None, 'up': None}
        counters, now = traffic(device) if device else None, time.monotonic()
        if device != previous_device:
            previous = None
        previous_device = device
        if counters and previous and now > previous_time:
            seconds = now - previous_time
            result['down'] = round((counters[0] - previous[0]) * 8 / seconds / 1e6, 2)
            result['up'] = round((counters[1] - previous[1]) * 8 / seconds / 1e6, 2)
        previous, previous_time = counters, now
        print(json.dumps(result), flush=True)
        time.sleep(1)


def set_dns(connection, provider):
    servers = DNS[provider]
    nmcli('connection', 'modify', 'id', connection, 'ipv4.dns', ' '.join(servers),
          'ipv4.ignore-auto-dns', 'yes' if servers else 'no', 'ipv6.ignore-auto-dns', 'yes' if servers else 'no')


def apply(connection):
    device, active = wifi_device()
    if device and active == connection:
        nmcli('device', 'reapply', device)


def wifi_uri(name, password, security):
    def escape(text):
        return ''.join('\\' + char if char in '\\;,:"' else char for char in text)
    kind = 'nopass' if not password else 'WEP' if security == 'wep' else 'WPA'
    uri = 'WIFI:T:' + kind + ';S:' + escape(name) + ';'
    if password:
        uri += 'P:' + escape(password) + ';'
    return uri + ';'


def share(connection):
    """The QR code phones scan to join. The password never leaves this process except inside it."""
    fields = values(nmcli('-s', '-t', '-g', '802-11-wireless.ssid,802-11-wireless-security.key-mgmt,'
                          '802-11-wireless-security.psk,802-11-wireless-security.wep-key0',
                          'connection', 'show', 'id', connection))
    ssid, management, psk, wep = (fields + ['', '', '', ''])[:4]
    password = psk or wep
    if management and management != 'none' and not password:
        raise RuntimeError('The password for this network is not saved')
    return {'name': ssid or connection, 'rows': qr_rows(wifi_uri(ssid or connection, password, 'wep' if wep else ''))}


# QR encoding: byte mode, error correction level M, versions 1 to 20. Follows
# the ISO/IEC 18004 construction as laid out in Project Nayuki's reference code.
ECC_PER_BLOCK = [0, 10, 16, 26, 18, 24, 16, 18, 22, 22, 26, 30, 22, 22, 24, 24, 28, 28, 26, 26, 26]
BLOCKS = [0, 1, 1, 1, 2, 2, 4, 4, 4, 5, 5, 5, 8, 9, 9, 10, 10, 11, 13, 14, 16]


def raw_modules(version):
    result = (16 * version + 128) * version + 64
    if version >= 2:
        count = version // 7 + 2
        result -= (25 * count - 10) * count - 55
        if version >= 7:
            result -= 36
    return result


def data_codewords(version):
    return raw_modules(version) // 8 - ECC_PER_BLOCK[version] * BLOCKS[version]


def multiply(x, y):
    z = 0
    for i in reversed(range(8)):
        z = (z << 1) ^ ((z >> 7) * 0x11D)
        z ^= ((y >> i) & 1) * x
    return z


def divisor(degree):
    result = [0] * (degree - 1) + [1]
    root = 1
    for _ in range(degree):
        for j in range(degree):
            result[j] = multiply(result[j], root)
            if j + 1 < degree:
                result[j] ^= result[j + 1]
        root = multiply(root, 2)
    return result


def remainder(data, generator):
    result = [0] * len(generator)
    for byte in data:
        factor = byte ^ result.pop(0)
        result.append(0)
        for i, coefficient in enumerate(generator):
            result[i] ^= multiply(coefficient, factor)
    return result


def alignment_positions(version):
    if version == 1:
        return []
    count = version // 7 + 2
    step = (version * 4 + count * 2 + 1) // (count * 2 - 2) * 2
    size = version * 4 + 17
    result = [6]
    position = size - 7
    for _ in range(count - 1):
        result.insert(1, position)
        position -= step
    return result


def qr_rows(text):
    payload = text.encode('utf-8')
    for version in range(1, len(BLOCKS)):
        count_bits = 8 if version < 10 else 16
        if 4 + count_bits + 8 * len(payload) <= data_codewords(version) * 8:
            break
    else:
        raise RuntimeError('Too long to share as a QR code')

    bits = [0, 1, 0, 0] + [(len(payload) >> i) & 1 for i in reversed(range(count_bits))]
    for byte in payload:
        bits += [(byte >> i) & 1 for i in reversed(range(8))]
    capacity = data_codewords(version) * 8
    bits += [0] * min(4, capacity - len(bits))
    bits += [0] * (-len(bits) % 8)
    data = [int(''.join(map(str, bits[i:i + 8])), 2) for i in range(0, len(bits), 8)]
    pad = 0xEC
    while len(data) < capacity // 8:
        data.append(pad)
        pad ^= 0xEC ^ 0x11

    # Split into blocks, add error correction to each, then interleave.
    blocks_count, ecc_length = BLOCKS[version], ECC_PER_BLOCK[version]
    raw = raw_modules(version) // 8
    short_blocks = blocks_count - raw % blocks_count
    short_length = raw // blocks_count
    generator = divisor(ecc_length)
    blocks, k = [], 0
    for i in range(blocks_count):
        part = data[k:k + short_length - ecc_length + (0 if i < short_blocks else 1)]
        k += len(part)
        ecc = remainder(part, generator)
        if i < short_blocks:
            part = part + [0]
        blocks.append(part + ecc)
    codewords = [block[i] for i in range(len(blocks[0])) for j, block in enumerate(blocks)
                 if i != short_length - ecc_length or j >= short_blocks]

    size = version * 4 + 17
    modules = [[False] * size for _ in range(size)]
    function = [[False] * size for _ in range(size)]

    def put(x, y, dark):
        modules[y][x] = dark
        function[y][x] = True

    for i in range(size):
        put(6, i, i % 2 == 0)
        put(i, 6, i % 2 == 0)
    for cx, cy in ((3, 3), (size - 4, 3), (3, size - 4)):
        for dy in range(-4, 5):
            for dx in range(-4, 5):
                if 0 <= cx + dx < size and 0 <= cy + dy < size:
                    put(cx + dx, cy + dy, max(abs(dx), abs(dy)) not in (2, 4))
    positions = alignment_positions(version)
    last = len(positions) - 1
    for i, ax in enumerate(positions):
        for j, ay in enumerate(positions):
            if (i, j) in ((0, 0), (0, last), (last, 0)):
                continue
            for dy in range(-2, 3):
                for dx in range(-2, 3):
                    put(ax + dx, ay + dy, max(abs(dx), abs(dy)) != 1)

    def format_bits(mask):
        value = mask  # Level M is 00, so only the mask remains in the high bits.
        rem = value
        for _ in range(10):
            rem = (rem << 1) ^ ((rem >> 9) * 0x537)
        return (value << 10 | rem) ^ 0x5412

    def draw_format(mask):
        word = format_bits(mask)
        bit = lambda i: (word >> i) & 1 == 1
        for i in range(6):
            put(8, i, bit(i))
        put(8, 7, bit(6))
        put(8, 8, bit(7))
        put(7, 8, bit(8))
        for i in range(9, 15):
            put(14 - i, 8, bit(i))
        for i in range(8):
            put(size - 1 - i, 8, bit(i))
        for i in range(8, 15):
            put(8, size - 15 + i, bit(i))
        put(8, size - 8, True)

    draw_format(0)
    if version >= 7:
        rem = version
        for _ in range(12):
            rem = (rem << 1) ^ ((rem >> 11) * 0x1F25)
        word = version << 12 | rem
        for i in range(18):
            dark = (word >> i) & 1 == 1
            a, b = size - 11 + i % 3, i // 3
            put(a, b, dark)
            put(b, a, dark)

    i = 0
    right = size - 1
    while right >= 1:
        if right == 6:
            right = 5
        for vertical in range(size):
            for j in range(2):
                x = right - j
                upward = (right + 1) & 2 == 0
                y = size - 1 - vertical if upward else vertical
                if not function[y][x] and i < len(codewords) * 8:
                    modules[y][x] = (codewords[i >> 3] >> (7 - (i & 7))) & 1 == 1
                    i += 1
        right -= 2

    masks = [lambda x, y: (x + y) % 2 == 0, lambda x, y: y % 2 == 0, lambda x, y: x % 3 == 0,
             lambda x, y: (x + y) % 3 == 0, lambda x, y: (x // 3 + y // 2) % 2 == 0,
             lambda x, y: x * y % 2 + x * y % 3 == 0, lambda x, y: (x * y % 2 + x * y % 3) % 2 == 0,
             lambda x, y: ((x + y) % 2 + x * y % 3) % 2 == 0]

    def masked(mask):
        draw_format(mask)
        return [[modules[y][x] ^ (not function[y][x] and masks[mask](x, y)) for x in range(size)] for y in range(size)]

    def penalty(grid):
        # Runs, 2x2 blocks and balance: enough to avoid the patterns that confuse scanners.
        score = 0
        for line in grid + [list(column) for column in zip(*grid)]:
            run = 1
            for a, b in zip(line, line[1:]):
                run = run + 1 if a == b else 1
                if run == 5:
                    score += 3
                elif run > 5:
                    score += 1
        for y in range(size - 1):
            for x in range(size - 1):
                if grid[y][x] == grid[y][x + 1] == grid[y + 1][x] == grid[y + 1][x + 1]:
                    score += 3
        dark = sum(map(sum, grid))
        score += abs(dark * 20 - size * size * 10) // (size * size) * 10
        return score

    best = min(range(8), key=lambda mask: penalty(masked(mask)))
    grid = masked(best)
    return [''.join('1' if cell else '0' for cell in row) for row in grid]


def main():
    operation = sys.argv[1] if len(sys.argv) > 1 else ''
    arguments = sys.argv[2:]
    try:
        if operation == 'watch':
            try:
                watch()
            except BrokenPipeError:
                pass
            return
        if operation == 'details':
            result = details()
        elif operation == 'share' and len(arguments) == 1:
            result = share(arguments[0])
        elif operation == 'dns' and len(arguments) == 2 and arguments[1] in DNS:
            set_dns(*arguments)
            apply(arguments[0])
            result = details()
        elif operation == 'autoconnect' and len(arguments) == 2 and arguments[1] in ('yes', 'no'):
            nmcli('connection', 'modify', 'id', arguments[0], 'connection.autoconnect', arguments[1])
            result = details()
        elif operation == 'private' and len(arguments) == 2 and arguments[1] in ('yes', 'no'):
            # A random address per network hides this computer from network-wide tracking.
            nmcli('connection', 'modify', 'id', arguments[0], '802-11-wireless.cloned-mac-address',
                  'stable' if arguments[1] == 'yes' else 'permanent')
            apply(arguments[0])
            result = details()
        elif operation == 'hidden' and len(arguments) in (1, 2):
            command = ['device', 'wifi', 'connect', arguments[0], 'hidden', 'yes']
            if len(arguments) == 2 and arguments[1]:
                command += ['password', arguments[1]]
            nmcli(*command)
            result = details()
        else:
            raise RuntimeError('usage: network.py details | share NAME | dns NAME PROVIDER | '
                               'autoconnect NAME yes|no | private NAME yes|no | hidden SSID [PASSWORD]')
        print(json.dumps({'ok': True, **result}))
    except (OSError, RuntimeError, subprocess.TimeoutExpired) as error:
        print(json.dumps({'ok': False, 'error': str(error)[:200]}))


if __name__ == '__main__':
    main()
