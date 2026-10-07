#!/usr/bin/env python3
"""
arch-health-radar.py — Repo Health & Tech Debt Radar

Đo KỶ LUẬT KỸ THUẬT ĐO ĐƯỢC của repo: độ phủ cổng CI trên từng script, chất lượng spec,
kỷ luật kích thước file mã, mật độ chú thích trong file MÃ, và nợ TODO/FIXME.

KHÔNG đo coupling / cyclomatic complexity — repo này là tài liệu + script, không có đồ thị
import để phân tích. Báo cáo IN RA công thức chấm điểm để con số không bị đọc nhầm thành
"điểm kiến trúc" tổng quát (audit 2026-09-13, A-02).
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

EXCLUDE_DIRS = {".git", "node_modules", "venv", ".venv", "__pycache__", ".ai-telemetry", ".hermes", "dist", "build", "coverage"}

CODE_EXT = {".sh", ".py", ".ts", ".js", ".ps1", ".mjs"}
DOC_EXT = {".md", ".mdc"}
LARGE_CODE_LINES = 400   # ngưỡng cho FILE MÃ
LARGE_DOC_LINES = 900    # tài liệu dài là bình thường, ngưỡng riêng và rộng hơn


def _count_code_files(file_type_counts):
    return sum(n for e, n in file_type_counts.items() if e in CODE_EXT)


def _list_scripts(scripts_dir):
    """Mọi script trong scripts/, đã sắp xếp. Thư mục không tồn tại -> danh sách rỗng."""
    if not os.path.isdir(scripts_dir):
        return []
    return sorted(f for f in os.listdir(scripts_dir)
                  if os.path.splitext(f)[1] in (".sh", ".py"))


def _ci_gate_tests(test_scripts):
    """Lọc ra test THẬT SỰ được ci.yml chạy.

    ci.yml là nguồn DUY NHẤT: một file tên `test-*` không nằm trong ci.yml thì không phải
    cổng, nên không được tính là bảo vệ ai cả (kể cả chính nó).
    """
    ci_path = os.path.join(ROOT_DIR, ".github", "workflows", "ci.yml")
    if not os.path.exists(ci_path):
        return []
    with open(ci_path, encoding="utf-8", errors="ignore") as fp:
        ci_text = fp.read()
    return [t for t in test_scripts if t in ci_text]


def _scripts_covered_by(test_name, scripts_dir, all_scripts):
    """Script nào được MỘT test cổng nhắc tới (kể cả chính test đó).

    Luật wrapper: `x.sh` được nhắc thì `x.py` cùng tên cũng coi là được phủ, vì wrapper .sh
    chỉ là lớp vỏ gọi thẳng .py. Không đọc được thân test -> chỉ tính chính nó, không vỡ.
    """
    covered = {test_name}
    try:
        with open(os.path.join(scripts_dir, test_name), encoding="utf-8", errors="ignore") as fp:
            body = fp.read()
    except OSError:
        return covered
    for cand in all_scripts:
        if cand not in body:
            continue
        covered.add(cand)
        stem, ext = os.path.splitext(cand)
        if ext == ".sh" and stem + ".py" in all_scripts:
            covered.add(stem + ".py")
    return covered


def _scripts_covered_by_python_tests(test_name, scripts_dir, all_scripts):
    """Script được test Python (`tests/*.py`) mà MỘT test cổng trong CI nhắc tới.

    Test Python không nằm ở scripts/ nên luật đọc-thân-`test-*.sh` không thấy nó (F-N02). Chỉ tính test Python
    mà thân một test CHẠY TRONG CI gọi bằng đường dẫn `tests/<tên>.py`; test không ai gọi thì không phải cổng.
    Script được coi là phủ khi tên file (`x-y.py`) hoặc tên module nạp động (`"x-y"`) xuất hiện trong thân nó.
    """
    covered = set()
    try:
        with open(os.path.join(scripts_dir, test_name), encoding="utf-8", errors="ignore") as fp:
            body = fp.read()
    except OSError:
        return covered
    tests_dir = os.path.join(os.path.dirname(scripts_dir), "tests")
    for ref in set(re.findall(r"tests/([\w.-]+\.py)", body)) | set(re.findall(r"\b(test_[\w-]+\.py)\b", body)):
        try:
            with open(os.path.join(tests_dir, ref), encoding="utf-8", errors="ignore") as fp:
                tbody = fp.read()
        except OSError:
            continue
        for cand in all_scripts:
            stem, ext = os.path.splitext(cand)
            if ext == ".py" and (cand in tbody or f'"{stem}"' in tbody or f"'{stem}'" in tbody):
                covered.add(cand)
    return covered


def _scripts_inventory():
    """Kiểm kê script + xem cái nào được một test CHẠY TRONG CI gọi tới.

    Đây là tín hiệu sức khoẻ THẬT của repo này: repo khung không có đồ thị import để đo
    coupling, nhưng "script nào có cổng bảo vệ" thì đo được chính xác và hành động được.
    """
    scripts_dir = os.path.join(ROOT_DIR, "scripts")
    all_scripts = _list_scripts(scripts_dir)
    if not all_scripts:
        return [], set(), set()
    ci_tests = _ci_gate_tests([f for f in all_scripts if f.startswith("test-")])
    covered = set()
    for t in ci_tests:
        covered |= _scripts_covered_by(t, scripts_dir, all_scripts)
        covered |= _scripts_covered_by_python_tests(t, scripts_dir, all_scripts)
    return all_scripts, covered, set(ci_tests)


def _spec_quality():
    """Spec có khai mã yêu cầu và mục touchpoints không — gốc rễ của engine vỏ rỗng
    (audit 2026-09-13: 2 spec dừng ở mục 5 nên không gì ràng buộc phần triển khai)."""
    specs_dir = os.path.join(ROOT_DIR, "docs", "specs")
    total, good, weak = 0, 0, []
    if not os.path.isdir(specs_dir):
        return 0, 0, []
    for f in sorted(os.listdir(specs_dir)):
        if not f.endswith(".md") or f == "README.md":
            continue
        total += 1
        with open(os.path.join(specs_dir, f), encoding="utf-8", errors="ignore") as fp:
            body = fp.read()
        has_ids = bool(re.search(r"\b(?:FR|AC|NFR|W)-\d+\b", body))
        has_touch = "Architecture và code touchpoints" in body
        if has_ids and has_touch:
            good += 1
        else:
            missing = []
            if not has_ids:
                missing.append("không có mã FR-/AC-")
            if not has_touch:
                missing.append("thiếu mục 11 touchpoints")
            weak.append({"file": f"docs/specs/{f}", "missing": ", ".join(missing)})
    return total, good, weak


def _measure_code_file(rel_path, lines, acc):
    """Đo MỘT file mã: kỷ luật kích thước, dòng mã vs dòng chú thích, dấu nợ TODO/FIXME."""
    if len(lines) > LARGE_CODE_LINES:
        acc["large_code_files"].append({"file": rel_path, "lines": len(lines)})
    for idx, l in enumerate(lines, 1):
        l_str = l.strip()
        if not l_str:
            continue
        if l_str.startswith("#") or l_str.startswith("//"):
            acc["code_comment_lines"] += 1
        else:
            acc["code_lines"] += 1
        # Marker phải nằm NGAY SAU dấu chú thích. Khớp trần "\bTODO\b" sẽ bắt nhầm
        # chính regex này, docstring và dòng in báo cáo của file này (đã đo thật:
        # 3 dương tính giả, làm điểm tụt 30 mà không có việc gì để sửa).
        if re.search(r"(?:^|\s)(?:#|//)\s*(?:TODO|FIXME|XXX|HACK)\b", l_str):
            acc["todo_markers"].append({"file": rel_path, "line": idx})


def _read_lines(full_path):
    """Trả về danh sách dòng, hoặc None nếu không đọc được (file bị xoá giữa chừng, quyền...)."""
    try:
        with open(full_path, "r", encoding="utf-8", errors="ignore") as fp:
            return fp.readlines()
    except OSError:
        return None


def _walk_repo_files():
    """Duyệt repo một lượt, gom các con số thô. Tài liệu và file mã đếm TÁCH BẠCH —
    gộp chúng chính là lỗi của bản cũ (67% .md bị đếm thành 'code')."""
    acc = {
        "total_files": 0, "total_lines": 0, "file_type_counts": {},
        "large_code_files": [], "large_doc_files": [],
        "code_lines": 0, "code_comment_lines": 0, "doc_lines": 0, "todo_markers": [],
    }
    for dirpath, dirnames, filenames in os.walk(ROOT_DIR):
        dirnames[:] = [d for d in dirnames if d not in EXCLUDE_DIRS]
        for f in filenames:
            full_path = os.path.join(dirpath, f)
            lines = _read_lines(full_path)
            if lines is None:
                continue

            ext = os.path.splitext(f)[1].lower() or "(no-ext)"
            # relpath nem ValueError khi khac o dia tren Windows (xem _display_path cua spec-compiler).
            try:
                rel_path = os.path.relpath(full_path, ROOT_DIR).replace(os.sep, "/")
            except ValueError:
                rel_path = os.path.abspath(full_path).replace(os.sep, "/")
            acc["total_files"] += 1
            acc["total_lines"] += len(lines)
            acc["file_type_counts"][ext] = acc["file_type_counts"].get(ext, 0) + 1

            if ext in DOC_EXT:
                acc["doc_lines"] += len(lines)
                if len(lines) > LARGE_DOC_LINES:
                    acc["large_doc_files"].append({"file": rel_path, "lines": len(lines)})
            elif ext in CODE_EXT:
                _measure_code_file(rel_path, lines, acc)
    return acc


def _pct(part, whole):
    return 100.0 if whole == 0 else round(100.0 * part / whole, 1)


def _compute_signals(acc, scripts_total, scripts_covered, spec_total, spec_good):
    """5 tín hiệu, mỗi tín hiệu 0-100. Công thức được IN RA báo cáo nên không ai đọc nhầm."""
    code_file_total = _count_code_files(acc["file_type_counts"])
    comment = 100.0 if acc["code_lines"] == 0 else min(
        100.0, round(100.0 * (acc["code_comment_lines"] / acc["code_lines"]) / 0.15, 1))
    todo_count = len(acc["todo_markers"])
    return {
        "gate_coverage": _pct(scripts_covered, scripts_total),
        "spec_quality": _pct(spec_good, spec_total),
        "size_discipline": _pct(max(0, code_file_total - len(acc["large_code_files"])),
                                code_file_total),
        "comment_density": comment,
        "todo_debt": 100.0 if not todo_count else max(0.0, 100.0 - 10.0 * todo_count),
    }


def scan_codebase_health():
    """Đo các tín hiệu CÓ THẬT, mỗi tín hiệu nói rõ nó đo gì.

    VÌ SAO VIẾT LẠI (audit 2026-09-13, A-02): bản cũ chấm điểm bằng đúng hai thứ —
    số file > 400 dòng và tỷ lệ dòng mở đầu bằng '#'. Nó KHÔNG đo kiến trúc, và tệ hơn,
    nó đếm văn xuôi Markdown là "code" nên báo repo 67% là .md thành "84% code".
    Bản này đo thứ hành động được, và IN RA CÔNG THỨC để không ai hiểu nhầm con số.
    """
    acc = _walk_repo_files()
    all_scripts, covered, ci_tests = _scripts_inventory()
    covered_in_repo = covered & set(all_scripts)
    spec_total, spec_good, spec_weak = _spec_quality()

    signals = _compute_signals(acc, len(all_scripts), len(covered_in_repo),
                               spec_total, spec_good)
    weights = {"gate": 40, "spec": 20, "size": 15, "comment": 15, "todo": 10}
    health_score = round(
        (signals["gate_coverage"] * weights["gate"] + signals["spec_quality"] * weights["spec"]
         + signals["size_discipline"] * weights["size"]
         + signals["comment_density"] * weights["comment"]
         + signals["todo_debt"] * weights["todo"]) / 100.0)

    return {
        "health_score": health_score,
        "weights": weights,
        "signals": signals,
        "total_files": acc["total_files"],
        "total_lines": acc["total_lines"],
        "code_lines": acc["code_lines"],
        "code_comment_lines": acc["code_comment_lines"],
        "doc_lines": acc["doc_lines"],
        "doc_ratio_pct": _pct(acc["doc_lines"], acc["total_lines"]),
        "file_type_counts": dict(sorted(acc["file_type_counts"].items(), key=lambda kv: -kv[1])),
        "scripts_total": len(all_scripts),
        "scripts_covered": len(covered_in_repo),
        "scripts_uncovered": sorted(set(all_scripts) - covered),
        "ci_tests": sorted(ci_tests),
        "spec_total": spec_total,
        "spec_good": spec_good,
        "spec_weak": spec_weak,
        "large_code_files": acc["large_code_files"],
        "large_doc_files": acc["large_doc_files"],
        "todo_markers": acc["todo_markers"],
        "recommendations": [],
    }


def generate_recommendations(data):
    """Đề xuất phải TRỎ VÀO VIỆC CỤ THỂ. Câu chung chung kiểu 'giữ vững kỷ luật refactoring'
    không hành động được nên không in ra."""
    recs = []
    if data["scripts_uncovered"]:
        recs.append("Thêm test (và nối vào `ci.yml`) cho: "
                    + ", ".join(f"`scripts/{x}`" for x in data["scripts_uncovered"]))
    for w in data["spec_weak"]:
        recs.append(f"Bổ sung cho `{w['file']}`: {w['missing']}")
    for lf in data["large_code_files"]:
        recs.append(f"File mã `{lf['file']}` dài {lf['lines']} dòng (> {LARGE_CODE_LINES}) — cân nhắc tách")
    for t in data["todo_markers"]:
        recs.append(f"Giải quyết hoặc chuyển thành issue: `{t['file']}:{t['line']}`")
    if not recs:
        recs.append("Không còn tín hiệu nợ kỹ thuật nào ĐO ĐƯỢC BẰNG CÁC THƯỚC Ở TRÊN.")
    return recs


# Bốn khối mục TUỲ CHỌN của báo cáo tách riêng khỏi `format_markdown_report` để hàm đó nằm
# dưới trần CC 12 mà `scripts/check-python-complexity.sh` cưỡng chế. Trước đây chỗ này là một dấu nợ
# kỹ thuật có điều kiện quay lại "HOẶC repo dựng cổng máy cưỡng chế CC <= 12" — cổng đã có, nợ đã trả.
# Giữ NGUYÊN thứ tự bốn khối: thứ tự mục trong báo cáo là hành vi mà `test-py-coverage.sh` chạm tới.
def _optional_report_blocks(data):
    lines = []
    if data["scripts_uncovered"]:
        lines += ["", f"### ⚠️ Script KHÔNG có cổng bảo vệ ({len(data['scripts_uncovered'])})", ""]
        lines += [f"- `scripts/{x}`" for x in data["scripts_uncovered"]]

    if data["spec_weak"]:
        lines += ["", f"### ⚠️ Spec chưa đạt chuẩn ({len(data['spec_weak'])})", ""]
        lines += [f"- `{x['file']}` — {x['missing']}" for x in data["spec_weak"]]

    if data["large_code_files"]:
        lines += ["", f"### File mã dài (> {LARGE_CODE_LINES} dòng)", "", "| File | Dòng |", "| :--- | ---: |"]
        lines += [f"| `{lf['file']}` | {lf['lines']} |" for lf in data["large_code_files"]]

    if data["large_doc_files"]:
        lines += ["", f"### File tài liệu dài (> {LARGE_DOC_LINES} dòng — thông tin, KHÔNG trừ điểm)",
                  "", "| File | Dòng |", "| :--- | ---: |"]
        lines += [f"| `{lf['file']}` | {lf['lines']} |" for lf in data["large_doc_files"]]

    return lines


def format_markdown_report(data):
    sig = data["signals"]
    w = data["weights"]
    score = data["health_score"]
    lines = [
        "## 🛡️ Repo Health & Tech Debt Radar",
        "",
        f"- **Điểm sức khoẻ:** `{score}/100` " + ("🟢" if score >= 90 else "🟡" if score >= 70 else "🔴"),
        "",
        "### Điểm được tính ra sao (in công thức để không ai hiểu nhầm con số)",
        "",
        "| Tín hiệu | Đo cái gì | Điểm | Trọng số |",
        "| :--- | :--- | ---: | ---: |",
        f"| Độ phủ cổng | % script trong `scripts/` được một test CHẠY TRONG CI phủ | {sig['gate_coverage']} | {w['gate']}% |",
        f"| Chất lượng spec | % spec có mã `FR-`/`AC-` **và** mục 11 touchpoints | {sig['spec_quality']} | {w['spec']}% |",
        f"| Kỷ luật kích thước | % file MÃ ≤ {LARGE_CODE_LINES} dòng (tài liệu tính riêng) | {sig['size_discipline']} | {w['size']}% |",
        f"| Mật độ chú thích | tỷ lệ chú thích trong file MÃ, chuẩn hoá theo mốc 15% | {sig['comment_density']} | {w['comment']}% |",
        f"| Nợ TODO/FIXME | trừ 10 điểm mỗi dấu TODO/FIXME/XXX/HACK còn sót | {sig['todo_debt']} | {w['todo']}% |",
        "",
        "> **Giới hạn trung thực:** repo này chủ yếu là tài liệu + script, không có đồ thị import",
        "> nên thước này **không** đo coupling hay cyclomatic complexity như công cụ kiến trúc thật.",
        "> Nó đo kỷ luật kỹ thuật *đo được* của chính repo. Đừng đọc nó như điểm kiến trúc tổng quát.",
        "",
        "### Quy mô",
        "",
        f"- Tổng: `{data['total_files']}` file / `{data['total_lines']}` dòng",
        f"- Mã: `{data['code_lines']}` dòng (+ `{data['code_comment_lines']}` dòng chú thích)",
        f"- Tài liệu: `{data['doc_lines']}` dòng — **{data['doc_ratio_pct']}%** tổng số dòng",
        f"- Script: `{data['scripts_covered']}`/`{data['scripts_total']}` có cổng bảo vệ trong CI",
        f"- Spec: `{data['spec_good']}`/`{data['spec_total']}` đạt chuẩn (có FR/AC + touchpoints)",
        "",
        "### Phân bổ loại file",
        "",
        "| Mở rộng | Số file |",
        "| :--- | ---: |",
    ]
    for ext, count in data["file_type_counts"].items():
        lines.append(f"| `{ext}` | {count} |")

    lines += _optional_report_blocks(data)

    lines += ["", "### Việc cần làm", ""]
    lines += [f"- {r}" for r in data["recommendations"]]
    return "\n".join(lines)


def main():
    parser = argparse.ArgumentParser(description="Architectural Health & Tech Debt Radar Engine")
    parser.add_argument("--scan", action="store_true", help="Scan codebase and print Markdown report")
    parser.add_argument("--json", action="store_true", help="Output JSON results")

    args = parser.parse_args()
    data = scan_codebase_health()
    data["recommendations"] = generate_recommendations(data)

    if args.json:
        print(json.dumps(data, indent=2, ensure_ascii=False))
    else:
        print(format_markdown_report(data))

if __name__ == "__main__":
    main()
