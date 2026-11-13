#!/usr/bin/env python3
"""Measure what takes up space under a folder, like ncdu, and empty a chosen folder."""
import argparse
import json
import os
from pathlib import Path
import shutil
import stat
import sys
import time

# Emptying these would break the desktop or lose keys, so they are always refused.
PROTECTED = ('.config', '.local', '.local/share', '.local/state', '.ssh', '.gnupg', '.pki')
# Below these limits a folder's contents are summed, keeping the result small.
MIN_LISTED = 1024 * 1024
MAX_LISTED = 100
PROGRESS_SECONDS = 0.25


def cache_path():
    root = Path(os.environ.get('XDG_CACHE_HOME', Path.home() / '.cache'))
    return root / 'ghost/storage-scan.json'


class Scan:
    def __init__(self, on_progress=None):
        self.on_progress = on_progress
        self.items = 0
        self.size = 0
        self.unreadable = 0
        self.seen = set()
        self.reported = 0.0

    def progress(self):
        now = time.monotonic()
        if self.on_progress and now - self.reported >= PROGRESS_SECONDS:
            self.reported = now
            self.on_progress(self.items, self.size)

    def folder(self, path, name, device):
        """Return a node: name, size, folder flag, then listed and other children."""
        total = 0
        children = []
        try:
            with os.scandir(path) as entries:
                entries = list(entries)
        except OSError:
            self.unreadable += 1
            entries = []
        # Only entries large enough to be listed become nodes; a home folder has
        # millions of small files, and their sizes are all the result needs.
        small = small_count = 0
        seen = self.seen
        for entry in entries:
            try:
                info = entry.stat(follow_symlinks=False)
            except OSError:
                self.unreadable += 1
                continue
            self.items += 1
            if stat.S_ISDIR(info.st_mode):
                # Other mounts and subvolumes are not part of this folder's disk.
                if info.st_dev != device:
                    continue
                child = self.folder(entry.path, entry.name, device)
                size = child['s'] = child['s'] + info.st_blocks * 512
            else:
                # Hard links use their space once.
                if info.st_nlink > 1:
                    key = (info.st_dev, info.st_ino)
                    if key in seen:
                        continue
                    seen.add(key)
                size = info.st_blocks * 512
                self.size += size
                child = None
            total += size
            if size < MIN_LISTED:
                small += size
                small_count += 1
            else:
                children.append(child or {'n': entry.name, 's': size})
        self.progress()
        children.sort(key=lambda child: child['s'], reverse=True)
        listed = children[:MAX_LISTED]
        return {'n': name, 's': total, 'd': 1, 'c': listed,
                'o': small + sum(child['s'] for child in children[MAX_LISTED:]),
                'm': small_count + len(children) - len(listed)}


def scan(root, on_progress=None):
    root = Path(root)
    job = Scan(on_progress)
    tree = job.folder(root, root.name, root.stat().st_dev)
    return {'path': str(root), 'scanned': time.time(), 'items': job.items,
            'unreadable': job.unreadable, 'tree': tree}


def empty_folder(path):
    """Permanently delete a folder's contents. Returns how many entries were removed and failed."""
    home = Path.home().resolve()
    folder = Path(os.path.abspath(path))
    # resolve() differing means a symlink is somewhere in the path; never delete through one.
    if folder.resolve() != folder or folder.is_symlink() or not folder.is_dir():
        raise ValueError('not a real folder: ' + str(folder))
    if home not in folder.parents:
        raise ValueError('outside the home folder: ' + str(folder))
    if str(folder.relative_to(home)) in PROTECTED:
        raise ValueError('protected folder: ' + str(folder))
    device = folder.stat().st_dev
    removed = failed = 0
    with os.scandir(folder) as entries:
        entries = list(entries)
    for entry in entries:
        try:
            info = entry.stat(follow_symlinks=False)
            if stat.S_ISDIR(info.st_mode):
                # A mount inside the folder is another disk, not this folder's contents.
                if info.st_dev != device:
                    failed += 1
                    continue
                shutil.rmtree(entry.path)
            else:
                os.unlink(entry.path)
            removed += 1
        except OSError:
            failed += 1
    return removed, failed


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--cached', action='store_true', help='print the last result without scanning')
    parser.add_argument('--empty', action='store_true', help='permanently delete everything in path')
    parser.add_argument('path', nargs='?', default=str(Path.home()))
    args = parser.parse_args()
    if args.empty:
        try:
            removed, failed = empty_folder(args.path)
        except (OSError, ValueError) as error:
            print(json.dumps({'error': str(error)}), flush=True)
            return 1
        print(json.dumps({'removed': removed, 'failed': failed}), flush=True)
        return 0
    cache = cache_path()
    if args.cached:
        if cache.exists():
            print(cache.read_text())
        return
    os.nice(10)

    def report(items, size):
        print(json.dumps({'items': items, 'size': size}), flush=True)

    result = json.dumps(scan(args.path, report), separators=(',', ':'))
    cache.parent.mkdir(parents=True, exist_ok=True)
    temporary = cache.with_suffix('.tmp')
    temporary.write_text(result)
    temporary.replace(cache)
    print(result, flush=True)


if __name__ == '__main__':
    sys.exit(main())
