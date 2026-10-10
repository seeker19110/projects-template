#!/usr/bin/env bash
# test-hooks-gate.sh — CHỨNG MINH hook cổng thật sự CHẶN, không chỉ tồn tại.
#
# VÌ SAO CẦN (audit 2026-09-12, F-002): `.claude/hooks/pre-commit-gate.sh` là tính năng cốt lõi
# của khung — "cổng chặn commit đỏ". Trước script này KHÔNG có bất kỳ test nào chạy nó:
# `test-copy-framework.sh` chỉ kiểm hook được COPY, `verify-dropins.sh` cố ý không commit nên
# husky cũng không chạy. Tức hàng rào quan trọng nhất là hàng rào duy nhất chưa có bằng chứng
# hoạt động — nếu nó hỏng im lặng (fail-open), mọi dự án đích mất cổng mà không ai biết.
#
# Kiểm: pre-commit-gate (6 ca + main/bí mật/file lớn) + block-dangerous-git (chặn 5 khuôn, không chặn oan, cờ bỏ qua, negative test).
# Chi tiết pre-commit-gate: chặn khi đỏ · cho qua khi xanh · --no-verify bỏ qua · lệnh không phải commit bỏ qua ·
# thiếu jq thì fail-open CÓ CẢNH BÁO · và NEGATIVE TEST (hook hỏng phải làm test này đỏ).
#
# Chạy: bash scripts/test-hooks-gate.sh
set -uo pipefail   # cố ý KHÔNG -e: không được làm chết phiên/lượt chạy (xem docs/CONVENTIONS.md §A)

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
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

# Gọi hook với payload JSON như Claude Code gửi thật (PreToolUse, tool_input.command).
run_hook() {        # $1 = project dir, $2 = lệnh bash, [$3 = "no-jq"], [$4 = hook path]
  local dir="$1" cmd="$2" mode="${3:-}" hook="${4:-$HOOK}" path_override=""
  local payload; payload="$(printf '{"tool_input":{"command":%s}}' "$(printf '%s' "$cmd" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))')")"
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

red="$(setup_project 1)"
green="$(setup_project 0)"

echo "== 1. Cổng ĐỎ + lệnh git commit → PHẢI chặn (exit 2) =="
if [ "$HAS_JQ" = "0" ]; then skip "hook không đọc được lệnh nên không thể chứng minh việc chặn"; else
rc="$(run_hook "$red" 'git commit -m "test"')"
[ "$rc" = "2" ] && ok "hook chặn commit (exit 2)" || bad "hook KHÔNG chặn khi cổng đỏ (exit $rc, kỳ vọng 2)"

echo "== 2. Cổng XANH + git commit → phải cho qua (exit 0) =="
rc="$(run_hook "$green" 'git commit -m "test"')"
[ "$rc" = "0" ] && ok "hook cho qua khi cổng xanh" || bad "hook chặn oan khi cổng xanh (exit $rc)"

echo "== 3. Cổng ĐỎ nhưng có --no-verify → bỏ qua có chủ đích (exit 0) =="
rc="$(run_hook "$red" 'git commit --no-verify -m "test"')"
[ "$rc" = "0" ] && ok "--no-verify bỏ qua được cổng" || bad "--no-verify không bỏ qua được (exit $rc)"

echo "== 4. Lệnh KHÔNG phải commit (cổng đỏ) → không can thiệp (exit 0) =="
rc="$(run_hook "$red" 'git status')"
[ "$rc" = "0" ] && ok "không can thiệp lệnh khác" || bad "can thiệp oan lệnh không phải commit (exit $rc)"
rc="$(run_hook "$red" "echo 'git commit trong chuỗi mô tả'")"
[ "$rc" = "0" ] && ok "không khớp nhầm chuỗi chứa chữ git commit" || bad "chặn OAN chuỗi mô tả (exit $rc)"

fi

# Máy đã thiếu jq sẵn thì không cần dựng PATH giả — điều kiện cần kiểm đã đúng sẵn.
echo "== 5. Thiếu jq → fail-open nhưng PHẢI có cảnh báo (không im lặng) =="
mode5="no-jq"; [ "$HAS_JQ" = "1" ] || mode5=""
rc="$(run_hook "$red" 'git commit -m "test"' "$mode5")"
if [ "$rc" = "0" ] && grep -q "jq" "$WORK/stderr.txt"; then
  ok "fail-open kèm cảnh báo ra stderr"
elif [ "$rc" = "0" ]; then
  bad "fail-open nhưng IM LẶNG — người dùng mất cổng mà không biết"
