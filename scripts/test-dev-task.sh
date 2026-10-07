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
fails=0  # ShellCheck không theo được source qua $ROOT; giữ biến đếm tường minh.

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
  # Lệnh fixture không được là no-op nguyên văn (`true`, `:`, `echo`) — gate chặn đúng các lệnh đó (LD-03).
  printf '%s\n' "build='test -d .'" "typecheck='test -d .'" "lint='test -d .'" "test='test -d .'" > "$dir/.claude/project-commands.sh"
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

# --- LD-03: lệnh giả, zero-test, bằng chứng gắn đúng phiên bản (AC-3 của lean-delivery) ---
noop_tests() {
  local d i=0 cmd
  for cmd in 'true' ':' 'echo ok' 'exit 0' 'printf done'; do
    i=$((i+1)); d="$(gate_fixture "gate-noop-$i")"; printf "test='%s'\n" "$cmd" >> "$d/.claude/project-commands.sh"
    gate_case "$d" 2 'no-op'
  done
  d="$(gate_fixture gate-noop-doctor)"; printf "build=':'\n" >> "$d/.claude/project-commands.sh"; gate_case "$d" 2 'no-op' doctor
  d="$(gate_fixture gate-pass-no-tests)"; printf "test='npx vitest run --passWithNoTests'\n" >> "$d/.claude/project-commands.sh"
  gate_case "$d" 2 'passWithNoTests'
  d="$(gate_fixture gate-exit-nonzero)"; printf "test='exit 3'\n" >> "$d/.claude/project-commands.sh"; gate_case "$d" 1 FAIL
  d="$(gate_fixture gate-echo-piped)"; printf "test='echo 42 | grep -q 41'\n" >> "$d/.claude/project-commands.sh"
  gate_case "$d" 1 FAIL   # echo nối ống vào một phép kiểm thật không phải no-op: phải chạy và đỏ
}
count_fixture() {  # $1=tên $2=số ca test in ra
  local d; d="$(gate_fixture "$1")"
  printf 'echo "Ran %s tests"\n' "$2" > "$d/run-tests.sh"
  printf "test='bash run-tests.sh'\ngate_test_count_regex='Ran ([0-9]+) tests'\n" >> "$d/.claude/project-commands.sh"
  printf '%s' "$d"
}
count_tests() {
  local d
  d="$(count_fixture gate-zero-tests 0)"; gate_case "$d" 1 '0 ca'
  d="$(count_fixture gate-three-tests 3)"
  CLAUDE_PROJECT_DIR="$d" bash "$DT" gate --evidence "$WORK/count.json" >"$WORK/gate-output" 2>&1
  [ "$(jq -r .test_cases "$WORK/count.json" 2>/dev/null)" = 3 ] && ok "số ca test ghi vào evidence (3)" || bad "evidence không ghi số ca test"
  d="$(gate_fixture gate-unknown-count)"
  CLAUDE_PROJECT_DIR="$d" bash "$DT" gate --evidence "$WORK/unknown.json" >"$WORK/gate-output" 2>&1
  [ "$(jq -r .test_cases "$WORK/unknown.json" 2>/dev/null)" = null ] && ok "không khai regex → test_cases null (không biết), không phải 0" || bad "số ca test không biết bị ghi thành số"
}
fixture_git() {  # git trong fixture, danh tính cố định (không đọc cấu hình máy)
  git -C "$1" -c user.name=fixture -c user.email=fixture@example.invalid "${@:2}"
}
git_fixture() {  # repo git sạch: config + file nguồn đã ghi vào HEAD, out/ bị ignore
  local d; d="$(gate_fixture "$1")"
  mkdir -p "$d/out"; printf 'out/\n' > "$d/.gitignore"; printf 'v1\n' > "$d/src.txt"
  git -C "$d" init -q && git -C "$d" add -A && fixture_git "$d" commit -qm 'test: baseline'
  printf '%s' "$d"
}
ev_check() {  # $1=fixture $2=evidence $3=exit mong đợi $4=dấu hiệu $5=mô tả
  local rc; CLAUDE_PROJECT_DIR="$1" bash "$DT" evidence-check "$2" >"$WORK/ev-output" 2>&1; rc=$?
  if [ "$rc" -eq "$3" ] && grep -q "$4" "$WORK/ev-output"; then ok "$5 → exit $rc"; else bad "$5: mong exit $3/$4, được $rc"; cat "$WORK/ev-output"; fi
}
evidence_tests() {
  local d ev
  d="$(git_fixture gate-evidence)"; ev="$d/out/gate.json"
  CLAUDE_PROJECT_DIR="$d" bash "$DT" gate --evidence "$ev" >"$WORK/gate-output" 2>&1 || bad "gate xanh nhưng exit khác 0"
  if [ "$(jq -r '[.schema,.status,.head,([.checks[]|select(.status=="PASS")]|length|tostring)]|join(" ")' "$ev" 2>/dev/null)" = "gate-evidence/1 PASS $(git -C "$d" rev-parse HEAD) 4" ]; then
    ok "evidence PASS gắn HEAD, đủ 4 kiểm tra đã chạy"
  else bad "evidence PASS thiếu trường/HEAD/kiểm tra"; cat "$ev" 2>/dev/null; fi
  ev_check "$d" "$ev" 0 VERIFIED "evidence khớp cây hiện tại"
  printf 'v2\n' > "$d/src.txt"; ev_check "$d" "$ev" 1 STALE "mã đổi sau kiểm tra → evidence cũ"
  printf 'v1\n' > "$d/src.txt"; ev_check "$d" "$ev" 0 VERIFIED "trả nội dung cũ → khớp lại (vân tay theo nội dung)"
  printf 'x\n' > "$d/new-untracked.txt"; ev_check "$d" "$ev" 1 STALE "file mới chưa ignore sau kiểm tra → evidence cũ"; rm "$d/new-untracked.txt"
  jq '.checks[3].status="NOT_RUN"' "$ev" > "$d/out/forged.json"; ev_check "$d" "$d/out/forged.json" 1 INCOMPLETE "evidence có task chưa chạy"
  jq 'del(.checks[3])' "$ev" > "$d/out/short.json"; ev_check "$d" "$d/out/short.json" 1 INCOMPLETE "evidence bỏ sót task test"
  jq '.status="FAIL"' "$ev" > "$d/out/fail.json"; ev_check "$d" "$d/out/fail.json" 1 'không phải PASS' "evidence FAIL không được nghiệm thu"
  printf '{' > "$d/out/bad.json"; ev_check "$d" "$d/out/bad.json" 2 BLOCKED "evidence hỏng → BLOCKED"
  ev_check "$d" "$d/out/khong-co.json" 2 BLOCKED "thiếu file evidence → BLOCKED"
  fixture_git "$d" commit --allow-empty -qm 'test: next'
  ev_check "$d" "$ev" 1 STALE "HEAD mới sau kiểm tra → evidence cũ"
  printf "lint='exit 4'\n" >> "$d/.claude/project-commands.sh"
  CLAUDE_PROJECT_DIR="$d" GATE_EVIDENCE="$ev" bash "$DT" gate >"$WORK/gate-output" 2>&1
  [ "$(jq -r '[.status,(.checks[]|.status)]|join(" ")' "$ev" 2>/dev/null)" = "FAIL PASS PASS FAIL NOT_RUN" ] \
    && ok "evidence FAIL ghi đúng task hỏng; task sau là NOT_RUN" || { bad "evidence FAIL sai trạng thái từng task"; cat "$ev"; }
  printf "test=''\n" >> "$d/.claude/project-commands.sh"
  CLAUDE_PROJECT_DIR="$d" bash "$DT" gate --evidence "$ev" >"$WORK/gate-output" 2>&1
  [ "$(jq -r .status "$ev" 2>/dev/null)" = BLOCKED ] && ok "BLOCKED ghi đè evidence cũ (không để lại PASS cũ)" || bad "BLOCKED để lại evidence cũ"
}
evidence_binding_tests() {
  local d rc
  d="$(git_fixture gate-evidence-tracked)"
  CLAUDE_PROJECT_DIR="$d" bash "$DT" gate --evidence "$d/gate.json" >"$WORK/gate-output" 2>&1; rc=$?
  [ "$rc" -eq 2 ] && grep -q 'ignore' "$WORK/gate-output" && ok "evidence ghi vào cây chưa ignore → BLOCKED" || bad "evidence trong cây làm bẩn chính phiên bản được kiểm (exit $rc)"
  CLAUDE_PROJECT_DIR="$d" bash "$DT" gate --evidence "$d/src.txt" >"$WORK/gate-output" 2>&1; rc=$?
  [ "$rc" -eq 2 ] && [ "$(cat "$d/src.txt" 2>/dev/null)" = v1 ] && ok "--evidence trỏ nhầm file đã theo dõi → BLOCKED, file không bị xoá" || bad "--evidence xoá/ghi đè file nguồn đã theo dõi (exit $rc)"
  d="$(git_fixture gate-mutates-tracked)"; printf 'printf "v9\\n" > src.txt\n' > "$d/out/mutate.sh"
  printf "test='bash out/mutate.sh'\n" >> "$d/.claude/project-commands.sh"; gate_case "$d" 2 'working tree'
  d="$(git_fixture gate-creates-artifact)"; printf 'printf "a\\n" > artifact.txt\n' > "$d/out/make.sh"
  printf "test='bash out/make.sh'\n" >> "$d/.claude/project-commands.sh"
  CLAUDE_PROJECT_DIR="$d" bash "$DT" gate --evidence "$d/out/gate.json" >"$WORK/gate-output" 2>&1; rc=$?
  [ "$rc" -eq 0 ] && grep -q 'artifact.txt' "$WORK/gate-output" && ok "file mới sinh khi kiểm → PASS kèm cảnh báo tên file" || bad "file sinh mới bị chặn oan hoặc không được báo (exit $rc)"
  ev_check "$d" "$d/out/gate.json" 0 VERIFIED "evidence tính cả file sinh mới"
  # Lượt sau ghi lại chính artifact chưa ignore đó (vd __pycache__ ở dự án chưa có .gitignore): đây là output
  # build, không phải mã nguồn — chặn sẽ làm mọi lượt gate thứ hai đỏ oan (suite adoption Python đã bắt được).
  printf 'printf "b\\n" > artifact.txt\n' > "$d/out/make.sh"
  CLAUDE_PROJECT_DIR="$d" bash "$DT" gate >"$WORK/gate-output" 2>&1; rc=$?
  [ "$rc" -eq 0 ] && grep -q 'WARN.*artifact.txt' "$WORK/gate-output" && ok "artifact chưa ignore bị ghi lại → PASS kèm cảnh báo" || bad "artifact chưa ignore bị ghi lại làm gate chặn oan (exit $rc)"
  d="$(gate_fixture gate-evidence-nogit)"
  CLAUDE_PROJECT_DIR="$d" bash "$DT" gate --evidence "$WORK/nogit.json" >"$WORK/gate-output" 2>&1
  ev_check "$d" "$WORK/nogit.json" 2 BLOCKED "ngoài git → không gắn được phiên bản"
}
evidence_write_failure_tests() {
  local d rc scenario
  for scenario in missing-parent destination-directory failed-check; do
    d="$(git_fixture "gate-evidence-write-$scenario")"
    if [ "$scenario" = missing-parent ]; then
      printf "test='rmdir out'\n" >> "$d/.claude/project-commands.sh"
    elif [ "$scenario" = destination-directory ]; then
      printf "test='mkdir out/gate.json'\n" >> "$d/.claude/project-commands.sh"
    else
      printf "test='rmdir out; exit 7'\n" >> "$d/.claude/project-commands.sh"
    fi
    CLAUDE_PROJECT_DIR="$d" bash "$DT" gate --evidence "$d/out/gate.json" >"$WORK/gate-output" 2>&1; rc=$?
    if [ "$rc" -eq 2 ] && grep -q 'BLOCKED.*evidence' "$WORK/gate-output" && ! grep -q 'PASS:' "$WORK/gate-output"; then
      ok "$scenario: không lưu được evidence → BLOCKED, không báo PASS"
    else
      bad "$scenario: evidence không ghi được nhưng exit $rc"
      cat "$WORK/gate-output"
    fi
    [ -z "$(find "$d" -name 'gate.json.tmp.*' -print)" ] && ok "$scenario: không để lại evidence tạm" || bad "$scenario: còn evidence tạm"
  done
}
echo "== 7b. Bằng chứng: lệnh giả, zero-test, evidence gắn phiên bản (LD-03) =="
noop_tests
count_tests
evidence_tests
evidence_binding_tests
evidence_write_failure_tests

