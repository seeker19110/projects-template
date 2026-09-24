#!/usr/bin/env bash
# Smoke test cho copy-framework.sh / copy-framework.ps1: chạy thật vào thư mục scratch,
# xác nhận (1) cấu trúc copy đúng như tài liệu mô tả (Lớp 1 copy thẳng, Lớp 2 vào
# _framework-dropins/), (2) KHÔNG đè file đã có ở dự án đích, (3) chạy lại lần hai
# không lỗi. copy-framework.ps1 chỉ được kiểm nếu máy có `pwsh` (luôn có trên
# runner ubuntu-latest của GitHub Actions).
# Chạy: bash scripts/test-copy-framework.sh
set -uo pipefail   # cố ý KHÔNG -e: không được làm chết phiên/lượt chạy (xem docs/CONVENTIONS.md §A)

cd "$(git rev-parse --show-toplevel)" || exit 1
REPO_ROOT="$(pwd)"
fail=0
tmp_dirs=()
cleanup() { [ "${#tmp_dirs[@]}" -eq 0 ] || rm -rf "${tmp_dirs[@]}"; }
trap cleanup EXIT

new_target() {
  local t
  t="$(mktemp -d)"
  git init -q "$t"
  tmp_dirs+=("$t")
  printf '%s' "$t"
}

run_logged() {          # run_logged <mô tả> <lệnh...>
  local desc="$1"; shift
  if "$@" >/tmp/copy-framework-test.log 2>&1; then
    return 0
  fi
  echo "  FAIL [$desc]: script thoát lỗi — log:"
  sed 's/^/    /' /tmp/copy-framework-test.log
  fail=1
  return 1
}

