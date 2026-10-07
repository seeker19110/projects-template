"""Characterization: arch-health-radar.py (scan_codebase_health, _scripts_inventory, _spec_quality, generate_recommendations)."""
import os
import tempfile
import unittest

from .common import _load, write

radar = _load("radar_under_test", "arch-health-radar.py")


class RadarBase(unittest.TestCase):
    def setUp(self):
        self._tmp = tempfile.TemporaryDirectory()
        self.repo = self._tmp.name
        self._saved_root = radar.ROOT_DIR
        radar.ROOT_DIR = self.repo
        self.addCleanup(self._restore)

    def _restore(self):
        radar.ROOT_DIR = self._saved_root
        self._tmp.cleanup()


class TestRepoRong(RadarBase):
    """Repo TRỐNG: mọi mẫu số bằng 0 -> pct() trả 100.0, điểm tuyệt đối, không có đề xuất."""

    def test_scan_repo_rong(self):
        data = radar.scan_codebase_health()
        self.assertEqual(data["total_files"], 0)
        self.assertEqual(data["total_lines"], 0)
        self.assertEqual(data["code_lines"], 0)
        self.assertEqual(data["code_comment_lines"], 0)
        self.assertEqual(data["doc_lines"], 0)
        self.assertEqual(data["doc_ratio_pct"], 100.0)
        self.assertEqual(data["file_type_counts"], {})
        self.assertEqual(data["scripts_total"], 0)
        self.assertEqual(data["scripts_covered"], 0)
        self.assertEqual(data["scripts_uncovered"], [])
        self.assertEqual(data["ci_tests"], [])
        self.assertEqual((data["spec_total"], data["spec_good"], data["spec_weak"]), (0, 0, []))
        self.assertEqual(data["large_code_files"], [])
        self.assertEqual(data["large_doc_files"], [])
        self.assertEqual(data["todo_markers"], [])
        self.assertEqual(data["signals"], {
            "gate_coverage": 100.0, "spec_quality": 100.0, "size_discipline": 100.0,
            "comment_density": 100.0, "todo_debt": 100.0,
        })
        self.assertEqual(data["weights"], {"gate": 40, "spec": 20, "size": 15, "comment": 15, "todo": 10})
        self.assertEqual(data["health_score"], 100)
        self.assertEqual(data["recommendations"], [])
        self.assertEqual(radar.generate_recommendations(data),
                         ["Không còn tín hiệu nợ kỹ thuật nào ĐO ĐƯỢC BẰNG CÁC THƯỚC Ở TRÊN."])

    def test_inventory_va_spec_khi_thieu_thu_muc(self):
        self.assertEqual(radar._scripts_inventory(), ([], set(), set()))
        self.assertEqual(radar._spec_quality(), (0, 0, []))

    def test_scripts_dir_rong_khong_co_ci_yml(self):
        os.makedirs(os.path.join(self.repo, "scripts"))
        write(self.repo, "scripts/README.txt", "khong phai script\n")
        self.assertEqual(radar._scripts_inventory(), ([], set(), set()))


