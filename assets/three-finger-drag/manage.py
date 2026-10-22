#!/usr/bin/env python3
"""Install/disable a user-scoped GNOME Ubuntu-session three-finger-drag helper."""
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys

HERE = Path(__file__).resolve().parent
HOME = Path.home()
LIB = HOME / '.local/lib/apple-three-finger-drag/libapple-three-finger-drag.so'
DROPIN = Path(os.environ.get('XDG_CONFIG_HOME', HOME / '.config')) / 'systemd/user/org.gnome.Shell@ubuntu.service.d/60-apple-three-finger-drag.conf'
CONTENT = '[Service]\nEnvironment="LD_PRELOAD=' + str(LIB) + '"\n'

LAUNCHER = LIB.parent / 'launch-gnome.py'
PRIVATE_CONTENT = CONTENT + 'ExecStart=\nExecStart=/usr/bin/python3 ' + str(LAUNCHER) + '\n'
KNOWN = (CONTENT, PRIVATE_CONTENT)

def copy_atomic(source, destination):
    destination.parent.mkdir(parents=True, exist_ok=True)
    temporary = destination.with_name(destination.name + '.new')
    shutil.copyfile(source, temporary)
    temporary.chmod(0o644)
    temporary.replace(destination)

def run(*args):
    return subprocess.check_output(args, text=True).strip()

def main():
    if os.geteuid() == 0:
        sys.exit('Run as your normal desktop user, without sudo.')
    if len(sys.argv) != 2 or sys.argv[1] not in ('install', 'install-private', 'use-stock', 'disable', 'status'):
        sys.exit('Usage: python3 manage.py install|install-private|use-stock|disable|status')
    action = sys.argv[1]
    if action == 'status':
        print(run('systemctl', '--user', 'show', 'org.gnome.Shell@ubuntu.service',
                  '-p', 'Environment', '-p', 'DropInPaths', '-p', 'ActiveState'))
        return
    if action == 'disable':
        if DROPIN.exists():
            if DROPIN.read_text() not in KNOWN:
                sys.exit('Refusing to change an edited drop-in: ' + str(DROPIN))
            DROPIN.unlink()
            print('Disabled: ' + str(DROPIN))
    else:
        if any(c in str(LIB) for c in '\n\r"%: '):
            sys.exit('Unsupported characters in install path')
        if os.environ.get('XDG_SESSION_TYPE') != 'wayland':
            sys.exit('This installer targets your Ubuntu GNOME Wayland session.')
        environment = run('systemctl', '--user', 'show-environment')
        service_env = run('systemctl', '--user', 'show', 'org.gnome.Shell@ubuntu.service', '-p', 'Environment', '--value')
        if any(line.startswith('LD_PRELOAD=') for line in environment.splitlines()):
            sys.exit('Existing manager LD_PRELOAD; resolve manually rather than overwrite.')
        if 'LD_PRELOAD=' in service_env and not (DROPIN.exists() and DROPIN.read_text() in KNOWN):
            sys.exit('Existing service LD_PRELOAD; resolve manually rather than overwrite.')
        if DROPIN.exists() and DROPIN.read_text() not in KNOWN:
            sys.exit('Refusing to overwrite existing drop-in')
        source = HERE / 'build' / LIB.name
        expected = (HERE / 'build/library.sha256').read_text().split()[0]
        if hashlib.sha256(source.read_bytes()).hexdigest() != expected:
            sys.exit('Library checksum mismatch; rebuild and regenerate checksum.')
        content = CONTENT
        if action == 'install' and DROPIN.exists() and DROPIN.read_text() == PRIVATE_CONTENT:
            content = PRIVATE_CONTENT
        if action == 'install-private':
            private = HERE / 'build/private'
            metadata = json.loads((private / 'build.json').read_text())
            if metadata['package_version'] != run('dpkg-query', '-W', '-f=${Version}', 'libinput10'):
                sys.exit('Package version changed since build; rebuild first.')
            if hashlib.sha256((private / 'libinput.so.10').read_bytes()).hexdigest() != metadata['sha256']:
                sys.exit('Private library checksum mismatch; rebuild first.')
            copy_atomic(private / 'libinput.so.10', LIB.parent / 'private/libinput.so.10')
            copy_atomic(private / 'build.json', LIB.parent / 'private/build.json')
            copy_atomic(HERE / 'launch-gnome.py', LAUNCHER)
            content = PRIVATE_CONTENT
        copy_atomic(source, LIB)
        DROPIN.parent.mkdir(parents=True, exist_ok=True)
        DROPIN.write_text(content)
        print('Installed: ' + str(LIB))
        print('Installed: ' + str(DROPIN))
    subprocess.run(['systemctl', '--user', 'daemon-reload'], check=True)
    print('Save work, log out and back in. The running session has not been restarted.')

if __name__ == '__main__':
    main()