else
  bad "thiếu jq mà chặn commit (exit $rc) — hook phải fail-open"
fi

echo "== 6. NEGATIVE TEST: hook hỏng (luôn exit 0) PHẢI làm test này đỏ =="
if [ "$HAS_JQ" = "0" ]; then skip "mục 6–10 — vô nghĩa khi mục 1/7 không chạy được"; else
broken="$WORK/broken-hook.sh"
printf '#!/usr/bin/env bash\ncat >/dev/null\nexit 0\n' > "$broken"
rc="$(run_hook "$red" 'git commit -m "test"' "" "$broken")"
[ "$rc" = "0" ] && ok "test bắt được hook hỏng (ca 1 sẽ đỏ nếu hook ngừng chặn)" \
                || bad "negative test sai: hook hỏng lại trả $rc"

echo "== 7. block-dangerous-git.sh: PHẢI chặn 3 khuôn nguy hiểm =="
DG="$ROOT/.claude/hooks/block-dangerous-git.sh"
any="$(setup_project 0)"
for pair in \
  "git push --force origin main|force-push nhánh chính" \
  "git push -f origin main|force-push nhánh chính (-f)" \
  "git reset --hard HEAD~1|reset --hard" \
  "git merge --abort|merge --abort" \
  "git rebase --abort|rebase --abort" \
  "echo \"a << b\"
git reset --hard HEAD~1|lệnh nguy hiểm SAU một chuỗi chứa '<<' không phải heredoc" \
; do
  c="${pair%%|*}"; label="${pair##*|}"
  rc="$(run_hook "$any" "$c" "" "$DG")"
  [ "$rc" = "2" ] && ok "chặn: $label" || bad "KHÔNG chặn: $label (exit $rc, kỳ vọng 2)"
done

echo "== 8. block-dangerous-git.sh: KHÔNG được chặn oan =="
for pair in \
  "git push -u origin claude/abc|push thường lên nhánh riêng" \
  "git reset HEAD~1|reset mềm (không --hard)" \
  "git merge main|merge bình thường" \
  "git status|lệnh đọc" \
  "echo 'git reset --hard trong tài liệu'|chuỗi mô tả, không phải lệnh git" \
  "git commit -F - <<EOF
quay ve main roi push
EOF
git push -u origin claude/abc --force-with-lease|force-push nhánh RIÊNG, chữ 'main' chỉ nằm trong thân heredoc" \
  "git push --force-with-lease origin feat/main-menu|nhánh riêng có chuỗi 'main' trong TÊN nhánh" \
; do
  c="${pair%%|*}"; label="${pair##*|}"
  rc="$(run_hook "$any" "$c" "" "$DG")"
  [ "$rc" = "0" ] && ok "cho qua: $label" || bad "chặn OAN: $label (exit $rc, kỳ vọng 0)"
done

echo "== 9. Cờ bỏ qua tường minh ALLOW_DANGEROUS_GIT=1 =="
rc="$(printf '{"tool_input":{"command":"git reset --hard"}}' | ALLOW_DANGEROUS_GIT=1 bash "$DG" >/dev/null 2>&1; echo $?)"
[ "$rc" = "0" ] && ok "cờ bỏ qua hoạt động" || bad "cờ ALLOW_DANGEROUS_GIT không hoạt động (exit $rc)"

echo "== 10. NEGATIVE TEST cho hook chặn git (hook rỗng phải bị bắt) =="
rc="$(run_hook "$any" 'git reset --hard' "" "$broken")"
[ "$rc" = "0" ] && ok "test bắt được hook git hỏng" || bad "negative test sai (exit $rc)"

