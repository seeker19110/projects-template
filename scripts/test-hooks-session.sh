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
fails=0  # explicit for ShellCheck; _test-lib.sh also initializes the counter

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

echo "== 6. session-resume: chỉ nạp 4 mục, bỏ khối 'trước đó', trần byte, nói rõ khi cắt =="
SR="$ROOT/.claude/hooks/session-resume.sh"
P2="$WORK/proj2"; mkdir -p "$P2/.claude"; git -C "$P2" init -q 2>/dev/null
{
  echo "# PROGRESS"; echo; echo "## Giai đoạn hiện tại"; echo; echo "- Giai đoạn: GĐ 5. MOC-HIEN-TAI"
  echo "- Giai đoạn trước đó: LICH-SU-CU dòng 1"; echo "  LICH-SU-CU dòng 2 thụt đầu dòng"
  echo "- Default-branch SHA đã đối chiếu: abc"; echo; echo "## Goal đang active"; echo; echo "GOAL-KHONG-CAN"
  echo; echo "## Đang làm / chờ"; echo; echo "- DANG-LAM-X"; echo; echo "## Tiếp theo"; echo; echo "- TIEP-THEO-Y"
  echo; echo "## Quyết định quan trọng"; echo; echo "QUYET-DINH-KHONG-CAN"; echo; echo "## Bàn giao phiên"; echo; echo "- BAN-GIAO-Z"
} > "$P2/PROGRESS.md"
out="$(printf '{}' | CLAUDE_PROJECT_DIR="$P2" bash "$SR")"
ctx="$(printf '%s' "$out" | jq -r '.hookSpecificOutput.additionalContext')"
for want in MOC-HIEN-TAI DANG-LAM-X TIEP-THEO-Y BAN-GIAO-Z "SHA đã đối chiếu"; do
  printf '%s' "$ctx" | grep -q -- "$want" && ok "có: $want" || bad "thiếu mục cần cho 'tiếp tục': $want"
done
for nowant in LICH-SU-CU GOAL-KHONG-CAN QUYET-DINH-KHONG-CAN; do
  printf '%s' "$ctx" | grep -q -- "$nowant" && bad "vẫn nạp thứ không cần: $nowant" || ok "không nạp: $nowant"
done
# Trần: PROGRESS.md 100 KB toàn nội dung trong mục cần → phải cắt ở trần và nói rõ.
{ echo "## Đang làm / chờ"; echo; yes -- "- dòng dài lặp lại để vượt trần byte của hook session-resume" | head -n 2000; } > "$P2/PROGRESS.md"
out="$(printf '{}' | CLAUDE_PROJECT_DIR="$P2" bash "$SR")"
n="$(printf '%s' "$out" | jq -r '.hookSpecificOutput.additionalContext' | wc -c)"
[ "$n" -le 9000 ] && ok "ngữ cảnh bị cắt về ≤ 9000 byte (đo: $n)" || bad "hook vẫn nạp $n byte — vượt trần"
printf '%s' "$out" | grep -q "ĐÃ CẮT" && ok "nói rõ đã cắt" || bad "cắt mà không nói"
out="$(printf '{}' | SESSION_RESUME_MAX_BYTES=2000 CLAUDE_PROJECT_DIR="$P2" bash "$SR")"
n="$(printf '%s' "$out" | jq -r '.hookSpecificOutput.additionalContext' | wc -c)"
[ "$n" -le 2600 ] && ok "trần tuỳ chỉnh SESSION_RESUME_MAX_BYTES=2000 có hiệu lực (đo: $n)" || bad "trần tuỳ chỉnh không hiệu lực ($n)"

echo "== 7. SubagentStop: --agent = agent_type, mốc riêng theo transcript (không lẫn với phiên chính) =="
TR2="$WORK/sub-transcript.jsonl"
printf '{"type":"assistant","timestamp":"2026-09-23T11:00:00.000Z","message":{"model":"claude-haiku-4-5","usage":{"input_tokens":10,"output_tokens":5}}}\n' > "$TR2"
printf '{"transcript_path":"%s","agent_type":"mechanical-worker","hook_event_name":"SubagentStop"}' "$TR2" | CLAUDE_PROJECT_DIR="$PROJ" bash "$PROJ/.claude/hooks/telemetry-record.sh"
e="$(python3 -c "import json; l=json.load(open('$PROJ/.ai-telemetry/telemetry.json', encoding='utf-8')); e=l[-1]; print(e['agent'], e['input_tokens'], e['output_tokens'])")"
[ "$e" = "mechanical-worker 10 5" ] && ok "SubagentStop ghi agent=mechanical-worker với token riêng" || bad "SubagentStop sai: '$e'"
# Phiên chính vẫn không có dòng mới → không ghi (mốc của nó không bị mốc subagent ghi đè)
n0="$(python3 -c "import json; print(len(json.load(open('$PROJ/.ai-telemetry/telemetry.json', encoding='utf-8'))))")"
run_hook
n1="$(python3 -c "import json; print(len(json.load(open('$PROJ/.ai-telemetry/telemetry.json', encoding='utf-8'))))")"
[ "$n0" = "$n1" ] && ok "mốc phiên chính độc lập với mốc subagent" || bad "mốc bị lẫn: phiên chính ghi thêm entry ($n0 → $n1)"

