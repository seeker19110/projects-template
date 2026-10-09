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
# input = 1000+500 (cache read) + 3000 = 4500; output = 200+800 = 1000; 10:00→10:12 = 720 giây
if [ "$e" = "claude-sonnet-5 4500 1000 720.0 1" ]; then
  ok "entry = model cuối · 4500 in · 1000 out · 720 giây (không phải 1000/500 bịa)"
else
  bad "entry sai: '$e' (kỳ vọng 'claude-sonnet-5 4500 1000 720.0 1')"
fi

echo "== 2. Lượt kế KHÔNG có dòng mới → không ghi thêm (không cộng dồn cả phiên) =="
run_hook
n="$(python3 -c "import json; print(len(json.load(open('$PROJ/.ai-telemetry/telemetry.json', encoding='utf-8'))))")"
[ "$n" = "1" ] && ok "vẫn 1 entry" || bad "hook ghi trùng khi không có dòng mới: $n entry"

echo "== 3. Có dòng mới → chỉ tính phần MỚI (delta), không tính lại từ đầu =="
echo '{"type":"assistant","timestamp":"2026-09-23T10:30:00.000Z","message":{"model":"claude-sonnet-5","usage":{"input_tokens":100,"output_tokens":50}}}' >> "$TR"
run_hook
e="$(last_entry -1)"
# 10:12 → 10:30 = 1080 giây
[ "$e" = "claude-sonnet-5 100 50 1080.0 2" ] && ok "entry 2 chỉ có phần mới: 100 in · 50 out · 1080 giây" || bad "entry 2 sai: '$e'"

echo "== 4. Transcript không tồn tại / payload rỗng → thoát 0, không ghi =="
printf '{}' | CLAUDE_PROJECT_DIR="$PROJ" bash "$PROJ/.claude/hooks/telemetry-record.sh"; rc=$?
n="$(python3 -c "import json; print(len(json.load(open('$PROJ/.ai-telemetry/telemetry.json', encoding='utf-8'))))")"
[ "$rc" -eq 0 ] && [ "$n" = "2" ] && ok "payload rỗng: thoát 0, không ghi" || bad "payload rỗng: rc=$rc, entry=$n"

echo "== 4b. Lượt mới không có message.usage → token null (unknown), không ghi 0 (LD-07) =="
echo '{"type":"assistant","timestamp":"2026-09-23T10:40:00.000Z","message":{"model":"claude-sonnet-5"}}' >> "$TR"
run_hook
e="$(last_entry -1)"
[ "$e" = "claude-sonnet-5 None None 600.0 3" ] && ok "không có usage → input/output null, entry 3" || bad "không có usage bị ghi thành số: '$e'"

echo "== 5. NEGATIVE: engine đổi mặc định token về số bịa thì test này phải ĐỎ =="
sed 's/type=int, default=None)/type=int, default=777)/' "$ROOT/scripts/telemetry-log.py" > "$PROJ/scripts/telemetry-log.py"
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

echo "== 6b. session-resume: tìm hồ sơ active khi thiếu/đầy PROGRESS, không nạp done hoặc nội dung =="
P3="$WORK/work records"; mkdir -p "$P3/.claude" "$P3/docs/work/01-active" "$P3/docs/work/02-active" "$P3/docs/work/03-closed"
printf 'WORK-CONTENT-MUST-NOT-LOAD\n' > "$P3/docs/work/01-active/working.md"
printf 'NEXT-WORK-CONTENT\n' > "$P3/docs/work/02-active/working.md"
printf 'DONE-CONTENT-MUST-NOT-LOAD\n' > "$P3/docs/work/03-closed/done.md"
before="$(cksum "$P3/docs/work/01-active/working.md")"
out="$(printf '{}' | CLAUDE_PROJECT_DIR="$P3" bash "$SR")"
ctx="$(printf '%s' "$out" | jq -r '.hookSpecificOutput.additionalContext')"
for want in docs/work/01-active/working.md docs/work/02-active/working.md; do
  printf '%s' "$ctx" | grep -qF "$want" && ok "không PROGRESS vẫn có: $want" || bad "mất hồ sơ khi không PROGRESS: $want"
