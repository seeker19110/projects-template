#!/usr/bin/env bash
# Hai dự án đích tối thiểu: copy khung, cấu hình gate, chạy Node/Python thật.
# CI drop-in chỉ được kiểm cấu trúc offline; GitHub hosted CI cần một repo đích riêng.
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -r "$WORK"' EXIT
# shellcheck source=scripts/_test-lib.sh
source "$ROOT/scripts/_test-lib.sh"

for tool in git node python3; do
  command -v "$tool" >/dev/null 2>&1 || { bad "thiếu runtime bắt buộc: $tool"; exit 1; }
done

new_target() { # $1: tên fixture
  local dir="$WORK/$1"
  mkdir -p "$dir"
  git -C "$dir" init -q || return 1
  if ! bash "$ROOT/copy-framework.sh" "$dir" >"$WORK/copy-$1.log" 2>&1; then
    cat "$WORK/copy-$1.log" >&2
    return 1
  fi
  [ -f "$dir/scripts/dev-task.sh" ] && [ -f "$dir/_framework-dropins/.github/workflows/ci.yml" ] || return 1
  printf '%s' "$dir"
}

# Dự án đích phải thấy ROOT của CHÍNH NÓ: gate/doctor ưu tiên CLAUDE_PROJECT_DIR, mà hook pre-commit-gate
# của repo khung đặt biến đó trỏ về khung → gate khung chạy lại trong gate khung (TRAPS mục 52).
gate_expect() { # $1: target; $2: expected exit; $3: expected output marker
  local dir="$1" expected="$2" marker="$3" rc
  (cd "$dir" && CLAUDE_PROJECT_DIR="$dir" bash scripts/dev-task.sh gate) >"$WORK/gate.log" 2>&1; rc=$?
  if [ "$rc" -eq "$expected" ] && grep -Fq "$marker" "$WORK/gate.log"; then
    ok "$(basename "$dir"): gate exit $rc; $marker"
  else
    bad "$(basename "$dir"): gate exit $rc (mong $expected), thiếu '$marker'"
    cat "$WORK/gate.log" >&2
  fi
}

ci_policy_check() { # Kiểm cấu trúc offline của ci.yml đã cài vào đích.
  local ci="$1" dir="$2" script
  grep -Eq '^[[:space:]]+run: bash scripts/dev-task\.sh gate[[:space:]]*$' "$ci" || return 1
  grep -Eq '^[[:space:]]+run: bash scripts/dev-task\.sh doctor[[:space:]]*$' "$ci" || return 1
  grep -Eq '^[[:space:]]+- uses:' "$ci" || return 1
  if grep -E '^[[:space:]]+- uses:' "$ci" \
    | grep -Ev 'uses:[[:space:]]+[^[:space:]@]+@[0-9a-f]{40}([[:space:]]|$)' >/dev/null; then return 1; fi
  while IFS= read -r script; do
    [ -f "$dir/$script" ] || return 1
  done < <(grep -Eo 'scripts/[A-Za-z0-9_.-]+\.sh' "$ci" | sort -u)
}

install_and_check_ci() { # $1: target
  local dir="$1" ci="$1/.github/workflows/ci.yml"
  mkdir -p "$dir/.github/workflows"
  cp "$dir/_framework-dropins/.github/workflows/ci.yml" "$ci"
  sed -i 's/bash scripts\/dev-task.sh gate/echo gate-omitted/' "$ci"
  if ci_policy_check "$ci" "$dir"; then bad "$(basename "$dir"): cổng offline bỏ sót gate bị xoá";
  else ok "$(basename "$dir"): cổng offline đỏ khi xoá lời gọi gate"; fi
  cp "$dir/_framework-dropins/.github/workflows/ci.yml" "$ci"
  sed -i 's/actions\/checkout@[0-9a-f]*/actions\/checkout@v0/' "$ci"
  if ci_policy_check "$ci" "$dir"; then bad "$(basename "$dir"): cổng offline bỏ sót action không ghim SHA";
  else ok "$(basename "$dir"): cổng offline đỏ khi action không ghim SHA"; fi
  cp "$dir/_framework-dropins/.github/workflows/ci.yml" "$ci"
  sed -i '/run: bash scripts\/dev-task.sh gate/a\      - run: bash scripts/missing-ci-only.sh' "$ci"
  if ci_policy_check "$ci" "$dir"; then bad "$(basename "$dir"): cổng offline bỏ sót script chưa phát";
  else ok "$(basename "$dir"): cổng offline đỏ khi CI gọi script chưa phát"; fi
  cp "$dir/_framework-dropins/.github/workflows/ci.yml" "$ci"
  if ci_policy_check "$ci" "$dir"; then ok "$(basename "$dir"): CI drop-in chỉ gọi script đã phát, có gate và action ghim SHA";
  else bad "$(basename "$dir"): CI drop-in gọi script vắng hoặc thiếu gate/action ghim SHA"; fi
  (cd "$dir" && CLAUDE_PROJECT_DIR="$dir" bash scripts/dev-task.sh doctor) >"$WORK/doctor.log" 2>&1
  if [ "$?" -eq 0 ] && grep -Fq 'READY:' "$WORK/doctor.log"; then ok "$(basename "$dir"): lệnh doctor của CI trả READY";
  else bad "$(basename "$dir"): lệnh doctor của CI không READY"; cat "$WORK/doctor.log" >&2; fi
  gate_expect "$dir" 0 'PASS: 3 kiểm tra đã chạy thành công'
  spec_contract_expect "$dir"
}

