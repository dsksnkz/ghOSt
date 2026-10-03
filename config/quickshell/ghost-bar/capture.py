#!/usr/bin/env python3
"""Explicit region capture through standard Wayland tools; no legacy helper."""
from datetime import datetime
import os
from pathlib import Path
import re
import subprocess
import uuid

def geometry(value):
    if not re.fullmatch(r'-?\d+,-?\d+ [1-9]\d*x[1-9]\d*',value.strip()):
        raise ValueError('Invalid capture region')
    return value.strip()

def main():
    selection=subprocess.run(['slurp'],capture_output=True,text=True)
    if selection.returncode:return
    region=geometry(selection.stdout)
    directory=Path(os.environ.get('XDG_PICTURES_DIR',Path.home()/'Pictures'))/'Screenshots'
    directory.mkdir(parents=True,exist_ok=True)
    path=directory/('ghOSt-'+datetime.now().strftime('%Y%m%d-%H%M%S')+'-'+uuid.uuid4().hex[:8]+'.png')
    subprocess.run(['grim','-g',region,str(path)],check=True)
    path.chmod(0o600)
    try:
        subprocess.run(['wl-copy','--type','image/png'],input=path.read_bytes(),check=True)
    except (OSError,subprocess.CalledProcessError):
        pass # The saved capture remains available even without a clipboard.

if __name__=='__main__':main()
