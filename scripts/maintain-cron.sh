#!/usr/bin/env bash
# maintain-cron.sh — Wrapper KHÔNG GIÁM SÁT (VPS/cron/systemd timer) cho `maintain-run.sh`.
#
# Vì sao tồn tại: `maintain-run.sh` chỉ ghi vào 3 file cục bộ (docs/ops/MAINTENANCE-*.md) và
# in ra stdout — không ai đọc được nếu chạy trên một VPS không ai mở máy. Wrapper này thêm ĐÚNG
# MỘT việc mới: đồng bộ với remote rồi ĐẨY kế hoạch/báo cáo lên một NHÁNH RIÊNG để bạn duyệt qua
# PR như bình thường — không đụng `main`, không tự merge, không tự sửa source code (CLAUDE.md §9:
# thao tác ghi không giám sát phải có hàng rào cứng, không chỉ lời hứa trong prompt).
#
# HÀNG RÀO CỨNG (không phải tùy chọn, không có cờ nào tắt được):
#   1) KHÔNG BAO GIỜ commit/push thẳng vào nhánh mặc định (main/master) — luôn qua nhánh riêng
#      `maint/auto-<ngày>` (mỗi ngày một nhánh mới, không ghi đè lịch sử nhánh cũ).
#   2) KHÔNG BAO GIỜ `git push --force`/`-f` (không điều kiện) hay push force vào bất cứ gì khác
#      ngoài `maint/auto-<ngày>`. CHỈ dùng `--force-with-lease` (an toàn hơn — bị remote từ chối
#      nếu ai đó vừa đẩy lên đúng nhánh đó sau lượt fetch gần nhất) và CHỈ nhắm vào nhánh do chính
#      agent này tạo/sở hữu, không bao giờ cho `$BASE`/main. KHÔNG `git reset --hard`/`git clean -f*`
#      khi có thay đổi khác đang dở (kiểm working tree TRƯỚC khi chạy, dừng nếu bẩn).
#   3) CHỈ `git add` đúng 3 file docs/ops/MAINTENANCE-*.md — không `git add -A`/`git add .`, để
#      một thay đổi bất thường khác trên VPS không lỡ bị cuốn theo commit tự động.
#   4) Khoá tiến trình (flock nếu có, else file khoá + PID) — hai lần cron chồng nhau (job trước
#      chạy lâu hơn interval) không được chạy song song trên cùng một checkout.
#   5) Không bao giờ echo/log nội dung file bí mật; không truyền gì qua `eval`.
#
# BÁO CÁO CHO CHỦ DỰ ÁN: sau khi đẩy nhánh, script TỰ MỞ MỘT PULL REQUEST qua GitHub REST API
# (không cần cài `gh` CLI — chỉ `curl` + `jq`/`python3` để parse JSON) nếu có token trong biến môi
# trường GITHUB_TOKEN/GH_TOKEN (hoặc --gh-token). Đây là kênh báo chính: bạn nhận thông báo PR mới
# giống hệt mọi PR khác trên GitHub (email/app tuỳ bạn bật ở Settings › Notifications). KHÔNG có
# token → tự động bỏ qua bước mở PR (chỉ log, không coi là lỗi) — nhánh vẫn đã nằm trên remote,
# bạn tự mở PR tay được. Chạy lại cùng ngày → KHÔNG mở PR trùng (tìm PR đang mở cho nhánh trước).
# Token chỉ cần quyền `pull_request: write` (contents: write để push đã có ở bước git push).
#
# Dùng (crontab ví dụ — 07:00 thứ Hai, sau workflow GitHub 06:47 UTC ở §maintenance.yml):
#   0 7 * * 1  cd /path/to/repo && GITHUB_TOKEN=ghp_xxx scripts/maintain-cron.sh >> /var/log/maintain-cron.log 2>&1
#
# Cờ: --harness/--model/--provider/--mode chuyển thẳng cho maintain-run.sh (xem --help ở đó).
#     --base <nhánh>     nhánh nền để đồng bộ + rẽ nhánh maint/auto-* (mặc định: tự dò origin/HEAD)
#     --no-push          chạy trọn vẹn (pull + sweep + agent) nhưng KHÔNG commit/push — để test tay
#     --lock-dir <dir>   nơi đặt file khoá (mặc định: thư mục tạm hệ thống, NGOÀI working tree)
#     --no-open-pr       đẩy nhánh nhưng KHÔNG tự mở PR dù có token (bạn tự mở tay)
#     --gh-token-file <f>  file chứa token GitHub (khuyến nghị trên máy chung, thay biến môi trường)
#     --gh-token <tok>   token qua argv — CHỈ để tương thích cũ, lộ qua `ps`; script cảnh báo
#     --repo <owner/repo> ghi đè owner/repo (mặc định: tự tách từ `git remote get-url origin`;
#                        bắt buộc khai nếu origin không phải github.com hoặc là SSH alias lạ)
set -uo pipefail

