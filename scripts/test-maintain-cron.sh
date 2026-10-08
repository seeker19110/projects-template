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
fails=0  # ShellCheck không theo được source qua $ROOT; giữ biến đếm tường minh.

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
GIT=(git -c user.name=t -c user.email=t@example.com -c commit.gpgsign=false -c init.defaultBranch=main)

# ── Dựng remote giả (bare) + checkout làm việc ───────────────────────────────
REMOTE="$TMP/remote.git"; "${GIT[@]}" init -q --bare "$REMOTE"
WORK="$TMP/work"; mkdir -p "$WORK/scripts" "$WORK/.claude/agents"
( cd "$WORK" && "${GIT[@]}" init -q && "${GIT[@]}" remote add origin "$REMOTE" )
cp "$ROOT"/scripts/{maintain-cron.sh,maintain-run.sh,maintenance-sweep.sh,subagent-dispatch.sh,subagent-dispatch.py,_python-exec.sh,_commit-guard.sh} "$WORK/scripts/"
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

echo
if [ "$fails" -eq 0 ]; then echo "OK — maintain-cron.sh chỉ đẩy nhánh maint/auto-*, không đụng main, chặn đúng working tree bẩn + chạy chồng, tự mở/tránh trùng PR đúng qua GitHub REST API."; else echo "FAIL — $fails kiểm hỏng."; fi
exit "$fails"
