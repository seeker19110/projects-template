#!/usr/bin/env bash
# maintenance-sweep.sh — Engine QUÉT BẢO TRÌ toàn diện, KHÔNG phụ thuộc stack.
#
# Vì sao tồn tại: "bảo trì" là việc lặp lại (tuần/tháng) gồm nhiều mảng rời rạc — dependency
# lỗi thời/lỗ hổng, nhánh chết, tài liệu trạng thái lỗi thời, nợ TODO, bí mật lọt vào git,
# action CI chưa ghim, cổng khung đỏ… Không ai nhớ hết, nên bảo trì hay bị bỏ hoặc làm lệch.
# Script này GOM mọi phép đo về một báo cáo Markdown có mức độ, để subagent `maintainer`
# (hoặc người) chỉ còn việc TRIAGE + LẬP KẾ HOẠCH, không phải nhớ danh sách kiểm.
#
# Nguyên tắc (giống dev-task.sh): CHỈ ĐỌC + ĐO, không sửa gì. Mỗi phép đo không dò được ở
# stack hiện tại → ghi "n-a", không làm chết lượt quét. Lệnh đặc thù dự án khai ở
# .claude/project-commands.sh (biến `deps_outdated`, `deps_audit`) sẽ được ưu tiên.
#
# Dùng: scripts/maintenance-sweep.sh [--out <file.md>] [--strict] [--gate] [--no-deps]
#   --out      ghi báo cáo ra file (mặc định: stdout)
#   --strict   thoát mã 1 nếu có phát hiện mức 🔴 (dùng cho CI/lịch tuần)
#   --gate     chạy thêm `scripts/dev-task.sh gate` (build/type/lint/test) — chậm, tuỳ chọn
#   --no-deps  bỏ qua kiểm dependency (cần mạng; tắt khi offline)
#
# Mức độ:  🔴 phải xử lý ngay (bí mật lọt git, cổng đỏ, lỗ hổng dependency)
#          🟡 nên lên kế hoạch (dependency lỗi thời, tài liệu lỗi thời, nhánh chết, TODO nhiều)
#          ℹ️  thông tin (số liệu tham chiếu)
set -uo pipefail   # cố ý KHÔNG -e: một phép đo hỏng không được làm chết cả lượt quét

ROOT="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"
DECL="$ROOT/.claude/project-commands.sh"
OUT=""; STRICT=0; RUN_GATE=0; DO_DEPS=1
DEPS_TIMEOUT="${MAINT_DEPS_TIMEOUT:-180}"   # giây cho mỗi lệnh dependency (cần mạng)
STALE_DOC_DAYS="${MAINT_STALE_DOC_DAYS:-30}"
FRAMEWORK_STALE_DAYS="${MAINT_FRAMEWORK_STALE_DAYS:-90}"   # dự án đích: bản khung đã copy quá cũ → 🟡 (spec 2026-09-23 nâng bản khung)
TODO_WARN="${MAINT_TODO_WARN:-20}"

while [ $# -gt 0 ]; do
  case "$1" in
    --out)     OUT="${2:-}"; shift 2 ;;
    --strict)  STRICT=1; shift ;;
    --gate)    RUN_GATE=1; shift ;;
    --no-deps) DO_DEPS=0; shift ;;
    -h|--help) sed -n '2,24p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) printf '[maintenance-sweep] tham số lạ: %s\n' "$1" >&2; exit 2 ;;
  esac
done

cd "$ROOT" || exit 2

# ── Bộ đếm + bộ gom phát hiện ─────────────────────────────────────────────────
RED=0; YEL=0
FINDINGS=()           # mỗi dòng: "<mức>|<mảng>|<mô tả>|<cách xử lý>"
REPORT=()             # nội dung markdown từng mảng

red()  { RED=$((RED+1)); FINDINGS+=("🔴|$1|$2|$3"); }
yel()  { YEL=$((YEL+1)); FINDINGS+=("🟡|$1|$2|$3"); }
info() { FINDINGS+=("ℹ️|$1|$2|$3"); }
sec()  { REPORT+=("" "## $1" ""); }
line() { REPORT+=("$1"); }
block() { # gom stdin vào một khối ```; KHÔNG dùng `| while` (subshell làm mất REPORT)
  local l; line '```'; while IFS= read -r l; do line "$l"; done; line '```'
}

