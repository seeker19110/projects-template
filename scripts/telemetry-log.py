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
import errno
import hashlib
import tempfile
from contextlib import contextmanager
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
    try:
        with open(LOG_FILE, "r", encoding="utf-8") as f:
            logs = json.load(f)
    except FileNotFoundError:
        return []
    if not isinstance(logs, list) or any(not isinstance(entry, dict) for entry in logs):
        raise ValueError(f"{LOG_FILE} phải là JSON array chứa object; giữ nguyên file để phục hồi")
    return logs


@contextmanager
def log_lock():
    """One lock file for the whole read/append/replace transaction on Windows and POSIX."""
    os.makedirs(LOG_DIR, exist_ok=True)
    with open(f"{LOG_FILE}.lock", "a+b") as lock:
        lock.seek(0, os.SEEK_END)
        if lock.tell() == 0:
            lock.write(b"\0")
            lock.flush()
        deadline = time.monotonic() + 10
        while True:
            try:
                lock.seek(0)
                if os.name == "nt":
                    import msvcrt
                    msvcrt.locking(lock.fileno(), msvcrt.LK_NBLCK, 1)
                else:
                    import fcntl
                    fcntl.flock(lock.fileno(), fcntl.LOCK_EX | fcntl.LOCK_NB)
                break
            except OSError as exc:
                if exc.errno not in (errno.EACCES, errno.EAGAIN) or time.monotonic() >= deadline:
                    raise
                time.sleep(0.05)
        try:
            yield
        finally:
            lock.seek(0)
            if os.name == "nt":
                msvcrt.locking(lock.fileno(), msvcrt.LK_UNLCK, 1)
            else:
                fcntl.flock(lock.fileno(), fcntl.LOCK_UN)

def save_logs(logs):
    os.makedirs(LOG_DIR, exist_ok=True)
    temporary = None
    try:
        with tempfile.NamedTemporaryFile(mode="w", encoding="utf-8", dir=LOG_DIR,
                                         prefix=".telemetry-", suffix=".json", delete=False) as f:
            temporary = f.name
            json.dump(logs, f, indent=2, ensure_ascii=False)
            f.flush()
            os.fsync(f.fileno())
        os.replace(temporary, LOG_FILE)
    finally:
        if temporary and os.path.exists(temporary):
            os.unlink(temporary)

RECORD_SCHEMA = "telemetry-record/2"
OUTCOMES = ("attempt", "accepted", "rejected", "abandoned")


def usage_fields(model, input_tokens, output_tokens):
    """Token thiếu là KHÔNG BIẾT (None), không phải 0 (AC-7). 0 tường minh vẫn là số đo thật.
    Bảng giá luôn được nạp: hỏng/thiếu 'default' vẫn dừng hẳn, kể cả khi usage unknown."""
    rates, _ = load_rates()
    known = [t for t in (input_tokens, output_tokens) if t is not None]
    if len(known) < 2:
        return {"input_tokens": input_tokens, "output_tokens": output_tokens,
                "usage_status": "partial" if known else "unknown", "est_cost_usd": None}
    rate = resolve_rate(model, rates)
    cost = (input_tokens / 1_000_000) * rate["input"] + (output_tokens / 1_000_000) * rate["output"]
    return {"input_tokens": input_tokens, "output_tokens": output_tokens,
            "usage_status": "measured", "est_cost_usd": round(cost, 4)}


def load_evidence(path):
    """Nghiệm thu cần evidence PASS của `dev-task.sh gate` (gate-evidence/1). Chỉ kiểm schema/status;
    evidence cũ so với cây hiện tại do `dev-task.sh evidence-check` bắt, không lặp ở đây."""
    if not path:
        raise ValueError("--outcome accepted cần --evidence <file gate-evidence/1>")
    with open(path, "r", encoding="utf-8") as f:
        data = json.load(f)
    if not isinstance(data, dict) or data.get("schema") != "gate-evidence/1" or data.get("status") != "PASS":
        raise ValueError(f"evidence không phải gate-evidence/1 PASS: {path}")
    digest = hashlib.sha256(json.dumps(data, sort_keys=True).encode("utf-8")).hexdigest()
    return {"schema": data["schema"], "status": data["status"], "head": data.get("head"),
            "config_sha": data.get("config_sha"), "sha256": digest}


