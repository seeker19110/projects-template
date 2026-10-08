#!/usr/bin/env bash
# test-check-python-complexity.sh — CHỨNG MINH cổng `check-python-complexity.sh` thật sự BẮT
# được hàm vượt trần CC, không chỉ "chạy không crash" (cùng khuôn F-002 với
# `test-hooks-gate.sh` / `test-check-scripts.sh`: cổng chưa có negative test là cổng có thể
# mất khả năng phát hiện mà CI không hề biết).
#
# Sandbox: `git archive HEAD` như `test-check-scripts.sh` → chỉ chứa bản ĐÃ COMMIT. Sửa cổng
# rồi chạy test này NGAY khi chưa commit thì sandbox vẫn chạy bản cũ (TRAPS.md mục 12) — nên
# ca baseline/negative ở đây chạy trên CÂY LÀM VIỆC thật (cổng chỉ đọc file, không sửa gì),
# còn thư mục tạm chỉ dùng để dựng file .py vi phạm.
#
# Chạy: bash scripts/test-check-python-complexity.sh
set -uo pipefail   # cố ý KHÔNG -e (docs/CONVENTIONS.md §A)

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
if command -v cygpath >/dev/null 2>&1; then ROOT="$(cygpath -m "$ROOT")"; fi
WORK="$(mktemp -d)"
trap 'rm -f "$ROOT/scripts/zz-probe-cc-$$.py"; rm -rf "$WORK"' EXIT

source "$ROOT/scripts/_test-lib.sh"

GATE="scripts/check-python-complexity.sh"
run_gate() { ( cd "$ROOT" && "$@" bash "$GATE" >/dev/null 2>&1 ); echo $?; }

echo "== 1. Baseline: repo hiện tại phải XANH (mọi khối ≤ CC 12) =="
rc="$(run_gate env)"
[ "$rc" = "0" ] && ok "baseline → rc=0" || bad "baseline lẽ ra phải xanh (rc=$rc)"

echo "== 2. NEGATIVE: thả một hàm CC 13 vào scripts/ → cổng phải ĐỎ =="
PROBE="$ROOT/scripts/zz-probe-cc-$$.py"
{
  echo '"""File thăm dò tạm — dựng một hàm CC 13 để kiểm cổng."""'
  echo 'def probe(n):'
  echo '    total = 0'
  for i in $(seq 1 12); do echo "    if n == $i: total += $i"; done
  echo '    return total'
} > "$PROBE"
rc="$(run_gate env)"
[ "$rc" = "1" ] && ok "hàm CC 13 → rc=1 (cổng bắt được)" || bad "hàm CC 13 nhưng cổng KHÔNG đỏ (rc=$rc) — cổng xanh giả"

# Thông điệp phải chỉ đúng file + tên hàm, nếu không người sửa không biết sửa ở đâu.
out="$( cd "$ROOT" && bash "$GATE" 2>&1 )"
case "$out" in
  *"zz-probe-cc-$$.py"*probe*) ok "thông điệp nêu đúng file + tên hàm vi phạm" ;;
  *) bad "thông điệp không nêu rõ file/tên hàm vi phạm" ;;
esac

echo "== 3. ĐỐI CHỨNG ĐỊNH LƯỢNG: cùng file đó, nâng trần lên 13 → phải XANH =="
rc="$(run_gate env PY_CC_MAX=13)"
[ "$rc" = "0" ] && ok "PY_CC_MAX=13 → rc=0 (ngưỡng thật sự được dùng, không phải hằng số chết)" \
                || bad "PY_CC_MAX=13 vẫn đỏ (rc=$rc) — cổng không đọc ngưỡng"

rm -f "$PROBE"
rc="$(run_gate env)"
[ "$rc" = "0" ] && ok "dọn file thăm dò → xanh trở lại" || bad "sau khi dọn vẫn đỏ (rc=$rc)"

echo "== 4. Thiếu radon → ĐỎ, KHÔNG được 'skip' im lặng =="
mkdir -p "$WORK/bin"
cat > "$WORK/bin/python3" <<'STUB'
#!/usr/bin/env bash
# Giả lập môi trường KHÔNG có radon: mọi lời gọi `-m radon` đều thất bại.
case " $* " in *" radon "*) exit 1 ;; esac
exec /usr/bin/env python3 "$@"
STUB
chmod +x "$WORK/bin/python3"
rc="$( cd "$ROOT" && PATH="$WORK/bin:$PATH" bash "$GATE" >/dev/null 2>&1; echo $? )"
[ "$rc" = "1" ] && ok "thiếu radon → rc=1 (không tự tắt thành cổng xanh giả)" \
                || bad "thiếu radon nhưng rc=$rc — cổng tự tắt"

echo
finish "cổng CC chứng minh được là bắt đúng vi phạm."
