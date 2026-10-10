#!/usr/bin/env bash
# test-maintain-cron.sh — Self-test cho wrapper không giám sát `scripts/maintain-cron.sh`.
#
# Dựng một remote GIẢ (bare repo cục bộ, không đụng mạng thật) + một checkout, dùng CLI GIẢ
# (stub) để "maintainer" luôn trả về một MAINTENANCE-PLAN.md xác định, rồi chứng minh: (1) hàng
# rào cứng thật sự chặn (working tree bẩn, khoá tiến trình, không đụng main), (2) chạy sạch thì
# đẩy đúng MỘT nhánh maint/auto-<ngày> lên remote giả, KHÔNG bao giờ lên nhánh chính, (3) chạy lại
# lần hai trong cùng ngày ghi đè nhánh đó chứ không cộng dồn, (4) --no-push không đụng remote.
#
# Chạy: bash scripts/test-maintain-cron.sh
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT/scripts/_test-lib.sh"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
GIT=(git -c user.name=t -c user.email=t@example.com -c commit.gpgsign=false -c init.defaultBranch=main)

# ── Dựng remote giả (bare) + checkout làm việc ───────────────────────────────
REMOTE="$TMP/remote.git"; "${GIT[@]}" init -q --bare "$REMOTE"
WORK="$TMP/work"; mkdir -p "$WORK/scripts" "$WORK/.claude/agents"
( cd "$WORK" && "${GIT[@]}" init -q && "${GIT[@]}" remote add origin "$REMOTE" )
cp "$ROOT"/scripts/{maintain-cron.sh,maintain-run.sh,maintenance-sweep.sh,subagent-dispatch.sh,subagent-dispatch.py,_python-exec.sh,_stack-detect.sh,_commit-guard.sh} "$WORK/scripts/"
cp "$ROOT/.claude/agents/maintainer.md" "$WORK/.claude/agents/"
printf '# PROGRESS\n- Ngày cập nhật: %s\n' "$(date +%Y-%m-%d)" > "$WORK/PROGRESS.md"
( cd "$WORK" && "${GIT[@]}" add -A && "${GIT[@]}" commit -qm init && "${GIT[@]}" push -q -u origin HEAD:main )
( cd "$WORK" && git symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/main )

# Stub "claude" CLI: đọc prompt qua stdin, GHI SẴN một MAINTENANCE-PLAN.md xác định vào cwd
# (đúng hành vi thật của agent maintainer khi triage xong), rồi thoát 0. Không gọi mạng/LLM thật.
mk_stub_claude() {
  cat > "$TMP/claude" <<'EOF'
#!/usr/bin/env bash
cat > /dev/null   # đọc hết stdin (prompt) như CLI thật
mkdir -p docs/ops
printf '# Kế hoạch bảo trì — stub\nNguồn: docs/ops/MAINTENANCE-REPORT.md · Trạng thái: CHỜ DUYỆT\n\n| ID | Mức |\n| --- | --- |\n| M-01 | 🟡 |\n' > docs/ops/MAINTENANCE-PLAN.md
exit 0
EOF
  chmod +x "$TMP/claude"
}
mk_stub_claude
export MAINT_BIN_CLAUDE="$TMP/claude"
export CLAUDE_PROJECT_DIR="$WORK"

run() { ( cd "$WORK" && bash scripts/maintain-cron.sh "$@" ); }

echo "== 1. --help thoát 0 =="
run --help >/dev/null 2>&1 && ok "--help thoát 0" || bad "--help lỗi"

echo "== 2. Working tree bẩn → CHẶN, không commit/push gì =="
touch "$WORK/scratch.txt"
run --harness claude --mode quick >"$TMP/o2" 2>&1; rc=$?
[ "$rc" -eq 5 ] && ok "working tree bẩn → thoát 5" || bad "working tree bẩn không bị chặn (rc=$rc): $(cat "$TMP/o2")"
rm -f "$WORK/scratch.txt"
[ "$(git -C "$REMOTE" branch --list 'maint/*' | wc -l | tr -d ' ')" = 0 ] && ok "remote chưa có nhánh maint/* nào (đúng — bị chặn trước khi đụng git)" || bad "remote đã có nhánh dù bị chặn"