class TestRepoCoKhiemKhuyet(RadarBase):
    """Repo có ĐỦ khiếm khuyết: script không cổng, file mã dài, tài liệu dài, spec yếu, TODO."""

    def setUp(self):
        super().setUp()
        write(self.repo, ".github/workflows/ci.yml",
              "jobs:\n  a:\n    steps:\n      - run: bash scripts/test-alpha.sh\n")
        # test-alpha.sh là test CHẠY TRONG CI, thân của nó nhắc beta.sh -> beta.sh được phủ,
        # và beta.py (cùng tên, đuôi .py) cũng được phủ theo luật wrapper.
        write(self.repo, "scripts/test-alpha.sh", "#!/usr/bin/env bash\nbash scripts/beta.sh\n")
        write(self.repo, "scripts/beta.sh", "#!/usr/bin/env bash\n# chu thich\ntrue\n")
        write(self.repo, "scripts/beta.py", "x = 1\n")
        write(self.repo, "scripts/gamma.sh", "#!/usr/bin/env bash\n# TODO: no ky thuat\nTODO khong tinh\n")
        # test-orphan.sh là test nhưng KHÔNG nằm trong ci.yml -> không phải cổng, tự nó uncovered.
        write(self.repo, "scripts/test-orphan.sh", "#!/usr/bin/env bash\ntrue\n")
        write(self.repo, "scripts/long.sh", "#!/usr/bin/env bash\n" + "true\n" * 401)
        write(self.repo, "docs/long.md", "dong\n" * 901)
        write(self.repo, "docs/specs/README.md", "# bo qua\n")
        write(self.repo, "docs/specs/good.md",
              "# Spec tot\n\nFR-1 va AC-2\n\n## 11. Architecture và code touchpoints\n\n- `scripts/beta.sh`\n")
        write(self.repo, "docs/specs/weak.md", "# Spec yeu\n\nkhong co gi\n")
        write(self.repo, "notes", "khong co duoi file\n")
        write(self.repo, "app.js", "// chu thich\nconst a = 1;\n")

    def test_inventory(self):
        all_scripts, covered, ci_tests = radar._scripts_inventory()
        self.assertEqual(all_scripts, ["beta.py", "beta.sh", "gamma.sh", "long.sh",
                                       "test-alpha.sh", "test-orphan.sh"])
        self.assertEqual(covered, {"test-alpha.sh", "beta.sh", "beta.py"})
        self.assertEqual(ci_tests, {"test-alpha.sh"})

    def test_inventory_khong_co_ci_yml_thi_khong_gi_duoc_phu(self):
        # ci.yml là nguồn DUY NHẤT xác định test nào là cổng thật; mất nó -> covered rỗng,
        # KHÔNG được suy diễn "cứ tên test- là cổng".
        os.remove(os.path.join(self.repo, ".github", "workflows", "ci.yml"))
        all_scripts, covered, ci_tests = radar._scripts_inventory()
        self.assertEqual(len(all_scripts), 6)
        self.assertEqual((covered, ci_tests), (set(), set()))

    def test_inventory_test_khong_doc_duoc_thi_bo_qua_khong_vo(self):
        # Nhánh `except OSError: continue` — test là cổng nhưng không đọc được thân:
        # vẫn tính CHÍNH NÓ là covered, nhưng MẤT phần bao đóng suy từ thân nó (beta.*).
        # Kích lỗi bằng THƯ MỤC trùng tên (IsADirectoryError) chứ KHÔNG bằng chmod 000:
        # test chạy dưới uid 0 (CI/container) đọc được cả file 000 -> nhánh không bị chạm,
        # test xanh giả. Cách này độc lập với quyền của người chạy.
        alpha = os.path.join(self.repo, "scripts", "test-alpha.sh")
        os.remove(alpha)
        os.mkdir(alpha)
        all_scripts, covered, ci_tests = radar._scripts_inventory()
        self.assertIn("test-alpha.sh", all_scripts)
        self.assertEqual(ci_tests, {"test-alpha.sh"})
        self.assertEqual(covered, {"test-alpha.sh"})

    def test_spec_quality(self):
        total, good, weak = radar._spec_quality()
        self.assertEqual((total, good), (2, 1))
        self.assertEqual(weak, [{"file": "docs/specs/weak.md",
                                 "missing": "không có mã FR-/AC-, thiếu mục 11 touchpoints"}])

    def test_scan_tin_hieu_va_danh_sach(self):
        data = radar.scan_codebase_health()
        self.assertEqual(data["scripts_total"], 6)
        self.assertEqual(data["scripts_covered"], 3)
        self.assertEqual(data["scripts_uncovered"], ["gamma.sh", "long.sh", "test-orphan.sh"])
        self.assertEqual(data["ci_tests"], ["test-alpha.sh"])
        self.assertEqual(data["signals"]["gate_coverage"], 50.0)
        self.assertEqual(data["signals"]["spec_quality"], 50.0)
        # file mã: beta.py, beta.sh, gamma.sh, long.sh, test-alpha.sh, test-orphan.sh, app.js = 7
        self.assertEqual(data["signals"]["size_discipline"], round(100.0 * 6 / 7, 1))
        self.assertEqual(data["large_code_files"], [{"file": "scripts/long.sh", "lines": 402}])
        self.assertEqual(data["large_doc_files"], [{"file": "docs/long.md", "lines": 901}])
        # CHỈ dấu nằm ngay sau '#' hoặc '//' mới tính; dòng "TODO khong tinh" bị bỏ qua.
        self.assertEqual(data["todo_markers"], [{"file": "scripts/gamma.sh", "line": 2}])
        self.assertEqual(data["signals"]["todo_debt"], 90.0)
        # docs/long.md 901 + specs/README.md 1 + specs/good.md 7 + specs/weak.md 3
        self.assertEqual(data["doc_lines"], 901 + 1 + 7 + 3)
        self.assertEqual(data["file_type_counts"][".sh"], 5)
        self.assertEqual(data["file_type_counts"]["(no-ext)"], 1)
        self.assertEqual(data["file_type_counts"][".yml"], 1)

    def test_de_xuat_tro_vao_viec_cu_the(self):
        data = radar.scan_codebase_health()
        recs = radar.generate_recommendations(data)
        self.assertEqual(recs[0], "Thêm test (và nối vào `ci.yml`) cho: "
                                  "`scripts/gamma.sh`, `scripts/long.sh`, `scripts/test-orphan.sh`")
        self.assertIn("Bổ sung cho `docs/specs/weak.md`: "
                      "không có mã FR-/AC-, thiếu mục 11 touchpoints", recs)
        self.assertIn("File mã `scripts/long.sh` dài 402 dòng (> 400) — cân nhắc tách", recs)
        self.assertIn("Giải quyết hoặc chuyển thành issue: `scripts/gamma.sh:2`", recs)

    def test_bao_cao_markdown_in_du_muc_canh_bao(self):
        data = radar.scan_codebase_health()
        data["recommendations"] = radar.generate_recommendations(data)
        report = radar.format_markdown_report(data)
        self.assertIn("### ⚠️ Script KHÔNG có cổng bảo vệ (3)", report)
        self.assertIn("### ⚠️ Spec chưa đạt chuẩn (1)", report)
        self.assertIn("### File mã dài (> 400 dòng)", report)
        self.assertIn("### File tài liệu dài (> 900 dòng — thông tin, KHÔNG trừ điểm)", report)


