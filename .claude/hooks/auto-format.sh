#!/usr/bin/env bash
# auto-format.sh — PostToolUse hook (matcher: Edit|Write).
# Sau khi Claude sửa/tạo file, tự format ĐÚNG file đó qua scripts/dev-task.sh format-file.
# No-op an toàn khi dự án chưa có per-file formatter. Luôn exit 0 (không cản luồng).
#
# An toàn đa-loại-dự-án: không chứa lệnh stack; mọi lệnh nằm sau dev-task.sh.
set -uo pipefail   # cố ý KHÔNG -e: hook không được làm chết phiên (xem docs/CONVENTIONS.md §A)

ROOT="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"

payload="$(cat)"
path=""
if command -v jq >/dev/null 2>&1; then
  path="$(printf '%s' "$payload" | jq -r '.tool_input.file_path // empty' 2>/dev/null)"
else
  # Fail-open CÓ CẢNH BÁO (audit 2026-09-12, F-007): trước đây hook no-op IM LẶNG khi thiếu jq,
  # nên người dùng tưởng auto-format đang chạy suốt phiên. Thống nhất với pre-commit-gate.sh:
  # bỏ qua thì phải nói ra.
  echo "[auto-format] không có jq → không đọc được đường dẫn file, bỏ qua format." >&2
  exit 0
fi

[ -n "$path" ] || exit 0
if [ ! -x "$ROOT/scripts/dev-task.sh" ]; then
  echo "[auto-format] không thấy scripts/dev-task.sh → bỏ qua format." >&2
  exit 0
fi

# Best-effort nhưng không nuốt lỗi (F-Q10): stdout bỏ, stderr của formatter được bắt để in kèm tiền tố.
err="$("$ROOT/scripts/dev-task.sh" format-file "$path" 2>&1 >/dev/null)" || echo "[auto-format] format-file lỗi: ${err:-exit $?}" >&2
exit 0
