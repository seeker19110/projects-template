#!/usr/bin/env bash
# test-dev-task.sh — dev-task.sh phải PHÂN GIẢI ĐÚNG LỆNH cho từng stack (không chỉ "chạy không crash").
#
# VÌ SAO (audit 2026-09-23, T4): cổng commit của dự án Node điển hình bỏ qua type-check ÂM THẦM vì
# dev-task chỉ nhận script tên đúng `typecheck` trong khi khung dạy `type-check`; Python không dò venv
# nên chạy nhầm binary toàn cục hoặc no-op; Bun ≥ 1.2 (`bun.lock`) bị coi là npm; 8 stack CLAUDE.md §0b
# tuyên bố hỗ trợ nhưng dev-task no-op. Không test nào đo `resolve()` → cổng xanh giả không ai thấy.
# Dùng `dev-task.sh --print <task>` (chỉ in lệnh) trên fixture tối thiểu từng stack, binary giả trong PATH.
#
# Chạy: bash scripts/test-dev-task.sh
set -uo pipefail   # cố ý KHÔNG -e (docs/CONVENTIONS.md §A)

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DT="$ROOT/scripts/dev-task.sh"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
# shellcheck source=scripts/_test-lib.sh
source "$ROOT/scripts/_test-lib.sh"

FAKEBIN="$WORK/bin"; mkdir -p "$FAKEBIN"
for b in ruff mypy pytest uv poetry flutter; do printf '#!/usr/bin/env bash\nexit 0\n' > "$FAKEBIN/$b"; chmod +x "$FAKEBIN/$b"; done
export PATH="$FAKEBIN:$PATH"

fx() {   # fx <tên> → thư mục fixture mới (dev-task cần scripts/ để tính ROOT qua CLAUDE_PROJECT_DIR)
  local d="$WORK/$1"; mkdir -p "$d"; printf '%s' "$d"
}
resolve() { CLAUDE_PROJECT_DIR="$1" bash "$DT" --print "$2" 2>/dev/null; }
expect() { # expect <fixture> <task> <chuỗi mong đợi> <mô tả>
  local got; got="$(resolve "$1" "$2")"
  if [ "$got" = "$3" ]; then ok "$4 → '$got'"; else bad "$4: mong '$3', được '$got'"; fi
}

echo "== 1. Node: alias script + trình quản lý gói theo lockfile =="
d="$(fx node1)"; printf '{"scripts":{"type-check":"tsc --noEmit","lint":"eslint .","test":"vitest run"}}\n' > "$d/package.json"
expect "$d" typecheck "npm run type-check" "script 'type-check' được nhận cho task typecheck (bản cũ: skip)"
expect "$d" lint "npm run lint" "lint npm"
d="$(fx node2)"; printf '{"scripts":{"tsc":"tsc --noEmit","check":"biome check .","fmt":"biome format --write ."}}\n' > "$d/package.json"; : > "$d/bun.lock"
expect "$d" typecheck "bun run tsc" "alias 'tsc' + Bun ≥ 1.2 (bun.lock dạng text) → bun"
expect "$d" lint "bun run check" "alias 'check' cho lint"
expect "$d" format "bun run fmt" "alias 'fmt' cho format"
d="$(fx node3)"; printf '{"scripts":{"build":"next build"}}\n' > "$d/package.json"; : > "$d/pnpm-lock.yaml"
expect "$d" build "pnpm run build" "pnpm theo pnpm-lock.yaml"
expect "$d" typecheck "" "không có script nào khớp → rỗng (no-op), không bịa lệnh"

echo "== 2. Python: venv / uv / poetry / PATH, marker requirements.txt =="
d="$(fx py1)"; : > "$d/requirements.txt"; mkdir -p "$d/.venv/bin"; printf '#!/usr/bin/env bash\nexit 0\n' > "$d/.venv/bin/ruff"; chmod +x "$d/.venv/bin/ruff"
expect "$d" lint "$d/.venv/bin/ruff check ." "requirements.txt là marker; ruff trong .venv được ưu tiên hơn PATH"
d="$(fx py2)"; : > "$d/pyproject.toml"; : > "$d/uv.lock"
expect "$d" test "uv run pytest -q" "uv.lock → 'uv run pytest'"
expect "$d" typecheck "uv run mypy ." "uv.lock → 'uv run mypy'"
d="$(fx py3)"; : > "$d/pyproject.toml"; : > "$d/poetry.lock"
expect "$d" format "poetry run ruff format ." "poetry.lock → 'poetry run ruff'"
d="$(fx py4)"; : > "$d/pyproject.toml"
expect "$d" test "pytest -q" "không venv/uv/poetry → PATH"

echo "== 3. Rust typecheck = cargo check (rẻ hơn build) =="
d="$(fx rs)"; : > "$d/Cargo.toml"
expect "$d" typecheck "cargo check" "cargo check"

