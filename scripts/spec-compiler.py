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
import shutil

# Console Windows mặc định dùng cp1252 → in tiếng Việt/emoji ra stdout sẽ chết với
# UnicodeEncodeError. Ép UTF-8 để engine chạy được trên mọi nền (xem TRAPS.md).
for _stream in (sys.stdout, sys.stderr):
    if hasattr(_stream, "reconfigure"):
        _stream.reconfigure(encoding="utf-8")

ROOT_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
_SCRIPTS_DIR = os.path.dirname(os.path.abspath(__file__))
if _SCRIPTS_DIR not in sys.path:
    sys.path.insert(0, _SCRIPTS_DIR)
from _spec_contract_gen import generate_python_contract_test  # noqa: E402  (tái xuất: main() và tests dùng compiler.generate_python_contract_test)

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


# --- Bản đồ AC → bằng chứng (LD-03) -------------------------------------------------------------
# Spec đặt tên từ ngày này trở đi (đã Approved) phải khai bản đồ; spec cũ hơn không bị bắt hồi tố.
EVIDENCE_MAP_REQUIRED_FROM = "2026-10-07"
_PENDING = re.compile(r"chưa có|pending", re.IGNORECASE)
_MANUAL = re.compile(r"^(thủ công|manual)\s*:\s*\S", re.IGNORECASE)


def _ac_sort_key(ac_id):
    return int(ac_id.split("-")[1])


def _acceptance_ids(content):
    """AC bắt buộc = mã AC trong mục "Acceptance criteria"; không có mục đó thì lấy cả file."""
    m = re.search(
        r"^##\s*\d*\.?\s*Acceptance criteria\s*$(.*?)(?=^##\s|\Z)",
        content,
        re.M | re.S | re.I,
    )
    source = m.group(1) if m else content
    return sorted(set(re.findall(r"\bAC-\d+\b", source)), key=_ac_sort_key)


def _cells(line):
    stripped = line.strip()
    if not stripped.startswith("|"):
        return None
    return [c.strip() for c in stripped.strip("|").split("|")]


def _evidence_entry(cells, col):
    """Một dòng bảng → {acceptance_id, refs, kind}. kind: test | manual | pending | empty."""
    ac = re.fullmatch(r"(AC-\d+)", cells[0].strip("*` "))
    if not ac:
        return None
    cell = cells[col] if col < len(cells) else ""
    refs = [r.strip() for r in re.findall(r"`([^`\n]+)`", cell) if r.strip()]
    if refs:
        kind = "test"
    elif _MANUAL.search(cell):
        kind = "manual"
    elif _PENDING.search(cell):
        kind = "pending"
    else:
        kind = "empty"
    return {"acceptance_id": ac.group(1), "refs": refs, "kind": kind}


def _evidence_map(content):
    """Bảng đầu tiên có cột đầu `AC` và một cột `Bằng chứng`/`Evidence`. Không có bảng → None."""
    lines = content.split("\n")
    for idx, line in enumerate(lines):
        header = _cells(line)
        if not header or header[0].upper() != "AC":
            continue
        cols = [
            i
            for i, c in enumerate(header)
            if re.search(r"bằng chứng|evidence", c, re.I)
        ]
        if not cols:
            continue
        entries = []
        for row in lines[idx + 2 :]:
            cells = _cells(row)
            if cells is None:
                break
            entry = _evidence_entry(cells, cols[0])
            if entry:
                entries.append(entry)
        return entries
    return None


def _evidence_map_required(spec_path, approved):
    date = re.match(r"(\d{4}-\d{2}-\d{2})-", os.path.basename(spec_path))
    return approved and (date is None or date.group(1) >= EVIDENCE_MAP_REQUIRED_FROM)


def _ref_problem(root, ref):
    """None nếu `path` hoặc `path::ký hiệu` có thật dưới root; ngược lại là lý do."""
    path, _, symbol = ref.partition("::")
    target = os.path.join(root, path)
    if not os.path.isfile(target):
        return "không có file " + path
    if symbol:
        with open(target, encoding="utf-8", errors="ignore") as f:
            if symbol not in f.read():
                return "không thấy '" + symbol + "' trong " + path
    return None


