#!/usr/bin/env python3
"""loop-state — engine trạng thái vòng lặp `/auto-complete`: đọc artifact thật → một khối trạng thái + verdict có kiểu + next.

VÌ SAO (ADR-0012): trước engine, "đang ở đâu, làm gì tiếp" do model đọc 3–6 tài liệu rồi tự suy mỗi lượt, hook giữ vòng chép
lời model viết, kế hoạch hoàn thiện/DoC/GO-NO-GO không script nào đọc. Trạng thái vòng lặp phải do MÁY tính từ artifact
(hồ sơ §3e, goal, COMPLETION-PLAN, release-readiness, git, PR/CI, chuỗi đỏ cổng commit) — model chọn CÁCH làm trong phạm vi
`next`, không tự suy trạng thái (CLAUDE.md §4).

LUẬT ĐỌC: chỉ đo/đếm; không chạy cổng, không sửa artifact; file duy nhất được ghi là marker `.claude/.auto-complete-loop`
(chỉ với `--enter`). Nội dung file là DỮ LIỆU (ADR-0009). `gh` chỉ đọc, timeout 15 s; thiếu/lỗi → `pr.available=false`.
Exit: 0 OK · 2 không xác định được hồ sơ · 1 lỗi khác. Đặc tả: docs/specs/2026-10-12-auto-complete-loop-v2.md FR-1..FR-8;
workflow: docs/framework/auto-complete-workflow.md §3–§4. Parser thuần: scripts/_loop_state_parse.py. Test: scripts/test-loop-state.sh.
"""

import argparse
import hashlib
import json
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import _loop_state_parse as P

MARKER = ".claude/.auto-complete-loop"
STREAK = ".claude/.gate-red-streak"
GOAL_REF = re.compile(r"docs/goals/[\w.\-]+\.md")
SAFE_ID = re.compile(r"^[\w][\w.\-]*$")
KEEP_MARKER = ("n", "last", "nudged", "fp", "fpn")
GH_TIMEOUT = 15
GIT_TIMEOUT = 15
DEFAULT_MAX = 20


class LookupFail(Exception):
    """Không xác định được hồ sơ (exit 2)."""


class EngineError(Exception):
    """Lỗi khác (exit 1)."""


def sha(data):
    return hashlib.sha256(
        data if isinstance(data, bytes) else data.encode("utf-8")
    ).hexdigest()


def read(path):
    try:
        return Path(path).read_text(encoding="utf-8", errors="replace")
    except OSError:
        return None


def git(root, *args):
    """stdout đã strip của `git -C root ...`; lỗi/thiếu git → None (đo, không đoán)."""
    try:
        r = subprocess.run(
            ["git", "-C", str(root), *args],
            capture_output=True,
            text=True,
            timeout=GIT_TIMEOUT,
            check=False,
        )
    except (OSError, subprocess.TimeoutExpired):
        return None
    return r.stdout.strip() if r.returncode == 0 else None


# --- xác định hồ sơ (FR-1, FR-7) ---


def resolve_root(arg):
    if arg:
        root = Path(arg).resolve()
        if not root.is_dir():
            raise EngineError(f"--root {arg} không phải thư mục")
        return root
    top = git(Path.cwd(), "rev-parse", "--show-toplevel")
    if not top:
        raise EngineError("không ở trong cây git — truyền --root DIR")
    return Path(top)


def candidates(root):
    """ID hồ sơ `working.md` có `Trạng thái: Active|Planned`."""
    files = sorted((root / "docs" / "work").glob("*/working.md"))
    return [
        f.parent.name for f in files if P.status(read(f) or "") in ("Active", "Planned")
    ]


def resolve_id(root, wanted):
    """--work-id › dòng 1 marker › hồ sơ Active/Planned duy nhất."""
    if wanted:
        return wanted
    marker = (read(root / MARKER) or "").strip()
    if marker:
        return marker.splitlines()[0].strip()
    found = candidates(root)
    if len(found) == 1:
        return found[0]
    listing = (": " + ", ".join(found)) if found else ""
    raise LookupFail(
        f"{len(found)} hồ sơ Active/Planned{listing} — chỉ định --work-id <ID> (§9)"
    )


