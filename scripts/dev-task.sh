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
# Task hỗ trợ: format | lint | typecheck | test | build | gate | doctor
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
declared_cmd() {
  # Config là shell tin cậy của dự án, không phải input từ PR/provider chưa review.
  # Shell riêng giữ errexit hoạt động ngay cả khi caller dùng command substitution/if.
  [ -f "$DECL" ] || return 0
  bash -e -o pipefail -c '. "$1" >/dev/null; key="$2"; printf "%s" "${!key-}"' bash "$DECL" "$1"
}

# --- 2) TỰ DÒ theo hệ sinh thái ---------------------------------------------
# shellcheck source=scripts/_stack-detect.sh
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/_stack-detect.sh"   # node_pm, py_present, py_tool (dùng chung với maintenance-sweep)
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
_cmd_dart() {   # Flutter / Dart
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

resolve() { # $1=task -> in lệnh (khai báo ưu tiên), rỗng nếu không có
  local c; c="$(declared_cmd "$1")" || return 2; [ -n "$c" ] && { echo "$c"; return 0; }
  detected_cmd "$1"
}

run_task() { # $1=task -> chạy; 0 nếu ok hoặc no-op, khác 0 nếu lệnh fail
  local cmd; cmd="$(resolve "$1")" || return 2
  if [ -z "$cmd" ]; then log "skip: chưa cấu hình/dò được '$1'"; return 0; fi
  log "run [$1]: $cmd"
  ( cd "$ROOT" && bash -c "$cmd" )
}

# --- format-file: format ĐÚNG file vừa sửa (dùng cho auto-format hook) --------
declared_format_file() {
  [ -f "$DECL" ] || return 0
  # shellcheck source=/dev/null  # như trên: đường dẫn chỉ có ở dự án đích
  ( set +u; . "$DECL" >/dev/null 2>&1; eval "printf '%s' \"\${format_file:-}\"" )
}
resolve_format_file() { # $1=path -> in lệnh format 1 file, rỗng nếu không có per-file formatter
  local p="$1" tmpl ext
  tmpl="$(declared_format_file)"
  if [ -n "$tmpl" ]; then printf '%s' "${tmpl//\{\}/$p}"; return 0; fi
  ext="${p##*.}"
  case "$ext" in
    js|jsx|ts|tsx|mjs|cjs|json|css|scss|md|mdx|html|yaml|yml)
      if command -v npx >/dev/null 2>&1 && [ -f "$ROOT/package.json" ]; then
        echo "npx --no-install prettier --write \"$p\""; return 0; fi ;;
    py)
      command -v ruff  >/dev/null 2>&1 && { echo "ruff format \"$p\""; return 0; }
      command -v black >/dev/null 2>&1 && { echo "black \"$p\"";       return 0; } ;;
    go)  command -v gofmt   >/dev/null 2>&1 && { echo "gofmt -w \"$p\""; return 0; } ;;
    rs)  command -v rustfmt >/dev/null 2>&1 && { echo "rustfmt \"$p\"";  return 0; } ;;
  esac
  return 0
}

# --- Contract kiểm chứng: thiếu kiểm tra là BLOCKED, không phải PASS ----------
nonblank() { [[ "$1" == *[![:space:]]* ]]; }
blocked() { log "BLOCKED: $*"; return 2; }
gate_context() {
  local config=absent head=no-commit
  if [ -f "$DECL" ]; then config="$(git hash-object --no-filters "$DECL")" || return 2; fi
  head="$(git -C "$ROOT" rev-parse --verify HEAD 2>/dev/null)" || head=no-commit
  printf '%s:%s' "$head" "$config"
}
gate_tools_ready() {
  local tools modules tool
  tools="$(declared_cmd gate_tools)" || { blocked 'không đọc được gate_tools'; return 2; }
  for tool in bash git jq $tools; do
    command -v "$tool" >/dev/null 2>&1 || { blocked "thiếu công cụ '$tool'"; return 2; }
  done
  modules="$(declared_cmd gate_python_modules)" || { blocked 'không đọc được gate_python_modules'; return 2; }
  if nonblank "$modules"; then
    command -v python3 >/dev/null 2>&1 || { blocked 'thiếu python3 cho module checks'; return 2; }
    python3 -c 'import importlib.util,sys; sys.exit(any(importlib.util.find_spec(m) is None for m in sys.argv[1:]))' $modules \
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
    return 0
  fi
  nonblank "$cmd" || { blocked "chưa cấu hình '$task'; khai command hoặc gate_skip_${task}_reason được review"; return 2; }
  bash -n -c "$cmd" || { blocked "command '$task' sai cú pháp Bash"; return 2; }
  GATE_NAMES+=("$task"); GATE_COMMANDS+=("$cmd")
}
gate_preflight() {
  local task after
  GATE_NAMES=(); GATE_COMMANDS=()
  command -v git >/dev/null 2>&1 || { blocked 'thiếu git'; return 2; }
  GATE_CONTEXT="$(gate_context)" || { blocked 'không đọc được context'; return 2; }
  if [ -f "$DECL" ]; then
    bash -n "$DECL" || { blocked 'project-commands.sh sai cú pháp'; return 2; }
  fi
  gate_tools_ready || return 2
  for task in build typecheck lint test; do gate_add_task "$task" || return 2; done
  [ "${#GATE_NAMES[@]}" -gt 0 ] || { blocked 'không có kiểm tra thực thi nào'; return 2; }
  after="$(gate_context)" || return 2
  [ "$GATE_CONTEXT" = "$after" ] || { blocked 'HEAD/config đổi trong tiền kiểm'; return 2; }
}
verify_contract() { # doctor chỉ READY; gate chạy command rồi mới được PASS.
  local mode="$1" i after
  gate_preflight || return 2
  if [ "$mode" = doctor ]; then
    log "READY: ${#GATE_NAMES[@]} kiểm tra đã cấu hình; chưa chạy, không phải PASS."
    return 0
  fi
  for i in "${!GATE_NAMES[@]}"; do
    log "run [${GATE_NAMES[$i]}]: ${GATE_COMMANDS[$i]}"
    if ! (cd "$ROOT" && bash -e -o pipefail -c "${GATE_COMMANDS[$i]}"); then
      log "FAIL: kiểm tra '${GATE_NAMES[$i]}' thất bại"; return 1
    fi
  done
  after="$(gate_context)" || return 2
  [ "$GATE_CONTEXT" = "$after" ] || { blocked 'HEAD/config đổi trong khi kiểm tra; cần chạy lại'; return 2; }
  log "PASS: ${#GATE_NAMES[@]} kiểm tra đã chạy thành công; context=$GATE_CONTEXT"
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
    C="$(resolve_format_file "$P")"
    [ -n "$C" ] || { log "skip format-file: không có per-file formatter cho '$P'"; exit 0; }
    log "format-file: $C"; ( cd "$ROOT" && bash -c "$C" ) || true
    exit 0 ;;
  gate|doctor)
    verify_contract "$TASK"; exit $? ;;
  *)
    log "task không hợp lệ: '$TASK' (format|lint|typecheck|test|build|gate|doctor)"; exit 2 ;;
esac