echo "== 4. 8 stack mới (CLAUDE.md §0b) =="
d="$(fx java)"; : > "$d/pom.xml";              expect "$d" test "mvn -q -B test" "Maven test"
d="$(fx kt)"; : > "$d/build.gradle.kts"; printf '#!/bin/sh\n' > "$d/gradlew"; chmod +x "$d/gradlew"
                                                expect "$d" build "./gradlew build -x test" "Gradle wrapper build"
d="$(fx net)"; : > "$d/App.csproj";           expect "$d" lint "dotnet format --verify-no-changes" ".NET lint = format --verify-no-changes"
                                                expect "$d" test "dotnet test --nologo" ".NET test"
d="$(fx dart)"; printf 'name: x\ndependencies:\n  flutter:\n    sdk: flutter\n' > "$d/pubspec.yaml"
                                                expect "$d" test "flutter test" "Flutter (pubspec có flutter + binary flutter) → flutter test"
                                                expect "$d" lint "dart analyze --fatal-infos" "Dart analyze"
d="$(fx dart2)"; printf 'name: x\n' > "$d/pubspec.yaml"; expect "$d" test "dart test" "Dart thuần → dart test"
d="$(fx php)"; : > "$d/composer.json"; mkdir -p "$d/vendor/bin"; printf '#!/bin/sh\n' > "$d/vendor/bin/phpstan"; chmod +x "$d/vendor/bin/phpstan"
                                                expect "$d" lint "vendor/bin/phpstan analyse --no-progress" "PHP phpstan khi có vendor/bin"
d="$(fx rb)"; : > "$d/Gemfile"; mkdir -p "$d/spec"; expect "$d" test "bundle exec rspec" "Ruby rspec khi có spec/"
d="$(fx ex)"; : > "$d/mix.exs";                expect "$d" build "mix compile --warnings-as-errors" "Elixir build"
d="$(fx deno)"; : > "$d/deno.json"; printf '{"scripts":{"typecheck":"x"}}\n' > "$d/package.json"
                                                expect "$d" typecheck "deno check ." "Deno thắng Node khi cùng có deno.json + package.json"
d="$(fx swift)"; : > "$d/Package.swift";      expect "$d" build "swift build" "Swift build"

echo "== 5. Khai báo (.claude/project-commands.sh) vẫn thắng tự dò; task lạ → exit 2 =="
d="$(fx decl)"; : > "$d/Cargo.toml"; mkdir -p "$d/.claude"; printf 'typecheck="echo KHAI-BAO"\n' > "$d/.claude/project-commands.sh"
expect "$d" typecheck "echo KHAI-BAO" "khai báo thắng tự dò"
CLAUDE_PROJECT_DIR="$d" bash "$DT" --print nope >/dev/null 2>&1; rc=$?
[ "$rc" -eq 2 ] && ok "--print task lạ → exit 2" || bad "--print task lạ → exit $rc"

echo "== 6. NEGATIVE: gỡ alias → ca 1 phải đỏ (test đo thật) =="
tmpdt="$WORK/dev-task-noalias.sh"; sed 's/typecheck) echo "typecheck type-check tsc check-types" ;;/typecheck) echo "typecheck" ;;/' "$DT" > "$tmpdt"
cp "$ROOT/scripts/_stack-detect.sh" "$WORK/_stack-detect.sh"
got="$(CLAUDE_PROJECT_DIR="$WORK/node1" bash "$tmpdt" --print typecheck 2>/dev/null)"
[ -z "$got" ] && ok "negative: không alias → 'type-check' không được nhận (test bắt được)" || bad "negative test không bắt được (được '$got')"


