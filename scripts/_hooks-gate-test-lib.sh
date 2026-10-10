#!/usr/bin/env bash
# _hooks-gate-test-lib.sh — phần dùng chung của hai suite hook (`source`, KHÔNG chạy trực tiếp):
# scripts/test-hooks-gate.sh (mục 1–16) và scripts/test-hooks-gate-guard.sh (mục 17–19). Tách 2026-10-10 vì
# test-hooks-gate.sh vượt 400 dòng (radar); cùng khuôn với _dev-task-test-lib.sh. Phát sang dự án đích TRƯỚC hai
# suite (copy-framework.manifest, TRAPS.md mục 19) — smoke của test-copy-framework.sh chạy cả hai ở đích.
#   setup_project <exit gate> → dự án giả có scripts/dev-task.sh trả exit đó · run_hook <dir> <lệnh> [no-jq] [hook]
#   skip <nhãn> (thiếu jq) · hooks_gate_finish <OK> <đỏ> (kết luận cuối suite)
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOOK="$ROOT/.claude/hooks/pre-commit-gate.sh"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# shellcheck source=scripts/_test-lib.sh
source "$ROOT/scripts/_test-lib.sh"
fails=0  # _test-lib.sh cũng khởi tạo; khai rõ để ShellCheck kiểm được file độc lập.
skips=0
skip() { echo "  ⏭  BỎ QUA (thiếu jq): $1"; skips=$((skips+1)); }

# Hook đọc lệnh từ payload JSON bằng jq. Thiếu jq → hook fail-open theo thiết kế, nên mọi ca
# "phải chặn" lẫn "không chặn oan" đều cho exit 0 — xanh giả hoặc đỏ sai bản chất. Báo BỎ QUA
# trung thực thay vì kết luận "cổng không hoạt động" (CLAUDE.md §7). CI có jq nên vẫn chứng minh đủ.
HAS_JQ=0; command -v jq >/dev/null 2>&1 && HAS_JQ=1
if [ "$HAS_JQ" = "0" ]; then
  echo "⚠️  Máy này KHÔNG có jq → hook fail-open; chỉ kiểm được ca fail-open (mục 5)."
  echo "   Cài jq để chạy đủ bộ (xem README → Yêu cầu môi trường)."
  echo ""
fi

# --- Dựng dự án giả: chỉ cần scripts/dev-task.sh mà hook sẽ gọi. ---
setup_project() {   # $1 = exit code mà `dev-task.sh gate` sẽ trả về
  local dir="$WORK/proj-$1-$RANDOM"
  mkdir -p "$dir/scripts"
  cat > "$dir/scripts/dev-task.sh" <<EOF
#!/usr/bin/env bash
[ "\${1:-}" = "gate" ] && exit $1
exit 0
EOF
  chmod +x "$dir/scripts/dev-task.sh"
  git -C "$dir" init -q 2>/dev/null
  git -C "$dir" switch -q -c feat/test 2>/dev/null || git -C "$dir" checkout -q -b feat/test 2>/dev/null   # hook chặn commit trên main (mục 11)
  printf '%s\n' "$dir"
}

# Chuỗi → JSON string. python3 trên Windows là bí danh WindowsApps, có lúc trả "Permission denied" (TRAPS mục 66): payload
# rỗng làm hook không đọc được lệnh và exit 0 → ca "phải chặn" đỏ chập chờn. Thử python3 rồi python; cả hai hỏng → báo to.
hook_json_str() {
  local py out
  for py in python3 python; do
    out="$(printf '%s' "$1" | "$py" -c 'import json,sys; print(json.dumps(sys.stdin.read()))' 2>/dev/null)" || continue
    [ -n "$out" ] && { printf '%s' "$out"; return 0; }
  done
  echo "hook_json_str: python3/python đều không mã hoá được JSON — payload hỏng, kết quả ca này vô nghĩa" >&2
  return 1
}

# Gọi hook với payload JSON như Claude Code gửi thật (PreToolUse, tool_input.command).
run_hook() {        # $1 = project dir, $2 = lệnh bash, [$3 = "no-jq"], [$4 = hook path]
  local dir="$1" cmd="$2" mode="${3:-}" hook="${4:-$HOOK}" path_override=""
  local payload; payload="$(printf '{"tool_input":{"command":%s}}' "$(hook_json_str "$cmd")")"
  if [ "$mode" = "no-jq" ]; then
    # PATH tối giản KHÔNG có jq (giữ coreutils/bash/git để hook chạy được).
    mkdir -p "$WORK/nojq-bin"
    for b in bash cat printf grep git awk sed env dirname pwd cd; do
      src="$(command -v "$b" 2>/dev/null)" && [ -n "$src" ] &&         { ln -sf "$src" "$WORK/nojq-bin/$b" 2>/dev/null || cp "$src" "$WORK/nojq-bin/$b" 2>/dev/null; }
    done
    # PATH giả phải thật sự chạy được: trên Windows/MSYS `ln -s` có thể không tạo được binary
    # dùng được, hook sẽ chết với exit 127 và test báo "chặn oan" — sai bản chất.
    # Dự phòng: giữ nguyên PATH thật, chỉ bỏ các thư mục có chứa jq.
    if env -i PATH="$WORK/nojq-bin" bash -c 'true' 2>/dev/null; then
      path_override="$WORK/nojq-bin"
    else
      local d filtered=""
      while IFS= read -r d; do
        [ -n "$d" ] || continue
        [ -x "$d/jq" ] || [ -x "$d/jq.exe" ] && continue
        filtered="${filtered:+$filtered:}$d"
      done <<< "$(printf '%s' "$PATH" | tr ':' '
')"
      path_override="$filtered"
    fi
  fi
  if [ -n "$path_override" ]; then
    ( cd "$dir" && printf '%s' "$payload" | env -i PATH="$path_override" CLAUDE_PROJECT_DIR="$dir" bash "$hook" 2>"$WORK/stderr.txt" )
  else
    # cwd = thư mục dự án: đúng thực tế (cwd của hook là cwd của lệnh commit); hook đọc cây từ cwd (mục 15).
    ( cd "$dir" && printf '%s' "$payload" | CLAUDE_PROJECT_DIR="$dir" bash "$hook" 2>"$WORK/stderr.txt" )
  fi
  echo $?
}

hooks_gate_finish() {   # $1 = phần sau "OK — " khi xanh, $2 = phần sau "❌ N ca thất bại — " khi đỏ (exit 1)
  echo ""
  if [ "$fails" -eq 0 ] && [ "$skips" -gt 0 ]; then
    echo "⚠️  $skips nhóm ca BỊ BỎ QUA vì máy thiếu jq — chưa chứng minh được cổng chặn."
    echo "OK (không có ca nào ĐỎ) — cài jq rồi chạy lại để có bằng chứng đầy đủ."
  elif [ "$fails" -eq 0 ]; then
    echo "OK — $1"
  else
    echo "❌ $fails ca thất bại — $2"
    exit 1
  fi
}