done
for nowant in docs/work/03-closed/done.md WORK-CONTENT-MUST-NOT-LOAD DONE-CONTENT-MUST-NOT-LOAD; do
  printf '%s' "$ctx" | grep -qF "$nowant" && bad "nạp lịch sử/nội dung ngoài scope: $nowant" || ok "không nạp: $nowant"
done
[ "$(cksum "$P3/docs/work/01-active/working.md")" = "$before" ] && ok "hook không sửa hồ sơ" || bad "hook sửa hồ sơ"
{ echo '## Đang làm / chờ'; yes -- '- oversized progress'; } | head -n 3000 > "$P3/PROGRESS.md"
out="$(printf '{}' | CLAUDE_PROJECT_DIR="$P3" SESSION_RESUME_MAX_BYTES=1200 bash "$SR")"
ctx="$(printf '%s' "$out" | jq -r '.hookSpecificOutput.additionalContext')"
for want in docs/work/01-active/working.md docs/work/02-active/working.md 'ĐÃ CẮT'; do
  printf '%s' "$ctx" | grep -qF "$want" && ok "PROGRESS dài vẫn có: $want" || bad "PROGRESS dài che hồ sơ/cảnh báo: $want"
done

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
CLAUDE_PROJECT_DIR="$UI_PROJ" UI_INTELLIGENCE_COMMAND="$PROVIDER" bash "$UI" <<< "$(ui_payload 'src/my component.tsx')"; rc=$?
[ "$rc" -eq 0 ] && [ ! -e "$UI_CALLS" ] && ok "disabled: không gọi provider" || bad "disabled: rc=$rc hoặc provider vẫn chạy"
CLAUDE_PROJECT_DIR="$UI_PROJ" UI_INTELLIGENCE_HOOK=1 UI_INTELLIGENCE_COMMAND="$PROVIDER" bash "$UI" <<< "$(ui_payload 'src/my component.tsx')"; rc=$?
[ "$rc" -eq 0 ] && [ "$(cat "$UI_CALLS")" = "$(printf 'detect\n%s' "$UI_FILE")" ] && ok "enabled: gọi đúng file UI có khoảng trắng" || bad "enabled: sai command/path hoặc exit $rc"
CLAUDE_PROJECT_DIR="$UI_PROJ" UI_INTELLIGENCE_HOOK=1 UI_INTELLIGENCE_COMMAND="$PROVIDER" bash "$UI" <<< "$(ui_payload 'src/not-found.tsx')"
[ "$(wc -l < "$UI_CALLS")" -eq 2 ] && ok "file thiếu: không gọi provider" || bad "file thiếu vẫn gọi provider"
printf 'text\n' > "$UI_PROJ/src/readme.txt"
CLAUDE_PROJECT_DIR="$UI_PROJ" UI_INTELLIGENCE_HOOK=1 UI_INTELLIGENCE_COMMAND="$PROVIDER" bash "$UI" <<< "$(ui_payload 'src/readme.txt')"
[ "$(wc -l < "$UI_CALLS")" -eq 2 ] && ok "file ngoài danh sách UI: không gọi provider" || bad "file ngoài danh sách UI vẫn gọi provider"
CLAUDE_PROJECT_DIR="$UI_PROJ" UI_INTELLIGENCE_HOOK=1 UI_INTELLIGENCE_COMMAND="$PROVIDER" UI_EXIT=9 bash "$UI" <<< "$(ui_payload 'src/my component.tsx')"; rc=$?
[ "$rc" -eq 0 ] && [ "$(wc -l < "$UI_CALLS")" -eq 4 ] && ok "provider lỗi: edit vẫn tiếp tục" || bad "provider lỗi đã chặn edit hoặc không chạy"

