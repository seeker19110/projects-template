#!/usr/bin/env bash
# test-usage-estimate.sh — Tự kiểm `scripts/usage-estimate.sh`.
#
# VÌ SAO CÓ FILE NÀY (audit 2026-09-13, A-02): radar đo độ phủ cổng phát hiện
# `usage-estimate.sh` là script DUY NHẤT không có test nào — nó quyết định lúc nào phiên AI
# bị nhắc "sắp hết quota", nên hỏng âm thầm thì người dùng mất cảnh báo mà không ai biết.
#
# Nguyên tắc F-002/G-001 áp cho chính mình: mỗi hành vi kiểm CẢ ca đúng lẫn ca sai; không
# ca nào được xanh vì "script chạy không crash".

set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
if command -v cygpath >/dev/null 2>&1; then ROOT="$(cygpath -m "$ROOT")"; fi
SCRIPT="$ROOT/scripts/usage-estimate.sh"

source "$ROOT/scripts/_test-lib.sh"

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

echo "== usage-estimate.sh =="

# UE-1: không có transcript -> phải TỰ TẮT (OVERALL=NA), không báo động sai, không lỗi.
out="$(bash "$SCRIPT" 2>&1)"
if echo "$out" | grep -q '^OVERALL=NA$' && echo "$out" | grep -q '^THRESHOLD='; then
  ok "UE-1: thiếu transcript → OVERALL=NA + THRESHOLD (tự tắt, không báo động sai)"
else
  bad "UE-1: thiếu transcript nhưng không trả OVERALL=NA/THRESHOLD (got: $(echo "$out" | tr '\n' ' '))"
fi

# UE-2: transcript có thật nhưng CHƯA khai budget -> vẫn NA (không bịa mẫu số).
# Script chỉ đếm message trong 5 GIỜ gần nhất (trường `timestamp`) — fixture phải có mốc
# thời gian ĐỘNG, không hard-code, nếu không test sẽ tự hỏng khi thời gian trôi.
NOW_TS="$(python3 -c 'from datetime import datetime,timezone;print(datetime.now(timezone.utc).isoformat())')"
printf '{"timestamp":"%s","message":{"model":"claude-opus-5","usage":{"input_tokens":1000,"output_tokens":500}}}\n' \
  "$NOW_TS" > "$WORK/t.jsonl"
out="$(CLAUDE_PROJECT_DIR="$WORK" bash "$SCRIPT" "$WORK/t.jsonl" 2>&1)"
if echo "$out" | grep -q '^OVERALL=NA$'; then
  ok "UE-2: có transcript nhưng chưa khai budget → vẫn NA (không bịa mẫu số)"
else
  bad "UE-2: chưa khai budget mà đã ra % (bịa mẫu số): $(echo "$out" | tr '\n' ' ')"
fi

# UE-3: khai budget -> phải ra % THẬT, và % phải tỉ lệ đúng với token đã dùng.
mkdir -p "$WORK/.claude"
cat > "$WORK/.claude/usage-budget.sh" <<'BUD'
BUDGET_OPUS=10000
BUD
out="$(CLAUDE_PROJECT_DIR="$WORK" bash "$SCRIPT" "$WORK/t.jsonl" 2>&1)"
overall="$(echo "$out" | sed -n 's/^OVERALL=\([0-9]*\)$/\1/p')"
if [ -n "$overall" ] && [ "$overall" -gt 0 ] 2>/dev/null; then
  ok "UE-3: có budget → tính ra % thật (OVERALL=$overall)"
else
  bad "UE-3: có budget nhưng không ra % (got: $(echo "$out" | tr '\n' ' '))"
fi

# UE-4 (đối chứng ĐỊNH LƯỢNG): gấp đôi budget thì % phải GIẢM.
# Không có ca này thì UE-3 chỉ chứng minh "có in ra số", không chứng minh số đó có nghĩa.
cat > "$WORK/.claude/usage-budget.sh" <<'BUD'
BUDGET_OPUS=20000
BUD
out2="$(CLAUDE_PROJECT_DIR="$WORK" bash "$SCRIPT" "$WORK/t.jsonl" 2>&1)"
overall2="$(echo "$out2" | sed -n 's/^OVERALL=\([0-9]*\)$/\1/p')"
if [ -n "$overall2" ] && [ -n "$overall" ] && [ "$overall2" -lt "$overall" ] 2>/dev/null; then
  ok "UE-4: budget gấp đôi → % giảm ($overall → $overall2), con số có ý nghĩa thật"
