#!/usr/bin/env bash
# telemetry-record.sh — Stop + SubagentStop hook. Tự ghi một entry vào telemetry-log.py cuối mỗi lượt,
# thay vì chỉ dựa vào lời gọi tay theo AGENTS.md (khoảng cách đã phát hiện ở audit
# 2026-09-19: tài liệu mô tả engine "ghi mỗi tác vụ AI" nhưng không hook nào gọi nó thật).
#
# SỐ THẬT, KHÔNG BỊA (CLAUDE.md §4; audit 2026-09-23 C4): bản cũ không truyền token (engine mặc
# định 1000/500) và tính thời lượng từ ĐẦU transcript nên mỗi lượt cộng dồn cả phiên. Bản này:
#   - token = tổng `message.usage` của các dòng transcript MỚI kể từ lần ghi trước
#     (mốc lưu ở .ai-telemetry/last-stop-ts) — cùng cách đọc với scripts/usage-estimate.sh;
#   - thời lượng = delta từ mốc trước tới timestamp cuối;
#   - model = model của message assistant cuối cùng (không đọc settings.json — sau `/model` sẽ sai);
#   - không có dòng mới → không ghi gì;
#   - SubagentStop (Claude Code gửi agent_type + transcript_path riêng của subagent): --agent = tên
#     agent, mốc lưu riêng theo transcript nên Tầng 2/3 — nơi tốn nhất — được đo tách khỏi phiên chính.
# Không chặn phiên nếu lỗi (xem docs/CONVENTIONS.md §A) — best-effort: luôn exit 0, nhưng thiếu jq/python hoặc
# engine lỗi thì NÓI RA một dòng stderr (O-2 2026-10-08: im lặng = mất số đo mà không ai biết).
set -uo pipefail

ROOT="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"
[ -x "$ROOT/scripts/telemetry-log.sh" ] || exit 0
command -v jq >/dev/null 2>&1 || { echo "[telemetry-record] không có jq → không đọc được payload, bỏ qua ghi telemetry." >&2; exit 0; }
# Dò python3 rồi python — cùng thứ tự với scripts/_python-exec.sh (helper đó `exec` một engine .py nên không
# source được cho đoạn Python inline dưới đây).
PYTHON_CMD=""
if command -v python3 >/dev/null 2>&1; then PYTHON_CMD=python3
elif command -v python >/dev/null 2>&1; then PYTHON_CMD=python
else echo "[telemetry-record] không có python3/python → bỏ qua ghi telemetry." >&2; exit 0
fi

payload="$(cat)"
tp="$(printf '%s' "$payload" | jq -r '.transcript_path // empty' 2>/dev/null)"
[ -n "$tp" ] && [ -f "$tp" ] || exit 0
agent="$(printf '%s' "$payload" | jq -r '.agent_type // "session"' 2>/dev/null)"; [ -n "$agent" ] || agent=session

STATE_DIR="$ROOT/.ai-telemetry"
# Mốc riêng theo transcript (git hash-object của ĐƯỜNG DẪN — ổn định, không cần sha256sum): phiên chính và
# từng subagent có transcript riêng → delta không lẫn nhau.
STATE="$STATE_DIR/last-stop-$(printf '%s' "$tp" | git hash-object --stdin 2>/dev/null || printf '%s' "$tp" | cksum | cut -d' ' -f1)"
mkdir -p "$STATE_DIR" 2>/dev/null || exit 0

# In một dòng: <model> <input> <output> <giây> <ts-cuối>  — hoặc rỗng nếu không có dòng mới.
# PYTHONIOENCODING: console Windows mặc định cp1252 (TRAPS.md bẫy 24).
stats="$(PYTHONIOENCODING=utf-8 "$PYTHON_CMD" - "$tp" "$STATE" <<'PY'
import json, sys
from datetime import datetime
path, state = sys.argv[1], sys.argv[2]

def parse(s):
    try:
        return datetime.fromisoformat((s or "").replace("Z", "+00:00"))
    except Exception:
        return None

since = None
try:
    since = parse(open(state, encoding="utf-8").read().strip())
except OSError:
    pass

model, inp, out, first, last, seen = "", 0, 0, None, None, False
with open(path, encoding="utf-8", errors="replace") as f:
    for line in f:
        try:
            o = json.loads(line)
        except Exception:
            continue
        ts = parse(o.get("timestamp"))
        if not ts or (since and ts <= since):
            continue
        first = first or ts
        last = ts
        msg = o.get("message")
        if not isinstance(msg, dict):
            continue
        u = msg.get("usage")
        if isinstance(u, dict):
            seen = True
            # cache_creation/cache_read tính vào input: giá cache khác giá input thường, nhưng
            # gộp vào input là ước lượng TRÊN (không âm thầm thấp hơn thật).
            inp += (u.get("input_tokens", 0) or 0) + (u.get("cache_creation_input_tokens", 0) or 0) \
                   + (u.get("cache_read_input_tokens", 0) or 0)
            out += u.get("output_tokens", 0) or 0
        if msg.get("model"):
            model = msg["model"]
if last is None:
    sys.exit(0)
start = since or first
seconds = max(0.0, (last - start).total_seconds())
# Không có message.usage nào → token KHÔNG BIẾT ("-"), không ghi 0 (LD-07/AC-7).
print(model or "unknown", inp if seen else "-", out if seen else "-", f"{seconds:.4f}", last.isoformat())
PY
)"
[ -n "$stats" ] || exit 0
read -r model in_tok out_tok seconds last_ts <<<"$stats"

tokens=()
[ "$in_tok" = - ] || tokens=(--input-tokens "$in_tok" --output-tokens "$out_tok")
# Engine lỗi → in lỗi của nó ra stderr (có tiền tố), KHÔNG dời mốc (lượt sau ghi lại được), vẫn exit 0 (hook Stop
# không được làm chết phiên). Engine thành công thì stderr của nó (vd cảnh báo token unknown) vẫn bỏ như cũ.
err="$(bash "$ROOT/scripts/telemetry-log.sh" --record \
  --harness claude-code --provider anthropic --model "$model" \
  --agent "$agent" --task "Stop hook tu dong" \
  --duration "$seconds" --test-status N/A "${tokens[@]}" 2>&1 >/dev/null)"; rc=$?
if [ "$rc" -ne 0 ]; then
  echo "[telemetry-record] telemetry-log.sh lỗi (exit $rc) → không ghi được số đo lượt này:" >&2
  printf '%s\n' "$err" | sed 's/^/[telemetry-record]   /' >&2
  exit 0
fi

printf '%s\n' "$last_ts" > "$STATE" 2>/dev/null || true
exit 0
