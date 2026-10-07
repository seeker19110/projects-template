"""LD-02: quy trình theo rủi ro, agent chính trực tiếp, không hạ cổng (AC-2).

Kiểm hợp đồng tài liệu đang chi phối agent (không phải văn phong) và chạy parser spec thật
trên một spec gọn để chứng minh spec gọn vẫn mang approval + AC qua cùng cổng máy.
"""

from pathlib import Path
import importlib.util
import re
from unittest import TestCase, main

ROOT = Path(__file__).resolve().parents[1]
DELIVERY = "docs/framework/standard-delivery.md"
TEMPLATE = "docs/framework/templates/FEATURE-SPEC.template.md"
LITE_SECTIONS = ("1", "2", "5", "9", "11")


def read(rel):
    return (ROOT / rel).read_text(encoding="utf-8")


def load_compiler():
    spec = importlib.util.spec_from_file_location(
        "spec_compiler", ROOT / "scripts/spec-compiler.py"
    )
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def section(text, heading):
    match = re.search(rf"(?ms)^{re.escape(heading)}\n(.*?)(?=^## |\Z)", text)
    return match[1] if match else ""


def compact_spec(state, criteria):
    template = read(TEMPLATE)
    head = template.split("\n## ", 1)[0].replace(
        "Draft / In review / **Approved for implementation**", state
    )
    parts = [head]
    for number in LITE_SECTIONS:
        heading = re.search(rf"(?m)^## {number}\. .+$", template)[0]
        parts.append(f"{heading}\n\n{criteria if number == '9' else 'Nội dung.'}\n")
    return "\n".join(parts)


class RiskTiers(TestCase):
    def test_delivery_contract_defines_three_tiers_without_lowering_gates(self):
        tiers = section(read(DELIVERY), "### 3c. Mức quy trình theo rủi ro")
        self.assertTrue(tiers, "standard-delivery.md thiếu §3c")
        for tier in ("| S ", "| M ", "| L "):
            self.assertIn(tier, tiers)
        for gate in (
            "dev-task.sh gate",
            "đỏ-trước",
            "Approved for implementation",
            "§9",
        ):
            self.assertIn(gate, tiers, f"§3c phải giữ cổng: {gate}")
        self.assertIn("nghi ngờ thì chọn mức cao hơn", tiers)

    def test_main_agent_codes_and_rights_stay_separate(self):
        tiers = section(read(DELIVERY), "### 3c. Mức quy trình theo rủi ro")
        self.assertIn("Agent chính tự làm", tiers)
        self.assertIn("quyền code ≠ quyền merge ≠ quyền deploy", tiers)

    def test_three_tier_orchestration_is_opt_in(self):
        orch = read("docs/framework/orchestration-3-tier.md")
        self.assertIn("Chế độ tùy chọn cho mức L", orch)
        self.assertIn("standard-delivery.md` §3c", orch)

    def test_entry_docs_route_to_tiers(self):
        for rel in ("CLAUDE.md", "AGENTS.md", ".claude/commands/auto.md"):
            self.assertIn("§3c", read(rel), f"{rel} phải trỏ tới mức quy trình §3c")

    def test_feature_gate_still_enforced_by_pr_policy(self):
        policy = read(".github/workflows/pr-policy.yml")
        self.assertIn("/Approved for implementation/i.test(body)", policy)
        self.assertIn("docs\\/specs\\/\\d{4}-\\d{2}-\\d{2}-[a-z0-9-]+\\.md", policy)


class CompactSpec(TestCase):
    def test_template_declares_compact_subset(self):
        note = read(TEMPLATE)
        self.assertIn("Spec gọn (mức M)", note)
        for number in LITE_SECTIONS:
            self.assertRegex(note, rf"(?m)^## {number}\. ")

    def test_compact_approved_spec_passes_compiler_contract(self):
        compiler = load_compiler()
        parsed = compiler.parse_spec_text(
            compact_spec("**Approved for implementation**", "AC-1 Given/When/Then."),
            "docs/specs/x.md",
        )
        self.assertTrue(parsed["approved"])
        self.assertEqual(parsed["requirement_ids"], ["AC-1"])
        self.assertTrue(parsed["metadata"].get("Approver / date") is not None)

    def test_compact_spec_without_ac_or_approval_is_not_ready(self):
        compiler = load_compiler()
        parsed = compiler.parse_spec_text(
            compact_spec("Draft", "Chưa có tiêu chí."), "docs/specs/x.md"
        )
        self.assertFalse(parsed["approved"])
        self.assertEqual(parsed["requirement_ids"], [])


if __name__ == "__main__":
    main()
