#!/usr/bin/env bash
# precompact-checkpoint.sh — PreCompact hook. Ngay TRƯỚC khi Claude Code nén ngữ cảnh (tự động hoặc
# /compact), chụp trạng thái làm việc ra file để phần "sau nén" (và phiên sau) không mất dấu:
# nhánh, thay đổi chưa commit, 5 commit gần nhất, mục "Đang làm / chờ" + "Bàn giao phiên" của PROGRESS.md.
# Ghi vào .claude/.compact-checkpoint (gitignored), thêm dòng vào .ai-telemetry/compact.log.
# Chỉ đọc + ghi file cục bộ; không đổi gì trong repo. Fail-open (docs/CONVENTIONS.md §A).
set -uo pipefail

ROOT="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"
OUT="$ROOT/.claude/.compact-checkpoint"
payload="$(cat 2>/dev/null || true)"
trigger="$(printf '%s' "$payload" | jq -r '.trigger // .matcher // "unknown"' 2>/dev/null || echo unknown)"

{
  echo "# Checkpoint trước khi nén ngữ cảnh — $(date -u +%Y-%m-%dT%H:%M:%SZ) (trigger: $trigger)"
  if command -v git >/dev/null 2>&1 && git -C "$ROOT" rev-parse --git-dir >/dev/null 2>&1; then
    echo "Branch: $(git -C "$ROOT" branch --show-current 2>/dev/null)"
    echo "-- Thay đổi chưa commit --"; git -C "$ROOT" status --short 2>/dev/null | head -30
    echo "-- 5 commit gần nhất --";   git -C "$ROOT" log --oneline -5 2>/dev/null
  fi
  if [ -f "$ROOT/PROGRESS.md" ]; then
    echo "-- PROGRESS.md: Đang làm / chờ · Bàn giao phiên --"
    awk '/^## /{keep=($0 ~ /^## (Đang làm \/ chờ|Bàn giao phiên)/)} keep' "$ROOT/PROGRESS.md" | head -60
  fi
} > "$OUT" 2>/dev/null || exit 0

mkdir -p "$ROOT/.ai-telemetry" 2>/dev/null && printf '%s compact trigger=%s branch=%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$trigger" "$(git -C "$ROOT" branch --show-current 2>/dev/null)" >> "$ROOT/.ai-telemetry/compact.log" 2>/dev/null || true
echo "[precompact-checkpoint] đã chụp trạng thái vào .claude/.compact-checkpoint — sau khi nén, đọc lại file này nếu mất dấu việc đang làm." >&2
exit 0