ROOT="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"
BASE=""; NO_PUSH=0; LOCK_DIR=""; NO_OPEN_PR=0; GH_TOKEN_FLAG=""; REPO_FLAG=""
PASS_ARGS=()

log() { printf '[maintain-cron] %s %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$*" >&2; }
die() { log "LỖI: $*"; exit "${2:-1}"; }

# Kiểm trước shift 2: thiếu giá trị không được thành vòng lặp vô hạn.
require_cli_value() {
  if [ "$#" -lt 2 ] || [ -z "${2:-}" ] || [[ "${2:-}" == -* ]]; then
    printf '[CLI] thiếu giá trị cho %s (cần giá trị không rỗng)\n' "$1" >&2
    exit 2
  fi
}

while [ $# -gt 0 ]; do
  case "$1" in
    --base|--lock-dir|--gh-token|--gh-token-file|--repo|--harness|--model|--provider|--mode) require_cli_value "$@" ;;
  esac
  case "$1" in
    --base)       BASE="${2:-}"; shift 2 ;;
    --no-push)    NO_PUSH=1; shift ;;
    --lock-dir)   LOCK_DIR="${2:-}"; shift 2 ;;
    --no-open-pr) NO_OPEN_PR=1; shift ;;
    --gh-token)   GH_TOKEN_FLAG="${2:-}"; log "CẢNH BÁO: --gh-token đưa token vào argv (lộ qua ps/cron log máy chung) — dùng --gh-token-file hoặc biến môi trường GITHUB_TOKEN"; shift 2 ;;
    --gh-token-file) GH_TOKEN_FLAG="$(tr -d '[:space:]' < "${2:-/dev/null}")"; shift 2 ;;
    --repo)       REPO_FLAG="${2:-}"; shift 2 ;;
    -h|--help)    awk 'NR>1 && !/^#/{exit} NR>1' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;   # in TRỌN khối comment đầu file (bản cũ cắt ở dòng 36 → thiếu 5 cờ)
    --harness|--model|--provider|--mode) PASS_ARGS+=("$1" "${2:-}"); shift 2 ;;
    *) die "tham số lạ: $1 (xem --help)" 2 ;;
  esac
done

cd "$ROOT" || die "không cd được vào $ROOT" 2
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || die "không phải git repo: $ROOT" 2
for need in scripts/maintain-run.sh scripts/maintenance-sweep.sh; do
  [ -f "$need" ] || die "thiếu $need — repo chưa có agent bảo trì (chạy copy-framework.sh)" 3
done

# ── (0) Khoá tiến trình — không chạy chồng lên chính nó ─────────────────────
# Mặc định đặt NGOÀI working tree (thư mục tạm hệ thống, khoá theo đường dẫn repo) — cố ý không
# mặc định vào $ROOT/.claude: một file khoá lọt vào git status sẽ tự làm hỏng bước (1) "working
# tree phải sạch" ở NGAY LƯỢT CHẠY KẾ TIẾP, dù đã có dòng .gitignore. Không phụ thuộc quy ước
# .gitignore của mỗi checkout — an toàn cả khi ai đó quên thêm dòng đó vào .gitignore của họ.
if [ -z "${LOCK_DIR:-}" ]; then
  repo_hash="$(printf '%s' "$ROOT" | cksum | cut -d' ' -f1)"
  LOCK_DIR="${TMPDIR:-/tmp}/maintain-cron.$repo_hash"
