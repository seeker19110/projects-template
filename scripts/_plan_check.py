"""Kiểm tra hình thức kín của PLAN.md trước khi dispatch — THUẦN: không đọc file, không in, không import
subagent-dispatch. Tách khỏi subagent-dispatch.py để engine không vượt ngưỡng 400 dòng của radar
(arch-health-radar, 2026-10-09; cùng khuôn `_telemetry_report.py`). Luật kiểm: docs/framework/orchestration-3-tier.md
"cổng khoá brief"; mẫu: docs/framework/templates/PLAN.template.md."""

import re

PLAN_ROUTES = ("complex", "spec", "standard", "mechanical")
PLAN_FIELDS = ("Điểm chạm", "Đặc tả", "Phụ thuộc", "Tiêu chí chấp nhận")
_TASK_HEAD = re.compile(r"^###\s+(T\d+)\s+—\s+(.*?)\s*(?:`route:\s*([\w-]*)`)?\s*$", re.M)
_PR_LINE = re.compile(r"^-\s+\*\*PR-\d+\*\*.*?gồm việc\s+([^—\n]+)", re.M)
_PLACEHOLDER = re.compile(r"<[^<>\n]+>")


def _plan_tasks(content):
    """[{id, route, body}] theo thứ tự xuất hiện; body = phần dưới heading tới heading kế."""
    heads = list(_TASK_HEAD.finditer(content))
    tasks = []
    for i, m in enumerate(heads):
        end = heads[i + 1].start() if i + 1 < len(heads) else len(content)
        tasks.append({"id": m.group(1), "route": m.group(3), "body": content[m.end():end]})
    return tasks


def _plan_field(body, name):
    m = re.search(r"^-\s+" + re.escape(name) + r"\s*:\s*(.*)$", body, re.M)
    return m.group(1).strip() if m else None


def _check_task(task, ids):
    tid, route, body = task["id"], task["route"], task["body"]
    out = []
    if route not in PLAN_ROUTES:
        out.append(f"{tid}: route '{route or '(thiếu)'}' không thuộc {'/'.join(PLAN_ROUTES)}")
    for name in PLAN_FIELDS:
        if _plan_field(body, name) is None:
            out.append(f"{tid}: thiếu trường bắt buộc '{name}'")
    for ph in _PLACEHOLDER.findall(body):
        out.append(f"{tid}: còn placeholder '{ph}' — brief chưa kín")
    deps = _plan_field(body, "Phụ thuộc") or ""
    for d in re.findall(r"\bT\d+\b", deps):
        if d not in ids:
            out.append(f"{tid}: phụ thuộc '{d}' không có trong danh sách việc")
    if route == "mechanical":
        out.extend(_check_mechanical(tid, body))
    return out


def _check_mechanical(tid, body):
    out = []
    if "```" not in body:
        out.append(f"{tid}: route:mechanical phải có khuôn cuối cùng từng ký tự trong fence ```")
    touch = _plan_field(body, "Điểm chạm") or ""
    paths = re.findall(r"`([^`]+)`", touch)
    bad = [p for p in paths if re.search(r"[*?<>]", p)]
    if not paths or bad:
        out.append(f"{tid}: route:mechanical cần điểm chạm là đường dẫn tường minh trong backtick, không glob: {bad or touch!r}")
    return out


def _check_dependency_cycle(tasks):
    deps = {t["id"]: set(re.findall(r"\bT\d+\b", _plan_field(t["body"], "Phụ thuộc") or "")) for t in tasks}
    done = set()
    while True:
        ready = [t for t, d in deps.items() if t not in done and d <= done]
        if not ready:
            break
        done.update(ready)
    left = sorted(set(deps) - done)
    return [f"phụ thuộc tạo vòng giữa: {', '.join(left)}"] if left else []


def _check_pr_groups(content, ids):
    seen = {}
    for m in _PR_LINE.finditer(content):
        for t in re.findall(r"\bT\d+\b", m.group(1)):
            seen[t] = seen.get(t, 0) + 1
    out = [f"{t}: không thuộc đơn vị PR nào (mục 'Nhóm PR')" for t in ids if t not in seen]
    out += [f"{t}: nằm trong {n} đơn vị PR — mỗi việc đúng một PR" for t, n in seen.items() if n > 1]
    out += [f"'Nhóm PR' nhắc việc '{t}' không có trong danh sách" for t in seen if t not in ids]
    return out


def check_plan(content):
    """Danh sách lỗi (rỗng = PLAN hợp lệ) và số việc."""
    tasks = _plan_tasks(content)
    ids = [t["id"] for t in tasks]
    findings = [] if tasks else ["không tìm thấy việc nào dạng '### Tn — <tên>   `route: …`'"]
    for t in tasks:
        findings += _check_task(t, ids)
    findings += _check_dependency_cycle(tasks)
    findings += _check_pr_groups(content, ids)
    return findings, len(tasks)
