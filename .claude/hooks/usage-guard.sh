#!/usr/bin/env bash
# usage-guard.sh — Stop hook. Sau mỗi lượt, ước tính % quota 5h (usage-estimate.sh).
# Nếu >= ngưỡng → tiêm additionalContext nhắc AI WIND-DOWN (không chặn cứng).
# Nhắc MỘT lần/phiên (marker) để không lặp. Tự tắt khi chưa khai báo budget (OVERALL=NA).
set -uo pipefail   # cố ý KHÔNG -e: không được làm chết phiên/lượt chạy (xem docs/CONVENTIONS.md §A)

ROOT="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"
command -v jq >/dev/null 2>&1 || { echo "[usage-guard] không có jq → không đọc được transcript_path, bỏ qua cảnh báo quota." >&2; exit 0; }

payload="$(cat)"
tp="$(printf '%s' "$payload" | jq -r '.transcript_path // empty' 2>/dev/null)"
[ -n "$tp" ] || exit 0
[ -x "$ROOT/scripts/usage-estimate.sh" ] || exit 0

# Estimate lỗi → NÓI RA rồi thoát 0 (Stop hook không được chặn phiên; im lặng = mất cảnh báo quota mà không ai biết).
out="$("$ROOT/scripts/usage-estimate.sh" "$tp" 2>/dev/null)" || {
  echo "[usage-guard] usage-estimate.sh lỗi (exit $?) → bỏ qua cảnh báo quota." >&2; exit 0; }
overall="$(printf '%s' "$out" | sed -n 's/^OVERALL=//p' | head -1)"
thr="$(printf '%s' "$out" | sed -n 's/^THRESHOLD=//p' | head -1)"
[ -n "$overall" ] && [ "$overall" != "NA" ] || exit 0
[ -n "$thr" ] || thr=70

# So sánh nguyên; nếu chưa đạt ngưỡng → im lặng.
if [ "$overall" -lt "$thr" ] 2>/dev/null; then exit 0; fi

MARK="$ROOT/.claude/.winddown-nudged"
[ -f "$MARK" ] && exit 0
touch "$MARK" 2>/dev/null || true

detail="$(printf '%s' "$out" | grep -E '^(opus|sonnet|haiku|fable)=' | tr '\n' ' ')"
reason="⚠️ Ước tính đã dùng ~${overall}% quota 5h (ngưỡng ${thr}%). Chi tiết: ${detail}. WIND-DOWN NGAY: hoàn tất gọn đơn vị đang làm, commit phần đã xong (qua cổng, không commit đỏ), cập nhật PROGRESS.md mục 'Bàn giao phiên' (việc dở + bước kế tiếp cụ thể), rồi DỪNG phiên sạch sẽ. Phiên sau người dùng chỉ cần nhắn 'tiếp tục' để nối lại. KHÔNG khởi động đơn vị/merge mới."

jq -n --arg r "$reason" '{hookSpecificOutput:{hookEventName:"Stop",additionalContext:$r}}'
exit 0