spec_contract_expect() { # CI drop-in phải CHẠY contract C-1..C-4 của spec Approved: engine phát sang đích từ 2026-09-13
  # nhưng không job nào gọi → chết im lặng (TRAPS mục 11/25; đối chiếu SDD 2026-10-10). Chạy đúng dòng `run:` của drop-in.
  local dir="$1" name cmd spec missing="scripts/khong-co.sh"  # biến: docs-consistency không soi đường dẫn giả trong backtick
  name="$(basename "$dir")"; spec="$dir/docs/specs/2099-01-01-ca-am.md"
  cmd="$(grep -E '^[[:space:]]+run: .*spec-compiler\.sh --compile-all' "$dir/.github/workflows/ci.yml" | sed -E 's/^[[:space:]]+run: //')"
  if [ -z "$cmd" ]; then bad "$name: CI drop-in không chạy spec-compiler → spec Approved không cổng nào kiểm"; return; fi
  if (cd "$dir" && bash -ec "$cmd") >"$WORK/spec.log" 2>&1; then ok "$name: chưa có spec → bước contract xanh";
  else bad "$name: chưa có spec nhưng bước contract đỏ"; cat "$WORK/spec.log" >&2; fi
  printf '%s\n' '# Feature spec: ca âm' '' '| Thuộc tính | Giá trị |' '| --- | --- |' '| State | Approved for implementation |' '' \
    '## 9. Acceptance criteria' '' '- AC-1 Có file thật.' '' '| AC | Bằng chứng |' '| --- | --- |' '| AC-1 | `'"$missing"'` |' '' \
    '## 11. Architecture và code touchpoints' '' '- `'"$missing"'`' > "$spec"
  if (cd "$dir" && bash -ec "$cmd") >"$WORK/spec.log" 2>&1; then bad "$name: spec Approved trỏ file không có mà bước contract vẫn xanh"; cat "$WORK/spec.log" >&2;
  else ok "$name: spec Approved trỏ file không có → bước contract đỏ"; fi
  sed -i "s|$missing|scripts/dev-task.sh|g" "$spec"
  if (cd "$dir" && bash -ec "$cmd") >"$WORK/spec.log" 2>&1; then ok "$name: sửa về file có thật → bước contract xanh";
  else bad "$name: file có thật nhưng bước contract đỏ"; cat "$WORK/spec.log" >&2; fi
  rm -f "$spec"; rm -rf "$dir/tests/contracts"
}

clone_ci_expect() { # CI chỉ thấy file đã commit, không thấy config bị ignore ở máy dev.
  local dir="$1" name clone tracked_clone
  name="$(basename "$dir")"
  cp "$dir/_framework-dropins/.gitignore" "$dir/.gitignore"
  rm -r "$dir/_framework-dropins"
  git -C "$dir" check-ignore -q .claude/project-commands.sh || { bad "$name: config phải mặc định bị ignore"; return; }
  git -C "$dir" add -A
  git -C "$dir" -c user.email=smoke@example.invalid -c user.name=Smoke commit -qm 'test: target fixture'
  clone="$WORK/clone-$name"
  git clone -q --no-hardlinks "$dir" "$clone"
  (cd "$clone" && CLAUDE_PROJECT_DIR="$clone" bash scripts/dev-task.sh doctor) >"$WORK/clone-doctor.log" 2>&1
  if [ "$?" -eq 2 ] && grep -Fq 'BLOCKED:' "$WORK/clone-doctor.log"; then
    ok "$name: checkout sạch thiếu config bị ignore → doctor BLOCKED"
  else
    bad "$name: checkout sạch thiếu config nhưng doctor không BLOCKED"
    cat "$WORK/clone-doctor.log" >&2
  fi
  git -C "$dir" add -f .claude/project-commands.sh
  git -C "$dir" -c user.email=smoke@example.invalid -c user.name=Smoke commit -qm 'test: track reviewed commands'
  tracked_clone="$WORK/clone-tracked-$name"
  git clone -q --no-hardlinks "$dir" "$tracked_clone"
  (cd "$tracked_clone" && CLAUDE_PROJECT_DIR="$tracked_clone" bash scripts/dev-task.sh doctor) >"$WORK/clone-doctor.log" 2>&1
  if [ "$?" -eq 0 ] && grep -Fq 'READY:' "$WORK/clone-doctor.log"; then
    ok "$name: checkout sạch có config đã review → doctor READY"
  else
    bad "$name: config đã track nhưng doctor không READY"
    cat "$WORK/clone-doctor.log" >&2
  fi
  gate_expect "$tracked_clone" 0 'PASS: 3 kiểm tra đã chạy thành công'
}

