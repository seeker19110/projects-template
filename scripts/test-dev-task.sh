#!/usr/bin/env bash
# test-dev-task.sh — dev-task.sh phải PHÂN GIẢI ĐÚNG LỆNH cho từng stack (không chỉ "chạy không crash").
#
# VÌ SAO (audit 2026-09-23, T4): cổng commit của dự án Node điển hình bỏ qua type-check ÂM THẦM vì
# dev-task chỉ nhận script tên đúng `typecheck` trong khi khung dạy `type-check`; Python không dò venv
# nên chạy nhầm binary toàn cục hoặc no-op; Bun ≥ 1.2 (`bun.lock`) bị coi là npm; 8 stack CLAUDE.md §0b
# tuyên bố hỗ trợ nhưng dev-task no-op. Không test nào đo `resolve()` → cổng xanh giả không ai thấy.
# Dùng `dev-task.sh --print <task>` (chỉ in lệnh) trên fixture tối thiểu từng stack, binary giả trong PATH.
#
# Chạy: bash scripts/test-dev-task.sh
set -uo pipefail   # cố ý KHÔNG -e (docs/CONVENTIONS.md §A)

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DT="$ROOT/scripts/dev-task.sh"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
# shellcheck source=scripts/_test-lib.sh
source "$ROOT/scripts/_test-lib.sh"

FAKEBIN="$WORK/bin"; mkdir -p "$FAKEBIN"
for b in ruff mypy pytest uv poetry flutter; do printf '#!/usr/bin/env bash\nexit 0\n' > "$FAKEBIN/$b"; chmod +x "$FAKEBIN/$b"; done
export PATH="$FAKEBIN:$PATH"

fx() {   # fx <tên> → thư mục fixture mới (dev-task cần scripts/ để tính ROOT qua CLAUDE_PROJECT_DIR)
  local d="$WORK/$1"; mkdir -p "$d"; printf '%s' "$d"
}
resolve() { CLAUDE_PROJECT_DIR="$1" bash "$DT" --print "$2" 2>/dev/null; }
expect() { # expect <fixture> <task> <chuỗi mong đợi> <mô tả>
  local got; got="$(resolve "$1" "$2")"
  if [ "$got" = "$3" ]; then ok "$4 → '$got'"; else bad "$4: mong '$3', được '$got'"; fi
}

echo "== 1. Node: alias script + trình quản lý gói theo lockfile =="
d="$(fx node1)"; printf '{"scripts":{"type-check":"tsc --noEmit","lint":"eslint .","test":"vitest run"}}\n' > "$d/package.json"
expect "$d" typecheck "npm run type-check" "script 'type-check' được nhận cho task typecheck (bản cũ: skip)"
expect "$d" lint "npm run lint" "lint npm"
d="$(fx node2)"; printf '{"scripts":{"tsc":"tsc --noEmit","check":"biome check .","fmt":"biome format --write ."}}\n' > "$d/package.json"; : > "$d/bun.lock"
expect "$d" typecheck "bun run tsc" "alias 'tsc' + Bun ≥ 1.2 (bun.lock dạng text) → bun"
expect "$d" lint "bun run check" "alias 'check' cho lint"
expect "$d" format "bun run fmt" "alias 'fmt' cho format"
d="$(fx node3)"; printf '{"scripts":{"build":"next build"}}\n' > "$d/package.json"; : > "$d/pnpm-lock.yaml"
expect "$d" build "pnpm run build" "pnpm theo pnpm-lock.yaml"
expect "$d" typecheck "" "không có script nào khớp → rỗng (no-op), không bịa lệnh"

echo "== 2. Python: venv / uv / poetry / PATH, marker requirements.txt =="
d="$(fx py1)"; : > "$d/requirements.txt"; mkdir -p "$d/.venv/bin"; printf '#!/usr/bin/env bash\nexit 0\n' > "$d/.venv/bin/ruff"; chmod +x "$d/.venv/bin/ruff"
expect "$d" lint "$d/.venv/bin/ruff check ." "requirements.txt là marker; ruff trong .venv được ưu tiên hơn PATH"
d="$(fx py2)"; : > "$d/pyproject.toml"; : > "$d/uv.lock"
expect "$d" test "uv run pytest -q" "uv.lock → 'uv run pytest'"
expect "$d" typecheck "uv run mypy ." "uv.lock → 'uv run mypy'"
d="$(fx py3)"; : > "$d/pyproject.toml"; : > "$d/poetry.lock"
expect "$d" format "poetry run ruff format ." "poetry.lock → 'poetry run ruff'"
d="$(fx py4)"; : > "$d/pyproject.toml"
expect "$d" test "pytest -q" "không venv/uv/poetry → PATH"