check_structure() {     # check_structure <mô tả> <target>
  local label="$1" target="$2" ok=1
  [ -f "$target/docs/framework/new-project-runbook.md" ] || { echo "  FAIL [$label]: thiếu docs/framework/new-project-runbook.md"; ok=0; }
  [ -f "$target/docs/framework/standard-delivery.md" ] || { echo "  FAIL [$label]: thiếu Standard Delivery Contract"; ok=0; }
  [ -f "$target/docs/framework/templates/GOAL.template.md" ] || { echo "  FAIL [$label]: thiếu GOAL template"; ok=0; }
  [ -f "$target/docs/framework/templates/FEATURE-SPEC.template.md" ] || { echo "  FAIL [$label]: thiếu FEATURE-SPEC template"; ok=0; }
  [ -d "$target/.claude/commands" ] && [ -f "$target/.claude/commands/gate.md" ] || { echo "  FAIL [$label]: thiếu .claude/commands/gate.md"; ok=0; }
  [ -f "$target/.claude/settings.json" ] || { echo "  FAIL [$label]: thiếu .claude/settings.json"; ok=0; }
  [ -d "$target/.claude/agents" ] || { echo "  FAIL [$label]: thiếu .claude/agents/"; ok=0; }
  [ -f "$target/CLAUDE.md" ] || { echo "  FAIL [$label]: thiếu CLAUDE.md"; ok=0; }
  [ -f "$target/_framework-dropins/.github/workflows/pr-policy.yml" ] || { echo "  FAIL [$label]: thiếu PR policy drop-in"; ok=0; }
  [ -f "$target/_framework-dropins/.github/workflows/dependency-review.yml" ] || { echo "  FAIL [$label]: thiếu Dependency Review drop-in"; ok=0; }
  [ -f "$target/_framework-dropins/.github/workflows/maintenance.yml" ] || { echo "  FAIL [$label]: thiếu Maintenance sweep drop-in"; ok=0; }
  [ -f "$target/_framework-dropins/.github/workflows/codeql.yml" ] && [ -f "$target/_framework-dropins/.github/workflows/scorecard.yml" ] || { echo "  FAIL [$label]: thiếu CodeQL/Scorecard drop-in"; ok=0; }
  [ -f "$target/scripts/requirements-ci.txt" ] || { echo "  FAIL [$label]: thiếu scripts/requirements-ci.txt (ci.yml dropin cần)"; ok=0; }
  [ -f "$target/scripts/_stack-detect.sh" ] && [ -x "$target/scripts/githooks/pre-commit" ] || { echo "  FAIL [$label]: thiếu scripts/_stack-detect.sh hoặc scripts/githooks/pre-commit (dev-task/sweep source; hook harness-agnostic)"; ok=0; }
  ( cd "$target" && bash scripts/dev-task.sh --print lint >/dev/null 2>&1 ) || { echo "  FAIL [$label]: dev-task.sh --print không chạy được ở đích (thiếu _stack-detect.sh?)"; ok=0; }
  [ -x "$target/scripts/maintenance-sweep.sh" ] && [ -x "$target/scripts/maintain-run.sh" ] || { echo "  FAIL [$label]: thiếu/không chạy được maintenance-sweep.sh hoặc maintain-run.sh"; ok=0; }
  [ -f "$target/docs/ops/repository-settings.md" ] || { echo "  FAIL [$label]: thiếu repository settings baseline"; ok=0; }
  [ -f "$target/docs/ops/supply-chain.md" ] || { echo "  FAIL [$label]: thiếu supply-chain guidance"; ok=0; }
  [ -f "$target/docs/framework/templates/THREAT-MODEL.template.md" ] || { echo "  FAIL [$label]: thiếu threat model template"; ok=0; }
  [ -f "$target/_framework-dropins/.github/ISSUE_TEMPLATE/goal.yml" ] || { echo "  FAIL [$label]: thiếu Goal Issue Form"; ok=0; }
  [ -f "$target/docs/framework/templates/FEATURE-MAP.template.md" ] || { echo "  FAIL [$label]: thiếu docs/framework/templates/FEATURE-MAP.template.md"; ok=0; }
  [ -f "$target/docs/framework/templates/TRAPS.template.md" ] || { echo "  FAIL [$label]: thiếu TRAPS template"; ok=0; }
  [ -f "$target/docs/framework/templates/CODEMAP.template.md" ] || { echo "  FAIL [$label]: thiếu CODEMAP template"; ok=0; }
  [ -f "$target/docs/framework/templates/GOLDEN-TEST.template.md" ] || { echo "  FAIL [$label]: thiếu GOLDEN-TEST template"; ok=0; }
  [ -f "$target/_framework-dropins/scripts/ci-workflow-policy.test.ts" ] || { echo "  FAIL [$label]: thiếu ci-workflow-policy.test.ts drop-in"; ok=0; }
  [ ! -e "$target/TRAPS.md" ] || { echo "  FAIL [$label]: TRAPS.md của khung (nhật ký riêng) bị copy sang gốc dự án đích"; ok=0; }
  [ ! -e "$target/CODEMAP.md" ] || { echo "  FAIL [$label]: CODEMAP.md của khung (nhật ký riêng) bị copy sang gốc dự án đích"; ok=0; }
  for st in MAINTENANCE-LOG.md MAINTENANCE-PLAN.md COMPLETION-PLAN.md COMPREHENSIVE-AUDIT-STATUS.md; do
    [ ! -e "$target/docs/ops/$st" ] || { echo "  FAIL [$label]: docs/ops/$st (trạng thái nội bộ của khung) bị copy sang dự án đích"; ok=0; }
  done
  [ -f "$target/docs/specs/README.md" ] && [ -f "$target/docs/goals/README.md" ] || { echo "  FAIL [$label]: thiếu docs/specs/README.md hoặc docs/goals/README.md (pr-policy.yml đòi docs/specs/)"; ok=0; }
  if [ -f "$target/docs/framework/FRAMEWORK-VERSION" ] && grep -q "^commit-nguon: " "$target/docs/framework/FRAMEWORK-VERSION"; then
    :
  else
    echo "  FAIL [$label]: thiếu/hỏng docs/framework/FRAMEWORK-VERSION (dấu bản khung)"; ok=0
  fi
  if [ "$label" = "bash / đích trống" ]; then   # phiên bản + manifest (spec 2026-09-23 nâng bản khung, AC-1) — bản .ps1 chỉ ghi commit
    grep -q "^version: $(cat "$REPO_ROOT/VERSION")$" "$target/docs/framework/FRAMEWORK-VERSION" 2>/dev/null \
      || { echo "  FAIL [$label]: FRAMEWORK-VERSION thiếu 'version:' khớp file VERSION"; ok=0; }
    [ "$(grep -c '^manifest: ' "$target/docs/framework/FRAMEWORK-VERSION" 2>/dev/null)" -gt 0 ] \
      || { echo "  FAIL [$label]: FRAMEWORK-VERSION thiếu dòng 'manifest:' (hash từng file Lớp 1)"; ok=0; }
  fi
  [ "$ok" -eq 1 ] && echo "  ok [$label]: cấu trúc copy đúng kỳ vọng" || fail=1
}

