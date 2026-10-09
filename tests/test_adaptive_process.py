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
        self.assertIn("từ 2 PR trở lên phải giao subagent đủ năng lực", tiers)
        self.assertIn("Tối đa 5 subagent đang chạy trong toàn cây", tiers)
        self.assertIn("tuần tự", tiers)
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
        self.assertIsNotNone(parsed["metadata"].get("Approver / date"))

    def test_compact_spec_without_ac_or_approval_is_not_ready(self):
        compiler = load_compiler()
        parsed = compiler.parse_spec_text(
            compact_spec("Draft", "Chưa có tiêu chí."), "docs/specs/x.md"
        )
        self.assertFalse(parsed["approved"])
        self.assertEqual(parsed["requirement_ids"], [])


if __name__ == "__main__":
    main()


class DecisionOrder(TestCase):
    """`/auto-complete`: người quyết định là phiên chính theo thứ tự ưu tiên §3d; lệnh chỉ nối /auto → /completion."""

    ORDER = ("Đúng + bảo mật + không mất dữ liệu", "Ít hơn", "Kiểm được", "Nhanh và rẻ")

    def test_contract_ranks_priorities_in_fixed_order(self):
        rule = section(read(DELIVERY), "### 3d. Ủy quyền quyết định: chất lượng cao nhất, phương án tối giản nhất")
        positions = [rule.find(f"**{p}**") for p in self.ORDER]
        self.assertTrue(all(pos >= 0 for pos in positions), f"§3d thiếu bậc ưu tiên: {positions}")
        self.assertEqual(positions, sorted(positions), "thứ tự bậc ưu tiên trong §3d bị đảo")
        self.assertIn("không đánh đổi bậc trên lấy bậc dưới", rule)
        self.assertIn("working.md", rule)

    def test_auto_complete_chains_existing_playbooks_under_3d(self):
        cmd = read(".claude/commands/auto-complete.md")
        for ref in ("`/auto`", "`/completion`", "§3d", "§8", "--check-plan", "working.md", "Definition of Complete"):
            self.assertIn(ref, cmd, f"auto-complete.md phải trỏ {ref}")
        for never in ("deploy/production", "thanh toán", "dữ liệu thật", "quá 3 lần"):
            self.assertIn(never, cmd, f"auto-complete.md phải giữ mốc không tự quyết: {never}")

    def test_entry_docs_mention_auto_complete(self):
        for rel in ("CLAUDE.md", "AGENTS.md"):
            self.assertIn("/auto-complete", read(rel), f"{rel} phải nhắc /auto-complete")