echo "== 10. Thiếu jq/python hoặc engine lỗi → thoát 0 nhưng PHẢI cảnh báo stderr (không im lặng) =="
# VÌ SAO (O-2 P-A2, 2026-10-08): session-guide/usage-guard/telemetry-record thoát 0 IM LẶNG khi thiếu công cụ hoặc
# telemetry-log.sh lỗi → người dùng mất gợi ý/cảnh báo quota/số đo mà không ai biết. Khuôn chung các hook khác:
# fail-open nhưng NÓI RA (`[tên-hook] không có jq → … bỏ qua.`).
mkbin() {   # mkbin <thư mục> <lệnh…> — PATH tối giản chỉ có đúng các lệnh liệt kê (symlink, dự phòng cp)
  local d="$1" b src; shift; mkdir -p "$d"
  for b in "$@"; do
    src="$(command -v "$b" 2>/dev/null)" && [ -n "$src" ] && { ln -sf "$src" "$d/$b" 2>/dev/null || cp "$src" "$d/$b"; }
  done
}
NOJQ="$WORK/bin-nojq"; mkbin "$NOJQ" bash cat dirname
for h in session-guide usage-guard telemetry-record; do
  printf '{}' | env -i PATH="$NOJQ" CLAUDE_PROJECT_DIR="$PROJ" bash "$ROOT/.claude/hooks/$h.sh" >/dev/null 2>"$WORK/err.txt"; rc=$?
  if [ "$rc" -eq 0 ] && grep -q "^\[$h\] không có jq" "$WORK/err.txt"; then ok "$h: thiếu jq → exit 0 + cảnh báo"
  else bad "$h: thiếu jq → rc=$rc, stderr='$(head -c 200 "$WORK/err.txt")' (kỳ vọng exit 0 + '[$h] không có jq')"; fi
done
NOPY="$WORK/bin-nopy"; mkbin "$NOPY" bash cat dirname jq
printf '{"transcript_path":"%s"}' "$TR" | env -i PATH="$NOPY" CLAUDE_PROJECT_DIR="$PROJ" bash "$PROJ/.claude/hooks/telemetry-record.sh" >/dev/null 2>"$WORK/err.txt"; rc=$?
[ "$rc" -eq 0 ] && grep -q '^\[telemetry-record\] không có python' "$WORK/err.txt" && ok "telemetry-record: thiếu python → exit 0 + cảnh báo" \
  || bad "telemetry-record: thiếu python → rc=$rc, stderr='$(head -c 200 "$WORK/err.txt")'"
