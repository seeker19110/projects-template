#!/usr/bin/env bash
# test-maintain-run.sh — Self-test cho runner đa-provider `scripts/maintain-run.sh`.
#
# KHÔNG gọi LLM thật. Dùng CLI GIẢ (stub) ghi lại argv + stdin để chứng minh runner gọi đúng cú
# pháp đã xác minh của từng harness, chọn harness đúng, và thất bại RÕ RÀNG khi thiếu CLI
# (TRAPS.md mục 11/15: chạy thật mới tin; F-002: phải chứng minh bắt được lỗi).
#
# Chạy: bash scripts/test-maintain-run.sh
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
RUN="$ROOT/scripts/maintain-run.sh"
source "$ROOT/scripts/_test-lib.sh"
fails=0  # ShellCheck không theo được source qua $ROOT; giữ biến đếm tường minh.

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
# Stub CLI: ghi argv (mỗi dòng một tham số) + stdin vào $TMP/<tên>.argv / .stdin, rồi thoát 0.
mk_stub() {
  cat > "$TMP/$1" <<EOF
#!/usr/bin/env bash
printf '%s\n' "\$@" > "$TMP/$1.argv"
if [ ! -t 0 ]; then cat > "$TMP/$1.stdin"; fi
exit 0
EOF
  chmod +x "$TMP/$1"
}
for h in claude hermes codex opencode; do mk_stub "$h"; done
export MAINT_BIN_CLAUDE="$TMP/claude" MAINT_BIN_HERMES="$TMP/hermes" MAINT_BIN_CODEX="$TMP/codex" MAINT_BIN_OPENCODE="$TMP/opencode"
# Báo cáo/prompt sinh ra khi test không được rơi vào docs/ops của repo → chạy trong bản sao tối thiểu.
WORK="$TMP/work"; mkdir -p "$WORK/scripts" "$WORK/.claude/agents" "$WORK/docs/ops"
cp "$ROOT"/scripts/{maintenance-sweep.sh,maintain-run.sh,subagent-dispatch.sh,subagent-dispatch.py,_python-exec.sh} "$WORK/scripts/"
cp "$ROOT/.claude/agents/maintainer.md" "$WORK/.claude/agents/"
printf '# PROGRESS\n- Ngày cập nhật: %s\n' "$(date +%Y-%m-%d)" > "$WORK/PROGRESS.md"
( cd "$WORK" && git -c user.name=t -c user.email=t@x init -q -b main && git -c user.name=t -c user.email=t@x add -A && git -c user.name=t -c user.email=t@x -c commit.gpgsign=false commit -qm init )
export CLAUDE_PROJECT_DIR="$WORK"
unset MAINT_HARNESS MAINT_MODEL MAINT_PROVIDER

echo "== 1. --help / tham số sai =="
bash "$RUN" --help 2>&1 | grep -q -- '--harness' && ok "--help liệt kê --harness" || bad "--help thiếu --harness"
bash "$RUN" --harness cursor >/dev/null 2>&1; [ $? -eq 2 ] && ok "harness chưa xác minh (cursor) → thoát 2, không bịa lệnh" || bad "harness lạ không thoát 2"
bash "$RUN" --mode turbo >/dev/null 2>&1; [ $? -eq 2 ] && ok "mode lạ → thoát 2" || bad "mode lạ không thoát 2"

echo "== 2. print: không CLI, prompt chứa vai maintainer + báo cáo quét =="
out="$(bash "$RUN" --harness print --mode quick --prompt-out "$TMP/p.md" 2>"$TMP/err")"; rc=$?
[ "$rc" -eq 0 ] && ok "print thoát 0" || bad "print thoát $rc: $(cat "$TMP/err")"
grep -q "SUBAGENT ROLE: MAINTAINER" "$TMP/p.md" && ok "prompt nạp vai từ .claude/agents/maintainer.md" || bad "prompt thiếu vai maintainer"
grep -q "## Tổng hợp phát hiện" "$TMP/p.md" && ok "prompt đính kèm báo cáo quét" || bad "prompt thiếu báo cáo quét"
grep -q "MAINTENANCE-PLAN.md" "$TMP/p.md" && ok "prompt yêu cầu viết kế hoạch + dừng chờ duyệt" || bad "prompt thiếu yêu cầu kế hoạch"
[ -f "$WORK/docs/ops/MAINTENANCE-REPORT.md" ] && ok "báo cáo ghi ở docs/ops/MAINTENANCE-REPORT.md" || bad "thiếu báo cáo"

