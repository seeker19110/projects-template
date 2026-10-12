#!/usr/bin/env bash
# test-hooks-loop.sh — Kiểm hook GIỮ VÒNG /auto-complete (.claude/hooks/auto-complete-guard.sh, sự kiện Stop) và phần
# dọn marker của session-resume.sh. Hook không chặn lệnh nào nên hỏng im lặng không ai thấy (cùng lý do test-hooks-session.sh).
#
# VÌ SAO (đối chiếu vòng lặp coding 2026-10-12, N2): "/auto-complete chỉ dừng ở §9/BLOCKED" trước đó là văn xuôi — không gì
# ngăn lượt kết thúc sớm, người dùng phải gõ "tiếp tục". Tín hiệu DỪNG đọc từ FILE TRẠNG THÁI §3e (working.md
# Blocked/Waiting, hoặc đã rename done.md), trần lượt, wind-down quota, chuỗi đỏ ≥ 3 của cổng commit, lời cuối lặp y hệt —
# KHÔNG đọc chuỗi `<promise>` model in ra (CLAUDE.md §4).
#
# Chạy: bash scripts/test-hooks-loop.sh
set -uo pipefail   # cố ý KHÔNG -e (docs/CONVENTIONS.md §A)

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
# shellcheck source=scripts/_test-lib.sh
source "$ROOT/scripts/_test-lib.sh"
HOOK="$ROOT/.claude/hooks/auto-complete-guard.sh"
SR="$ROOT/.claude/hooks/session-resume.sh"

if ! command -v jq >/dev/null 2>&1; then
  echo "::error::Cần jq để kiểm hook giữ vòng (hook fail-open khi thiếu — test này không được xanh giả)."
  exit 1
fi
[ -f "$HOOK" ] || { echo "❌ thiếu $HOOK"; exit 1; }

ID="2026-10-12-giả"
new_proj() {   # dự án giả: repo git + hồ sơ Active + marker /auto-complete
  local p="$WORK/p-$RANDOM-$RANDOM"
  mkdir -p "$p/.claude" "$p/docs/work/$ID"; git -C "$p" init -q 2>/dev/null
  printf '# Công việc: x\n\n- Work ID: %s\n- Trạng thái: Active (đang làm)\n\n## Bàn giao / bước tiếp theo\n\nBUOC-KE-TIEP-DAC-THU\n' "$ID" > "$p/docs/work/$ID/working.md"
  printf '%s\n' "$ID" > "$p/.claude/.auto-complete-loop"
  printf '%s\n' "$p"
}
run_guard() {   # $1 = dự án, $2 = last_assistant_message, [$3 = stop_hook_active] → stdout JSON; stderr vào $WORK/err
  # Here-string, KHÔNG `jq | hook`: hook `exit 0` trước khi đọc stdin (không marker) → jq ghi vào pipe đã đóng → SIGPIPE,
  # pipefail biến thành rc=141 (tái hiện 13/400 lượt, chặn oan cổng commit 2026-10-12).
  local pl; pl="$(jq -cn --arg m "$2" --argjson a "${3:-false}" '{last_assistant_message:$m, stop_hook_active:$a}')"
  ( cd "$1" && CLAUDE_PROJECT_DIR="$1" bash "$HOOK" 2>"$WORK/err" <<<"$pl" )
}
decision() {   # exit 0 không JSON = allow (jq với input rỗng không in gì → phải xử lý riêng)
  [ -n "$1" ] || { echo allow; return; }
  printf '%s' "$1" | jq -r '.decision // "allow"' 2>/dev/null || echo "không-phải-JSON"
}

echo "== 1. Không có marker → không can thiệp (exit 0, không JSON) =="
p="$(new_proj)"; rm -f "$p/.claude/.auto-complete-loop"
out="$(run_guard "$p" "xong")"; rc=$?
[ "$rc" -eq 0 ] && [ -z "$out" ] && ok "không marker: im lặng" || bad "không marker vẫn can thiệp (rc=$rc, out=$out)"

