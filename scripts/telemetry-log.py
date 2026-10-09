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
_SCRIPTS_DIR = os.path.dirname(os.path.abspath(__file__))
if _SCRIPTS_DIR not in sys.path:
    sys.path.insert(0, _SCRIPTS_DIR)
from _telemetry_report import markdown_summary, widget_html  # noqa: E402
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


def generate_markdown_summary(logs):
    if not logs:
        return "### AI Telemetry Summary\n*Chưa có dữ liệu thực thi được ghi nhận.*"
    return markdown_summary(aggregate(logs))


def generate_html_widget(logs):
    widget_path = os.path.join(LOG_DIR, "widget-telemetry.html")
    os.makedirs(LOG_DIR, exist_ok=True)
    with open(widget_path, "w", encoding="utf-8") as f:
        f.write(widget_html(aggregate(logs)))
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
