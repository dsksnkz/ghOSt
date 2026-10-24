#!/usr/bin/env python3
"""Install only Intro's launcher entry/icon, snapshotting any exact existing files."""
import argparse
from datetime import datetime
import json
import os
from pathlib import Path
import shutil

ROOT = Path(__file__).resolve().parents[1]


def install():
    data = Path(os.environ.get('XDG_DATA_HOME', Path.home() / '.local/share'))
    state = Path(os.environ.get('XDG_STATE_HOME', Path.home() / '.local/state'))
    backup = state / 'ghost/backups' / datetime.now().strftime('intro-%Y%m%d-%H%M%S-%f')
    backup.mkdir(parents=True)
    files = [(ROOT / 'config/applications/ghost-intro.desktop', data / 'applications/ghost-intro.desktop'),
             (ROOT / 'config/quickshell/ghost-bar/icons/white/ghost.svg',
              data / 'icons/hicolor/scalable/apps/ghost-intro.svg')]
    record = []
    for index, (source, target) in enumerate(files):
        saved = backup / str(index)
        if target.exists():
            shutil.copy2(target, saved)
        record.append({'target': str(target), 'saved': str(saved) if target.exists() else None})
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source, target)
    (backup / 'before.json').write_text(json.dumps(record, indent=2) + '\n')
    print('Installed ghOSt Intro entry and icon; snapshot: ' + str(backup))


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--apply', action='store_true')
    if parser.parse_args().apply:
        install()
    else:
        print('Desktop unchanged. Install deliberately with --apply after deploying Intro and its floating rule.')
