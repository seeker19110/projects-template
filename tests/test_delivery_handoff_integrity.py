"""Offline producer integrity: metadata is not authenticated approval."""
import contextlib
import copy
import hashlib
import importlib
import io
import json
import runpy
import sys
import tempfile
import unittest
from pathlib import Path
from unittest import mock

SCRIPTS = Path(__file__).resolve().parents[1] / "scripts"
sys.path.insert(0, str(SCRIPTS))
compiler = importlib.import_module("spec-compiler")

SPEC = """# Feature spec: Handoff\n\n| Thuộc tính | Giá trị |\n| --- | --- |\n| State | **Approved for implementation** |\n| Approver / date | human:reviewer / 2026-09-26 |\n\n## 9. Acceptance criteria\n- AC-1 Export deterministic data, never execute commands.\n"""


def policy():
    # A producer does not interpret JSON Schema. The native consumer pins its FULL real policy.
    return {"protocol": "xagents-template-handoff/1", "source": {
        "repository": "seeker19110/projects-template", "revision": "a" * 40},
        "delivery_schema": {"title": "DeliveryContract", "type": "object"}, "max_spec_bytes": 1048576}


def plan():
    return {"adoption": "brownfield", "completion_level": "done", "spec": {
        "artifact_ref": "docs/spec.md", "approval_record": "approval:fixture-only",
        "approved_by": "human:reviewer", "approved_at": "2026-09-26T00:00:00Z"},
        "research_refs": ["research:fixture"], "baseline_ref": "baseline:fixture",
        "no_change_rationale": "Manual transfer can bind the wrong spec.",
        "alternatives_and_tradeoffs": "Reuse native policy; do not fork its validator.",
        "acceptance_tests": [{"acceptance_id": "AC-1", "test_ref": "tests/test_handoff.py"}],
        "gates": [{"id": "unit", "phase": "done", "mechanism": "command", "applicable": True,
                   "command": ["python", "-m", "unittest"]}]}


class ApprovalMetadataTests(unittest.TestCase):
    def parse(self, text):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "spec.md"
            path.write_text(text, encoding="utf-8")
            return compiler.parse_spec_markdown(str(path))

    def test_draft_instruction_is_not_approval(self):
        text = SPEC.replace("**Approved for implementation**", "Draft")
        text += "\nNever code before Approved for implementation.\n"
        self.assertFalse(self.parse(text)["approved"])

    def test_unselected_template_options_are_not_approval(self):
        text = SPEC.replace("**Approved for implementation**", "Draft / In review / **Approved for implementation**")
        self.assertFalse(self.parse(text)["approved"])

    def test_body_without_metadata_is_not_approval(self):
        self.assertFalse(self.parse("# Draft\nDo not mark Approved for implementation yet.\n")["approved"])

    def test_duplicate_state_is_rejected(self):
        text = SPEC.replace("| Approver / date", "| State | Draft |\n| Approver / date")
        with self.assertRaises(ValueError):
            self.parse(text)

    def test_exact_state_and_markup_are_supported(self):
        self.assertTrue(self.parse(SPEC)["approved"])
        self.assertTrue(self.parse(SPEC.replace("**Approved for implementation**", "approved for implementation"))["approved"])

    def test_parse_text_and_file_match(self):
        parsed = compiler.parse_spec_text(SPEC, "spec.md")
        self.assertEqual(parsed["requirement_ids"], ["AC-1"])
        self.assertTrue(parsed["approved"])