has() { command -v "$1" >/dev/null 2>&1; }
is_git() { git rev-parse --is-inside-work-tree >/dev/null 2>&1; }
tracked() { git ls-files -z 2>/dev/null; }   # NUL-separated

# Chạy một lệnh có timeout (nếu có coreutils timeout), gom stdout+stderr, trả exit code.
run_capture() { # $1=giây, $2..=lệnh (chuỗi bash)
  local secs="$1"; shift
  if has timeout; then timeout "$secs" bash -c "$*" 2>&1; else bash -c "$*" 2>&1; fi
}

declared_var() { # $1=tên biến trong project-commands.sh → in giá trị hoặc rỗng
  [ -f "$DECL" ] || return 0
  # shellcheck source=/dev/null  # file khai báo của DỰ ÁN ĐÍCH, repo khung không có
  ( set +u; . "$DECL" >/dev/null 2>&1; eval "printf '%s' \"\${$1:-}\"" )
}

days_since() { # $1=YYYY-MM-DD → số ngày tới nay, rỗng nếu không parse được
  local ts; ts="$(date -d "$1" +%s 2>/dev/null || date -j -f '%Y-%m-%d' "$1" +%s 2>/dev/null)" || return 0
  [ -n "$ts" ] && echo $(( ( $(date +%s) - ts ) / 86400 ))
}

# ── 1. Git hygiene ────────────────────────────────────────────────────────────
sweep_git() {
  sec "1. Git"
  if ! is_git; then line "n-a — không phải git repo"; info Git "không phải git repo" "—"; return; fi
  local main dirty behind stale_n stale_list last_age
  main="$(git symbolic-ref -q --short refs/remotes/origin/HEAD 2>/dev/null | sed 's#^origin/##')"
  [ -n "$main" ] || { git show-ref -q --verify refs/heads/main && main=main; } || main=master
  dirty="$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')"
  line "- Nhánh chính: \`$main\` · nhánh hiện tại: \`$(git rev-parse --abbrev-ref HEAD 2>/dev/null)\`"
  line "- File chưa commit: $dirty"
  [ "$dirty" -gt 0 ] && yel Git "$dirty file chưa commit trong working tree" "commit hoặc stash trước khi bảo trì"
  if git show-ref -q --verify "refs/remotes/origin/$main"; then
    behind="$(git rev-list --count "HEAD..origin/$main" 2>/dev/null || echo 0)"
    line "- Commit đứng sau \`origin/$main\`: $behind"
    [ "$behind" -gt 0 ] && yel Git "nhánh hiện tại đứng sau origin/$main $behind commit" "merge/rebase với $main trước"
  fi
  # Nhánh local đã merge vào main mà chưa xoá (trừ chính main + nhánh hiện tại)
  stale_list="$(git branch --merged "$main" 2>/dev/null | sed 's/^[* ] *//' | grep -vxE "$main|$(git rev-parse --abbrev-ref HEAD)" || true)"
  stale_n="$(printf '%s' "$stale_list" | grep -c . || true)"
  line "- Nhánh local đã merge vào \`$main\` chưa xoá: $stale_n"
  [ "$stale_n" -gt 0 ] && yel Git "$stale_n nhánh local đã merge còn sót: $(printf '%s' "$stale_list" | tr '\n' ' ')" "git branch -d <nhánh>"
  last_age="$(( ( $(date +%s) - $(git log -1 --format=%ct 2>/dev/null || date +%s) ) / 86400 ))"
  line "- Commit gần nhất: $last_age ngày trước"
  info Git "commit gần nhất $last_age ngày trước" "—"
}