def record_entry(harness, provider, model, agent, task, duration_sec, diff_loc, test_status,
                 input_tokens=None, output_tokens=None, work_id=None, outcome="attempt", evidence_path=None):
    if outcome not in OUTCOMES:
        raise ValueError(f"outcome không hợp lệ: {outcome}")
    evidence = load_evidence(evidence_path) if outcome == "accepted" else None
    entry = {
        "schema": RECORD_SCHEMA,
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "harness": harness,
        "provider": provider,
        "model": model,
        "agent": agent,
        "task": task,
        "work_id": work_id,
        "outcome": outcome,
        "duration_sec": round(duration_sec, 2),
        "diff_loc": diff_loc,
        "test_status": test_status,
        **usage_fields(model, input_tokens, output_tokens),
        "evidence": evidence,
    }

    with log_lock():
        logs = load_logs()
        entry["id"] = f"tel-{int(time.time())}-{len(logs)+1}"
        logs.append(entry)
        save_logs(logs)
    return entry


def normalize_record(entry):
    """Đọc mọi phiên bản bản ghi, KHÔNG ghi lại file. v1 (không có `schema`): mọi bản ghi là một lần
    thử chưa nghiệm thu; token 0/0 của v1 là unknown vì v1 không phân biệt được "thiếu" với "0"."""
    rec = {"id": "?", "harness": "?", "agent": "?", "task": "?", "duration_sec": 0, "diff_loc": 0,
           "test_status": "?", "work_id": None, "outcome": "attempt", "evidence": None, **entry}
    if entry.get("schema") != RECORD_SCHEMA:
        tokens = (entry.get("input_tokens"), entry.get("output_tokens"))
        measured = all(isinstance(t, int) for t in tokens) and any(tokens)
        rec.update(schema="v1", outcome="attempt", evidence=None,
                   usage_status="measured" if measured else "unknown",
                   est_cost_usd=entry.get("est_cost_usd") if measured else None)
    rec["work_key"] = rec["work_id"] or str(rec["task"])
    return rec


def _known_cost(recs):
    return sum(r["est_cost_usd"] for r in recs if r["est_cost_usd"] is not None)


def _unknown(recs):
    return sum(1 for r in recs if r["est_cost_usd"] is None)


def _acceptance(recs):
    """Công việc được nghiệm thu = có bản ghi accepted kèm evidence; chi phí gồm mọi lần thử của nó."""
    accepted = {r["work_key"] for r in recs if r["outcome"] == "accepted" and r["evidence"]}
    in_accepted = [r for r in recs if r["work_key"] in accepted]
    per_work = _known_cost(in_accepted) / len(accepted) if accepted else None
    return {"accepted": len(accepted), "cost_per_accepted": per_work,
            "cost_per_accepted_partial": _unknown(in_accepted) > 0}


def aggregate(logs):
    """Lần thử ≠ công việc được nghiệm thu. Chi phí của một công việc gồm MỌI lần thử của nó,
    kể cả lần thất bại; usage unknown được đếm riêng và biến tổng thành cận dưới (≥)."""
    recs = [normalize_record(e) for e in logs]
    status = [str(r["test_status"]).upper() for r in recs]
    return {
        "records": recs,
        "attempts": len(recs),
        "passed": status.count("PASSED"),
        "failed": status.count("FAILED"),
        "works": len({r["work_key"] for r in recs}),
        "known_cost": _known_cost(recs),
        "unknown": _unknown(recs),
        "v1": sum(1 for r in recs if r["schema"] == "v1"),
        "duration": sum(r["duration_sec"] or 0 for r in recs),
        **_acceptance(recs),
    }


def fmt_cost(value, partial=False):
    if value is None:
        return "unknown"
    return f"{'≥ ' if partial else ''}${value:.4f}"


