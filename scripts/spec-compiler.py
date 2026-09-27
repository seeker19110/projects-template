#!/usr/bin/env python3
"""
spec-compiler.py — Autonomous Spec-to-Contract Compiler Engine
Biên dịch tài liệu đặc tả Markdown (docs/specs/*.md) thành hợp đồng kiểm thử khả thi (Executable Test Contracts).
"""

import sys
import os
import argparse
import json
import re

# Console Windows mặc định dùng cp1252 → in tiếng Việt/emoji ra stdout sẽ chết với
# UnicodeEncodeError. Ép UTF-8 để engine chạy được trên mọi nền (xem TRAPS.md).
for _stream in (sys.stdout, sys.stderr):
    if hasattr(_stream, "reconfigure"):
        _stream.reconfigure(encoding="utf-8")

ROOT_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

def _parse_metadata_table(content):
    """Bảng "| Thuộc tính | Giá trị |" -> dict. Dòng thiếu cột bị BỎ QUA, không đoán."""
    metadata = {}
    meta_table = re.search(r"\|\s*Thuộc tính\s*\|\s*Giá trị\s*\|\s*\n\|[-:| ]+\|\n((?:\|.*\|\n)+)", content)
    if not meta_table:
        return metadata
    for line in meta_table.group(1).strip().splitlines():
        cols = [c.strip() for c in line.split("|")[1:-1]]
        if len(cols) >= 2:
            if cols[0] in metadata:
                raise ValueError("duplicate spec metadata field: " + cols[0])
            metadata[cols[0]] = cols[1]
    return metadata


def _parse_sections(content):
    """Gom gạch đầu dòng theo tiêu đề `## `. Gạch đầu dòng đứng TRƯỚC tiêu đề đầu tiên
    thuộc về mục ảo "Overview" (không có tiêu đề thì không vứt dữ liệu đi)."""
    sections = {}
    current_sec = "Overview"
    for line in content.splitlines():
        sec_match = re.match(r"^##\s+(.+)$", line)
        if sec_match:
            current_sec = sec_match.group(1).strip()
            sections[current_sec] = []
        elif line.strip().startswith("- ") or line.strip().startswith("* "):
            sections.setdefault(current_sec, []).append(line.strip()[2:])
    return sections


def _extract_touchpoint_paths(content):
    """Đường dẫn trong backtick ở mục 11 — và CHỈ mục 11.

    C-3 CHỈ neo vào mục "Architecture và code touchpoints" (mục 11 của FEATURE-SPEC template):
    đó là nơi spec khai SẢN PHẨM BÀN GIAO của chính repo này. CỐ Ý không quét toàn file —
    mục "3. Research current state" trích đường dẫn của REPO KHÁC (X-Studio, donghanh...),
    quét cả file sẽ cho dương tính giả hàng loạt (đã đo thật khi viết hàm này).
    """
    m = re.search(r"^##\s*\d*\.?\s*Architecture và code touchpoints\s*$(.*?)(?=^##\s|\Z)",
                  content, re.MULTILINE | re.DOTALL)
    touchpoint_body = m.group(1) if m else ""

    referenced_paths = set()
    for cand in re.findall(r"`([^`\n]+)`", touchpoint_body):
        cand = cand.strip()
        if cand.startswith(("http", "/", "-", "$", "@")) or " " in cand:
            continue
        # Phải trông như đường dẫn THẬT: có thư mục, hoặc có TÊN rồi mới tới đuôi file.
        # (Bản đầu bắt nhầm cả chuỗi ".sh" trần vì chỉ khớp đuôi — đã mắc thật khi viết hàm này.)
        looks_like_path = ("/" in cand) or re.fullmatch(
            r"[A-Za-z0-9_.-]+\.(sh|py|ts|md|json|ya?ml|ps1)", cand)
        if looks_like_path:
            referenced_paths.add(cand.rstrip("/"))
    return referenced_paths


def _parse_exemptions(content):
    """Miễn trừ C-3 phải KHAI LÝ DO ngay trong spec (cùng triết lý CODEMAP_EXEMPT):
      <!-- contract-exempt: scripts/x.sh — gỡ theo ADR-0004 -->
    Không có lý do thì không phải miễn trừ, chỉ là giấu lỗi (nên regex bắt buộc có phần lý do).
    """
    return {
        m_ex.group(1).strip(): m_ex.group(2).strip()
        for m_ex in re.finditer(r"<!--\s*contract-exempt:\s*(\S+?)\s+(?:—|--)\s+(.+?)\s*-->", content)
    }