# Chỉ có `python` (không có python3 — Windows/một số distro): phải ghi được như _python-exec.sh.
ONLYPY="$WORK/bin-onlypy"; mkbin "$ONLYPY" bash cat dirname jq git mkdir cksum cut
ln -sf "$(command -v python3)" "$ONLYPY/python"
P4="$WORK/proj-onlypy"; mkdir -p "$P4/.claude/hooks"; cp -R "$PROJ/scripts" "$P4/"; cp "$PROJ/.claude/hooks/telemetry-record.sh" "$P4/.claude/hooks/"
rm -f "$P4"/scripts/*.tmp 2>/dev/null
printf '{"transcript_path":"%s"}' "$TR" | env -i PATH="$ONLYPY" CLAUDE_PROJECT_DIR="$P4" bash "$P4/.claude/hooks/telemetry-record.sh" >/dev/null 2>"$WORK/err.txt"; rc=$?
n="$(python3 -c "import json; print(len(json.load(open('$P4/.ai-telemetry/telemetry.json', encoding='utf-8'))))" 2>/dev/null)"
[ "$rc" -eq 0 ] && [ "$n" = "1" ] && ok "telemetry-record: chỉ có 'python' vẫn ghi được 1 entry" \
  || bad "telemetry-record: chỉ có 'python' → rc=$rc, entry='$n', stderr='$(head -c 200 "$WORK/err.txt")'"
# telemetry-log.sh lỗi → lỗi phải hiện ra stderr có tiền tố, hook vẫn exit 0 (hook Stop không được làm chết phiên).
P5="$WORK/proj-badlog"; mkdir -p "$P5/scripts" "$P5/.claude/hooks"; cp "$PROJ/.claude/hooks/telemetry-record.sh" "$P5/.claude/hooks/"
printf '#!/usr/bin/env bash\necho "LOI-ENGINE-GIA" >&2\nexit 3\n' > "$P5/scripts/telemetry-log.sh"; chmod +x "$P5/scripts/telemetry-log.sh"
printf '{"transcript_path":"%s"}' "$TR" | CLAUDE_PROJECT_DIR="$P5" bash "$P5/.claude/hooks/telemetry-record.sh" >/dev/null 2>"$WORK/err.txt"; rc=$?
[ "$rc" -eq 0 ] && grep -q '^\[telemetry-record\].*LOI-ENGINE-GIA' "$WORK/err.txt" && ok "telemetry-log.sh lỗi → exit 0 + lỗi engine hiện ra stderr có tiền tố" \
  || bad "telemetry-log.sh lỗi → rc=$rc, stderr='$(head -c 200 "$WORK/err.txt")' (kỳ vọng exit 0 + '[telemetry-record] … LOI-ENGINE-GIA')"
[ ! -f "$P5/.ai-telemetry/last-stop-$(printf '%s' "$TR" | git hash-object --stdin)" ] && ok "engine lỗi → KHÔNG dời mốc (lượt sau ghi lại được)" \
  || bad "engine lỗi mà mốc vẫn bị dời → mất số đo lượt này"

# usage-estimate.sh lỗi → usage-guard nói ra (exit code) rồi exit 0, không nuốt im lặng (O-4b 2026-10-08).
P6="$WORK/proj-badest"; mkdir -p "$P6/scripts" "$P6/.claude/hooks"; cp "$ROOT/.claude/hooks/usage-guard.sh" "$P6/.claude/hooks/"
printf '#!/usr/bin/env bash\nexit 4\n' > "$P6/scripts/usage-estimate.sh"; chmod +x "$P6/scripts/usage-estimate.sh"
printf '{"transcript_path":"%s"}' "$TR" | CLAUDE_PROJECT_DIR="$P6" bash "$P6/.claude/hooks/usage-guard.sh" >"$WORK/out.txt" 2>"$WORK/err.txt"; rc=$?
[ "$rc" -eq 0 ] && [ ! -s "$WORK/out.txt" ] && grep -q '^\[usage-guard\] usage-estimate.sh lỗi (exit 4)' "$WORK/err.txt" \
  && ok "usage-estimate.sh lỗi → exit 0 + cảnh báo stderr có exit code" \
  || bad "usage-estimate.sh lỗi → rc=$rc, stderr='$(head -c 200 "$WORK/err.txt")' (kỳ vọng exit 0 + '[usage-guard] usage-estimate.sh lỗi (exit 4)')"

# ── 11. session-guide: gợi ý theo trạng thái thật ───────────────────────────────
echo "== 11. session-guide: gợi ý theo trạng thái thật (có GĐ / chưa có tiến độ / không phải dự án khung) =="
# guide_ok <hook> <proj>: 0 nếu hook thoát 0 và systemMessage chứa GĐ + model thật (phép kiểm (a)).
guide_ok() {
  local out
  out="$(printf '{"model":"claude-test-model"}' | CLAUDE_PROJECT_DIR="$2" bash "$1" 2>/dev/null)" || return 1
  printf '%s' "$out" | jq -e '.systemMessage' >/dev/null 2>&1 || return 1
  printf '%s' "$out" | jq -r '.systemMessage' | grep -qF 'GĐ 3 — thử nghiệm' || return 1
  printf '%s' "$out" | jq -r '.systemMessage' | grep -qF 'Model phiên: claude-test-model' || return 1
}
G1="$WORK/guide-phase"; mkdir -p "$G1/docs/framework" "$G1/.claude/hooks"
printf '# Tiến độ\n\n## Giai đoạn hiện tại\n- Giai đoạn: GĐ 3 — thử nghiệm\n\n## Khác\n' > "$G1/PROGRESS.md"
cp "$ROOT/.claude/hooks/session-guide.sh" "$G1/.claude/hooks/"
guide_ok "$G1/.claude/hooks/session-guide.sh" "$G1" && ok "session-guide: có GĐ + model trong systemMessage" \
  || bad "session-guide: không hiện 'GĐ 3 — thử nghiệm' + 'Model phiên: claude-test-model'"
printf '#!/usr/bin/env bash\nexit 0\n' > "$WORK/guide-empty.sh"
guide_ok "$WORK/guide-empty.sh" "$G1" && bad "negative: hook rỗng mà phép kiểm (a) vẫn xanh (xanh giả)" \
  || ok "negative: hook rỗng bị phép kiểm session-guide bắt"

G2="$WORK/guide-nostate"; mkdir -p "$G2/docs/framework"
out="$(printf '{}' | CLAUDE_PROJECT_DIR="$G2" bash "$ROOT/.claude/hooks/session-guide.sh" 2>/dev/null)"; rc=$?
[ "$rc" -eq 0 ] && printf '%s' "$out" | jq -r '.systemMessage' | grep -qF 'Chưa có tiến độ' \
  && ok "session-guide: chưa có tiến độ → gợi ý bắt đầu" || bad "session-guide: chưa có tiến độ → rc=$rc, out='$(printf '%s' "$out" | head -c 200)'"

G3="$WORK/guide-foreign"; mkdir -p "$G3"
out="$(printf '{}' | CLAUDE_PROJECT_DIR="$G3" bash "$ROOT/.claude/hooks/session-guide.sh" 2>/dev/null)"; rc=$?
[ "$rc" -eq 0 ] && [ -z "$out" ] && ok "session-guide: không phải dự án khung → exit 0, stdout rỗng" \
  || bad "session-guide: không marker → rc=$rc, stdout='$(printf '%s' "$out" | head -c 200)'"

# ── 12. auto-format ─────────────────────────────────────────────────────────────
echo "== 12. auto-format: gọi dev-task.sh format-file đúng file, no-op khi thiếu đường dẫn/dev-task =="
AF="$WORK/af"; mkdir -p "$AF/scripts"
printf '#!/usr/bin/env bash\nprintf "%%s\\n" "$@" > "$AF_LOG"\nexit "${AF_RC:-0}"\n' > "$AF/scripts/dev-task.sh"; chmod +x "$AF/scripts/dev-task.sh"
HOOK="$ROOT/.claude/hooks/auto-format.sh"
rm -f "$WORK/af.log"
printf '{"tool_input":{"file_path":"src/a b.ts"}}' | AF_LOG="$WORK/af.log" CLAUDE_PROJECT_DIR="$AF" bash "$HOOK" >/dev/null 2>&1; rc=$?
[ "$rc" -eq 0 ] && [ "$(wc -l < "$WORK/af.log")" -eq 2 ] && [ "$(sed -n 1p "$WORK/af.log")" = "format-file" ] && [ "$(sed -n 2p "$WORK/af.log")" = "src/a b.ts" ] \
  && ok "auto-format: gọi 'format-file' đúng file (giữ khoảng trắng)" || bad "auto-format: rc=$rc, log='$(cat "$WORK/af.log" 2>/dev/null)'"
rm -f "$WORK/af.log"
printf '{}' | AF_LOG="$WORK/af.log" CLAUDE_PROJECT_DIR="$AF" bash "$HOOK" >/dev/null 2>&1; rc=$?
[ "$rc" -eq 0 ] && [ ! -e "$WORK/af.log" ] && ok "auto-format: thiếu đường dẫn → exit 0, không gọi dev-task" || bad "auto-format: payload {} → rc=$rc, stub bị gọi=$([ -e "$WORK/af.log" ] && echo có || echo không)"
AF2="$WORK/af-nostub"; mkdir -p "$AF2"
printf '{"tool_input":{"file_path":"x.ts"}}' | CLAUDE_PROJECT_DIR="$AF2" bash "$HOOK" >/dev/null 2>"$WORK/err.txt"; rc=$?
[ "$rc" -eq 0 ] && grep -qF '[auto-format] không thấy scripts/dev-task.sh' "$WORK/err.txt" && ok "auto-format: thiếu dev-task.sh → exit 0 + cảnh báo stderr" \
  || bad "auto-format: thiếu dev-task.sh → rc=$rc, stderr='$(head -c 200 "$WORK/err.txt")'"
printf '{"tool_input":{"file_path":"x.ts"}}' | AF_RC=7 AF_LOG="$WORK/af.log" CLAUDE_PROJECT_DIR="$AF" bash "$HOOK" >/dev/null 2>&1; rc=$?
[ "$rc" -eq 0 ] && ok "auto-format: dev-task exit 7 → hook vẫn exit 0 (best-effort)" || bad "auto-format: dev-task lỗi làm hook exit $rc"

finish "hook session (telemetry-record, session-resume, session-guide, auto-format) ghi số thật, nạp gọn, không ghi trùng, no-op đúng chỗ."