def generate_markdown_summary(logs):
    if not logs:
        return "### AI Telemetry Summary\n*Chưa có dữ liệu thực thi được ghi nhận.*"
    st = aggregate(logs)
    lines = [
        "## 📊 AI Execution & Observability Summary",
        f"- **Lần thử (attempts):** `{st['attempts']}` — PASSED tự khai `{st['passed']}`, FAILED `{st['failed']}`, khác `{st['attempts'] - st['passed'] - st['failed']}`",
        f"- **Công việc:** `{st['works']}` — được nghiệm thu (có evidence): `{st['accepted']}`; chưa/không: `{st['works'] - st['accepted']}`",
        f"- **Tổng thời gian chạy:** `{st['duration']:.1f}s`",
        f"- **Chi phí đã biết:** `{fmt_cost(st['known_cost'], st['unknown'] > 0)} USD` trên `{st['attempts']}` lần thử (gồm cả lần thất bại/bị từ chối); usage unknown: {st['unknown']}",
        f"- **Chi phí / công việc nghiệm thu:** `{fmt_cost(st['cost_per_accepted'], st['cost_per_accepted_partial'])}`",
    ]
    if st["v1"]:
        lines.append(f"- *{st['v1']} bản ghi v1: usage tự khai, không kiểm được; 0/0 coi là unknown, không tính là nghiệm thu.*")
    lines += [
        "",
        "### Nhật ký tác vụ gần nhất",
        "| ID | Harness | Agent | Task | Outcome | Thời gian | Status | Est. Cost |",
        "| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |",
    ]
    for r in st["records"][-10:]:
        task_cell = str(r["task"])[:30].replace("|", "\\|")
        lines.append(f"| `{r['id']}` | `{r['harness']}` | `{r['agent']}` | {task_cell} | `{r['outcome']}` | "
                     f"{r['duration_sec']}s | `{r['test_status']}` | {fmt_cost(r['est_cost_usd'])} |")
    return "\n".join(lines)

def generate_html_widget(logs):
    st = aggregate(logs)
    cost_card = fmt_cost(st["known_cost"], st["unknown"] > 0) + (f" (+{st['unknown']} unknown)" if st["unknown"] else "")

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
    <div class="card"><div class="title">LẦN THỬ</div><div class="value">{st['attempts']}</div></div>
    <div class="card"><div class="title">NGHIỆM THU (EVIDENCE)</div><div class="value">{st['accepted']}/{st['works']}</div></div>
    <div class="card"><div class="title">THỜI GIAN CHẠY</div><div class="value">{st['duration']:.1f}s</div></div>
    <div class="card"><div class="title">EST. COST</div><div class="value">{html.escape(cost_card)}</div></div>
  </div>
  <table>
    <thead>
      <tr><th>Harness</th><th>Agent</th><th>Task</th><th>Outcome</th><th>Duration</th><th>Status</th><th>Est Cost</th></tr>
    </thead>
    <tbody>
"""
    e = lambda v: html.escape(str(v), quote=True)
    for r in st["records"][-8:]:
        badge_cls = "badge-passed" if str(r['test_status']).upper() == "PASSED" else "badge-failed"
        widget_html += (f"      <tr><td>{e(r['harness'])}</td><td>{e(r['agent'])}</td><td>{e(str(r['task'])[:35])}</td>"
                        f"<td>{e(r['outcome'])}</td><td>{e(r['duration_sec'])}s</td><td class=\"{badge_cls}\">{e(r['test_status'])}</td>"
                        f"<td>{e(fmt_cost(r['est_cost_usd']))}</td></tr>\n")

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
    # Mặc định None = KHÔNG BIẾT, không phải 0 và không phải số "trông hợp lý" (CLAUDE.md §4;
    # audit 2026-09-23 C4 bịa 1000/500; LD-07/AC-7: 0 làm tổng chi phí trông như đầy đủ).
    parser.add_argument("--input-tokens", type=int, default=None)
    parser.add_argument("--output-tokens", type=int, default=None)
    parser.add_argument("--work-id", type=str, default=None, help="Gom các lần thử của cùng một công việc")
    parser.add_argument("--outcome", choices=OUTCOMES, default="attempt",
                        help="accepted cần --evidence (gate-evidence/1 PASS)")
    parser.add_argument("--evidence", type=str, default=None, help="File evidence của dev-task.sh gate")

    args = parser.parse_args()

    if args.record:
        if args.input_tokens is None or args.output_tokens is None:
            print("CẢNH BÁO: --record không có đủ số token thật → usage/est_cost_usd = unknown "
                  "(không phải 0); hook nên đọc message.usage từ transcript.", file=sys.stderr)
        if args.outcome == "accepted":
            try:
                load_evidence(args.evidence)
            except (OSError, ValueError) as exc:
                print(f"LỖI: không ghi bản ghi nghiệm thu: {exc}", file=sys.stderr)
                sys.exit(2)
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
            output_tokens=args.output_tokens,
            work_id=args.work_id,
            outcome=args.outcome,
            evidence_path=args.evidence,
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
    try:
        main()
    except (OSError, ValueError, json.JSONDecodeError) as exc:
        print(f"LỖI: telemetry không được ghi/đọc; dữ liệu cũ được giữ nguyên: {exc}", file=sys.stderr)
        sys.exit(1)