echo "== 2. Marker + hồ sơ Active → CHẶN kết lượt, reason mang mục 'Bàn giao', đếm lượt =="
p="$(new_proj)"
out="$(run_guard "$p" "tôi nghĩ xong rồi")"
[ "$(decision "$out")" = "block" ] && ok "decision=block" || bad "không block: $out"
printf '%s' "$out" | jq -r '.reason' | grep -q "BUOC-KE-TIEP-DAC-THU" && ok "reason có mục Bàn giao / bước tiếp theo" || bad "reason thiếu bước kế tiếp"
grep -q '^n=1$' "$p/.claude/.auto-complete-loop" && ok "lượt tiếp tục = 1" || bad "không đếm lượt: $(cat "$p/.claude/.auto-complete-loop")"
printf '%s' "$out" | jq -r '.reason' | grep -q "1/20" && ok "reason ghi 1/20 (trần mặc định 20)" || bad "reason không ghi lượt/trần"

echo "== 3. Hồ sơ Blocked / Waiting → cho dừng; 'Active (chưa done)' KHÔNG bị nhận nhầm là Done =="
for st in "Blocked — chờ chủ repo quyết" "Waiting (chờ CI)"; do
  p="$(new_proj)"; sed -i "s/^- Trạng thái: .*/- Trạng thái: $st/" "$p/docs/work/$ID/working.md"
  out="$(run_guard "$p" "dừng")"
  [ "$(decision "$out")" = "allow" ] && grep -q "cho dừng" "$WORK/err" && ok "trạng thái '$st' → cho dừng" || bad "'$st' vẫn block: $out"
done
p="$(new_proj)"; sed -i "s/^- Trạng thái: .*/- Trạng thái: Active (chưa done, còn waiting CI ở bước 3)/" "$p/docs/work/$ID/working.md"
out="$(run_guard "$p" "x")"
[ "$(decision "$out")" = "block" ] && ok "'Active (chưa done…)' vẫn block (so khớp neo đầu giá trị)" || bad "chữ done/waiting giữa câu làm hook cho dừng nhầm"

echo "== 4. working.md đã rename done.md → tắt vòng (xoá marker), cho dừng =="
p="$(new_proj)"; mv "$p/docs/work/$ID/working.md" "$p/docs/work/$ID/done.md"
out="$(run_guard "$p" "xong")"
[ "$(decision "$out")" = "allow" ] && [ ! -f "$p/.claude/.auto-complete-loop" ] && ok "done.md → marker bị xoá, cho dừng" || bad "done.md: $out / marker $(ls "$p/.claude")"

echo "== 5. Trần lượt (AUTO_COMPLETE_MAX_CONTINUES) → cho dừng kèm cảnh báo =="
p="$(new_proj)"; printf '%s\nn=3\nlast=\nnudged=\n' "$ID" > "$p/.claude/.auto-complete-loop"
out="$( cd "$p" && printf '{"last_assistant_message":"x"}' | AUTO_COMPLETE_MAX_CONTINUES=3 CLAUDE_PROJECT_DIR="$p" bash "$HOOK" 2>"$WORK/err" )"
[ "$(decision "$out")" = "allow" ] && grep -q "3/3" "$WORK/err" && ok "chạm trần 3/3 → cho dừng, nói rõ" || bad "trần không hiệu lực: $out $(cat "$WORK/err")"

echo "== 6. Lời cuối lặp y hệt lượt trước (không tiến triển) → cho dừng =="
p="$(new_proj)"
run_guard "$p" "Đã hoàn thành." >/dev/null
out="$(run_guard "$p" "Đã hoàn thành.")"
[ "$(decision "$out")" = "allow" ] && grep -qi "lặp" "$WORK/err" && ok "lặp y hệt → cho dừng" || bad "lặp y hệt vẫn block: $out"
out="$(run_guard "$p" "Khác hẳn, đang sửa test.")"
[ "$(decision "$out")" = "block" ] && ok "lời khác → vẫn giữ vòng" || bad "lời khác bị coi là lặp: $out"

