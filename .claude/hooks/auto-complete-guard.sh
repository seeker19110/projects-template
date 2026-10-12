#!/usr/bin/env bash
# auto-complete-guard.sh — Stop hook GIỮ VÒNG /auto-complete: khi lượt /auto-complete đang bật (marker
# .claude/.auto-complete-loop do lệnh ghi, gitignored) mà hồ sơ docs/work/<id>/working.md còn `Active`, hook trả
# {"decision":"block"} để Claude KHÔNG kết lượt sớm và nối tiếp đúng mục "Bàn giao / bước tiếp theo".
#
# VÌ SAO (đối chiếu vòng lặp coding 2026-10-12, N2): "/auto-complete chỉ dừng ở §9/BLOCKED" trước đó chỉ là văn xuôi; mọi
# nguồn (plugin ralph chính thức, /goal của Claude Code, Codex Goals) cưỡng chế "không dừng khi chưa xong" bằng Stop hook.
# Khác ralph: tín hiệu DỪNG đọc từ FILE TRẠNG THÁI §3e, không từ chuỗi `<promise>` model in ra (CLAUDE.md §4 không tin
# lời khai). Giới hạn nói thật: dòng `- Trạng thái:` vẫn do model ghi — nhưng là artifact bắt buộc, đi cùng PR, người
# dùng audit được; hook là lưới đỡ cho "quên tiếp tục", không phải hàng rào chống model cố né.
#
# CHO DỪNG khi một trong các điều kiện (thứ tự kiểm): không marker · hồ sơ không còn working.md (đã done.md → xoá marker) ·
# `- Trạng thái: Blocked|Waiting|Done|Ready` (neo đầu giá trị) · usage-guard đã nhắc wind-down · đã đủ AUTO_COMPLETE_MAX_CONTINUES
# (mặc định 20; /goal của Claude Code cũng khuyên trần ~20 lượt) · lời cuối lặp y hệt lượt trước (không tiến triển — Codex
# Goals "no tool call → suppress") · chuỗi đỏ cổng commit ≥ 3 (.claude/.gate-red-streak) đã được nhắc §8 một lần.
# Claude Code tự có trần 8 lần block liên tiếp không tool call (CLAUDE_CODE_STOP_HOOK_BLOCK_CAP) — lớp đỡ thứ hai.
# Fail-open có cảnh báo khi thiếu jq (docs/CONVENTIONS.md §A). Test: scripts/test-hooks-loop.sh.
set -uo pipefail   # cố ý KHÔNG -e: không được làm chết phiên/lượt chạy

# ROOT = cây ĐANG làm việc (worktree, TRAPS 45); CLAUDE_PROJECT_DIR chỉ là chỗ lùi về.
ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"
[ -n "$ROOT" ] || ROOT="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"
MARK="$ROOT/.claude/.auto-complete-loop"
[ -f "$MARK" ] || exit 0
command -v jq >/dev/null 2>&1 || { echo "[auto-complete-guard] không có jq → không đọc được payload Stop, KHÔNG giữ được vòng /auto-complete (tự nối bằng tay)." >&2; exit 0; }

payload="$(cat 2>/dev/null || true)"
last="$(printf '%s' "$payload" | jq -r '.last_assistant_message // ""' 2>/dev/null | cksum | cut -d' ' -f1)"
MAX="${AUTO_COMPLETE_MAX_CONTINUES:-20}"; case "$MAX" in ''|*[!0-9]*) MAX=20 ;; esac

id="$(sed -n 1p "$MARK" | tr -d '[:space:]')"
n="$(sed -n 's/^n=//p' "$MARK" | head -1)"; case "$n" in ''|*[!0-9]*) n=0 ;; esac
prev_last="$(sed -n 's/^last=//p' "$MARK" | head -1)"
nudged="$(sed -n 's/^nudged=//p' "$MARK" | head -1)"
WF="$ROOT/docs/work/$id/working.md"

save()  { printf '%s\nn=%s\nlast=%s\nnudged=%s\n' "$id" "$1" "$2" "$3" > "$MARK" 2>/dev/null || true; }
allow() { echo "[auto-complete-guard] $1" >&2; exit 0; }   # exit 0 không JSON = cho dừng
block() { jq -n --arg r "$1" '{decision:"block", reason:$r}'; exit 0; }

[ -n "$id" ] || allow "marker không có Work ID → bỏ qua."
[ -f "$WF" ] || { rm -f "$MARK"; allow "hồ sơ $id không còn working.md (đã đổi thành done.md?) → tắt vòng, cho dừng."; }
status="$(grep -m1 -E '^- Trạng thái:' "$WF" 2>/dev/null || true)"
if printf '%s' "$status" | grep -Eq '^- Trạng thái:[[:space:]]*(Blocked|Waiting|Done|Ready)'; then
  allow "hồ sơ $id ở trạng thái dừng hợp lệ ('$status') → cho dừng; marker giữ để nối lại sau khi có quyết định."
fi
[ -f "$ROOT/.claude/.winddown-nudged" ] && allow "usage-guard đã nhắc wind-down (quota) → cho dừng; phiên sau nhắn 'tiếp tục'."
[ "$n" -ge "$MAX" ] && allow "đã $n/$MAX lượt tiếp tục trong lần bật này → cho dừng (trần AUTO_COMPLETE_MAX_CONTINUES); gõ /auto-complete để nối."
[ -n "$prev_last" ] && [ "$last" = "$prev_last" ] && allow "lời cuối lượt lặp y hệt lượt trước (không tiến triển) → cho dừng, tránh vòng kẹt."

streak="$(sed -n 's/^n=//p' "$ROOT/.claude/.gate-red-streak" 2>/dev/null | head -1)"; case "$streak" in ''|*[!0-9]*) streak=0 ;; esac
if [ "$streak" -ge 3 ]; then
  [ "$nudged" = "1" ] && allow "chuỗi đỏ cổng commit ≥ 3 đã nhắc §8 → cho dừng."
  save "$n" "$last" 1
  block "/auto-complete: cổng commit đã đỏ $streak lần liên tiếp CÙNG một failure — §8 BLOCKED: không sửa mù thêm. Ghi '- Trạng thái: Blocked — <failure + giả thuyết đã bác bỏ>' vào docs/work/$id/working.md, nêu lựa chọn + đề xuất cho người dùng, rồi kết lượt (hook sẽ cho dừng)."
fi

save $((n + 1)) "$last" "$nudged"
excerpt="$(awk '/^## Bàn giao/{f=1; next} /^## /{f=0} f' "$WF" 2>/dev/null | grep -v '^[[:space:]]*$' | head -12)"
block "/auto-complete đang bật (hồ sơ $id, lượt tiếp tục $((n + 1))/$MAX): hồ sơ còn Active → chưa được kết lượt. Nối tiếp đúng chỗ dở theo 'Bàn giao / bước tiếp theo':
${excerpt:-(mục Bàn giao trống — ghi bước kế tiếp cụ thể trước)}
Chỉ dừng khi §9/§8: ghi '- Trạng thái: Blocked — <lý do>' hoặc 'Waiting — <chờ gì>' vào working.md rồi kết lượt; DoC đạt + mọi PR merge → rename done.md và rm .claude/.auto-complete-loop. Không tuyên bố xong mà không chạy lệnh chứng minh (CLAUDE.md §4)."
