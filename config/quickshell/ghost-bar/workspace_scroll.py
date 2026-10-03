#!/usr/bin/env python3
"""Scroll through 1–5 plus populated numbered workspaces; never empty 6+."""
import argparse
import fcntl
import json
import os
from pathlib import Path
import subprocess

def choose(current, direction, workspaces, steps=1):
    allowed=sorted(set(range(1,6)) | {int(w['id']) for w in workspaces if w.get('id',0)>5 and w.get('windows',0)>0})
    ring=sorted(set(allowed+[current]))
    index=ring.index(current)
    for _ in range(max(1,min(abs(int(steps)),20))):
        index=(index+(1 if direction>0 else -1))%len(ring)
        while ring[index] not in allowed:
            index=(index+(1 if direction>0 else -1))%len(ring)
    return ring[index]

def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('direction',type=int)
    parser.add_argument('steps',type=int,nargs='?',default=1)
    parser.add_argument('--dry-run',action='store_true')
    args=parser.parse_args()
    runtime=Path(os.environ.get('XDG_RUNTIME_DIR','/tmp'))
    with (runtime/f'ghost-workspace-{os.getuid()}.lock').open('a') as lock:
        fcntl.flock(lock,fcntl.LOCK_EX)
        monitors=json.loads(subprocess.check_output(['hyprctl','-j','monitors'],text=True))
        monitor=next((m for m in monitors if m.get('focused')),monitors[0])
        current=int(monitor['activeWorkspace']['id'])
        workspaces=json.loads(subprocess.check_output(['hyprctl','-j','workspaces'],text=True))
        target=choose(current,args.direction,workspaces,args.steps)
        if args.dry_run: print(target)
        else: subprocess.run(['hyprctl','dispatch',f'hl.dsp.focus({{ workspace = {target} }})'],check=True,stdout=subprocess.DEVNULL)

if __name__=='__main__': main()