else
  bad "UE-4: budget gấp đôi nhưng % không giảm ($overall → $overall2)"
fi

# UE-5 (O-2 P-A3, 2026-10-08): transcript có ký tự NGOÀI ASCII (tiếng Việt trong nội dung) + locale KHÔNG phải
# UTF-8. Bản cũ `open(path)` không encoding → đọc theo mã locale (cp1252 trên Windows; ở đây mô phỏng bằng
# LC_ALL=C + PYTHONUTF8=0 → ASCII) → UnicodeDecodeError, script chết, usage-guard tắt cảnh báo quota im lặng.
printf '{"timestamp":"%s","message":{"model":"claude-opus-5","content":"Tiếng Việt — đã sửa ✓","usage":{"input_tokens":1000,"output_tokens":500}}}\n' \
  "$NOW_TS" > "$WORK/t-utf8.jsonl"
out="$(LC_ALL=C LANG=C PYTHONUTF8=0 CLAUDE_PROJECT_DIR="$WORK" bash "$SCRIPT" "$WORK/t-utf8.jsonl" 2>&1)"; rc=$?
overall5="$(echo "$out" | sed -n 's/^OVERALL=\([0-9]*\)$/\1/p')"
if [ "$rc" -eq 0 ] && [ -n "$overall5" ] && [ "$overall5" = "$overall2" ]; then
  ok "UE-5: transcript non-ASCII + locale C → vẫn đọc được, OVERALL=$overall5 (bằng ca ASCII cùng token)"
else
  bad "UE-5: transcript non-ASCII + locale không UTF-8 làm hỏng ước tính (rc=$rc): $(echo "$out" | tail -n 3 | tr '\n' ' ')"
fi

# UE-6/UE-7 (F-Q9 audit 2026-10-09): máy chỉ có `python` (Windows/một số distro) thì bản cũ dò riêng `python3`
# → OVERALL=NA im lặng, usage-guard tắt cảnh báo quota mà không ai biết. PATH tối giản bằng wrapper (script có
# shebang tới bash thật, exec interpreter THẬT theo sys.executable) — không copy/symlink binary (hỏng trên Git Bash).
BASH_ABS="$(command -v bash)"
PY_REAL="$(python3 -c 'import sys; print(sys.executable)')"
command -v cygpath >/dev/null 2>&1 && PY_REAL="$(cygpath -u "$PY_REAL")"
ONLYPY="$WORK/bin-onlypy"; NOPY="$WORK/bin-nopy"; mkdir -p "$ONLYPY" "$NOPY"
printf '#!%s\nexec %q "$@"\n' "$BASH_ABS" "$PY_REAL" > "$ONLYPY/python"; chmod +x "$ONLYPY/python"
# env -i xoá SYSTEMROOT → Python native trên Windows không khởi tạo được; giữ lại nếu có (Linux: rỗng, vô hại).
minenv() { local p="$1"; shift; env -i PATH="$p" SYSTEMROOT="${SYSTEMROOT:-}" CLAUDE_PROJECT_DIR="$WORK" "$@"; }

out="$(minenv "$ONLYPY" "$BASH_ABS" "$SCRIPT" "$WORK/t.jsonl" 2>"$WORK/err.txt")"; rc=$?
overall6="$(echo "$out" | sed -n 's/^OVERALL=\([0-9]*\)$/\1/p')"
if [ "$rc" -eq 0 ] && [ -n "$overall6" ] && [ "$overall6" = "$overall2" ]; then
  ok "UE-6: PATH chỉ có 'python' → vẫn ước tính được (OVERALL=$overall6)"
else
  bad "UE-6: PATH chỉ có 'python' → rc=$rc, out='$(echo "$out" | tr '\n' ' ')', stderr='$(head -c 200 "$WORK/err.txt")'"
fi

out="$(minenv "$NOPY" "$BASH_ABS" "$SCRIPT" "$WORK/t.jsonl" 2>"$WORK/err.txt")"; rc=$?
if [ "$rc" -eq 0 ] && echo "$out" | grep -q '^OVERALL=NA$' \
   && grep -qF '[usage-estimate] không có python → bỏ qua ước tính' "$WORK/err.txt"; then
  ok "UE-7: không có python3/python → OVERALL=NA + nói ra ở stderr (không im lặng)"
else
  bad "UE-7: thiếu python → rc=$rc, out='$(echo "$out" | tr '\n' ' ')', stderr='$(head -c 200 "$WORK/err.txt")'"
fi

finish "usage-estimate.sh đạt toàn bộ ca kiểm (kể cả đối chứng định lượng)."
