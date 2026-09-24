#!/usr/bin/env python3
"""
subagent-dispatch.py — Universal Subagent Dispatcher Engine
Giao thức điều phối Subagent đa-harness.

Harness ĐƯỢC HỖ TRỢ THẬT (mỗi cái có một nhánh xử lý riêng): claude, hermes, codex, generic.
KHÔNG kê tên harness chưa có nhánh xử lý — bản đầu ghi cả Cursor/Windsurf/Gemini trong
docstring dù `--harness` chỉ nhận 4 giá trị, khiến người đọc tưởng đã hỗ trợ (A-03).
Harness chưa có nhánh riêng dùng `generic`: trả về system prompt thô để tự dán.

Cho phép MỌI AI Coding Harness nạp và điều phối các subagent trong `.claude/agents/*.md`
theo đúng quy ước 3-Tier Architecture (docs/framework/orchestration-3-tier.md).
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
            "tool_call": {
                "tool": "Task",
                "subagent_type": name,
                "description": task_text[:60],
                "prompt": full_prompt,
            },
            "agent": agent_info,
        }
    elif harness_type == "codex":
        return {"harness": "codex", "prompt": full_prompt, "agent": agent_info}
    else:
        return {"harness": "generic", "prompt": full_prompt, "agent": agent_info}


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


def _load_task_text(task, context_file):
    if context_file and os.path.exists(context_file):
        with open(context_file, "r", encoding="utf-8", errors="ignore") as f:
            return task + "\n\n" + f.read()
    return task


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

    payload = build_dispatch_payload(
        agent_info, _load_task_text(args.task, args.context_file), args.harness
    )
    _print_payload(payload, args.harness, args.json)


if __name__ == "__main__":
    main()
