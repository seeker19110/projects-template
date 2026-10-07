"""Characterization: spec-compiler.py (parse_spec_markdown)."""
import os
import tempfile
import unittest

from .common import _load, write

compiler = _load("compiler_under_test", "spec-compiler.py")


class TestParseSpecMarkdown(unittest.TestCase):
    def setUp(self):
        self._tmp = tempfile.TemporaryDirectory()
        self.dir = self._tmp.name
        self.addCleanup(self._tmp.cleanup)

    def parse(self, name, text):
        path = write(self.dir, name, text)
        return compiler.parse_spec_markdown(path)

    def test_file_khong_ton_tai_tra_none(self):
        self.assertIsNone(compiler.parse_spec_markdown(
            os.path.join(self.dir, "khong-ton-tai.md")))

    def test_file_rong(self):
        parsed = self.parse("rong.md", "")
        self.assertEqual(parsed["title"], "rong.md")   # không có '# ' -> lấy basename
        self.assertEqual(parsed["metadata"], {})
        self.assertEqual(parsed["sections"], {})
        self.assertEqual(parsed["referenced_paths"], [])
        self.assertEqual(parsed["exempt_paths"], {})
        self.assertEqual(parsed["requirement_ids"], [])
        self.assertFalse(parsed["approved"])

    def test_bullet_truoc_moi_tieu_de_vao_muc_overview(self):
        parsed = self.parse("ov.md", "# T\n\n- mot\n* hai\n\n## Muc A\n\n- ba\n")
        self.assertEqual(parsed["sections"], {"Overview": ["mot", "hai"], "Muc A": ["ba"]})

    def test_bang_metadata_thieu_cot_thi_bo_qua_dong_do(self):
        parsed = self.parse("meta.md",
                            "# T\n\n| Thuộc tính | Giá trị |\n| :--- | :--- |\n"
                            "| State | Approved |\n| Người duyệt | An |\n")
        self.assertEqual(parsed["metadata"], {"State": "Approved", "Người duyệt": "An"})

    def test_khong_co_bang_metadata(self):
        parsed = self.parse("nometa.md", "# T\n\n| A | B |\n| :--- | :--- |\n| x | y |\n")
        self.assertEqual(parsed["metadata"], {})

    def test_touchpoints_loc_dung_thu_trong_duong_dan(self):
        body = (
            "# Spec\n\n"
            "## 3. Research current state\n\n"
            "- `scripts/khong-duoc-quet.sh`\n\n"
            "## 11. Architecture và code touchpoints\n\n"
            "- `scripts/beta.sh` và `docs/x.md`\n"
            "- `ten-file.py` nhưng `.sh` thì không\n"
            "- `https://vd.com/a.sh`, `/abs/x.sh`, `-flag`, `$VAR`, `@scope/pkg`\n"
            "- `co khoang trang.sh`\n"
            "- `thu-muc/`\n"
            "- `KHONG_PHAI_DUONG_DAN`\n\n"
            "## 12. Sau đó\n\n- `scripts/cung-khong-quet.sh`\n"
        )
        parsed = self.parse("tp.md", body)
        self.assertEqual(parsed["referenced_paths"],
                         ["docs/x.md", "scripts/beta.sh", "ten-file.py", "thu-muc"])

    def test_khong_co_muc_touchpoints(self):
        parsed = self.parse("notp.md", "# T\n\n## Khac\n\n- `scripts/beta.sh`\n")
        self.assertEqual(parsed["referenced_paths"], [])

    def test_mien_tru_phai_khai_ly_do_va_bi_tru_khoi_danh_sach(self):
        body = (
            "# T\n\n"
            "<!-- contract-exempt: scripts/go.sh — gỡ theo ADR-0004 -->\n"
            "<!-- contract-exempt: scripts/go2.sh -- ly do dung hai gach -->\n"
            "<!-- contract-exempt: scripts/khong-ly-do.sh -->\n\n"
            "## 11. Architecture và code touchpoints\n\n"
            "- `scripts/go.sh` `scripts/go2.sh` `scripts/khong-ly-do.sh` `scripts/o-lai.sh`\n"
        )
        parsed = self.parse("ex.md", body)
        self.assertEqual(parsed["exempt_paths"], {
            "scripts/go.sh": "gỡ theo ADR-0004",
            "scripts/go2.sh": "ly do dung hai gach",
        })
        self.assertEqual(parsed["referenced_paths"],
                         ["scripts/khong-ly-do.sh", "scripts/o-lai.sh"])

    def test_ma_yeu_cau_duy_nhat_va_sap_xep(self):
        parsed = self.parse("ids.md", "# T\n\nW-301 AC-2 FR-1 FR-1 NFR-10 XX-9\n")
        self.assertEqual(parsed["requirement_ids"], ["AC-2", "FR-1", "NFR-10", "W-301"])

    def test_approved_khong_phan_biet_hoa_thuong(self):
        # PR #181: approval is a selected metadata state, not a phrase in instructions.
        selected = "# T\n\n| Thuộc tính | Giá trị |\n| --- | --- |\n| State | approved FOR implementation |\n"
        self.assertTrue(self.parse("a1.md", selected)["approved"])
        self.assertFalse(self.parse("a2.md", "# T\n\nchua duyet\n")["approved"])
        self.assertFalse(self.parse("a3.md", "# T\n\napproved FOR implementation\n")["approved"])
        draft = selected.replace("approved FOR implementation", "Draft") + "\nApproved for implementation\n"
        self.assertFalse(self.parse("a4.md", draft)["approved"])

    def test_spec_file_la_duong_dan_tuong_doi_theo_root_dir(self):
        path = write(self.dir, "rel.md", "# T\n")
        parsed = compiler.parse_spec_markdown(path)
        # Ky vong tinh qua CHINH _display_path chu khong goi thang os.path.relpath: tren Windows
        # relpath NEM ValueError khi spec va ROOT_DIR khac o dia (runner: repo o D:, tmp o C:)
        # -- va khi do chinh DONG KY VONG cua test se vo, chu khong phai ham dang duoc kiem.
        # Xem TRAPS.md muc 28.
        self.assertEqual(parsed["spec_file"], compiler._display_path(path))
        # Van phai la duong dan TUONG DOI khi cung o dia -- neu khong, khang dinh tren rong
        # tuech (ca hai ve goi cung mot ham). Chi doi hoi dieu do khi relpath tinh duoc that.
        try:
            expected_rel = os.path.relpath(path, compiler.ROOT_DIR)
        except ValueError:
            expected_rel = None
        if expected_rel is not None:
            self.assertEqual(parsed["spec_file"], expected_rel)