# ── 2. Dependency (cần mạng; ưu tiên khai báo, rồi tự dò) ─────────────────────
# node_pm/py_present dùng chung với dev-task.sh — một nguồn (scripts/_stack-detect.sh); ROOT = thư mục đang quét.
# shellcheck source=scripts/_stack-detect.sh
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/_stack-detect.sh"
# Mỗi hệ sinh thái một hàm: in lệnh cho loại quét $1 (outdated|audit), hoặc return 1 nếu hệ sinh
# thái này không có mặt / không có lệnh. Tách ra vì bản gộp từng ở CC 13 — trên trần 12 mà
# `scripts/check-shell-complexity.sh` cưỡng chế.
_deps_node() {
  [ -f package.json ] || return 1
  local pm; pm="$(node_pm)"
  case "$1" in
    outdated) echo "$pm outdated" ;;
    audit)    [ "$pm" = yarn ] && echo "yarn npm audit --severity high" || echo "$pm audit --audit-level=high" ;;
  esac
  return 0   # hệ sinh thái CÓ MẶT → thắng, kể cả khi không có lệnh (bản cũ cũng dừng tại đây)
}
_deps_python() {
  py_present || return 1
  case "$1" in
    outdated) has pip && echo "! pip list --outdated --format=freeze 2>/dev/null | grep -q ." ;;   # có dòng = có gói cũ → exit 1 (pip luôn exit 0)
    audit)    has pip-audit && echo "pip-audit" ;;
  esac
  return 0   # hệ sinh thái CÓ MẶT → thắng, kể cả khi không có lệnh (bản cũ cũng dừng tại đây)
}
_deps_go() {
  [ -f go.mod ] || return 1
  case "$1" in
    outdated) echo "test -z \"\$(go list -m -u all 2>/dev/null | grep '\\[')\"" ;;   # có '[vX]' = có gói cũ → exit 1 (bản cũ đảo chiều: grep khớp → exit 0 → báo 'sạch')
    audit)    has govulncheck && echo "govulncheck ./..." ;;
  esac
  return 0   # hệ sinh thái CÓ MẶT → thắng, kể cả khi không có lệnh (bản cũ cũng dừng tại đây)
}
_deps_rust() {
  [ -f Cargo.toml ] || return 1
  case "$1" in
    outdated) has cargo-outdated && echo "cargo outdated --exit-code 1" ;;
    audit)    has cargo-audit && echo "cargo audit" ;;
  esac
  return 0   # hệ sinh thái CÓ MẶT → thắng, kể cả khi không có lệnh (bản cũ cũng dừng tại đây)
}
detect_deps_cmd() { # $1=outdated|audit → in lệnh hoặc rỗng
  # THỨ TỰ LÀ HÀNH VI: hệ sinh thái đầu tiên CÓ MẶT thắng, kể cả khi nó không có lệnh cho
  # loại quét này (bản cũ cũng `return 0` ngay tại đó, không rơi xuống hệ sinh thái sau).
  local eco
  for eco in _deps_node _deps_python _deps_go _deps_rust; do
    "$eco" "$1" && return 0
  done
  return 0
}
sweep_deps() {
  sec "2. Dependency"
  if [ "$DO_DEPS" -eq 0 ]; then line "bỏ qua (--no-deps)"; info Dependency "bỏ qua theo --no-deps" "—"; return; fi
  local kind cmd out rc
  for kind in outdated audit; do
    cmd="$(declared_var "deps_$kind")"; [ -n "$cmd" ] || cmd="$(detect_deps_cmd "$kind")"
    if [ -z "$cmd" ]; then
      line "- $kind: n-a (không dò được lệnh cho stack này — khai \`deps_$kind\` ở \`.claude/project-commands.sh\`)"
      info Dependency "$kind: chưa có lệnh cho stack này" "khai deps_$kind trong .claude/project-commands.sh"
      continue
    fi
    out="$(run_capture "$DEPS_TIMEOUT" "$cmd")"; rc=$?
    line "- $kind: \`$cmd\` → exit $rc"
    if [ "$rc" -eq 124 ]; then
      yel Dependency "$kind: hết giờ sau ${DEPS_TIMEOUT}s (mạng/proxy?)" "chạy tay: $cmd"
    elif [ "$rc" -ne 0 ] && [ "$kind" = audit ]; then
      red Dependency "audit báo lỗ hổng (exit $rc)" "chạy tay: $cmd — nâng gói bị ảnh hưởng"
    elif [ "$rc" -ne 0 ]; then
      yel Dependency "có gói lỗi thời (exit $rc)" "chạy tay: $cmd — lên kế hoạch nâng theo lô"
    fi
    [ -n "$out" ] && block <<<"$(printf '%s\n' "$out" | tail -n 25)"
  done
}

