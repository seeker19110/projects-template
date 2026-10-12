#!/usr/bin/env bash
# test-py-coverage.sh — ĐỘ PHỦ DÒNG (line coverage) thật cho 5 engine Python.
#
# KHÁC với "độ phủ cổng" mà arch-health-radar đo (script nào có test chạy trong CI):
# cái đó trả lời "có ai canh không", cái này trả lời "test chạm được bao nhiêu dòng".
# Một script có test nhưng test chỉ gọi `--help` thì độ phủ cổng = 100% mà độ phủ dòng ~ 0.
#
# Ngưỡng là SÀN, không phải mục tiêu: hạ ngưỡng để CI xanh là tự bịt mắt mình.
# Nâng ngưỡng khi thêm ca test; muốn hạ thì phải nêu lý do trong PR.

set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
if command -v cygpath >/dev/null 2>&1; then ROOT="$(cygpath -m "$ROOT")"; fi
cd "$ROOT" || exit 1

THRESHOLD="${PY_COVERAGE_MIN:-95}"

PYTHON_CMD="python3"
command -v python3 >/dev/null 2>&1 || PYTHON_CMD="python"

if ! "$PYTHON_CMD" -m coverage --version >/dev/null 2>&1; then
  # CỐ Ý đỏ chứ không "skip": một cổng tự tắt khi thiếu công cụ là cổng xanh giả.
  echo "::error::Thiếu coverage.py — cài bằng: $PYTHON_CMD -m pip install coverage" >&2
  exit 1
fi

WORK="$(mktemp -d)"
trap 'rm -r "$WORK"' EXIT

run() {
  "$PYTHON_CMD" -m coverage run -a --source=scripts "$@" >"$WORK/probe-output" 2>&1
  local rc=$?
  if [ "$rc" -ne 0 ]; then
    echo "::error::Success probe failed (exit $rc): $*" >&2
    cat "$WORK/probe-output" >&2
    exit 1
  fi
}

run_expected_failure() {
  if "$PYTHON_CMD" -m coverage run -a --source=scripts "$@" >"$WORK/probe-output" 2>&1; then
    echo "::error::Expected failure probe succeeded: $*" >&2
    exit 1
  fi
}

"$PYTHON_CMD" -m coverage erase >/dev/null 2>&1

echo "== Chạy 5 engine qua các luồng chính + đường lỗi =="

# --- spec-compiler: compile-all, một spec lẻ, JSON, spec không tồn tại, thiếu tham số ---
run scripts/spec-compiler.py --compile-all
run scripts/spec-compiler.py --compile-all --json
run scripts/spec-compiler.py --spec docs/specs/2026-09-13-quickstart-adoption.md --out-dir "$WORK/c1"
# Missing spec is an empty compile result (exit 0) in this CLI, not an error exit.
run scripts/spec-compiler.py --spec "$WORK/khong-ton-tai.md" --out-dir "$WORK/c2"
run_expected_failure scripts/spec-compiler.py

# --- arch-health-radar: báo cáo Markdown + JSON ---
run scripts/arch-health-radar.py --scan
run scripts/arch-health-radar.py --json

# Các nhánh CẢNH BÁO của radar (script không cổng, file mã dài, tài liệu dài, spec yếu, TODO)
# chỉ chạy khi repo CÓ khiếm khuyết — mà repo đang sạch 100/100 nên chúng không bao giờ được
# chạm. Dựng khiếm khuyết TẠM THỜI để chạm đúng những nhánh đó, rồi dọn sạch.
# Đây chính là phần mã quan trọng nhất khi repo KHÔNG khoẻ, nên không được để trắng.
PROBE_SCRIPT="scripts/zz-probe-coverage-$$.sh"
# .sh chứ KHÔNG .py: --source=scripts sẽ theo dõi file .py rồi báo lỗi "No source"
# khi ta xoá nó đi. Radar tính cả .sh là file mã nên vẫn chạm đúng nhánh cần.
PROBE_LONG="scripts/zz-probe-long-$$.sh"
PROBE_DOC="docs/zz-probe-doc-$$.md"
PROBE_SPEC="docs/specs/2099-12-31-zz-probe-$$.md"
cleanup_probes() { rm -f "$ROOT/$PROBE_SCRIPT" "$ROOT/$PROBE_LONG" "$ROOT/$PROBE_DOC" "$ROOT/$PROBE_SPEC"; }
cleanup_all() {
  cleanup_probes
  if [ -f "$WORK/rates.bak" ]; then cp "$WORK/rates.bak" scripts/model-rates.json; fi
  if [ -f "$WORK/tiers.bak" ]; then cp "$WORK/tiers.bak" scripts/model-capability-tiers.json; fi
  rm -r "$WORK"
}
trap cleanup_all EXIT

