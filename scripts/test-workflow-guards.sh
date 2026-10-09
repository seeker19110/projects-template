#!/usr/bin/env bash
# test-workflow-guards.sh — CHỨNG MINH thân step `protection-guard` (ci.yml) và `Detect project manifest`
# (dependency-review.yml) chạy đúng với API/manifest giả lập: bắt đúng lỗi, không chặn oan.
#
# VÌ SAO TÁCH khỏi `test-check-scripts.sh` (2026-10-09): suite gốc vượt 400 dòng (radar). Hai mục này
# kiểm step trong workflow (trích bằng `step_body`), không kiểm gate script nên tách riêng theo đối tượng.
#
# Chạy: bash scripts/test-workflow-guards.sh
set -uo pipefail   # cố ý KHÔNG -e: một ca lỗi không được làm chết cả lượt chạy (docs/CONVENTIONS.md §A)

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
if command -v cygpath >/dev/null 2>&1; then ROOT="$(cygpath -m "$ROOT")"; fi
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

source "$ROOT/scripts/_test-lib.sh"

bad() {
  echo "  ❌ $1"
  fails=$((fails+1))
  cat "$WORK/check-output" >&2
}

# step_body <tên-step> <file-workflow> <file-ra>: trích thân `run:` của một step trong .github/workflows.
step_body() {
  awk -v name="      - name: $1" '
    $0 == name { found=1; next }
    found && /^        run: \|$/ { body=1; next }
    body && /^      - name:/ { exit }
    body && /^          / { sub(/^          /, ""); print }
  ' "$ROOT/.github/workflows/$2" > "$3"
}

## ============================================================
## 4. protection-guard: tham số strict của ruleset thật
## ============================================================
echo "== 4. protection-guard strict =="

# Chạy đúng thân step CI với phản hồi API giả lập; không gọi GitHub hoặc thay ruleset thật.
step_body "Bảo vệ nhánh đã có hiệu lực chưa" ci.yml "$WORK/protection-guard.sh"
if [ ! -s "$WORK/protection-guard.sh" ]; then
  echo 'không tìm thấy thân step protection-guard' > "$WORK/check-output"
  bad "không thể trích step protection-guard từ ci.yml"
else
  mkdir -p "$WORK/bin"
  cat > "$WORK/bin/curl" <<'EOF'
#!/usr/bin/env bash
cat "$TEST_LIVE_RULES"
EOF
  chmod +x "$WORK/bin/curl"
  for live_strict in true false; do
    jq --argjson strict "$live_strict" \
      '[.rules[] | {type, parameters: ((.parameters // {}) | if has("strict_required_status_checks_policy") then .strict_required_status_checks_policy = $strict else . end)}]' \
      "$ROOT/.github/rulesets/main.json" > "$WORK/live-rules-$live_strict.json"
    (cd "$ROOT" && PATH="$WORK/bin:$PATH" TEST_LIVE_RULES="$WORK/live-rules-$live_strict.json" \
      RUNNER_TEMP="$WORK" GH_TOKEN=test REPO=test/repo BRANCH=main bash "$WORK/protection-guard.sh" \
      > "$WORK/check-output" 2>&1)
    rc=$?
    if [ "$live_strict" = true ]; then
      [ "$rc" = 0 ] && ok "ruleset live strict=true khớp file → xanh" || bad "ruleset khớp bị chặn oan (rc=$rc)"
    else
      [ "$rc" = 1 ] && grep -q 'strict_required_status_checks_policy' "$WORK/check-output" && \
        ok "ruleset live strict=false lệch file → đỏ" || bad "KHÔNG bắt được ruleset strict=false (rc=$rc)"
    fi
  done
fi

## ============================================================
## 5. dependency-review: nhận manifest của khung và monorepo
## ============================================================
echo "== 5. dependency-review manifests =="
step_body "Detect project manifest" dependency-review.yml "$WORK/detect-manifest.sh"
if [ ! -s "$WORK/detect-manifest.sh" ]; then
  echo 'không tìm thấy thân step Detect project manifest' > "$WORK/check-output"
  bad "không thể trích step dependency-review từ workflow"
else
  for manifest in none scripts/requirements-ci.txt packages/api/package.json services/backend/go.mod; do
    d="$WORK/manifest-${manifest//\//-}"
    mkdir -p "$d"
    git -C "$d" init -q
    if [ "$manifest" != none ]; then
      mkdir -p "$d/$(dirname "$manifest")"
      : > "$d/$manifest"
      git -C "$d" add "$manifest"
    fi
    : > "$WORK/github-output"
    (cd "$d" && GITHUB_OUTPUT="$WORK/github-output" bash "$WORK/detect-manifest.sh" \
      > "$WORK/check-output" 2>&1)
    rc=$?
    actual=$(sed -n 's/^exists=//p' "$WORK/github-output" | tail -1)
    expected=true
    [ "$manifest" = none ] && expected=false
    [ "$rc" = 0 ] && [ "$actual" = "$expected" ] && \
      ok "manifest $manifest → exists=$expected" || \
      bad "manifest $manifest: muốn exists=$expected, nhận '$actual' (rc=$rc)"
  done
  d="$WORK/manifest-no-git"
  mkdir -p "$d"
  : > "$WORK/github-output"
  (cd "$d" && GITHUB_OUTPUT="$WORK/github-output" bash "$WORK/detect-manifest.sh" \
    > "$WORK/check-output" 2>&1)
  rc=$?
  if [ "$rc" -ne 0 ] && ! grep -q '^exists=false$' "$WORK/github-output"; then
    ok "git ls-files lỗi → phát hiện manifest đỏ, không skip dependency review"
  else
    bad "git ls-files lỗi nhưng bước phát hiện trả exists=false (rc=$rc)"
  fi
fi


finish "protection-guard và dependency-review bắt đúng lỗi + không chặn oan."