echo "== 11. pre-commit-gate: commit trên main/master bị chặn; bí mật / file lớn staged bị chặn =="
onmain="$(setup_project 0)"; git -C "$onmain" switch -q -c main 2>/dev/null || git -C "$onmain" checkout -q -b main
rc="$(run_hook "$onmain" 'git commit -m "x"')"
[ "$rc" = "2" ] && ok "chặn commit khi đang ở main (TRAPS 14)" || bad "KHÔNG chặn commit trên main (exit $rc)"
rc="$(cd "$onmain" && printf '{"tool_input":{"command":"git commit -m x"}}' | ALLOW_COMMIT_ON_MAIN=1 CLAUDE_PROJECT_DIR="$onmain" bash "$HOOK" >/dev/null 2>&1; echo $?)"
[ "$rc" = "0" ] && ok "ALLOW_COMMIT_ON_MAIN=1 cho qua" || bad "cờ ALLOW_COMMIT_ON_MAIN không hoạt động (exit $rc)"
sec="$(setup_project 0)"
# Khoá giả dựng lúc chạy (không viết literal — kẻo chính test này bị sweep/hook bắt).
printf 'KEY=AKIA%s\n' "$(printf 'Q%.0s' $(seq 16))" > "$sec/cfg.txt"; git -C "$sec" add cfg.txt
rc="$(run_hook "$sec" 'git commit -m "x"')"
[ "$rc" = "2" ] && ok "chặn commit có chuỗi giống khoá AWS trong staged" || bad "KHÔNG chặn bí mật staged (exit $rc)"
bigp="$(setup_project 0)"; head -c 1100000 /dev/zero > "$bigp/blob.bin"; git -C "$bigp" add blob.bin
rc="$(run_hook "$bigp" 'git commit -m "x"')"
[ "$rc" = "2" ] && ok "chặn commit có file staged > 1 MB" || bad "KHÔNG chặn file lớn staged (exit $rc)"
clean="$(setup_project 0)"; echo "hello" > "$clean/a.txt"; git -C "$clean" add a.txt
rc="$(run_hook "$clean" 'git commit -m "x"')"
[ "$rc" = "0" ] && ok "diff sạch trên nhánh riêng → cho qua" || bad "chặn OAN diff sạch (exit $rc)"

# Lệnh TỰ STAGE (`git add … && git commit`, `commit -a`): hook chạy TRƯỚC lệnh nên index còn cũ — bản trước chỉ
# đọc `diff --cached` nên bí mật/file lớn đi qua. Đối chiếu X-Agents #368 (TRAPS §3 của nó), đo lại ở repo này.
fakekey="AKIA$(printf 'ABCDEFGHIJKLMNOP')"   # dựng lúc chạy: file test không tự chứa khoá giả nguyên khối
c1="$(setup_project 0)"; head -c 1100000 /dev/zero > "$c1/blob.bin"
rc="$(run_hook "$c1" 'git add blob.bin && git commit -m "x"')"
[ "$rc" = "2" ] && ok "chặn: git add file >1MB && git commit (tự stage)" || bad "LỌT file lớn khi lệnh tự stage (exit $rc, kỳ vọng 2)"
c2="$(setup_project 0)"; printf 'key=%s\n' "$fakekey" > "$c2/conf.txt"
rc="$(run_hook "$c2" 'git add -A && git commit -m "x"')"
[ "$rc" = "2" ] && ok "chặn: git add -A && git commit có bí mật chưa stage" || bad "LỌT bí mật khi lệnh tự stage (exit $rc, kỳ vọng 2)"
c3="$(setup_project 0)"; echo ok > "$c3/t.txt"; git -C "$c3" add t.txt; git -C "$c3" -c user.email=t@t -c user.name=t commit -q -m init --no-verify
printf 'key=%s\n' "$fakekey" > "$c3/t.txt"
rc="$(run_hook "$c3" 'git commit -am "x"')"
[ "$rc" = "2" ] && ok "chặn: git commit -am có bí mật ở file đã theo dõi" || bad "LỌT bí mật với commit -a (exit $rc, kỳ vọng 2)"
c4="$(setup_project 0)"; printf 'key=%s\n' "$fakekey" > "$c4/conf.txt"
rc="$(run_hook "$c4" 'git commit -m "x"')"
[ "$rc" = "0" ] && ok "cho qua: commit thường khi bí mật chỉ nằm ngoài index (không chặn oan)" || bad "chặn OAN commit thường (exit $rc)"
c5="$(setup_project 0)"; echo hello > "$c5/a.txt"
rc="$(run_hook "$c5" 'git add a.txt && git commit -m "x"')"
[ "$rc" = "0" ] && ok "cho qua: git add file sạch && git commit" || bad "chặn OAN add file sạch (exit $rc)"

echo "== 12. block-dangerous-git: khuôn 5 — push xoá / ép ghi đè nhánh chính không có --force =="
for pair in \
  "git push origin +main|refspec +main" \
  "git push origin +HEAD:master|refspec +HEAD:master" \
  "git push origin :main|refspec :main (xoá)" \
  "git push --delete origin main|--delete main" \
  "git push origin -d master|-d master" \
; do
  c="${pair%%|*}"; label="${pair##*|}"
  rc="$(run_hook "$any" "$c" "" "$DG")"
  [ "$rc" = "2" ] && ok "chặn: $label" || bad "KHÔNG chặn: $label (exit $rc, kỳ vọng 2)"
