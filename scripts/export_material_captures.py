#!/usr/bin/env python3
"""Export allowlisted fixture crops only; exclude rail MPRIS/private desktop data."""
from pathlib import Path
import sys
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
captures = Path(sys.argv[1])
output = ROOT / 'docs/images/2026-10-24-material-icons'
output.mkdir(parents=True, exist_ok=True)
site = ROOT / 'site/assets'


def crop(name, box, destination):
    with Image.open(captures / (name + '.png')) as image:
        image.crop(box).convert('RGB').save(destination)


for name in ('general', 'sound', 'battery', 'widgets', 'brightness', 'wallpaper',
             'notifications', 'network', 'bluetooth', 'airplane', 'accessibility',
             'storage', 'applications', 'about'):
    crop('settings-' + name, (488, 176, 1588, 936), site / ('settings-' + name + '.webp'))
crop('settings-general', (524, 212, 1548, 911), site / 'settings-dark.png')
crop('settings-applications', (524, 212, 1548, 911), site / 'applications-top-bar.png')
crop('sidebar-frame', (0, 144, 356, 938), site / 'sidebar-material.png')
crop('calendar-frame', (550, 82, 1370, 429), site / 'calendar-native.png')
for name in ('settings-dark.png', 'sidebar-material.png', 'calendar-native.png'):
    with Image.open(site / name) as image:
        image.save(output / name)
print('Exported cropped sample-data Settings, sidebar and calendar; no rail/private titles')