fi
mkdir -p "$LOCK_DIR" 2>/dev/null || true
LOCK_FILE="$LOCK_DIR/.maintain-cron.lock"
if command -v flock >/dev/null 2>&1; then
  exec 9>"$LOCK_FILE"
  flock -n 9 || die "một lượt maintain-cron khác đang chạy (khoá: $LOCK_FILE)" 4
else
  # Fallback không có flock (vd macOS mặc định): file khoá + kiểm PID còn sống không.
  if [ -f "$LOCK_FILE" ]; then
    old_pid="$(cat "$LOCK_FILE" 2>/dev/null || true)"
    if [ -n "$old_pid" ] && kill -0 "$old_pid" 2>/dev/null; then
      die "một lượt maintain-cron khác đang chạy (PID $old_pid, khoá: $LOCK_FILE)" 4
    fi
    log "khoá cũ trỏ tới PID đã chết ($old_pid) — dọn và tiếp tục."
  fi
  echo $$ > "$LOCK_FILE"
  trap 'rm -f "$LOCK_FILE"' EXIT
fi

# ── (1) Tiền kiểm — working tree PHẢI sạch trước khi đụng vào git ───────────
if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
  die "working tree BẨN (thay đổi chưa commit) — không tự ý stash/reset trên VPS không giám sát. Dọn tay rồi chạy lại." 5
fi

[ -n "$BASE" ] || BASE="$(git symbolic-ref -q --short refs/remotes/origin/HEAD 2>/dev/null | sed 's#^origin/##')"
[ -n "$BASE" ] || BASE=main
log "nhánh nền: $BASE"

# Working tree sạch KHÔNG có nghĩa là không có commit cục bộ chưa đẩy.
guard_local_base() {
  if git show-ref -q --verify "refs/heads/$BASE"; then
    git merge-base --is-ancestor "$BASE" "origin/$BASE" \
      || die "nhánh nền $BASE có commit cục bộ/chia nhánh — giữ nguyên, không reset" 6
  fi
}
git fetch origin "$BASE" --quiet || die "git fetch origin $BASE thất bại (mạng/quyền?)" 6
guard_local_base
git checkout -q "$BASE" 2>/dev/null || git checkout -q -B "$BASE" "origin/$BASE" || die "không checkout được $BASE" 6
git reset -q --hard "origin/$BASE" || die "không đồng bộ được với origin/$BASE" 6   # an toàn: base vừa fetch, không phải nhánh có việc dở
log "đã đồng bộ $BASE = origin/$BASE ($(git rev-parse --short HEAD))"

WORK_BRANCH="maint/auto-$(date -u +%Y-%m-%d)"
# Chụp SHA kỳ vọng MỘT LẦN; background fetch không được cấp quyền ghi đè mới.
[ "$WORK_BRANCH" != "$BASE" ] || die "nhánh báo cáo không được trùng nhánh nền" 2
REMOTE_WORK_REF="$(git ls-remote --heads origin "refs/heads/$WORK_BRANCH")" \
  || die "không đọc được trạng thái nhánh báo cáo — không đoán là nhánh chưa tồn tại" 6
EXPECTED_WORK_SHA="${REMOTE_WORK_REF%%[[:space:]]*}"
readonly EXPECTED_WORK_SHA
if git show-ref -q --verify "refs/heads/$WORK_BRANCH"; then
  git checkout -q "$WORK_BRANCH"
  git reset -q --hard "$BASE"   # nhánh cùng ngày chạy lại lần 2 → làm lại từ base mới nhất, không cộng dồn
