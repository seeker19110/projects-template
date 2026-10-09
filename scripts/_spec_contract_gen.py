"""Sinh contract test từ spec đã parse — tách khỏi spec-compiler.py để engine không vượt
ngưỡng 400 dòng của radar (arch-health-radar, 2026-10-09). spec-compiler tái xuất hàm này."""

import json
import os
import re


def generate_python_contract_test(parsed_spec):
    """Sinh contract test KIỂM ĐƯỢC THẬT.

    Nguyên tắc (audit 2026-09-13, A-01): mỗi test phải CÓ THỂ ĐỎ. Bản cũ sinh
    `assertTrue(len(requirements) >= 0)` — hằng đúng, nên 82/82 test không bao giờ đỏ dù
    code sai thế nào; tệ hơn không có test vì tạo cảm giác an toàn giả.

    Hợp đồng thật sự kiểm được từ một file spec Markdown:
      C-1 spec khai State + người duyệt (metadata bảng "Thuộc tính | Giá trị")
      C-2 spec khai ít nhất một mã yêu cầu (FR-/AC-/NFR-/W-) — spec rỗng không phải spec
      C-3 MỌI đường dẫn spec nhắc tới trong backtick PHẢI tồn tại thật — CHỈ áp cho spec đã
          "Approved for implementation" (spec nháp cố ý trỏ tới file của tương lai)
    Không có dữ liệu để kiểm -> skipTest, KHÔNG assert hằng đúng.
    """
    spec_name = os.path.splitext(os.path.basename(parsed_spec["spec_file"]))[0]
    safe_name = re.sub(r"[^a-zA-Z0-9_]", "_", spec_name)

    return "\n".join([
        "# Auto-generated Executable Contract Test by spec-compiler.py",
        f"# Source Spec: {parsed_spec['spec_file']}",
        "# DO NOT EDIT DIRECTLY - Update the source Markdown spec instead.",
        "",
        "import glob",
        "import os",
        "import re",
        "import unittest",
        "",
        "ROOT_DIR = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))",
        "",
        f"class TestSpecContract_{safe_name}(unittest.TestCase):",
        f"    SPEC_FILE = {parsed_spec['spec_file']!r}",
        f"    METADATA = {json.dumps(parsed_spec['metadata'], ensure_ascii=False)}",
        f"    REQUIREMENT_IDS = {json.dumps(parsed_spec['requirement_ids'], ensure_ascii=False)}",
        f"    REFERENCED_PATHS = {json.dumps(parsed_spec['referenced_paths'], ensure_ascii=False)}",
        f"    EXEMPT_PATHS = {json.dumps(parsed_spec['exempt_paths'], ensure_ascii=False)}",
        f"    APPROVED = {parsed_spec['approved']!r}",
        f"    EVIDENCE_MAP_REQUIRED = {parsed_spec['evidence_map_required']!r}",
        f"    ACCEPTANCE_IDS = {json.dumps(parsed_spec['acceptance_ids'], ensure_ascii=False)}",
        f"    EVIDENCE_MAP = {parsed_spec['evidence_map']!r}",  # repr: None/list là literal Python hợp lệ
        "",
        "    @staticmethod",
        "    def _exists(rel):",
        "        \"\"\"Spec viet duong dan RAT LONG LEO - chuan hoa truoc khi ket luan la thieu:",
        "        bo hau to so dong (file.md:27), bo qua brace {a,b} (khong phai glob shell that),",
        "        ho tro glob *, va cho phep TEN FILE TRAN khop bat ky dau trong repo.\"\"\"",
        "        rel = re.sub(r':\\d+(?:-\\d+)?$', '', rel.strip())",
        "        if '{' in rel or '}' in rel:",
        "            return True  # mau liet ke kieu {a,b}.sh - khong ket luan duoc, khong bao thieu",
        "        if any(ch in rel for ch in '*?['):",
        "            return bool(glob.glob(os.path.join(ROOT_DIR, rel)))",
        "        if os.path.exists(os.path.join(ROOT_DIR, rel)):",
        "            return True",
        "        if '/' in rel:",
        "            return False",
        "        # ten tran: tim khap repo (bo qua .git)",
        "        for base, dirs, files in os.walk(ROOT_DIR):",
        "            dirs[:] = [d for d in dirs if d not in ('.git', 'node_modules', '__pycache__')]",
        "            if rel in files:",
        "                return True",
        "        return False",
        "",
        "    def test_c1_spec_khai_state_va_nguoi_duyet(self):",
        "        \"\"\"C-1: spec phai khai State (va nguoi duyet) trong bang metadata.\"\"\"",
        "        if not self.METADATA:",
        "            self.skipTest(f'{self.SPEC_FILE}: khong co bang metadata de kiem')",
        "        self.assertIn('State', self.METADATA,",
        "                      f'{self.SPEC_FILE}: bang metadata thieu dong State')",
        "        self.assertTrue(str(self.METADATA.get('State', '')).strip(),",
        "                        f'{self.SPEC_FILE}: State rong')",
        "",
        "    def test_c2_spec_khai_it_nhat_mot_ma_yeu_cau(self):",
        "        \"\"\"C-2: spec phai co it nhat mot ma FR-/AC-/NFR-/W-.\"\"\"",
        "        self.assertGreater(len(self.REQUIREMENT_IDS), 0,",
        "                           f'{self.SPEC_FILE}: khong khai ma yeu cau nao (FR-/AC-/NFR-/W-)')",
        "",
        "    def test_c3_duong_dan_spec_hua_phai_ton_tai(self):",
        "        \"\"\"C-3: spec da Approved thi moi duong dan no nhac toi phai co that.\"\"\"",
        "        if not self.APPROVED:",
        "            self.skipTest(f'{self.SPEC_FILE}: chua Approved - duoc phep tro toi file tuong lai')",
        "        if not self.REFERENCED_PATHS:",
        "            self.skipTest(f'{self.SPEC_FILE}: khong tham chieu duong dan nao')",
        "        missing = [p for p in self.REFERENCED_PATHS if not self._exists(p)]",
        "        self.assertEqual(missing, [],",
        "                         f'{self.SPEC_FILE}: spec da Approved nhung cac duong dan sau khong ton tai: '",
        "                         + ', '.join(missing))",
        "",
        "    @staticmethod",
        "    def _ref_ok(ref):",
        "        path, _, symbol = ref.partition('::')",
        "        target = os.path.join(ROOT_DIR, path)",
        "        if not os.path.isfile(target):",
        "            return False",
        "        with open(target, encoding='utf-8', errors='ignore') as f:",
        "            return not symbol or symbol in f.read()",
        "",
        "    def test_c4_ac_co_ban_do_bang_chung(self):",
        "        \"\"\"C-4: spec Approved (tu 2026-10-07) phai noi MOI AC toi bang chung co that.",
        "        Day la truy vet, khong phai nghiem thu: ket qua chay nam o CI / evidence-check.\"\"\"",
        "        if not self.EVIDENCE_MAP_REQUIRED:",
        "            self.skipTest(f'{self.SPEC_FILE}: chua Approved hoac spec truoc moc ban do AC')",
        "        entries = self.EVIDENCE_MAP or []",
        "        mapped = {e['acceptance_id'] for e in entries}",
        "        problems = {",
        "            'khong co AC nao': [] if self.ACCEPTANCE_IDS else ['<spec>'],",
        "            'AC thieu dong ban do': [a for a in self.ACCEPTANCE_IDS if a not in mapped],",
        "            'AC la (khong co trong Acceptance criteria)': sorted(mapped - set(self.ACCEPTANCE_IDS)),",
        "            'o bang chung trong': [e['acceptance_id'] for e in entries if e['kind'] == 'empty'],",
        "            'bang chung khong ton tai': [r for e in entries for r in e['refs'] if not self._ref_ok(r)],",
        "        }",
        "        problems = {k: v for k, v in problems.items() if v}",
        "        self.assertEqual(problems, {}, f'{self.SPEC_FILE}: ban do AC -> bang chung loi: {problems}')",
        "",
        "if __name__ == '__main__':",
        "    unittest.main()",
        "",
    ])
