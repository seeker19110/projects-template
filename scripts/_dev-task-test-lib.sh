#!/usr/bin/env bash
# _dev-task-test-lib.sh — phần dùng chung của hai suite dev-task (`source`, KHÔNG chạy trực tiếp):
# thư mục tạm, fixture tối thiểu và hàm chạy gate/doctor. Tách 2026-10-09 vì test-dev-task.sh vượt 400 dòng
# (radar); cùng khuôn với `_test-lib.sh` (bộ đếm) — lib này chỉ thêm phần RIÊNG của dev-task.
#   fx <tên>            → thư mục fixture mới (dev-task cần CLAUDE_PROJECT_DIR trỏ tới nó)
#   gate_case <fx> <exit> <marker> [gate|doctor]   chạy và so exit + dấu hiệu trong output
#   gate_fixture <tên>  → fixture có .claude/project-commands.sh 4 lệnh không phải no-op
#   assert_no_marker <fx>  doctor/preflight không được chạy lệnh thật
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DT="$ROOT/scripts/dev-task.sh"
# shellcheck disable=SC2034  # test-dev-task.sh dùng ROOT_REPO khi source _stack-detect.sh trong subshell
ROOT_REPO="$ROOT"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
# shellcheck source=scripts/_test-lib.sh
source "$ROOT/scripts/_test-lib.sh"

fx() {   # fx <tên> → thư mục fixture mới (dev-task cần scripts/ để tính ROOT qua CLAUDE_PROJECT_DIR)
  local d="$WORK/$1"; mkdir -p "$d"; printf '%s' "$d"
}
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