echo "== 7. Chuỗi đỏ cổng commit ≥ 3 → nhắc §8 BLOCKED một lần (block), lần sau cho dừng =="
p="$(new_proj)"; printf 'n=3\nsig=FAIL: x\n' > "$p/.claude/.gate-red-streak"
out="$(run_guard "$p" "sửa tiếp lần 4")"
[ "$(decision "$out")" = "block" ] && printf '%s' "$out" | jq -r '.reason' | grep -q "BLOCKED" && ok "chuỗi đỏ 3: block một lần với lời nhắc §8" || bad "chuỗi đỏ: $out"
out="$(run_guard "$p" "sửa tiếp lần 5")"
[ "$(decision "$out")" = "allow" ] && ok "chuỗi đỏ 3 đã nhắc → cho dừng (không giữ vòng kẹt)" || bad "chuỗi đỏ vẫn block lần 2: $out"

echo "== 8. usage-guard đã nhắc wind-down → cho dừng =="
p="$(new_proj)"; touch "$p/.claude/.winddown-nudged"
out="$(run_guard "$p" "x")"
[ "$(decision "$out")" = "allow" ] && grep -qi "wind-down" "$WORK/err" && ok "wind-down → cho dừng" || bad "wind-down vẫn block: $out"

echo "== 9. Thiếu jq → fail-open NHƯNG phải nói ra (stderr) =="
mkdir -p "$WORK/nojq"; for b in bash cat printf grep sed awk git cksum cut head tr dirname mktemp rm; do
  src="$(command -v "$b" 2>/dev/null)" && [ -n "$src" ] && ln -sf "$src" "$WORK/nojq/$b"; done
p="$(new_proj)"
if env -i PATH="$WORK/nojq" bash -c 'true' 2>/dev/null; then
  ( cd "$p" && printf '{}' | env -i PATH="$WORK/nojq" CLAUDE_PROJECT_DIR="$p" bash "$HOOK" >"$WORK/out" 2>"$WORK/err" ); rc=$?
  [ "$rc" -eq 0 ] && grep -q "jq" "$WORK/err" && ok "thiếu jq: exit 0 + cảnh báo" || bad "thiếu jq: rc=$rc err=$(cat "$WORK/err")"
else
  ok "(bỏ qua ca thiếu jq: PATH giả không chạy được trên máy này)"
fi

echo "== 10. session-resume: phiên MỚI xoá marker (và nói ra); compact/resume GIỮ marker =="
for src in startup clear; do
  p="$(new_proj)"; printf '## Đang làm / chờ\n- x\n' > "$p/PROGRESS.md"
  ( cd "$p" && printf '{"source":"%s"}' "$src" | CLAUDE_PROJECT_DIR="$p" bash "$SR" >/dev/null 2>"$WORK/err" )
  [ ! -f "$p/.claude/.auto-complete-loop" ] && grep -q "auto-complete" "$WORK/err" && ok "source=$src → xoá marker + nói ra" || bad "source=$src: marker còn/không báo ($(cat "$WORK/err"))"
done
for src in compact resume; do
  p="$(new_proj)"; printf '## Đang làm / chờ\n- x\n' > "$p/PROGRESS.md"
  ( cd "$p" && printf '{"source":"%s"}' "$src" | CLAUDE_PROJECT_DIR="$p" bash "$SR" >/dev/null 2>&1 )
  [ -f "$p/.claude/.auto-complete-loop" ] && ok "source=$src → giữ marker (vòng đang chạy không bị tắt khi nén)" || bad "source=$src xoá mất marker"
done

echo "== 11. NEGATIVE: hook rỗng (luôn exit 0, không JSON) PHẢI bị mục 2 bắt =="
printf '#!/usr/bin/env bash\nexit 0\n' > "$WORK/fake-hook.sh"
p="$(new_proj)"
out="$( cd "$p" && printf '{"last_assistant_message":"x"}' | CLAUDE_PROJECT_DIR="$p" bash "$WORK/fake-hook.sh" 2>/dev/null )"
[ "$(decision "$out")" = "allow" ] && ok "negative: hook rỗng cho 'allow' → mục 2 sẽ đỏ với hook như vậy" || bad "negative: phép đo không phân biệt được hook rỗng"

finish "hook giữ vòng /auto-complete: giữ khi Active, dừng theo file trạng thái/trần/wind-down/chuỗi đỏ/không tiến triển."
