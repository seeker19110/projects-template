#!/usr/bin/env bash
# test-telemetry-and-dispatch.sh — Tự kiểm tra Universal Subagent Dispatch & Telemetry Engine.

set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
if command -v cygpath >/dev/null 2>&1; then ROOT="$(cygpath -m "$ROOT")"; fi

# shellcheck source=scripts/_test-lib.sh
source "$ROOT/scripts/_test-lib.sh"
fails=0

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

echo "== 1b. Dispatcher chỉ chuẩn bị, context không bị bỏ im lặng (LD-05/AC-5) =="
err_prep="$(bash "$ROOT/scripts/subagent-dispatch.sh" --agent tester --task t --harness codex 2>&1 >/dev/null)"
echo "$err_prep" | grep -q "prepare-only" && ok "dispatch nói rõ prepare-only (không chạy agent, không cấp quyền)" || bad "dispatch không nói rõ prepare-only"
json_prep="$(bash "$ROOT/scripts/subagent-dispatch.sh" --agent tester --task t --harness claude --json 2>/dev/null)"
echo "$json_prep" | grep -q '"executed": false' && ok "payload JSON có executed=false" || bad "payload JSON thiếu executed=false"
if bash "$ROOT/scripts/subagent-dispatch.sh" --agent tester --task t --context-file "$ROOT/khong-co-file-nay.txt" >/dev/null 2>&1; then
  bad "--context-file thiếu vẫn thoát 0 (context bị bỏ im lặng)"
else
  ok "--context-file thiếu → thoát khác 0"
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

# --- Không có token thật → unknown (null) + cảnh báo, KHÔNG bịa 1000/500 (C4) và KHÔNG ghi 0 (LD-07/AC-7) ---
echo "== 4. Không bịa token khi không được cấp =="
err0="$(bash "$ROOT/scripts/telemetry-log.sh" --record --model claude-sonnet-5 --agent zero-check --task "zero" 2>&1 >/dev/null)"
last_cost="$(python3 -c "import json; l=json.load(open('$ROOT/.ai-telemetry/telemetry.json', encoding='utf-8')); print(l[-1]['est_cost_usd'], l[-1]['input_tokens'], l[-1]['output_tokens'])")"
if [ "$last_cost" = "None None None" ]; then
  ok "record không token → input/output/est_cost = null (unknown), không phải 0"
else
  bad "record không token vẫn ghi số bịa: $last_cost"
fi
echo "$err0" | grep -q "unknown" && ok "có cảnh báo stderr khi thiếu token" || bad "thiếu cảnh báo stderr khi không có token"

echo "== 5. Nhật ký telemetry giữ dữ liệu khi lỗi và khi ghi song song =="
integrity_out="$(cd "$ROOT" && python3 -m unittest discover -s tests -p test_telemetry_integrity.py 2>&1)"
integrity_rc=$?
# Không ghim số ca (`^Ran 15 tests`): thêm ca vào file kia làm đỏ oan file này. unittest in `OK` (có thể kèm
# `(skipped=N)`) ở cuối khi mọi ca đạt; rc=0 + dòng `OK` là đủ, số ca thật đọc từ dòng `Ran N tests`.
integrity_ran="$(printf '%s\n' "$integrity_out" | sed -n 's/^Ran \([0-9]*\) tests\{0,1\}.*/\1/p' | tail -n 1)"
if [ "$integrity_rc" -eq 0 ] && printf '%s\n' "$integrity_out" | grep -q '^OK'; then
  ok "${integrity_ran:-?} ca toàn vẹn telemetry: JSON lỗi, schema, ghi lỗi, ghi đồng thời, chờ khoá, usage unknown, lần thử/nghiệm thu"
else
  bad "telemetry integrity thất bại (rc=$integrity_rc)"
  printf '%s\n' "$integrity_out" >&2
fi

if [ "$fails" -eq 0 ]; then
  echo "OK — Tất cả kiểm tra Universal Subagent Dispatch & Telemetry đều XANH."
  exit 0
else
  echo "FAIL — Có $fails ca kiểm tra thất bại."
  exit 1
fi