done
for pair in \
  "git push origin +feat/x|refspec + nhánh riêng" \
  "git push --delete origin feat/x|xoá nhánh riêng" \
  "git push origin main|push thường lên main (ruleset chặn, hook không cần)" \
; do
  c="${pair%%|*}"; label="${pair##*|}"
  rc="$(run_hook "$any" "$c" "" "$DG")"
  [ "$rc" = "0" ] && ok "cho qua: $label" || bad "chặn OAN: $label (exit $rc)"
done

fi

echo "== 13. scripts/githooks/pre-commit (hook git chuẩn, harness-agnostic) =="
GH="$ROOT/scripts/githooks/pre-commit"
g1="$(setup_project 0)"; git -C "$g1" switch -q -c main 2>/dev/null || git -C "$g1" checkout -q -b main
rc="$( cd "$g1" && bash "$GH" >/dev/null 2>&1; echo $? )"
[ "$rc" = "1" ] && ok "githooks: chặn commit trên main (exit 1)" || bad "githooks: KHÔNG chặn trên main (exit $rc)"
g2="$(setup_project 0)"; echo hi > "$g2/a.txt"; git -C "$g2" add a.txt
rc="$( cd "$g2" && bash "$GH" >/dev/null 2>&1; echo $? )"
[ "$rc" = "0" ] && ok "githooks: nhánh riêng + diff sạch + gate xanh → 0" || bad "githooks: chặn oan (exit $rc)"
g3="$(setup_project 1)"; echo hi > "$g3/a.txt"; git -C "$g3" add a.txt
rc="$( cd "$g3" && bash "$GH" >/dev/null 2>&1; echo $? )"
[ "$rc" = "1" ] && ok "githooks: gate đỏ → 1" || bad "githooks: gate đỏ mà cho qua (exit $rc)"
g4="$(setup_project 0)"; echo hi > "$g4/a.txt"; git -C "$g4" add a.txt
cat > "$g4/scripts/dev-task.sh" <<'EOF'
#!/usr/bin/env bash
[ "${1:-}" = gate ] || exit 2
for name in GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_COMMON_DIR; do
  [ -z "${!name+x}" ] || exit 42
done
exit 0
EOF
chmod +x "$g4/scripts/dev-task.sh"
rc="$( cd "$g4" && GIT_DIR="$g4/.git" GIT_WORK_TREE="$g4" GIT_INDEX_FILE="$g4/.git/index" bash "$GH" >/dev/null 2>&1; echo $? )"
[ "$rc" = "0" ] && ok "githooks: gate không kế thừa biến Git của hook" || bad "githooks: gate kế thừa biến Git của hook (exit $rc)"

echo "== 14. hook nối trong settings*.json phải có bit thực thi trong git index =="
# VÌ SAO (đối chiếu X-Agents 2026-10-06, TRAPS họ H6): settings gọi THẲNG đường dẫn nên file mode 100644
# (commit từ Windows) → `sh` trả 126 "Permission denied" — Claude Code coi là lỗi KHÔNG chặn, hàng rào chết
# im lặng ngoài Windows. Đo thật ở repo này: `ui-intelligence.sh` 100644 chết rc=126; test mục 9 chạy nó qua
# `bash` nên không thấy. Phép thử phải xét MODE TRONG INDEX (mode trên đĩa Windows luôn "chạy được").
check_hook_modes() {   # $1 = root git; in từng đường dẫn hook không chạy được, mỗi dòng một đường dẫn
  local root="$1" f p mode
  for f in "$root"/.claude/settings.json "$root"/.claude/settings-shared-default.json; do
    [ -f "$f" ] || continue
    grep -oE '\$\{CLAUDE_PROJECT_DIR\}/[^" ]+' "$f" | sed 's|^\${CLAUDE_PROJECT_DIR}/||' | sort -u | while read -r p; do
      mode="$(git -C "$root" ls-files -s -- "$p" 2>/dev/null | awk '{print $1}')"
      if [ -z "$mode" ]; then [ -x "$root/$p" ] || echo "$p"; else [ "$mode" = "100755" ] || echo "$p"; fi
    done
  done
}
dead="$(check_hook_modes "$ROOT")"
[ -z "$dead" ] && ok "mọi hook trong settings*.json có mode 100755" || bad "hook KHÔNG chạy được ngoài Windows (cần 100755): $(echo "$dead" | tr '\n' ' ')"
# NEGATIVE TEST: hạ một hook về 100644 trong repo giả → phép thử phải đỏ (không thì nó xanh giả).
neg="$WORK/modes-neg"; mkdir -p "$neg/.claude/hooks"; git -C "$neg" init -q
printf '{"c":"${CLAUDE_PROJECT_DIR}/.claude/hooks/a.sh"}\n' > "$neg/.claude/settings.json"
printf '#!/usr/bin/env bash\n' > "$neg/.claude/hooks/a.sh"
git -C "$neg" add -A; git -C "$neg" update-index --chmod=-x .claude/hooks/a.sh
[ -n "$(check_hook_modes "$neg")" ] && ok "negative: hook 100644 bị phát hiện" || bad "negative: hook 100644 KHÔNG bị phát hiện (phép thử xanh giả)"