echo "== 3. Rust typecheck = cargo check (rẻ hơn build) =="
d="$(fx rs)"; : > "$d/Cargo.toml"
expect "$d" typecheck "cargo check" "cargo check"

echo "== 4. 8 stack mới (CLAUDE.md §0b) =="
d="$(fx java)"; : > "$d/pom.xml";              expect "$d" test "mvn -q -B test" "Maven test"
d="$(fx kt)"; : > "$d/build.gradle.kts"; printf '#!/bin/sh\n' > "$d/gradlew"; chmod +x "$d/gradlew"
                                                expect "$d" build "./gradlew build -x test" "Gradle wrapper build"
d="$(fx net)"; : > "$d/App.csproj";           expect "$d" lint "dotnet format --verify-no-changes" ".NET lint = format --verify-no-changes"
                                                expect "$d" test "dotnet test --nologo" ".NET test"
d="$(fx dart)"; printf 'name: x\ndependencies:\n  flutter:\n    sdk: flutter\n' > "$d/pubspec.yaml"
                                                expect "$d" test "flutter test" "Flutter (pubspec có flutter + binary flutter) → flutter test"
                                                expect "$d" lint "dart analyze --fatal-infos" "Dart analyze"
d="$(fx dart2)"; printf 'name: x\n' > "$d/pubspec.yaml"; expect "$d" test "dart test" "Dart thuần → dart test"
d="$(fx php)"; : > "$d/composer.json"; mkdir -p "$d/vendor/bin"; printf '#!/bin/sh\n' > "$d/vendor/bin/phpstan"; chmod +x "$d/vendor/bin/phpstan"
                                                expect "$d" lint "vendor/bin/phpstan analyse --no-progress" "PHP phpstan khi có vendor/bin"
d="$(fx rb)"; : > "$d/Gemfile"; mkdir -p "$d/spec"; expect "$d" test "bundle exec rspec" "Ruby rspec khi có spec/"
d="$(fx ex)"; : > "$d/mix.exs";                expect "$d" build "mix compile --warnings-as-errors" "Elixir build"
d="$(fx deno)"; : > "$d/deno.json"; printf '{"scripts":{"typecheck":"x"}}\n' > "$d/package.json"
                                                expect "$d" typecheck "deno check ." "Deno thắng Node khi cùng có deno.json + package.json"
d="$(fx swift)"; : > "$d/Package.swift";      expect "$d" build "swift build" "Swift build"

echo "== 5. Khai báo (.claude/project-commands.sh) vẫn thắng tự dò; task lạ → exit 2 =="
d="$(fx decl)"; : > "$d/Cargo.toml"; mkdir -p "$d/.claude"; printf 'typecheck="echo KHAI-BAO"\n' > "$d/.claude/project-commands.sh"
expect "$d" typecheck "echo KHAI-BAO" "khai báo thắng tự dò"
CLAUDE_PROJECT_DIR="$d" bash "$DT" --print nope >/dev/null 2>&1; rc=$?
[ "$rc" -eq 2 ] && ok "--print task lạ → exit 2" || bad "--print task lạ → exit $rc"

echo "== 6. NEGATIVE: gỡ alias → ca 1 phải đỏ (test đo thật) =="
tmpdt="$WORK/dev-task-noalias.sh"; sed 's/typecheck) echo "typecheck type-check tsc check-types" ;;/typecheck) echo "typecheck" ;;/' "$DT" > "$tmpdt"
cp "$ROOT/scripts/_stack-detect.sh" "$WORK/_stack-detect.sh"
got="$(CLAUDE_PROJECT_DIR="$WORK/node1" bash "$tmpdt" --print typecheck 2>/dev/null)"
[ -z "$got" ] && ok "negative: không alias → 'type-check' không được nhận (test bắt được)" || bad "negative test không bắt được (được '$got')"

if [ "$fails" -eq 0 ]; then echo "OK — dev-task.sh phân giải đúng lệnh cho 13 stack, alias Node, môi trường Python."; exit 0; fi
echo "FAIL — $fails ca hỏng."; exit 1
