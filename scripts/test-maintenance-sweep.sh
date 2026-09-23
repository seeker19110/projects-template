#!/usr/bin/env bash
# test-maintenance-sweep.sh — Self-test cho engine quét bảo trì (scripts/maintenance-sweep.sh).
#
# Nguyên tắc F-002 / TRAPS.md mục 11: engine phải được CHỨNG MINH bắt đúng lỗi bằng negative-test
# trên một repo dựng tạm có lỗi cài sẵn, không chỉ "chạy không crash". Chạy trong job CI
# `framework-lint` VÀ được copy sang dự án đích để smoke (test-copy-framework.sh).
#
# Chạy: bash scripts/test-maintenance-sweep.sh
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SWEEP="$ROOT/scripts/maintenance-sweep.sh"
source "$ROOT/scripts/_test-lib.sh"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
GIT=(git -c user.name=t -c user.email=t@example.com -c commit.gpgsign=false)

echo "== 1. --help thoát 0 và có hướng dẫn =="
if bash "$SWEEP" --help 2>&1 | grep -q -- '--strict'; then ok "--help in ra tuỳ chọn"; else bad "--help không in tuỳ chọn"; fi

echo "== 2. Quét chính repo này (--no-deps) — đủ 6 mảng + bảng tổng hợp, không crash =="
out="$(bash "$SWEEP" --no-deps 2>&1)"; rc=$?
[ "$rc" -eq 0 ] || [ "$rc" -eq 1 ] && ok "thoát $rc (0 = không 🔴; 1 chỉ khi --strict)" || bad "thoát mã lạ $rc"
[ "$rc" -eq 0 ] || bad "không dùng --strict mà vẫn thoát khác 0"
for s in "## Tổng hợp phát hiện" "## 1. Git" "## 2. Dependency" "## 3. Tài liệu" "## 4. Vệ sinh" "## 5. CI" "## 6. Cổng"; do
  if printf '%s' "$out" | grep -q "$s"; then ok "có mục '$s'"; else bad "thiếu mục '$s'"; fi
done

echo "== 3. NEGATIVE: repo tạm có lỗi cài sẵn phải bị bắt đúng mức =="
bad_repo="$TMP/bad"; mkdir -p "$bad_repo/.github/workflows" "$bad_repo/.claude"
# Khoá giả DỰNG LÚC CHẠY (không viết literal vào file test — kẻo chính test này bị sweep bắt).
fake_aws="AKIA$(printf 'Q%.0s' $(seq 16))"
fake_pem="-----BEGIN ""RSA PRIVATE KEY-----"
(
  cd "$bad_repo" && "${GIT[@]}" init -q -b main
  printf 'DB_URL=x\nAWS_KEY=%s\n' "$fake_aws" > .env
  printf '%s\nabc\n' "$fake_pem" > key.pem
  printf 'name: x\non: push\njobs:\n  a:\n    runs-on: ubuntu-latest\n    steps:\n      - uses: actions/checkout@v4\n' > .github/workflows/ci.yml
  printf '# PROGRESS\n- Ngày cập nhật: 2020-01-01\n' > PROGRESS.md
  # Khai báo lệnh dependency: outdated xanh có dấu vết, audit ĐỎ giả lập
  printf 'deps_outdated="echo OUTDATED-DECL-MARK"\ndeps_audit="echo VULN-FOUND; exit 3"\n' > .claude/project-commands.sh
  "${GIT[@]}" add -A && "${GIT[@]}" commit -qm init
)
bout="$(CLAUDE_PROJECT_DIR="$bad_repo" bash "$SWEEP" --strict --out "$TMP/bad-report.md" 2>&1)"; brc=$?
[ "$brc" -eq 1 ] && ok "--strict thoát 1 khi có 🔴" || bad "--strict thoát $brc (mong 1). Output: $bout"
[ -s "$TMP/bad-report.md" ] && ok "--out ghi được báo cáo" || bad "--out không ghi file"
rep="$(cat "$TMP/bad-report.md" 2>/dev/null)"
chk() { if printf '%s' "$rep" | grep -q -- "$2"; then ok "$1"; else bad "$1 — không thấy '$2'"; fi; }
chk "🔴 .env trong git"                    "🔴 | Bí mật | file .env"
chk "🔴 chuỗi giống bí mật (AWS/PEM)"     "🔴 | Bí mật | .* dòng giống khoá"
chk "🟡 action chưa ghim SHA"             "🟡 | CI | 1 action chưa ghim"
chk "🟡 PROGRESS.md lỗi thời"             "🟡 | Tài liệu | PROGRESS.md lỗi thời"
chk "🟡 thiếu dependabot.yml"             "🟡 | CI | thiếu .github/dependabot.yml"
chk "lệnh deps KHAI BÁO được ưu tiên"     "OUTDATED-DECL-MARK"
chk "🔴 audit khai báo đỏ → 🔴"           "🔴 | Dependency | audit báo lỗ hổng (exit 3)"
chk "cổng khung vắng → n-a, không crash"  "docs-consistency: n-a"