rv_check() {  # $1=fixture $2=findings $3=exit mong đợi $4=dấu hiệu $5=mô tả
  local rc; CLAUDE_PROJECT_DIR="$1" bash "$DT" review-check "$2" >"$WORK/rv-output" 2>&1; rc=$?
  if [ "$rc" -eq "$3" ] && grep -q -- "$4" "$WORK/rv-output"; then ok "$5 → exit $rc"; else bad "$5: mong exit $3/$4, được $rc"; cat "$WORK/rv-output"; fi
}
finding() {  # $1=kind $2=location $3=scenario $4=evidence → một finding JSON
  jq -nc --arg k "$1" --arg l "$2" --arg s "$3" --arg e "$4" '{id:"F1",kind:$k,location:$l,scenario:$s,evidence:$e}'
}
findings_file() {  # $1=đường dẫn, phần còn lại = các finding JSON
  local out="$1"; shift
  printf '%s\n' "$@" | jq -s '{schema:"review-findings/1",findings:.}' > "$out"
}
review_tests() {
  local d f="$WORK/findings.json"
  d="$(gate_fixture review)"; printf 'a\nb\n' > "$d/app.sh"
  findings_file "$f" "$(finding defect app.sh:2 'b rỗng → chia 0' 'test_div_zero đỏ')"
  rv_check "$d" "$f" 0 'REPAIR-CODE F1' "lỗi có vị trí + kịch bản + bằng chứng → sửa code"
  # jq trên Windows in CRLF (CI framework-lint-windows đã đỏ đúng ca này): giả lập bằng jq bọc thêm \r.
  mkdir -p "$WORK/crlf-bin"; printf '#!/usr/bin/env bash\n%s "$@" | sed "s/\\$/\\r/"\n' "$(command -v jq)" > "$WORK/crlf-bin/jq"; chmod +x "$WORK/crlf-bin/jq"
  PATH="$WORK/crlf-bin:$PATH" rv_check "$d" "$f" 0 'REPAIR-CODE F1' "jq in CRLF (Windows) → vẫn đọc đúng path:line"
  findings_file "$f" "$(finding missing-evidence '' 'evidence STALE' 'evidence-check: STALE head')"
  rv_check "$d" "$f" 0 'RERUN-EVIDENCE F1' "thiếu/cũ bằng chứng → chạy lại kiểm, không sửa code"
  grep -q 'REPAIR-CODE' "$WORK/rv-output" && bad "thiếu bằng chứng bị quy thành sửa code" || ok "thiếu bằng chứng không sinh REPAIR-CODE"
  findings_file "$f" "$(finding missing-input '' 'AC-3 không nói ca rỗng' 'spec §9 thiếu ca rỗng')"
  rv_check "$d" "$f" 0 'ASK-UPSTREAM F1' "thiếu input/spec → hỏi/sửa tầng trên, không sửa code"
  findings_file "$f" "$(finding defect app.sh:2 'chia 0' '')"
  rv_check "$d" "$f" 1 'UNSUPPORTED F1' "finding không có bằng chứng → bị loại"
  findings_file "$f" "$(finding defect '' 'chia 0' 'test đỏ')"
  rv_check "$d" "$f" 1 'UNSUPPORTED F1' "lỗi code không chỉ được path:line → bị loại"
  findings_file "$f" "$(finding defect khong-co.sh:3 'chia 0' 'test đỏ')"
  rv_check "$d" "$f" 1 'UNSUPPORTED F1' "lỗi trỏ tới file không tồn tại → bị loại"
  findings_file "$f" "$(finding defect app.sh:9 'chia 0' 'test đỏ')"
  rv_check "$d" "$f" 1 'UNSUPPORTED F1' "dòng vượt quá độ dài file → bị loại"
  findings_file "$f" "$(finding defect ../app.sh:1 'chia 0' 'test đỏ')"
  rv_check "$d" "$f" 1 'UNSUPPORTED F1' "path thoát khỏi repo → bị loại"
  findings_file "$f" "$(finding style app.sh:1 'x' 'y')"
  rv_check "$d" "$f" 1 'UNSUPPORTED F1' "kind lạ → bị loại, không đoán"
  findings_file "$f" "$(finding cleanup app.sh:1 'trùng helper' 'grep thấy 2 bản')"
  rv_check "$d" "$f" 0 'OPTIONAL F1' "cleanup → tuỳ chọn, không chặn"
  findings_file "$f"
  rv_check "$d" "$f" 0 'CLEAN' "không có finding → CLEAN"
  printf '{"schema":"x"}' > "$f"; rv_check "$d" "$f" 2 BLOCKED "sai schema → BLOCKED"
  rv_check "$d" "$WORK/khong-co.json" 2 BLOCKED "thiếu file findings → BLOCKED"
}
echo "== 7c. Review có căn cứ, repair đúng nguyên nhân (LD-04) =="
review_tests