check_no_overwrite() {  # check_no_overwrite <mô tả> <target>
  local label="$1" target="$2"
  if grep -q "SENTINEL-KHONG-DUOC-DE" "$target/CLAUDE.md" 2>/dev/null; then
    echo "  ok [$label]: CLAUDE.md sẵn có KHÔNG bị đè"
  else
    echo "  FAIL [$label]: CLAUDE.md sẵn có đã bị đè!"
    fail=1
  fi
  if [ -f "$target/CLAUDE.md.framework-new" ]; then
    echo "  ok [$label]: bản khung để cạnh ở CLAUDE.md.framework-new"
  else
    echo "  FAIL [$label]: thiếu CLAUDE.md.framework-new khi đích đã có CLAUDE.md"
    fail=1
  fi
}

check_claude_config_not_overwritten() {   # check_claude_config_not_overwritten <mô tả> <target>
  local label="$1" target="$2"
  if grep -q "SENTINEL-KHONG-DUOC-DE" "$target/.claude/settings.json" 2>/dev/null; then
    echo "  ok [$label]: .claude/settings.json sẵn có KHÔNG bị đè"
  else
    echo "  FAIL [$label]: .claude/settings.json sẵn có đã bị đè!"
    fail=1
  fi
  [ -f "$target/.claude/settings.json.framework-new" ] \
    && echo "  ok [$label]: bản khung để cạnh ở settings.json.framework-new" \
    || { echo "  FAIL [$label]: thiếu settings.json.framework-new"; fail=1; }
  if grep -q "SENTINEL-KHONG-DUOC-DE" "$target/.claude/hooks/my-hook.sh" 2>/dev/null; then
    echo "  ok [$label]: .claude/hooks sẵn có KHÔNG bị đè"
  else
    echo "  FAIL [$label]: .claude/hooks sẵn có đã bị đè!"
    fail=1
  fi
  [ -d "$target/.claude/hooks.framework-new" ] \
    && echo "  ok [$label]: bản khung để cạnh ở hooks.framework-new" \
    || { echo "  FAIL [$label]: thiếu hooks.framework-new"; fail=1; }
}

check_ops_state_kept() {  # check_ops_state_kept <mô tả> <target> — chạy lại copy KHÔNG được xoá nhật ký của đích
  local label="$1" target="$2"
  if grep -q "SENTINEL-NHAT-KY-DICH" "$target/docs/ops/MAINTENANCE-LOG.md" 2>/dev/null; then
    echo "  ok [$label]: docs/ops/MAINTENANCE-LOG.md của đích KHÔNG bị đè khi chạy lại"
  else
    echo "  FAIL [$label]: docs/ops/MAINTENANCE-LOG.md của đích bị đè bằng nhật ký của repo khung (mất dữ liệu)!"
    fail=1
  fi
}

echo "== bash / đích trống =="
targetA="$(new_target)"
run_logged "bash / đích trống" bash "$REPO_ROOT/copy-framework.sh" "$targetA"
check_structure "bash / đích trống" "$targetA"

echo ""
echo "== bash / đích đã có CLAUDE.md + .claude/settings.json + .claude/hooks (không được đè) =="
targetB="$(new_target)"
echo "SENTINEL-KHONG-DUOC-DE" > "$targetB/CLAUDE.md"
mkdir -p "$targetB/.claude/hooks"
echo '{"SENTINEL-KHONG-DUOC-DE": true}' > "$targetB/.claude/settings.json"
echo "SENTINEL-KHONG-DUOC-DE" > "$targetB/.claude/hooks/my-hook.sh"
run_logged "bash / đích có sẵn" bash "$REPO_ROOT/copy-framework.sh" "$targetB"
check_no_overwrite "bash / đích có sẵn" "$targetB"
check_claude_config_not_overwritten "bash / đích có sẵn" "$targetB"

echo ""
echo "== bash / chạy lại lần hai trên cùng đích (nhật ký vận hành của đích phải còn nguyên) =="
mkdir -p "$targetA/docs/ops"
echo "SENTINEL-NHAT-KY-DICH" > "$targetA/docs/ops/MAINTENANCE-LOG.md"
run_logged "bash / chạy lại lần 2" bash "$REPO_ROOT/copy-framework.sh" "$targetA" \
  && echo "  ok [bash / chạy lại lần 2]: không lỗi"
check_ops_state_kept "bash / chạy lại lần 2" "$targetA"