echo "== 3b. NEGATIVE: tên file độc KHÔNG được thực thi (command injection qua git ls-files) =="
# Bản cũ: `xargs -I{} sh -c 'f="{}"'` nội suy tên file vào shell → file tên '$(touch X)' chạy lệnh
# khi sweep quét (nguy hiểm nhất ở maintain-cron không giám sát). Audit 2026-09-23 C8.
inj_repo="$TMP/inj"; mkdir -p "$inj_repo"
(
  cd "$inj_repo" && "${GIT[@]}" init -q -b main
  : > 'a$(touch INJECTED-MARK)b.txt'
  : > 'c`touch INJECTED-MARK2`d.txt'
  "${GIT[@]}" add -A && "${GIT[@]}" commit -qm init
) 2>/dev/null
CLAUDE_PROJECT_DIR="$inj_repo" bash "$SWEEP" --no-deps --out "$TMP/inj-report.md" >/dev/null 2>&1
if [ -e "$inj_repo/INJECTED-MARK" ] || [ -e "$inj_repo/INJECTED-MARK2" ]; then
  bad "tên file chứa \$(...)/backtick ĐÃ ĐƯỢC THỰC THI khi sweep quét file lớn"
else
  ok "tên file độc không được thực thi"
fi

echo "== 3c. Chiều đúng của phép đo dependency lỗi thời (Go / pip) =="
# Bản cũ: Go `... | grep '['` → CÓ gói cũ ⇒ grep exit 0 ⇒ báo 'sạch' (đảo chiều); pip luôn exit 0 ⇒ không bao giờ 🟡.
FAKEBIN="$TMP/fakebin"; mkdir -p "$FAKEBIN"
mk_fake() { printf '#!/usr/bin/env bash\n%s\n' "$2" > "$FAKEBIN/$1"; chmod +x "$FAKEBIN/$1"; }
dep_repo() { # $1=tên $2=file marker
  local d="$TMP/$1"; mkdir -p "$d"
  ( cd "$d" && "${GIT[@]}" init -q -b main && : > "$2" && "${GIT[@]}" add -A && "${GIT[@]}" commit -qm init ) 2>/dev/null
  printf '%s' "$d"
}
has_outdated() { grep -q "🟡 | Dependency | có gói lỗi thời" "$1" 2>/dev/null; }
gorepo="$(dep_repo gorepo go.mod)"
mk_fake go 'echo "example.com/a v1.0.0 [v1.2.0]"'
PATH="$FAKEBIN:$PATH" CLAUDE_PROJECT_DIR="$gorepo" bash "$SWEEP" --out "$TMP/go1.md" >/dev/null 2>&1
has_outdated "$TMP/go1.md" && ok "Go: có '[vX]' → 🟡 gói lỗi thời" || bad "Go: có gói cũ nhưng KHÔNG báo 🟡 (đảo chiều)"
mk_fake go 'echo "example.com/a v1.0.0"'
PATH="$FAKEBIN:$PATH" CLAUDE_PROJECT_DIR="$gorepo" bash "$SWEEP" --out "$TMP/go2.md" >/dev/null 2>&1
has_outdated "$TMP/go2.md" && bad "Go: KHÔNG có gói cũ mà vẫn báo 🟡 (đảo chiều)" || ok "Go: sạch → không 🟡"
pyrepo="$(dep_repo pyrepo requirements.txt)"
mk_fake pip 'echo "requests==2.0.0"'
PATH="$FAKEBIN:$PATH" CLAUDE_PROJECT_DIR="$pyrepo" bash "$SWEEP" --out "$TMP/py1.md" >/dev/null 2>&1
has_outdated "$TMP/py1.md" && ok "pip: có gói cũ → 🟡" || bad "pip: có gói cũ nhưng KHÔNG báo 🟡 (pip luôn exit 0)"
mk_fake pip ':'
PATH="$FAKEBIN:$PATH" CLAUDE_PROJECT_DIR="$pyrepo" bash "$SWEEP" --out "$TMP/py2.md" >/dev/null 2>&1
has_outdated "$TMP/py2.md" && bad "pip: sạch mà vẫn 🟡" || ok "pip: sạch → không 🟡"

