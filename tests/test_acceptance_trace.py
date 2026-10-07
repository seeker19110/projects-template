"""LD-03: bản đồ AC → bằng chứng của spec-compiler (C-4, --trace).

Truy vết ≠ nghiệm thu: các ca dưới chứng minh AC bị bỏ sót, bằng chứng gãy hoặc "chưa có" không
bao giờ được báo là đủ; còn kết quả chạy test thuộc về CI/evidence của đúng commit.
"""

import contextlib
import importlib.util
import io
import tempfile
from pathlib import Path
from unittest import TestCase, main

ROOT = Path(__file__).resolve().parents[1]


def load_compiler():
    spec = importlib.util.spec_from_file_location(
        "spec_compiler_trace", ROOT / "scripts/spec-compiler.py"
    )
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


compiler = load_compiler()

HEADER = """# Feature spec: truy vết

| Thuộc tính | Giá trị |
| --- | --- |
| State | {state} |
| Approver / date | Fixture, 2026-10-08 |

## 9. Acceptance criteria

AC-1 thứ nhất. AC-2 thứ hai.

## 16. Test/eval plan

| AC | Bằng chứng | Ghi chú |
| --- | --- | --- |
{rows}
"""
APPROVED = "**Approved for implementation**"


class TraceFixture(TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name)
        (self.root / "docs/specs").mkdir(parents=True)
        (self.root / "tests").mkdir()
        (self.root / "tests/test_real.py").write_text(
            "def test_login_rejects_other_tenant():\n    pass\n", encoding="utf-8"
        )

    def tearDown(self):
        self.tmp.cleanup()

    def write(self, rows, name="2026-10-08-x.md", state=APPROVED, body=None):
        path = self.root / "docs/specs" / name
        path.write_text(
            body if body is not None else HEADER.format(state=state, rows=rows),
            encoding="utf-8",
        )
        return path

    def trace(self, path):
        parsed = compiler.parse_spec_markdown(str(path))
        return {
            ac: status
            for ac, status, _ in compiler.trace_acceptance(parsed, str(self.root))
        }

    def cli(self, path):
        out = io.StringIO()
        with contextlib.redirect_stdout(out):
            rc = compiler.print_trace(str(path))
        return rc, out.getvalue()


class AcceptanceTrace(TraceFixture):
    def test_mapped_and_manual_rows_complete_the_trace(self):
        path = self.write(
            "| AC-1 | `tests/test_real.py::test_login_rejects_other_tenant` | |\n"
            "| AC-2 | thủ công: quan sát trên staging | |"
        )
        self.assertEqual(self.trace(path), {"AC-1": "MAPPED", "AC-2": "MANUAL"})
        rc, out = self.cli(path)
        self.assertEqual(rc, 0)
        self.assertIn("TRACE COMPLETE", out)
        self.assertIn("Chưa phải nghiệm thu", out)

    def test_every_gap_is_reported_and_blocks_completion(self):
        path = self.write(
            "| AC-1 | `tests/test_real.py::test_khong_co` | |\n"
            "| AC-3 | `tests/test_real.py` | |\n"
            "| AC-2 |  | |"
        )
        self.assertEqual(
            self.trace(path), {"AC-1": "BROKEN", "AC-2": "EMPTY", "AC-3": "UNKNOWN"}
        )
        rc, out = self.cli(path)
        self.assertEqual(rc, 1)
        self.assertIn("TRACE INCOMPLETE", out)

    def test_missing_file_pending_and_unmapped(self):
        path = self.write("| AC-1 | `tests/khong_co.py` | |")
        self.assertEqual(self.trace(path), {"AC-1": "BROKEN", "AC-2": "UNMAPPED"})
        path = self.write("| AC-1 | chưa có — slice sau | |\n| AC-2 | pending | |")
        self.assertEqual(self.trace(path), {"AC-1": "PENDING", "AC-2": "PENDING"})

    def test_duplicate_rows_merge_and_any_real_ref_counts(self):
        path = self.write(
            "| AC-1 | chưa có | |\n"
            "| AC-1 | `tests/test_real.py` | |\n"
            "| **AC-2** | thủ công: đo tay | |"
        )
        self.assertEqual(self.trace(path), {"AC-1": "MAPPED", "AC-2": "MANUAL"})

    def test_no_table_or_no_acceptance_ids_is_never_complete(self):
        path = self.write("", body=HEADER.split("## 16.")[0])
        self.assertIsNone(compiler.parse_spec_markdown(str(path))["evidence_map"])
        self.assertEqual(self.trace(path), {"AC-1": "UNMAPPED", "AC-2": "UNMAPPED"})
        empty = self.write("", body="# Spec\n\n| AC | Bằng chứng |\n| --- | --- |\n")
        rc, out = self.cli(empty)
        self.assertEqual((rc, "TRACE INCOMPLETE" in out), (1, True))

    def test_table_without_evidence_column_is_not_a_map(self):
        body = "# Spec\n\n## Acceptance criteria\n\nAC-1 x.\n\n| AC | Owner |\n| --- | --- |\n| AC-1 | `tests/test_real.py` |\n"
        self.assertIsNone(
            compiler.parse_spec_markdown(str(self.write("", body=body)))["evidence_map"]
        )

    def test_acceptance_ids_fall_back_to_whole_file_without_section(self):
        body = "# Spec\n\nAC-2 rồi AC-10.\n\n| AC | Evidence |\n| --- | --- |\n| AC-2 | `tests/test_real.py` |\n"
        parsed = compiler.parse_spec_markdown(str(self.write("", body=body)))
        self.assertEqual(parsed["acceptance_ids"], ["AC-2", "AC-10"])

    def test_requirement_starts_at_cutoff_only_for_approved_specs(self):
        old = compiler.parse_spec_markdown(str(self.write("", name="2026-10-06-cu.md")))
        new = compiler.parse_spec_markdown(
            str(self.write("", name="2026-10-07-moi.md"))
        )
        undated = compiler.parse_spec_markdown(
            str(self.write("", name="khong-ngay.md"))
        )
        draft = compiler.parse_spec_markdown(
            str(self.write("", name="2026-10-09-nhap.md", state="Draft"))
        )
        self.assertEqual(
            [
                old["evidence_map_required"],
                new["evidence_map_required"],
                undated["evidence_map_required"],
                draft["evidence_map_required"],
            ],
            [False, True, True, False],
        )

    def test_missing_spec_is_blocked_and_root_detection(self):
        err = io.StringIO()
        with contextlib.redirect_stderr(err):
            self.assertEqual(
                compiler.print_trace(str(self.root / "docs/specs/khong-co.md")), 2
            )
        self.assertEqual(
            compiler._project_root(str(self.root / "docs/specs/a.md")),
            str(self.root).replace("\\", "/"),
        )
        self.assertEqual(compiler._project_root("/khac/a.md"), compiler.ROOT_DIR)

    def test_generated_contract_embeds_map_as_python_literals(self):
        path = self.write("| AC-1 | `tests/test_real.py` | |")
        source = compiler.generate_python_contract_test(
            compiler.parse_spec_markdown(str(path))
        )
        compile(
            source, "generated.py", "exec"
        )  # None/True phải là literal Python, không phải null/true
        self.assertIn("EVIDENCE_MAP_REQUIRED = True", source)
        no_map = compiler.generate_python_contract_test(
            compiler.parse_spec_markdown(
                str(self.write("", body=HEADER.split("## 16.")[0]))
            )
        )
        compile(no_map, "generated.py", "exec")
        self.assertIn("EVIDENCE_MAP = None", no_map)


if __name__ == "__main__":
    main()
