#!/usr/bin/env bash
# Optional PostToolUse UI-review adapter. It never installs/downloads a provider or blocks editing.
set -uo pipefail

ROOT="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"
[ "${UI_INTELLIGENCE_HOOK:-0}" = "1" ] || exit 0
[ -n "${UI_INTELLIGENCE_COMMAND:-}" ] || exit 0
[ -x "$UI_INTELLIGENCE_COMMAND" ] || { echo "[ui-intelligence] configured command is not executable; skipped." >&2; exit 0; }
command -v jq >/dev/null 2>&1 || { echo "[ui-intelligence] jq unavailable; skipped." >&2; exit 0; }

payload="$(cat)"
path="$(printf '%s' "$payload" | jq -r '.tool_input.file_path // empty' 2>/dev/null)"
[ -n "$path" ] || exit 0
case "$path" in
  *.tsx|*.jsx|*.html|*.vue|*.svelte|*.astro|*.css|*.scss|*.sass|*.less) ;;
  *) exit 0 ;;
esac

case "$path" in /*) target="$path" ;; *) target="$ROOT/$path" ;; esac
[ -f "$target" ] || exit 0
"$UI_INTELLIGENCE_COMMAND" detect "$target" || true
exit 0
