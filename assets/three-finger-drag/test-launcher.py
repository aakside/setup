#!/usr/bin/env python3
import hashlib
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest

spec = importlib.util.spec_from_file_location('launcher', Path(__file__).with_name('launch-gnome.py'))
launcher = importlib.util.module_from_spec(spec)
spec.loader.exec_module(launcher)

class UpgradeFallback(unittest.TestCase):
    def test_selection(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            shim = str(root / 'libapple-three-finger-drag.so')
            self.assertEqual(launcher.select_preload(root, '1')[0], shim)
            (root / 'private').mkdir()
            lib = root / 'private/libinput.so.10'
            lib.write_bytes(b'test library')
            metadata = root / 'private/build.json'
            metadata.write_text(json.dumps({'package_version': '1', 'sha256': hashlib.sha256(lib.read_bytes()).hexdigest()}))
            self.assertEqual(launcher.select_preload(root, '1')[0], shim + ':' + str(lib))
            self.assertEqual(launcher.select_preload(root, '2')[0], shim)
            self.assertEqual(launcher.select_preload(root, '')[0], shim)
            lib.write_bytes(b'corrupted')
            self.assertEqual(launcher.select_preload(root, '1')[0], shim)
            metadata.write_text('broken json')
            self.assertEqual(launcher.select_preload(root, '1')[0], shim)

if __name__ == '__main__': unittest.main()
