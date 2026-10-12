"""Parser THUẦN cho engine loop-state — không đọc file, không chạy lệnh, không in: nhận chuỗi, trả dict/list.
Tách khỏi loop-state.py để engine không vượt ngưỡng 400 dòng của radar (khuôn `_plan_check.py`). Nội dung hồ sơ/goal/
kế hoạch là DỮ LIỆU (ADR-0009): chỉ đếm/so khớp, không thực thi. Khuôn bảng: docs/framework/templates/ (WORK, COMPLETION-PLAN),
docs/goals/*.md (bảng slice). Đặc tả: docs/specs/2026-10-12-auto-complete-loop-v2.md FR-4, FR-5, FR-7."""

import re

STATUSES = ("Active", "Planned", "Blocked", "Waiting", "Ready", "Done")
NO_DEP = {"", "—", "-", "–", "none", "baseline"}
CLOSED = {"DONE", "DROPPED"}
PARKED = {"BLOCKED", "WAITING"}
PLAN_MARKS = (("⬜", "open"), ("🔄", "doing"), ("✅", "done"), ("➖", "dropped"))
_CHECK = re.compile(r"^\s*[-*]\s+\[([ xX])\]", re.MULTILINE)
_SPEC_HINT = re.compile(r"tầng\s*[12]\b|\bspec\b|\bdesign\b")
_CODE_HINT = re.compile(r"tầng\s*[34]\b|\bcode\b|\btest\b")


def field(text, name):
    """Giá trị dòng `- <name>: ...` đầu tiên (None nếu không có)."""
    m = re.search(r"^-\s+" + re.escape(name) + r"\s*:\s*(.*)$", text, re.MULTILINE)
    return m.group(1).strip() if m else None


def status(text):
    """Từ khoá trạng thái neo đầu giá trị `- Trạng thái:` (khớp hook guard); không khớp → 'unknown'."""
    value = field(text, "Trạng thái") or ""
    for s in STATUSES:
        if re.match(s + r"\b", value):
            return s
    return "unknown"


def section(text, prefix):
    """Thân mục `## <prefix>...` tới `## ` kế (chuỗi rỗng nếu không có)."""
    m = re.search(r"^##\s+" + re.escape(prefix) + r".*$", text, re.MULTILINE)
    if not m:
        return ""
    nxt = re.search(r"^##\s", text[m.end() :], re.MULTILINE)
    return text[m.end() : m.end() + nxt.start()] if nxt else text[m.end() :]


def meaningful_lines(body):
    """Dòng không rỗng, không phải placeholder `<...>` của template."""
    return [
        ln.strip()
        for ln in body.splitlines()
        if ln.strip() and not ln.strip().startswith("<")
    ]


def layer_hint(text):
    """Tầng ghi ở dòng cuối mục 'Lần thử / blocker': ①② → spec, ③④ → code (standard-delivery §3b)."""
    lines = meaningful_lines(section(text, "Lần thử"))
    if not lines:
        return "unknown"
    last = lines[-1].lower()
    for marks, hint in (("①②", "spec"), ("③④", "code")):
        if any(c in last for c in marks):
            return hint
    if _SPEC_HINT.search(last):
        return "spec"
    return "code" if _CODE_HINT.search(last) else "unknown"


def work_info(text):
    """Các ô hồ sơ: trạng thái, base SHA, mức S/M/L, Bàn giao đã điền, gợi ý tầng."""
    base = re.search(
        r"`([0-9a-f]{7,40})`",
        field(text, "Nhánh / base SHA / thời điểm reconcile") or "",
    )
    level = re.search(r"\b([SML])\b", field(text, "Mức rủi ro / số PR") or "")
    handoff = meaningful_lines(section(text, "Bàn giao"))
    return {
        "status": status(text),
        "base_sha": base.group(1) if base else None,
        "level": level.group(1) if level else None,
        "handoff_filled": bool(handoff),
        "handoff_first": handoff[0] if handoff else "",
        "layer_hint": layer_hint(text),
    }


