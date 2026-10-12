#!/usr/bin/env bash
# session-resume.sh — SessionStart hook.
# Nạp trạng thái phiên trước vào ngữ cảnh để người dùng chỉ cần nhắn "tiếp tục":
# CHỈ 4 mục cần cho việc nối tiếp của PROGRESS.md (Giai đoạn hiện tại · Đang làm / chờ · Tiếp theo ·
# Bàn giao phiên) + tóm tắt git (branch, chưa commit, commit gần nhất). Chỉ ĐỌC, không đổi gì.
# Hồ sơ active docs/work/*/working.md được liệt kê TRƯỚC PROGRESS để không bị che bởi lịch sử dài.
#
# VÌ SAO KHÔNG `cat` cả file (audit 2026-09-23, C5): bản cũ nạp NGUYÊN PROGRESS.md — repo khung lúc đó
# 58 KB (~15k token, 57% ngữ cảnh khởi đầu) vì file tích 21 khối "Giai đoạn trước đó" trái luật
# quality-supplements-group1 §9. Token rẻ nhất là token KHÔNG nạp (models-and-automation §5). Trần cứng
# SESSION_RESUME_MAX_BYTES (mặc định 8000) — vượt thì cắt và NÓI RÕ đã cắt, không im lặng.
set -uo pipefail   # cố ý KHÔNG -e: không được làm chết phiên/lượt chạy (xem docs/CONVENTIONS.md §A)

ROOT="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"
MAX="${SESSION_RESUME_MAX_BYTES:-8000}"

# Phiên mới → xóa marker đã-nhắc-wind-down để usage-guard nhắc lại được ở phiên này.
rm -f "$ROOT/.claude/.winddown-nudged" 2>/dev/null || true
# Marker vòng /auto-complete (auto-complete-guard.sh) chỉ sống trong MỘT phiên: phiên mới (startup/clear) xoá và nói ra, để
# một phiên hỏi việc khác không bị hook giữ lượt; nén ngữ cảnh (compact) hay nối phiên (resume) GIỮ — vòng đang chạy.
# `source` đọc từ payload stdin; thiếu jq/payload → coi như startup (chiều an toàn: không giữ vòng mồ côi).
loop_ctx=""   # vòng /auto-complete còn sống qua compact/resume → 3 dòng trạng thái máy tính (ADR-0012) vào ngữ cảnh model
if [ -f "$ROOT/.claude/.auto-complete-loop" ]; then
  src="$( { cat; } 2>/dev/null | { command -v jq >/dev/null 2>&1 && jq -r '.source // "startup"' 2>/dev/null || echo startup; } )"
  case "$src" in
    compact|resume)
       # Vòng giữ nguyên → nạp trạng thái do engine tính (verdict + bước kế tiếp), fail-open: engine lỗi → không có khối này.
       if [ -f "$ROOT/scripts/loop-state.py" ]; then
         loop_ctx="$(bash "$ROOT/scripts/loop-state.sh" --root "$ROOT" --work-id "$(sed -n 1p "$ROOT/.claude/.auto-complete-loop" | tr -d '[:space:]')" --brief 2>/dev/null | head -3 || true)"
         echo "[session-resume] loop-state: ${loop_ctx:-(engine lỗi — chạy tay bash scripts/loop-state.sh --brief)}" >&2
       fi ;;
    *) rm -f "$ROOT/.claude/.auto-complete-loop" 2>/dev/null || true
       echo "[session-resume] lượt /auto-complete trước chưa kết (marker đã xoá) — gõ /auto-complete để nối lại vòng." >&2 ;;
  esac
fi

command -v jq >/dev/null 2>&1 || { echo "[session-resume] không có jq → không nạp được PROGRESS.md vào ngữ cảnh." >&2; exit 0; }

# In các section (## <tên>) được chọn của PROGRESS.md, bỏ khối "Giai đoạn trước đó" (lịch sử → docs/changelog/).
progress_excerpt() {
  awk '
    /^## /  { keep = ($0 ~ /^## (Giai đoạn hiện tại|Đang làm \/ chờ|Tiếp theo|Bàn giao phiên)/); skipblk = 0 }
    keep {
      if ($0 ~ /^- Giai đoạn trước đó/) { skipblk = 1; next }
      if (skipblk && $0 ~ /^  /) next
      skipblk = 0
      print
    }' "$1"
}

ctx="$(
  if [ -n "$loop_ctx" ]; then
    echo "===== Vòng /auto-complete đang bật (scripts/loop-state.sh --brief; mỗi vòng chạy lại --enter --brief và làm đúng next) ====="
    printf '%s\n' "$loop_ctx"
  fi
  work_list_started=0
  for work_file in "$ROOT"/docs/work/*/working.md; do
    [ -f "$work_file" ] || continue
    if [ "$work_list_started" -eq 0 ]; then
      echo "===== Hồ sơ công việc đang mở ====="
      echo "Đọc đầy đủ từng working.md trước khi làm; đối chiếu Git/PR/CI. Lịch sử liên quan: docs/work/*/done.md."
      work_list_started=1
    fi
    printf -- '- %s\n' "${work_file#"$ROOT"/}"
  done
  if [ -f "$ROOT/PROGRESS.md" ]; then
    echo "===== PROGRESS.md (4 mục để 'tiếp tục' — bản đầy đủ: đọc file; lịch sử: docs/changelog/) ====="
    progress_excerpt "$ROOT/PROGRESS.md"
    echo
  fi
  if command -v git >/dev/null 2>&1 && git -C "$ROOT" rev-parse --git-dir >/dev/null 2>&1; then
    echo "===== Git ====="
    echo "Branch: $(git -C "$ROOT" branch --show-current 2>/dev/null)"
    echo "-- Thay đổi chưa commit --"; git -C "$ROOT" status --short 2>/dev/null | head -20
    echo "-- 5 commit gần nhất --";   git -C "$ROOT" log --oneline -5 2>/dev/null
  fi
)"

[ -n "${ctx// /}" ] || exit 0

if [ "$(printf '%s' "$ctx" | wc -c)" -gt "$MAX" ]; then
  ctx="$(printf '%s' "$ctx" | head -c "$MAX")
… (ĐÃ CẮT ở ${MAX} byte — đọc trực tiếp PROGRESS.md và liệt kê docs/work/*/working.md để không bỏ sót việc; lịch sử PROGRESS chuyển sang docs/changelog/)"
fi

jq -n --arg c "$ctx" '{
  hookSpecificOutput: {
    hookEventName: "SessionStart",
    additionalContext: ("Trạng thái để tiếp tục công việc dở (khi người dùng nhắn \"tiếp tục\", nối tiếp mục \"Đang làm\"/\"Tiếp theo\"/\"Bàn giao\"):\n\n" + $c)
  }
}'
