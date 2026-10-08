#!/usr/bin/env bash
# dev-task.sh — điểm vào ỔN ĐỊNH, KHÔNG phụ thuộc stack, cho các tác vụ dev.
#
# Vì sao tồn tại: template hỗ trợ MỌI loại dự án (web/mobile/backend/CLI/data/…),
# nên KHÔNG được hardcode lệnh (npm/ruff/go…) vào hook hay settings. Thay vào đó
# hook chỉ gọi `dev-task.sh <task>`; script này tự phân giải lệnh đúng cho dự án.
#
# Thứ tự phân giải (đầu tiên thắng):
#   1) KHAI BÁO: nếu có .claude/project-commands.sh và định nghĩa biến <task> → chạy.
#   2) TỰ DÒ: nhận diện hệ sinh thái (node/python/go/rust/make) → chạy lệnh quy ước.
#   3) Task đơn lẻ chưa có lệnh → skip. RIÊNG gate/doctor: thiếu kiểm tra → BLOCKED.
#
# Task hỗ trợ: format | lint | typecheck | test | build | gate | doctor | evidence-check | review-check
#   gate = tiền kiểm đủ build/typecheck/lint/test, rồi chạy fail-fast; thiếu command → BLOCKED.
#   doctor = cùng tiền kiểm, chỉ READY (không chạy kiểm tra, không phải PASS).
#   N/A theo profile: gate_skip_<task>_reason trong config đã review; không được bỏ tất cả.
#   --print <task> = chỉ IN lệnh sẽ chạy (để test/dò cấu hình), không chạy.
#
# Stack tự dò (mỗi stack một hàm _cmd_*, thêm stack = thêm hàm + một tên trong detected_cmd):
#   node (npm/pnpm/yarn/bun; alias script: typecheck→type-check→tsc, lint→check, format→fmt) ·
#   python (venv/uv/poetry/PATH — scripts/_stack-detect.sh) · go · rust · java/kotlin (maven/gradle) ·
#   dotnet · flutter/dart · php (composer) · ruby (bundler) · elixir (mix) · deno · swift · make
#
# Dùng: scripts/dev-task.sh <task>
set -uo pipefail   # cố ý KHÔNG -e: không được làm chết phiên/lượt chạy (xem docs/CONVENTIONS.md §A)

TASK="${1:-}"
ROOT="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"
DECL="$ROOT/.claude/project-commands.sh"

log() { printf '[dev-task] %s\n' "$*" >&2; }

if [ -z "$TASK" ]; then
  log "thiếu tên task. Dùng: dev-task.sh format|lint|typecheck|test|build|gate|doctor"
  exit 2
fi

# --- 1) Lệnh KHAI BÁO (escape hatch cho mọi dự án đặc thù) --------------------
# declared_cmd() nằm ở _stack-detect.sh (dùng chung; đọc $DECL lúc gọi).
# --- 2) TỰ DÒ theo hệ sinh thái ---------------------------------------------
# shellcheck source=scripts/_stack-detect.sh
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/_stack-detect.sh"   # node_pm, py_present, py_tool, declared_cmd (dùng chung với maintenance-sweep)
node_has_script() {
  # $1 = tên script; true nếu package.json khai báo nó.
  [ -f "$ROOT/package.json" ] || return 1
  if command -v jq >/dev/null 2>&1; then
    jq -e --arg s "$1" '.scripts[$s] // empty' "$ROOT/package.json" >/dev/null 2>&1
  else
    grep -Eq "\"$1\"[[:space:]]*:" "$ROOT/package.json"
  fi
}

