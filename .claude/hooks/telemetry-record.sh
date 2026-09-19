#!/usr/bin/env bash
# telemetry-record.sh — Stop hook. Tự ghi một entry vào telemetry-log.py cuối mỗi lượt,
# thay vì chỉ dựa vào lời gọi tay theo AGENTS.md (khoảng cách đã phát hiện ở audit
# 2026-09-19: tài liệu mô tả engine "ghi mỗi tác vụ AI" nhưng không hook nào gọi nó thật).
# Không chặn phiên nếu lỗi (xem docs/CONVENTIONS.md §A) — best-effort, im lặng khi thiếu điều kiện.
set -uo pipefail

ROOT="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"
[ -x "$ROOT/scripts/telemetry-log.sh" ] || exit 0

payload="$(cat)"
command -v jq >/dev/null 2>&1 || exit 0
tp="$(printf '%s' "$payload" | jq -r '.transcript_path // empty' 2>/dev/null)"

duration="0"
if [ -n "$tp" ] && [ -f "$tp" ]; then
  first_ts="$(jq -rs 'map(.timestamp // empty) | map(select(. != "")) | first // empty' "$tp" 2>/dev/null)"
  last_ts="$(jq -rs 'map(.timestamp // empty) | map(select(. != "")) | last // empty' "$tp" 2>/dev/null)"
  if [ -n "$first_ts" ] && [ -n "$last_ts" ]; then
    start_epoch="$(date -d "$first_ts" +%s 2>/dev/null || date -j -f "%Y-%m-%dT%H:%M:%S" "${first_ts%%.*}" +%s 2>/dev/null)"
    end_epoch="$(date -d "$last_ts" +%s 2>/dev/null || date -j -f "%Y-%m-%dT%H:%M:%S" "${last_ts%%.*}" +%s 2>/dev/null)"
    if [ -n "${start_epoch:-}" ] && [ -n "${end_epoch:-}" ] && [ "$end_epoch" -ge "$start_epoch" ] 2>/dev/null; then
      duration="$(awk -v s="$start_epoch" -v e="$end_epoch" 'BEGIN{printf "%.2f", (e-s)/3600}')"
    fi
  fi
fi

model="$(jq -r '.model // "claude-sonnet-5"' "$ROOT/.claude/settings.json" 2>/dev/null)"
[ -n "$model" ] || model="claude-sonnet-5"

bash "$ROOT/scripts/telemetry-log.sh" --record \
  --harness claude-code --provider anthropic --model "$model" \
  --agent session --task "Stop hook tu dong" \
  --duration "$duration" --test-status N/A >/dev/null 2>&1 || true

exit 0