echo "== 3. Chạy sạch → đẩy ĐÚNG một nhánh maint/auto-<ngày>, KHÔNG đụng main =="
main_before="$(git -C "$REMOTE" rev-parse main)"
run --harness claude --mode quick >"$TMP/o3" 2>&1; rc=$?
[ "$rc" -eq 0 ] && ok "chạy sạch thoát 0" || bad "chạy sạch thoát $rc: $(cat "$TMP/o3")"
today="$(date -u +%Y-%m-%d)"
branch="maint/auto-$today"
git -C "$REMOTE" show-ref -q --verify "refs/heads/$branch" && ok "remote CÓ nhánh $branch" || bad "remote KHÔNG có $branch: $(git -C "$REMOTE" branch --list)"
main_after="$(git -C "$REMOTE" rev-parse main)"
[ "$main_before" = "$main_after" ] && ok "nhánh main trên remote KHÔNG đổi (không bị push thẳng)" || bad "main đã bị đổi! $main_before -> $main_after"
git -C "$REMOTE" show "$branch:docs/ops/MAINTENANCE-PLAN.md" 2>/dev/null | grep -q "Kế hoạch bảo trì" && ok "nhánh $branch chứa MAINTENANCE-PLAN.md" || bad "nhánh $branch thiếu MAINTENANCE-PLAN.md"
git -C "$WORK" branch --show-current | grep -qx "$(git -C "$REMOTE" symbolic-ref --short HEAD 2>/dev/null || echo main)" \
  && ok "checkout cục bộ quay lại nhánh nền sau khi đẩy" || bad "checkout cục bộ không quay lại nhánh nền"

echo "== 4. Chạy lại LẦN HAI cùng ngày → ghi đè nhánh cũ, KHÔNG cộng dồn commit =="
n1="$(git -C "$REMOTE" rev-list --count "$branch")"
run --harness claude --mode quick >"$TMP/o4" 2>&1; rc=$?
[ "$rc" -eq 0 ] && ok "chạy lại lần 2 thoát 0" || bad "chạy lại lần 2 lỗi: $(cat "$TMP/o4")"
n2="$(git -C "$REMOTE" rev-list --count "$branch")"
[ "$n1" = "$n2" ] && ok "số commit trên $branch không tăng (reset --hard về base, không cộng dồn): $n2" || bad "commit cộng dồn: $n1 -> $n2"

echo "== 5. --no-push: commit cục bộ nhưng KHÔNG đẩy lên remote =="
git -C "$REMOTE" branch -D "$branch" >/dev/null 2>&1
run --harness claude --mode quick --no-push >"$TMP/o5" 2>&1; rc=$?
[ "$rc" -eq 0 ] && ok "--no-push thoát 0" || bad "--no-push lỗi: $(cat "$TMP/o5")"
git -C "$REMOTE" show-ref -q --verify "refs/heads/$branch" && bad "--no-push mà remote vẫn có nhánh $branch" || ok "--no-push: remote không nhận nhánh mới"
git -C "$WORK" show-ref -q --verify "refs/heads/$branch" && ok "--no-push: commit vẫn nằm cục bộ trên $branch" || bad "--no-push: không thấy commit cục bộ"

