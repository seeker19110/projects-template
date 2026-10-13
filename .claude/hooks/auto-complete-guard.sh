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
# VÂN TAY (ADR-0012): khi có engine (python3 + scripts/loop-state.py) "không tiến triển" đo bằng ARTIFACT (HEAD, working.md,
# PR mở, file dở — `loop-state.sh --fingerprint`) không đổi 2 lượt liên tiếp, KHÔNG bằng lời cuối: model đổi câu chữ mỗi lượt
# vẫn có thể đứng yên, còn lời lặp có thể là việc thật đang chạy. Không engine → lùi về cksum lời cuối như cũ.
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
prev_fp="$(sed -n 's/^fp=//p' "$MARK" | head -1)"
fpn="$(sed -n 's/^fpn=//p' "$MARK" | head -1)"; case "$fpn" in ''|*[!0-9]*) fpn=0 ;; esac
fp=""
WF="$ROOT/docs/work/$id/working.md"

save()  { printf '%s\nn=%s\nlast=%s\nnudged=%s\nfp=%s\nfpn=%s\n' "$id" "$1" "$2" "$3" "$fp" "$fpn" > "$MARK" 2>/dev/null || true; }
allow() { echo "[auto-complete-guard] $1" >&2; exit 0; }   # exit 0 không JSON = cho dừng
block() { jq -n --arg r "$1" '{decision:"block", reason:$r}'; exit 0; }

[ -n "$id" ] || allow "marker không có Work ID → bỏ qua."
[ -f "$WF" ] || { rm -f "$MARK"; allow "hồ sơ $id không còn working.md (đã đổi thành done.md?) → tắt vòng, cho dừng."; }
status="$(grep -m1 -E '^- Trạng thái:' "$WF" 2>/dev/null || true)"
if grep -Eq '^- Trạng thái:[[:space:]]*(Blocked|Waiting|Done|Ready)' <<<"$status"; then   # here-string: TRAPS 71
  fp="$prev_fp" fpn=0 save "0" "$last" "$nudged"   # n=0, fpn=0 để nối lại sau quyết định đếm từ đầu; giữ vân tay
  allow "hồ sơ $id ở trạng thái dừng hợp lệ ('$status') → cho dừng; marker giữ để nối lại sau khi có quyết định."
fi
echo "[auto-complete-guard] stop_hook_active=$(printf '%s' "$payload" | jq -r '.stop_hook_active // false' 2>/dev/null)" >&2
[ -f "$ROOT/.claude/.winddown-nudged" ] && allow "usage-guard đã nhắc wind-down (quota) → cho dừng; phiên sau nhắn 'tiếp tục'."
[ "$n" -ge "$MAX" ] && allow "đã $n/$MAX lượt tiếp tục trong lần bật này → cho dừng (trần AUTO_COMPLETE_MAX_CONTINUES); gõ /auto-complete để nối."
# Planned đứng SAU wind-down/trần (không kẹt block vô hạn) và vẫn đếm n (review PR-B F2).
if grep -Eq '^- Trạng thái:[[:space:]]*Planned' <<<"$status"; then
  fp="$prev_fp" save $((n + 1)) "$last" "$nudged"
  block "/auto-complete: hồ sơ $id chưa bắt đầu (Planned) — đổi '- Trạng thái: Active' và làm bước đầu tiên theo 'Kế hoạch và phân công'."
fi

# Đo tiến triển: có engine → vân tay artifact; không → lời cuối lặp y hệt (cksum). Hàm đặt fp/fpn.
measure_progress() {
  local py=""
  command -v python3 >/dev/null 2>&1 && py=1; command -v python >/dev/null 2>&1 && py=1
  [ -n "$py" ] && [ -f "$ROOT/scripts/loop-state.py" ] && fp="$(bash "$ROOT/scripts/loop-state.sh" --root "$ROOT" --work-id "$id" --fingerprint 2>/dev/null)"
  if [ -n "$fp" ]; then
    if [ "$fp" = "$prev_fp" ]; then fpn=$((fpn + 1)); else fpn=0; fi
    if [ "$fpn" -ge 2 ]; then
      save "$n" "$last" "$nudged"
      allow "vân tay artifact không đổi 2 lượt liên tiếp (không tiến triển theo artifact: HEAD/working.md/PR mở/file dở) → cho dừng; ghi Bàn giao cụ thể rồi gõ /auto-complete để nối."
    fi
  elif [ -n "$prev_last" ] && [ "$last" = "$prev_last" ]; then
    allow "lời cuối lượt lặp y hệt lượt trước (không tiến triển) → cho dừng, tránh vòng kẹt."
  fi
}
measure_progress

streak="$(sed -n 's/^n=//p' "$ROOT/.claude/.gate-red-streak" 2>/dev/null | head -1)"; case "$streak" in ''|*[!0-9]*) streak=0 ;; esac
if [ "$streak" -ge 3 ]; then
  [ "$nudged" = "1" ] && allow "chuỗi đỏ cổng commit ≥ 3 đã nhắc §8 → cho dừng."
  save "$n" "$last" 1
  block "/auto-complete: cổng commit đã đỏ $streak lần liên tiếp CÙNG một failure — §8 BLOCKED: không sửa mù thêm. Ghi '- Trạng thái: Blocked — <failure + giả thuyết đã bác bỏ>' vào docs/work/$id/working.md, nêu lựa chọn + đề xuất cho người dùng, rồi kết lượt (hook sẽ cho dừng)."
fi

save $((n + 1)) "$last" "$nudged"
lines=12; brief=""
if [ -n "$fp" ]; then   # engine chạy được → thêm khối trạng thái (verdict + bước kế tiếp), Bàn giao rút còn 6 dòng
  brief="$(bash "$ROOT/scripts/loop-state.sh" --root "$ROOT" --work-id "$id" --brief 2>/dev/null)" && lines=6 || brief=""
  [ -n "$brief" ] || lines=12
fi
excerpt="$(awk '/^## Bàn giao/{f=1; next} /^## /{f=0} f' "$WF" 2>/dev/null | grep -v '^[[:space:]]*$' | head -"$lines")"
block "/auto-complete đang bật (hồ sơ $id, lượt tiếp tục $((n + 1))/$MAX): hồ sơ còn Active → chưa được kết lượt. Nối tiếp đúng chỗ dở theo 'Bàn giao / bước tiếp theo':
${brief:+$brief
}${excerpt:-(mục Bàn giao trống — ghi bước kế tiếp cụ thể trước)}
Chỉ dừng khi §9/§8: ghi '- Trạng thái: Blocked — <lý do>' hoặc 'Waiting — <chờ gì>' vào working.md rồi kết lượt; DoC đạt + mọi PR merge → rename done.md và rm .claude/.auto-complete-loop. Không tuyên bố xong mà không chạy lệnh chứng minh (CLAUDE.md §4)."
