#!/usr/bin/env python3
"""
subagent-dispatch.py — Universal Subagent Dispatcher Engine
Giao thức điều phối Subagent đa-harness.

Harness ĐƯỢC HỖ TRỢ THẬT (mỗi cái có một nhánh xử lý riêng): claude, hermes, codex, generic.
KHÔNG kê tên harness chưa có nhánh xử lý — bản đầu ghi cả Cursor/Windsurf/Gemini trong
docstring dù `--harness` chỉ nhận 4 giá trị, khiến người đọc tưởng đã hỗ trợ (A-03).
Harness chưa có nhánh riêng dùng `generic`: trả về system prompt thô để tự dán.

CHỈ CHUẨN BỊ (prepare-only): đọc vai trong `.claude/agents/*.md` và in prompt/lời gọi cho từng
harness theo quy ước 3-Tier (docs/framework/orchestration-3-tier.md). KHÔNG gọi harness, KHÔNG
chạy agent, KHÔNG cấp hay cưỡng chế quyền: `tools`/`model`/`effort` trong payload chỉ là gợi ý
từ frontmatter — harness/người gọi mới là bên thực thi và giới hạn quyền (LD-05, AC-5).
Context (`--context-file`) thiếu, rỗng, không phải UTF-8 hoặc vượt `--max-context-bytes` → lỗi
thoát 2; không bao giờ bỏ qua hay cắt im lặng.
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
AGENTS_DIR = os.path.join(ROOT_DIR, ".claude", "agents")
CAPABILITY_MAP_FILE = os.path.join(ROOT_DIR, "scripts", "model-capability-tiers.json")
PREPARE_ONLY_NOTICE = (
    "subagent-dispatch: CHỈ CHUẨN BỊ (prepare-only) — không gọi harness, không chạy agent, "
    "không cấp/cưỡng chế quyền; tools/model/effort chỉ là gợi ý từ frontmatter."
)
# Trần theo BYTE (không phải token): chặn nối nhầm file khổng lồ, không phải giới hạn của model.
DEFAULT_MAX_CONTEXT_BYTES = 262144

# Nhãn route: -> cấp năng lực trong CAPABILITY_MAP_FILE (đa nhà cung cấp, xem
# docs/framework/orchestration-3-tier.md). "planning" không gắn với agent nào (là Tầng 1).
AGENT_TIER = {
    "complex-implementer": "complex",
    "spec-executor": "spec",
    "standard-worker": "standard",
    "mechanical-worker": "mechanical",
}


def load_capability_tiers():
    if not os.path.exists(CAPABILITY_MAP_FILE):
        return {}
    with open(CAPABILITY_MAP_FILE, "r", encoding="utf-8", errors="ignore") as f:
        return json.load(f).get("tiers", {})


def parse_agent_md(file_path):
    if not os.path.exists(file_path):
        return None
    with open(file_path, "r", encoding="utf-8", errors="ignore") as f:
        content = f.read()

    frontmatter = {}
    body = content

    if content.startswith("---"):
        parts = content.split("---", 2)
        if len(parts) >= 3:
            yaml_text = parts[1]
            body = parts[2].strip()
            for line in yaml_text.splitlines():
                line = line.strip()
                if ":" in line and not line.startswith("#"):
                    key, val = line.split(":", 1)
                    key = key.strip()
                    val = val.strip().strip(">-\n ").strip()
                    frontmatter[key] = val

    name = frontmatter.get("name", os.path.splitext(os.path.basename(file_path))[0])
    return {
        "name": name,
        "description": frontmatter.get("description", ""),
        "tools": frontmatter.get("tools", ""),
        "model": frontmatter.get("model", "sonnet"),
        "effort": frontmatter.get("effort", ""),
        "path": file_path,
        "system_prompt": body,
    }


def list_agents():
    agents = []
    if not os.path.exists(AGENTS_DIR):
        return agents
    for f in sorted(os.listdir(AGENTS_DIR)):
        if f.endswith(".md"):
            info = parse_agent_md(os.path.join(AGENTS_DIR, f))
            if info:
                agents.append(info)
    return agents


def build_dispatch_payload(agent_info, task_text, harness_type):
    name = agent_info["name"]
    model = agent_info["model"]
    sys_prompt = agent_info["system_prompt"]

    effort_note = f"(effort: {agent_info['effort']}) " if agent_info.get("effort") else ""
    full_prompt = (
        f"=== SUBAGENT ROLE: {name.upper()} ({model}) ===\n"
        f"{effort_note}{sys_prompt}\n\n"
        f"=== TASK CONTEXT ===\n"
        f"{task_text}\n"
    )

    if harness_type == "hermes":
        return {
            "harness": "hermes",
            "mode": "prepare-only",
            "executed": False,
            "delegate_task_call": {
                "tasks": [
                    {"goal": f"[{name}] {task_text[:200]}...", "context": full_prompt}
                ]
            },
            "agent": agent_info,
        }
    elif harness_type == "claude":
        # Claude Code KHÔNG có lệnh `/subagent` (audit 2026-09-13, A-03: bản cũ sinh ra chuỗi
        # đó, dán vào Claude Code sẽ không chạy). Cơ chế THẬT là tool Task/Agent với
        # subagent_type = tên file trong .claude/agents/. Trả về đúng hình dạng lời gọi đó.
        return {
            "harness": "claude",
            "mode": "prepare-only",
            "executed": False,
            "tool_call": {
                "tool": "Task",
                "subagent_type": name,
                "description": task_text[:60],
                "prompt": full_prompt,
            },
            "agent": agent_info,
        }
    elif harness_type == "codex":
        return {"harness": "codex", "mode": "prepare-only", "executed": False,
                "prompt": full_prompt, "agent": agent_info}
    else:
        return {"harness": "generic", "mode": "prepare-only", "executed": False,
                "prompt": full_prompt, "agent": agent_info}


def _build_parser():
    parser = argparse.ArgumentParser(description="Universal Subagent Dispatcher Engine")
    parser.add_argument(
        "--list", action="store_true", help="List all available subagents"
    )
    parser.add_argument(
        "--agent",
        type=str,
        help="Target agent name (e.g. security-reviewer, complex-implementer)",
    )
    parser.add_argument(
        "--task", type=str, default="", help="Task text/description for the agent"
    )
    parser.add_argument(
        "--context-file", type=str, help="File path containing context/diff/spec"
    )
    parser.add_argument(
        "--harness",
        type=str,
        choices=["hermes", "claude", "codex", "generic"],
        default="generic",
        help="Target AI Harness",
    )
    parser.add_argument(
        "--max-context-bytes",
        type=int,
        default=DEFAULT_MAX_CONTEXT_BYTES,
        help="Trần byte của --context-file; vượt → lỗi thoát 2, không tự cắt",
    )
    parser.add_argument("--json", action="store_true", help="Output result as JSON")
    parser.add_argument(
        "--tier",
        type=str,
        choices=["planning", "complex", "spec", "standard", "mechanical"],
        help="In ứng viên đa nhà cung cấp cho một cấp năng lực (scripts/model-capability-tiers.json), không dispatch agent nào",
    )
    return parser


def _print_tier_candidates(tier, as_json):
    tiers = load_capability_tiers()
    info = tiers.get(tier)
    if not info:
        print(
            f"Error: tier '{tier}' không có trong {CAPABILITY_MAP_FILE}",
            file=sys.stderr,
        )
        sys.exit(1)
    if as_json:
        print(json.dumps({"tier": tier, **info}, indent=2, ensure_ascii=False))
        return
    print(f"Cấp năng lực '{tier}': {info.get('desc', '')}")
    for c in info.get("candidates", []):
        flag = " (CẦN xác minh trước khi dùng)" if c.get("verify_before_use") else ""
        print(
            f"  - [{c['provider']}] harness={c['harness']} :: {c['model_hint']}{flag}"
        )


def _print_agent_list(as_json):
    agents = list_agents()
    if as_json:
        print(
            json.dumps(
                [
                    {
                        "name": a["name"],
                        "description": a["description"],
                        "model": a["model"],
                    }
                    for a in agents
                ],
                indent=2,
                ensure_ascii=False,
            )
        )
        return
    print(f"Available Subagents ({len(agents)}):")
    for a in agents:
        print(f"  - {a['name']:<20} [{a['model']:<8}] : {a['description'][:80]}...")


def _fail_context(message):
    print(f"Error: context-file: {message}", file=sys.stderr)
    sys.exit(2)


def _read_context_file(path, limit):
    if not os.path.isfile(path):
        _fail_context(f"không tồn tại hoặc không phải file: {path}")
    size = os.path.getsize(path)
    if size == 0:
        _fail_context(f"rỗng: {path}")
    if size > limit:
        _fail_context(f"{size} byte vượt giới hạn {limit} (--max-context-bytes); không tự cắt: {path}")
    try:
        with open(path, "r", encoding="utf-8") as f:
            return f.read()
    except UnicodeDecodeError:
        _fail_context(f"không phải UTF-8 hợp lệ: {path}")


def _load_task_text(task, context_file, limit=DEFAULT_MAX_CONTEXT_BYTES):
    if context_file is None:
        return task
    return task + "\n\n" + _read_context_file(context_file, limit)


def _print_payload(payload, harness, as_json):
    if as_json:
        print(json.dumps(payload, indent=2, ensure_ascii=False))
    elif harness == "hermes":
        print(json.dumps(payload["delegate_task_call"], indent=2, ensure_ascii=False))
    elif harness == "claude":
        # In chỉ dẫn NGƯỜI/AI đọc được mô tả đúng cơ chế thật của Claude Code
        # (tool Task với subagent_type), thay vì một slash command không tồn tại.
        tc = payload["tool_call"]
        print(
            f'Claude Code — gọi tool {tc["tool"]} với subagent_type="{tc["subagent_type"]}":'
        )
        print()
        print(tc["prompt"])
    else:
        print(payload["prompt"])


def main():
    args = _build_parser().parse_args()

    if args.tier:
        _print_tier_candidates(args.tier, args.json)
        sys.exit(0)

    if args.list:
        _print_agent_list(args.json)
        sys.exit(0)

    if not args.agent:
        print(
            "Error: --agent is required when not listing. Use --list to see available agents.",
            file=sys.stderr,
        )
        sys.exit(1)

    agent_file = os.path.join(AGENTS_DIR, f"{args.agent}.md")
    agent_info = parse_agent_md(agent_file)
    if not agent_info:
        print(f"Error: Agent '{args.agent}' not found at {agent_file}", file=sys.stderr)
        sys.exit(1)

    task_text = _load_task_text(args.task, args.context_file, args.max_context_bytes)
    payload = build_dispatch_payload(agent_info, task_text, args.harness)
    print(PREPARE_ONLY_NOTICE, file=sys.stderr)
    _print_payload(payload, args.harness, args.json)


if __name__ == "__main__":
    main()
