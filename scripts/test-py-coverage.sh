#!/usr/bin/env bash
# test-py-coverage.sh — ĐỘ PHỦ DÒNG (line coverage) thật cho 4 engine Python.
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
trap 'rm -rf "$WORK"' EXIT

run() { "$PYTHON_CMD" -m coverage run -a --source=scripts "$@" >/dev/null 2>&1 || true; }

"$PYTHON_CMD" -m coverage erase >/dev/null 2>&1

echo "== Chạy 4 engine qua các luồng chính + đường lỗi =="

# --- spec-compiler: compile-all, một spec lẻ, JSON, spec không tồn tại, thiếu tham số ---
run scripts/spec-compiler.py --compile-all
run scripts/spec-compiler.py --compile-all --json
run scripts/spec-compiler.py --spec docs/specs/2026-09-13-quickstart-adoption.md --out-dir "$WORK/c1"
run scripts/spec-compiler.py --spec "$WORK/khong-ton-tai.md" --out-dir "$WORK/c2"
run scripts/spec-compiler.py

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
trap 'cleanup_probes; rm -rf "$WORK"' EXIT

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
run scripts/subagent-dispatch.py --tier khong-ton-tai
for h in claude hermes codex generic; do
  run scripts/subagent-dispatch.py --agent tester --task "Kiem tra" --harness "$h"
  run scripts/subagent-dispatch.py --agent tester --task "Kiem tra" --harness "$h" --json
done
printf 'ngu canh gia lap\n' > "$WORK/ctx.txt"
run scripts/subagent-dispatch.py --agent reviewer --task "T" --harness generic --context-file "$WORK/ctx.txt"
run scripts/subagent-dispatch.py --agent khong-ton-tai --task "T"
run scripts/subagent-dispatch.py

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
integrity_out="$("$PYTHON_CMD" -m coverage run -a --source=scripts -m unittest discover -s tests -p test_telemetry_integrity.py 2>&1)"
integrity_rc=$?
if [ "$integrity_rc" -ne 0 ]; then
  printf '%s\n' "$integrity_out" >&2
  echo "FAIL — telemetry integrity tests failed during coverage measurement."
  exit 1
fi

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