else
  git checkout -q -b "$WORK_BRANCH" "$BASE"
fi
log "nhánh làm việc: $WORK_BRANCH"

# ── (2) Chạy agent (quét + triage qua CLI subscription cục bộ) ──────────────
AGENT_BASE_SHA="$(git rev-parse HEAD)" || die "không đọc được HEAD trước khi chạy agent" 6
readonly AGENT_BASE_SHA
run_rc=0
bash scripts/maintain-run.sh "${PASS_ARGS[@]}" || run_rc=$?
[ "$run_rc" -eq 0 ] || log "maintain-run.sh thoát $run_rc (không phải lỗi chặn — có thể agent chỉ báo 🔴>0, hoặc CLI lỗi; xem log phía trên)"

# Một CLI có thể stage file khác. Chỉ git add báo cáo là CHƯA đủ để giới hạn commit.
assert_report_only() {
  local changed
  [ "$(git rev-parse HEAD)" = "$AGENT_BASE_SHA" ] && [ "$(git symbolic-ref --quiet --short HEAD)" = "$WORK_BRANCH" ] \
    || die "agent thay đổi commit/nhánh — giữ nguyên để review, không publish" 9
  while IFS= read -r -d '' changed; do
    case "$changed" in
      docs/ops/MAINTENANCE-PLAN.md|docs/ops/MAINTENANCE-LOG.md|docs/ops/MAINTENANCE-REPORT.md) ;;
      *) die "agent thay đổi file ngoài phạm vi báo cáo: $changed — giữ nguyên để kiểm tra, không publish" 9 ;;
    esac
  done < <(git diff --name-only -z; git diff --cached --name-only -z; git ls-files --others --exclude-standard -z)
}
assert_report_only

# ── (3) Commit + push CHỈ 3 file MAINTENANCE-*.md, CHỈ vào nhánh riêng ──────
FILES=(docs/ops/MAINTENANCE-PLAN.md docs/ops/MAINTENANCE-LOG.md docs/ops/MAINTENANCE-REPORT.md)
present=()
for f in "${FILES[@]}"; do [ -f "$f" ] && present+=("$f"); done
if [ "${#present[@]}" -eq 0 ]; then
  log "agent không ghi file MAINTENANCE-* nào — không có gì để commit."
  git checkout -q "$BASE"; exit "$run_rc"
fi
git add -- "${present[@]}"
if git diff --cached --quiet; then
  log "không có thay đổi thật trong ${present[*]} — không commit."
  git checkout -q "$BASE"; exit "$run_rc"
fi

git -c user.name="maintain-cron" -c user.email="maintain-cron@localhost" \
  commit -q -m "chore(maintenance): quét bảo trì tự động $(date -u +%Y-%m-%d)

Sinh bởi scripts/maintain-cron.sh (không giám sát). KHÔNG tự merge — mở PR
để người duyệt docs/ops/MAINTENANCE-PLAN.md trước khi bất kỳ mục nào được
thực thi (CLAUDE.md §2 Feature gate)." \
  || die "git commit thất bại" 7

if [ "$NO_PUSH" -eq 1 ]; then
  log "--no-push: đã commit vào $WORK_BRANCH cục bộ, KHÔNG đẩy lên remote."
  exit "$run_rc"
fi

# Lease gắn SHA bất biến (rỗng = nhánh chưa tồn tại). Không fetch/rồi thử lại
# bằng lease mới: làm vậy có thể ghi đè báo cáo concurrent đã bảo vệ ở lần đầu.
if ! git push --force-with-lease="refs/heads/$WORK_BRANCH:$EXPECTED_WORK_SHA" -u origin "$WORK_BRANCH" --quiet; then
  die "push bị từ chối hoặc mạng lỗi — giữ nhánh cục bộ, không tự refresh lease; đối chiếu remote trước khi chạy lại" 8
fi
log "đã đẩy $WORK_BRANCH lên origin."
git checkout -q "$BASE"