# Mỗi hệ sinh thái một hàm dò riêng: in lệnh cho task $1 rồi return 0, hoặc return 1 nếu
# hệ sinh thái này không nhận task đó. Tách ra vì `detected_cmd` gộp cả năm từng ở CC 18 — trên
# trần 12 mà `scripts/check-shell-complexity.sh` cưỡng chế; thêm một hệ sinh thái nữa là thêm
# một hàm + một dòng trong danh sách dưới, không phải thêm một nhánh vào hàm đã quá tải.
# Tên script npm hay gặp cho cùng một task (thứ tự = ưu tiên). Bản cũ chỉ nhận đúng `typecheck` trong khi
# chính khung dạy `npm run type-check` (CLAUDE.md §5) → cổng bỏ qua type-check ÂM THẦM (audit 2026-09-23, T4).
_node_aliases() {
  case "$1" in
    typecheck) echo "typecheck type-check tsc check-types" ;;
    lint)      echo "lint check" ;;
    format)    echo "format fmt prettier" ;;
    *)         echo "$1" ;;
  esac
}
_cmd_node() {
  [ -f "$ROOT/package.json" ] || return 1
  local s
  for s in $(_node_aliases "$1"); do
    node_has_script "$s" && { echo "$(node_pm) run $s"; return 0; }
  done
  return 1
}
_cmd_python() {
  py_present || return 1
  local t
  case "$1" in
    format)    t="$(py_tool ruff)" && { echo "$t format ."; return 0; }
               t="$(py_tool black)" && { echo "$t ."; return 0; } ;;
    lint)      t="$(py_tool ruff)" && { echo "$t check ."; return 0; } ;;
    typecheck) t="$(py_tool mypy)" && { echo "$t ."; return 0; }
               t="$(py_tool pyright)" && { echo "$t"; return 0; } ;;
    test)      t="$(py_tool pytest)" && { echo "$t -q"; return 0; } ;;
  esac
  return 1
}
_cmd_go() {
  [ -f "$ROOT/go.mod" ] || return 1
  case "$1" in
    format) echo "gofmt -l -w ." ;;
    lint)   echo "go vet ./..." ;;
    test)   echo "go test ./..." ;;
    build)  echo "go build ./..." ;;
    *)      return 1 ;;
  esac
}
_cmd_rust() {
  [ -f "$ROOT/Cargo.toml" ] || return 1
  case "$1" in
    format)    echo "cargo fmt" ;;
    lint)      echo "cargo clippy -- -D warnings" ;;
    typecheck) echo "cargo check" ;;
    test)      echo "cargo test" ;;
    build)     echo "cargo build" ;;
    *)         return 1 ;;
  esac
}
# ── Stack thêm 2026-09-23 (CLAUDE.md §0b "mọi loại dự án" — trước đó tuyên bố mà dev-task no-op) ──
_cmd_java() {   # Maven / Gradle (Java, Kotlin)
  if [ -f "$ROOT/pom.xml" ]; then
    case "$1" in build) echo "mvn -q -B compile" ;; test) echo "mvn -q -B test" ;; lint) echo "mvn -q -B verify -DskipTests" ;; *) return 1 ;; esac
  elif [ -f "$ROOT/build.gradle" ] || [ -f "$ROOT/build.gradle.kts" ]; then
    local g="./gradlew"; [ -x "$ROOT/gradlew" ] || g="gradle"
    case "$1" in build) echo "$g build -x test" ;; test) echo "$g test" ;; lint) echo "$g check -x test" ;; *) return 1 ;; esac
  else return 1; fi
}
_cmd_dotnet() {
  local f found=0; for f in "$ROOT"/*.sln "$ROOT"/*.csproj "$ROOT"/*.fsproj; do [ -e "$f" ] && { found=1; break; }; done   # `ls a b c` thoát ≠0 nếu MỘT glob không khớp
  [ "$found" -eq 1 ] || return 1
  case "$1" in
    format) echo "dotnet format" ;;
    lint)   echo "dotnet format --verify-no-changes" ;;
    build)  echo "dotnet build --nologo -warnaserror" ;;
    test)   echo "dotnet test --nologo" ;;
    *)      return 1 ;;
  esac
}
_cmd_dart() {
  [ -f "$ROOT/pubspec.yaml" ] || return 1
  local t="dart test"; command -v flutter >/dev/null 2>&1 && grep -q "^  flutter:" "$ROOT/pubspec.yaml" 2>/dev/null && t="flutter test"
  case "$1" in
    format)    echo "dart format --set-exit-if-changed ." ;;
    lint|typecheck) echo "dart analyze --fatal-infos" ;;
    test)      echo "$t" ;;
    *)         return 1 ;;
  esac
}
_cmd_php() {
  [ -f "$ROOT/composer.json" ] || return 1
  case "$1" in
    lint) [ -x "$ROOT/vendor/bin/phpstan" ] && echo "vendor/bin/phpstan analyse --no-progress" || echo "php -l \$(git ls-files '*.php')" ;;
    test) [ -x "$ROOT/vendor/bin/phpunit" ] && echo "vendor/bin/phpunit" || echo "composer test" ;;
    *)    return 1 ;;
  esac
}
_cmd_ruby() {
  [ -f "$ROOT/Gemfile" ] || return 1
  case "$1" in
    lint)   echo "bundle exec rubocop" ;;
    format) echo "bundle exec rubocop -a" ;;
    test)   [ -d "$ROOT/spec" ] && echo "bundle exec rspec" || echo "bundle exec rake test" ;;
    *)      return 1 ;;
  esac
}
_cmd_elixir() {
  [ -f "$ROOT/mix.exs" ] || return 1
  case "$1" in
    format) echo "mix format" ;;
    lint)   echo "mix format --check-formatted" ;;
    build)  echo "mix compile --warnings-as-errors" ;;
    test)   echo "mix test" ;;
    *)      return 1 ;;
  esac
}
_cmd_deno() {
  [ -f "$ROOT/deno.json" ] || [ -f "$ROOT/deno.jsonc" ] || return 1
  case "$1" in
    format)    echo "deno fmt" ;;
    lint)      echo "deno lint" ;;
    typecheck) echo "deno check ." ;;
    test)      echo "deno test" ;;
    *)         return 1 ;;
  esac
}
_cmd_swift() {
  [ -f "$ROOT/Package.swift" ] || return 1
  case "$1" in
    build) echo "swift build" ;;
    test)  echo "swift test" ;;
    *)     return 1 ;;
  esac
}
_cmd_make() {
  [ -f "$ROOT/Makefile" ] && grep -Eq "^$1:" "$ROOT/Makefile" || return 1
  echo "make $1"
}

detected_cmd() {
  # In ra lệnh tự-dò cho task $1, hoặc rỗng nếu không dò được.
  # THỨ TỰ LÀ HÀNH VI: Node trước (script khai trong package.json thắng mọi suy đoán khác),
  # rồi Python/Go/Rust, Makefile cuối cùng (chỉ khớp khi có target trùng tên).
  # Deno trước Node: dự án Deno có thể có package.json (npm compat) nhưng deno.json mới là nguồn.
  local eco
  for eco in _cmd_deno _cmd_node _cmd_python _cmd_go _cmd_rust _cmd_java _cmd_dotnet _cmd_dart _cmd_php _cmd_ruby _cmd_elixir _cmd_swift _cmd_make; do
    "$eco" "$1" && return 0
  done
  return 0
}

resolve() {
  local c; c="$(declared_cmd "$1")" || return 2; [ -n "$c" ] && { echo "$c"; return 0; }
  detected_cmd "$1"
}

run_task() {
  local cmd; cmd="$(resolve "$1")" || return 2
  if [ -z "$cmd" ]; then log "skip: chưa cấu hình/dò được '$1'"; return 0; fi
  log "run [$1]: $cmd"
  ( cd "$ROOT" && bash -c "$cmd" )
}

# --- format-file: format ĐÚNG file vừa sửa (dùng cho auto-format hook) --------
declared_format_file() {
  [ -f "$DECL" ] || return 0
  # shellcheck source=/dev/null  # như trên: đường dẫn chỉ có ở dự án đích
  ( set +u; . "$DECL" >/dev/null 2>&1; printf '%s' "${format_file:-}" )
}
resolve_format_file() {
  local p="$1" tmpl ext
  tmpl="$(declared_format_file)"
  if [ -n "$tmpl" ]; then
    # Placeholder là một đối số độc lập: {}, "{}" hoặc '{}'. Chỉ thay shell
    # tin cậy bằng "$1"; filename được truyền riêng, không ghép vào shell source.
    tmpl="${tmpl//\'\{\}\'/\"\$1\"}"
    tmpl="${tmpl//\"\{\}\"/\"\$1\"}"
    printf '%s' "${tmpl//\{\}/\"\$1\"}"; return 0
  fi
  ext="${p##*.}"
  case "$ext" in
    js|jsx|ts|tsx|mjs|cjs|json|css|scss|md|mdx|html|yaml|yml)
      if command -v npx >/dev/null 2>&1 && [ -f "$ROOT/package.json" ]; then
        echo 'npx --no-install prettier --write "$1"'; return 0; fi ;;
    py)
      command -v ruff  >/dev/null 2>&1 && { echo 'ruff format "$1"'; return 0; }
      command -v black >/dev/null 2>&1 && { echo 'black "$1"'; return 0; } ;;
    go)  command -v gofmt   >/dev/null 2>&1 && { echo 'gofmt -w "$1"'; return 0; } ;;
    rs)  command -v rustfmt >/dev/null 2>&1 && { echo 'rustfmt "$1"'; return 0; } ;;
  esac
  return 0
}

# --- Contract kiểm chứng: thiếu kiểm tra là BLOCKED, không phải PASS ----------
nonblank() { [[ "$1" == *[![:space:]]* ]]; }
blocked() { GATE_REASON="$*"; log "BLOCKED: $*"; return 2; }

# --- Vân tay cây làm việc (LD-03): bằng chứng gắn đúng nội dung đã kiểm ------
# Chỉ đọc (không ghi object vào .git): diff mọi file đã theo dõi so với HEAD + băm từng file
# chưa theo dõi không bị ignore. Bắt được sửa chưa commit mà HEAD thuần bỏ sót.
tracked_diff_id() {
  local base
  base="$(git -C "$ROOT" rev-parse -q --verify HEAD)" || base="$(git -C "$ROOT" mktree </dev/null)" || return 2
  git -C "$ROOT" -c core.safecrlf=false diff --no-ext-diff --no-textconv --binary "$base" -- . \
    | git -C "$ROOT" hash-object --stdin
}
untracked_listing() {  # "<hash> <path>" mỗi dòng, theo thứ tự của git ls-files
  local files hashes f h
  files="$(git -C "$ROOT" -c core.quotepath=off ls-files -o --exclude-standard -- .)" || return 2
  [ -n "$files" ] || return 0
  hashes="$(printf '%s\n' "$files" | git -C "$ROOT" hash-object --no-filters --stdin-paths)" || return 2
  while IFS= read -r f <&3 && IFS= read -r h <&4; do printf '%s %s\n' "$h" "$f"; done 3<<<"$files" 4<<<"$hashes"
}
worktree_snapshot() {  # đặt WT_TRACKED (no-git nếu ngoài repo) và WT_UNTRACKED
  WT_TRACKED=no-git; WT_UNTRACKED=''
  git -C "$ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1 || return 0
  WT_TRACKED="$(tracked_diff_id)" && WT_UNTRACKED="$(untracked_listing)"
}
worktree_id() {
  [ "$WT_TRACKED" = no-git ] && { printf 'no-git'; return 0; }
  printf '%s\n%s\n' "$WT_TRACKED" "$WT_UNTRACKED" | git -C "$ROOT" hash-object --stdin
}
lines_missing() {  # in các dòng có trong $1 mà không có trong $2
  [ -n "$1" ] || return 0
  OTHER="$2" awk 'BEGIN { n = split(ENVIRON["OTHER"], a, "\n"); for (i = 1; i <= n; i++) seen[a[i]] = 1 }
    !($0 in seen)' <<<"$1"
}
worktree_unchanged_since() {  # $1/$2 = snapshot trước khi chạy
  # File ĐÃ THEO DÕI (mã nguồn) đổi → BLOCKED. File chưa theo dõi sinh/ghi lại/xoá trong lúc chạy gần như luôn
  # là output build chưa ignore (__pycache__, dist/) → chỉ cảnh báo kèm tên; evidence ghi trạng thái SAU.
  local tracked="$1" untracked="$2" touched
  worktree_snapshot || { blocked 'không đọc được working tree sau khi kiểm'; return 2; }
  if [ "$tracked" != "$WT_TRACKED" ]; then
    blocked "working tree đổi trong khi kiểm tra (file đã theo dõi bị sửa/xoá); kết quả không thuộc về một phiên bản — chạy lại"
    return 2
  fi
  touched="$({ lines_missing "$WT_UNTRACKED" "$untracked"; lines_missing "$untracked" "$WT_UNTRACKED"; } | cut -d' ' -f2- | sort -u)"
  GATE_UNTRACKED_TOUCHED="$touched"
  nonblank "$touched" && log "WARN: kiểm tra sinh/ghi lại file chưa ignore (nên thêm vào .gitignore): $(printf '%s' "$touched" | head -n 5 | tr '\n' ' ')"
  return 0
}

# --- Lệnh giả và zero-test: PASS của chúng không chứng minh điều gì ----------
noop_command() {  # lệnh chỉ gồm true / : / echo / printf / exit 0 thì không kiểm gì cả
  local c="$1"
  c="${c#"${c%%[![:space:]]*}"}"; c="${c%"${c##*[![:space:]]}"}"; c="${c%;}"
  # Có toán tử shell (ống, &&, ;, chuyển hướng, $(…)) thì có thể là phép kiểm thật: không đoán.
  [[ "$c" == *[\|\&\;\<\>\`]* || "$c" == *'$('* ]] && return 1
  [[ "$c" =~ ^(true|:|echo|printf)([[:space:]].*)?$ || "$c" =~ ^exit([[:space:]]+0)?$ ]]
}
command_is_real() {  # $1=task $2=command
  if noop_command "$2"; then
    blocked "'$1' là lệnh no-op ('$2'); khai lệnh kiểm thật hoặc gate_skip_${1}_reason được review"; return 2
  fi
  if [ "$1" = test ] && [[ "$2" =~ --passWithNoTests|--pass-with-no-tests ]]; then
    blocked "'test' cho phép xanh khi 0 ca (passWithNoTests); bỏ cờ, hoặc N/A có lý do nếu thật sự không có test"; return 2
  fi
}
count_cases() {  # tổng nhóm bắt số đầu tiên của gate_test_count_regex trên output; không khớp → 0
  local line n total=0
  while IFS= read -r line; do
    [[ "$line" =~ $GATE_COUNT_RE ]] || continue
    n="${BASH_REMATCH[1]:-}"   # lưu trước: phép =~ kế tiếp ghi đè BASH_REMATCH
    [[ "$n" =~ ^[0-9]+$ ]] && total=$((total + 10#$n))
  done <"$1"
  printf '%s' "$total"
}
gate_context() {
  local config=absent head=no-commit
  if [ -f "$DECL" ]; then config="$(git hash-object --no-filters "$DECL")" || return 2; fi
  head="$(git -C "$ROOT" rev-parse --verify HEAD 2>/dev/null)" || head=no-commit
  printf '%s:%s' "$head" "$config"
}
gate_tools_ready() {
  local tools modules tool
  local -a tool_list module_list
  tools="$(declared_cmd gate_tools)" || { blocked 'không đọc được gate_tools'; return 2; }
  read -r -a tool_list <<<"bash git jq ${tools//$'\n'/ }"
  for tool in "${tool_list[@]}"; do
    command -v "$tool" >/dev/null 2>&1 || { blocked "thiếu công cụ '$tool'"; return 2; }
  done
  modules="$(declared_cmd gate_python_modules)" || { blocked 'không đọc được gate_python_modules'; return 2; }
  if nonblank "$modules"; then
    command -v python3 >/dev/null 2>&1 || { blocked 'thiếu python3 cho module checks'; return 2; }
    read -r -a module_list <<<"${modules//$'\n'/ }"
    python3 -c 'import importlib.util,sys; sys.exit(any(importlib.util.find_spec(m) is None for m in sys.argv[1:]))' "${module_list[@]}" \
      || { blocked "thiếu hoặc không nạp được Python module: $modules"; return 2; }
  fi
}
gate_add_task() {
  local task="$1" cmd reason
  cmd="$(resolve "$task")" || { blocked "không đọc được command '$task'"; return 2; }
  reason="$(declared_cmd "gate_skip_${task}_reason")" || { blocked "không đọc được lý do N/A '$task'"; return 2; }
  if nonblank "$reason"; then
    if nonblank "$cmd"; then blocked "'$task' vừa có command vừa có lý do N/A — phải review lại"; return 2; fi
    log "N/A [$task]: $reason"
    GATE_NA+="$task"$'\t'"${reason//[$'\t\n']/ }"$'\n'
    return 0
  fi
  nonblank "$cmd" || { blocked "chưa cấu hình '$task'; khai command hoặc gate_skip_${task}_reason được review"; return 2; }
  bash -n -c "$cmd" || { blocked "command '$task' sai cú pháp Bash"; return 2; }
  command_is_real "$task" "$cmd" || return 2
  GATE_NAMES+=("$task"); GATE_COMMANDS+=("$cmd")
}
gate_count_ready() {
  GATE_COUNT_RE="$(declared_cmd gate_test_count_regex)" || { blocked 'không đọc được gate_test_count_regex'; return 2; }
  nonblank "$GATE_COUNT_RE" || return 0
  [[ "" =~ $GATE_COUNT_RE ]]; [ "$?" -ne 2 ] || { blocked 'gate_test_count_regex không phải ERE hợp lệ'; return 2; }
}
gate_preflight() {
  local task after
  GATE_NAMES=(); GATE_COMMANDS=(); GATE_NA=''
  command -v git >/dev/null 2>&1 || { blocked 'thiếu git'; return 2; }
  # Chống đệ quy (2026-10-08, TRAPS mục 52): gate lồng nhau TRÊN CÙNG ROOT là một lệnh con kế thừa
  # CLAUDE_PROJECT_DIR (hook pre-commit-gate đặt biến này) rồi gọi lại chính gate này → treo vô hạn.
  # ROOT khác (fixture của test, dự án đích trong smoke test) vẫn hợp lệ.
  if [ "${DEV_TASK_GATE_ROOT:-}" = "$ROOT" ]; then
    blocked "gate lồng nhau trên cùng ROOT '$ROOT' — lệnh con kế thừa CLAUDE_PROJECT_DIR; đặt CLAUDE_PROJECT_DIR trỏ đúng dự án con"; return 2
  fi
  export DEV_TASK_GATE_ROOT="$ROOT"
  GATE_CONTEXT="$(gate_context)" || { blocked 'không đọc được context'; return 2; }
  if [ -f "$DECL" ]; then
    bash -n "$DECL" || { blocked 'project-commands.sh sai cú pháp'; return 2; }
  fi
  gate_tools_ready || return 2
  for task in build typecheck lint test; do gate_add_task "$task" || return 2; done
  [ "${#GATE_NAMES[@]}" -gt 0 ] || { blocked 'không có kiểm tra thực thi nào'; return 2; }
  gate_count_ready || return 2
  after="$(gate_context)" || return 2
  [ "$GATE_CONTEXT" = "$after" ] || { blocked 'HEAD/config đổi trong tiền kiểm'; return 2; }
}

# --- Evidence máy đọc (LD-03): gate tự ghi, không nhận lời PASS tự khai -------
now_utc() { date -u +%Y-%m-%dT%H:%M:%SZ; }
evidence_prepare() {  # $1=path; BLOCKED nếu file evidence làm bẩn chính cây đang kiểm
  local dir rc
  GATE_EVIDENCE_PATH=''   # chỉ nhận đường dẫn sau khi kiểm xong — không bao giờ xoá nhầm file nguồn
  [ -n "$1" ] || return 0
  [ ! -d "$1" ] || { blocked "evidence phải là file, không phải thư mục: $1"; return 2; }
  dir="$(cd "$(dirname -- "$1")" 2>/dev/null && pwd)" || { blocked "thư mục evidence không tồn tại: $1"; return 2; }
  if [ "$WT_TRACKED" != no-git ]; then
    git -C "$ROOT" check-ignore -q -- "$dir/$(basename -- "$1")" 2>/dev/null; rc=$?
    [ "$rc" -ne 1 ] || { blocked "file evidence '$1' nằm trong cây đang kiểm mà không bị ignore — đặt ngoài repo hoặc trong thư mục đã ignore"; return 2; }
  fi   # rc 0 = đã ignore, 128 = nằm ngoài repo
  rm -f -- "$1" || { blocked "không xoá được evidence cũ: $1"; return 2; }
  GATE_EVIDENCE_PATH="$1"
}
check_json() {  # $1=task → một phần tử JSON theo trạng thái đã ghi
  local task="$1" i
  if [[ $'\n'"$GATE_NA" == *$'\n'"$task"$'\t'* ]]; then
    jq -cn --arg t "$task" --arg r "$(printf '%s\n' "$GATE_NA" | grep "^$task"$'\t' | cut -f2-)" '{task:$t, status:"N/A", reason:$r}'
    return
  fi
  for i in "${!GATE_NAMES[@]}"; do
    [ "${GATE_NAMES[$i]}" = "$task" ] || continue
    jq -cn --arg t "$task" --arg c "${GATE_COMMANDS[$i]}" --arg s "${GATE_STATUS[$i]:-NOT_RUN}" \
      --argjson rc "${GATE_RC[$i]:-null}" --argjson sec "${GATE_SECS[$i]:-null}" \
      '{task:$t, status:$s, command:$c, exit_code:$rc, seconds:$sec}'
    return
  done
  jq -cn --arg t "$task" '{task:$t, status:"NOT_RUN"}'
}
evidence_finish() {  # $1=PASS|FAIL|BLOCKED — ghi nguyên tử; jq là công cụ bắt buộc của gate
  local status="$1" path="${GATE_EVIDENCE_PATH:-}" tmp checks task head config
  [ -n "$path" ] || return 0
  command -v jq >/dev/null 2>&1 || { blocked "thiếu jq để ghi evidence: $path"; return 2; }
  checks="$(for task in build typecheck lint test; do check_json "$task" || exit 2; done | jq -cs .)" \
    || { blocked "không tạo được nội dung evidence: $path"; return 2; }
  head="${GATE_CONTEXT%%:*}"; config="${GATE_CONTEXT#*:}"
  tmp="$path.tmp.$$"
  jq -n --arg st "$status" --arg reason "${GATE_REASON:-}" --arg head "$head" --arg config "$config" \
    --arg wt "$(worktree_id)" --arg started "$GATE_STARTED" --arg finished "$(now_utc)" \
    --argjson checks "$checks" --argjson cases "${GATE_TEST_CASES:-null}" \
    --arg created "${GATE_UNTRACKED_TOUCHED:-}" \
    '{schema:"gate-evidence/1", producer:"scripts/dev-task.sh gate", status:$st,
      reason:(if $reason == "" then null else $reason end), head:$head, config_sha:$config, worktree:$wt,
      started_at:$started, finished_at:$finished, checks:$checks, test_cases:$cases,
      untracked_changed_during_run:($created | split("\n") | map(select(. != "")))}' >"$tmp" && [ ! -d "$path" ] && mv -f "$tmp" "$path" \
    || { rm -f "$tmp"; blocked "không ghi được evidence: $path"; return 2; }
}

run_check() {  # $1=index; ghi trạng thái/exit/thời gian; return 1 khi FAIL
  local i="$1" start=$SECONDS rc out
  log "run [${GATE_NAMES[$i]}]: ${GATE_COMMANDS[$i]}"
  if [ "${GATE_NAMES[$i]}" = test ] && nonblank "$GATE_COUNT_RE"; then
    out="$(mktemp)" || { blocked 'không tạo được file tạm để đếm ca test'; return 2; }
    (cd "$ROOT" && bash -e -o pipefail -c "${GATE_COMMANDS[$i]}") 2>&1 | tee "$out"; rc=${PIPESTATUS[0]}
    [ "$rc" -ne 0 ] || GATE_TEST_CASES="$(count_cases "$out")"
    rm -f "$out"
  else
    (cd "$ROOT" && bash -e -o pipefail -c "${GATE_COMMANDS[$i]}"); rc=$?
  fi
  GATE_RC[i]=$rc; GATE_SECS[i]=$((SECONDS - start)); GATE_STATUS[i]=PASS
  if [ "$rc" -ne 0 ]; then
    GATE_STATUS[i]=FAIL; GATE_REASON="kiểm tra '${GATE_NAMES[$i]}' thất bại (exit $rc)"
  elif [ "${GATE_TEST_CASES:-}" = 0 ]; then
    GATE_STATUS[i]=FAIL; GATE_REASON="kiểm tra 'test' chạy 0 ca (gate_test_count_regex không khớp số > 0)"
  fi
  [ "${GATE_STATUS[$i]}" = PASS ] || { log "FAIL: ${GATE_REASON}"; return 1; }
}
run_checks() {
  local i after before_tracked="$WT_TRACKED" before_untracked="$WT_UNTRACKED"
  for i in "${!GATE_NAMES[@]}"; do run_check "$i" || return "$?"; done
  after="$(gate_context)" || { blocked 'không đọc được context sau khi kiểm'; return 2; }
  [ "$GATE_CONTEXT" = "$after" ] || { blocked 'HEAD/config đổi trong khi kiểm tra; cần chạy lại'; return 2; }
  worktree_unchanged_since "$before_tracked" "$before_untracked"
}
gate_args() {  # $1=mode, phần còn lại = tuỳ chọn; đặt GATE_EVIDENCE_ARG
  local mode="$1"; shift
  GATE_EVIDENCE_ARG=''; [ "$mode" = gate ] && GATE_EVIDENCE_ARG="${GATE_EVIDENCE:-}"
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --evidence) [ "$mode" = gate ] && [ -n "${2:-}" ] || { blocked '--evidence <file> chỉ dùng với gate'; return 2; }
                  GATE_EVIDENCE_ARG="$2"; shift 2 ;;
      *) blocked "tham số không hợp lệ: $1"; return 2 ;;
    esac
  done
}
verify_contract() {
  local mode="$1" rc
  GATE_STARTED="$(now_utc)"; GATE_REASON=''; GATE_TEST_CASES=''; GATE_UNTRACKED_TOUCHED=''; GATE_EVIDENCE_PATH=''
  GATE_STATUS=(); GATE_RC=(); GATE_SECS=(); GATE_NAMES=(); GATE_COMMANDS=(); GATE_CONTEXT=':'
  gate_args "$@" || return 2
  worktree_snapshot || { blocked 'không đọc được working tree'; return 2; }
  evidence_prepare "$GATE_EVIDENCE_ARG" || return 2
  gate_preflight || { evidence_finish BLOCKED; return 2; }
  if [ "$mode" = doctor ]; then
    log "READY: ${#GATE_NAMES[@]} kiểm tra đã cấu hình; chưa chạy, không phải PASS."
    return 0
  fi
  run_checks; rc=$?
  case "$rc" in
    0) evidence_finish PASS || return 2
       log "PASS: ${#GATE_NAMES[@]} kiểm tra đã chạy thành công; context=$GATE_CONTEXT:$(worktree_id)" ;;
    1) evidence_finish FAIL || return 2 ;;
    *) evidence_finish BLOCKED || return 2 ;;
  esac
  return "$rc"
}

# --- evidence-check: đối chiếu evidence với phiên bản HIỆN TẠI ---------------
# Bắt evidence cũ (HEAD/config/working tree đã đổi), evidence thiếu task hoặc không PASS.
# KHÔNG phải chữ ký: file viết tay khớp cây hiện tại vẫn không bị phát hiện — nghiệm thu
# tích hợp dựa trên CI của đúng commit; lệnh này để không tin lời "đã PASS" cũ/thiếu.
evidence_current_mismatch() {  # $1=file → in tên trường lệch so với hiện tại
  local field want got
  for field in head config_sha worktree; do
    want="$(jq -r ".$field" "$1")"
    case "$field" in
      head) got="${GATE_CONTEXT%%:*}" ;;
      config_sha) got="${GATE_CONTEXT#*:}" ;;
      worktree) got="$(worktree_id)" ;;
    esac
    [ "$want" = "$got" ] || printf '%s ' "$field"
  done
}
evidence_check() {
  local f="${1:-}" status stale
  [ -n "$f" ] && [ -f "$f" ] || { blocked "không có file evidence: ${f:-<thiếu đường dẫn>}"; return 2; }
  command -v jq >/dev/null 2>&1 || { blocked 'thiếu jq để đọc evidence'; return 2; }
  jq -e '.schema == "gate-evidence/1"' "$f" >/dev/null 2>&1 || { blocked "evidence hỏng hoặc sai schema: $f"; return 2; }
  status="$(jq -r .status "$f")"
  [ "$status" = PASS ] || { log "REJECTED: evidence không phải PASS (status=$status)"; return 1; }
  jq -e '([.checks[].task] == ["build","typecheck","lint","test"])
    and all(.checks[]; .status == "PASS" or (.status == "N/A" and (.reason // "") != ""))
    and any(.checks[]; .status == "PASS")' "$f" >/dev/null \
    || { log 'INCOMPLETE: evidence phải có đủ build/typecheck/lint/test, mỗi task PASS hoặc N/A có lý do'; return 1; }
  [ "$(jq -r .worktree "$f")" != no-git ] || { blocked 'evidence tạo ngoài git — không gắn được phiên bản'; return 2; }
  GATE_CONTEXT="$(gate_context)" && worktree_snapshot || { blocked 'không đọc được phiên bản hiện tại'; return 2; }
  stale="$(evidence_current_mismatch "$f")"
  [ -z "$stale" ] || { log "STALE: evidence không thuộc phiên bản hiện tại (lệch: $stale) — chạy lại gate"; return 1; }
  log "VERIFIED: evidence PASS khớp HEAD/config/working tree hiện tại. Không phải chữ ký; CI của đúng commit là nguồn nghiệm thu tích hợp."
}

# --- review-check: finding phải có căn cứ, repair theo đúng nguyên nhân (LD-04) --
# Schema review-findings/1: {findings:[{id,kind,location,scenario,evidence}]}. kind:
#   defect           → REPAIR-CODE: lỗi code thật; bắt buộc path:line có trong repo, test đỏ trước khi sửa
#   missing-evidence → RERUN-EVIDENCE: bằng chứng thiếu/cũ (vd evidence-check STALE) — chạy lại, KHÔNG sửa code
#   missing-input    → ASK-UPSTREAM: spec/AC/thiết kế thiếu — hỏi hoặc sửa tầng trên, KHÔNG sửa code
#   cleanup          → OPTIONAL: gợi ý không chặn
# Finding thiếu kịch bản/bằng chứng, kind lạ, hoặc defect không trỏ được dòng có thật → UNSUPPORTED (exit 1).
location_exists() {  # $1=path:line → true nếu path nằm trong ROOT và có dòng đó
  local path="${1%:*}" line="${1##*:}" n
  case "$path" in ''|/*|../*|*/../*) return 1 ;; esac
  [[ "$line" =~ ^[1-9][0-9]*$ ]] && [ -f "$ROOT/$path" ] || return 1
  n="$(awk 'END { print NR }' "$ROOT/$path")"; [ "$line" -le "$n" ]
}
review_action() {  # $1=kind $2=location → nhãn hành động; rỗng nếu finding không có căn cứ
  case "$1" in
    defect) location_exists "$2" && echo REPAIR-CODE ;;
    missing-evidence) echo RERUN-EVIDENCE ;;
    missing-input) echo ASK-UPSTREAM ;;
    cleanup) echo OPTIONAL ;;
  esac
}
review_check() {
  local f="${1:-}" id kind loc action rejected=0 total=0
  [ -n "$f" ] && [ -f "$f" ] || { blocked "không có file findings: ${f:-<thiếu đường dẫn>}"; return 2; }
  command -v jq >/dev/null 2>&1 || { blocked 'thiếu jq để đọc findings'; return 2; }
  jq -e '.schema == "review-findings/1" and (.findings | type == "array")' "$f" >/dev/null 2>&1 \
    || { blocked "findings hỏng hoặc sai schema (cần review-findings/1): $f"; return 2; }
  while IFS=$'\x1f' read -r id kind loc; do   # \x1f không phải khoảng trắng: trường rỗng không bị gộp
    total=$((total + 1)); action="$(review_action "$kind" "$loc")"
    [ "$id" != '-' ] && [ -n "$action" ] || { rejected=$((rejected + 1)); log "UNSUPPORTED $id: thiếu căn cứ (kind/kịch bản/bằng chứng/path:line có thật)"; continue; }
    log "$action $id${loc:+ @ $loc}"
  done < <(jq -r '.findings[] | [(if ((.id // "") | tostring) == "" then "-" else .id end),
      (if ((.scenario // "") | length) > 0 and ((.evidence // "") | length) > 0 then (.kind // "") else "" end),
      (.location // "")] | map(tostring | gsub("[\u001f\r\n]"; " ")) | join("\u001f")' "$f" | tr -d '\r')
  # tr: jq trên Windows in CRLF; `$(...)` của Git Bash bỏ \r nhưng `read` từ process substitution thì không.
  [ "$rejected" -eq 0 ] || { log "REJECTED: $rejected/$total finding không có căn cứ — bổ sung bằng chứng, không sửa code theo chúng"; return 1; }
  [ "$total" -gt 0 ] || log 'CLEAN: không có finding'
}

# --- Điều phối ---------------------------------------------------------------
case "$TASK" in
  --print)
    T="${2:-}"; case "$T" in format|lint|typecheck|test|build) ;; *) log "--print: cần tên task hợp lệ"; exit 2 ;; esac
    C="$(resolve "$T")" || exit 2; [ -n "$C" ] && printf '%s\n' "$C"; exit 0 ;;
  format|lint|typecheck|test|build)
    run_task "$TASK"; exit $? ;;
  format-file)
    P="${2:-}"; [ -n "$P" ] || { log "format-file: thiếu path"; exit 0; }
    case "$P" in -*) P="./$P" ;; esac   # filename không trở thành cờ formatter
    C="$(resolve_format_file "$P")"
    [ -n "$C" ] || { log "skip format-file: không có per-file formatter cho '$P'"; exit 0; }
    log "format-file: $C"; ( cd "$ROOT" && bash -c "$C" bash "$P" ) || true
    exit 0 ;;
  gate|doctor)
    verify_contract "$@"; exit $? ;;
  evidence-check)
    evidence_check "${2:-}"; exit $? ;;
  review-check)
    review_check "${2:-}"; exit $? ;;
  *)
    log "task không hợp lệ: '$TASK' (format|lint|typecheck|test|build|gate|doctor|evidence-check|review-check)"; exit 2 ;;
esac