echo "== 6. Hai lượt CHỒNG NHAU (khoá tiến trình) → lượt sau bị chặn =="
LOCKD="$TMP/lockdir"; mkdir -p "$LOCKD"
HELD_MARK="$TMP/holder.held"
# Holder GHI MARKER ngay sau khi giữ được khoá — chờ marker thay vì `sleep` cố định (tránh flaky
# dưới tải máy nặng: một sleep ngắn cố định không đảm bảo holder đã thật sự cầm khoá kịp lúc).
mk_holder() { cat > "$TMP/holder.sh" <<EOF
#!/usr/bin/env bash
mkdir -p "$LOCKD"
if command -v flock >/dev/null 2>&1; then
  exec 9>"$LOCKD/.maintain-cron.lock"; flock 9; touch "$HELD_MARK"; sleep 5
else
  echo \$\$ > "$LOCKD/.maintain-cron.lock"; touch "$HELD_MARK"; sleep 5
fi
EOF
chmod +x "$TMP/holder.sh"; }
mk_holder
rm -f "$HELD_MARK"
bash "$TMP/holder.sh" & holder_pid=$!
waited=0
while [ ! -f "$HELD_MARK" ] && [ "$waited" -lt 50 ]; do sleep 0.1; waited=$((waited+1)); done
[ -f "$HELD_MARK" ] || bad "holder không kịp giữ khoá trong 5s (môi trường quá tải?)"
( cd "$WORK" && bash scripts/maintain-cron.sh --harness claude --mode quick --lock-dir "$LOCKD" >"$TMP/o6" 2>&1 ); rc=$?
wait "$holder_pid" 2>/dev/null
if command -v flock >/dev/null 2>&1; then
  [ "$rc" -eq 4 ] && ok "lượt chồng lên nhau bị chặn bởi khoá (rc=4)" || bad "khoá không chặn được lượt chồng nhau (rc=$rc): $(cat "$TMP/o6")"
else
  echo "  ⏭️  không có flock trên máy này — bỏ qua kiểm khoá bằng flock (fallback PID vẫn được các kiểm khác phủ gián tiếp)"
fi

echo "== 7. Tự mở PR (GitHub REST API qua curl GIẢ — không đụng mạng thật) =="
STUB_LOG="$TMP/curl.log"
mk_stub_curl() { # $1=STUB_EXISTING(0/1) $2=STUB_CODE_GET(mặc định 200) $3=STUB_CODE_POST(mặc định 201)
  cat > "$TMP/curl" <<EOF
#!/usr/bin/env bash
printf '%s\n' "\$*" >> "$STUB_LOG"
out_file=""; prev=""; is_post=0
for a in "\$@"; do
  [ "\$prev" = "-o" ] && out_file="\$a"
  [ "\$prev" = "-X" ] && [ "\$a" = "POST" ] && is_post=1
  # Header nạp từ file (-H @path): chụp nội dung + đường dẫn để test kiểm token đi qua FILE, không argv.
  case "\$prev:\$a" in -H:@*) cat "\${a#@}" > "$TMP/hdr.seen" 2>/dev/null; printf '%s' "\${a#@}" > "$TMP/hdr.path" ;; esac
  prev="\$a"
done
url="\${@: -1}"
if [ "\$is_post" = 1 ]; then
  printf '{"html_url":"https://github.com/fakeowner/fakerepo/pull/42","number":42}' > "\$out_file"
  printf '${3:-201}'
else
  case "\$url" in
    *"/pulls?"*)
      if [ "${1:-0}" = "1" ]; then printf '[{"html_url":"https://github.com/fakeowner/fakerepo/pull/7","number":7}]' > "\$out_file"; else printf '[]' > "\$out_file"; fi
      printf '${2:-200}'
      ;;
    *) printf '{}' > "\$out_file"; printf '500' ;;
  esac
fi
EOF
  chmod +x "$TMP/curl"
}
git -C "$REMOTE" branch -D "maint/auto-$today" >/dev/null 2>&1
# Xoá remote-tracking ref CỤC BỘ tương ứng — nếu không, --force-with-lease trong maintain-cron.sh
# (đúng như thiết kế) sẽ từ chối push vì so lease với giá trị CŨ còn sót từ trước khi ta xoá nhánh
# thẳng tay trên remote giả (một thao tác chỉ test này làm, script thật không bao giờ làm vậy).
git -C "$WORK" update-ref -d "refs/remotes/origin/maint/auto-$today" 2>/dev/null || true
REPO_ARGS=(--repo fakeowner/fakerepo)   # --repo bỏ qua việc parse origin (origin trỏ tới bare repo cục bộ, không phải github.com)

