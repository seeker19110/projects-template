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
fails=0  # ShellCheck không theo được source qua $ROOT; giữ biến đếm tường minh.

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

if [ "$fails" -eq 0 ]; then
  echo "OK — usage-estimate.sh đạt toàn bộ ca kiểm (kể cả đối chứng định lượng)."
  exit 0
fi
echo "FAIL — Có $fails ca thất bại."
exit 1
