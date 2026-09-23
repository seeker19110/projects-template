#!/usr/bin/env bash
# session-resume.sh — SessionStart hook.
# Nạp trạng thái phiên trước vào ngữ cảnh để người dùng chỉ cần nhắn "tiếp tục":
# CHỈ 4 mục cần cho việc nối tiếp của PROGRESS.md (Giai đoạn hiện tại · Đang làm / chờ · Tiếp theo ·
# Bàn giao phiên) + tóm tắt git (branch, chưa commit, commit gần nhất). Chỉ ĐỌC, không đổi gì.
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
… (ĐÃ CẮT ở ${MAX} byte — PROGRESS.md quá dài so với luật 'một khối hiện tại'; đọc file trực tiếp nếu cần, và chuyển lịch sử sang docs/changelog/)"
fi

jq -n --arg c "$ctx" '{
  hookSpecificOutput: {
    hookEventName: "SessionStart",
    additionalContext: ("Trạng thái để tiếp tục công việc dở (khi người dùng nhắn \"tiếp tục\", nối tiếp mục \"Đang làm\"/\"Tiếp theo\"/\"Bàn giao\"):\n\n" + $c)
  }
}'