echo "== 3. Từng harness gọi ĐÚNG CÚ PHÁP ĐÃ XÁC MINH (stub ghi argv/stdin) =="
rm -f "$TMP"/*.argv "$TMP"/*.stdin
bash "$RUN" --harness claude --mode quick --model opus >/dev/null 2>&1 && ok "claude: runner thoát 0" || bad "claude: runner lỗi"
[ "$(sed -n 1p "$TMP/claude.argv")" = "-p" ] && [ "$(sed -n 2,3p "$TMP/claude.argv" | tr '\n' ' ')" = "--model opus " ] && ok "claude: argv = -p --model opus (không --bare, không API key)" || bad "claude: argv sai: $(tr '\n' ' ' <"$TMP/claude.argv")"
grep -q "SUBAGENT ROLE: MAINTAINER" "$TMP/claude.stdin" 2>/dev/null && ok "claude: prompt đi qua stdin" || bad "claude: stdin không có prompt"

bash "$RUN" --harness hermes --mode quick --provider claude-code-cli --model sonnet >/dev/null 2>&1 && ok "hermes: runner thoát 0" || bad "hermes: runner lỗi"
[ "$(sed -n 1,2p "$TMP/hermes.argv" | tr '\n' ' ')" = "chat -q " ] && ok "hermes: argv bắt đầu bằng chat -q" || bad "hermes: argv sai: $(head -2 "$TMP/hermes.argv" | tr '\n' ' ')"
grep -q "SUBAGENT ROLE: MAINTAINER" "$TMP/hermes.argv" && ok "hermes: prompt là tham số của -q" || bad "hermes: thiếu prompt"
grep -A1 -x -- '--provider' "$TMP/hermes.argv" | grep -qx 'claude-code-cli' && grep -A1 -x -- '-m' "$TMP/hermes.argv" | grep -qx 'sonnet' && ok "hermes: --provider claude-code-cli -m sonnet" || bad "hermes: thiếu --provider/-m"

rm -f "$TMP/hermes.argv"
bash "$RUN" --harness gemini --mode quick >/dev/null 2>&1 && ok "gemini: runner thoát 0" || bad "gemini: runner lỗi"
grep -A1 -x -- '--provider' "$TMP/hermes.argv" 2>/dev/null | grep -qx 'antigravity' && grep -A1 -x -- '-m' "$TMP/hermes.argv" | grep -qx 'gemini-3.7-flash' && ok "gemini: đi qua hermes --provider antigravity -m gemini-3.7-flash" || bad "gemini: không đi qua hermes/antigravity: $(tr '\n' ' ' <"$TMP/hermes.argv" 2>/dev/null | cut -c1-120)"
rm -f "$TMP/hermes.argv"
bash "$RUN" --harness gemini --model gemini-3.1-pro --mode quick >/dev/null 2>&1; grep -A1 -x -- '-m' "$TMP/hermes.argv" | grep -qx 'gemini-3.1-pro' && ok "gemini: --model ghi đè được (gemini-3.1-pro)" || bad "gemini: --model không ghi đè"

bash "$RUN" --harness codex --mode quick >/dev/null 2>&1 && ok "codex: runner thoát 0" || bad "codex: runner lỗi"
[ "$(sed -n 1p "$TMP/codex.argv")" = "exec" ] && [ "$(sed -n 2p "$TMP/codex.argv")" = "-C" ] && [ "$(tail -1 "$TMP/codex.argv")" = "-" ] && ok "codex: argv = exec -C <repo> -" || bad "codex: argv sai: $(tr '\n' ' ' <"$TMP/codex.argv")"
grep -q "SUBAGENT ROLE: MAINTAINER" "$TMP/codex.stdin" 2>/dev/null && ok "codex: prompt qua stdin" || bad "codex: stdin không có prompt"

bash "$RUN" --harness opencode --mode quick >/dev/null 2>&1 && ok "opencode: runner thoát 0" || bad "opencode: runner lỗi"
[ "$(sed -n 1p "$TMP/opencode.argv")" = "run" ] && grep -q "SUBAGENT ROLE: MAINTAINER" "$TMP/opencode.argv" && ok "opencode: argv = run \"<prompt>\"" || bad "opencode: argv sai"

echo "== 4. auto chọn CLI đầu tiên có; thiếu CLI → thoát 3 rõ ràng =="
rm -f "$TMP"/*.argv
bash "$RUN" --mode quick >/dev/null 2>&1; [ -f "$TMP/claude.argv" ] && ok "auto → claude (ưu tiên đầu)" || bad "auto không chọn claude"
MAINT_BIN_CLAUDE=/nonexistent/claude bash "$RUN" --harness claude --mode quick >"$TMP/o" 2>&1; rc=$?
[ "$rc" -eq 3 ] && grep -q "không tìm thấy CLI 'claude'" "$TMP/o" && ok "thiếu CLI claude → thoát 3 + thông báo cài/đăng nhập" || bad "thiếu CLI: thoát $rc, msg: $(cat "$TMP/o")"
MAINT_BIN_CLAUDE=/nonexistent/x MAINT_BIN_HERMES=/nonexistent/x MAINT_BIN_CODEX=/nonexistent/x MAINT_BIN_OPENCODE=/nonexistent/x \
  bash "$RUN" --mode quick --prompt-out "$TMP/p2.md" 2>"$TMP/e2" >/dev/null; rc=$?
[ "$rc" -eq 0 ] && grep -q "harness tự chọn: print" "$TMP/e2" && ok "auto không có CLI nào → print (không lỗi, không API key)" || bad "auto không CLI: rc=$rc"

echo "== 5. --dry-run không gọi CLI =="
rm -f "$TMP"/*.argv
out="$(bash "$RUN" --harness claude --mode quick --dry-run 2>/dev/null)"
printf '%s' "$out" | grep -q "DRY-RUN harness=claude" && [ ! -f "$TMP/claude.argv" ] && ok "dry-run in lệnh, stub không bị gọi" || bad "dry-run vẫn gọi CLI hoặc không in lệnh"

echo
if [ "$fails" -eq 0 ]; then echo "OK — maintain-run.sh gọi đúng cú pháp từng harness bằng CLI cục bộ, tự chọn/thoát rõ ràng, không cần API key."; else echo "FAIL — $fails kiểm hỏng."; fi
exit "$fails"