def kv_lines(text):
    """Dòng `k=v` (marker, .gate-red-streak) → dict; dòng không có `=` bỏ qua."""
    out = {}
    for ln in text.splitlines():
        k, sep, v = ln.partition("=")
        if sep and k.strip() and k.strip() not in out:
            out[k.strip()] = v.strip()
    return out


def to_int(value):
    return int(value) if value and value.isdigit() else 0


def _cells(line):
    return [c.strip() for c in line.strip().strip("|").split("|")]


def table_rows(text, required):
    """Hàng (dict tên cột → ô) của bảng Markdown ĐẦU TIÊN có đủ cột `required`."""
    lines = text.splitlines()
    for i, ln in enumerate(lines):
        if not ln.lstrip().startswith("|"):
            continue
        head = _cells(ln)
        if not all(r in head for r in required):
            continue
        rows = []
        for body in lines[i + 2 :]:
            if not body.lstrip().startswith("|"):
                break
            cells = _cells(body)
            rows.append(dict(zip(head, cells + [""] * (len(head) - len(cells)))))
        return rows
    return []


def _deps(cell):
    return [d for d in re.split(r"[,;\s]+", cell) if d.lower() not in NO_DEP]


def _first_word(cell, default=""):
    return (cell.split() or [default])[0]


def _split_open(rows, state):
    """(ready, blocked) trong các slice mở: ready = không BLOCKED/WAITING ∧ mọi phụ thuộc DONE."""
    done = {i for i, s in state.items() if s == "DONE"}
    ready, blocked = [], []
    for r in rows:
        s = state[r["ID"]]
        if s in CLOSED:
            continue
        deps_ok = all(d in done for d in _deps(r.get("Dependency", "")))
        (ready if s not in PARKED and deps_ok else blocked).append(r["ID"])
    return ready, blocked


def goal_info(text):
    """FR-4: slice open/ready/blocked/done theo cột ID/State/Dependency/Evidence; state goal từ bảng thuộc tính."""
    attrs = {
        r.get("Thuộc tính", ""): r.get("Giá trị", "")
        for r in table_rows(text, ("Thuộc tính", "Giá trị"))
    }
    rows = table_rows(text, ("ID", "State"))
    state = {r["ID"]: _first_word(r["State"]).upper() for r in rows}
    ready, blocked = _split_open(rows, state)
    done = [r["ID"] for r in rows if state[r["ID"]] == "DONE"]
    return {
        "state": _first_word(attrs.get("State", ""), None),
        "slices": {
            "ready": ready,
            "blocked": blocked,
            "open": len(ready) + len(blocked),
            "done": len(done),
        },
        "done_without_evidence": [
            r["ID"] for r in rows if r["ID"] in done and not r.get("Evidence", "")
        ],
        "total": len(rows),
    }


def _plan_mark(cells):
    for cell in reversed(cells):
        for mark, key in PLAN_MARKS:
            if cell.startswith(mark):
                return key
    return None


def checkboxes(text):
    """(chưa tick, tổng) của checklist `- [ ]`/`- [x]`."""
    marks = _CHECK.findall(text)
    return sum(1 for m in marks if m == " "), len(marks)


def completion_info(text):
    """FR-5: đếm hàng `W-` theo ⬜/🔄/✅/➖; DoC = checklist dưới tiêu đề 'Definition of Complete' tới `## ` kế."""
    out = {"open": 0, "doing": 0, "done": 0, "dropped": 0, "next_ids": []}
    for ln in text.splitlines():
        cells = _cells(ln) if ln.lstrip().startswith("|") else []
        key = _plan_mark(cells) if cells and re.match(r"W-\d+", cells[0]) else None
        if key:
            out[key] += 1
            if key in ("doing", "open"):
                out["next_ids"].append((key != "doing", cells[0]))
    out["next_ids"] = [i for _, i in sorted(out["next_ids"], key=lambda t: t[0])]
    m = re.search(r"^#+\s.*Definition of Complete.*$", text, re.MULTILINE)
    doc = ""
    if m:
        nxt = re.search(r"^##\s", text[m.end() :], re.MULTILINE)
        doc = text[m.end() : m.end() + nxt.start()] if nxt else text[m.end() :]
    out["doc_unchecked"], out["doc_total"] = checkboxes(doc)
    return out