# Contract tests share the real dispatcher; only these tiny fixture commands are stubs.
gate_case() {  # $1=fixture $2=expected exit $3=output marker [$4=gate|doctor]
  local dir="$1" expected="$2" marker="$3" rc
  CLAUDE_PROJECT_DIR="$dir" bash "$DT" "${4:-gate}" >"$WORK/gate-output" 2>&1; rc=$?
  if [ "$rc" -eq "$expected" ] && grep -q "$marker" "$WORK/gate-output"; then
    ok "${dir##*/}: ${4:-gate} → exit $rc, $marker"
  else
    bad "${dir##*/}: expected exit $expected / $marker, got $rc"
    cat "$WORK/gate-output"
  fi
}
gate_fixture() {
  local dir; dir="$(fx "$1")"; mkdir -p "$dir/.claude"
  printf '%s\n' "build='true'" "typecheck='true'" "lint='true'" "test='true'" > "$dir/.claude/project-commands.sh"
  printf '%s' "$dir"
}
assert_no_marker() {
  if [ -e "$1/ran-check" ]; then bad "preflight/doctor executed a check"; else ok "preflight/doctor did not execute checks"; fi
}
contract_tests() {
  local d
  d="$(fx gate-empty)"; gate_case "$d" 2 BLOCKED
  d="$(gate_fixture gate-incomplete)"; printf "test=''\nbuild='touch ran-check'\n" >> "$d/.claude/project-commands.sh"
  gate_case "$d" 2 BLOCKED; assert_no_marker "$d"
  d="$(gate_fixture gate-whitespace)"; printf "test='   '\n" >> "$d/.claude/project-commands.sh"; gate_case "$d" 2 BLOCKED
  d="$(gate_fixture gate-config-syntax)"; printf "broken='\n" >> "$d/.claude/project-commands.sh"; gate_case "$d" 2 BLOCKED
  d="$(gate_fixture gate-config-failure)"; printf "false\n" >> "$d/.claude/project-commands.sh"; gate_case "$d" 2 BLOCKED
  d="$(gate_fixture gate-command-syntax)"; printf "test='if'\n" >> "$d/.claude/project-commands.sh"; gate_case "$d" 2 BLOCKED
  d="$(gate_fixture gate-missing-tool)"; printf "gate_tools='framework-fixture-tool-does-not-exist'\n" >> "$d/.claude/project-commands.sh"; gate_case "$d" 2 BLOCKED doctor
  d="$(gate_fixture gate-missing-module)"; printf "gate_python_modules='framework_fixture_module_does_not_exist'\n" >> "$d/.claude/project-commands.sh"; gate_case "$d" 2 BLOCKED doctor
  d="$(gate_fixture gate-doctor)"; printf "build='touch ran-check'\n" >> "$d/.claude/project-commands.sh"
  gate_case "$d" 0 READY doctor; assert_no_marker "$d"
  gate_case "$d" 0 PASS
  [ -f "$d/ran-check" ] && ok "gate actually executed the check" || bad "gate reported PASS without running the check"
}
skip_and_failure_tests() {
  local d t
  d="$(gate_fixture gate-na)"; printf "typecheck=''\ngate_skip_typecheck_reason='Fixture has no statically typed sources; reviewed.'\n" >> "$d/.claude/project-commands.sh"
  gate_case "$d" 0 PASS
  grep -q 'N/A.*typecheck' "$WORK/gate-output" && ok "N/A reason visible" || bad "N/A reason not visible"
  d="$(gate_fixture gate-na-ambiguous)"; printf "gate_skip_typecheck_reason='Old exclusion should not hide a newly available check.'\n" >> "$d/.claude/project-commands.sh"; gate_case "$d" 2 BLOCKED
  d="$(gate_fixture gate-all-na)"
  for t in build typecheck lint test; do printf "%s=''\ngate_skip_%s_reason='Not applicable in this negative fixture.'\n" "$t" "$t" >> "$d/.claude/project-commands.sh"; done
  gate_case "$d" 2 BLOCKED
  d="$(gate_fixture gate-failing-test)"; printf "test='exit 7'\n" >> "$d/.claude/project-commands.sh"; gate_case "$d" 1 FAIL
  d="$(gate_fixture gate-pipeline)"; printf "test='false | true'\n" >> "$d/.claude/project-commands.sh"; gate_case "$d" 1 FAIL
  d="$(gate_fixture gate-masked-failure)"; printf "test='false; true'\n" >> "$d/.claude/project-commands.sh"; gate_case "$d" 1 FAIL
  d="$(gate_fixture gate-config-drift)"; printf "test='echo mutation >> .claude/project-commands.sh'\n" >> "$d/.claude/project-commands.sh"; gate_case "$d" 2 BLOCKED
}
real_node_fixture() {
  local d; d="$(fx gate-real-node)"; mkdir -p "$d/.claude"
  if ! command -v node >/dev/null 2>&1; then bad "real Node fixture requires node; not skipped"; return; fi
  cat > "$d/.claude/project-commands.sh" <<'CONFIG'
gate_tools='node'
build='node --check sum.cjs'
lint='node --check test.cjs'
test='node test.cjs'
gate_skip_typecheck_reason='Plain JavaScript fixture; behavior is asserted by the real Node test.'
CONFIG
  printf "module.exports = (a,b) => a-b;\n" > "$d/sum.cjs"
  printf "require('node:assert/strict').equal(require('./sum.cjs')(2,3),5);\n" > "$d/test.cjs"
  gate_case "$d" 1 FAIL
  printf "module.exports = (a,b) => a+b;\n" > "$d/sum.cjs"
  gate_case "$d" 0 PASS
}
head_drift_test() {
  local d; d="$(gate_fixture gate-head-drift)"
  git -C "$d" init -q
  git -C "$d" -c user.name=fixture -c user.email=fixture@example.invalid commit --allow-empty -qm 'test: baseline'
  printf "test='git -c user.name=fixture -c user.email=fixture@example.invalid commit --allow-empty -qm changed'\n" >> "$d/.claude/project-commands.sh"
  gate_case "$d" 2 BLOCKED
}
echo "== 7. Strict gate: missing checks are BLOCKED; doctor is READY, never PASS =="
contract_tests
skip_and_failure_tests
head_drift_test
real_node_fixture

if [ "$fails" -eq 0 ]; then echo "OK — dev-task.sh phân giải đúng lệnh cho 13 stack, alias Node, môi trường Python."; exit 0; fi
echo "FAIL — $fails ca hỏng."; exit 1