echo "== 8. PreCompact: chụp checkpoint có nhánh + mục Đang làm, ghi compact.log =="
PC="$ROOT/.claude/hooks/precompact-checkpoint.sh"
P3="$WORK/proj3"; mkdir -p "$P3/.claude"; git -C "$P3" init -q 2>/dev/null; git -C "$P3" switch -q -c feat/x 2>/dev/null || git -C "$P3" checkout -q -b feat/x
printf '## Đang làm / chờ\n\n- DANG-LAM-CHECKPOINT\n\n## Bàn giao phiên\n\n- BAN-GIAO-CHECKPOINT\n' > "$P3/PROGRESS.md"
printf '{"trigger":"auto"}' | CLAUDE_PROJECT_DIR="$P3" bash "$PC" 2>/dev/null; rc=$?
[ "$rc" -eq 0 ] && ok "hook thoát 0" || bad "hook thoát $rc"
grep -q "Branch: feat/x" "$P3/.claude/.compact-checkpoint" && grep -q "DANG-LAM-CHECKPOINT" "$P3/.claude/.compact-checkpoint" && grep -q "BAN-GIAO-CHECKPOINT" "$P3/.claude/.compact-checkpoint" \
  && ok "checkpoint có nhánh + Đang làm + Bàn giao" || bad "checkpoint thiếu nội dung: $(head -c 300 "$P3/.claude/.compact-checkpoint" 2>/dev/null)"
grep -q "trigger=auto" "$P3/.ai-telemetry/compact.log" && ok "compact.log ghi trigger" || bad "compact.log không ghi"

echo "== 9. UI detector chỉ chạy khi opt-in và chỉ nhận file UI tồn tại =="
UI="$ROOT/.claude/hooks/ui-intelligence.sh"
UI_PROJ="$WORK/ui-proj"; mkdir -p "$UI_PROJ/src"
UI_FILE="$UI_PROJ/src/my component.tsx"
printf 'export default null\n' > "$UI_FILE"
PROVIDER="$WORK/provider.sh"
cat > "$PROVIDER" <<'PROVIDER_SH'
#!/usr/bin/env bash
printf '%s\n' "$1" "$2" >> "$UI_CALLS"
exit "${UI_EXIT:-0}"
PROVIDER_SH
chmod +x "$PROVIDER"
UI_CALLS="$WORK/ui-calls"; export UI_CALLS
ui_payload() { printf '{"tool_input":{"file_path":%s}}' "$(printf '%s' "$1" | jq -Rs .)"; }
ui_payload 'src/my component.tsx' | CLAUDE_PROJECT_DIR="$UI_PROJ" UI_INTELLIGENCE_COMMAND="$PROVIDER" bash "$UI"; rc=$?
[ "$rc" -eq 0 ] && [ ! -e "$UI_CALLS" ] && ok "disabled: không gọi provider" || bad "disabled: rc=$rc hoặc provider vẫn chạy"
ui_payload 'src/my component.tsx' | CLAUDE_PROJECT_DIR="$UI_PROJ" UI_INTELLIGENCE_HOOK=1 UI_INTELLIGENCE_COMMAND="$PROVIDER" bash "$UI"; rc=$?
[ "$rc" -eq 0 ] && [ "$(cat "$UI_CALLS")" = "$(printf 'detect\n%s' "$UI_FILE")" ] && ok "enabled: gọi đúng file UI có khoảng trắng" || bad "enabled: sai command/path hoặc exit $rc"
ui_payload 'src/not-found.tsx' | CLAUDE_PROJECT_DIR="$UI_PROJ" UI_INTELLIGENCE_HOOK=1 UI_INTELLIGENCE_COMMAND="$PROVIDER" bash "$UI"
[ "$(wc -l < "$UI_CALLS")" -eq 2 ] && ok "file thiếu: không gọi provider" || bad "file thiếu vẫn gọi provider"
printf 'text\n' > "$UI_PROJ/src/readme.txt"
ui_payload 'src/readme.txt' | CLAUDE_PROJECT_DIR="$UI_PROJ" UI_INTELLIGENCE_HOOK=1 UI_INTELLIGENCE_COMMAND="$PROVIDER" bash "$UI"
[ "$(wc -l < "$UI_CALLS")" -eq 2 ] && ok "file ngoài danh sách UI: không gọi provider" || bad "file ngoài danh sách UI vẫn gọi provider"
ui_payload 'src/my component.tsx' | CLAUDE_PROJECT_DIR="$UI_PROJ" UI_INTELLIGENCE_HOOK=1 UI_INTELLIGENCE_COMMAND="$PROVIDER" UI_EXIT=9 bash "$UI"; rc=$?
[ "$rc" -eq 0 ] && [ "$(wc -l < "$UI_CALLS")" -eq 4 ] && ok "provider lỗi: edit vẫn tiếp tục" || bad "provider lỗi đã chặn edit hoặc không chạy"

if [ "$fails" -eq 0 ]; then
  echo "OK — hook session (telemetry-record, session-resume) ghi số thật, nạp gọn, không ghi trùng."
  exit 0
fi
echo "FAIL — $fails ca hỏng."
exit 1