# ── 3. Tài liệu & nợ kỹ thuật ─────────────────────────────────────────────────
sweep_framework_age() {   # dự án đích có docs/framework/FRAMEWORK-VERSION → đo tuổi bản khung đã copy
  local d age
  [ -f docs/framework/FRAMEWORK-VERSION ] || return 0
  d="$(grep -m1 -oE 'ngay-copy:[[:space:]]*[0-9]{4}-[0-9]{2}-[0-9]{2}' docs/framework/FRAMEWORK-VERSION | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}' || true)"
  [ -n "$d" ] || { line "- Bản khung đã copy: không đọc được 'ngay-copy:'"; return 0; }
  age="$(days_since "$d")"; line "- Bản khung đã copy: $age ngày trước ($d)"
  [ -n "$age" ] && [ "$age" -gt "$FRAMEWORK_STALE_DAYS" ] && yel "Tài liệu" "bản khung đã copy $age ngày trước ($d)" "clone repo khung mới rồi: bash copy-framework.sh <đích> --upgrade (giữ chỉnh sửa cục bộ)"
  return 0
}
sweep_docs() {
  sec "3. Tài liệu & nợ kỹ thuật"
  local d age n
  sweep_framework_age
  if [ -f PROGRESS.md ]; then
    d="$(grep -m1 -oE 'Ngày cập nhật:[[:space:]]*[0-9]{4}-[0-9]{2}-[0-9]{2}' PROGRESS.md | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}' || true)"
    if [ -n "$d" ]; then
      age="$(days_since "$d")"; line "- PROGRESS.md cập nhật $age ngày trước ($d)"
      [ -n "$age" ] && [ "$age" -gt "$STALE_DOC_DAYS" ] && yel "Tài liệu" "PROGRESS.md lỗi thời $age ngày" "cập nhật mục 'Giai đoạn hiện tại' (CLAUDE.md §2)"
    else
      line "- PROGRESS.md: không đọc được 'Ngày cập nhật:'"; yel "Tài liệu" "PROGRESS.md thiếu dòng 'Ngày cập nhật: YYYY-MM-DD'" "thêm dòng đó theo PROGRESS.template.md"
    fi
  else
    line "- PROGRESS.md: không có"; yel "Tài liệu" "thiếu PROGRESS.md" "tạo từ PROGRESS.template.md"
  fi
  if [ -d docs/specs ]; then
    n="$(grep -lE '^\| State \|.*(Draft|In review)' docs/specs/*.md 2>/dev/null | wc -l | tr -d ' ')"
    line "- Spec chưa Approved (Draft/In review): $n"
    [ "$n" -gt 0 ] && info "Tài liệu" "$n spec còn Draft/In review" "duyệt hoặc đóng spec treo"
  fi
  if [ -d docs/goals ]; then
    n="$(grep -lE '^\|[[:space:]]*State[[:space:]]*\|[^|]*\bBLOCKED\b' docs/goals/*.md 2>/dev/null | grep -v README | wc -l | tr -d ' ')"
    line "- Goal đang BLOCKED: $n"
    [ "$n" -gt 0 ] && yel "Tài liệu" "$n goal BLOCKED chờ quyết định" "xem docs/goals/ — quyết định rồi mở lại"
  fi
  if is_git; then
    n="$(tracked | grep -zvE '\.(md|json|lock|svg|png|jpg)$|^(CHANGELOG|TRAPS)' | xargs -0 grep -nE '\b(TODO|FIXME|HACK|XXX)\b' 2>/dev/null | grep -vc "maintenance-sweep.sh" || true)"
    line "- TODO/FIXME/HACK trong mã: $n"
    if [ "$n" -gt "$TODO_WARN" ]; then yel "Nợ kỹ thuật" "$n TODO/FIXME/HACK (ngưỡng $TODO_WARN)" "gom thành issue hoặc xử lý theo lô"; else info "Nợ kỹ thuật" "$n TODO/FIXME/HACK" "—"; fi
    # Dấu nợ CÓ CẤU TRÚC (CLAUDE.md §3 A7): "DEBT: <gì> | trần: <giới hạn> | xem lại khi: <điều kiện>".
    # Thiếu "xem lại khi:" = khoản nợ không có đường quay lại → mục âm thầm (TRAPS.md mục 14 đã tái phát vì vậy).
    # TU_NO (TRAPS.md mục 18): loại chính file đếm + file test của nó, kẻo bộ đếm tự khớp văn bản của mình.
    local debt_all debt_notrigger
    debt_all="$(tracked | grep -zvE '\.(md|json|lock|svg|png|jpg)$|^(CHANGELOG|TRAPS)' \
      | xargs -0 grep -nE '\bDEBT:' 2>/dev/null | grep -vE 'maintenance-sweep\.sh|test-maintenance-sweep\.sh' || true)"
    n="$(printf '%s' "$debt_all" | grep -c . || true)"
    debt_notrigger="$(printf '%s' "$debt_all" | grep -vc 'xem lại khi:' || true)"
    [ "$n" -eq 0 ] && debt_notrigger=0
    line "- Dấu nợ \`DEBT:\` trong mã: $n (thiếu điều kiện xem lại: $debt_notrigger)"
    if [ "$debt_notrigger" -gt 0 ]; then
      yel "Nợ kỹ thuật" "$debt_notrigger dấu DEBT: không có 'xem lại khi:'" "bổ sung điều kiện quay lại (CLAUDE.md §3 A7) — nợ không có đường quay lại sẽ mục âm thầm"
    else
      if [ "$n" -eq 0 ]; then info "Nợ kỹ thuật" "không có dấu DEBT:" "—"; else info "Nợ kỹ thuật" "$n dấu DEBT:, đều có điều kiện xem lại" "—"; fi
    fi
  fi
}