# ── (4) Tự mở PR — kênh báo cáo chính cho chủ dự án ──────────────────────────
open_pr() {
  local TOKEN owner_repo url list_url create_url code body existing_url title pr_body \
        json_body http_body_file len
  [ "$NO_OPEN_PR" -eq 1 ] && { log "--no-open-pr: bỏ qua tự mở PR (nhánh đã có sẵn trên remote để bạn tự mở tay)."; return 0; }
  TOKEN="${GH_TOKEN_FLAG:-${GITHUB_TOKEN:-${GH_TOKEN:-}}}"
  if [ -z "$TOKEN" ]; then
    log "không có GITHUB_TOKEN/GH_TOKEN (hoặc --gh-token) — bỏ qua tự mở PR. Đặt biến môi trường để bật kênh báo cáo này, hoặc tự mở PR tay từ $WORK_BRANCH."
    return 0
  fi
  if ! command -v curl >/dev/null 2>&1; then
    log "thiếu 'curl' trên máy này — không tự mở PR được. Cài curl hoặc tự mở PR tay."
    return 0
  fi

  if [ -n "$REPO_FLAG" ]; then
    owner_repo="$REPO_FLAG"
  else
    url="$(git remote get-url origin 2>/dev/null || true)"
    case "$url" in
      *github.com*)
        owner_repo="$(printf '%s' "$url" | sed -E 's#^(https://|http://|git@|ssh://git@)?github\.com[:/]##; s#\.git$##; s#/+$##')"
        ;;
      *)
        log "remote 'origin' ($url) không phải github.com và không có --repo — bỏ qua tự mở PR."
        return 0
        ;;
    esac
  fi
  [ -n "$owner_repo" ] || { log "không xác định được owner/repo từ origin — dùng --repo <owner/repo>. Bỏ qua tự mở PR."; return 0; }

  # Parse JSON: ưu tiên jq, dự phòng python3 — không có cả hai thì không tự mở PR được an toàn
  # (không tự escape JSON bằng tay, tránh chèn được nội dung lạ vào request).
  local JSON_TOOL=""
  if command -v jq >/dev/null 2>&1; then JSON_TOOL=jq
  elif command -v python3 >/dev/null 2>&1; then JSON_TOOL=py
  else log "thiếu jq và python3 — không tự mở PR được (cần để parse/dựng JSON an toàn). Cài một trong hai, hoặc tự mở PR tay."; return 0
  fi

  local CURL_BIN="${MAINT_BIN_CURL:-curl}"
  # $1=method(GET|POST) $2=url $3=bodyfile(ĐÃ tạo sẵn bởi caller) $4=data(optional, chỉ POST)
  # -> in http code ra stdout. CỐ Ý nhận bodyfile làm THAM SỐ thay vì ghi vào biến ngoài: mọi lệnh
  # gọi hàm này đều qua `code="$(http_call ...)"` (command substitution = SUBSHELL) — một biến được
  # gán BÊN TRONG hàm khi chạy trong subshell đó không bao giờ thấy được ở scope gọi nó ra ngoài,
  # dù có khai `local` ở hàm cha hay không (bài học bắt được khi viết test §7: lỗi
  # "http_body_file: unbound variable" dưới `set -u`, vì biến never được gán do chạy trong subshell).
  http_call() {
    if [ "$1" = POST ]; then
      "$CURL_BIN" -sS -o "$3" -w '%{http_code}' -X POST \
        -H "Authorization: Bearer $TOKEN" -H "Accept: application/vnd.github+json" \
        -H "X-GitHub-Api-Version: 2022-11-28" -H "User-Agent: maintain-cron" \
        -d "$4" "$2"
    else
      "$CURL_BIN" -sS -o "$3" -w '%{http_code}' \
        -H "Authorization: Bearer $TOKEN" -H "Accept: application/vnd.github+json" \
        -H "X-GitHub-Api-Version: 2022-11-28" -H "User-Agent: maintain-cron" \
        "$2"
    fi
  }
  json_len() { if [ "$JSON_TOOL" = jq ]; then jq 'length' 2>/dev/null; else python3 -c 'import json,sys;print(len(json.load(sys.stdin)))' 2>/dev/null; fi; }
  json_field0() { if [ "$JSON_TOOL" = jq ]; then jq -r ".[0].$1 // empty" 2>/dev/null; else python3 -c "import json,sys;d=json.load(sys.stdin);print((d[0].get('$1') or '') if d else '')" 2>/dev/null; fi; }
  json_field() { if [ "$JSON_TOOL" = jq ]; then jq -r ".$1 // empty" 2>/dev/null; else python3 -c "import json,sys;d=json.load(sys.stdin);print(d.get('$1') or '')" 2>/dev/null; fi; }

  # (a) Tránh PR trùng: đã có PR mở cho đúng nhánh này chưa?
  local owner="${owner_repo%%/*}"
  list_url="https://api.github.com/repos/${owner_repo}/pulls?head=${owner}:${WORK_BRANCH}&base=${BASE}&state=open"
  http_body_file="$(mktemp "${TMPDIR:-/tmp}/maintain-cron-gh.XXXXXX")"
  code="$(http_call GET "$list_url" "$http_body_file")"
  body="$(cat "$http_body_file" 2>/dev/null)"; rm -f "$http_body_file"
  if [ "$code" != "200" ]; then
    log "kiểm tra PR đang mở thất bại (HTTP $code) — bỏ qua tự mở PR lượt này. Body: $(printf '%s' "$body" | head -c 200)"
    return 0
  fi
  len="$(printf '%s' "$body" | json_len)"
  if [ -n "$len" ] && [ "$len" -gt 0 ] 2>/dev/null; then
    existing_url="$(printf '%s' "$body" | json_field0 html_url)"
    log "PR đã mở sẵn cho $WORK_BRANCH — không tạo trùng: ${existing_url:-<không đọc được URL>}"
    return 0
  fi

  # (b) Chưa có → tạo PR mới. Nội dung: tóm tắt + link kế hoạch, để chủ dự án đọc ngay trên GitHub.
  title="chore(maintenance): bảo trì tự động $(date -u +%Y-%m-%d)"
  pr_body="Sinh tự động bởi \`scripts/maintain-cron.sh\` (không giám sát) trên $(hostname 2>/dev/null || echo VPS).

