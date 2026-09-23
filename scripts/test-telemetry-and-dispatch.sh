#!/usr/bin/env bash
# test-telemetry-and-dispatch.sh — Tự kiểm tra Universal Subagent Dispatch & Telemetry Engine.

set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
if command -v cygpath >/dev/null 2>&1; then ROOT="$(cygpath -m "$ROOT")"; fi

# shellcheck source=scripts/_test-lib.sh
source "$ROOT/scripts/_test-lib.sh"

echo "== 1. Subagent Dispatcher Engine =="

out_list="$(bash "$ROOT/scripts/subagent-dispatch.sh" --list 2>&1)"
if echo "$out_list" | grep -q "security-reviewer"; then
  ok "subagent-dispatch --list liệt kê thành công subagents"
else
  bad "subagent-dispatch --list thất bại"
fi

# --- A-03 (audit 2026-09-13): đầu ra cho mỗi harness phải là CƠ CHẾ CÓ THẬT ---
# Bản cũ sinh "/subagent <tên> <task>" cho Claude Code, nhưng .claude/commands/ không có
# subagent.md — dán vào Claude Code sẽ không chạy. Cơ chế thật là tool Task + subagent_type.
out_claude="$(bash "$ROOT/scripts/subagent-dispatch.sh" --agent tester --task "Kiem tra" --harness claude 2>&1)"
if echo "$out_claude" | grep -q '/subagent'; then
  bad "A-03: đầu ra cho Claude Code vẫn chứa '/subagent' — lệnh này KHÔNG tồn tại"
else
  ok "A-03: đầu ra cho Claude Code không còn lệnh '/subagent' không tồn tại"
fi
if echo "$out_claude" | grep -q 'subagent_type="tester"'; then
  ok "A-03: đầu ra nêu đúng cơ chế thật (tool Task + subagent_type)"
else
  bad "A-03: đầu ra không nêu tool Task/subagent_type"
fi

# Frontmatter `effort:` (2026-09-23) phải đi theo vai khi dispatch cho harness ngoài Claude Code.
out_generic="$(bash "$ROOT/scripts/subagent-dispatch.sh" --agent coordinator --task "x" --harness generic 2>&1)"
echo "$out_generic" | grep -q "(effort: low)" && ok "dispatch nêu effort từ frontmatter (coordinator: low)" || bad "dispatch không nêu effort từ frontmatter"

# Đối chứng: mọi lệnh slash sinh ra (nếu có) phải có file thật trong .claude/commands/.
for slash in $(echo "$out_claude" | grep -oE '(^|[[:space:]])/[a-z][a-z0-9-]*' | tr -d ' /' | sort -u); do
  if [ ! -f "$ROOT/.claude/commands/$slash.md" ]; then
    bad "A-03: đầu ra nhắc lệnh /$slash nhưng .claude/commands/$slash.md không tồn tại"
  fi
done

# Harness không được hỗ trợ phải BÁO LỖI rõ, không đoán bừa (FR-2).
if bash "$ROOT/scripts/subagent-dispatch.sh" --agent tester --task d --harness cursor >/dev/null 2>&1; then
  bad "A-03: harness 'cursor' chưa hỗ trợ nhưng vẫn chạy — đang đoán bừa"
else
  ok "A-03: harness chưa hỗ trợ → báo lỗi rõ, không đoán bừa"
fi

out_hermes="$(bash "$ROOT/scripts/subagent-dispatch.sh" --agent security-reviewer --task "Test Task" --harness hermes 2>&1)"
if echo "$out_hermes" | grep -q '"tasks"'; then
  ok "subagent-dispatch --harness hermes xuất JSON delegate_task hợp lệ"
else
  bad "subagent-dispatch --harness hermes thất bại"
fi

# Ca này TRƯỚC ĐÂY assert đầu ra PHẢI chứa "/subagent complex-implementer" — tức là test
# khoá chặt đúng cái lỗi A-03 thay vì bắt nó. Một test viết theo hành vi sai sẽ bảo vệ
# hành vi sai. Nay assert theo CƠ CHẾ THẬT của Claude Code.
out_claude_ci="$(bash "$ROOT/scripts/subagent-dispatch.sh" --agent complex-implementer --task "Test Task" --harness claude 2>&1)"
if echo "$out_claude_ci" | grep -q 'subagent_type="complex-implementer"'; then
  ok "subagent-dispatch --harness claude nêu đúng subagent_type cho tool Task"
else
  bad "subagent-dispatch --harness claude không nêu subagent_type đúng"
fi

# --- Đa model/đa nhà cung cấp (2026-09-15): --tier tra ứng viên theo cấp năng lực,
# không gắn cứng vào Claude — xem docs/framework/orchestration-3-tier.md.
out_tier="$(bash "$ROOT/scripts/subagent-dispatch.sh" --tier standard 2>&1)"
if echo "$out_tier" | grep -q "harness=claude" && echo "$out_tier" | grep -qi "google\|hermes\|opencode"; then
  ok "subagent-dispatch --tier standard liệt kê ứng viên đa nhà cung cấp"
else
  bad "subagent-dispatch --tier standard không liệt kê được ứng viên đa nhà cung cấp"