class HandoffIntegrityTests(unittest.TestCase):
    def setUp(self):
        self.exporter = importlib.import_module("delivery-handoff")
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        (self.root / "docs").mkdir()
        (self.root / "docs/spec.md").write_text(SPEC, encoding="utf-8")

    def build(self, source=None, rules=None):
        return self.exporter.build_handoff(self.root, plan() if source is None else source,
                                           policy() if rules is None else rules)

    def test_deterministic_nonmutating_bound_spec(self):
        source, rules = plan(), policy()
        before = copy.deepcopy((source, rules))
        first = self.build(source, rules)
        self.assertEqual(first, self.build(source, rules))
        self.assertEqual((source, rules), before)
        self.assertEqual(set(first), {"protocol", "policy_sha256", "delivery"})
        self.assertEqual(first["delivery"]["source_revision"], rules["source"]["revision"])
        self.assertEqual(first["delivery"]["spec"]["artifact_sha256"],
                         hashlib.sha256((self.root / "docs/spec.md").read_bytes()).hexdigest())
        self.assertEqual(first["policy_sha256"], hashlib.sha256(self.exporter.canonical(rules)).hexdigest())

    def test_crlf_spec_preserves_original_byte_hash(self):
        raw = SPEC.replace("\n", "\r\n").encode("utf-8")
        (self.root / "docs/spec.md").write_bytes(raw)
        self.assertEqual(self.build()["delivery"]["spec"]["artifact_sha256"], hashlib.sha256(raw).hexdigest())

    def test_no_shell_execution_or_writes(self):
        source = plan()
        marker = self.root / "must-not-exist"
        source["gates"][0]["command"] = [sys.executable, "-c", "open(%r, 'w').close()" % str(marker)]
        self.assertEqual(self.build(source)["delivery"]["gates"], source["gates"])
        self.assertFalse(marker.exists())

    def test_draft_and_missing_approver_fail(self):
        for text in (SPEC.replace("**Approved for implementation**", "Draft"),
                     SPEC.replace("human:reviewer / 2026-09-26", "")):
            with self.subTest(text=text):
                (self.root / "docs/spec.md").write_text(text, encoding="utf-8")
                with self.assertRaises(ValueError):
                    self.build()

    def test_bad_policy(self):
        mutations = [lambda p: p.update(protocol="unknown"), lambda p: p.update(extra=True),
                     lambda p: p.update(source=[]), lambda p: p["source"].update(repository="attacker/repo"),
                     lambda p: p["source"].update(revision="main"),
                     lambda p: p.update(delivery_schema=[]), lambda p: p.update(delivery_schema={}),
                     lambda p: p.update(max_spec_bytes=True), lambda p: p.update(max_spec_bytes=0),
                     lambda p: p.update(max_spec_bytes=1048577)]
        for mutate in mutations:
            rules = policy()
            mutate(rules)
            with self.subTest(rules=rules), self.assertRaises(ValueError):
                self.build(rules=rules)
        with self.assertRaises(ValueError):
            self.build(rules=[])

    def test_unsafe_and_missing_spec_paths(self):
        for ref in ("../spec.md", "/spec.md", "C:/spec.md", "docs\\spec.md", "", "docs/../spec.md",
                    "docs/missing.md", "docs", "docs/./spec.md", "./docs/spec.md", "docs//spec.md"):
            source = plan()
            source["spec"]["artifact_ref"] = ref
            with self.subTest(ref=ref), self.assertRaises((ValueError, OSError)):
                self.build(source)

    def test_symlink_escape_using_resolver(self):
        outside = self.root.parent / "outside-spec.md"
        # Resolver injection works on Windows without symlink privileges.
        real_resolve = Path.resolve
        def redirect(path, *args, **kwargs):
            if path == self.root / "docs/spec.md":
                return outside
            return real_resolve(path, *args, **kwargs)
        with mock.patch.object(Path, "resolve", redirect), self.assertRaises(ValueError):
            self.exporter.read_spec(self.root, "docs/spec.md", 1024)

    def test_empty_oversized_and_invalid_utf8_spec(self):
        for data in (b"", b"x" * 1048577, b"\xff"):
            (self.root / "docs/spec.md").write_bytes(data)
            with self.subTest(length=len(data)), self.assertRaises(ValueError):
                self.build()

    def test_preserves_existing_pins_or_rejects_conflict(self):
        source = plan()
        source["source_revision"] = "a" * 40
        source["spec"]["state"] = "Approved for implementation"
        source["spec"]["artifact_sha256"] = hashlib.sha256((self.root / "docs/spec.md").read_bytes()).hexdigest()
        self.build(source)
        for field, value in (("state", "Draft"), ("artifact_sha256", "b" * 64)):
            altered = copy.deepcopy(source)
            altered["spec"][field] = value
            with self.subTest(field=field), self.assertRaises(ValueError):
                self.build(altered)
        source["source_revision"] = "b" * 40
        with self.assertRaises(ValueError):
            self.build(source)

    def test_missing_or_ambiguous_acceptance_mapping(self):
        for entries in ([], [{"acceptance_id": "AC-2", "test_ref": "x"}],
                        plan()["acceptance_tests"] * 2, [None], [{"acceptance_id": "AC-1", "test_ref": ""}],
                        [{"acceptance_id": "AC-1", "test_ref": "x", "extra": "x"}], None):
            source = plan()
            source["acceptance_tests"] = entries
            with self.subTest(entries=entries), self.assertRaises(ValueError):
                self.build(source)
        (self.root / "docs/spec.md").write_text(SPEC.replace("AC-1", "FR-1"), encoding="utf-8")
        with self.assertRaises(ValueError):
            self.build()

    def test_bad_plan_and_approval_claims(self):
        for source in ([], {}, {"spec": []}):
            with self.subTest(source=source), self.assertRaises(ValueError):
                self.build(source)
        for field in ("approved_by", "approved_at", "approval_record"):
            source = plan()
            source["spec"][field] = " "
            with self.subTest(field=field), self.assertRaises(ValueError):
                self.build(source)
        source = plan()
        source["blocking_decisions"] = ["Unresolved scope"]
        with self.assertRaises(ValueError):
            self.build(source)

    def test_strict_json_boundary(self):
        for raw in (b'{"x":1,"x":2}', b'{"x":NaN}', b'{"x":Infinity}', b'{"x":1e999}', b'[]', b'null', b'bad',
                    b'\xff', b' ' * 1048577, b'{"x":' + b'[' * 2000 + b'0' + b']' * 2000 + b'}'):
            with self.subTest(raw=raw[:20]), self.assertRaises(ValueError):
                self.exporter.document(raw)
        self.assertEqual(self.exporter.document(b'{"x":1}'), {"x": 1})

    def test_main_success_and_errors(self):
        policy_file, plan_file = self.root / "policy.json", self.root / "plan.json"
        policy_file.write_text(json.dumps(policy()), encoding="utf-8")
        plan_file.write_text(json.dumps(plan()), encoding="utf-8")
        args = ["--root", str(self.root), "--policy", str(policy_file), "--plan", str(plan_file)]
        out, err = io.StringIO(), io.StringIO()
        with contextlib.redirect_stdout(out), contextlib.redirect_stderr(err):
            self.assertEqual(self.exporter.main(args), 0)
        self.assertEqual(json.loads(out.getvalue()), self.build())
        self.assertEqual(err.getvalue(), "")
        plan_file.unlink()
        with contextlib.redirect_stderr(err):
            self.assertEqual(self.exporter.main(args), 2)
        self.assertIn("handoff:", err.getvalue())

    def test_parser_recursion_is_normalized(self):
        with mock.patch.object(self.exporter.json, "loads", side_effect=RecursionError("too deep")):
            with self.assertRaises(ValueError):
                self.exporter.document(b"{}")

    def test_script_entrypoint(self):
        out, err = io.StringIO(), io.StringIO()
        with mock.patch.object(sys, "argv", ["delivery-handoff.py", "--root", str(self.root),
                                            "--policy", str(self.root / "absent"), "--plan", "absent"]):
            with contextlib.redirect_stdout(out), contextlib.redirect_stderr(err), self.assertRaises(SystemExit) as result:
                runpy.run_path(str(SCRIPTS / "delivery-handoff.py"), run_name="__main__")
        self.assertEqual(result.exception.code, 2)


if __name__ == "__main__":
    unittest.main()