echo "== Node: copy → gate đỏ khi logic sai → gate xanh khi sửa =="
node_dir="$(new_target node)" || { bad "không copy được vào Node target"; exit 1; }
cat > "$node_dir/.claude/project-commands.sh" <<'COMMANDS'
gate_tools='node'
build='node --check sum.cjs'
lint='node --check test.cjs'
test='node test.cjs'
gate_skip_typecheck_reason='Fixture JavaScript thuần; hành vi được kiểm bằng test Node thật.'
COMMANDS
printf 'module.exports = (a, b) => a - b;\n' > "$node_dir/sum.cjs"
printf "require('node:assert/strict').equal(require('./sum.cjs')(2, 3), 5);\n" > "$node_dir/test.cjs"
gate_expect "$node_dir" 1 "FAIL: kiểm tra 'test' thất bại"
printf 'module.exports = (a, b) => a + b;\n' > "$node_dir/sum.cjs"
gate_expect "$node_dir" 0 'PASS: 3 kiểm tra đã chạy thành công'
install_and_check_ci "$node_dir"
clone_ci_expect "$node_dir"

echo "== Python: copy → gate đỏ khi logic sai → gate xanh khi sửa =="
python_dir="$(new_target python)" || { bad "không copy được vào Python target"; exit 1; }
cat > "$python_dir/.claude/project-commands.sh" <<'COMMANDS'
gate_tools='python3'
build='python3 -m py_compile calc.py test_calc.py'
lint='python3 -m tabnanny calc.py test_calc.py'
test='python3 -m unittest -q test_calc'
gate_skip_typecheck_reason='Fixture Python động; hành vi được kiểm bằng unittest thật.'
COMMANDS
printf 'def add(a, b):\n    return a - b\n' > "$python_dir/calc.py"
cat > "$python_dir/test_calc.py" <<'PYTEST'
import unittest
from calc import add


class CalcTest(unittest.TestCase):
    def test_add(self):
        self.assertEqual(add(2, 3), 5)
PYTEST
gate_expect "$python_dir" 1 "FAIL: kiểm tra 'test' thất bại"
printf 'def add(a, b):\n    return a + b\n' > "$python_dir/calc.py"
gate_expect "$python_dir" 0 'PASS: 3 kiểm tra đã chạy thành công'
install_and_check_ci "$python_dir"
clone_ci_expect "$python_dir"

if command -v pwsh >/dev/null 2>&1; then
  ps_dir="$WORK/powershell"
  mkdir -p "$ps_dir"
  git -C "$ps_dir" init -q
  if pwsh -NoProfile -File "$ROOT/copy-framework.ps1" "$ps_dir" >"$WORK/copy-powershell.log" 2>&1 \
    && cmp -s "$ps_dir/_framework-dropins/.github/workflows/ci.yml" "$ROOT/docs/framework/templates/ci-target.yml"; then
    ok 'PowerShell và Bash phát cùng CI drop-in cho đích'
  else
    bad 'PowerShell và Bash phát CI drop-in khác nhau hoặc copy lỗi'
    diff -u "$ROOT/docs/framework/templates/ci-target.yml" "$ps_dir/_framework-dropins/.github/workflows/ci.yml" >&2 || true
    tail -n 8 "$WORK/copy-powershell.log" >&2
  fi
elif [ "${REQUIRE_PWSH:-0}" = 1 ]; then
  bad 'thiếu PowerShell bắt buộc để đối chiếu CI drop-in'
else
  echo '  ℹ️  không có pwsh; chưa đối chiếu bản PowerShell trên máy này'
fi

finish "Node/Python copy + gate thật xanh sau ca đỏ; CI drop-in kiểm cấu trúc offline + bước spec contract chạy thật."