echo ""
echo "== bash / --upgrade: giữ chỉnh sửa của đích, cập nhật file chưa sửa (AC-2, AC-3) =="
targetU="$(new_target)"
run_logged "upgrade / copy lần đầu" bash "$REPO_ROOT/copy-framework.sh" "$targetU"
echo "USER-EDIT-GIU-LAI" >> "$targetU/docs/framework/quickstart.md"
echo "KHONG-PHAI-BAN-KHUNG" > "$targetU/docs/framework/standard-delivery.md"
cp "$targetU/docs/framework/standard-delivery.md" "$targetU/docs/framework/standard-delivery.md.usercopy"
# Giả lập file "chưa sửa" nhưng khung có bản mới: đích giữ nguyên hash manifest → phải được ghi đè.
run_logged "upgrade / lần 2 --upgrade" bash "$REPO_ROOT/copy-framework.sh" "$targetU" --upgrade
if grep -q "USER-EDIT-GIU-LAI" "$targetU/docs/framework/quickstart.md" || grep -q "USER-EDIT-GIU-LAI" "$targetU/docs/framework/quickstart.md.framework-new" 2>/dev/null; then
  grep -q "USER-EDIT-GIU-LAI" "$targetU/docs/framework/quickstart.md" && echo "  ok [upgrade]: chỉnh sửa của đích còn trong quickstart.md (merge/giữ)" \
    || echo "  ok [upgrade]: chỉnh sửa của đích được giữ, bản khung để cạnh .framework-new"
else
  echo "  FAIL [upgrade]: --upgrade làm MẤT chỉnh sửa của đích trong quickstart.md"; fail=1
fi
if grep -q "KHONG-PHAI-BAN-KHUNG" "$targetU/docs/framework/standard-delivery.md"; then
  echo "  ok [upgrade]: file đích viết lại toàn bộ → nội dung đích được giữ (merge 3 chiều hoặc .framework-new)"
else
  echo "  FAIL [upgrade]: --upgrade ghi đè file đích đã sửa (standard-delivery.md)"; fail=1
fi
cmp -s "$REPO_ROOT/docs/framework/new-project-runbook.md" "$targetU/docs/framework/new-project-runbook.md" \
  && echo "  ok [upgrade]: file chưa sửa được cập nhật bằng bản khung" \
  || { echo "  FAIL [upgrade]: file chưa sửa không khớp bản khung sau --upgrade"; fail=1; }
# AC-3: FRAMEWORK-VERSION đời cũ (chỉ commit-nguon không giải được, không manifest) → vẫn không mất sửa đổi.
targetV="$(new_target)"
run_logged "upgrade cũ / copy lần đầu" bash "$REPO_ROOT/copy-framework.sh" "$targetV"
printf 'commit-nguon: khong-ro\nngay-copy: 2020-01-01\n' > "$targetV/docs/framework/FRAMEWORK-VERSION"
echo "USER-EDIT-CU" >> "$targetV/docs/framework/quickstart.md"
run_logged "upgrade cũ / --upgrade" bash "$REPO_ROOT/copy-framework.sh" "$targetV" --upgrade
{ grep -q "USER-EDIT-CU" "$targetV/docs/framework/quickstart.md" || grep -q "USER-EDIT-CU" "$targetV/docs/framework/quickstart.md.framework-new" 2>/dev/null; } \
  && echo "  ok [upgrade cũ]: không manifest/không base → vẫn giữ chỉnh sửa (giữ đích hoặc .framework-new)" \
  || { echo "  FAIL [upgrade cũ]: --upgrade trên FRAMEWORK-VERSION đời cũ làm MẤT chỉnh sửa"; fail=1; }
# Không cờ → hành vi cũ (ghi đè Lớp 1) — để script/CI đang gọi không bất ngờ (AC-5).
run_logged "không cờ / lần 2" bash "$REPO_ROOT/copy-framework.sh" "$targetV"
grep -q "USER-EDIT-CU" "$targetV/docs/framework/quickstart.md" \
  && { echo "  FAIL [không cờ]: không --upgrade mà không ghi đè Lớp 1 — hành vi cũ đổi ngoài ý muốn"; fail=1; } \
  || echo "  ok [không cờ]: không --upgrade → ghi đè Lớp 1 như cũ"

