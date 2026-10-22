#!/usr/bin/env python3
"""Reproducible, version-pinned private build; never installs system files."""
import hashlib
import json
from pathlib import Path
import shutil
import subprocess
import urllib.request

HERE = Path(__file__).resolve().parent
VERSION = '1.31.1-1ubuntu1.2'
FILES = {
    'libinput_1.31.1.orig.tar.gz': '72c7d62a117f89a0e611d76b0a28ba8bf08fc24083d2678060aee8de88c87953',
    'libinput_1.31.1-1ubuntu1.2.debian.tar.xz': '7f92934f77f382e262962a088ee84860891368b26ca039700d2112d3fa6fee61',
}


def run(*args, **kwargs):
    subprocess.run(args, check=True, **kwargs)


def main():
    installed = subprocess.check_output(['dpkg-query', '-W', '-f=${Version}', 'libinput10'], text=True).strip()
    if installed != VERSION:
        raise SystemExit(f'This patch is verified only for {VERSION}; installed: {installed}. Update the source pin and retest first.')
    work = HERE / 'build/private-work'
    work.mkdir(parents=True, exist_ok=True)
    for name, expected in FILES.items():
        archive = work / name
        if not archive.exists():
            urllib.request.urlretrieve('https://us.archive.ubuntu.com/ubuntu/pool/main/libi/libinput/' + name, archive)
        if hashlib.sha256(archive.read_bytes()).hexdigest() != expected:
            raise SystemExit('Archive checksum mismatch: ' + str(archive))
    source = work / 'source'
    build = work / 'compiled'
    for directory in (source, build):
        if directory.exists(): shutil.rmtree(directory)
    source.mkdir()
    run('tar', '-xf', str(work / 'libinput_1.31.1.orig.tar.gz'), '--strip-components=1', '-C', str(source))
    run('tar', '-xf', str(work / 'libinput_1.31.1-1ubuntu1.2.debian.tar.xz'), '-C', str(source))
    patches = source / 'debian/patches'
    for line in (patches / 'series').read_text().splitlines():
        if line.strip() and not line.startswith('#'):
            run('patch', '-p1', '--batch', '--forward', '-i', str(patches / line.strip()), cwd=source)
    for name in ('always-drag.patch', 'always-drag-test.patch'):
        run('patch', '-p1', '--batch', '--forward', '-i', str(HERE / name), cwd=source)
    run('meson', 'setup', str(build), str(source), '--prefix=/usr', '-Ddebug-gui=false',
        '-Ddocumentation=false', '-Dtests=true', '-Dlua-plugins=disabled')
    run('ninja', '-C', str(build))
    # Keep source/build for focused uinput tests; never run ninja install.
    output = HERE / 'build/private'
    output.mkdir(exist_ok=True)
    library = output / 'libinput.so.10'
    shutil.copyfile(build / 'libinput.so.10.13.0', library)
    (output / 'build.json').write_text(json.dumps({
        'package_version': VERSION,
        'sha256': hashlib.sha256(library.read_bytes()).hexdigest(),
        'source_sha256': FILES,
    }, indent=2) + '\n')
    print('Built private libinput. No installation performed.')


if __name__ == '__main__':
    main()