printf '#!/usr/bin/env bash\nexit 0\n' > "$ROOT/$PROBE_SCRIPT"
{ printf '#!/usr/bin/env bash\n# TODO: dau hieu no ky thuat gia lap\n'; for _ in $(seq 1 420); do printf 'true\n'; done; } > "$ROOT/$PROBE_LONG"
for _ in $(seq 1 950); do printf 'dong tai lieu gia lap\n'; done > "$ROOT/$PROBE_DOC"
printf '# Feature spec: probe yeu\n\nKhong co ma yeu cau, khong co muc touchpoints.\n' > "$ROOT/$PROBE_SPEC"

run scripts/arch-health-radar.py --scan
run scripts/arch-health-radar.py --json
cleanup_probes

# --- subagent-dispatch: list, TỪNG harness, context-file, JSON, agent không tồn tại ---
run scripts/subagent-dispatch.py --list
run scripts/subagent-dispatch.py --list --json
# --tier: đa nhà cung cấp (ADR-0006) — happy path text + JSON, và cấp không tồn tại (đường lỗi)
run scripts/subagent-dispatch.py --tier standard
run scripts/subagent-dispatch.py --tier standard --json
run_expected_failure scripts/subagent-dispatch.py --tier khong-ton-tai
# --tier với bảng cấp hỏng: mỗi ca một nguyên nhân, đều phải thoát khác 0 (bản gốc phục hồi ngay sau).
cp scripts/model-capability-tiers.json "$WORK/tiers.bak"
rm scripts/model-capability-tiers.json
run scripts/subagent-dispatch.py --list
run_expected_failure scripts/subagent-dispatch.py --tier standard
for bad_tiers in '{ hong json' '[]' '{"tiers": []}' '{"tiers": {"standard": "x"}}' '{"tiers": {"standard": {"candidates": "x"}}}'; do
  printf '%s' "$bad_tiers" > scripts/model-capability-tiers.json
  run_expected_failure scripts/subagent-dispatch.py --tier standard
done
# Ứng viên thiếu khoá → cảnh báo + in '?', vẫn thoát 0.
printf '{"tiers": {"standard": {"desc": "d", "candidates": [{"provider": "p"}]}}}' > scripts/model-capability-tiers.json
run scripts/subagent-dispatch.py --tier standard
cp "$WORK/tiers.bak" scripts/model-capability-tiers.json
for h in claude hermes codex generic; do
  run scripts/subagent-dispatch.py --agent tester --task "Kiem tra" --harness "$h"
  run scripts/subagent-dispatch.py --agent tester --task "Kiem tra" --harness "$h" --json
done
printf 'ngu canh gia lap\n' > "$WORK/ctx.txt"
run scripts/subagent-dispatch.py --agent reviewer --task "T" --harness generic --context-file "$WORK/ctx.txt"
run_expected_failure scripts/subagent-dispatch.py --agent khong-ton-tai --task "T"
run_expected_failure scripts/subagent-dispatch.py --agent reviewer --task "T" --context-file "$WORK/khong-co.txt"
run_expected_failure scripts/subagent-dispatch.py --agent reviewer --task "T" --context-file "$WORK/ctx.txt" --max-context-bytes 1
run_expected_failure scripts/subagent-dispatch.py
# --check-plan: PLAN hợp lệ (0), PLAN hỏng (1: thiếu trường/placeholder/route lạ/vòng/PR), file thiếu (2)
cat > "$WORK/plan-ok.md" <<'PLAN'
## Nhóm PR (đơn vị mở PR)
- **PR-1** (a): gồm việc T1, T2 — độc lập
## Danh sách việc
### T1 — Viec A   `route: standard`
- Điểm chạm: `a.py`
- Đặc tả: lam A
- Phụ thuộc: none
- Tiêu chí chấp nhận: test A xanh
### T2 — Viec B   `route: mechanical`
- Điểm chạm: `b.md`
- Đặc tả: noi khoi
```
khoi
```
- Phụ thuộc: T1
- Tiêu chí chấp nhận: tail khop
PLAN
run scripts/subagent-dispatch.py --check-plan "$WORK/plan-ok.md"
cat > "$WORK/plan-bad.md" <<'PLAN'
## Nhóm PR (đơn vị mở PR)
- **PR-1** (a): gồm việc T1, T1, T7 — độc lập
## Danh sách việc
### T1 — Viec A   `route: wizard`
- Điểm chạm: `docs/*.md`
- Đặc tả: <điền>
- Phụ thuộc: T2
### T2 — Viec B   `route: mechanical`
- Phụ thuộc: T1
PLAN
run_expected_failure scripts/subagent-dispatch.py --check-plan "$WORK/plan-bad.md"
run_expected_failure scripts/subagent-dispatch.py --check-plan "$WORK/khong-co-plan.md"