echo "-- 7a. Không có token → bỏ qua tự mở PR, không gọi curl --"
rm -f "$STUB_LOG"; mk_stub_curl 0
unset GITHUB_TOKEN GH_TOKEN
out7a="$( ( cd "$WORK" && MAINT_BIN_CURL="$TMP/curl" bash scripts/maintain-cron.sh --harness claude --mode quick "${REPO_ARGS[@]}" ) 2>&1 )"; rc=$?
[ "$rc" -eq 0 ] && ok "không token: runner vẫn thoát 0" || bad "không token: thoát $rc"
printf '%s' "$out7a" | grep -q "không có GITHUB_TOKEN" && ok "không token: log rõ lý do bỏ qua" || bad "không token: thiếu log giải thích"
[ ! -s "$STUB_LOG" ] && ok "không token: KHÔNG gọi curl lần nào" || bad "không token: vẫn gọi curl: $(cat "$STUB_LOG")"

echo "-- 7b. --no-open-pr dù CÓ token → vẫn bỏ qua, không gọi curl --"
rm -f "$STUB_LOG"; mk_stub_curl 0
out7b="$( ( cd "$WORK" && GITHUB_TOKEN=fake-tok MAINT_BIN_CURL="$TMP/curl" bash scripts/maintain-cron.sh --harness claude --mode quick --no-open-pr "${REPO_ARGS[@]}" ) 2>&1 )"; rc=$?
[ "$rc" -eq 0 ] && ok "--no-open-pr: thoát 0" || bad "--no-open-pr: thoát $rc"
printf '%s' "$out7b" | grep -q -- "--no-open-pr: bỏ qua" && ok "--no-open-pr: log đúng lý do" || bad "--no-open-pr: thiếu log"
[ ! -s "$STUB_LOG" ] && ok "--no-open-pr: KHÔNG gọi curl" || bad "--no-open-pr: vẫn gọi curl"

echo "-- 7c. Có token, chưa có PR mở → TẠO MỚI qua POST, log đúng URL --"
rm -f "$STUB_LOG"; mk_stub_curl 0
out7c="$( ( cd "$WORK" && GITHUB_TOKEN=fake-tok MAINT_BIN_CURL="$TMP/curl" bash scripts/maintain-cron.sh --harness claude --mode quick "${REPO_ARGS[@]}" ) 2>&1 )"; rc=$?
[ "$rc" -eq 0 ] && ok "7c: thoát 0" || bad "7c: thoát $rc: $out7c"
[ "$(grep -cv -- '-X POST' "$STUB_LOG" 2>/dev/null || echo 0)" -ge 1 ] && ok "7c: có gọi kiểm tra PR đang mở trước (GET)" || bad "7c: không thấy lượt GET kiểm tra trước"
grep -q -- "-X POST" "$STUB_LOG" && ok "7c: có gọi POST tạo PR" || bad "7c: không thấy POST: $(cat "$STUB_LOG" 2>/dev/null)"
printf '%s' "$out7c" | grep -q "Đã mở PR báo cáo cho chủ dự án: https://github.com/fakeowner/fakerepo/pull/42" && ok "7c: log đúng URL PR vừa tạo" || bad "7c: thiếu/sai log URL: $out7c"

echo "-- 7d. Có token, ĐÃ có PR mở cho đúng nhánh → KHÔNG tạo trùng --"
rm -f "$STUB_LOG"; mk_stub_curl 1
out7d="$( ( cd "$WORK" && GITHUB_TOKEN=fake-tok MAINT_BIN_CURL="$TMP/curl" bash scripts/maintain-cron.sh --harness claude --mode quick "${REPO_ARGS[@]}" ) 2>&1 )"; rc=$?
[ "$rc" -eq 0 ] && ok "7d: thoát 0" || bad "7d: thoát $rc"
grep -q -- "-X POST" "$STUB_LOG" && bad "7d: vẫn gọi POST dù PR đã tồn tại (tạo trùng!)" || ok "7d: KHÔNG gọi POST — tránh PR trùng"
printf '%s' "$out7d" | grep -q "PR đã mở sẵn cho maint/auto-$today — không tạo trùng: https://github.com/fakeowner/fakerepo/pull/7" && ok "7d: log đúng URL PR đã có" || bad "7d: thiếu/sai log: $out7d"

