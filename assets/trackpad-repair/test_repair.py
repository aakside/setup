"""Safety checks using temporary files; never edits host input configuration."""
import hashlib
import importlib.util
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

sys.dont_write_bytecode = True

script = Path(__file__).resolve().parents[2] / 'scripts/trackpad-quirks.py'
spec = importlib.util.spec_from_file_location('repair', script)
repair = importlib.util.module_from_spec(spec)
spec.loader.exec_module(repair)


class RepairTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.base = Path(self.temp.name)
        self.file = self.base / 'old.quirks'
        self.file.write_text('AttrEventCodeDisable=BTN_RIGHT\n')
        self.manifest = {self.file.name: hashlib.sha256(self.file.read_bytes()).hexdigest()}
        p = patch.object(repair, 'BASE', self.base)
        p.start()
        self.addCleanup(p.stop)

    def unowned(self):
        return patch.object(repair.subprocess, 'run', return_value=subprocess.CompletedProcess([], 1, '', ''))

    def test_healthy_skips_all_file_checks(self):
        with patch.object(repair, 'validate', return_value=(True, '')), patch.object(repair, 'plan') as plan:
            self.assertEqual(repair.check(self.manifest), [])
            plan.assert_not_called()

    def test_check_stages_without_changing_original(self):
        def validate(directory=None):
            if directory is None:
                return False, 'Unknown key AttrEventCodeDisable'
            self.assertFalse((directory / self.file.name).exists())
            self.assertTrue((directory / (self.file.name + repair.SUFFIX)).exists())
            return True, ''
        with self.unowned(), patch.object(repair, 'validate', side_effect=validate):
            self.assertEqual(len(repair.check(self.manifest)), 1)
        self.assertTrue(self.file.exists())

    def test_unknown_failure_refused(self):
        with patch.object(repair, 'validate', return_value=(False, 'Different parser error')):
            with self.assertRaises(RuntimeError): repair.check(self.manifest)

    def test_changed_file_refused(self):
        self.file.write_text('changed')
        with self.assertRaises(RuntimeError): repair.plan(self.manifest)

    def test_package_owned_file_refused(self):
        with patch.object(repair.subprocess, 'run', return_value=subprocess.CompletedProcess([], 0, 'package', '')):
            with self.assertRaises(RuntimeError): repair.plan(self.manifest)

    def test_remaining_parser_error_refused(self):
        with self.unowned(), patch.object(repair, 'validate', side_effect=[(False, 'AttrEventCodeDisable'), (False, 'Another error')]):
            with self.assertRaises(RuntimeError): repair.check(self.manifest)
        self.assertTrue(self.file.exists())

    def test_failed_apply_rolls_back(self):
        with self.unowned(): moves = repair.plan(self.manifest)
        with patch.object(repair, 'validate', return_value=(False, 'failure')):
            with self.assertRaises(RuntimeError): repair.execute(moves)
        self.assertTrue(self.file.exists())
        self.assertFalse(self.file.with_name(self.file.name + repair.SUFFIX).exists())

    def test_apply_undo_and_idempotent_plan(self):
        with self.unowned(), patch.object(repair, 'validate', return_value=(True, '')):
            repair.execute(repair.plan(self.manifest))
            self.assertEqual(repair.plan(self.manifest), [])
            repair.execute(repair.plan(self.manifest, undo=True), undo=True)
            self.assertEqual(repair.plan(self.manifest, undo=True), [])
        self.assertTrue(self.file.exists())


if __name__ == '__main__':
    unittest.main()