echo "== 15. pre-commit-gate: cây ĐANG COMMIT (worktree) ≠ CLAUDE_PROJECT_DIR (checkout chính) =="
# VÌ SAO (đối chiếu X-Agents 2026-09-15 `pt.10`, đo lại ở repo này): hook đọc nhánh/index/cổng từ CLAUDE_PROJECT_DIR.
# Phiên chạy trong `git worktree` thì lệnh `git commit` chạy ở worktree còn biến vẫn trỏ checkout chính → hỏng CẢ HAI
# chiều: chặn oan commit hợp lệ ("đang đứng trên main") và buông bí mật/cổng đỏ của worktree (đọc index rỗng của main).
wt_main="$(setup_project 0)"
git -C "$wt_main" add -A; git -C "$wt_main" -c user.email=t@t -c user.name=t commit -q -m init --no-verify
git -C "$wt_main" branch -M main
git -C "$wt_main" worktree add -q "$WORK/wt-tree" -b feat/wt 2>/dev/null
run_wt() {   # $1 = cwd của lệnh commit (worktree), $2 = lệnh; CLAUDE_PROJECT_DIR luôn là checkout chính
  local payload; payload="$(printf '{"tool_input":{"command":%s}}' "$(printf '%s' "$2" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))')")"
  ( cd "$1" && printf '%s' "$payload" | CLAUDE_PROJECT_DIR="$wt_main" bash "$HOOK" 2>"$WORK/stderr.txt"; echo $? )
}
echo "ok" > "$WORK/wt-tree/a.txt"; git -C "$WORK/wt-tree" add a.txt
rc="$(run_wt "$WORK/wt-tree" 'git commit -m "x"')"
[ "$rc" = "0" ] && ok "worktree feat/wt, checkout chính ở main → cho qua (không chặn oan)" || bad "chặn OAN commit trong worktree vì đọc nhánh của checkout chính (exit $rc, kỳ vọng 0)"
printf 'KEY=AKIA%s\n' "$(printf 'W%.0s' $(seq 16))" > "$WORK/wt-tree/cfg.txt"; git -C "$WORK/wt-tree" add cfg.txt
git -C "$wt_main" switch -q -c scratch   # main không còn là nhánh hiện tại → chỉ còn lỗi "đọc index checkout chính"
rc="$(run_wt "$WORK/wt-tree" 'git commit -m "x"')"
[ "$rc" = "2" ] && ok "bí mật staged trong worktree vẫn bị chặn" || bad "LỌT bí mật staged ở worktree vì đọc index checkout chính (exit $rc, kỳ vọng 2)"
git -C "$WORK/wt-tree" reset -q cfg.txt; rm -f "$WORK/wt-tree/cfg.txt"
printf '#!/usr/bin/env bash\n[ "${1:-}" = "gate" ] && exit 1\nexit 0\n' > "$WORK/wt-tree/scripts/dev-task.sh"   # cổng của WORKTREE đỏ, của checkout chính xanh
rc="$(run_wt "$WORK/wt-tree" 'git commit -m "x"')"
[ "$rc" = "2" ] && ok "cổng đỏ của worktree chặn commit (cổng chạy trên cây đang commit)" || bad "cổng chạy trên checkout chính thay vì worktree (exit $rc, kỳ vọng 2)"

echo "== 16. pre-commit-gate: THÂN HEREDOC là dữ liệu — không kích hoạt cổng / tự-stage oan =="
# VÌ SAO (O-2 P-A1, 2026-10-08): block-dangerous-git đã bỏ thân heredoc từ 2026-09-14 nhưng pre-commit-gate chỉ bỏ
# nháy — bản sao bộ lọc lệch nhau. `python3 - <<PY … git commit … PY` (cổng đỏ) bị chặn oan; commit có message
# heredoc nhắc "git add" bị coi là lệnh tự stage → soi cả file chưa theo dõi và chặn oan. Nay dùng chung _lib.sh.
if [ "$HAS_JQ" = "0" ]; then skip "mục 16 — hook không đọc được lệnh"; else
rc="$(run_hook "$red" 'python3 - <<PY
print("du lieu test")
git commit -m "trong than heredoc"
PY')"
[ "$rc" = "0" ] && ok "lệnh không phải commit, thân heredoc chứa git commit → không chạy cổng (exit 0)" \
               || bad "chạy cổng OAN vì thân heredoc chứa git commit (exit $rc, kỳ vọng 0)"
