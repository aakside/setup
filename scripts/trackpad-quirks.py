#!/usr/bin/env python3
"""Check for, repair, or undo the known obsolete libinput quirks defect."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile

BASE = Path('/usr/share/libinput')
MANIFEST_PATH = Path(__file__).resolve().parent.parent / 'assets/trackpad-repair/manifest.json'
SUFFIX = '.disabled-trackpad-repair'


def validate(directory=None):
    command = ['libinput', 'quirks', 'validate']
    if directory is not None:
        command += ['--data-dir', str(directory)]
    result = subprocess.run(command, capture_output=True, text=True, check=False)
    return result.returncode == 0, result.stdout + result.stderr


def plan(manifest, undo=False):
    moves = []
    for name, digest in manifest.items():
        original, disabled = BASE / name, BASE / (name + SUFFIX)
        src, dst = (disabled, original) if undo else (original, disabled)
        if src.is_symlink() or dst.is_symlink():
            raise RuntimeError(f'Refusing symlink: {src} or {dst}')
        # Accept already-applied/already-undone files, but verify their identity.
        if not src.exists() and dst.is_file():
            if hashlib.sha256(dst.read_bytes()).hexdigest() == digest:
                continue
        if not src.is_file() or dst.exists():
            raise RuntimeError(f'Unexpected file state: {src}, {dst}')
        if hashlib.sha256(src.read_bytes()).hexdigest() != digest:
            raise RuntimeError(f'Contents differ from the known obsolete file: {src}')
        owner = subprocess.run(['dpkg-query', '-S', str(original)], capture_output=True, text=True)
        if owner.returncode != 1:
            raise RuntimeError(f'File is package-owned or ownership query failed: {original}')
        moves.append((src, dst))
    return moves


def check(manifest):
    valid, diagnostic = validate()
    if valid:
        print('Quirks database is valid. This repair is not needed; no changes made.')
        return []
    print(diagnostic, end='' if diagnostic.endswith('\n') else '\n')
    if 'AttrEventCodeDisable' not in diagnostic:
        raise RuntimeError('This is not the known obsolete-key error. Investigate the diagnostic; no repair attempted.')
    moves = plan(manifest)
    if not moves:
        raise RuntimeError('Known files are already disabled; a different file needs investigation.')
    # Validate the full database with the exact proposed changes before touching it.
    # libinput still reads the real /etc/libinput/local-overrides.quirks.
    with tempfile.TemporaryDirectory(prefix='trackpad-quirks-') as temporary:
        staged = Path(temporary) / 'quirks'
        shutil.copytree(BASE, staged)
        for src, dst in moves:
            (staged / src.name).rename(staged / dst.name)
        valid, diagnostic = validate(staged)
        if not valid:
            raise RuntimeError('Proposed repair does not fix the full database:\n' + diagnostic)
    print('Known repair is applicable. These unowned files would be renamed:')
    for src, dst in moves:
        print(f'  {src} -> {dst.name}')
    return moves


def execute(moves, undo=False):
    completed = []
    try:
        for src, dst in moves:
            src.rename(dst)
            completed.append((src, dst))
            print(f'Renamed {src} -> {dst}')
        if not undo:
            valid, diagnostic = validate()
            if not valid:
                raise RuntimeError('Validation failed; restoring original filenames:\n' + diagnostic)
    except BaseException:
        for src, dst in reversed(completed):
            dst.rename(src)
        raise
    print('Original files restored (this may restore the parser error).' if undo else 'Repair validated.')
    if moves:
        print('Save work, log out and back in. No session restart was performed.')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('action', nargs='?', choices=['check', 'apply', 'undo'], default='check')
    args = parser.parse_args()
    try:
        manifest = json.loads(MANIFEST_PATH.read_text())
        if args.action == 'undo':
            if os.geteuid() != 0:
                raise RuntimeError('Undo requires sudo.')
            execute(plan(manifest, undo=True), undo=True)
            return 0
        moves = check(manifest)
        if not moves:
            return 0
        if args.action == 'check':
            print('No system changes made. To apply: sudo python3 scripts/trackpad-quirks.py apply')
            return 1
        if os.geteuid() != 0:
            raise RuntimeError('Apply requires sudo.')
        execute(moves)
        return 0
    except (OSError, RuntimeError, ValueError) as error:
        print(f'Cannot proceed: {error}')
        return 2


if __name__ == '__main__':
    raise SystemExit(main())