# ── 4. Vệ sinh repo & bí mật ──────────────────────────────────────────────────
sweep_hygiene() {
  sec "4. Vệ sinh repo & bí mật"
  is_git || { line "n-a — không phải git repo"; return; }
  local envs big hits
  envs="$(tracked | grep -zE '(^|/)\.env(\.[a-z]+)?$' | grep -zvE '\.example$|\.sample$|\.template$' | tr '\0' ' ')"
  line "- File .env đang được git theo dõi: ${envs:-không}"
  [ -n "$envs" ] && red "Bí mật" "file .env nằm trong git: $envs" "git rm --cached <file> + thêm vào .gitignore + xoay vòng bí mật"
  hits="$(tracked | grep -zvE '\.(example|sample)$|maintenance-sweep\.sh$' \
    | xargs -0 grep -nIE '(AKIA[0-9A-Z]{16}|-----BEGIN [A-Z ]*PRIVATE KEY-----|ghp_[A-Za-z0-9]{36}|github_pat_[A-Za-z0-9_]{22,}|glpat-[A-Za-z0-9_-]{20}|AIza[0-9A-Za-z_-]{35}|sk-[A-Za-z0-9]{32,}|xox[baprs]-[A-Za-z0-9-]{10,})' 2>/dev/null | head -n 10 || true)"
  if [ -n "$hits" ]; then
    line "- Chuỗi giống bí mật:"; block <<<"$(printf '%s\n' "$hits" | cut -c1-160)"
    red "Bí mật" "$(printf '%s\n' "$hits" | wc -l | tr -d ' ') dòng giống khoá/token thật trong file được git theo dõi" "xoá khỏi lịch sử + xoay vòng khoá; cân nhắc gitleaks"
  else
    line "- Chuỗi giống bí mật (AWS/PEM/GitHub/GitLab/Google/OpenAI/Slack): không"
  fi
  # KHÔNG nội suy tên file vào chuỗi lệnh shell (bản cũ `xargs -I{} sh -c 'f="{}"'` = command
  # injection qua tên file do PR/fork đưa vào — nguy hiểm khi maintain-cron chạy không giám sát).
  big="$(tracked | while IFS= read -r -d '' f; do
    s=$(wc -c <"$f" 2>/dev/null || echo 0); [ "$s" -gt 1048576 ] && echo "$f ($((s/1024)) KB)"; done || true)"
  line "- File > 1 MB được theo dõi: ${big:-không}"
  [ -n "$big" ] && yel "Vệ sinh" "file lớn trong git: $(printf '%s' "$big" | tr '\n' ' ')" "cân nhắc Git LFS hoặc loại khỏi repo"
}

