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
# Log RIÊNG từng lượt chạy (không dùng tên cố định trong /tmp): hai bản suite chạy chồng — vd cổng mồ côi từ lượt
# bị dừng dở — từng ghi đè log của nhau, smoke đọc nhầm kết quả bản kia (TRAPS.md mục 65).
LOG_DIR="$(mktemp -d)"; tmp_dirs+=("$LOG_DIR")

new_target() {
  local t
  t="$(mktemp -d)"
  git init -q "$t"
  tmp_dirs+=("$t")
  printf '%s' "$t"
}

run_logged() {          # run_logged <mô tả> <lệnh...>
  local desc="$1"; shift
  if "$@" >"$LOG_DIR/test.log" 2>&1; then
    return 0
  fi
  echo "  FAIL [$desc]: script thoát lỗi — log:"
  sed 's/^/    /' "$LOG_DIR/test.log"
  fail=1
  return 1
}

# shellcheck source=scripts/_copy-framework-test-lib.sh
source "$REPO_ROOT/scripts/_copy-framework-test-lib.sh"   # manifest_paths, check_manifest, check_structure, check_ci_target_stacks

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

check_no_framework_new() {  # check_no_framework_new <mô tả> <target> — chạy lại trên đích CHƯA sửa không được rải bản trùng (F-Q7)
  local label="$1" target="$2" n
  n="$(find "$target" -name '*.framework-new' | wc -l | tr -d ' ')"
  if [ "$n" -eq 0 ]; then
    echo "  ok [$label]: 0 file .framework-new (đích giống hệt nguồn → không tạo bản trùng)"
  else
    echo "  FAIL [$label]: $n file .framework-new dù đích chưa sửa gì — vd: $(find "$target" -name '*.framework-new' | head -3 | sed "s|$target/||" | tr '\n' ' ')"
    fail=1
  fi
}

check_git_exec_bit() {  # check_git_exec_bit <mô tả> <target> — script phát sang phải mang mode 100755 trong index git (F-Q8)
  local label="$1" target="$2" mode
  mode="$(git -C "$target" ls-files -s .claude/hooks/auto-format.sh | awk '{print $1}')"
  if [ "$mode" = "100755" ]; then
    echo "  ok [$label]: .claude/hooks/auto-format.sh mode 100755 trong index git"
  else
    echo "  FAIL [$label]: .claude/hooks/auto-format.sh mode '${mode:-không có trong index}' (kỳ vọng 100755) — clone trên Linux/macOS sẽ không chạy được hook"
    fail=1
  fi
}

