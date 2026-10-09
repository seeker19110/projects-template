"""Dựng báo cáo telemetry (Markdown + HTML) từ số liệu đã aggregate — THUẦN: không đọc/ghi file,
không import telemetry-log. Tách khỏi telemetry-log.py để engine không vượt ngưỡng 400 dòng
của radar (arch-health-radar, 2026-10-09)."""

import html


def fmt_cost(value, partial=False):
    if value is None:
        return "unknown"
    return f"{'≥ ' if partial else ''}${value:.4f}"


def markdown_summary(st):
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


def widget_html(st):
    cost_card = fmt_cost(st["known_cost"], st["unknown"] > 0) + (f" (+{st['unknown']} unknown)" if st["unknown"] else "")

    out = f"""<!DOCTYPE html>
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
        out += (f"      <tr><td>{e(r['harness'])}</td><td>{e(r['agent'])}</td><td>{e(str(r['task'])[:35])}</td>"
                        f"<td>{e(r['outcome'])}</td><td>{e(r['duration_sec'])}s</td><td class=\"{badge_cls}\">{e(r['test_status'])}</td>"
                        f"<td>{e(fmt_cost(r['est_cost_usd']))}</td></tr>\n")

    out += """    </tbody>
  </table>
</body>
</html>"""
    return out