h2="$(setup_project 0)"; printf 'key=%s\n' "$fakekey" > "$h2/conf.txt"
rc="$(run_hook "$h2" 'git commit -F - <<EOF
nho chay git add -A truoc khi push
EOF')"
[ "$rc" = "0" ] && ok "commit có message heredoc nhắc git add → không coi là tự stage (exit 0)" \
               || bad "coi message heredoc là lệnh git add → soi file chưa theo dõi, chặn OAN (exit $rc, kỳ vọng 0)"
rc="$(run_hook "$red" 'cat <<EOF > note.txt
ghi chu
EOF
git commit -m "x"')"
[ "$rc" = "2" ] && ok "git commit THẬT sau heredoc vẫn qua cổng (cổng đỏ → exit 2)" \
               || bad "bỏ nhầm dòng LỆNH sau heredoc — cổng để lọt (exit $rc, kỳ vọng 2)"
fi

echo "== 17. Mẫu bí mật + ngưỡng file lớn: MỘT nguồn (scripts/_commit-guard.sh) cho hook/githook/sweep =="
# VÌ SAO (O-4b, 2026-10-08 — TRAPS.md mục 19/53 "bản sao lệch nhau"): regex bí mật + ngưỡng 1 MB từng chép
# nguyên văn 3 nơi, không gì kiểm chúng còn khớp. Mẫu dựng lúc chạy để chính file test không chứa bản rời.
pat_re='AKIA[0-9A-Z]{''16}'; pat_mb="$((1024*1024))"
for pat in "$pat_re" "$pat_mb"; do
  # *.framework-new (file hoặc thư mục) = bản khung copy-framework để cạnh ở dự án đích, không phải mã đang chạy (F-Q7).
  stray="$(grep -rlF --exclude='*.framework-new' --exclude-dir='*.framework-new' -- "$pat" "$ROOT/scripts" "$ROOT/.claude/hooks" 2>/dev/null | grep -v '/scripts/_commit-guard\.sh$' || true)"
  [ -z "$stray" ] && ok "không còn bản rời '$pat' ngoài scripts/_commit-guard.sh" \
                  || bad "còn bản rời '$pat' ngoài scripts/_commit-guard.sh: $(printf '%s' "${stray//$ROOT\//}" | tr '\n' ' ')"
done
g5="$(setup_project 0)"; printf 'key=%s\n' "$fakekey" > "$g5/conf.txt"; git -C "$g5" add conf.txt
rc="$( cd "$g5" && bash "$GH" >/dev/null 2>&1; echo $? )"
[ "$rc" = "1" ] && ok "githooks: chặn bí mật staged (exit 1)" || bad "githooks: LỌT bí mật staged (exit $rc, kỳ vọng 1)"
g6="$(setup_project 0)"; head -c 1100000 /dev/zero > "$g6/blob.bin"; git -C "$g6" add blob.bin
rc="$( cd "$g6" && bash "$GH" >/dev/null 2>&1; echo $? )"
[ "$rc" = "1" ] && ok "githooks: chặn file staged > 1 MB (exit 1)" || bad "githooks: LỌT file lớn staged (exit $rc, kỳ vọng 1)"
# Dự án đích copy hook TRƯỚC khi có _commit-guard.sh: thiếu nguồn mẫu → CHẶN kèm lời nhắc (fail-closed), không
# âm thầm bỏ kiểm bí mật. Bản hook/githook dựng trong cây tạm không có scripts/_commit-guard.sh.
nolib="$(setup_project 0)"; mkdir -p "$nolib/.claude/hooks" "$nolib/scripts/githooks"
cp "$HOOK" "$ROOT/.claude/hooks/_lib.sh" "$nolib/.claude/hooks/"; cp "$GH" "$nolib/scripts/githooks/pre-commit"
echo hi > "$nolib/a.txt"; git -C "$nolib" add a.txt
rc="$( cd "$nolib" && bash scripts/githooks/pre-commit 2>"$WORK/stderr.txt" >/dev/null; echo $? )"
[ "$rc" = "1" ] && grep -q '_commit-guard.sh' "$WORK/stderr.txt" && ok "githooks: thiếu _commit-guard.sh → chặn kèm lời nhắc" \
  || bad "githooks: thiếu _commit-guard.sh mà không chặn/không nhắc (exit $rc)"
if [ "$HAS_JQ" = "0" ]; then skip "mục 17 — pre-commit-gate thiếu _commit-guard.sh"; else
rc="$(run_hook "$nolib" 'git commit -m "x"' "" "$nolib/.claude/hooks/pre-commit-gate.sh")"
[ "$rc" = "2" ] && grep -q '_commit-guard.sh' "$WORK/stderr.txt" && ok "pre-commit-gate: thiếu _commit-guard.sh → chặn kèm lời nhắc" \
  || bad "pre-commit-gate: thiếu _commit-guard.sh mà không chặn/không nhắc (exit $rc)"
fi

echo "== 18. Bộ lọc dữ liệu/nháy KHÔNG được tự khớp nhầm — biến thể lọt (audit 2026-10-09, TRAPS.md mục 62) =="
# VÌ SAO (F-S01, F-Q1..Q5): mỗi ca "chặn" dưới đo thật là exit 0 (LỌT) ở bản trước. Nháy đơn trong nháy kép (`don't`)
# làm bộ lọc nháy nuốt lệnh giữa; refspec đầy đủ `refs/heads/main`, cờ gộp `-fu`, tên nhánh trong nháy `"main"`;
# vỏ bọc `bash -c '…'`; `<<-EOF` có terminator thụt tab; `<<` nằm trong chuỗi; `--no-verify` của lệnh KHÁC.
if [ "$HAS_JQ" = "0" ]; then skip "mục 18 — hook không đọc được lệnh"; else
tab="$(printf '\t')"
for pair in \
  "git commit -m \"don't break\" && git push --force origin main && echo \"it's done\"|nháy đơn trong nháy kép không nuốt force-push main" \
  "git push origin +refs/heads/main|refspec +refs/heads/main" \
  "git push origin +HEAD:refs/heads/main|refspec +HEAD:refs/heads/main" \
  "git push -fu origin main|cờ gộp -fu + main" \
  "git push -f origin \"main\"|tên nhánh trong nháy \"main\"" \
  "git push -f origin HEAD:refs/heads/main|-f + HEAD:refs/heads/main" \
  "bash -c 'git reset --hard'|vỏ bọc bash -c '…'" \
  "cat <<-EOF
${tab}du lieu
${tab}EOF
git reset --hard|<<-EOF terminator thụt tab, lệnh nguy hiểm ở dòng sau" \
  "git push --delete origin refs/heads/main|--delete refs/heads/main" \
  "sh -c \"git push --force origin master\"|vỏ bọc sh -c \"…\"" \
  "eval \"git reset --hard\"|vỏ bọc eval \"…\"" \
  "echo \"x <<EOF\"
git reset --hard|'<<EOF' nằm trong chuỗi không phải heredoc" \
; do
  c="${pair%%|*}"; label="${pair##*|}"
  rc="$(run_hook "$any" "$c" "" "$DG")"
  [ "$rc" = "2" ] && ok "chặn: $label" || bad "KHÔNG chặn: $label (exit $rc, kỳ vọng 2)"
done
for pair in \
  "git push -f origin feat/x|force-push nhánh riêng (chỉ cảnh báo)" \
  "echo \"git reset --hard\"|chuỗi trong nháy kép không phải lệnh" \
  "git commit -m \"don't\"|message có nháy đơn trong nháy kép" \
  "rm -rf build && git push origin main|cờ gộp có chữ f của lệnh KHÁC không phải force-push" \
  "git push --force origin main:feat/x|force-push ghi vào nhánh riêng (dst khác main)" \
  "git commit -F - <<-EOF
${tab}quay ve main
${tab}EOF
git push -u origin claude/abc --force-with-lease|<<-EOF thụt tab: chữ 'main' chỉ trong thân, push nhánh riêng" \
; do
  c="${pair%%|*}"; label="${pair##*|}"
  rc="$(run_hook "$any" "$c" "" "$DG")"
  [ "$rc" = "0" ] && ok "cho qua: $label" || bad "chặn OAN: $label (exit $rc, kỳ vọng 0)"
done
rc="$(run_hook "$any" 'git push -f origin feat/x' "" "$DG")"
[ "$rc" = "0" ] && grep -q '⚠️' "$WORK/stderr.txt" && ok "force-push nhánh riêng vẫn có cảnh báo ⚠️" \
  || bad "force-push nhánh riêng mất cảnh báo ⚠️ (exit $rc)"
rc="$(run_hook "$red" 'git commit -m x && rm --no-verify')"
[ "$rc" = "2" ] && ! grep -q 'phát hiện --no-verify' "$WORK/stderr.txt" && ok "--no-verify của lệnh KHÁC không bỏ cổng (cổng đỏ → exit 2)" \
  || bad "--no-verify ở segment khác bỏ cổng (exit $rc, kỳ vọng 2 và không có 'phát hiện --no-verify')"
rc="$(run_hook "$red" "bash -c 'git commit -m x'")"
[ "$rc" = "2" ] && ok "git commit trong vỏ bọc bash -c vẫn qua cổng (cổng đỏ → exit 2)" \
  || bad "git commit trong bash -c bỏ qua cổng (exit $rc, kỳ vọng 2)"
rc="$(run_hook "$red" 'git commit --no-verify -m x && echo xong')"
[ "$rc" = "0" ] && ok "--no-verify cùng segment commit vẫn bỏ qua có chủ đích" || bad "--no-verify cùng segment không còn tác dụng (exit $rc)"
rc="$(run_hook "$green" "git commit -m \"don't\"")"
[ "$rc" = "0" ] && ok "pre-commit-gate: git commit -m \"don't\" trên nhánh riêng, cổng xanh → cho qua" \
  || bad "pre-commit-gate chặn OAN git commit -m \"don't\" (exit $rc)"