fi

if bash "$ROOT/scripts/subagent-dispatch.sh" --tier khong-ton-tai >/dev/null 2>&1; then
  bad "subagent-dispatch --tier chấp nhận giá trị không hợp lệ (choices= chưa chặn)"
else
  ok "subagent-dispatch --tier chặn giá trị không hợp lệ"
fi

echo "== 2. Telemetry & Observability Engine =="

out_rec="$(bash "$ROOT/scripts/telemetry-log.sh" --record --agent test-agent --harness test-harness --task "Self Test" --duration 1.5 --test-status PASSED 2>&1)"
if echo "$out_rec" | grep -q "Recorded telemetry entry"; then
  ok "telemetry-log --record ghi nhận entry thành công"
else
  bad "telemetry-log --record thất bại"
fi

out_sum="$(bash "$ROOT/scripts/telemetry-log.sh" --summary 2>&1)"
if echo "$out_sum" | grep -q "AI Execution & Observability Summary"; then
  ok "telemetry-log --summary sinh báo cáo Markdown thành công"
else
  bad "telemetry-log --summary thất bại"
fi

out_widget="$(bash "$ROOT/scripts/telemetry-log.sh" --widget 2>&1)"
if echo "$out_widget" | grep -q "::preview{file="; then
  ok "telemetry-log --widget sinh HTML widget thành công"
else
  bad "telemetry-log --widget thất bại"
fi

# --- Bảng giá phải PHỦ mọi model Anthropic khung gợi ý (audit 2026-09-23, C3) ---
# Trước đó `claude-opus-5-5` khớp khoá 'opus' 15/75 (giá đời cũ, sai ×3.75) và `claude-fable-5-1`
# rơi về 'default' — sai âm thầm vì không cổng nào so khoá giá với model đang dùng.
echo "== 3. Bảng giá khớp model đang dùng =="
hinted="$(python3 - "$ROOT/scripts/model-capability-tiers.json" <<'PY'
import json, re, sys
d = json.load(open(sys.argv[1], encoding="utf-8"))
ids = set()
for t in d["tiers"].values():
    for c in t["candidates"]:
        if c.get("provider") == "anthropic":
            ids.update(re.findall(r"claude-[a-z0-9-]+", c.get("model_hint", "")))
print(" ".join(sorted(ids)))
PY
)"
for m in $hinted claude-fable-5-1 claude-opus-5-5 claude-sonnet-5 claude-haiku-4-5-20251001; do
  err="$(bash "$ROOT/scripts/telemetry-log.sh" --record --model "$m" --agent rate-check --task "rate $m" \
         --input-tokens 1000000 --output-tokens 0 2>&1 >/dev/null)"
  if echo "$err" | grep -q "không có trong bảng giá"; then
    bad "model '$m' không có khoá giá riêng trong model-rates.json (rơi về default)"
  else
    ok "model '$m' có khoá giá"
  fi
done
# Giá phải khớp nguồn sống 2026-09-23 (platform.claude.com/docs/en/about-claude/pricing), không phải đời cũ.
py_rate() { python3 -c "import json,sys; r=json.load(open('$ROOT/scripts/model-rates.json', encoding='utf-8'))['rates']; print(r['$1']['input'], r['$1']['output'])" 2>/dev/null; }
[ "$(py_rate opus-5-5)" = "4.0 20.0" ] && ok "opus-5-5 = 4/20" || bad "opus-5-5 phải là 4/20 (đang: $(py_rate opus-5-5))"
[ "$(py_rate fable-5-1)" = "10.0 50.0" ] && ok "fable-5-1 = 10/50" || bad "fable-5-1 phải là 10/50 (đang: $(py_rate fable-5-1))"
[ "$(py_rate sonnet)" = "2.0 10.0" ] && ok "sonnet = 2/10" || bad "sonnet phải là 2/10 (đang: $(py_rate sonnet))"

# --- Không có token thật → chi phí 0 + cảnh báo, KHÔNG bịa 1000/500 (C4, CLAUDE.md §4) ---
echo "== 4. Không bịa token khi không được cấp =="
err0="$(bash "$ROOT/scripts/telemetry-log.sh" --record --model claude-sonnet-5 --agent zero-check --task "zero" 2>&1 >/dev/null)"
last_cost="$(python3 -c "import json; l=json.load(open('$ROOT/.ai-telemetry/telemetry.json', encoding='utf-8')); print(l[-1]['est_cost_usd'], l[-1]['input_tokens'], l[-1]['output_tokens'])")"
if [ "$last_cost" = "0.0 0 0" ] || [ "$last_cost" = "0 0 0" ]; then
  ok "record không token → input=0, output=0, est_cost=0"
else
  bad "record không token vẫn ghi số bịa: $last_cost"
fi
echo "$err0" | grep -q "không có số token" && ok "có cảnh báo stderr khi thiếu token" || bad "thiếu cảnh báo stderr khi không có token"

if [ "$fails" -eq 0 ]; then
  echo "OK — Tất cả kiểm tra Universal Subagent Dispatch & Telemetry đều XANH."
  exit 0
else
  echo "FAIL — Có $fails ca kiểm tra thất bại."
  exit 1
fi