echo "== 8. Lint của chính repo khung fail-closed ở từng bước =="
lint_cmd="$(CLAUDE_PROJECT_DIR="$ROOT" bash "$DT" --print lint)"
d="$(fx framework-lint)"; mkdir -p "$d/scripts"
lint_bin="$WORK/lint-bin"; mkdir -p "$lint_bin"
# Windows CI không cài ShellCheck: giả lập đúng mã thoát để kiểm chuỗi lệnh,
# và chỉ báo lỗi khi mỗi file được kiểm riêng (bắt mất cờ xargs -n1).
cat > "$lint_bin/shellcheck" <<'SHELLCHECK_STUB'
#!/usr/bin/env bash
files=()
for arg in "$@"; do
  [[ "$arg" == *.sh ]] && files+=("$arg")
done
if [ "${#files[@]}" -eq 1 ] && grep -Fq '$missing_var' "${files[0]}"; then exit 1; fi
exit 0
SHELLCHECK_STUB
chmod +x "$lint_bin/shellcheck"
printf '#!/usr/bin/env bash\nprintf "%%s\\n" "$missing_var"\n' > "$d/scripts/bad.sh"
printf '#!/usr/bin/env bash\ntouch docs-ran\n' > "$d/scripts/check-docs-consistency.sh"
printf '#!/usr/bin/env bash\ntouch ci-ran\n' > "$d/scripts/check-ci-policy.sh"
if PATH="$lint_bin:$PATH" shellcheck --severity=warning "$d/scripts/bad.sh" >"$WORK/lint-fixture-output" 2>&1; then
  bad "fixture ShellCheck không tạo được cảnh báo"
