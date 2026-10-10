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
# Mục 17–19 (một nguồn mẫu bí mật, biến thể lọt bộ lọc, settings giống hệt) ở scripts/test-hooks-gate-guard.sh;
# fixture dùng chung (setup_project, run_hook, skip) ở scripts/_hooks-gate-test-lib.sh — tách 2026-10-10 (trần 400 dòng).
#
# Chạy: bash scripts/test-hooks-gate.sh
set -uo pipefail   # cố ý KHÔNG -e: không được làm chết phiên/lượt chạy (xem docs/CONVENTIONS.md §A)

# shellcheck source=scripts/_hooks-gate-test-lib.sh
source "$(dirname "$0")/_hooks-gate-test-lib.sh"

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

hooks_gate_finish "hook cổng CHẶN thật + hook chặn lệnh git nguy hiểm hoạt động." \
  "cổng chặn commit KHÔNG hoạt động như tài liệu mô tả."