def _display_path(path, start=None):
    """Duong dan de HIEN THI, uu tien tuong doi so voi ROOT_DIR.

    Tren Windows, os.path.relpath NEM ValueError khi hai duong dan nam tren hai o dia khac nhau
    ("path is on mount 'C:', start on mount 'D:'"). Gap that tren runner windows-latest: repo
    checkout o o dia D:, con thu muc tam cua mktemp o o dia C: -- spec-compiler chet ngay khi
    --spec tro toi mot o dia khac. Tren Linux khong bao gio xay ra vi khong co khai niem o dia,
    nen CI Linux khong bat duoc (cung ho loi chi-no-tren-Windows voi TRAPS.md muc 24/27).

    Day chi la chuoi de doc trong bao cao: khong lay duoc duong dan tuong doi thi dung duong dan
    tuyet doi, khong co ly do gi de lam hong ca lenh bien dich vi mot nhan hien thi.
    """
    try:
        return os.path.relpath(path, start if start is not None else ROOT_DIR)
    except ValueError:
        return os.path.abspath(path)


def parse_spec_markdown(spec_path):
    if not os.path.exists(spec_path):
        return None

    with open(spec_path, "r", encoding="utf-8", errors="ignore") as f:
        content = f.read()

    return parse_spec_text(content, spec_path)


def parse_spec_text(content, spec_path):
    """Parse already-read text so a handoff hashes and interprets the SAME bytes."""
    content = content.replace("\r\n", "\n").replace("\r", "\n")
    metadata = _parse_metadata_table(content)
    state = metadata.get("State", "").strip(" *_`").casefold()
    title_match = re.search(r"^#\s+(.+)$", content, re.MULTILINE)
    title = title_match.group(1).strip() if title_match else os.path.basename(spec_path)

    exempt_paths = _parse_exemptions(content)
    referenced_paths = _extract_touchpoint_paths(content) - set(exempt_paths)

    return {
        "spec_file": _display_path(spec_path),
        "title": title,
        "metadata": metadata,
        "sections": _parse_sections(content),
        "referenced_paths": sorted(referenced_paths),
        "exempt_paths": exempt_paths,
        # Mã định danh yêu cầu / tiêu chí chấp nhận (FR-1, AC-2, W-301...) — dùng để đối chiếu
        # spec có thật sự khai yêu cầu nào không, thay vì chỉ có tiêu đề rỗng.
        "requirement_ids": sorted(set(re.findall(r"\b((?:FR|AC|NFR|W)-\d+)\b", content))),
        # Approval language in instructions or unselected template options is NOT a selected state.
        "approved": state == "approved for implementation",
    }

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
        "if __name__ == '__main__':",
        "    unittest.main()",
        "",
    ])


def main():
    parser = argparse.ArgumentParser(description="Autonomous Spec-to-Contract Compiler Engine")
    parser.add_argument("--spec", type=str, help="Path to markdown spec file (e.g. docs/specs/2026-09-13-quickstart-adoption.md)")
    parser.add_argument("--out-dir", type=str, default="tests/contracts", help="Output directory for generated contract tests")
    parser.add_argument("--compile-all", action="store_true", help="Compile all specs in docs/specs/")
    parser.add_argument("--json", action="store_true", help="Output JSON structure of compiled spec")

    args = parser.parse_args()

    specs_dir = os.path.join(ROOT_DIR, "docs", "specs")
    target_specs = []

    if args.compile_all:
        if os.path.exists(specs_dir):
            for f in sorted(os.listdir(specs_dir)):
                if f.endswith(".md") and f != "README.md":
                    target_specs.append(os.path.join(specs_dir, f))
    elif args.spec:
        spec_path = os.path.abspath(args.spec)
        target_specs.append(spec_path)
    else:
        print("Error: Specify --spec <path> or --compile-all", file=sys.stderr)
        sys.exit(1)

    # DỰ ÁN ĐÍCH mới dựng chưa có docs/specs/ — đó là trạng thái HỢP LỆ, không phải lỗi.
    # Trước đây rơi vào đây thì script im lặng không in gì, làm self-test đi kèm báo ĐỎ ở mọi
    # dự án đích (phát hiện 2026-09-14 khi smoke self-test ngay trong dự án đích).
    if not target_specs:
        print("Không có spec nào trong docs/specs/ — chưa có gì để biên dịch. "
              "Viết spec đầu tiên từ docs/framework/templates/FEATURE-SPEC.template.md.")
        sys.exit(0)

    compiled_results = []
    os.makedirs(os.path.join(ROOT_DIR, args.out_dir), exist_ok=True)

    for spec_path in target_specs:
        parsed = parse_spec_markdown(spec_path)
        if not parsed:
            continue
        compiled_results.append(parsed)

        test_code = generate_python_contract_test(parsed)
        spec_base = os.path.splitext(os.path.basename(spec_path))[0]
        safe_base = re.sub(r"[^a-zA-Z0-9_]", "_", spec_base)
        out_file = os.path.join(ROOT_DIR, args.out_dir, f"test_contract_{safe_base}.py")

        with open(out_file, "w", encoding="utf-8") as f:
            f.write(test_code)

        print(f"Compiled contract test: {_display_path(out_file)}")

    if args.json:
        print(json.dumps(compiled_results, indent=2, ensure_ascii=False))

if __name__ == "__main__":
    main()