check_hooks_and_owners() {  # check_hooks_and_owners <mô tả> <target> — core.hooksPath bật sẵn + dropin CODEOWNERS không mang owner của khung (F-A7, F-A5)
  local label="$1" target="$2" hp
  hp="$(git -C "$target" config core.hooksPath 2>/dev/null)"
  if [ "$hp" = "scripts/githooks" ]; then
    echo "  ok [$label]: core.hooksPath = scripts/githooks ở đích"
  else
    echo "  FAIL [$label]: core.hooksPath '${hp:-chưa đặt}' (kỳ vọng scripts/githooks) — commit ngoài Claude Code không qua cổng"
    fail=1
  fi
  if [ ! -f "$target/_framework-dropins/.github/CODEOWNERS" ]; then
    echo "  FAIL [$label]: thiếu _framework-dropins/.github/CODEOWNERS"; fail=1
  elif grep -q 'seeker19110' "$target/_framework-dropins/.github/CODEOWNERS"; then
    echo "  FAIL [$label]: dropin CODEOWNERS còn @seeker19110 (owner của khung)"; fail=1
  elif grep -q '@OWNER-CHANGE-ME' "$target/_framework-dropins/.github/CODEOWNERS"; then
    echo "  ok [$label]: dropin CODEOWNERS dùng placeholder @OWNER-CHANGE-ME"
  else
    echo "  FAIL [$label]: dropin CODEOWNERS không có placeholder @OWNER-CHANGE-ME"; fail=1
  fi
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
check_manifest "bash / đích trống" "$targetA"
check_ci_target_stacks "bash / đích trống" "$targetA"
check_hooks_and_owners "bash / đích trống" "$targetA"

echo "== .gitignore drop-in: chặn biến thể môi trường, giữ tệp mẫu =="
env_target="$(new_target)"
if cp "$targetA/_framework-dropins/.gitignore" "$env_target/.gitignore"; then
  for env_file in .env .env.production .env.staging; do
    if git -C "$env_target" check-ignore --no-index -q -- "$env_file"; then
      echo "  ok: $env_file được ignore"
    else
      echo "  FAIL: $env_file chưa được ignore"
      fail=1
    fi
  done
  for env_file in .env.example .env.sample .env.template .env.production.example .env.staging.sample; do
    if git -C "$env_target" check-ignore --no-index -q -- "$env_file"; then
      echo "  FAIL: $env_file bị ignore oan"
      fail=1
    else
      echo "  ok: $env_file vẫn được phép commit"
    fi
  done
else
  echo "  FAIL: thiếu .gitignore drop-in"
  fail=1
fi

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
check_no_framework_new "bash / chạy lại lần 2" "$targetA"

echo ""
echo "== bash / --upgrade: giữ chỉnh sửa của đích, cập nhật file chưa sửa (AC-2, AC-3) =="
targetU="$(new_target)"
run_logged "upgrade / copy lần đầu" bash "$REPO_ROOT/copy-framework.sh" "$targetU"
echo "USER-EDIT-GIU-LAI" >> "$targetU/docs/framework/quickstart.md"
# File "đích viết lại toàn bộ" phải là file khung CHƯA sửa so với HEAD: --upgrade lấy base từ HEAD còn nguồn là
# working tree, nên một file khung đang sửa dở xung đột THẬT (đúng hành vi) và làm suite đỏ oan (TRAPS mục 47).
rewrite_rel=docs/framework/standard-delivery.md
if git -C "$REPO_ROOT" rev-parse -q --verify HEAD >/dev/null 2>&1; then
  rewrite_rel=""
  for cand in docs/framework/standard-delivery.md docs/framework/industry-standards.md \
              docs/framework/01-process-and-standards.md docs/framework/adopt-from-outside.md; do
    git -C "$REPO_ROOT" diff --quiet HEAD -- "$cand" && { rewrite_rel="$cand"; break; }
  done
  [ -n "$rewrite_rel" ] || { echo "  FAIL [upgrade]: mọi file ứng viên đều đang sửa dở — không dựng được ca viết lại"; fail=1; rewrite_rel=docs/framework/standard-delivery.md; }
fi
echo "KHONG-PHAI-BAN-KHUNG" > "$targetU/$rewrite_rel"
cp "$targetU/$rewrite_rel" "$targetU/$rewrite_rel.usercopy"
# Giả lập file "chưa sửa" nhưng khung có bản mới: đích giữ nguyên hash manifest → phải được ghi đè.
run_logged "upgrade / lần 2 --upgrade" bash "$REPO_ROOT/copy-framework.sh" "$targetU" --upgrade
if grep -q "USER-EDIT-GIU-LAI" "$targetU/docs/framework/quickstart.md" || grep -q "USER-EDIT-GIU-LAI" "$targetU/docs/framework/quickstart.md.framework-new" 2>/dev/null; then
  grep -q "USER-EDIT-GIU-LAI" "$targetU/docs/framework/quickstart.md" && echo "  ok [upgrade]: chỉnh sửa của đích còn trong quickstart.md (merge/giữ)" \
    || echo "  ok [upgrade]: chỉnh sửa của đích được giữ, bản khung để cạnh .framework-new"
else
  echo "  FAIL [upgrade]: --upgrade làm MẤT chỉnh sửa của đích trong quickstart.md"; fail=1
fi
if grep -q "KHONG-PHAI-BAN-KHUNG" "$targetU/$rewrite_rel"; then
  echo "  ok [upgrade]: file đích viết lại toàn bộ → nội dung đích được giữ (merge 3 chiều hoặc .framework-new)"
else
  echo "  FAIL [upgrade]: --upgrade ghi đè file đích đã sửa ($rewrite_rel)"; fail=1
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
  check_manifest "pwsh / đích trống" "$targetD"
  check_ci_target_stacks "pwsh / đích trống" "$targetD"
  check_git_exec_bit "pwsh / đích trống" "$targetD"
  check_hooks_and_owners "pwsh / đích trống" "$targetD"

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
  check_no_framework_new "pwsh / chạy lại lần 2" "$targetD"
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
# Copy HAI lần: lần chạy lại từng rải *.framework-new làm mục 17 (nay ở test-hooks-gate-guard.sh) đỏ ở đích (F-Q7).
if ! { bash "$REPO_ROOT/copy-framework.sh" "$smoke_target" && bash "$REPO_ROOT/copy-framework.sh" "$smoke_target"; } >"$LOG_DIR/smoke.log" 2>&1; then
  echo "  FAIL: copy-framework.sh lỗi khi dựng dự án đích cho smoke"
  fail=1
else
  for t in test-telemetry-and-dispatch.sh test-next-gen-engines.sh test-maintenance-sweep.sh test-maintain-run.sh test-maintain-cron.sh test-hooks-gate.sh test-hooks-gate-guard.sh test-usage-estimate.sh; do
    if [ ! -f "$smoke_target/scripts/$t" ]; then
      echo "  FAIL: thiếu $t ở dự án đích — không smoke được"
      fail=1
      continue
    fi
    if ( cd "$smoke_target" && bash "scripts/$t" >"$LOG_DIR/smoke.log" 2>&1 ); then
      echo "  ✅ $t XANH trong dự án đích"
    else
      echo "  FAIL: $t ĐỎ trong dự án đích — script được phát nhưng không chạy nổi ở đó (log đủ in ngay dưới, thư mục log bị dọn khi suite thoát):"
      # 12 dòng đầu không bao giờ chứa ca đỏ (2026-10-10: ba lần đỏ chỉ thấy header) → in dòng ❌/FAIL/lỗi + đuôi log.
      { grep -n '❌\|FAIL\|rror\|cannot\|No such' "$LOG_DIR/smoke.log" | head -20; echo "… (đuôi log)"; tail -15 "$LOG_DIR/smoke.log"; } | sed 's/^/      /'
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
