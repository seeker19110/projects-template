#!/usr/bin/env bash
# pre-commit-gate.sh — PreToolUse hook (matcher: Bash).
# Khi Claude định chạy `git commit`: (1) chặn nếu đang đứng trên main/master (CLAUDE.md §8),
# (2) chặn nếu diff staged có chuỗi giống bí mật hoặc file > 1 MB, (3) chạy cổng chất lượng
# (build/typecheck/lint/test) qua scripts/dev-task.sh. Cổng ĐỎ → exit 2 để CHẶN commit (CLAUDE.md §5).
# Cổng no-op (dự án chưa cấu hình lệnh) → exit 0, cho commit chạy bình thường.
#
# An toàn đa-loại-dự-án: hook KHÔNG chứa lệnh stack nào; mọi lệnh nằm sau dev-task.sh.
set -uo pipefail   # cố ý KHÔNG -e: không được làm chết phiên/lượt chạy (xem docs/CONVENTIONS.md §A)

ROOT="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"

# Đọc payload hook từ stdin, lấy lệnh Bash sắp chạy.
payload="$(cat)"
cmd=""
if command -v jq >/dev/null 2>&1; then
  cmd="$(printf '%s' "$payload" | jq -r '.tool_input.command // empty' 2>/dev/null)"
else
  # Không có jq → KHÔNG đoán lệnh từ JSON thô (grep trên cả payload sẽ khớp nhầm nội dung
  # file/mô tả và chạy cổng oan hoặc chặn sai). Fail-open: bỏ qua cổng, chỉ nhắc.
  echo "[pre-commit-gate] không có jq → không đọc được lệnh, bỏ qua cổng." >&2
  exit 0
fi

# Bỏ phần TRONG DẤU NHÁY trước khi so khớp (audit 2026-09-12): nếu không, một chuỗi mô tả như
# `echo 'git reset --hard ...'` sẽ bị coi là lệnh git thật và chặn oan.
cmd_scan="$(printf '%s' "$cmd" | sed "s/'[^']*'//g; s/\"[^\"]*\"//g")"

# Chỉ can thiệp khi thực sự là `git commit` (bỏ qua commit-tree, --help…).
if ! printf '%s' "$cmd_scan" | grep -Eq '(^|[^-])git[[:space:]]+([^|&;]*[[:space:]])?commit([[:space:]]|$)'; then
  exit 0
fi

# Người dùng chủ động bỏ qua cổng?
# Chỉ nhận đúng cờ git hợp lệ `--no-verify` (`-n` của git commit là --no-verify nhưng cũng là
# cờ của nhiều lệnh khác trong chuỗi → không nhận, tránh bỏ cổng nhầm).
if printf '%s' "$cmd_scan" | grep -Eq '(^|[[:space:]])--no-verify([[:space:]]|$)'; then
  echo "[pre-commit-gate] phát hiện --no-verify → bỏ qua cổng." >&2
  exit 0
fi

# --- Không commit thẳng lên nhánh chính (CLAUDE.md §8; TRAPS mục 14: `checkout -b` hỏng → commit rơi
# vào main mà không ai thấy). Bỏ qua tường minh: ALLOW_COMMIT_ON_MAIN=1.
branch="$(git -C "$ROOT" branch --show-current 2>/dev/null || true)"
if [ "${ALLOW_COMMIT_ON_MAIN:-0}" != "1" ] && { [ "$branch" = "main" ] || [ "$branch" = "master" ]; }; then
  echo "🚫 Đang đứng trên nhánh '$branch' — CLAUDE.md §8: mọi thay đổi vào nhánh chính đi qua PR. Tạo nhánh trước: git switch -c feat/<tên>." >&2
  echo "   Nếu THỰC SỰ cần: chạy lại với ALLOW_COMMIT_ON_MAIN=1 (và nói rõ lý do cho người dùng)." >&2
  exit 2
fi

# --- Bí mật / file lớn trong diff STAGED (cùng mẫu với scripts/maintenance-sweep.sh — sweep chỉ chạy
# định kỳ, tới lúc đó khoá đã nằm trong lịch sử git; chặn ở đây là chặn TRƯỚC khi vào lịch sử). ---
secret_re='(AKIA[0-9A-Z]{16}|-----BEGIN [A-Z ]*PRIVATE KEY-----|ghp_[A-Za-z0-9]{36}|github_pat_[A-Za-z0-9_]{22,}|glpat-[A-Za-z0-9_-]{20}|AIza[0-9A-Za-z_-]{35}|sk-[A-Za-z0-9]{32,}|xox[baprs]-[A-Za-z0-9-]{10,})'
if git -C "$ROOT" diff --cached -U0 -- 2>/dev/null | grep -E '^\+[^+]' | grep -Eq "$secret_re"; then
  echo "🚫 Diff staged chứa chuỗi giống khoá/token thật (AWS/PEM/GitHub/GitLab/Google/OpenAI/Slack). Gỡ khỏi staged, đưa vào biến môi trường (CLAUDE.md §3.5), xoay vòng khoá nếu đã lộ." >&2
  exit 2
fi
big=""
while IFS= read -r -d '' f; do
  sz="$(wc -c <"$ROOT/$f" 2>/dev/null || echo 0)"
  [ "$sz" -gt 1048576 ] && big="$big $f($((sz/1024))KB)"
done < <(git -C "$ROOT" diff --cached --name-only --diff-filter=AM -z -- 2>/dev/null)
if [ -n "$big" ]; then
  echo "🚫 File staged > 1 MB:$big — không đưa file lớn vào git (Git LFS hoặc loại khỏi repo; maintenance-sweep sẽ 🟡 mãi)." >&2
  exit 2
fi

if [ ! -x "$ROOT/scripts/dev-task.sh" ]; then
  # Không có dispatcher → không chặn (an toàn), chỉ nhắc.
  echo "[pre-commit-gate] không thấy scripts/dev-task.sh → bỏ qua cổng." >&2
  exit 0
fi

if ! "$ROOT/scripts/dev-task.sh" gate; then
  echo "❌ Cổng trước commit ĐỎ (build/typecheck/lint/test). Sửa hết rồi commit lại (CLAUDE.md §5)." >&2
  echo "   Bỏ qua có chủ đích: thêm --no-verify vào lệnh git commit." >&2
  exit 2
fi

# Cổng máy móc (build/lint/test) chỉ bắt lỗi CÚ PHÁP, không bắt lỗi LOGIC/trùng lặp/hiệu năng —
# đúng việc Sonnet làm tốt qua skill /code-review, /simplify. Nudge (không chặn) khi diff staged đủ lớn.
lines_changed="$(git -C "$ROOT" diff --cached --numstat -- 2>/dev/null | awk '{a+=$1; d+=$2} END{print a+d+0}')"
files_changed="$(git -C "$ROOT" diff --cached --name-only -- 2>/dev/null | grep -c . || true)"
if [ "${lines_changed:-0}" -ge 80 ] || [ "${files_changed:-0}" -ge 5 ]; then
  echo "💡 Diff staged khá lớn (${files_changed} file, ~${lines_changed} dòng đổi). Cổng máy móc chỉ bắt lỗi cú pháp — cân nhắc chạy /code-review (hoặc /simplify) trước khi commit để bắt lỗi logic/trùng lặp/hiệu năng." >&2
fi

exit 0
