#!/usr/bin/env python3
"""
telemetry-log.py — Universal AI Telemetry & Observability Engine
Ghi nhận và báo cáo hiệu năng / chi phí / chất lượng thực thi của AI Coding Agents.
"""

import sys
import os
import argparse
import json
import time
import html
from datetime import datetime, timezone

# Console Windows mặc định dùng cp1252 → in tiếng Việt/emoji ra stdout sẽ chết với
# UnicodeEncodeError. Ép UTF-8 để engine chạy được trên mọi nền (xem TRAPS.md).
for _stream in (sys.stdout, sys.stderr):
    if hasattr(_stream, "reconfigure"):
        _stream.reconfigure(encoding="utf-8")

ROOT_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
# Thư mục log TRUNG LẬP harness: khung này là khung cho Claude Code, không gắn với một
# runner cụ thể. (Trước đây là ".hermes" — tên một harness khác lọt vào mặc định.)
LOG_DIR = os.path.join(ROOT_DIR, ".ai-telemetry")
LOG_FILE = os.path.join(LOG_DIR, "telemetry.json")

# Giá model KHÔNG hard-code ở đây: xem scripts/model-rates.json (có _verified_on + _source).
RATES_FILE = os.path.join(ROOT_DIR, "scripts", "model-rates.json")


def load_rates():
    """Đọc bảng giá từ scripts/model-rates.json. Thiếu file/hỏng JSON -> dừng hẳn thay vì
    âm thầm ước tính bằng số bịa: báo cáo chi phí sai còn tệ hơn không có báo cáo."""
    try:
        with open(RATES_FILE, "r", encoding="utf-8") as f:
            data = json.load(f)
    except (OSError, json.JSONDecodeError) as exc:
        print(f"LỖI: không đọc được bảng giá {RATES_FILE}: {exc}", file=sys.stderr)
        sys.exit(1)
    rates = data.get("rates")
    if not isinstance(rates, dict) or "default" not in rates:
        print(f"LỖI: {RATES_FILE} thiếu khoá 'rates' hoặc 'rates.default'.", file=sys.stderr)
        sys.exit(1)
    return rates, data.get("_verified_on", "?")


def resolve_rate(model, rates):
    """Khớp theo chuỗi con, ưu tiên khoá DÀI NHẤT (claude-haiku-4-5 -> 'haiku-4-5', không phải
    'haiku'). Không khớp -> 'default' kèm cảnh báo ra stderr, để con số lạ không đi qua im lặng."""
    key = (model or "").lower()
    best = None
    for name in rates:
        if name == "default":
            continue
        if name in key and (best is None or len(name) > len(best)):
            best = name
    if best is None:
        print(f"CẢNH BÁO: model '{model}' không có trong bảng giá — dùng 'default', "
              f"con số chi phí chỉ là ước lượng thô.", file=sys.stderr)
        return rates["default"]
    return rates[best]


def load_logs():
    if not os.path.exists(LOG_FILE):
        return []
    try:
        with open(LOG_FILE, "r", encoding="utf-8") as f:
            return json.load(f)
    except Exception:
        return []

def save_logs(logs):
    os.makedirs(LOG_DIR, exist_ok=True)
    with open(LOG_FILE, "w", encoding="utf-8") as f:
        json.dump(logs, f, indent=2, ensure_ascii=False)

def record_entry(harness, provider, model, agent, task, duration_sec, diff_loc, test_status, input_tokens=0, output_tokens=0):
    logs = load_logs()
    
    rates, _ = load_rates()
    rate = resolve_rate(model, rates)
    est_cost = ((input_tokens / 1_000_000) * rate["input"]) + ((output_tokens / 1_000_000) * rate["output"])
    
    entry = {
        "id": f"tel-{int(time.time())}-{len(logs)+1}",
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "harness": harness,
        "provider": provider,
        "model": model,
        "agent": agent,
        "task": task,
        "duration_sec": round(duration_sec, 2),
        "diff_loc": diff_loc,
        "test_status": test_status,
        "input_tokens": input_tokens,
        "output_tokens": output_tokens,
        "est_cost_usd": round(est_cost, 4)
    }
    
    logs.append(entry)
    save_logs(logs)
    return entry

def generate_markdown_summary(logs):
    if not logs:
        return "### AI Telemetry Summary\n*Chưa có dữ liệu thực thi được ghi nhận.*"

    total_tasks = len(logs)
    passed_tasks = sum(1 for l in logs if l["test_status"].upper() == "PASSED")
    total_cost = sum(l.get("est_cost_usd", 0) for l in logs)
    total_duration = sum(l.get("duration_sec", 0) for l in logs)
    total_loc = sum(l.get("diff_loc", 0) for l in logs)

    lines = [
        "## 📊 AI Execution & Observability Summary",
        f"- **Tổng số tác vụ AI:** `{total_tasks}`",
        f"- **Tỷ lệ thành công (Quality Gate):** `{passed_tasks}/{total_tasks}` ({(passed_tasks/total_tasks)*100:.1f}%)",
        f"- **Tổng thời gian chạy:** `{total_duration:.1f}s`",
        f"- **Tổng mã nguồn thay đổi (LOC):** `{total_loc} dòng`",
        f"- **Ước tính Chi phí API:** `${total_cost:.4f} USD`",
        "",
        "### Nhật ký tác vụ gần nhất",
        "| ID | Harness | Agent | Task | Thời gian | Status | LOC | Est. Cost |",
        "| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |"
    ]

    for l in logs[-10:]:
        task_cell = str(l['task'])[:30].replace("|", "\\|")
        lines.append(f"| `{l['id']}` | `{l['harness']}` | `{l['agent']}` | {task_cell} | {l['duration_sec']}s | `{l['test_status']}` | {l['diff_loc']} | ${l['est_cost_usd']:.4f} |")

    return "\n".join(lines)