def handoff_verdict(unchecked, total):
    """FR-5: GO khi có ô và không ô trống; NO-GO khi còn ô trống; unknown khi không có ô nào."""
    if total == 0:
        return "unknown"
    return "NO-GO" if unchecked else "GO"


def ci_state(checks):
    """FR-6: failure (FAILURE/ERROR) > pending (IN_PROGRESS/QUEUED/PENDING) > success (toàn SUCCESS/SKIPPED/NEUTRAL); rỗng → unknown."""
    states = {
        str(c.get("conclusion") or c.get("state") or c.get("status") or "").upper()
        for c in checks or []
    } - {""}
    if not states:
        return "unknown"
    if states & {"FAILURE", "ERROR"}:
        return "failure"
    if states & {"IN_PROGRESS", "QUEUED", "PENDING"}:
        return "pending"
    return "success" if states <= {"SUCCESS", "SKIPPED", "NEUTRAL"} else "unknown"


# --- verdict (FR-3): luật trả (verdict, reason, next) hoặc None; luật đầu tiên khớp thắng ---


def _r_terminal(s):
    w = s["work"]
    if w["file"].endswith("done.md"):
        return (
            "stop",
            "hồ sơ đã done.md",
            "rm .claude/.auto-complete-loop, báo cáo cuối",
        )
    if w["status"] == "Blocked":
        return "request-input", "hồ sơ Blocked", "nêu blocker + lựa chọn (§9), kết lượt"
    if w["status"] == "Waiting":
        return "waiting", "hồ sơ Waiting", "chờ sự kiện PR/CI; có sự kiện → đổi Active"
    return None


def _r_streak(s):
    n, sig, layer = s["streak"]["n"], s["streak"]["sig"], s["work"]["layer_hint"]
    why = f"cổng commit đỏ {n} lần cùng failure ({sig})"
    if n >= 3:
        return (
            "request-input",
            why,
            "ghi '- Trạng thái: Blocked — <failure>' (§8), kết lượt",
        )
    if n == 2 and layer == "spec":
        return (
            "refine-spec",
            why,
            "quay về tầng ①/② sửa spec/design trước khi chạm code",
        )
    if n == 2:
        return (
            "refine-code",
            why,
            "sửa code tầng ③/④ kèm test đỏ-trước, ghi 'lỗi ở tầng'",
        )
    return None


def _r_git(s):
    prs, g = s["pr"]["open"], s["git"]
    red = [p["number"] for p in prs if p["ci"] == "failure"]
    live = [p["number"] for p in prs if p["ci"] in ("success", "pending")]
    d = g["default_branch"]
    if red:
        return (
            "continue",
            f"PR #{red[0]} CI đỏ",
            f"sửa CI PR #{red[0]}, commit qua cổng",
        )
    if g["dirty"]:
        return "continue", f"{g['dirty']} file dở", "commit file dở qua cổng (/gate)"
    if live:
        why = f"PR #{live[0]} mở, CI xanh/pending, không file dở"
        return "waiting", why, f"ghi 'Waiting — chờ CI/merge PR #{live[0]}', kết lượt"
    if g["behind"] and not prs:
        why = f"tụt origin/{d} {g['behind']} commit, không PR"
        return "continue", why, f"reconcile với origin/{d} trước khi làm tiếp"
    return None