echo "-- 7e. HTTP lỗi khi tạo (500) → log rõ, KHÔNG coi là lỗi chặn toàn bộ script --"
rm -f "$STUB_LOG"; mk_stub_curl 0 200 500
out7e="$( ( cd "$WORK" && GITHUB_TOKEN=fake-tok MAINT_BIN_CURL="$TMP/curl" bash scripts/maintain-cron.sh --harness claude --mode quick "${REPO_ARGS[@]}" ) 2>&1 )"; rc=$?
[ "$rc" -eq 0 ] && ok "7e: HTTP 500 khi tạo PR vẫn không làm script thoát khác 0" || bad "7e: thoát $rc"
printf '%s' "$out7e" | grep -q "mở PR thất bại (HTTP 500)" && ok "7e: log rõ HTTP 500" || bad "7e: thiếu log lỗi HTTP"

echo "-- 7f. Token KHÔNG vào argv của curl (đọc được qua ps) — header đi qua file tạm -H @file --"
rm -f "$STUB_LOG" "$TMP/hdr.seen" "$TMP/hdr.path"; mk_stub_curl 0
TOK7F="fake-tok-argv-probe-7f"
out7f="$( ( cd "$WORK" && GITHUB_TOKEN="$TOK7F" MAINT_BIN_CURL="$TMP/curl" bash scripts/maintain-cron.sh --harness claude --mode quick "${REPO_ARGS[@]}" ) 2>&1 )"; rc=$?
[ "$rc" -eq 0 ] && ok "7f: thoát 0" || bad "7f: thoát $rc: $out7f"
[ -s "$STUB_LOG" ] || bad "7f: curl giả không được gọi — không kiểm được argv"
grep -q "Authorization" "$STUB_LOG" && bad "7f: argv curl CHỨA 'Authorization' (lộ qua ps): $(cat "$STUB_LOG")" || ok "7f: argv curl không chứa 'Authorization'"
grep -qF "$TOK7F" "$STUB_LOG" && bad "7f: argv curl CHỨA token" || ok "7f: argv curl không chứa token"
grep -q -- "-H @" "$STUB_LOG" && ok "7f: header nạp từ file (-H @…)" || bad "7f: không thấy '-H @' trong argv curl: $(cat "$STUB_LOG" 2>/dev/null)"
grep -qxF "Authorization: Bearer $TOK7F" "$TMP/hdr.seen" 2>/dev/null && ok "7f: file header mang đúng Authorization" || bad "7f: file header thiếu/sai Authorization"
hdr_path="$(cat "$TMP/hdr.path" 2>/dev/null)"
[ -n "$hdr_path" ] && [ ! -e "$hdr_path" ] && ok "7f: file header tạm đã bị xoá sau khi chạy" || bad "7f: file header tạm còn sót: ${hdr_path:-<không ghi nhận>}"
case "$hdr_path" in
  */.git/maintain-cron/*) ok "7f: file header tạm nằm trong thư mục khoá 0700 (không ở /tmp chung)" ;;
  *) bad "7f: file header tạm nằm ngoài thư mục khoá: ${hdr_path:-<không ghi nhận>}" ;;
esac
printf '%s' "$out7f" | grep -qF "$TOK7F" && bad "7f: token lọt ra log" || ok "7f: token không lọt ra log"

echo "== 8. Khoá: không theo symlink, mặc định nằm trong .git =="
[ -d "$WORK/.git/maintain-cron" ] && ok "8a: khoá mặc định ở .git/maintain-cron (ngoài working tree, không ở /tmp dùng chung)" || bad "8a: không thấy thư mục khoá mặc định $WORK/.git/maintain-cron"
LOCKS="$TMP/lock-sym"; VICTIM="$TMP/victim.txt"; mkdir -p "$LOCKS"; printf 'giu-nguyen\n' > "$VICTIM"
# Git Bash mặc định `ln -s` CHÉP file; nativestrict tạo symlink thật (cần Developer Mode) — không tạo được thì bỏ qua.
MSYS=winsymlinks:nativestrict ln -s "$VICTIM" "$LOCKS/.maintain-cron.lock" 2>/dev/null
if [ -L "$LOCKS/.maintain-cron.lock" ]; then
  ( cd "$WORK" && bash scripts/maintain-cron.sh --harness claude --mode quick --no-push --lock-dir "$LOCKS" >"$TMP/o8b" 2>&1 ); rc=$?
  [ "$rc" -ne 0 ] && ok "8b: file khoá là symlink → thoát ≠ 0 (rc=$rc)" || bad "8b: file khoá là symlink mà vẫn chạy (rc=0)"
  grep -q "symlink" "$TMP/o8b" && ok "8b: thông báo rõ lý do (symlink)" || bad "8b: thiếu thông báo symlink: $(cat "$TMP/o8b")"
  [ "$(cat "$VICTIM")" = "giu-nguyen" ] && ok "8b: file đích của symlink không bị ghi đè" || bad "8b: file đích bị ghi đè: $(cat "$VICTIM")"
else
  echo "  ⏭️  không tạo được symlink thật trên máy này — bỏ qua 8b"
fi
LOCKL="$TMP/lock-dirlink"; mkdir -p "$TMP/lock-real"
MSYS=winsymlinks:nativestrict ln -s "$TMP/lock-real" "$LOCKL" 2>/dev/null
if [ -L "$LOCKL" ]; then
  ( cd "$WORK" && bash scripts/maintain-cron.sh --harness claude --mode quick --no-push --lock-dir "$LOCKL" >"$TMP/o8c" 2>&1 ); rc=$?
  [ "$rc" -ne 0 ] && grep -q "symlink" "$TMP/o8c" && ok "8c: thư mục khoá là symlink → từ chối (rc=$rc)" || bad "8c: thư mục khoá symlink không bị từ chối (rc=$rc): $(cat "$TMP/o8c")"
else
  echo "  ⏭️  không tạo được symlink thư mục thật — bỏ qua 8c"
fi

echo "== 9. --gh-token-file: cảnh báo quyền file lỏng, file thiếu → dừng =="
TOKF="$TMP/tok.txt"; printf 'fake-tok-file-9\n' > "$TOKF"
file_mode() { stat -c %a "$1" 2>/dev/null || stat -f %Lp "$1" 2>/dev/null; }
chmod 644 "$TOKF"
( cd "$WORK" && bash scripts/maintain-cron.sh --harness claude --mode quick --no-push --gh-token-file "$TOKF" >"$TMP/o9a" 2>&1 ); rc=$?
[ "$rc" -eq 0 ] && ok "9a: quyền lỏng chỉ cảnh báo, không chặn (rc=0)" || bad "9a: thoát $rc: $(cat "$TMP/o9a")"
grep -q "quyền file token" "$TMP/o9a" && ok "9a: có cảnh báo quyền file token (mode $(file_mode "$TOKF"))" || bad "9a: thiếu cảnh báo quyền file token: $(cat "$TMP/o9a")"
chmod 600 "$TOKF"
if [ "$(file_mode "$TOKF")" = 600 ]; then
  ( cd "$WORK" && bash scripts/maintain-cron.sh --harness claude --mode quick --no-push --gh-token-file "$TOKF" >"$TMP/o9b" 2>&1 )
  grep -q "quyền file token" "$TMP/o9b" && bad "9b: mode 600 vẫn bị cảnh báo" || ok "9b: mode 600 không cảnh báo"
else
  echo "  ⏭️  chmod 600 không đổi được mode đọc lại (vd Windows/NTFS) — bỏ qua 9b"
fi
( cd "$WORK" && bash scripts/maintain-cron.sh --harness claude --mode quick --no-push --gh-token-file "$TMP/khong-co.txt" >"$TMP/o9c" 2>&1 ); rc=$?
[ "$rc" -eq 2 ] && ok "9c: file token không đọc được → thoát 2" || bad "9c: file token thiếu mà thoát $rc: $(cat "$TMP/o9c")"

echo "== 10. Tiến trình con (maintain-run/CLI AI) không nhận token qua env, không giữ fd khoá =="
# CLI AI giả ghi env + trạng thái fd 9 của chính nó. `flock` giả (luôn giành được khoá) để nhánh
# `exec 9>` chạy cả trên máy không có flock (Git Bash/macOS) — đo được fd 9 có rò vào con không.
cat > "$TMP/claude-probe" <<EOF
#!/usr/bin/env bash
cat > /dev/null
env > "$TMP/child.env"
if { : >&9; } 2>/dev/null; then echo open > "$TMP/child.fd9"; else echo closed > "$TMP/child.fd9"; fi
exit 0
EOF
chmod +x "$TMP/claude-probe"
mkdir -p "$TMP/fakeflock"; printf '#!/usr/bin/env bash\nexit 0\n' > "$TMP/fakeflock/flock"; chmod +x "$TMP/fakeflock/flock"
TOK10A="fake-tok-env-probe-10a"; TOK10B="fake-tok-env-probe-10b"
rm -f "$TMP/child.env" "$TMP/child.fd9"
( cd "$WORK" && PATH="$TMP/fakeflock:$PATH" MAINT_BIN_CLAUDE="$TMP/claude-probe" GITHUB_TOKEN="$TOK10A" GH_TOKEN="$TOK10B" \
    bash scripts/maintain-cron.sh --harness claude --mode quick --no-push >"$TMP/o10" 2>&1 ); rc=$?
if [ -s "$TMP/child.env" ]; then
  grep -qF -e "$TOK10A" -e "$TOK10B" "$TMP/child.env" && bad "10a: CLI AI con thấy token trong env" || ok "10a: env của CLI AI con không chứa GITHUB_TOKEN/GH_TOKEN"
else
  bad "10a: CLI AI giả không được gọi (rc=$rc): $(cat "$TMP/o10")"
fi
[ "$(cat "$TMP/child.fd9" 2>/dev/null)" = closed ] && ok "10b: tiến trình con không giữ fd 9 (khoá flock)" || bad "10b: fd 9 (khoá) rò vào tiến trình con: $(cat "$TMP/child.fd9" 2>/dev/null)"

echo "== 11. origin có userinfo (token trong URL) → token không vào argv/log, owner/repo đúng =="
TOK11="fake-tok-url-probe-11"
CRED_URL="https://x-access-token:${TOK11}@github.com/o/r.git"
BAD_URL="https://github.com/o/r/extra.git"
# insteadOf chuyển fetch/push về remote giả cục bộ; cấu hình origin vẫn mang URL có credential.
git -C "$WORK" remote set-url origin "$CRED_URL"
git -C "$WORK" config "url.$REMOTE.insteadOf" "$CRED_URL"
rm -f "$STUB_LOG"; mk_stub_curl 0
out11="$( ( cd "$WORK" && GITHUB_TOKEN=fake-tok MAINT_BIN_CURL="$TMP/curl" bash scripts/maintain-cron.sh --harness claude --mode quick ) 2>&1 )"; rc=$?
[ "$rc" -eq 0 ] && ok "11a: thoát 0" || bad "11a: thoát $rc: $out11"
grep -qF "$TOK11" "$STUB_LOG" 2>/dev/null && bad "11a: argv curl chứa token từ URL origin: $(cat "$STUB_LOG")" || ok "11a: argv curl không chứa token từ URL origin"
printf '%s' "$out11" | grep -qF "$TOK11" && bad "11a: log chứa token từ URL origin" || ok "11a: log không chứa token từ URL origin"
grep -q "/repos/o/r/pulls" "$STUB_LOG" 2>/dev/null && ok "11a: owner/repo tách đúng 'o/r'" || bad "11a: owner/repo sai: $(cat "$STUB_LOG" 2>/dev/null)"
git -C "$WORK" config --unset "url.$REMOTE.insteadOf"
git -C "$WORK" remote set-url origin "$BAD_URL"
git -C "$WORK" config "url.$REMOTE.insteadOf" "$BAD_URL"
rm -f "$STUB_LOG"; mk_stub_curl 0
out11b="$( ( cd "$WORK" && GITHUB_TOKEN=fake-tok MAINT_BIN_CURL="$TMP/curl" bash scripts/maintain-cron.sh --harness claude --mode quick ) 2>&1 )"; rc=$?
[ "$rc" -eq 0 ] && ok "11b: thoát 0" || bad "11b: thoát $rc: $out11b"
[ ! -s "$STUB_LOG" ] && ok "11b: owner/repo không hợp lệ → KHÔNG gọi curl" || bad "11b: vẫn gọi curl với owner/repo lạ: $(cat "$STUB_LOG")"
printf '%s' "$out11b" | grep -q "owner/repo không hợp lệ" && ok "11b: log rõ lý do bỏ qua" || bad "11b: thiếu log bỏ qua: $out11b"
git -C "$WORK" config --unset "url.$REMOTE.insteadOf"
git -C "$WORK" remote set-url origin "$REMOTE"

echo "== 12. bash -x không in token =="
TOK12="fake-tok-xtrace-probe-12"
rm -f "$STUB_LOG"; mk_stub_curl 0
out12="$( ( cd "$WORK" && GITHUB_TOKEN="$TOK12" MAINT_BIN_CURL="$TMP/curl" bash -x scripts/maintain-cron.sh --harness claude --mode quick "${REPO_ARGS[@]}" ) 2>&1 )"; rc=$?
[ "$rc" -eq 0 ] && ok "12: thoát 0 dưới bash -x" || bad "12: thoát $rc"
printf '%s' "$out12" | grep -qF "$TOK12" && bad "12: xtrace in token: $(printf '%s' "$out12" | grep -F "$TOK12" | head -3)" || ok "12: xtrace không in token"

echo "== 13. Thư mục khoá cho group/other ghi → từ chối =="
# `stat` giả báo 777 — kiểm nhánh logic trên mọi máy (Windows/NTFS luôn báo 755 nên chmod thật không đo được).
mkdir -p "$TMP/fakestat" "$TMP/lock-ww"
printf '#!/usr/bin/env bash\necho 777\n' > "$TMP/fakestat/stat"; chmod +x "$TMP/fakestat/stat"
( cd "$WORK" && PATH="$TMP/fakestat:$PATH" bash scripts/maintain-cron.sh --harness claude --mode quick --no-push --lock-dir "$TMP/lock-ww" >"$TMP/o13a" 2>&1 ); rc=$?
[ "$rc" -eq 10 ] && grep -q "group/other" "$TMP/o13a" && ok "13a: mode 777 (stat giả) → thoát 10 kèm lý do" || bad "13a: thư mục khoá ghi-được-bởi-người-khác không bị từ chối (rc=$rc): $(head -3 "$TMP/o13a")"
chmod g+w,o+w "$TMP/lock-ww" 2>/dev/null
case "$(file_mode "$TMP/lock-ww")" in
  *[2367][0-7]|*[2367]) ( cd "$WORK" && bash scripts/maintain-cron.sh --harness claude --mode quick --no-push --lock-dir "$TMP/lock-ww" >"$TMP/o13b" 2>&1 ); rc=$?
    [ "$rc" -eq 10 ] && ok "13b: chmod g+w,o+w thật → thoát 10" || bad "13b: chmod g+w,o+w thật mà không bị từ chối (rc=$rc)" ;;
  *) echo "  ⏭️  chmod g+w,o+w không đổi được mode đọc lại (vd Windows/NTFS) — bỏ qua 13b" ;;
esac

echo
finish "maintain-cron.sh chỉ đẩy nhánh maint/auto-*, không đụng main, chặn đúng working tree bẩn + chạy chồng, tự mở/tránh trùng PR đúng qua GitHub REST API."