echo "== 4. POSITIVE: repo tạm sạch → 0 🔴, --strict thoát 0 =="
good_repo="$TMP/good"; mkdir -p "$good_repo/.github"
(
  cd "$good_repo" && "${GIT[@]}" init -q -b main
  printf '# PROGRESS\n- Ngày cập nhật: %s\n' "$(date +%Y-%m-%d)" > PROGRESS.md
  printf 'version: 2\nupdates: []\n' > .github/dependabot.yml
  printf 'DB_URL=example\n' > .env.example
  "${GIT[@]}" add -A && "${GIT[@]}" commit -qm init
)
gout="$(CLAUDE_PROJECT_DIR="$good_repo" bash "$SWEEP" --strict --no-deps 2>&1)"; grc=$?
[ "$grc" -eq 0 ] && ok "repo sạch: --strict thoát 0" || bad "repo sạch mà --strict thoát $grc: $gout"
printf '%s' "$gout" | grep -q '🔴 0' && ok "báo cáo ghi 🔴 0" || bad "báo cáo không ghi 🔴 0"
printf '%s' "$gout" | grep -q 'Bí mật | file .env' && bad ".env.example bị báo oan là .env" || ok ".env.example không bị báo oan"

echo "== 5. NEGATIVE+POSITIVE: dấu nợ DEBT: — thiếu 'xem lại khi:' phải 🟡, đủ thì không =="
# Chuỗi dấu DỰNG LÚC CHẠY (TRAPS.md mục 18): không viết literal vào file test, kẻo chính bộ đếm
# của sweep khớp file test này và làm số đo phình lên.
MARK="DE""BT:"
debt_repo="$TMP/debt"; mkdir -p "$debt_repo"
(
  cd "$debt_repo" && "${GIT[@]}" init -q -b main
  printf '# PROGRESS\n- Ngày cập nhật: %s\n' "$(date +%Y-%m-%d)" > PROGRESS.md
  # 1 dấu ĐỦ ba phần + 1 dấu THIẾU điều kiện xem lại
  printf '# %s khoá toàn cục | trần: 50 req/s | xem lại khi: p95 > 300ms\nok = 1\n' "$MARK" > full.py
  printf '# %s quét O(n^2) | trần: n < 500\nok = 2\n' "$MARK" > partial.py
  "${GIT[@]}" add -A && "${GIT[@]}" commit -qm init
)
dout="$(CLAUDE_PROJECT_DIR="$debt_repo" bash "$SWEEP" --no-deps 2>&1)"
printf '%s' "$dout" | grep -q "1 dấu $MARK không có 'xem lại khi:'" \
  && ok "bắt đúng 1 dấu thiếu điều kiện xem lại" \
  || bad "không bắt được dấu thiếu điều kiện xem lại. Output: $(printf '%s' "$dout" | grep -i "$MARK")"
printf '%s' "$dout" | grep -q "🟡 | Nợ kỹ thuật | 1 dấu" && ok "đúng mức 🟡" || bad "không phải mức 🟡"
printf '%s' "$dout" | grep -qE "Dấu nợ .$MARK. trong mã: 2" && ok "đếm đủ 2 dấu" || bad "đếm sai tổng số dấu"
# Repo sạch ở mục 4 không có dấu nào → không được báo oan
printf '%s' "$gout" | grep -q "không có dấu $MARK" && ok "repo không có dấu nào: ℹ️, không 🟡" || bad "repo không có dấu mà vẫn báo gì đó lạ"

echo "== 6. Tham số lạ → thoát 2 =="
bash "$SWEEP" --bogus >/dev/null 2>&1; [ $? -eq 2 ] && ok "thoát 2" || bad "tham số lạ không thoát 2"

echo
if [ "$fails" -eq 0 ]; then echo "OK — maintenance-sweep.sh đo đúng, bắt đúng lỗi cài sẵn, không báo oan repo sạch."; else echo "FAIL — $fails kiểm hỏng."; fi
exit "$fails"
