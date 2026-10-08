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
if ! command -v jq >/dev/null 2>&1; then
  # Không có jq → KHÔNG đoán lệnh từ JSON thô (grep trên cả payload sẽ khớp nhầm nội dung
  # file/mô tả và chạy cổng oan hoặc chặn sai). Fail-open: bỏ qua cổng, chỉ nhắc.
  echo "[pre-commit-gate] không có jq → không đọc được lệnh, bỏ qua cổng." >&2
  exit 0
fi
# shellcheck source=.claude/hooks/_lib.sh
source "$(dirname "$0")/_lib.sh" || { echo "[pre-commit-gate] thiếu .claude/hooks/_lib.sh → bỏ qua cổng." >&2; exit 0; }
cmd="$(printf '%s' "$payload" | read_hook_command)"
case "$cmd" in *git*) ;; *) exit 0 ;; esac   # không có chữ `git` thì không thể là commit — khỏi chạy awk/sed/grep

# Bỏ DỮ LIỆU trước khi so khớp — CÙNG bộ lọc với block-dangerous-git (_lib.sh): phần TRONG DẤU NHÁY (audit
# 2026-09-12: `echo 'git commit ...'`) và THÂN HEREDOC (O-2 2026-10-08: `python3 - <<PY … git commit … PY` chạy
# cổng oan; message heredoc nhắc `git add` bật tự-stage oan — TRAPS.md "bản sao hook lệch nhau").
cmd_scan="$(printf '%s' "$cmd" | strip_heredoc_bodies | strip_quoted)"

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

# CÂY ĐANG COMMIT ≠ CHECKOUT CHÍNH (đối chiếu X-Agents `pt.10`, đo lại ở repo này — test mục 15). Phiên chạy trong
# `git worktree` thì `git commit` chạy ở worktree còn CLAUDE_PROJECT_DIR vẫn trỏ checkout chính: đọc nhánh/index/cổng
# từ đó vừa chặn oan ("đang đứng trên main") vừa buông bí mật và cổng đỏ của worktree. Mọi phép kiểm đọc $CAY = gốc
# cây chứa cwd của hook (cwd của lệnh commit); ngoài repo thì lùi về $ROOT (lùi về chặt hơn là buông cổng).
CAY="$(git rev-parse --show-toplevel 2>/dev/null)"
[ -n "$CAY" ] || CAY="$ROOT"

# --- Không commit thẳng lên nhánh chính (CLAUDE.md §8; TRAPS mục 14: `checkout -b` hỏng → commit rơi
# vào main mà không ai thấy). Bỏ qua tường minh: ALLOW_COMMIT_ON_MAIN=1.
branch="$(git -C "$CAY" branch --show-current 2>/dev/null || true)"
if [ "${ALLOW_COMMIT_ON_MAIN:-0}" != "1" ] && { [ "$branch" = "main" ] || [ "$branch" = "master" ]; }; then
  echo "🚫 Đang đứng trên nhánh '$branch' — CLAUDE.md §8: mọi thay đổi vào nhánh chính đi qua PR. Tạo nhánh trước: git switch -c feat/<tên>." >&2
  echo "   Nếu THỰC SỰ cần: chạy lại với ALLOW_COMMIT_ON_MAIN=1 (và nói rõ lý do cho người dùng)." >&2
  exit 2
fi

# --- Bí mật / file lớn trong diff STAGED (mẫu + ngưỡng một nguồn scripts/_commit-guard.sh, chung với githook và
# maintenance-sweep — sweep chỉ chạy định kỳ, tới lúc đó khoá đã nằm trong lịch sử git; chặn ở đây là chặn TRƯỚC). ---
# Lấy theo vị trí HOOK (không theo $CAY/$ROOT): hook và lib đi cùng một lần copy khung. Thiếu lib (đích copy hook
# trước khi có file này) → CHẶN kèm lời nhắc: buông kiểm bí mật âm thầm không đảo ngược được, commit bị chặn thì có.
# shellcheck source=scripts/_commit-guard.sh
if ! source "$(dirname "$0")/../../scripts/_commit-guard.sh" 2>/dev/null || [ -z "${COMMIT_GUARD_SECRET_RE:-}" ]; then
  echo "🚫 [pre-commit-gate] thiếu scripts/_commit-guard.sh (mẫu bí mật dùng chung) → không kiểm được bí mật/file lớn. Copy file đó từ khung (copy-framework.sh), hoặc bỏ qua có chủ đích bằng --no-verify." >&2
  exit 2
fi