def _r_goal(s):
    sl, missing = s["goal"]["slices"], s["goal"]["done_without_evidence"]
    if missing:
        ids = ", ".join(missing)
        return "continue", "slice DONE thiếu Evidence", f"điền Evidence cho {ids}"
    if sl["ready"]:
        ids = ", ".join(sl["ready"])
        return "continue", f"slice ready: {ids}", f"chọn một slice trong {ids} (§4)"
    if sl["open"]:
        why = f"slice mở không ready (blocked: {', '.join(sl['blocked'])})"
        return "request-input", why, "ghi Blocked + phụ thuộc chưa xong + đề xuất"
    return None


def _r_plan(s):
    c, h = s["completion"], s["handoff"]
    if c["open"] + c["doing"]:
        why = f"kế hoạch hoàn thiện còn {c['doing']} 🔄 + {c['open']} ⬜"
        return "continue", why, f"làm {c['next_ids'][0]} trong {c['file']}"
    if h["verdict"] == "NO-GO":
        why = f"release-readiness NO-GO ({h['unchecked']}/{h['total']} ô trống)"
        return "continue", why, f"hoàn tất ô trống trong {h['file']}"
    if c["doc_unchecked"]:
        why = f"DoC còn {c['doc_unchecked']}/{c['doc_total']} ô"
        return "continue", why, f"kiểm, tick DoC trong {c['file']} trước done.md"
    return None


def _r_rest(s):
    w = s["work"]
    if s["goal"]["total"] or s["completion"]["file"] or s["handoff"]["total"]:
        why = "goal/kế hoạch/release-readiness không còn việc mở"
        return "continue", why, "nghiệm thu: ghi PR/SHA, rename working.md → done.md"
    if not w["handoff_filled"]:
        why = "Bàn giao trống, không tracker máy đếm được"
        return "continue", why, "ghi Bàn giao: một hành động cụ thể kế tiếp"
    return (
        "continue",
        "hồ sơ Active, theo Bàn giao",
        "theo Bàn giao: " + w["handoff_first"],
    )


RULES = (_r_terminal, _r_streak, _r_git, _r_goal, _r_plan, _r_rest)


def decide(s):
    """(verdict, reason, next) theo thứ tự FR-3; `_r_rest` luôn khớp."""
    return next(hit for hit in (rule(s) for rule in RULES) if hit)


def brief(s):
    """FR-8: ≤ 20 dòng, một dòng một dữ kiện, không màu."""
    w, g, pr, gl, c, h = (
        s[k] for k in ("work", "git", "pr", "goal", "completion", "handoff")
    )
    prs = "; ".join(
        f"#{p['number']} ci={p['ci']} mergeable={p['mergeable']} auto={p['auto_merge']}"
        for p in pr["open"]
    )
    sl, lp = gl["slices"], s["loop"]
    return "\n".join(
        [
            f"verdict: {s['verdict']} — {s['reason']}",
            f"next: {s['next']}",
            f"work: {w['id']} · {w['status']} · mức {w['level']} · tầng {w['layer_hint']}",
            (
                f"git: {g['branch']}@{g['head']} · default {g['default_branch']}"
                f" · ahead {g['ahead']} behind {g['behind']} · dirty {g['dirty']}"
            ),
            f"pr: {prs or '0 PR mở'}"
            if pr["available"]
            else f"pr: unknown — {pr['note']}",
            (
                f"goal: {gl['file']} · ready {sl['ready']} · blocked {sl['blocked']}"
                f" · open {sl['open']} done {sl['done']} · thiếu Evidence {gl['done_without_evidence']}"
            ),
            (
                f"completion: {c['file']} · open {c['open']} doing {c['doing']} done {c['done']}"
                f" dropped {c['dropped']} · DoC chưa tick {c['doc_unchecked']}/{c['doc_total']}"
            ),
            f"handoff: {h['verdict']} ({h['unchecked']}/{h['total']} ô trống)",
            f"streak: n={s['streak']['n']} sig={s['streak']['sig']}",
            f"loop: marker {lp['marker']} · id {lp['id']} · n {lp['n']}/{lp['max']}",
        ]
    )
