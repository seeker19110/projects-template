"""Characterization: subagent-dispatch.py (main CLI)."""
import io
import json
import os
import sys
import tempfile
import unittest

from .common import _load, write

dispatch = _load("dispatch_under_test", "subagent-dispatch.py")


class TestDispatchMain(unittest.TestCase):
    """Khoá hành vi CLI của subagent-dispatch.py::main trước khi tách hàm.

    main() ghép ba việc khác nhau (phân tích tham số / nhánh --list / render theo harness);
    test gọi THẲNG main() với sys.argv giả và bắt SystemExit + stdout/stderr, nên một diff
    "gọn hơn" làm mất một nhánh render hay đổi mã thoát sẽ đỏ ngay.
    """

    def setUp(self):
        self._tmp = tempfile.TemporaryDirectory()
        self.dir = self._tmp.name
        self._saved_agents = dispatch.AGENTS_DIR
        dispatch.AGENTS_DIR = self.dir
        write(self.dir, "alpha.md",
              "---\nname: alpha\ndescription: Lam viec A\nmodel: haiku\ntools: Read\n---\nThan alpha.")
        write(self.dir, "beta.md",
              "---\nname: beta\ndescription: Lam viec B\nmodel: opus\n---\nThan beta.")
        write(self.dir, "ghi-chu.txt", "khong phai .md")

    def tearDown(self):
        dispatch.AGENTS_DIR = self._saved_agents
        self._tmp.cleanup()

    def run_main(self, *argv):
        """Chạy main() với argv giả; trả (mã thoát, stdout, stderr). None = không gọi sys.exit."""
        out, err = io.StringIO(), io.StringIO()
        saved = sys.argv, sys.stdout, sys.stderr
        sys.argv = ["subagent-dispatch.py", *argv]
        sys.stdout, sys.stderr = out, err
        code = None
        try:
            dispatch.main()
        except SystemExit as exc:
            code = exc.code
        finally:
            sys.argv, sys.stdout, sys.stderr = saved
        return code, out.getvalue(), err.getvalue()

    def test_list_van_ban_liet_ke_dung_dinh_dang_va_thoat_0(self):
        code, out, err = self.run_main("--list")
        self.assertEqual((code, err), (0, ""))
        self.assertEqual(out.splitlines()[0], "Available Subagents (2):")
        self.assertEqual(out.splitlines()[1],
                         "  - " + "alpha".ljust(20) + " [" + "haiku".ljust(8) + "] : Lam viec A...")

    def test_list_json_chi_ba_khoa_va_thoat_0(self):
        code, out, _ = self.run_main("--list", "--json")
        self.assertEqual(code, 0)
        data = json.loads(out)
        self.assertEqual(data, [{"name": "alpha", "description": "Lam viec A", "model": "haiku"},
                                {"name": "beta", "description": "Lam viec B", "model": "opus"}])

    def test_thieu_agent_ma_khong_list_thi_loi_ra_stderr_thoat_1(self):
        code, out, err = self.run_main()
        self.assertEqual((code, out), (1, ""))
        self.assertIn("--agent is required", err)

    def test_agent_khong_ton_tai_thi_thoat_1(self):
        code, out, err = self.run_main("--agent", "khong-co")
        self.assertEqual((code, out), (1, ""))
        self.assertIn("not found", err)

    def test_generic_in_prompt_tho(self):
        code, out, _ = self.run_main("--agent", "alpha", "--task", "Viec X")
        self.assertIsNone(code)
        self.assertEqual(out, "=== SUBAGENT ROLE: ALPHA (haiku) ===\nThan alpha.\n\n"
                              "=== TASK CONTEXT ===\nViec X\n\n")

    def test_claude_in_chi_dan_tool_task(self):
        _, out, _ = self.run_main("--agent", "beta", "--task", "Viec Y", "--harness", "claude")
        self.assertEqual(out.splitlines()[0],
                         'Claude Code — gọi tool Task với subagent_type="beta":')
        self.assertIn("=== SUBAGENT ROLE: BETA (opus) ===", out)

    def test_hermes_in_rieng_delegate_task_call(self):
        _, out, _ = self.run_main("--agent", "alpha", "--task", "Viec Z", "--harness", "hermes")
        data = json.loads(out)
        self.assertEqual(list(data.keys()), ["tasks"])
        self.assertEqual(data["tasks"][0]["goal"], "[alpha] Viec Z...")

    def test_json_thang_de_lay_ca_payload(self):
        _, out, _ = self.run_main("--agent", "alpha", "--task", "T", "--harness", "hermes", "--json")
        data = json.loads(out)
        self.assertEqual(data["harness"], "hermes")
        self.assertEqual(data["agent"]["path"], os.path.join(self.dir, "alpha.md"))

    def test_context_file_duoc_noi_vao_sau_task(self):
        ctx = write(self.dir, "ctx.txt", "NOI DUNG DIFF")
        _, out, _ = self.run_main("--agent", "alpha", "--task", "T", "--context-file", ctx)
        self.assertIn("T\n\nNOI DUNG DIFF", out)

    def test_context_file_khong_ton_tai_thi_bo_qua_khong_vo(self):
        _, out, _ = self.run_main("--agent", "alpha", "--task", "T",
                                  "--context-file", os.path.join(self.dir, "khong-co.txt"))
        self.assertIn("=== TASK CONTEXT ===\nT\n", out)