def _trace_status(entry, root):
    if entry is None:
        return "UNMAPPED", "không có dòng trong bản đồ AC → bằng chứng"
    if entry["kind"] == "test":
        problems = [p for p in (_ref_problem(root, r) for r in entry["refs"]) if p]
        if problems:
            return "BROKEN", "; ".join(problems)
        return "MAPPED", ", ".join(entry["refs"])
    labels = {
        "manual": ("MANUAL", "quan sát thủ công đã khai"),
        "pending": ("PENDING", "khai minh bạch là chưa có bằng chứng"),
        "empty": ("EMPTY", "ô bằng chứng trống"),
    }
    return labels[entry["kind"]]


def trace_acceptance(parsed, root):
    """Truy vết từng AC. Đây là traceability (đã khai CÁI GÌ chứng minh), KHÔNG phải nghiệm thu:
    kết quả chạy của đúng commit nằm ở CI / `dev-task.sh evidence-check`."""
    by_id = {}
    for entry in parsed["evidence_map"] or []:
        merged = by_id.setdefault(entry["acceptance_id"], dict(entry, refs=[]))
        merged["refs"] += entry["refs"]
        if entry["kind"] == "test":
            merged["kind"] = "test"
    rows = [
        (ac,) + _trace_status(by_id.get(ac), root) for ac in parsed["acceptance_ids"]
    ]
    rows += [
        (ac, "UNKNOWN", "AC không có trong mục Acceptance criteria")
        for ac in sorted(set(by_id) - set(parsed["acceptance_ids"]), key=_ac_sort_key)
    ]
    return rows


def _project_root(spec_path):
    norm = os.path.abspath(spec_path).replace("\\", "/")
    marker = "/docs/specs/"
    return norm[: norm.rindex(marker)] if marker in norm else ROOT_DIR


def print_trace(spec_path):
    parsed = parse_spec_markdown(spec_path)
    if parsed is None:
        print("Không có spec: " + spec_path, file=sys.stderr)
        return 2
    rows = trace_acceptance(parsed, _project_root(spec_path))
    for ac, status, detail in rows:
        print(f"{ac:<7} {status:<9} {detail}")
    complete = rows and all(status in ("MAPPED", "MANUAL") for _, status, _ in rows)
    if complete:
        print(
            "TRACE COMPLETE — mọi AC đã khai bằng chứng có thật. Chưa phải nghiệm thu: cần kết quả "
            "chạy của đúng commit (CI / dev-task.sh evidence-check)."
        )
        return 0
    print(
        "TRACE INCOMPLETE — còn AC thiếu/gãy/chưa có bằng chứng (hoặc spec không có AC); "
        "không được gọi là đã nghiệm thu hành vi."
    )
    return 1


def _display_path(path):
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
        return os.path.relpath(path, ROOT_DIR)
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
        "acceptance_ids": _acceptance_ids(content),
        "evidence_map": _evidence_map(content),
        "evidence_map_required": _evidence_map_required(spec_path, state == "approved for implementation"),
    }

def main():
    parser = argparse.ArgumentParser(description="Autonomous Spec-to-Contract Compiler Engine")
    parser.add_argument("--spec", type=str, help="Path to markdown spec file (e.g. docs/specs/2026-09-13-quickstart-adoption.md)")
    parser.add_argument("--out-dir", type=str, default="tests/contracts", help="Output directory for generated contract tests")
    parser.add_argument("--compile-all", action="store_true", help="Compile all specs in docs/specs/")
    parser.add_argument("--json", action="store_true", help="Output JSON structure of compiled spec")
    parser.add_argument("--trace", type=str, metavar="SPEC",
                        help="Truy vết AC → bằng chứng của một spec; exit 0 chỉ khi mọi AC có bằng chứng thật")

    args = parser.parse_args()

    if args.trace:
        sys.exit(print_trace(os.path.abspath(args.trace)))

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
    # Python dùng lại .pyc khi file nguồn có CÙNG mtime (giây) và CÙNG kích thước: sửa spec rồi biên dịch lại
    # trong cùng giây với đường dẫn dài bằng nhau → unittest chạy test CŨ, kết quả sai chiều (TRAPS mục 64).
    shutil.rmtree(os.path.join(ROOT_DIR, args.out_dir, "__pycache__"), ignore_errors=True)

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
