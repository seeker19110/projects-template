"""LD-06 / AC-6: mỗi hồ sơ C1–C10 nêu cách CHỨNG MINH hành vi, UX/DX, dữ liệu, bảo mật, release.

Kiểm ma trận trong `quality-gates-by-profile.md`: đủ hồ sơ (lấy từ bảng A0 của KHUNG-3, nguồn phân loại),
đủ 5 chiều, mọi ô trỏ tới cổng có thật (mục đánh số, bảng rollback, CLAUDE.md §3, hoặc file tồn tại).
Ca âm tính chạy cùng bộ kiểm trên văn bản đã làm hỏng, để chứng minh bộ kiểm đỏ được.
"""

from pathlib import Path
import re
from unittest import TestCase, main

ROOT = Path(__file__).resolve().parents[1]
QG = "docs/framework/quality-gates-by-profile.md"
MATRIX_HEADING = "## Ma trận bằng chứng theo hồ sơ (AC-6)"
TIER_HEADING = "### Độ sâu bằng chứng theo mức rủi ro"
HEADER = ["Hồ sơ", "Hành vi", "UX/DX", "Dữ liệu", "Bảo mật", "Release"]
TIER_HEADER = ["Mức", "Chiều phải chứng minh", "Độ sâu bằng chứng", "Nơi ghi"]
FORBIDDEN = ("chưa có", "todo", "[điền", "n/a")
REF = re.compile(r"§(C\d+)\.(\d+)|§PII\.(\d+)|§RB-(C\d+)|CLAUDE §3\.(\d+)|`([^`]+)`")


def read(rel):
    return (ROOT / rel).read_text(encoding="utf-8")


def profiles(k3_text):
    return re.findall(r"(?m)^\| \d+ \|.*\| (C\d+)\b[^|]*\|\s*$", k3_text)


def section_items(qg_text):
    """{'C4': {'1', ...}, 'PII': {...}} — số mục đánh số của từng phần `## `."""
    items = {}
    for block in re.split(r"(?m)^(?=## )", qg_text):
        head = re.match(r"## (C\d+) |## Cổng bổ sung", block)
        if head:
            key = head[1] or "PII"
            items[key] = set(re.findall(r"(?m)^(\d+)\. ", block))
    return items


def table_under(text, heading):
    if heading not in text:
        return None
    rows = []
    for line in text.split(heading, 1)[1].splitlines()[1:]:
        if not line.startswith("|"):
            if rows:
                break
            continue
        cells = [c.strip() for c in line.strip().strip("|").split("|")]
        if not set("".join(cells)) <= set("-: "):
            rows.append(cells)
    return rows


def claude_items(claude_text):
    body = claude_text.split("## 3. ", 1)[1].split("\n## ", 1)[0]
    return set(re.findall(r"(?m)^(\d+)\. ", body))


def unresolved(cell, ctx):
    bad = []
    for c_id, c_item, pii, rb, claude, path in REF.findall(cell):
        ok = (
            (c_id and c_item in ctx["items"].get(c_id, ()))
            or (pii and pii in ctx["items"].get("PII", ()))
            or (rb and rb in ctx["rollback"])
            or (claude and claude in ctx["claude"])
            or (
                path
                and (
                    ("/" not in path and not path.endswith(".md"))
                    or (ROOT / path).exists()
                )
            )
        )
        if not ok:
            bad.append(
                c_id
                and f"§{c_id}.{c_item}"
                or pii
                and f"§PII.{pii}"
                or rb
                and f"§RB-{rb}"
                or claude
                and f"CLAUDE §3.{claude}"
                or path
            )
    return bad


def check_cells(rows, ctx, ref_from=1):
    """Mọi ô phải điền; từ cột `ref_from` trở đi ô phải trỏ tới cổng/bằng chứng giải được."""
    errors = []
    for row in rows:
        for col, (name, cell) in enumerate(zip(ctx["header"][1:], row[1:]), start=1):
            where = f"{row[0]}/{name}"
            if not cell or any(word in cell.lower() for word in FORBIDDEN):
                errors.append(f"{where}: ô rỗng hoặc chưa điền")
            elif col >= ref_from and not REF.search(cell):
                errors.append(f"{where}: không trỏ tới cổng/bằng chứng nào")
            errors += [f"{where}: {ref} không tồn tại" for ref in unresolved(cell, ctx)]
    return errors


def validate(qg_text, claude_text, expected_profiles):
    rows = table_under(qg_text, MATRIX_HEADING)
    if not rows:
        return [f"thiếu bảng dưới '{MATRIX_HEADING}'"]
    ctx = {
        "items": section_items(qg_text),
        "rollback": set(re.findall(r"(?m)^\| (C\d+) ", qg_text)),
        "claude": claude_items(claude_text),
        "header": rows[0],
    }
    errors = [] if rows[0] == HEADER else [f"header sai: {rows[0]}"]
    names = [r[0] for r in rows[1:]]
    if sorted(names) != sorted(expected_profiles) or len(set(names)) != len(names):
        errors.append(f"hồ sơ trong ma trận {names} ≠ hồ sơ A0 {expected_profiles}")
    errors += [f"{r[0]}: thiếu cột" for r in rows[1:] if len(r) != len(HEADER)]
    errors += check_cells(rows[1:], ctx)
    tiers = table_under(qg_text, TIER_HEADING)
    if (
        not tiers
        or tiers[0] != TIER_HEADER
        or [t[0] for t in tiers[1:]] != ["S", "M", "L"]
    ):
        errors.append("thiếu bảng mức rủi ro S/M/L đúng cột")
    else:
        errors += check_cells(tiers[1:], {**ctx, "header": tiers[0]}, ref_from=2)
    return errors


class ProfileQualityMatrix(TestCase):
    def setUp(self):
        self.qg = read(QG)
        self.claude = read("CLAUDE.md")
        self.profiles = profiles(
            read("docs/framework/03-tech-selection-and-proactive-advice.md")
        )

    def test_classification_lists_ten_profiles(self):
        self.assertEqual(self.profiles, [f"C{n}" for n in range(1, 11)])

    def test_every_profile_proves_five_dimensions_with_real_gates(self):
        self.assertEqual(validate(self.qg, self.claude, self.profiles), [])

    def test_validator_rejects_broken_matrices(self):
        good = self.qg
        self.assertEqual(validate(good, self.claude, self.profiles), [])
        broken = {
            "thiếu ma trận": good.replace(MATRIX_HEADING, "## Khác"),
            "ô chưa điền": re.sub(
                r"(?m)^(\| C4 \|[^|]*\|)[^|]*\|", r"\1 chưa có |", good, count=1
            ),
            "mục không tồn tại": re.sub(r"§C4\.8", "§C4.99", good, count=1),
            "file không tồn tại": good.replace(
                "`docs/ops/release-readiness.md`", "`docs/ops/khong-co.md`", 1
            ),
            "thiếu hồ sơ": re.sub(r"(?m)^\| C10 \|.*\n", "", good, count=1),
            "thiếu mức L": re.sub(r"(?m)^\| L \|.*\n", "", good, count=1),
        }
        for name, text in broken.items():
            self.assertNotEqual(text, good, f"ca '{name}' không làm hỏng được văn bản")
            self.assertTrue(
                validate(text, self.claude, self.profiles), f"ca '{name}' không bị bắt"
            )
        self.assertTrue(
            validate(good, self.claude, self.profiles + ["C11"]),
            "thêm hồ sơ A0 mà ma trận không có",
        )


if __name__ == "__main__":
    main()
