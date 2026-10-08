#!/usr/bin/env bash
# usage-estimate.sh — ƯỚC TÍNH % quota 5h đã dùng.
#
# TỬ SỐ (chính xác): tổng token thật đọc từ transcript phiên (message.usage),
#   chỉ tính các message trong 5 GIỜ gần nhất, gộp theo model.
# MẪU SỐ (ước tính): budget token/5h theo GÓI của bạn, khai báo ở
#   .claude/usage-budget.sh (Anthropic KHÔNG cấp số này dạng máy đọc → tự hiệu chỉnh).
#
# In ra:  THRESHOLD=<n>   OVERALL=<%|NA>   rồi từng dòng <model>=<%|NA> (used/budget).
# OVERALL = MAX các % theo model (model nào chạm trần trước thì đó là ràng buộc).
# Chưa khai báo budget → OVERALL=NA (tính năng tự tắt, không báo động sai).
#
# LƯU Ý: chỉ đếm token của PHIÊN NÀY (1 transcript). Việc chạy ở phiên/khác song song
# trong cùng 5h sẽ không được cộng vào — nên đây là ước tính, không phải số chính thức.
set -uo pipefail   # cố ý KHÔNG -e: không được làm chết phiên/lượt chạy (xem docs/CONVENTIONS.md §A)

ROOT="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"
TRANSCRIPT="${1:-}"
[ -n "$TRANSCRIPT" ] && [ -f "$TRANSCRIPT" ] || { echo "THRESHOLD=70"; echo "OVERALL=NA"; exit 0; }
command -v python3 >/dev/null 2>&1 || { echo "THRESHOLD=70"; echo "OVERALL=NA"; exit 0; }

BUDGET_FILE="$ROOT/.claude/usage-budget.sh"
CACHE_READ_WEIGHT=0.1
WINDDOWN_THRESHOLD=70
BUDGET_OPUS=0; BUDGET_SONNET=0; BUDGET_HAIKU=0; BUDGET_FABLE=0
# shellcheck source=/dev/null  # đường dẫn động do người dùng cấu hình — không phân tích tĩnh được
if [ -f "$BUDGET_FILE" ]; then . "$BUDGET_FILE"; fi
export CACHE_READ_WEIGHT WINDDOWN_THRESHOLD BUDGET_OPUS BUDGET_SONNET BUDGET_HAIKU BUDGET_FABLE

# PYTHONIOENCODING: console Windows mặc định cp1252 → in tiếng Việt sẽ UnicodeEncodeError
# (TRAPS.md bẫy 24 — khối reconfigure trong file .py không áp cho heredoc inline này).
PYTHONIOENCODING=utf-8 python3 - "$TRANSCRIPT" <<'PY'
import json, sys, os
from datetime import datetime, timezone, timedelta
path = sys.argv[1]
weight = float(os.environ.get("CACHE_READ_WEIGHT", "0.1") or 0.1)
thr = os.environ.get("WINDDOWN_THRESHOLD", "70") or "70"
budgets = {a: float(os.environ.get("BUDGET_" + a.upper(), "0") or 0)
           for a in ("opus", "sonnet", "haiku", "fable")}

def alias(m):
    m = (m or "").lower()
    for a in ("opus", "sonnet", "haiku", "fable"):
        if a in m:
            return a
    return None

def parse_ts(s):
    try:
        return datetime.fromisoformat((s or "").replace("Z", "+00:00"))
    except Exception:
        return None

cut = datetime.now(timezone.utc) - timedelta(hours=5)
used = {a: 0.0 for a in ("opus", "sonnet", "haiku", "fable")}
# encoding tường minh: open() mặc định theo locale (cp1252 trên Windows) → UnicodeDecodeError với transcript
# tiếng Việt, script chết, usage-guard mất cảnh báo quota (O-2 P-A3, test UE-5).
with open(path, encoding="utf-8", errors="replace") as f:
    for line in f:
        try:
            o = json.loads(line)
        except Exception:
            continue
        ts = parse_ts(o.get("timestamp"))
        if not ts or ts < cut:
            continue
        msg = o.get("message")
        if not isinstance(msg, dict):
            continue
        u = msg.get("usage")
        if not isinstance(u, dict):
            continue
        a = alias(msg.get("model"))
        if not a:
            continue
        used[a] += ((u.get("input_tokens", 0) or 0)
                    + (u.get("output_tokens", 0) or 0)
                    + (u.get("cache_creation_input_tokens", 0) or 0)
                    + weight * (u.get("cache_read_input_tokens", 0) or 0))

overall = None
lines = []
for a in ("opus", "sonnet", "haiku", "fable"):
    b = budgets[a]
    if b > 0:
        pct = used[a] / b * 100.0
        overall = pct if overall is None else max(overall, pct)
        lines.append(f"{a}={pct:.0f} (used={int(used[a])} budget={int(b)})")
    elif used[a] > 0:
        lines.append(f"{a}=NA (used={int(used[a])} budget=0)")
print(f"THRESHOLD={thr}")
print("OVERALL=NA" if overall is None else f"OVERALL={overall:.0f}")
for l in lines:
    print(l)
PY