# ── 5. CI / chuỗi cung ứng ────────────────────────────────────────────────────
sweep_ci() {
  sec "5. CI & chuỗi cung ứng"
  local wf unpinned
  if [ ! -d .github/workflows ]; then line "n-a — không có .github/workflows"; info CI "chưa có workflow CI" "xem docs/ops/repository-settings.md"; return; fi
  wf="$(find .github/workflows -maxdepth 1 \( -name '*.yml' -o -name '*.yaml' \) | wc -l | tr -d ' ')"
  line "- Workflow: $wf"
  unpinned="$(grep -nE '^\s*-?\s*uses:\s*[^./][^@]*@' .github/workflows/*.y*ml 2>/dev/null | grep -vE '@[0-9a-f]{40}' || true)"
  if [ -n "$unpinned" ]; then
    line "- Action chưa ghim full SHA:"; block <<<"$unpinned"
    yel CI "$(printf '%s\n' "$unpinned" | wc -l | tr -d ' ') action chưa ghim commit SHA" "ghim \`uses: <action>@<sha40> # <tag>\` (docs/ops/supply-chain.md)"
  else
    line "- Action chưa ghim full SHA: không"
  fi
  [ -f .github/dependabot.yml ] || yel CI "thiếu .github/dependabot.yml" "copy từ dropins của khung"
  line "- dependabot.yml: $([ -f .github/dependabot.yml ] && echo có || echo không)"
}

# ── 6. Cổng của khung + gate dự án ────────────────────────────────────────────
run_gate_script() { # $1=script, $2=nhãn, $3..=tham số
  local s="$1" label="$2"; shift 2
  [ -f "$s" ] || { line "- $label: n-a (không có \`$s\`)"; return; }
  local out rc; out="$(bash "$s" "$@" 2>&1)"; rc=$?
  if [ "$rc" -eq 0 ]; then line "- $label: ✅"; else
    line "- $label: ❌ (exit $rc)"; block <<<"$(printf '%s\n' "$out" | grep -E 'error|FAIL|❌' | head -n 8)"
    red "Cổng" "$label đỏ" "chạy \`bash $s\` và sửa theo output"
  fi
}
sweep_gates() {
  sec "6. Cổng khung & gate dự án"
  run_gate_script scripts/check-docs-consistency.sh "docs-consistency"
  run_gate_script scripts/check-ci-policy.sh "ci-policy"
  if [ -f scripts/arch-health-radar.sh ]; then
    local score; score="$(bash scripts/arch-health-radar.sh --json 2>/dev/null | (has jq && jq -r '.health_score // empty' || grep -oE '"health_score":[[:space:]]*[0-9]+' | head -1 | grep -oE '[0-9]+') || true)"
    line "- arch-health-radar: ${score:-không đọc được}/100"
    [ -n "$score" ] && [ "$score" -lt 80 ] && yel "Cổng" "radar sức khoẻ $score/100" "chạy \`scripts/arch-health-radar.sh --scan\` xem mục kéo điểm"
  fi
  if [ "$RUN_GATE" -eq 1 ]; then
    run_gate_script scripts/dev-task.sh "dev-task gate (build/type/lint/test)" gate
  else
    line "- dev-task gate: bỏ qua (thêm \`--gate\` để chạy)"
  fi
}

# ── Chạy & xuất báo cáo ───────────────────────────────────────────────────────
sweep_git; sweep_deps; sweep_docs; sweep_hygiene; sweep_ci; sweep_gates

{
  echo "# Báo cáo quét bảo trì — $(date +%Y-%m-%d)"
  echo
  echo "> Sinh bởi \`scripts/maintenance-sweep.sh\` (chỉ đọc + đo, không sửa). 🔴 $RED · 🟡 $YEL."
  echo "> Triage + kế hoạch: subagent \`maintainer\` / lệnh \`/maintain\`. Mọi sửa đổi đi PR riêng qua \`/gate\`."
  echo
  echo "## Tổng hợp phát hiện"
  echo
  echo "| Mức | Mảng | Phát hiện | Cách xử lý |"
  echo "| --- | --- | --- | --- |"
  for f in "${FINDINGS[@]}"; do
    IFS='|' read -r lv area what how <<<"$f"
    printf '| %s | %s | %s | %s |\n' "$lv" "$area" "${what//|/\\|}" "${how//|/\\|}"
  done
  printf '%s\n' "${REPORT[@]}"
} > "${OUT:-/dev/stdout}"

[ -n "$OUT" ] && printf '[maintenance-sweep] báo cáo: %s (🔴 %s · 🟡 %s)\n' "$OUT" "$RED" "$YEL" >&2
if [ "$STRICT" -eq 1 ] && [ "$RED" -gt 0 ]; then exit 1; fi
exit 0
