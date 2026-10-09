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

    # LD-05/AC-5: context thiếu/hỏng/quá lớn KHÔNG được bỏ im lặng (bản cũ bỏ qua file thiếu,
    # nuốt byte không phải UTF-8 và nối file mọi kích thước) — báo lỗi, thoát 2, không in prompt.
    def assert_context_error(self, marker, *extra):
        code, out, err = self.run_main("--agent", "alpha", "--task", "T", *extra)
        self.assertEqual(code, 2, err)
        self.assertIn(marker, err)
        self.assertEqual(out, "")

    def test_context_file_khong_ton_tai_thi_bao_loi_thoat_2(self):
        self.assert_context_error("không tồn tại", "--context-file", os.path.join(self.dir, "khong-co.txt"))

    def test_context_file_la_thu_muc_hoac_rong_thi_bao_loi(self):
        self.assert_context_error("không tồn tại", "--context-file", self.dir)
        self.assert_context_error("rỗng", "--context-file", write(self.dir, "rong.txt", ""))

    def test_context_file_qua_gioi_han_khong_cat_im_lang(self):
        ctx = write(self.dir, "lon.txt", "MUOI-MOT-B")
        self.assert_context_error("vượt giới hạn", "--context-file", ctx, "--max-context-bytes", "5")
        _, out, _ = self.run_main("--agent", "alpha", "--task", "T", "--context-file", ctx,
                                  "--max-context-bytes", "10")
        self.assertIn("MUOI-MOT-B", out)

    def test_context_file_khong_utf8_bao_loi(self):
        ctx = os.path.join(self.dir, "nhi-phan.bin")
        with open(ctx, "wb") as f:
            f.write(b"ok\xff")
        self.assert_context_error("UTF-8", "--context-file", ctx)

    def test_moi_harness_noi_ro_prepare_only(self):
        for harness in ("claude", "hermes", "codex", "generic"):
            code, out, err = self.run_main("--agent", "alpha", "--task", "T", "--harness", harness, "--json")
            self.assertIsNone(code, err)
            self.assertIn("prepare-only", err)
            data = json.loads(out)
            self.assertEqual((data["mode"], data["executed"]), ("prepare-only", False), harness)


GOOD_PLAN = """# PLAN.md — vi du

## Nhóm PR (đơn vị mở PR)
- **PR-1** (mean): gồm việc T1 — độc lập
- **PR-2** (docs): gồm việc T2 — phụ thuộc PR-1

## Danh sách việc
### T1 — Thêm hàm mean   `route: standard`
- Điểm chạm: `src/stats.py`, `tests/test_stats.py`
- Đặc tả: mean([]) trả None; mean([1,2,3]) trả 2.0
- Phụ thuộc: none
- Tiêu chí chấp nhận: `python -m unittest tests/test_stats.py` xanh, có ca đỏ trước

### T2 — Nối khối README   `route: mechanical`
- Điểm chạm: `README.md`
- Đặc tả: nối đúng từng ký tự khối dưới vào cuối file
```markdown

## Cách dùng
`python -m stats`
```
- Phụ thuộc: T1
- Tiêu chí chấp nhận: `tail -n 4 README.md` khớp từng byte khối trên
"""


class TestCheckPlan(unittest.TestCase):
    """`--check-plan`: khoá brief TRƯỚC khi dispatch (nghiệm thu 2026-10-09 đợt 3: brief mechanical
    "0 quyết định để ngỏ" nhưng mâu thuẫn với fence → mất một vòng worker)."""

    def setUp(self):
        self._tmp = tempfile.TemporaryDirectory()
        self.dir = self._tmp.name

    def tearDown(self):
        self._tmp.cleanup()

    def check(self, text):
        path = write(self.dir, "PLAN.md", text)
        out, err = io.StringIO(), io.StringIO()
        saved = sys.argv, sys.stdout, sys.stderr
        sys.argv = ["subagent-dispatch.py", "--check-plan", path]
        sys.stdout, sys.stderr = out, err
        code = None
        try:
            dispatch.main()
        except SystemExit as exc:
            code = exc.code
        finally:
            sys.argv, sys.stdout, sys.stderr = saved
        return code, out.getvalue() + err.getvalue()

    def test_plan_hop_le_thoat_0_va_dem_viec(self):
        code, text = self.check(GOOD_PLAN)
        self.assertEqual(code, 0, text)
        self.assertIn("2 việc", text)

    def test_thieu_truong_bat_buoc_neu_ten_viec_va_truong(self):
        code, text = self.check(GOOD_PLAN.replace("- Tiêu chí chấp nhận: `python", "- Ghi chú: `python"))
        self.assertEqual(code, 1)
        self.assertIn("T1", text)
        self.assertIn("Tiêu chí chấp nhận", text)

    def test_placeholder_con_sot_la_loi(self):
        code, text = self.check(GOOD_PLAN.replace("mean([]) trả None", "<điền đặc tả>"))
        self.assertEqual(code, 1)
        self.assertIn("<điền đặc tả>", text)

    def test_route_la_hoac_thieu_la_loi(self):
        code, text = self.check(GOOD_PLAN.replace("`route: standard`", "`route: wizard`"))
        self.assertEqual(code, 1)
        self.assertIn("wizard", text)
        code, text = self.check(GOOD_PLAN.replace("   `route: standard`", ""))
        self.assertEqual(code, 1)
        self.assertIn("T1", text)

    def test_phu_thuoc_khong_ton_tai_hoac_vong_la_loi(self):
        code, text = self.check(GOOD_PLAN.replace("- Phụ thuộc: T1", "- Phụ thuộc: T9"))
        self.assertEqual(code, 1)
        self.assertIn("T9", text)
        code, text = self.check(GOOD_PLAN.replace("- Phụ thuộc: none", "- Phụ thuộc: T2"))
        self.assertEqual(code, 1)
        self.assertIn("vòng", text)

    def test_nhom_pr_phai_phu_moi_viec_dung_mot_lan(self):
        code, text = self.check(GOOD_PLAN.replace("gồm việc T2 — phụ thuộc PR-1", "gồm việc T1 — phụ thuộc PR-1"))
        self.assertEqual(code, 1)
        self.assertIn("T2", text)
        self.assertIn("T1", text)

    def test_mechanical_phai_co_fence_va_diem_cham_tuong_minh(self):
        no_fence = GOOD_PLAN.replace("```markdown\n\n## Cách dùng\n`python -m stats`\n```\n", "")
        code, text = self.check(no_fence)
        self.assertEqual(code, 1)
        self.assertIn("T2", text)
        self.assertIn("khuôn", text)
        code, text = self.check(GOOD_PLAN.replace("- Điểm chạm: `README.md`", "- Điểm chạm: `docs/*.md`"))
        self.assertEqual(code, 1)
        self.assertIn("docs/*.md", text)

    def test_file_plan_khong_ton_tai_thoat_2(self):
        out, err = io.StringIO(), io.StringIO()
        saved = sys.argv, sys.stdout, sys.stderr
        sys.argv = ["subagent-dispatch.py", "--check-plan", os.path.join(self.dir, "khong-co.md")]
        sys.stdout, sys.stderr = out, err
        try:
            with self.assertRaises(SystemExit) as cm:
                dispatch.main()
        finally:
            sys.argv, sys.stdout, sys.stderr = saved
        self.assertEqual(cm.exception.code, 2)
