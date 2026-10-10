#!/usr/bin/env bash
# _copy-framework-test-lib.sh — kiểm CẤU TRÚC đích của scripts/test-copy-framework.sh (`source`, KHÔNG chạy trực tiếp):
#   manifest_paths <mục> · check_manifest <mô tả> <target> · check_structure <mô tả> <target>
#   check_ci_target_stacks <mô tả> <target>
# Tách 2026-10-10 vì test-copy-framework.sh vượt 400 dòng (radar). Dùng REPO_ROOT và `fail` của suite gọi.
# shellcheck disable=SC2034  # fail: đọc bởi test-copy-framework.sh sau mỗi ca

manifest_paths() {      # manifest_paths <mục> → cột 1 của mục đó trong copy-framework.manifest (cùng cách đọc với hai script copy)
  awk -v s="[$1]" '/^\[/{on=($0==s); next} on && NF && $1 !~ /^#/ {print $1}' "$REPO_ROOT/copy-framework.manifest"
}
check_manifest() {      # check_manifest <mô tả> <target>: mọi mục manifest có mặt ở nguồn VÀ ở đích (một nguồn cho .sh/.ps1 — O-6 P-B10)
  local label="$1" target="$2" sec rel ok=1
  for sec in docs root scripts dropins; do
    while read -r rel; do
      [ -e "$REPO_ROOT/$rel" ] || { echo "  FAIL [$label]: manifest [$sec] kê '$rel' nhưng repo khung không có file đó (copy sẽ bỏ qua im lặng)"; ok=0; }
      if [ "$sec" = dropins ]; then
        [ -e "$target/_framework-dropins/$rel" ] || { echo "  FAIL [$label]: manifest [dropins] '$rel' không có ở _framework-dropins/"; ok=0; }
      else
        [ -e "$target/$rel" ] || [ -e "$target/$rel.framework-new" ] || { echo "  FAIL [$label]: manifest [$sec] '$rel' không được copy sang đích"; ok=0; }
      fi
    done < <(manifest_paths "$sec")
  done
  [ "$ok" -eq 1 ] && echo "  ok [$label]: $(manifest_paths docs | wc -l)+$(manifest_paths root | wc -l)+$(manifest_paths scripts | wc -l) file + $(manifest_paths dropins | wc -l) drop-in theo đúng manifest" || fail=1
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
  [ -f "$target/_framework-dropins/.github/workflows/dependabot-auto-merge.yml" ] || { echo "  FAIL [$label]: thiếu Dependabot auto-merge drop-in"; ok=0; }
  [ -f "$target/_framework-dropins/.github/workflows/maintenance.yml" ] || { echo "  FAIL [$label]: thiếu Maintenance sweep drop-in"; ok=0; }
  [ -f "$target/_framework-dropins/.github/workflows/codeql.yml" ] && [ -f "$target/_framework-dropins/.github/workflows/scorecard.yml" ] || { echo "  FAIL [$label]: thiếu CodeQL/Scorecard drop-in"; ok=0; }
  [ -f "$target/scripts/requirements-ci.txt" ] || { echo "  FAIL [$label]: thiếu scripts/requirements-ci.txt (ci.yml dropin cần)"; ok=0; }
  [ -f "$target/scripts/_stack-detect.sh" ] && [ -f "$target/scripts/_commit-guard.sh" ] && [ -x "$target/scripts/githooks/pre-commit" ] || { echo "  FAIL [$label]: thiếu scripts/_stack-detect.sh / _commit-guard.sh hoặc scripts/githooks/pre-commit (dev-task/sweep/hook source; hook harness-agnostic)"; ok=0; }
  ( cd "$target" && bash scripts/dev-task.sh --print lint >/dev/null 2>&1 ) || { echo "  FAIL [$label]: dev-task.sh --print không chạy được ở đích (thiếu _stack-detect.sh?)"; ok=0; }
  [ -x "$target/scripts/maintenance-sweep.sh" ] && [ -x "$target/scripts/maintain-run.sh" ] || { echo "  FAIL [$label]: thiếu/không chạy được maintenance-sweep.sh hoặc maintain-run.sh"; ok=0; }
  [ -f "$target/docs/ops/repository-settings.md" ] || { echo "  FAIL [$label]: thiếu repository settings baseline"; ok=0; }
  [ -f "$target/docs/ops/supply-chain.md" ] || { echo "  FAIL [$label]: thiếu supply-chain guidance"; ok=0; }
  [ -f "$target/docs/framework/templates/THREAT-MODEL.template.md" ] || { echo "  FAIL [$label]: thiếu threat model template"; ok=0; }
  [ -f "$target/.codex/config.toml" ] || { echo "  FAIL [$label]: thiếu .codex/config.toml (trần ngữ cảnh 500k cho Codex — models-and-automation.md §5.2.1)"; ok=0; }
  [ -f "$target/_framework-dropins/.github/ISSUE_TEMPLATE/goal.yml" ] || { echo "  FAIL [$label]: thiếu Goal Issue Form"; ok=0; }
  [ -f "$target/docs/framework/templates/FEATURE-MAP.template.md" ] || { echo "  FAIL [$label]: thiếu docs/framework/templates/FEATURE-MAP.template.md"; ok=0; }
  [ -f "$target/docs/framework/templates/TRAPS.template.md" ] || { echo "  FAIL [$label]: thiếu TRAPS template"; ok=0; }
  [ -f "$target/tests/test_telemetry_integrity.py" ] || { echo "  FAIL [$label]: thiếu telemetry integrity test cho self-test đã copy"; ok=0; }
  [ -f "$target/docs/framework/templates/CODEMAP.template.md" ] || { echo "  FAIL [$label]: thiếu CODEMAP template"; ok=0; }
  [ -f "$target/docs/framework/templates/GOLDEN-TEST.template.md" ] || { echo "  FAIL [$label]: thiếu GOLDEN-TEST template"; ok=0; }
  [ -f "$target/_framework-dropins/scripts/ci-workflow-policy.test.ts" ] || { echo "  FAIL [$label]: thiếu ci-workflow-policy.test.ts drop-in"; ok=0; }
  # TRAPS 57: vitest của đích gom cả file đang nằm trong _framework-dropins/ → phải có hàng rào tự bỏ qua khi còn staged
  grep -q "describe.skipIf(STAGED)" "$target/_framework-dropins/scripts/ci-workflow-policy.test.ts" 2>/dev/null || { echo "  FAIL [$label]: drop-in vitest thiếu hàng rào skipIf(STAGED) — npm test của đích sẽ đỏ ngay sau copy"; ok=0; }
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
  if [ "$label" = "bash / đích trống" ] || [ "$label" = "pwsh / đích trống" ]; then   # phiên bản + manifest (spec 2026-09-23 AC-1) — .sh và .ps1 cùng khuôn stamp (F-D-05)
    grep -q "^version: $(cat "$REPO_ROOT/VERSION")$" "$target/docs/framework/FRAMEWORK-VERSION" 2>/dev/null \
      || { echo "  FAIL [$label]: FRAMEWORK-VERSION thiếu 'version:' khớp file VERSION"; ok=0; }
    [ "$(grep -c '^manifest: ' "$target/docs/framework/FRAMEWORK-VERSION" 2>/dev/null)" -gt 0 ] \
      || { echo "  FAIL [$label]: FRAMEWORK-VERSION thiếu dòng 'manifest:' (hash từng file Lớp 1)"; ok=0; }
  fi
  # Khối required checks (fenced ĐẦU TIÊN của repository-settings.md) phải BẰNG ĐÚNG tập job thật của
  # workflow phát kèm — vitest drop-in ci-workflow-policy.test.ts đối chiếu hai chiều đúng như vậy ở đích
  # (TRAPS.md mục 54). Job id = đúng 2 khoảng trắng thụt lề rồi `<id>:` trong khối `jobs:` (như check-ci-policy.sh).
  local settings="$target/docs/ops/repository-settings.md" wf actual declared
  actual="$(for wf in ci.yml pr-policy.yml; do
    tr -d '\r' < "$target/_framework-dropins/.github/workflows/$wf" 2>/dev/null | awk -v wf="$wf" '
      /^jobs:$/ { j=1; next }
      j && /^[A-Za-z]/ { j=0 }
      j && match($0, /^  [A-Za-z0-9_-]+:([[:space:]]|$)/) { id=substr($0,3); sub(/:.*/,"",id); print wf ": " id }'
  done | sort -u)"
  declared="$(tr -d '\r' < "$settings" 2>/dev/null | awk '
    /^```/ { if (b) exit; b=1; next }
    b && /^[a-zA-Z0-9_.-]+\.yml:[[:space:]]*[A-Za-z0-9_-]+[[:space:]]*$/ { gsub(/:[[:space:]]*/, ": "); sub(/[[:space:]]+$/, ""); print }' | sort -u)"
  if [ "$actual" != "$declared" ]; then
    while IFS= read -r l; do [ -n "$l" ] && echo "  FAIL [$label]: job '$l' có trong workflow phát kèm nhưng THIẾU trong khối required checks đầu tiên của docs/ops/repository-settings.md"; done < <(comm -23 <(printf '%s\n' "$actual") <(printf '%s\n' "$declared"))
    while IFS= read -r l; do [ -n "$l" ] && echo "  FAIL [$label]: job '$l' khai trong khối required checks đầu tiên của docs/ops/repository-settings.md nhưng KHÔNG có trong workflow phát kèm"; done < <(comm -13 <(printf '%s\n' "$actual") <(printf '%s\n' "$declared"))
    ok=0
  fi
  [ "$ok" -eq 1 ] && echo "  ok [$label]: cấu trúc copy đúng kỳ vọng" || fail=1
}

check_ci_target_stacks() {  # check_ci_target_stacks <mô tả> <target> — ci.yml phát sang đích cài dependency đủ 17 stack + guard setting + gate tổng hợp (T6, TRAPS 57)
  local label="$1" target="$2" ok=1 lock wf
  wf="$target/_framework-dropins/.github/workflows/ci.yml"
  # Một chuỗi hashFiles(...) cho mỗi stack: thiếu một = stack đó đỏ trên runner sạch dù code đích không lỗi (S-05).
  for lock in "'package-lock.json'" "'pnpm-lock.yaml'" "'yarn.lock'" "'bun.lock', 'bun.lockb'" "'requirements.txt'" "'uv.lock'" \
      "'poetry.lock'" "'go.mod'" "'Cargo.toml'" "'pom.xml', 'build.gradle', 'build.gradle.kts'" \
      "'**/*.csproj', '**/*.sln', 'global.json'" "'Gemfile.lock'" "'composer.lock'" "'pubspec.lock'" "'mix.lock'" \
      "'deno.json', 'deno.jsonc'" "'Package.swift'"; do
    grep -qF "hashFiles($lock)" "$wf" 2>/dev/null || { echo "  FAIL [$label]: ci.yml phát kèm thiếu bước cài dependency có điều kiện hashFiles($lock)"; ok=0; }
  done
  grep -q '^  protection-guard:' "$wf" 2>/dev/null || { echo "  FAIL [$label]: ci.yml phát kèm thiếu job protection-guard (ruleset + allow_auto_merge/delete_branch_on_merge phải có hiệu lực thật)"; ok=0; }
  # Job tổng hợp `gate` phải `if: always()` — thiếu thì gate bị SKIP khi job cha đỏ và GitHub coi required check skipped là ĐẠT.
  tr -d '\r' < "$wf" 2>/dev/null | awk '/^  gate:$/ { g=1; next } g && /^  [A-Za-z]/ { g=0 } g && /^    if: always\(\)$/ { found=1 } END { exit !found }' \
    || { echo "  FAIL [$label]: ci.yml phát kèm thiếu job tổng hợp gate với 'if: always()'"; ok=0; }
  [ "$ok" -eq 1 ] && echo "  ok [$label]: ci.yml phát kèm cài dependency theo 17 stack, có protection-guard + gate if: always()" || fail=1
}
