#!/usr/bin/env bash
# test-hooks-session.sh — Kiểm các hook KHÔNG phải cổng chặn (telemetry-record, session-resume…):
# chúng không chặn gì nên hỏng im lặng không ai thấy. Audit 2026-09-23: 5/7 hook không có test, và
# đúng hai trong số đó mang lỗi thật — telemetry ghi token bịa 1000/500 + thời lượng cộng dồn (C4),
# session-resume nạp nguyên PROGRESS.md 58 KB mỗi phiên (C5).
#
# Chạy: bash scripts/test-hooks-session.sh
set -uo pipefail   # cố ý KHÔNG -e (docs/CONVENTIONS.md §A)

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
# shellcheck source=scripts/_test-lib.sh
source "$ROOT/scripts/_test-lib.sh"

if ! command -v jq >/dev/null 2>&1 || ! command -v python3 >/dev/null 2>&1; then
  echo "::error::Cần jq + python3 để kiểm hook session (hook fail-open khi thiếu — test này không được xanh giả)."
  exit 1
fi

# ── Dự án giả: đủ để hook tìm thấy engine telemetry ─────────────────────────────
PROJ="$WORK/proj"; mkdir -p "$PROJ/scripts" "$PROJ/.claude/hooks"
cp "$ROOT/scripts/telemetry-log.sh" "$ROOT/scripts/telemetry-log.py" "$ROOT/scripts/model-rates.json" \
   "$ROOT/scripts/_python-exec.sh" "$PROJ/scripts/"
cp "$ROOT/.claude/hooks/telemetry-record.sh" "$PROJ/.claude/hooks/"
chmod +x "$PROJ/scripts/"*.sh "$PROJ/.claude/hooks/"*.sh

TR="$WORK/transcript.jsonl"
cat > "$TR" <<'EOF'
{"type":"user","timestamp":"2026-09-23T10:00:00.000Z","message":{"role":"user","content":"hi"}}
{"type":"assistant","timestamp":"2026-09-23T10:06:00.000Z","message":{"model":"claude-opus-5-5","usage":{"input_tokens":1000,"output_tokens":200,"cache_read_input_tokens":500}}}
{"type":"assistant","timestamp":"2026-09-23T10:12:00.000Z","message":{"model":"claude-sonnet-5","usage":{"input_tokens":3000,"output_tokens":800}}}
EOF
run_hook() { printf '{"transcript_path":"%s"}' "$TR" | CLAUDE_PROJECT_DIR="$PROJ" bash "$PROJ/.claude/hooks/telemetry-record.sh"; }
last_entry() { python3 -c "import json,sys; l=json.load(open('$PROJ/.ai-telemetry/telemetry.json', encoding='utf-8')); e=l[$1]; print(e['model'], e['input_tokens'], e['output_tokens'], e['duration_sec'], len(l))"; }

echo "== 1. telemetry-record: token = tổng usage THẬT, model = message cuối, thời lượng = delta =="
run_hook; rc=$?
[ "$rc" -eq 0 ] && ok "hook thoát 0" || bad "hook thoát $rc"
e="$(last_entry -1 2>/dev/null)"
# input = 1000+500 (cache read) + 3000 = 4500; output = 200+800 = 1000; 10:00→10:12 = 0.2 giờ
if [ "$e" = "claude-sonnet-5 4500 1000 0.2 1" ]; then
  ok "entry = model cuối · 4500 in · 1000 out · 0.2 giờ (không phải 1000/500 bịa)"
else
  bad "entry sai: '$e' (kỳ vọng 'claude-sonnet-5 4500 1000 0.2 1')"
fi

echo "== 2. Lượt kế KHÔNG có dòng mới → không ghi thêm (không cộng dồn cả phiên) =="
run_hook
n="$(python3 -c "import json; print(len(json.load(open('$PROJ/.ai-telemetry/telemetry.json', encoding='utf-8'))))")"
[ "$n" = "1" ] && ok "vẫn 1 entry" || bad "hook ghi trùng khi không có dòng mới: $n entry"

echo "== 3. Có dòng mới → chỉ tính phần MỚI (delta), không tính lại từ đầu =="
echo '{"type":"assistant","timestamp":"2026-09-23T10:30:00.000Z","message":{"model":"claude-sonnet-5","usage":{"input_tokens":100,"output_tokens":50}}}' >> "$TR"
run_hook
e="$(last_entry -1)"
# 10:12 → 10:30 = 0.3 giờ
[ "$e" = "claude-sonnet-5 100 50 0.3 2" ] && ok "entry 2 chỉ có phần mới: 100 in · 50 out · 0.3 giờ" || bad "entry 2 sai: '$e'"

echo "== 4. Transcript không tồn tại / payload rỗng → thoát 0, không ghi =="
printf '{}' | CLAUDE_PROJECT_DIR="$PROJ" bash "$PROJ/.claude/hooks/telemetry-record.sh"; rc=$?
n="$(python3 -c "import json; print(len(json.load(open('$PROJ/.ai-telemetry/telemetry.json', encoding='utf-8'))))")"
[ "$rc" -eq 0 ] && [ "$n" = "2" ] && ok "payload rỗng: thoát 0, không ghi" || bad "payload rỗng: rc=$rc, entry=$n"

echo "== 5. NEGATIVE: engine đổi mặc định token về số bịa thì test này phải ĐỎ =="
sed 's/default=0)/default=777)/' "$ROOT/scripts/telemetry-log.py" > "$PROJ/scripts/telemetry-log.py"
rm -f "$PROJ/.ai-telemetry/last-stop-ts" "$PROJ/.ai-telemetry/telemetry.json"
printf '{"transcript_path":"%s"}' "$WORK/none.jsonl" | CLAUDE_PROJECT_DIR="$PROJ" bash "$PROJ/.claude/hooks/telemetry-record.sh"
# transcript không tồn tại → hook không ghi; gọi engine trực tiếp không token → phải lộ 777
CLAUDE_PROJECT_DIR="$PROJ" bash "$PROJ/scripts/telemetry-log.sh" --record --agent neg --task neg >/dev/null 2>&1
e="$(python3 -c "import json; l=json.load(open('$PROJ/.ai-telemetry/telemetry.json', encoding='utf-8')); print(l[-1]['input_tokens'])")"
[ "$e" = "777" ] && ok "negative test bắt được engine bịa token (777)" || bad "negative test không bắt được (đọc: $e)"

if [ "$fails" -eq 0 ]; then
  echo "OK — hook session (telemetry-record) ghi số thật, delta đúng, không ghi trùng."
  exit 0
fi
echo "FAIL — $fails ca hỏng."
exit 1
