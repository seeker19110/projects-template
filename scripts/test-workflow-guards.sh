#!/usr/bin/env bash
# test-workflow-guards.sh — CHỨNG MINH thân step `protection-guard` (ci.yml), `Detect project manifest`
# (dependency-review.yml), `Work ID trỏ tới hồ sơ có thật` (pr-policy.yml), `Dò ngôn ngữ repo cho CodeQL`
# (codeql.yml) và `Dò release-type theo manifest` (release.yml) chạy đúng với API/manifest giả lập: bắt đúng lỗi, không chặn oan.
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
# Dừng ở step kế tiếp HOẶC dòng thụt < 10 (step cuối job: không để nuốt `with:` của job sau).
step_body() {
  awk -v name="      - name: $1" '
    $0 == name { found=1; next }
    found && /^        run: \|$/ { body=1; next }
    body && /^      - name:/ { exit }
    body && /[^ ]/ && substr($0, 1, 10) != "          " { exit }
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


## ============================================================
## 6. pr-policy: dòng Work ID trong mô tả PR trỏ tới hồ sơ docs/work có thật
## ============================================================
echo "== 6. pr-policy Work ID =="
step_body "Work ID trỏ tới hồ sơ có thật" pr-policy.yml "$WORK/work-id.sh"
if [ ! -s "$WORK/work-id.sh" ]; then
  echo 'không tìm thấy thân step Work ID' > "$WORK/check-output"
  bad "không thể trích step Work ID từ pr-policy.yml"
else
  d="$WORK/work-id-repo"
  mkdir -p "$d/docs/work/2026-10-09-co-that" "$d/docs/work/2026-10-08-da-xong" "$d/docs/x"
  : > "$d/docs/work/2026-10-09-co-that/working.md"
  : > "$d/docs/work/2026-10-08-da-xong/done.md"
  : > "$d/docs/x/working.md"
  crlf=$'## Issue / Goal\r\n- Work ID: 2026-10-09-co-that\r\n'
  # nhãn|mã thoát mong đợi|thân PR
  while IFS='|' read -r label want body; do
    (cd "$d" && PR_BODY="$(printf '%b' "$body")" bash "$WORK/work-id.sh" > "$WORK/check-output" 2>&1)
    rc=$?
    [ "$rc" = "$want" ] && ok "Work ID $label → rc=$want" || bad "Work ID $label: muốn rc=$want, nhận rc=$rc"
  done <<'EOF'
thiếu dòng|1|## Summary\n- x
để trống như mẫu|1|- Work ID:\n
không có hồ sơ|1|- Work ID: 2026-10-09-khong-co
leo thư mục|1|- Work ID: ../x
sai khuôn|1|- Work ID: Ten_Sai
hồ sơ working.md|0|## Issue / Goal\n- Work ID: 2026-10-09-co-that\n
hồ sơ done.md trong backtick|0|- Work ID: `2026-10-08-da-xong`
EOF
  (cd "$d" && PR_BODY="$crlf" bash "$WORK/work-id.sh" > "$WORK/check-output" 2>&1)
  rc=$?
  [ "$rc" = 0 ] && ok "Work ID thân PR CRLF → rc=0" || bad "Work ID thân PR CRLF chặn oan (rc=$rc)"
fi


## ============================================================
## 7. codeql: matrix ngôn ngữ dò từ GET /repos/{repo}/languages
## ============================================================
echo "== 7. codeql detect languages =="
step_body "Dò ngôn ngữ repo cho CodeQL" codeql.yml "$WORK/codeql-langs.sh"
if [ ! -s "$WORK/codeql-langs.sh" ]; then
  echo 'không tìm thấy thân step Dò ngôn ngữ repo cho CodeQL' > "$WORK/check-output"
  bad "không thể trích step detect từ codeql.yml"
else
  mkdir -p "$WORK/bin-langs"
  cat > "$WORK/bin-langs/curl" <<'EOF'
#!/usr/bin/env bash
[ "$TEST_LANGS" = fail ] && { echo 'curl: (22) 403' >&2; exit 22; }
printf '%s' "$TEST_LANGS"
EOF
  chmod +x "$WORK/bin-langs/curl"
  # nhãn|phản hồi API giả|mảng langs mong đợi (jq -c)
  while IFS='|' read -r label api want; do
    : > "$WORK/github-output"
    (PATH="$WORK/bin-langs:$PATH" TEST_LANGS="$api" GITHUB_OUTPUT="$WORK/github-output" \
      GH_TOKEN=test REPO=test/repo bash "$WORK/codeql-langs.sh" > "$WORK/check-output" 2>&1)
    rc=$?
    actual=$(sed -n 's/^langs=//p' "$WORK/github-output" | tail -1)
    [ "$rc" = 0 ] && [ "$actual" = "$want" ] && ok "CodeQL $label → $want" || \
      bad "CodeQL $label: muốn $want, nhận '$actual' (rc=$rc)"
  done <<'EOF'
chỉ Python|{"Python":1200,"Shell":300}|["python","actions"]
JS+TS+Go (gộp trùng)|{"TypeScript":900,"JavaScript":50,"Go":400}|["javascript-typescript","go","actions"]
repo rỗng|{}|["actions"]
EOF
  : > "$WORK/github-output"
  (PATH="$WORK/bin-langs:$PATH" TEST_LANGS=fail GITHUB_OUTPUT="$WORK/github-output" \
    GH_TOKEN=test REPO=test/repo bash "$WORK/codeql-langs.sh" > "$WORK/check-output" 2>&1)
  rc=$?
  [ "$rc" -ne 0 ] && ! grep -q '^langs=' "$WORK/github-output" && \
    ok "API lỗi → step đỏ, không âm thầm quét thiếu ngôn ngữ" || bad "API lỗi nhưng step vẫn xuất langs (rc=$rc)"
fi

## ============================================================
## 8. release: release-type dò theo manifest của dự án
## ============================================================
echo "== 8. release release-type =="
step_body "Dò release-type theo manifest" release.yml "$WORK/release-type.sh"
if [ ! -s "$WORK/release-type.sh" ]; then
  echo 'không tìm thấy thân step Dò release-type theo manifest' > "$WORK/check-output"
  bad "không thể trích step release-type từ release.yml"
else
  for case in none:none version.txt:simple VERSION:none package.json:node pyproject.toml:python setup.py:python go.mod:go Cargo.toml:rust; do
    manifest=${case%%:*} want=${case##*:}
    d="$WORK/release-$manifest"
    mkdir -p "$d"
    [ "$manifest" != none ] && : > "$d/$manifest"
    : > "$WORK/github-output"
    (cd "$d" && GITHUB_OUTPUT="$WORK/github-output" bash "$WORK/release-type.sh" > "$WORK/check-output" 2>&1)
    rc=$?
    actual=$(sed -n 's/^type=//p' "$WORK/github-output" | tail -1)
    [ "$rc" = 0 ] && [ "$actual" = "$want" ] && ok "release $manifest → type=$want" || \
      bad "release $manifest: muốn type=$want, nhận '$actual' (rc=$rc)"
  done
fi

finish "protection-guard, dependency-review, Work ID, CodeQL langs và release-type bắt đúng lỗi + không chặn oan."