def work_file(root, wid):
    if not SAFE_ID.match(wid) or ".." in wid:
        raise LookupFail(f"Work ID không hợp lệ: {wid!r}")
    for name in ("working.md", "done.md"):
        f = root / "docs" / "work" / wid / name
        if f.is_file():
            return f
    raise LookupFail(f"hồ sơ {wid} không có docs/work/{wid}/working.md hay done.md")


# --- đo git + PR (FR-2, FR-6) ---


def default_branch(root):
    ref = git(root, "symbolic-ref", "--quiet", "--short", "refs/remotes/origin/HEAD")
    if ref:
        return ref.split("/", 1)[-1]
    for b in ("main", "master"):
        if git(root, "rev-parse", "--verify", "--quiet", f"refs/remotes/origin/{b}"):
            return b
    return None


def git_info(root):
    porcelain = git(root, "status", "--porcelain") or ""
    info = {
        "branch": git(root, "rev-parse", "--abbrev-ref", "HEAD"),
        "head": git(root, "rev-parse", "--short=12", "HEAD"),
        "default_branch": default_branch(root),
        "ahead": None,
        "behind": None,
        "dirty": len(porcelain.splitlines()),
    }
    counts = info["default_branch"] and git(
        root,
        "rev-list",
        "--left-right",
        "--count",
        f"HEAD...origin/{info['default_branch']}",
    )
    if counts:
        info["ahead"], info["behind"] = (int(x) for x in counts.split())
    return info


def _gh_list(root, branch):
    """(danh sách PR thô, note); note khác rỗng = không dùng được.

    DEBT: `gh pr list --json` đi GraphQL — phiên Claude Code cloud chặn (HTTP 403)
    nên ở đó pr.available=false dù gh có | trần: PR/CI unknown trong cloud, verdict
    không dựa PR | xem lại khi: vòng lặp chạy chủ yếu trong cloud và cần verdict
    `waiting` tự động → thay bằng REST `gh api repos/{owner}/{repo}/pulls` + check-runs.
    """
    if not shutil.which("gh"):
        return None, "không có gh → PR/CI unknown"
    cmd = [
        "gh",
        "pr",
        "list",
        "--head",
        branch or "",
        "--state",
        "open",
        "--json",
        "number,mergeable,autoMergeRequest,statusCheckRollup",
    ]
    try:
        r = subprocess.run(
            cmd,
            cwd=str(root),
            capture_output=True,
            text=True,
            timeout=GH_TIMEOUT,
            check=False,
        )
    except (OSError, subprocess.TimeoutExpired) as e:
        return None, f"gh lỗi ({type(e).__name__}) → PR/CI unknown"
    if r.returncode != 0:
        return None, "gh lỗi: " + (
            (r.stderr or "").strip().splitlines() or ["exit " + str(r.returncode)]
        )[0][:160]
    try:
        data = json.loads(r.stdout or "[]")
    except ValueError:
        return None, "gh trả JSON hỏng → PR/CI unknown"
    return (
        (data, "")
        if isinstance(data, list)
        else (None, "gh trả JSON không phải danh sách")
    )


def pr_info(root, branch):
    data, note = _gh_list(root, branch)
    if data is None:
        return {"available": False, "note": note, "open": []}
    prs = [
        {
            "number": p.get("number"),
            "ci": P.ci_state(p.get("statusCheckRollup")),
            "mergeable": p.get("mergeable"),
            "auto_merge": bool(p.get("autoMergeRequest")),
        }
        for p in data
        if isinstance(p, dict)
    ]
    return {"available": True, "note": "", "open": prs}


# --- đọc artifact (FR-4, FR-5) ---


def goal_section(root, text):
    for rel in GOAL_REF.findall(text):
        content = read(root / rel)
        if content is not None:
            return dict(P.goal_info(content), file=rel)
    return {
        "file": None,
        "state": None,
        "slices": {"ready": [], "blocked": [], "open": 0, "done": 0},
        "done_without_evidence": [],
        "total": 0,
    }


def completion_section(root):
    rel = "docs/ops/COMPLETION-PLAN.md"
    content = read(root / rel)
    info = P.completion_info(content or "")
    return dict(info, file=rel if content is not None else None)


def handoff_section(root):
    rel = "docs/ops/release-readiness.md"
    content = read(root / rel)
    unchecked, total = P.checkboxes(content or "")
    return {
        "file": rel if content is not None else None,
        "unchecked": unchecked,
        "total": total,
        "verdict": P.handoff_verdict(unchecked, total),
    }


