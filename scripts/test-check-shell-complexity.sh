#!/usr/bin/env bash
# test-check-shell-complexity.sh — CHỨNG MINH cổng `check-shell-complexity.sh` bắt được thật,
# không chỉ "chạy không crash" (khuôn F-002, như `test-check-python-complexity.sh` cho Python).
#
# Bốn thứ phải được chứng minh, vì mỗi thứ là một cách cổng có thể xanh giả:
#   1. hàm vượt trần 12          → ĐỎ
#   2. thân script vượt trần 45  → ĐỎ (trần thứ hai không phải trang trí)
#   3. thân script CC 41 hiện có → XANH (trần 45 không đỏ oan mã đang chạy)
#   4. checksum bản vendor sai   → ĐỎ (không đo bằng công cụ không rõ nội dung)
#
# Chạy: bash scripts/test-check-shell-complexity.sh
set -uo pipefail   # cố ý KHÔNG -e (docs/CONVENTIONS.md §A)

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
if command -v cygpath >/dev/null 2>&1; then ROOT="$(cygpath -m "$ROOT")"; fi
PROBE="$ROOT/scripts/zz-probe-shcc-$$.sh"
trap 'rm -f "$PROBE"' EXIT

source "$ROOT/scripts/_test-lib.sh"

GATE="scripts/check-shell-complexity.sh"
run_gate() { ( cd "$ROOT" && env "$@" bash "$GATE" >/dev/null 2>&1 ); echo $?; }

# In ra một script shell có đúng $1 nhánh `if`, bọc trong hàm nếu $2 = func.
make_probe() {
  local branches="$1" kind="$2" i
  {
    echo '#!/usr/bin/env bash'
    echo '# File thăm dò tạm của test cổng CC shell.'
    [ "$kind" = func ] && echo 'probe() {'
    for i in $(seq 1 "$branches"); do echo "if [ \"\${1:-}\" = \"v$i\" ]; then echo $i; fi"; done
    [ "$kind" = func ] && echo '}'
  } > "$PROBE"
}

echo "== 1. Baseline: repo hiện tại phải XANH =="
rc="$(run_gate _=_)"
[ "$rc" = "0" ] && ok "baseline → rc=0 (trần 45 KHÔNG đỏ oan thân script CC 41 đang có)" \
                || bad "baseline lẽ ra phải xanh (rc=$rc)"

echo "== 2. NEGATIVE: hàm 13 nhánh (> trần hàm 12) → ĐỎ =="
make_probe 13 func
rc="$(run_gate _=_)"
[ "$rc" = "1" ] && ok "hàm CC 14 → rc=1" || bad "hàm vượt trần nhưng cổng KHÔNG đỏ (rc=$rc) — xanh giả"
out="$( cd "$ROOT" && bash "$GATE" 2>&1 )"
case "$out" in
  *"zz-probe-shcc-$$.sh"*probe*) ok "thông điệp nêu đúng file + tên hàm" ;;
  *) bad "thông điệp không nêu rõ file/tên hàm vi phạm" ;;
esac

echo "== 3. ĐỐI CHỨNG: cùng file đó, nâng trần hàm → XANH (ngưỡng được đọc thật) =="
rc="$(run_gate SH_CC_MAX=20)"
[ "$rc" = "0" ] && ok "SH_CC_MAX=20 → rc=0" || bad "SH_CC_MAX=20 vẫn đỏ (rc=$rc) — cổng không đọc ngưỡng"

echo "== 4. NEGATIVE: THÂN SCRIPT 46 nhánh (> trần 45) → ĐỎ, và trần thân script tách rời trần hàm =="
make_probe 46 main
rc="$(run_gate _=_)"
[ "$rc" = "1" ] && ok "thân script CC 47 → rc=1" || bad "thân script vượt trần nhưng cổng KHÔNG đỏ (rc=$rc)"
rc="$(run_gate SH_CC_MAX=99)"
[ "$rc" = "1" ] && ok "nâng trần HÀM không cứu được thân script (hai trần thật sự tách rời)" \
                || bad "nâng SH_CC_MAX làm thân script hết đỏ — hai trần đang dính nhau"
rc="$(run_gate SH_CC_MAIN_MAX=99)"
[ "$rc" = "0" ] && ok "SH_CC_MAIN_MAX=99 → rc=0" || bad "SH_CC_MAIN_MAX không được đọc (rc=$rc)"

rm -f "$PROBE"
rc="$(run_gate _=_)"
[ "$rc" = "0" ] && ok "dọn file thăm dò → xanh trở lại" || bad "sau khi dọn vẫn đỏ (rc=$rc)"

echo "== 5. Checksum bản vendor sai → ĐỎ (không đo bằng công cụ lạ) =="
BACKUP="$(mktemp)"
cp "$ROOT/vendor/shellmetrics/shellmetrics" "$BACKUP"
printf '\n# dòng lạ chèn vào để đổi checksum\n' >> "$ROOT/vendor/shellmetrics/shellmetrics"
rc="$(run_gate _=_)"
cp "$BACKUP" "$ROOT/vendor/shellmetrics/shellmetrics"; rm -f "$BACKUP"
[ "$rc" = "1" ] && ok "bản vendor bị sửa → rc=1" || bad "bản vendor bị sửa nhưng cổng vẫn chạy (rc=$rc)"
rc="$(run_gate _=_)"
[ "$rc" = "0" ] && ok "khôi phục bản vendor → xanh trở lại" || bad "khôi phục xong vẫn đỏ (rc=$rc)"

echo "== 6. Chạy lại cổng dưới gawk (dialect của runner CI, khác mawk ở máy dev) =="
# TRAPS.md mục 23: `func` là từ khoá của gawk nhưng không phải của mawk — cổng chạy xanh ở máy,
# chết TRƯỚC khi đo được gì trên CI. Ca này bắt đúng lớp lỗi đó.
if command -v gawk >/dev/null 2>&1; then
  GAWKBIN="$(mktemp -d)"
  ln -sf "$(command -v gawk)" "$GAWKBIN/awk"
  rc="$( cd "$ROOT" && PATH="$GAWKBIN:$PATH" bash "$GATE" >/dev/null 2>&1; echo $? )"
  rm -rf "$GAWKBIN"
  [ "$rc" = "0" ] && ok "cổng chạy đúng dưới gawk" \
                  || bad "cổng ĐỎ dưới gawk (rc=$rc) — cú pháp awk không chạy được trên runner CI"
else
  echo "  ⏭️  bỏ qua: máy này không có gawk (CI luôn có — ở đó ca này không bao giờ bị bỏ qua)"
fi

echo
finish "cổng CC shell chứng minh được là bắt đúng vi phạm."
