"""Data integrity checks for the telemetry CLI used by Stop/SubagentStop hooks."""

import importlib.util
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest import mock


ROOT = Path(__file__).resolve().parents[1]
ENGINE = ROOT / "scripts" / "telemetry-log.py"


def load_engine():
    spec = importlib.util.spec_from_file_location("telemetry_log_integrity", ENGINE)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


class TelemetryIntegrityTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.directory = Path(self.temp.name)
        self.log = self.directory / "telemetry.json"
        self.engine = load_engine()
        self.engine.LOG_DIR = str(self.directory)
        self.engine.LOG_FILE = str(self.log)

    def record(self):
        return self.engine.record_entry(
            "claude", "anthropic", "claude-sonnet-5", "tester", "integrity",
            5, 1, "PASSED", 100, 20,
        )

    def test_new_log_and_empty_summary(self):
        self.assertFalse(self.log.exists())
        self.assertIn("Chưa có dữ liệu", self.engine.generate_markdown_summary(self.engine.load_logs()))
        self.record()
        self.assertEqual(len(json.loads(self.log.read_text(encoding="utf-8"))), 1)

    def test_corrupted_json_is_preserved(self):
        original = b'[{"task":"old"},'
        self.log.write_bytes(original)
        with self.assertRaises((ValueError, OSError)):
            self.record()
        self.assertEqual(self.log.read_bytes(), original)

    def test_wrong_root_type_is_preserved(self):
        original = b'{"task":"old"}'
        self.log.write_bytes(original)
        with self.assertRaises(ValueError):
            self.record()
        self.assertEqual(self.log.read_bytes(), original)

    def test_failed_atomic_replace_preserves_previous_log(self):
        self.log.write_text('[{"task":"old"}]', encoding="utf-8")
        with mock.patch.object(self.engine.os, "replace", side_effect=OSError("simulated")):
            with self.assertRaises(OSError):
                self.record()
        self.assertEqual(json.loads(self.log.read_text(encoding="utf-8")), [{"task": "old"}])

    def test_simultaneous_processes_keep_every_entry(self):
        # Delay each save after the read to expose an unlocked read/modify/write race.
        start = self.directory / "start"
        worker = r'''
import importlib.util, pathlib, sys, time
spec = importlib.util.spec_from_file_location("telemetry_worker", sys.argv[1])
mod = importlib.util.module_from_spec(spec); spec.loader.exec_module(mod)
mod.LOG_DIR = sys.argv[2]; mod.LOG_FILE = str(pathlib.Path(sys.argv[2]) / "telemetry.json")
original = mod.save_logs
def delayed(logs):
    time.sleep(0.1)
    return original(logs)
mod.save_logs = delayed
while not pathlib.Path(sys.argv[3]).exists(): time.sleep(0.005)
mod.record_entry("claude", "anthropic", "claude-sonnet-5", "tester", sys.argv[4], 5, 1, "PASSED", 1, 1)
'''
        processes = [subprocess.Popen(
            [sys.executable, "-c", worker, str(ENGINE), str(self.directory), str(start), str(n)],
            stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True,
        ) for n in range(6)]
        start.touch()
        for process in processes:
            output, error = process.communicate(timeout=15)
            self.assertEqual(process.returncode, 0, output + error)
        logs = json.loads(self.log.read_text(encoding="utf-8"))
        self.assertEqual({entry["task"] for entry in logs}, {str(n) for n in range(6)})

    @unittest.skipIf(os.name == "nt", "POSIX lock retry; Windows path is exercised by process test")
    def test_busy_lock_waits_then_records(self):
        ready = self.directory / "ready"
        holder = r'''
import fcntl, pathlib, sys, time
with open(sys.argv[1], "a+b") as lock:
    lock.write(b"\0"); lock.flush()
    fcntl.flock(lock.fileno(), fcntl.LOCK_EX)
    pathlib.Path(sys.argv[2]).touch()
    time.sleep(0.25)
'''
        process = subprocess.Popen(
            [sys.executable, "-c", holder, f"{self.log}.lock", str(ready)],
            stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True,
        )
        try:
            for _ in range(200):
                if ready.exists():
                    break
                self.engine.time.sleep(0.005)
            self.assertTrue(ready.exists())
            self.record()
            self.assertEqual(len(json.loads(self.log.read_text(encoding="utf-8"))), 1)
        finally:
            process.communicate(timeout=5)


if __name__ == "__main__":
    unittest.main()