class TestRadarCaBien(RadarBase):
    """Ca biên: thư mục loại trừ, file chỉ toàn chú thích, mật độ chú thích vượt mốc 15%."""

    def test_bo_qua_thu_muc_loai_tru(self):
        write(self.repo, "node_modules/x.js", "var a = 1;\n")
        write(self.repo, ".git/config", "[core]\n")
        write(self.repo, "keep.py", "a = 1\n")
        data = radar.scan_codebase_health()
        self.assertEqual(data["total_files"], 1)
        self.assertEqual(data["file_type_counts"], {".py": 1})

    def test_file_toan_chu_thich_mat_do_bi_chan_tran_100(self):
        write(self.repo, "a.py", "# mot\n# hai\n\n")
        data = radar.scan_codebase_health()
        self.assertEqual(data["code_lines"], 0)
        self.assertEqual(data["code_comment_lines"], 2)
        # code_lines == 0 -> nhánh 100.0 cố định, KHÔNG chia cho 0
        self.assertEqual(data["signals"]["comment_density"], 100.0)

    def test_mat_do_chu_thich_chuan_hoa_theo_moc_15_phan_tram(self):
        write(self.repo, "a.py", "# c\n" + "x = 1\n" * 99)
        data = radar.scan_codebase_health()
        self.assertEqual((data["code_comment_lines"], data["code_lines"]), (1, 99))
        self.assertEqual(data["signals"]["comment_density"],
                         round(100.0 * (1 / 99) / 0.15, 1))

    def test_todo_nhieu_hon_10_dau_khong_xuong_duoi_0(self):
        write(self.repo, "a.py", "# TODO: x\n" * 11)
        data = radar.scan_codebase_health()
        self.assertEqual(len(data["todo_markers"]), 11)
        self.assertEqual(data["signals"]["todo_debt"], 0.0)


class TestInventoryTestPython(RadarBase):
    """Test Python ở tests/ mà một test CHẠY TRONG CI gọi tới cũng là cổng bảo vệ (F-N02, 2026-10-06).

    Trước đây radar chỉ đọc thân `scripts/test-*.sh`, nên `delivery-handoff.py` bị báo "không có cổng" dù
    `tests/test_delivery_handoff_integrity.py` chạy trong `test-py-coverage.sh`: công cụ đo nói sai.
    """

    def setUp(self):
        super().setUp()
        write(self.repo, ".github/workflows/ci.yml",
              "jobs:\n  a:\n    steps:\n      - run: bash scripts/test-alpha.sh\n")
        write(self.repo, "scripts/test-alpha.sh", "#!/usr/bin/env bash\npython -m unittest tests/test_gamma.py\n")
        write(self.repo, "scripts/gamma-tool.py", "x = 1\n")
        write(self.repo, "scripts/delta-tool.py", "x = 1\n")
        write(self.repo, "scripts/epsilon-tool.py", "x = 1\n")
        write(self.repo, "tests/test_gamma.py", 'import importlib\nm = importlib.import_module("gamma-tool")\n')
        # test mồ côi: không CI test nào nhắc -> KHÔNG được tính là cổng cho epsilon-tool.
        write(self.repo, "tests/test_orphan.py", 'import importlib\nm = importlib.import_module("epsilon-tool")\n')

    def test_script_duoc_test_python_trong_ci_phu(self):
        _, covered, _ = radar._scripts_inventory()
        self.assertIn("gamma-tool.py", covered)

    def test_script_khong_ai_goi_van_bi_bao(self):
        _, covered, _ = radar._scripts_inventory()
        self.assertNotIn("delta-tool.py", covered)

    def test_test_python_mo_coi_khong_phu_ai(self):
        _, covered, _ = radar._scripts_inventory()
        self.assertNotIn("epsilon-tool.py", covered)