# --- loop-state (loop-state.py + parser thuần _loop_state_parse.py): mọi nhánh verdict FR-3 trên repo giả dựng tại chỗ (ADR-0012), gh giả qua PATH, ca exit 2/1, không gh ---
LS="$WORK/ls"; LSID="2026-10-12-probe"
ls_work() {   # $1 trạng thái, $2 dòng "Lần thử / blocker", $3 Bàn giao
  mkdir -p "$LS/docs/work/$LSID"
  printf -- '# x\n\n- Work ID: %s\n- Trạng thái: %s\n- Mức rủi ro / số PR: S\n- Spec / goal / issue: docs/goals/g.md\n- Nhánh / base SHA / thời điểm reconcile: `main` @ `abc1234`\n\n## Lần thử / blocker\n\n%s\n\n## Bàn giao / bước tiếp theo\n\n%s\n' \
    "$LSID" "$1" "$2" "$3" > "$LS/docs/work/$LSID/working.md"
}
ls_goal() { printf '| Thuộc tính | Giá trị |\n| --- | --- |\n| State | ACTIVE |\n\n| ID | Dependency | State | Evidence |\n| --- | --- | --- | --- |\n%b' "$1" > "$LS/docs/goals/g.md"; }
ls_plan() { printf '## Definition of Complete\n- [%s] a\n\n## Đợt 1\n| ID | Việc | Trạng thái |\n|---|---|---|\n| W-1 | a | %s |\n| W-2 | b | ✅ |\n| W-3 | c | ➖ |\n' "$1" "$2" > "$LS/docs/ops/COMPLETION-PLAN.md"; }
ls_git() { git -C "$LS" add -A && git -C "$LS" commit -q --allow-empty -m probe; }
lsr() { run scripts/loop-state.py --root "$LS" --work-id "$LSID" --json; }
mkdir -p "$LS/docs/goals" "$LS/docs/ops" "$LS/.claude" "$WORK/lsbin" "$WORK/lsnogh"
git -C "$LS" init -q -b main; git -C "$LS" config user.name p; git -C "$LS" config user.email p@example.invalid
printf '.claude/.gate-red-streak\n.claude/.auto-complete-loop\n' > "$LS/.gitignore"
ls_work "Active" "- chưa có failure" "Làm S2."
ls_goal '| S1 | — | DONE | PR #1 |\n| S2 | S1 | BUILD | |\n| S3 | S2 | BACKLOG | |\n'
ls_plan " " "🔄"; printf -- '- [ ] smoke\n' > "$LS/docs/ops/release-readiness.md"; ls_git
cat > "$WORK/lsbin/gh" <<'GH'
#!/usr/bin/env bash
case "${LS_GH:-}" in fail) echo "gh: auth" >&2; exit 1 ;; bad) echo "{" ;; obj) echo "{}" ;; *) printf '%s\n' "${LS_GH_JSON:-[]}" ;; esac
GH
chmod +x "$WORK/lsbin/gh"
for t in python3 git; do ln -s "$(command -v "$t")" "$WORK/lsnogh/$t"; done
LS_PATH="$PATH"; export PATH="$WORK/lsbin:$LS_PATH"
run scripts/loop-state.py --root "$LS" --enter
run scripts/loop-state.py --root "$LS" --enter --brief
run scripts/loop-state.py --root "$LS" --brief
run scripts/loop-state.py --root "$LS" --fingerprint
run scripts/loop-state.py --work-id 2026-10-12-redesign-auto-complete-loop --json
rm "$LS/.claude/.auto-complete-loop"
run_expected_failure scripts/loop-state.py --root "$LS" --work-id ../x --json
run_expected_failure scripts/loop-state.py --root "$LS" --work-id 2099-01-01-khong-co
run_expected_failure scripts/loop-state.py --root "$WORK/khong-co-thu-muc"
for st in "Blocked — chờ" "Waiting — CI"; do ls_work "$st" "-" "-"; lsr; done
ls_work "Active" "- lỗi ở tầng ① vì spec" "Làm S2."
for streak in "n=3" "n=2"; do printf '%s\nsig=FAIL: x\n' "$streak" > "$LS/.claude/.gate-red-streak"; lsr; done
for line in "- lỗi ở tầng ③" "- lại đỏ ở test" "- spec sai" "- không rõ"; do ls_work "Active" "$line" "Làm S2."; lsr; done
rm "$LS/.claude/.gate-red-streak"; ls_work "Active" "-" "Làm S2."; lsr
for j in '[{"number":3,"mergeable":"MERGEABLE","autoMergeRequest":null,"statusCheckRollup":[{"conclusion":"FAILURE"}]}]' \
         '[{"number":4,"statusCheckRollup":[{"status":"IN_PROGRESS","conclusion":""}]}]' \
         '[{"number":5,"statusCheckRollup":[{"state":"SUCCESS"}]},{"number":6,"statusCheckRollup":[]},{"number":7,"statusCheckRollup":[{"conclusion":"STALE"}]}]'; do
  export LS_GH_JSON="$j"; ls_git; lsr