if command -v pwsh >/dev/null 2>&1; then
  echo ""
  echo "== pwsh / đích trống =="
  targetD="$(new_target)"
  run_logged "pwsh / đích trống" pwsh -NoProfile -File "$REPO_ROOT/copy-framework.ps1" "$targetD"
  check_structure "pwsh / đích trống" "$targetD"

  echo ""
  echo "== pwsh / đích đã có CLAUDE.md + .claude/settings.json + .claude/hooks (không được đè) =="
  targetE="$(new_target)"
  echo "SENTINEL-KHONG-DUOC-DE" > "$targetE/CLAUDE.md"
  mkdir -p "$targetE/.claude/hooks"
  echo '{"SENTINEL-KHONG-DUOC-DE": true}' > "$targetE/.claude/settings.json"
  echo "SENTINEL-KHONG-DUOC-DE" > "$targetE/.claude/hooks/my-hook.sh"
  run_logged "pwsh / đích có sẵn" pwsh -NoProfile -File "$REPO_ROOT/copy-framework.ps1" "$targetE"
  check_no_overwrite "pwsh / đích có sẵn" "$targetE"
  check_claude_config_not_overwritten "pwsh / đích có sẵn" "$targetE"

  echo ""
  echo "== pwsh / chạy lại lần hai (nhật ký vận hành của đích phải còn nguyên) =="
  mkdir -p "$targetD/docs/ops"
  echo "SENTINEL-NHAT-KY-DICH" > "$targetD/docs/ops/MAINTENANCE-LOG.md"
  run_logged "pwsh / chạy lại lần 2" pwsh -NoProfile -File "$REPO_ROOT/copy-framework.ps1" "$targetD"
  check_ops_state_kept "pwsh / chạy lại lần 2" "$targetD"
else
  echo ""
  echo "⚠️  ⚠️  BỎ QUA toàn bộ kiểm thử copy-framework.ps1 — máy này KHÔNG có pwsh."
  echo "    Nghĩa là lượt chạy này KHÔNG chứng minh gì về bản Windows: danh sách file của"
  echo "    .sh và .ps1 có thể đã lệch nhau mà không ai thấy (audit 2026-09-12, F-015)."
  echo "    Bản .ps1 chỉ được kiểm thật trên CI (job copy-framework-smoke, ubuntu-latest có pwsh)."
  if [ "${REQUIRE_PWSH:-0}" = "1" ]; then
    echo "::error::REQUIRE_PWSH=1 nhưng không tìm thấy pwsh — CI phải kiểm được bản .ps1."
    fail=1
  fi
fi

# ── SMOKE THẬT: script phát cho dự án đích phải CHẠY ĐƯỢC ở đó ──────────────────────
# VÌ SAO (2026-09-14): các kiểm ở trên chỉ xác nhận ĐÚNG FILE ĐƯỢC COPY, không xác nhận
# chúng chạy nổi. Lỗ hổng đó đã làm hỏng thật: PR #93 bắt telemetry-log.py đọc
# scripts/model-rates.json và exit 1 nếu thiếu, nhưng copy-framework KHÔNG phát file đó —
# nên `telemetry-log.sh --record` CHẾT trên MỌI dự án đích, suốt nhiều PR mà không cổng
# nào kêu. Self-test đi kèm bắt được, nhưng chưa ai chạy nó BÊN TRONG dự án đích.
# Bài học tổng quát: "đã copy đủ file" ≠ "dùng được". Chỉ chạy thật mới chứng minh.
echo "== Smoke: self-test đi kèm phải XANH ngay trong dự án đích =="
smoke_target="$(new_target)"
if ! bash "$REPO_ROOT/copy-framework.sh" "$smoke_target" >/tmp/copy-framework-smoke.log 2>&1; then
  echo "  FAIL: copy-framework.sh lỗi khi dựng dự án đích cho smoke"
  fail=1
else
  for t in test-telemetry-and-dispatch.sh test-next-gen-engines.sh test-maintenance-sweep.sh test-maintain-run.sh test-maintain-cron.sh; do
    if [ ! -f "$smoke_target/scripts/$t" ]; then
      echo "  FAIL: thiếu $t ở dự án đích — không smoke được"
      fail=1
      continue
    fi
    if ( cd "$smoke_target" && bash "scripts/$t" >/tmp/copy-framework-smoke.log 2>&1 ); then
      echo "  ✅ $t XANH trong dự án đích"
    else
      echo "  FAIL: $t ĐỎ trong dự án đích — script được phát nhưng không chạy nổi ở đó:"
      sed -n '1,12p' /tmp/copy-framework-smoke.log | sed 's/^/      /'
      fail=1
    fi
  done
fi

echo ""
if [ "$fail" -eq 0 ]; then
  if command -v pwsh >/dev/null 2>&1; then
    echo "OK — copy-framework.sh VÀ copy-framework.ps1 hoạt động đúng kỳ vọng."
  else
    echo "OK — copy-framework.sh đúng kỳ vọng (bản .ps1 CHƯA được kiểm ở lượt này — xem cảnh báo trên)."
  fi
fi
exit "$fail"