fi

echo "== 19. settings.json ↔ settings-shared-default.json GIỐNG HỆT; MCP context7 bật (audit 2026-10-09, T4) =="
# VÌ SAO: hai file từng lệch nhau âm thầm (F-D-06) — copy-framework phát bản shared-default, phiên chính dùng settings.json;
# lệch = dự án đích nhận hàng rào khác repo khung. Cổng: cmp byte-một-byte, không "gần giống".
# Dự án đích chỉ nhận settings.json (copy-framework phát bản shared-default DƯỚI TÊN settings.json) → không có gì để so.
if [ ! -f "$ROOT/.claude/settings-shared-default.json" ]; then
  ok "chỉ có settings.json (dự án đích) → bỏ qua phép so hai bản"
elif cmp -s "$ROOT/.claude/settings.json" "$ROOT/.claude/settings-shared-default.json"; then
  ok "settings.json == settings-shared-default.json"
else
  bad "settings.json ≠ settings-shared-default.json (sửa một file thì copy sang file kia)"
fi
if command -v jq >/dev/null 2>&1; then
  if jq -e '.enabledMcpjsonServers | index("context7")' "$ROOT/.claude/settings.json" >/dev/null 2>&1; then
    ok "enabledMcpjsonServers có context7"
  else
    bad "settings.json thiếu enabledMcpjsonServers: [\"context7\"] (F-M02: MCP tra tài liệu không bật ở đích)"
  fi
  if jq -e '.permissions.deny | index("Bash(git push -f*)")' "$ROOT/.claude/settings.json" >/dev/null 2>&1; then
    ok "deny có Bash(git push -f*)"
  else
    bad "deny thiếu Bash(git push -f*) (F-S07)"
  fi
  # NEGATIVE: hai file lệch tạm trong repo giả → phép cmp phải đỏ (không thì cổng xanh giả)
  neg="$WORK/settings-neg"; mkdir -p "$neg/.claude"
  printf '{"a":1}
' > "$neg/.claude/settings.json"; printf '{"a":2}
' > "$neg/.claude/settings-shared-default.json"
  if cmp -s "$neg/.claude/settings.json" "$neg/.claude/settings-shared-default.json"; then
    bad "negative: hai file lệch mà cmp vẫn xanh"
  else
    ok "negative: hai file lệch bị phát hiện"
  fi
fi

echo ""
if [ "$fails" -eq 0 ] && [ "$skips" -gt 0 ]; then
  echo "⚠️  $skips nhóm ca BỊ BỎ QUA vì máy thiếu jq — chưa chứng minh được cổng chặn."
  echo "OK (không có ca nào ĐỎ) — cài jq rồi chạy lại để có bằng chứng đầy đủ."
elif [ "$fails" -eq 0 ]; then
  echo "OK — hook cổng CHẶN thật + hook chặn lệnh git nguy hiểm hoạt động."
else
  echo "❌ $fails ca thất bại — cổng chặn commit KHÔNG hoạt động như tài liệu mô tả."
  exit 1
fi