done
unset LS_GH_JSON
for mode in fail bad obj; do export LS_GH="$mode"; lsr; done
unset LS_GH
export PATH="$WORK/lsnogh"; lsr; export PATH="$WORK/lsbin:$LS_PATH"
ls_goal '| S1 | — | DONE | |\n'; ls_git; lsr
ls_goal '| S1 | none | BLOCKED | |\n'; ls_git; lsr
ls_goal '| S1 | baseline | DONE | PR #1 |\n'; ls_git; lsr
ls_plan "x" "✅"; ls_git; lsr
printf -- '- [x] smoke\n' > "$LS/docs/ops/release-readiness.md"; ls_plan " " "✅"; ls_git; lsr
ls_plan "x" "✅"; ls_git; lsr
mv "$LS/docs/work/$LSID/working.md" "$LS/docs/work/$LSID/done.md"; lsr
run_expected_failure scripts/loop-state.py --root "$LS" --json
mv "$LS/docs/work/$LSID/done.md" "$LS/docs/work/$LSID/working.md"
rm -r "$LS/docs/goals" "$LS/docs/ops"; ls_git; lsr
ls_work "Active" "-" "<placeholder>"; ls_git; lsr
git clone -q --bare "$LS" "$LS.git"; git -C "$LS" remote add origin "$LS.git"; git clone -q "$LS.git" "$LS.o"
git -C "$LS.o" -c user.name=p -c user.email=p@example.invalid commit --allow-empty -q -m tren-main
git -C "$LS.o" push -q origin main; git -C "$LS" fetch -q origin; git -C "$LS" remote set-head origin main; lsr
export PATH="$LS_PATH"

# --- telemetry-log: record (nhiều model), summary, widget, và ĐƯỜNG LỖI bảng giá ---
for m in claude-opus-5 claude-sonnet-5 claude-haiku-4-5 gpt-4o model-la-hoac-gi-do; do
  run scripts/telemetry-log.py --record --model "$m" --task "Ca do phu $m" \
      --input-tokens 1000 --output-tokens 500 --diff-loc 10 --test-status PASSED
done
run scripts/telemetry-log.py --record --model sonnet --task "Ca FAILED" --test-status FAILED
run scripts/telemetry-log.py --summary
run scripts/telemetry-log.py --widget

# Đường lỗi: bảng giá hỏng -> phải thoát khác 0 (kiểm luôn hành vi, không chỉ để lấy độ phủ).
cp scripts/model-rates.json "$WORK/rates.bak"
printf '{ hong json' > scripts/model-rates.json
if "$PYTHON_CMD" -m coverage run -a --source=scripts scripts/telemetry-log.py --record >/dev/null 2>&1; then
  cp "$WORK/rates.bak" scripts/model-rates.json
  echo "  ❌ bảng giá hỏng JSON nhưng vẫn chạy tiếp — phải thoát khác 0"
  exit 1
fi
printf '{"rates": {}}' > scripts/model-rates.json
if "$PYTHON_CMD" -m coverage run -a --source=scripts scripts/telemetry-log.py --record >/dev/null 2>&1; then
  cp "$WORK/rates.bak" scripts/model-rates.json
  echo "  ❌ bảng giá thiếu khoá 'default' nhưng vẫn chạy tiếp — phải thoát khác 0"
  exit 1
fi
cp "$WORK/rates.bak" scripts/model-rates.json
echo "  ✅ bảng giá hỏng/thiếu 'default' → thoát khác 0 (không ước tính bằng số bịa)"

# Exercise the data-loss/error paths as part of measured coverage, not only the CLI happy path.
for test_file in test_telemetry_integrity.py test_delivery_handoff_integrity.py test_acceptance_trace.py; do
  integrity_out="$("$PYTHON_CMD" -m coverage run -a --source=scripts -m unittest discover -s tests -p "$test_file" 2>&1)"
  integrity_rc=$?
  if [ "$integrity_rc" -ne 0 ]; then
    printf '%s\n' "$integrity_out" >&2
    echo "FAIL — $test_file failed during coverage measurement."
    exit 1
  fi
done

echo
echo "== Báo cáo độ phủ dòng (sàn: ${THRESHOLD}%) =="
"$PYTHON_CMD" -m coverage report -m --fail-under="$THRESHOLD"
rc=$?
"$PYTHON_CMD" -m coverage erase >/dev/null 2>&1

if [ "$rc" -eq 0 ]; then
  echo "OK — độ phủ dòng đạt sàn ${THRESHOLD}%."
  exit 0
fi
echo "FAIL — độ phủ dòng DƯỚI sàn ${THRESHOLD}%. Thêm ca test, đừng hạ sàn."
exit 1