def generate_html_widget(logs):
    total_tasks = len(logs)
    passed_tasks = sum(1 for l in logs if l["test_status"].upper() == "PASSED")
    total_cost = sum(l.get("est_cost_usd", 0) for l in logs)
    total_duration = sum(l.get("duration_sec", 0) for l in logs)
    pass_rate = round((passed_tasks/total_tasks)*100, 1) if total_tasks > 0 else 0

    widget_html = f"""<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <style>
    body {{
      font-family: system-ui, -apple-system, sans-serif;
      margin: 0;
      padding: 16px;
      color: var(--foreground, #1e293b);
      background: transparent;
    }}
    .grid {{
      display: grid;
      grid-template-columns: repeat(4, 1fr);
      gap: 12px;
      margin-bottom: 16px;
    }}
    .card {{
      background: var(--card, #f8fafc);
      border: 1px solid var(--border, #e2e8f0);
      border-radius: 8px;
      padding: 12px;
    }}
    .card .title {{
      font-size: 12px;
      color: var(--muted-foreground, #64748b);
      margin-bottom: 4px;
    }}
    .card .value {{
      font-size: 20px;
      font-weight: 700;
    }}
    table {{
      width: 100%;
      border-collapse: collapse;
      font-size: 13px;
    }}
    th, td {{
      padding: 8px 12px;
      text-align: left;
      border-bottom: 1px solid var(--border, #e2e8f0);
    }}
    th {{
      color: var(--muted-foreground, #64748b);
      font-weight: 600;
    }}
    .badge-passed {{ color: #16a34a; font-weight: 600; }}
    .badge-failed {{ color: #dc2626; font-weight: 600; }}
  </style>
</head>
<body>
  <div class="grid">
    <div class="card"><div class="title">TỔNG TÁC VỤ</div><div class="value">{total_tasks}</div></div>
    <div class="card"><div class="title">TỶ LỆ ĐẠT (PASS)</div><div class="value">{pass_rate}%</div></div>
    <div class="card"><div class="title">THỜI GIAN CHẠY</div><div class="value">{total_duration:.1f}s</div></div>
    <div class="card"><div class="title">EST. COST</div><div class="value">${total_cost:.4f}</div></div>
  </div>
  <table>
    <thead>
      <tr><th>Harness</th><th>Agent</th><th>Task</th><th>Duration</th><th>Status</th><th>Est Cost</th></tr>
    </thead>
    <tbody>
"""
    for l in logs[-8:]:
        badge_cls = "badge-passed" if l['test_status'].upper() == "PASSED" else "badge-failed"
        e = lambda v: html.escape(str(v), quote=True)
        widget_html += f"      <tr><td>{e(l['harness'])}</td><td>{e(l['agent'])}</td><td>{e(l['task'][:35])}</td><td>{e(l['duration_sec'])}s</td><td class=\"{badge_cls}\">{e(l['test_status'])}</td><td>${l['est_cost_usd']:.4f}</td></tr>\n"

    widget_html += """    </tbody>
  </table>
</body>
</html>"""
    
    widget_path = os.path.join(LOG_DIR, "widget-telemetry.html")
    os.makedirs(LOG_DIR, exist_ok=True)
    with open(widget_path, "w", encoding="utf-8") as f:
        f.write(widget_html)
    return widget_path

def main():
    parser = argparse.ArgumentParser(description="Universal AI Telemetry Logger")
    parser.add_argument("--record", action="store_true", help="Record a new telemetry entry")
    parser.add_argument("--summary", action="store_true", help="Generate Markdown summary")
    parser.add_argument("--widget", action="store_true", help="Generate Hermes HTML Widget")
    parser.add_argument("--harness", type=str, default="claude")
    parser.add_argument("--provider", type=str, default="anthropic")
    parser.add_argument("--model", type=str, default="sonnet")
    parser.add_argument("--agent", type=str, default="main")
    parser.add_argument("--task", type=str, default="Standard Task Execution")
    parser.add_argument("--duration", type=float, default=1.0)
    parser.add_argument("--diff-loc", type=int, default=0)
    parser.add_argument("--test-status", type=str, default="PASSED")
    # Mặc định 0, KHÔNG phải một con số "trông hợp lý": không được cấp token thật thì chi phí
    # phải là 0 kèm cảnh báo, không bịa (CLAUDE.md §4; audit 2026-09-23 C4 — bản cũ mặc định
    # 1000/500 khiến mọi entry từ hook Stop mang chi phí giả).
    parser.add_argument("--input-tokens", type=int, default=0)
    parser.add_argument("--output-tokens", type=int, default=0)

    args = parser.parse_args()

    if args.record:
        if args.input_tokens == 0 and args.output_tokens == 0:
            print("CẢNH BÁO: --record không có số token thật (--input-tokens/--output-tokens = 0) "
                  "→ est_cost_usd = 0; hook nên đọc message.usage từ transcript.", file=sys.stderr)
        entry = record_entry(
            harness=args.harness,
            provider=args.provider,
            model=args.model,
            agent=args.agent,
            task=args.task,
            duration_sec=args.duration,
            diff_loc=args.diff_loc,
            test_status=args.test_status,
            input_tokens=args.input_tokens,
            output_tokens=args.output_tokens
        )
        print(f"Recorded telemetry entry: {entry['id']}")
        sys.exit(0)

    if args.widget:
        logs = load_logs()
        wpath = generate_html_widget(logs)
        print(f"HTML Widget generated at: {wpath}")
        print(f"::preview{{file=\"{wpath}\"}}")
        sys.exit(0)

    # Default: output summary
    logs = load_logs()
    print(generate_markdown_summary(logs))

if __name__ == "__main__":
    main()