# Hook chạy TRƯỚC lệnh nên index còn CŨ: `git add X && git commit` hay `commit -a` tự stage thứ hook chưa thấy
# (đối chiếu X-Agents #368; đo lại ở repo này: bí mật/file lớn đi lọt). Lệnh tự stage → xét cả thay đổi chưa
# stage; `git add` còn kéo cả file chưa theo dõi. Commit thường vẫn chỉ xét index (không chặn oan).
self_stage=0; add_untracked=0
if printf '%s' "$cmd_scan" | grep -Eq '(^|[^-])git[[:space:]]+([^|&;]*[[:space:]])?add([[:space:]]|$)'; then self_stage=1; add_untracked=1; fi
if printf '%s' "$cmd_scan" | grep -Eq 'commit[^|&;]*[[:space:]](-[A-Za-z]*a[A-Za-z]*|--all)([[:space:]]|$)'; then self_stage=1; fi
candidates() {   # NUL-separated, đường dẫn tương đối gốc repo
  git -C "$CAY" diff --cached --name-only --diff-filter=AM -z -- 2>/dev/null
  [ "$self_stage" = 1 ] && git -C "$CAY" diff --name-only --diff-filter=AM -z -- 2>/dev/null
  [ "$add_untracked" = 1 ] && git -C "$CAY" ls-files -o --exclude-standard -z -- 2>/dev/null
  return 0
}
secret_hit=0
diff_text() {   # luôn return 0: pipefail sẽ biến trạng thái 1 của `[ ] &&` cuối nhóm thành "pipeline lỗi" và bỏ lọt ca
  git -C "$CAY" diff --cached -U0 -- 2>/dev/null
  [ "$self_stage" = 1 ] && git -C "$CAY" diff -U0 -- 2>/dev/null
  return 0
}
if diff_text | grep -E '^\+[^+]' | grep -Eq "$COMMIT_GUARD_SECRET_RE"; then secret_hit=1; fi
if [ "$secret_hit" = 0 ] && [ "$add_untracked" = 1 ]; then
  while IFS= read -r -d '' f; do
    grep -IEq "$COMMIT_GUARD_SECRET_RE" "$CAY/$f" 2>/dev/null && { secret_hit=1; break; }
  done < <(git -C "$CAY" ls-files -o --exclude-standard -z -- 2>/dev/null)
fi
if [ "$secret_hit" = 1 ]; then
  echo "🚫 Diff (staged hoặc sắp được stage) chứa chuỗi giống khoá/token thật (AWS/PEM/GitHub/GitLab/Google/OpenAI/Slack). Gỡ khỏi diff, đưa vào biến môi trường (CLAUDE.md §3.5), xoay vòng khoá nếu đã lộ." >&2
  exit 2
fi
big=""
while IFS= read -r -d '' f; do
  sz="$(wc -c <"$CAY/$f" 2>/dev/null || echo 0)"
  [ "$sz" -gt "$COMMIT_GUARD_MAX_FILE_BYTES" ] && big="$big $f($((sz/1024))KB)"
done < <(candidates | sort -zu)
if [ -n "$big" ]; then
  echo "🚫 File staged (hoặc sắp stage) > 1 MB:$big — không đưa file lớn vào git (Git LFS hoặc loại khỏi repo; maintenance-sweep sẽ 🟡 mãi)." >&2
  exit 2
fi

# Cổng chạy trên cây đang commit; cây đó không có dev-task.sh (hiếm) thì lùi về $ROOT.
GOC_CONG="$CAY"; [ -x "$GOC_CONG/scripts/dev-task.sh" ] || GOC_CONG="$ROOT"
if [ ! -x "$GOC_CONG/scripts/dev-task.sh" ]; then
  # Không có dispatcher → không chặn (an toàn), chỉ nhắc.
  echo "[pre-commit-gate] không thấy scripts/dev-task.sh → bỏ qua cổng." >&2
  exit 0
fi

# dev-task.sh lấy ROOT từ CLAUDE_PROJECT_DIR → ép về cây đang commit, kẻo nó cd sang checkout chính.
if ! CLAUDE_PROJECT_DIR="$GOC_CONG" "$GOC_CONG/scripts/dev-task.sh" gate; then
  echo "❌ Cổng trước commit ĐỎ (build/typecheck/lint/test). Sửa hết rồi commit lại (CLAUDE.md §5)." >&2
  echo "   Bỏ qua có chủ đích: thêm --no-verify vào lệnh git commit." >&2
  exit 2
fi

# Cổng máy móc (build/lint/test) chỉ bắt lỗi CÚ PHÁP, không bắt lỗi LOGIC/trùng lặp/hiệu năng —
# đúng việc Sonnet làm tốt qua skill /code-review, /simplify. Nudge (không chặn) khi diff staged đủ lớn.
lines_changed="$(git -C "$CAY" diff --cached --numstat -- 2>/dev/null | awk '{a+=$1; d+=$2} END{print a+d+0}')"
files_changed="$(git -C "$CAY" diff --cached --name-only -- 2>/dev/null | grep -c . || true)"
if [ "${lines_changed:-0}" -ge 80 ] || [ "${files_changed:-0}" -ge 5 ]; then
  echo "💡 Diff staged khá lớn (${files_changed} file, ~${lines_changed} dòng đổi). Cổng máy móc chỉ bắt lỗi cú pháp — cân nhắc chạy /code-review (hoặc /simplify) trước khi commit để bắt lỗi logic/trùng lặp/hiệu năng." >&2
fi

exit 0