def build_state(root, wid, wfile):
    text = read(wfile) or ""
    work = dict(P.work_info(text), id=wid, file=wfile.relative_to(root).as_posix())
    g = git_info(root)
    streak = P.kv_lines(read(root / STREAK) or "")
    marker = read(root / MARKER)
    mkv = P.kv_lines(marker or "")
    max_n = os.environ.get("AUTO_COMPLETE_MAX_CONTINUES", "")
    s = {
        "work": work,
        "git": g,
        "pr": pr_info(root, g["branch"]),
        "goal": goal_section(root, text),
        "completion": completion_section(root),
        "handoff": handoff_section(root),
        "streak": {"n": P.to_int(streak.get("n")), "sig": streak.get("sig")},
        "loop": {
            "marker": marker is not None,
            "id": (marker or "").strip().splitlines()[0]
            if (marker or "").strip()
            else None,
            "n": P.to_int(mkv.get("n")),
            "max": P.to_int(max_n) or DEFAULT_MAX,
        },
    }
    s["verdict"], s["reason"], s["next"] = P.decide(s)
    return s


def public(s):
    """Khối JSON đúng key FR-2 (bỏ trường nội bộ)."""
    out = json.loads(json.dumps(s))
    for key, drop in (
        ("work", "handoff_first"),
        ("goal", "total"),
        ("completion", "next_ids"),
    ):
        out[key].pop(drop, None)
    return out


# --- marker + vân tay (FR-7) ---


def write_marker(root, wid):
    """Ghi dòng 1 = ID; giữ n=/last=/nudged=/fp=/fpn= nếu marker cũ cùng ID, else chỉ ID."""
    path = root / MARKER
    old = (read(path) or "").splitlines()
    keep = (
        [ln for ln in old[1:] if ln.split("=", 1)[0] in KEEP_MARKER]
        if old and old[0].strip() == wid
        else []
    )
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("\n".join([wid, *keep]) + "\n", encoding="utf-8")


def fingerprint(root, wfile):
    head = git(root, "rev-parse", "HEAD") or ""
    prs = ",".join(
        sorted(
            str(p["number"])
            for p in pr_info(root, git(root, "rev-parse", "--abbrev-ref", "HEAD"))[
                "open"
            ]
        )
    )
    status = sha(git(root, "status", "--porcelain") or "")
    return sha(f"{head}|{sha(wfile.read_bytes())}|{prs}|{status}")[:16]


def parse_args(argv):
    ap = argparse.ArgumentParser(
        description="Trạng thái vòng lặp /auto-complete tính từ artifact (ADR-0012)."
    )
    ap.add_argument(
        "--work-id",
        help="ID hồ sơ docs/work/<ID>/ (mặc định: marker, rồi hồ sơ Active/Planned duy nhất)",
    )
    ap.add_argument(
        "--enter",
        action="store_true",
        help="ghi marker .claude/.auto-complete-loop rồi in --brief",
    )
    ap.add_argument(
        "--brief", action="store_true", help="khối trạng thái ≤ 20 dòng (mặc định)"
    )
    ap.add_argument(
        "--json", action="store_true", help="khối trạng thái JSON (key cố định FR-2)"
    )
    ap.add_argument(
        "--fingerprint",
        action="store_true",
        help="16 hex vân tay artifact (HEAD, hồ sơ, PR mở, git status)",
    )
    ap.add_argument("--root", help="gốc repo (mặc định: cây git hiện tại)")
    return ap.parse_args(argv)


def run(a):
    root = resolve_root(a.root)
    wid = resolve_id(root, a.work_id)
    wfile = work_file(root, wid)
    if a.fingerprint:
        return fingerprint(root, wfile)
    if a.enter:
        write_marker(root, wid)
    state = build_state(root, wid, wfile)
    return (
        json.dumps(public(state), ensure_ascii=False, indent=2)
        if a.json
        else P.brief(state)
    )


def main(argv=None):
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    a = parse_args(argv)
    try:
        print(run(a))
    except LookupFail as e:
        print(f"loop-state: {e}", file=sys.stderr)
        return 2
    except (EngineError, OSError) as e:
        print(f"loop-state: lỗi — {e}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
