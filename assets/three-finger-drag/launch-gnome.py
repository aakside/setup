#!/usr/bin/env python3
"""Load the private build only while it matches Ubuntu's installed package."""
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys


def select_preload(directory, installed_version):
    shim = directory / 'libapple-three-finger-drag.so'
    private = directory / 'private/libinput.so.10'
    try:
        metadata = json.loads((directory / 'private/build.json').read_text())
        if metadata['package_version'] != installed_version:
            return str(shim), 'package version changed; using stock libinput until rebuilt'
        if hashlib.sha256(private.read_bytes()).hexdigest() != metadata['sha256']:
            return str(shim), 'private library checksum mismatch; using stock libinput'
    except (OSError, ValueError, KeyError):
        return str(shim), 'private build unavailable; using stock libinput'
    return f'{shim}:{private}', 'using matching private libinput (Magic Trackpad 2 always-drag)'


def main():
    directory = Path(__file__).resolve().parent
    try:
        version = subprocess.check_output(
            ['/usr/bin/dpkg-query', '-W', '-f=${Version}', 'libinput10'], text=True).strip()
    except (OSError, subprocess.CalledProcessError):
        version = ''
    preload, message = select_preload(directory, version)
    print('[apple-three-finger-drag] ' + message, file=sys.stderr, flush=True)
    environment = dict(os.environ, LD_PRELOAD=preload)
    os.execve('/usr/bin/gnome-shell', ['/usr/bin/gnome-shell', '--mode=ubuntu'], environment)


if __name__ == '__main__':
    main()
