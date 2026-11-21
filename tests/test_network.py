import importlib.util
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1] / 'config/quickshell/ghost-bar'


def module(name):
    spec = importlib.util.spec_from_file_location(name, ROOT / (name + '.py'))
    value = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(value)
    return value


network = module('network')
airpods = module('airpods')


class Network(unittest.TestCase):
    def test_wifi_uri_escapes_reserved_characters(self):
        self.assertEqual(network.wifi_uri('Café;1', 'a:b"c\\', ''), r'WIFI:T:WPA;S:Café\;1;P:a\:b\"c\\;;')
        self.assertEqual(network.wifi_uri('Open', '', ''), 'WIFI:T:nopass;S:Open;;')
        self.assertEqual(network.wifi_uri('Old', 'key', 'wep'), 'WIFI:T:WEP;S:Old;P:key;;')

    def test_qr_sizes_follow_the_version(self):
        for text, size in (('A', 21), ('x' * 60, 33), ('y' * 200, 57)):
            rows = network.qr_rows(text)
            self.assertEqual(len(rows), size)
            self.assertTrue(all(len(row) == size and set(row) <= {'0', '1'} for row in rows))
        with self.assertRaises(RuntimeError):
            network.qr_rows('z' * 2000)

    @unittest.skipUnless(shutil.which('zbarimg'), 'zbarimg not installed')
    def test_qr_codes_decode(self):
        from PIL import Image
        with tempfile.TemporaryDirectory() as directory:
            for text in ('WIFI:T:WPA;S:Home;P:hunter22;;', 'é' * 40, 'q' * 150):
                rows = network.qr_rows(text)
                image = Image.new('L', ((len(rows) + 8) * 4,) * 2, 255)
                for y, row in enumerate(rows):
                    for x, cell in enumerate(row):
                        if cell == '1':
                            image.paste(0, ((x + 4) * 4, (y + 4) * 4, (x + 5) * 4, (y + 5) * 4))
                path = directory + '/code.png'
                image.save(path)
                decoded = subprocess.run(['zbarimg', '-q', '--raw', '-Sbinary', path], capture_output=True).stdout
                self.assertEqual(decoded.rstrip(b'\n'), text.encode())

    def test_details_reads_the_active_connection(self):
        replies = {
            ('-t', '-f', 'DEVICE,TYPE,STATE,CONNECTION', 'device'): 'wlan0:wifi:connected:Home\n',
            ('-t', '-g', 'IP4.ADDRESS,IP4.GATEWAY,IP4.DNS', 'device', 'show', 'wlan0'): '192.168.1.5/24\n192.168.1.1\n1.1.1.1 | 1.0.0.1\n',
            ('-t', '-g', 'ipv4.dns,ipv4.ignore-auto-dns,connection.autoconnect,802-11-wireless.cloned-mac-address',
             'connection', 'show', 'id', 'Home'): '1.1.1.1,1.0.0.1\nyes\nyes\nstable\n',
        }
        with patch.object(network, 'nmcli', side_effect=lambda *a: replies[a]):
            info = network.details()
        self.assertEqual(info['address'], '192.168.1.5')
        self.assertEqual(info['provider'], 'cloudflare')
        self.assertTrue(info['autoconnect'] and info['private'])

    def test_dns_change_goes_to_the_saved_connection(self):
        calls = []
        with patch.object(network, 'nmcli', side_effect=lambda *a: calls.append(a) or ''):
            network.set_dns('Home', 'quad9')
            network.set_dns('Home', 'auto')
        self.assertEqual(calls[0], ('connection', 'modify', 'id', 'Home', 'ipv4.dns', '9.9.9.9 149.112.112.112',
                                    'ipv4.ignore-auto-dns', 'yes', 'ipv6.ignore-auto-dns', 'yes'))
        self.assertEqual(calls[1][5:], ('', 'ipv4.ignore-auto-dns', 'no', 'ipv6.ignore-auto-dns', 'no'))

    def test_share_refuses_a_secured_network_without_a_saved_password(self):
        with patch.object(network, 'nmcli', return_value='Home\nwpa-psk\n\n\n'):
            with self.assertRaises(RuntimeError):
                network.share('Home')


class NearbyNetworks(unittest.TestCase):
    def test_escaped_names_dedupe_and_order(self):
        listing = (" :Home\\:5G:40:130 Mbit/s:WPA2\n*:Home\\:5G:70:270 Mbit/s:WPA2\n"
                   " :Cafe:90:54 Mbit/s:\n :Cafe:30:54 Mbit/s:\n :Weak:10:6 Mbit/s:WPA3\n")
        result = network.networks(listing, {'Home:5G'})
        self.assertEqual([n['name'] for n in result], ['Home:5G', 'Cafe', 'Weak'])
        home, cafe, weak = result
        self.assertTrue(home['connected'] and home['known'] and home['secured'])
        self.assertEqual((home['signal'], home['dbm'], home['rate']), (70, -65, 270))
        self.assertFalse(cafe['secured'] or cafe['known'])
        self.assertEqual(cafe['signal'], 90)
        self.assertEqual(weak['dbm'], -95)


class AirPods(unittest.TestCase):
    def test_model_from_metadata(self):
        state = {}
        airpods.parse(bytes.fromhex('040004001d') + bytes(6) + b'airbods\0A3064\0', state)
        self.assertEqual(state['model'], 'AirPods Pro 3')
        airpods.parse(bytes.fromhex('040004001d') + bytes(6) + b'x\0A9999\0', state)
        self.assertEqual(state['model'], 'A9999')

    def test_battery_ear_and_mode_packets(self):
        state = {}
        packet = bytes.fromhex('040004000400') + bytes([3, 2, 1, 90, 2, 1, 4, 1, 85, 1, 1, 8, 1, 40, 4, 1])
        self.assertTrue(airpods.parse(packet, state))
        self.assertEqual(state['battery'], {'right': {'level': 90, 'charging': False},
                                            'left': {'level': 85, 'charging': True}})
        airpods.parse(bytes.fromhex('040004000600') + bytes([0, 2]), state)
        self.assertEqual(state['ear'], ['ear', 'case'])
        airpods.parse(airpods.control(0x0D, 3), state)
        self.assertEqual(state['mode'], 'transparency')
        self.assertFalse(airpods.parse(airpods.control(0x0D, 3), state))

    def test_only_known_commands_are_sent(self):
        self.assertEqual(airpods.command('mode anc'), bytes.fromhex('0400040009000d02000000'))
        self.assertEqual(airpods.command('conversation off'), bytes.fromhex('0400040009002802000000'))
        self.assertIsNone(airpods.command('mode loud'))
        self.assertIsNone(airpods.command('rename x'))


if __name__ == '__main__':
    unittest.main()