Xem \`docs/ops/MAINTENANCE-PLAN.md\` trong PR này để duyệt kế hoạch trước khi bất kỳ mục nào được thực thi (CLAUDE.md §2 Feature gate). KHÔNG tự merge — cần người duyệt."
  create_url="https://api.github.com/repos/${owner_repo}/pulls"
  if [ "$JSON_TOOL" = jq ]; then
    json_body="$(jq -n --arg t "$title" --arg h "$WORK_BRANCH" --arg b "$BASE" --arg body "$pr_body" '{title:$t, head:$h, base:$b, body:$body}')"
  else
    json_body="$(TITLE="$title" HEAD="$WORK_BRANCH" BASEB="$BASE" BODY="$pr_body" python3 -c 'import json,os;print(json.dumps({"title":os.environ["TITLE"],"head":os.environ["HEAD"],"base":os.environ["BASEB"],"body":os.environ["BODY"]}))')"
  fi
  http_body_file="$(mktemp "${TMPDIR:-/tmp}/maintain-cron-gh.XXXXXX")"
  code="$(http_call POST "$create_url" "$http_body_file" "$json_body")"
  body="$(cat "$http_body_file" 2>/dev/null)"; rm -f "$http_body_file"
  if [ "$code" = "201" ]; then
    log "Đã mở PR báo cáo cho chủ dự án: $(printf '%s' "$body" | json_field html_url)"
  else
    log "mở PR thất bại (HTTP $code) — nhánh $WORK_BRANCH vẫn đã nằm trên remote, tự mở PR tay. Body: $(printf '%s' "$body" | head -c 300)"
  fi
}
open_pr
exit "$run_rc"
