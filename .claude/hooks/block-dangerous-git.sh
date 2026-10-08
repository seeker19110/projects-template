#!/usr/bin/env bash
# block-dangerous-git.sh — PreToolUse hook (matcher: Bash).
#
# VÌ SAO CẦN (audit 2026-09-12, F-004): CLAUDE.md §8 CẤM một số thao tác git, nhưng trước hook này
# lệnh cấm chỉ tồn tại dưới dạng LUẬT — không có cơ chế nào thi hành. Luật không có hàng rào thì
# sẽ bị vi phạm ở phiên dài (bằng chứng thật: luật FIFO §8 bị vi phạm 19 ngày, F-001).
#
# Chặn 5 khuôn (exit 2 = chặn, thông báo về lại Claude):
#   1. force-push vào nhánh chính (`--force`/`-f`/`--force-with-lease` + main/master)
#   2. `reset --hard` (mất thay đổi chưa commit, không hoàn tác được)
#   3. `merge --abort` / `rebase --abort` (né việc giải xung đột — CLAUDE.md §8 cấm tường minh)
#   4. `push --force` lên nhánh KHÔNG phải của mình → chỉ cảnh báo (không chặn), vì rebase nhánh
#      riêng là hợp lệ theo quy ước repo.
#   5. `push` xoá hoặc ép ghi đè nhánh chính không qua chữ --force: refspec `+main`, `:main`,
#      `--delete main` (audit 2026-09-23).
#
# Bỏ qua có chủ đích: đặt ALLOW_DANGEROUS_GIT=1 trong môi trường (tường minh, có chủ ý).
set -uo pipefail   # cố ý KHÔNG -e: không được làm chết phiên (xem docs/CONVENTIONS.md §A)

[ "${ALLOW_DANGEROUS_GIT:-0}" = "1" ] && exit 0

payload="$(cat)"
if ! command -v jq >/dev/null 2>&1; then
  # Không có jq → KHÔNG đoán lệnh từ JSON thô (sẽ khớp nhầm nội dung file/mô tả và chặn oan).
  # Fail-open nhưng NÓI RA (thống nhất pre-commit-gate.sh / auto-format.sh).
  echo "[block-dangerous-git] không có jq → không đọc được lệnh, bỏ qua kiểm tra." >&2
  exit 0
fi
# shellcheck source=.claude/hooks/_lib.sh
source "$(dirname "$0")/_lib.sh" || { echo "[block-dangerous-git] thiếu .claude/hooks/_lib.sh → bỏ qua kiểm tra." >&2; exit 0; }
cmd="$(printf '%s' "$payload" | read_hook_command)"
[ -n "$cmd" ] || exit 0
# Mọi khuôn dưới đều cần chữ `git` → lệnh không chứa nó thì khỏi chạy awk/sed/grep (hook chạy trên MỌI lệnh Bash).
case "$cmd" in *git*) ;; *) exit 0 ;; esac

# Bỏ DỮ LIỆU (thân heredoc + phần trong nháy) trước khi so khớp — lý do và giới hạn: _lib.sh.
cmd_scan="$(printf '%s' "$cmd" | strip_heredoc_bodies | strip_quoted)"
# `git … push` dùng ở khuôn 1, 5, 4 → so một lần.
is_push=0
printf '%s' "$cmd_scan" | grep -Eq '(^|[^-])git[[:space:]]+([^|&;]*[[:space:]])?push([[:space:]]|$)' && is_push=1

block() {
  echo "🚫 Lệnh bị chặn bởi block-dangerous-git.sh: $1" >&2
  echo "   Lý do: $2" >&2
  echo "   Nếu THỰC SỰ cần: chạy lại với ALLOW_DANGEROUS_GIT=1 (và nói rõ lý do cho người dùng)." >&2
  exit 2
}

# --- 1. force-push vào nhánh chính ---
if [ "$is_push" = 1 ] \
   && printf '%s' "$cmd_scan" | grep -Eq '(^|[[:space:]])(--force|--force-with-lease(=[^[:space:]]*)?|-f)([[:space:]]|$)' \
   && printf '%s' "$cmd_scan" | grep -Eq '(^|[[:space:]:])(main|master)([[:space:]]|$)'; then
  block "force-push vào nhánh chính" "CLAUDE.md §8: không push thẳng nhánh chính; force-push xoá lịch sử của người khác."
fi

# --- 2. reset --hard ---
if printf '%s' "$cmd_scan" | grep -Eq '(^|[^-])git[[:space:]]+([^|&;]*[[:space:]])?reset([[:space:]]|$)' \
   && printf '%s' "$cmd_scan" | grep -Eq '(^|[[:space:]])--hard([[:space:]]|$)'; then
  block "git reset --hard" "Mất vĩnh viễn thay đổi chưa commit. Dùng 'git stash' hoặc 'git restore <file>' cho phạm vi hẹp."
fi

# --- 3. --abort để né giải xung đột ---
if printf '%s' "$cmd_scan" | grep -Eq '(^|[^-])git[[:space:]]+([^|&;]*[[:space:]])?(merge|rebase|cherry-pick)([[:space:]]|$)' \
   && printf '%s' "$cmd_scan" | grep -Eq '(^|[[:space:]])--abort([[:space:]]|$)'; then
  block "git ...--abort" "CLAUDE.md §8: KHÔNG BAO GIỜ --abort để né việc giải xung đột — đọc cả hai phía rồi giải."
fi

# --- 5. push XOÁ nhánh chính hoặc refspec ép ghi đè (`+main`, `+HEAD:main`, `:main`, `--delete main`) ---
# Cùng bản chất khuôn 1 nhưng không có chữ --force nên bản cũ để lọt (audit 2026-09-23, T5).
# So theo TỪNG TOKEN (tách bằng khoảng trắng) để refspec `+feat/x` hay `--delete feat/x` không bị oan.
if [ "$is_push" = 1 ]; then
  tokens="$(printf '%s' "$cmd_scan" | tr -s '[:space:]' '\n')"
  if printf '%s\n' "$tokens" | grep -Eq '^\+([^:]*:)?(main|master)$|^:(main|master)$' \
     || { printf '%s\n' "$tokens" | grep -Eq '^(--delete|-d)$' && printf '%s\n' "$tokens" | grep -Eq '^(main|master)$'; }; then
    block "push xoá / ép ghi đè nhánh chính" "CLAUDE.md §8: nhánh chính chỉ nhận thay đổi qua PR; refspec '+main', ':main' hay --delete main xoá lịch sử/nhánh của mọi người."
  fi
fi

# --- 4. force-push nhánh khác: cảnh báo, không chặn ---
if [ "$is_push" = 1 ] \
   && printf '%s' "$cmd_scan" | grep -Eq '(^|[[:space:]])(--force|-f)([[:space:]]|$)'; then
  echo "⚠️  force-push (không phải nhánh chính): chỉ hợp lệ trên nhánh DO BẠN tạo. Nhánh của người khác → dùng merge commit (CLAUDE.md §8)." >&2
fi

exit 0