else
  ok "fixture ShellCheck đỏ trước khi chạy chuỗi lint"
fi
(cd "$d" && PATH="$lint_bin:$PATH" bash -c "$lint_cmd") >"$WORK/lint-output" 2>&1; rc=$?
if [ "$rc" -ne 0 ] && [ ! -e "$d/docs-ran" ] && [ ! -e "$d/ci-ran" ]; then
  ok "ShellCheck đỏ → lint đỏ, không chạy hai bước sau"
else
  bad "ShellCheck đỏ nhưng lint exit $rc / docs-ran=$([ -e "$d/docs-ran" ] && echo yes || echo no) / ci-ran=$([ -e "$d/ci-ran" ] && echo yes || echo no)"
fi
printf '#!/usr/bin/env bash\nprintf "%%s\\n" clean\n' > "$d/scripts/bad.sh"
rm -f "$d/docs-ran" "$d/ci-ran"
printf '#!/usr/bin/env bash\ntouch docs-ran\nexit 7\n' > "$d/scripts/check-docs-consistency.sh"
(cd "$d" && PATH="$lint_bin:$PATH" bash -c "$lint_cmd") >"$WORK/lint-output" 2>&1; rc=$?
if [ "$rc" -ne 0 ] && [ -e "$d/docs-ran" ] && [ ! -e "$d/ci-ran" ]; then
  ok "kiểm tài liệu đỏ → lint đỏ, không chạy kiểm CI"
else
  bad "kiểm tài liệu đỏ nhưng lint exit $rc / docs-ran=$([ -e "$d/docs-ran" ] && echo yes || echo no) / ci-ran=$([ -e "$d/ci-ran" ] && echo yes || echo no)"
fi
printf '#!/usr/bin/env bash\ntouch docs-ran\n' > "$d/scripts/check-docs-consistency.sh"
rm -f "$d/docs-ran" "$d/ci-ran"
(cd "$d" && PATH="$lint_bin:$PATH" bash -c "$lint_cmd") >"$WORK/lint-output" 2>&1; rc=$?
if [ "$rc" -eq 0 ] && [ -e "$d/docs-ran" ] && [ -e "$d/ci-ran" ]; then
  ok "ba bước xanh → lint xanh và đều đã chạy"
else
  bad "ba bước sạch nhưng lint exit $rc hoặc thiếu bước"
fi

if [ "$fails" -eq 0 ]; then echo "OK — dev-task.sh phân giải đúng lệnh cho 13 stack, alias Node, môi trường Python."; exit 0; fi
echo "FAIL — $fails ca hỏng."; exit 1
