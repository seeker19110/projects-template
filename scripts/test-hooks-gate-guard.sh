#!/usr/bin/env bash
# test-hooks-gate-guard.sh — mục 17–19 của bộ test hook (tách khỏi scripts/test-hooks-gate.sh 2026-10-10, trần 400 dòng):
#   17: mẫu bí mật + ngưỡng file lớn MỘT nguồn (scripts/_commit-guard.sh), tiền tố nhà cung cấp, thiếu guard → chặn
#   18: biến thể lọt bộ lọc dữ liệu/nháy của block-dangerous-git + pre-commit-gate (TRAPS.md mục 62)
#   19: settings.json ↔ settings-shared-default.json giống hệt; MCP context7 + deny force-push
# Fixture dùng chung ở scripts/_hooks-gate-test-lib.sh. Phát sang dự án đích và chạy ở đó (test-copy-framework.sh).
#
# Chạy: bash scripts/test-hooks-gate-guard.sh
set -uo pipefail   # cố ý KHÔNG -e: không được làm chết phiên/lượt chạy (xem docs/CONVENTIONS.md §A)

# shellcheck source=scripts/_hooks-gate-test-lib.sh
source "$(dirname "$0")/_hooks-gate-test-lib.sh"

# Cùng fixture/hook như test-hooks-gate.sh (mục 1, 7, 11, 13 dựng chúng ở đó).
red="$(setup_project 1)"
green="$(setup_project 0)"
any="$(setup_project 0)"
DG="$ROOT/.claude/hooks/block-dangerous-git.sh"
GH="$ROOT/scripts/githooks/pre-commit"
fakekey="AKIA$(printf 'ABCDEFGHIJKLMNOP')"   # dựng lúc chạy: file test không tự chứa khoá giả nguyên khối

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
# Tiền tố nhà cung cấp mở rộng (F-S06): mỗi tiền tố một ca staged diff phải bị chặn. Mẫu DỰNG LÚC CHẠY bằng
# ghép mảnh + lặp ký tự — file test không chứa khoá giả nguyên khối (chính guard/gitleaks sẽ chặn file này).
rpt() { printf "%${2}s" "" | tr ' ' "$1"; }   # $1 ký tự, $2 số lần
guard_case() {   # $1 nhãn, $2 nội dung, $3 exit kỳ vọng (1 = chặn, 0 = cho qua)
  local p rc; p="$(setup_project 0)"; printf 'v=%s\n' "$2" > "$p/conf.txt"; git -C "$p" add conf.txt
  rc="$( cd "$p" && bash "$GH" >/dev/null 2>"$p/err.txt"; echo $? )"
  if [ "$3" = 1 ]; then
    [ "$rc" = 1 ] && grep -q 'khoá/token' "$p/err.txt" && ok "githooks: chặn $1 staged" || bad "githooks: LỌT $1 staged (exit $rc, kỳ vọng 1)"
  else
    [ "$rc" = 0 ] && ok "githooks: KHÔNG chặn oan $1 (exit 0)" || bad "githooks: chặn OAN $1 (exit $rc, kỳ vọng 0)"
  fi
}
guard_case "Anthropic sk-ant-"      "sk-""ant-api03-$(rpt a 24)" 1
for gp in o u s r; do guard_case "GitHub gh${gp}_" "gh${gp}""_$(rpt B 36)" 1; done
guard_case "Stripe sk_live_"        "sk""_live_$(rpt c 24)" 1
guard_case "Stripe rk_live_"        "rk""_live_$(rpt c 24)" 1
guard_case "JWT eyJ….eyJ…"          "ey""J$(rpt d 12).ey""J$(rpt e 12)" 1
guard_case "npm npm_"               "np""m_$(rpt F 36)" 1
guard_case "Slack webhook"          "https://hooks.sl""ack.com/services/T$(rpt G 8)/B$(rpt H 8)/$(rpt x 24)" 1
guard_case "SendGrid SG."           "S""G.$(rpt i 22).$(rpt j 43)" 1
guard_case "Hugging Face hf_"       "h""f_$(rpt K 34)" 1
guard_case "DigitalOcean dop_v1_"   "dop""_v1_$(rpt f 64)" 1
guard_case "Azure AccountKey="      "Account""Key=$(rpt L 44)" 1
guard_case "chuỗi sk-ant- ngắn (đối chứng)" "sk-""ant-short" 0
# Vòng 2 (rà bảo mật): tiền tố ngắn neo trái — từ thường chứa tiền tố ở giữa không bị chặn oan.
guard_case "từ thường task-ant-… (đối chứng neo trái)" "tas""k-ant-colony-optimization-scheduler" 0
guard_case "từ thường task_live_… (đối chứng neo trái)" "tas""k_live_$(rpt m 20)" 0
guard_case "OpenAI sk-proj-"         "sk-""proj-$(rpt n 24)" 1
# Dòng NỘI DUNG bắt đầu bằng '+' thành '++…' trong diff — bộ lọc cũ '^\+[^+]' bỏ sót.
pp="$(setup_project 0)"; printf '++%s\n' "$fakekey" > "$pp/plus.txt"; git -C "$pp" add plus.txt
rc="$( cd "$pp" && bash "$GH" >/dev/null 2>&1; echo $? )"
[ "$rc" = "1" ] && ok "githooks: chặn bí mật trên dòng bắt đầu bằng '+'" || bad "githooks: LỌT bí mật trên dòng bắt đầu bằng '+' (exit $rc, kỳ vọng 1)"
if [ "$HAS_JQ" = "0" ]; then skip "mục 17 — pre-commit-gate dòng bắt đầu bằng '+'"; else
rc="$(run_hook "$pp" 'git commit -m "x"')"
[ "$rc" = "2" ] && ok "pre-commit-gate: chặn bí mật trên dòng bắt đầu bằng '+'" || bad "pre-commit-gate: LỌT bí mật trên dòng bắt đầu bằng '+' (exit $rc, kỳ vọng 2)"
fi
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

hooks_gate_finish "một nguồn mẫu bí mật + bộ lọc hook không lọt biến thể + settings đồng bộ." \
  "hàng rào commit/git KHÔNG hoạt động như tài liệu mô tả."
