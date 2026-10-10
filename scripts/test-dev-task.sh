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

# shellcheck source=scripts/_dev-task-test-lib.sh
source "$(dirname "$0")/_dev-task-test-lib.sh"


FAKEBIN="$WORK/bin"; mkdir -p "$FAKEBIN"
for b in ruff mypy pytest uv poetry flutter; do printf '#!/usr/bin/env bash\nexit 0\n' > "$FAKEBIN/$b"; chmod +x "$FAKEBIN/$b"; done
export PATH="$FAKEBIN:$PATH"

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
# F-309 (ghi nhận 2026-09-01, đóng 2026-10-09): KHÔNG có jq, bản cũ grep `"<task>"` trên CẢ package.json → khoá cùng tên
# ở dependencies/config bị coi là script → in `npm run test` cho dự án không có script test. Dựng PATH tối thiểu không jq
# bằng wrapper bash tới binary thật (không symlink — Git Bash Windows), chạy dev-task bằng $BASH tuyệt đối.
d="$(fx node4)"; printf '{"dependencies":{"test":"1.0.0"},"scripts":{"build":"x"}}\n' > "$d/package.json"
if command -v node >/dev/null 2>&1; then
  NOJQ="$WORK/nojq"; mkdir -p "$NOJQ"
  for b in node grep dirname; do printf '#!%s\nexec %q "$@"\n' "$BASH" "$(command -v "$b")" > "$NOJQ/$b"; chmod +x "$NOJQ/$b"; done
  got="$(PATH="$NOJQ" CLAUDE_PROJECT_DIR="$d" "$BASH" "$DT" --print test 2>/dev/null)"
  [ "$got" = "" ] && ok "không jq: khoá 'test' ở dependencies KHÔNG bị coi là script (F-309)" || bad "không jq: F-309 dương tính giả → '$got'"
  got="$(PATH="$NOJQ" CLAUDE_PROJECT_DIR="$d" "$BASH" "$DT" --print build 2>/dev/null)"
  [ "$got" = "npm run build" ] && ok "không jq: script thật vẫn được nhận (đọc JSON bằng node)" || bad "không jq: script 'build' bị bỏ sót → '$got'"
  # F-309b (nghiệm thu agent 2026-10-09, reviewer F3 + security-reviewer #1): gọi thẳng node_has_script với tên tùy ý —
  # "$1" đứng sau `-e` bị node đọc như CỜ (`--version` in phiên bản và trả 0; `--require=x.js` chạy mã), và `p.scripts[k]`
  # thấy cả khoá kế thừa từ Object.prototype (`toString` → "có script"). Caller hiện chỉ truyền tên cố định; cổng này giữ bất biến.
  nhs() { ( ROOT="$d"; . "$ROOT_REPO/scripts/_stack-detect.sh"; export PATH="$NOJQ"; node_has_script "$1" ); }
  got="$(nhs --version 2>/dev/null)"; rc=$?
  [ "$rc" -ne 0 ] && [ -z "$got" ] && ok "không jq: tên bắt đầu bằng '-' không thành cờ của node (F-309b)" || bad "không jq: '--version' → rc=$rc, stdout='$got' (option injection)"
  nhs toString >/dev/null 2>&1 && bad "không jq: khoá kế thừa 'toString' bị coi là script (F-309b)" || ok "không jq: chỉ nhận khoá sở hữu của scripts (F-309b)"
  # Không jq LẪN không node (reviewer F1): phải báo ra stderr, không im lặng trả false.
  mkdir -p "$NOJQ/none"; cp "$NOJQ/grep" "$NOJQ/dirname" "$NOJQ/none/"
  err="$( ( ROOT="$d"; . "$ROOT_REPO/scripts/_stack-detect.sh"; export PATH="$NOJQ/none"; node_has_script build ) 2>&1 >/dev/null )"
  [[ "$err" == *"jq lẫn node"* ]] && ok "không jq, không node: cảnh báo ra stderr thay vì im lặng (F-309b)" || bad "không jq, không node: im lặng → stderr='$err'"
  # BOM UTF-8 đầu package.json: jq bỏ qua BOM, JSON.parse thì ném → hai nhánh phải cùng kết quả (reviewer F2).
  d="$(fx node5)"; printf '\xEF\xBB\xBF{"scripts":{"build":"x"}}\n' > "$d/package.json"
  got="$(PATH="$NOJQ" CLAUDE_PROJECT_DIR="$d" "$BASH" "$DT" --print build 2>/dev/null)"
  [ "$got" = "npm run build" ] && ok "không jq: package.json có BOM vẫn nhận script (khớp nhánh jq)" || bad "không jq: BOM làm mất script 'build' → '$got'"
