"""Data integrity checks for the telemetry CLI used by Stop/SubagentStop hooks."""

import importlib.util
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
from unittest import TestCase, main, mock, skipIf


ROOT = Path(__file__).resolve().parents[1]
ENGINE = ROOT / "scripts" / "telemetry-log.py"


def load_engine():
    spec = importlib.util.spec_from_file_location("telemetry_log_integrity", ENGINE)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


class TelemetryIntegrityTests(TestCase):
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

    def test_fmt_cost_reexported_from_report_helper(self):
        # Engine nạp helper qua sys.path nên module nằm sẵn trong sys.modules; nạp lại bằng
        # spec_from_file_location sẽ ra bản sao khác danh tính.
        self.assertIs(self.engine.fmt_cost, sys.modules["_telemetry_report"].fmt_cost)

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

    @skipIf(os.name == "nt", "POSIX lock retry; Windows path is exercised by process test")
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


class AttemptOutcomeTests(TestCase):
    """LD-07 / AC-7: usage thiếu là unknown (không phải 0); lần thử khác công việc được nghiệm thu."""

    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.directory = Path(self.temp.name)
        self.log = self.directory / "telemetry.json"
        self.engine = load_engine()
        self.engine.LOG_DIR = str(self.directory)
        self.engine.LOG_FILE = str(self.log)

    def cli(self, *args):
        code = (
            "import importlib.util,sys;"
            "s=importlib.util.spec_from_file_location('t',sys.argv[1]);"
            "m=importlib.util.module_from_spec(s);s.loader.exec_module(m);"
            "m.LOG_DIR=sys.argv[2];m.LOG_FILE=sys.argv[3];sys.argv=['telemetry-log.py']+sys.argv[4:];m.main()"
        )
        return subprocess.run(
            [sys.executable, "-c", code, str(ENGINE), str(self.directory), str(self.log), *args],
            capture_output=True, text=True, encoding="utf-8",
        )

    def evidence(self, status="PASS", schema="gate-evidence/1"):
        path = self.directory / f"ev-{status}-{schema.replace('/', '_')}.json"
        path.write_text(json.dumps({"schema": schema, "status": status, "head": "abc",
                                    "config_sha": "def", "worktree": "123"}), encoding="utf-8")
        return str(path)

    def entries(self):
        return json.loads(self.log.read_text(encoding="utf-8")) if self.log.exists() else []

    def test_missing_usage_is_unknown_not_zero(self):
        result = self.cli("--record", "--model", "claude-sonnet-5", "--task", "t")
        self.assertEqual(result.returncode, 0, result.stderr)
        entry = self.entries()[-1]
        self.assertIsNone(entry["input_tokens"])
        self.assertIsNone(entry["output_tokens"])
        self.assertIsNone(entry["est_cost_usd"])
        self.assertEqual(entry["usage_status"], "unknown")
        self.assertEqual(entry["schema"], "telemetry-record/2")
        self.assertIn("unknown", result.stderr)

    def test_explicit_zero_is_measured(self):
        entry = self.engine.record_entry("claude", "anthropic", "claude-sonnet-5", "a", "t", 1, 0, "PASSED", 0, 0)
        self.assertEqual(entry["usage_status"], "measured")
        self.assertEqual(entry["est_cost_usd"], 0)

    def test_partial_usage_has_no_cost(self):
        entry = self.engine.record_entry("claude", "anthropic", "claude-sonnet-5", "a", "t", 1, 0, "PASSED", 10, None)
        self.assertEqual(entry["usage_status"], "partial")
        self.assertIsNone(entry["est_cost_usd"])

    def test_summary_reports_unknown_as_lower_bound(self):
        self.engine.record_entry("claude", "anthropic", "claude-sonnet-5", "a", "t1", 1, 0, "PASSED", 1_000_000, 0)
        self.engine.record_entry("claude", "anthropic", "claude-sonnet-5", "a", "t2", 1, 0, "PASSED", None, None)
        summary = self.engine.generate_markdown_summary(self.engine.load_logs())
        self.assertIn("usage unknown: 1", summary)
        self.assertIn("≥ $2.0000", summary)
        self.assertNotIn("$0.0000", summary.split("### ")[1] if "### " in summary else "")

    def test_failed_attempts_count_in_cost_of_accepted_work(self):
        self.engine.record_entry("claude", "anthropic", "claude-sonnet-5", "a", "fix", 1, 0, "FAILED",
                                 1_000_000, 0, work_id="W1")
        self.engine.record_entry("claude", "anthropic", "claude-sonnet-5", "a", "fix", 1, 0, "PASSED",
                                 500_000, 0, work_id="W1", outcome="accepted", evidence_path=self.evidence())
        stats = self.engine.aggregate(self.engine.load_logs())
        self.assertEqual(stats["attempts"], 2)
        self.assertEqual(stats["works"], 1)
        self.assertEqual(stats["accepted"], 1)
        self.assertAlmostEqual(stats["cost_per_accepted"], 3.0)
        self.assertFalse(stats["cost_per_accepted_partial"])
        summary = self.engine.generate_markdown_summary(self.engine.load_logs())
        self.assertIn("Lần thử (attempts):** `2`", summary)
        self.assertIn("được nghiệm thu (có evidence): `1`", summary)

    def test_accepted_requires_pass_gate_evidence(self):
        cases = [(), ("--evidence", self.evidence("FAIL")),
                 ("--evidence", self.evidence(schema="other/1")),
                 ("--evidence", str(self.directory / "khong-co.json"))]
        for extra in cases:
            result = self.cli("--record", "--outcome", "accepted", "--input-tokens", "1", "--output-tokens", "1", *extra)
            self.assertEqual(result.returncode, 2, (extra, result.stdout, result.stderr))
        self.assertEqual(self.entries(), [])
        ok = self.cli("--record", "--outcome", "accepted", "--work-id", "W9", "--evidence", self.evidence())
        self.assertEqual(ok.returncode, 0, ok.stderr)
        entry = self.entries()[-1]
        self.assertEqual(entry["outcome"], "accepted")
        self.assertEqual(entry["evidence"]["status"], "PASS")
        self.assertEqual(entry["evidence"]["head"], "abc")

    def test_self_reported_pass_is_not_acceptance(self):
        self.engine.record_entry("claude", "anthropic", "claude-sonnet-5", "a", "t", 1, 0, "PASSED", 1, 1)
        stats = self.engine.aggregate(self.engine.load_logs())
        self.assertEqual((stats["attempts"], stats["accepted"]), (1, 0))
        self.assertIsNone(stats["cost_per_accepted"])

    def test_v1_records_are_read_without_crash(self):
        legacy = [{"task": "old"},
                  {"id": "tel-1", "harness": "claude", "agent": "a", "task": "v1", "duration_sec": 1,
                   "diff_loc": 0, "test_status": "N/A", "input_tokens": 0, "output_tokens": 0, "est_cost_usd": 0.0}]
        self.log.write_text(json.dumps(legacy), encoding="utf-8")
        logs = self.engine.load_logs()
        stats = self.engine.aggregate(logs)
        self.assertEqual((stats["attempts"], stats["unknown"], stats["v1"]), (2, 2, 2))
        self.assertIn("v1", self.engine.generate_markdown_summary(logs))
        self.engine.generate_html_widget(logs)
        self.assertEqual(json.loads(self.log.read_text(encoding="utf-8")), legacy)

    def test_record_keeps_only_declared_fields(self):
        entry = self.engine.record_entry("claude", "anthropic", "claude-sonnet-5", "a", "t", 1, 0, "PASSED", 1, 1)
        self.assertEqual(set(entry), {
            "schema", "id", "timestamp", "harness", "provider", "model", "agent", "task", "work_id",
            "outcome", "duration_sec", "diff_loc", "test_status", "input_tokens", "output_tokens",
            "usage_status", "est_cost_usd", "evidence",
        })


if __name__ == "__main__":
    main()