else
  echo "  ℹ️ không có node — bỏ qua ca không-jq (F-309)"
fi

# Có jq: khoá cùng tên ở `config` không phải script (chỉ đọc `.scripts[...]`).
d="$(fx node6)"; printf '{"config":{"lint":"x"},"scripts":{"build":"y"}}\n' > "$d/package.json"
expect "$d" lint "" "có jq: khoá 'lint' ở config KHÔNG bị coi là script, không bịa 'npm run lint'"
expect "$d" build "npm run build" "có jq: script 'build' thật vẫn được nhận"

echo "== 2. Python: venv / uv / poetry / PATH, marker requirements.txt =="
d="$(fx py1)"; : > "$d/requirements.txt"; mkdir -p "$d/.venv/bin"; printf '#!/usr/bin/env bash\nexit 0\n' > "$d/.venv/bin/ruff"; chmod +x "$d/.venv/bin/ruff"
expect "$d" lint "$(printf '%q' "$d/.venv/bin/ruff") check ." "requirements.txt là marker; ruff trong .venv được ưu tiên hơn PATH"
d="$(fx 'py windows space')"; : > "$d/requirements.txt"; mkdir -p "$d/.venv/Scripts"; printf '#!/usr/bin/env bash\nexit 0\n' > "$d/.venv/Scripts/ruff.exe"; chmod +x "$d/.venv/Scripts/ruff.exe"
expect "$d" lint "$(printf '%q' "$d/.venv/Scripts/ruff.exe") check ." "Windows venv executable path được quote như một đối số"
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
tmpdt="$WORK/dev-task-noalias.sh"; cp "$DT" "$tmpdt"
# _node_aliases nằm ở _stack-detect.sh (dev-task.sh source file cùng thư mục) → gỡ alias ở bản sao đó
sed 's/typecheck) echo "typecheck type-check tsc check-types" ;;/typecheck) echo "typecheck" ;;/' "$ROOT/scripts/_stack-detect.sh" > "$WORK/_stack-detect.sh"
got="$(CLAUDE_PROJECT_DIR="$WORK/node1" bash "$tmpdt" --print typecheck 2>/dev/null)"
[ -z "$got" ] && ok "negative: không alias → 'type-check' không được nhận (test bắt được)" || bad "negative test không bắt được (được '$got')"


# Contract tests share the real dispatcher (helpers in _dev-task-test-lib.sh); fixture commands are stubs.
hooks_warning_tests() {   # doctor nhắc bật core.hooksPath (harness ngoài Claude Code không có cổng commit); không đổi exit code
  local d
  d="$(gate_fixture gate-hooks-unset)"; mkdir -p "$d/scripts/githooks"; : > "$d/scripts/githooks/pre-commit"; git init -q "$d"
  gate_case "$d" 0 'core.hooksPath chưa trỏ scripts/githooks' doctor
  d="$(gate_fixture gate-hooks-set)"; mkdir -p "$d/scripts/githooks"; : > "$d/scripts/githooks/pre-commit"; git init -q "$d"
  git -C "$d" config core.hooksPath scripts/githooks
  gate_case "$d" 0 READY doctor
  if grep -q 'core.hooksPath chưa trỏ' "$WORK/gate-output"; then bad "hooksPath đã đặt mà doctor vẫn cảnh báo"; else ok "hooksPath đã đặt → không cảnh báo"; fi
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
  hooks_warning_tests
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


echo "== 7d. Gate lồng nhau trên cùng ROOT → BLOCKED có lý do, không đệ quy (2026-10-08) =="
# VÌ SAO: test-adoption-smoke chạy gate của dự án đích giả mà KẾ THỪA CLAUDE_PROJECT_DIR của repo khung
# (hook pre-commit-gate đặt biến này) → ROOT quay về khung → gate khung chạy lại chính nó → treo vô hạn,
# CI không thấy vì CI không đặt biến. Fixture: lệnh test tự gọi lại gate với cùng ROOT; chặn ở 3 tầng
# để bản dev-task CŨ (chưa có chốt) không chạy mãi mà vẫn ĐỎ (không có thông báo "lồng nhau").
d="$(gate_fixture nested)"
printf '%s\n' "test='[ \"\${NESTED_DEPTH:-0}\" -lt 3 ] || exit 7; NESTED_DEPTH=\$((\${NESTED_DEPTH:-0}+1)) bash \"$DT\" gate'" >> "$d/.claude/project-commands.sh"
gate_case "$d" 1 "lồng nhau trên cùng ROOT"

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

finish "dev-task.sh phân giải đúng lệnh cho 13 stack, alias Node, môi trường Python."
