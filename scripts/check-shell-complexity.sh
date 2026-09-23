#!/usr/bin/env bash
# check-shell-complexity.sh — CỔNG MÁY cưỡng chế trần độ phức tạp vòng (CC) cho mã SHELL,
# song sinh của `scripts/check-python-complexity.sh` (PR #123) cho nửa còn lại của repo.
#
# HAI TRẦN, KHÔNG PHẢI MỘT — và đây là khác biệt CÓ ĐO, không phải nhân nhượng:
#   - HÀM shell: trần 12 (`SH_CC_MAX`) — cùng con số với Python, vì cùng một thứ: một đơn vị
#     logic có tên, tách được, test được.
#   - THÂN SCRIPT (`<main>` — mọi nhánh ở cấp cao nhất): trần 45 (`SH_CC_MAIN_MAX`). Một script
#     cổng vốn LÀ một chuỗi kiểm tuần tự; ép nó xuống 12 chỉ đẩy nhánh vào hàm một-lần-gọi cho
#     vừa con số chứ không làm script dễ đọc hơn. Trần 45 đặt ngay TRÊN mức cao nhất đo được
#     lúc dựng cổng (`check-ci-policy.sh` = 41) nên nó là **nắp chặn trượt**: đủ chỗ cho mã hiện
#     có, nhưng script nào phình thêm là đỏ. Hạ dần trần này khi có đợt tách script, đừng nâng.
#
# Công cụ: `vendor/shellmetrics/shellmetrics` (bản sao có ghim, xem README cạnh nó). Cổng KIỂM
# CHECKSUM trước khi chạy — mã bên thứ ba bị sửa mà không ai biết thì mọi con số dưới đây vô nghĩa.
#
# Chạy: bash scripts/check-shell-complexity.sh
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
if command -v cygpath >/dev/null 2>&1; then ROOT="$(cygpath -m "$ROOT")"; fi
cd "$ROOT" || exit 1

MAX="${SH_CC_MAX:-12}"
MAIN_MAX="${SH_CC_MAIN_MAX:-45}"
TOOL="vendor/shellmetrics/shellmetrics"

[ -x "$TOOL" ] || { echo "::error::Không tìm thấy $TOOL (bản vendor có ghim)." >&2; exit 1; }

# Checksum trước, đo sau. Sai checksum = hoặc ai đó sửa tay bản vendor, hoặc nâng cấp mà quên
# cập nhật SHA256SUMS — cả hai đều phải ĐỎ, không phải cảnh báo.
SHA_CMD="sha256sum"; command -v sha256sum >/dev/null 2>&1 || SHA_CMD="shasum -a 256"   # macOS không có sha256sum
if ! ( cd vendor/shellmetrics && $SHA_CMD -c SHA256SUMS ) >/dev/null 2>&1; then
  echo "::error file=vendor/shellmetrics/SHA256SUMS::Checksum của $TOOL KHÔNG khớp SHA256SUMS — không đo bằng một công cụ không rõ nội dung. Nâng cấp thì cập nhật SHA256SUMS + README rồi chạy lại." >&2
  exit 1
fi

# vendor/ bị loại khỏi phép đo: không áp trần của mình lên mã của người khác (nó vẫn qua
# hai cổng đó trong cùng job CI vẫn soi nó).
mapfile -t SH_FILES < <(find . -name '*.sh' -not -path './node_modules/*' -not -path './vendor/*' | sort)
if [ "${#SH_FILES[@]}" -eq 0 ]; then
  echo "::error::Không tìm thấy file .sh nào để đo — cổng rỗng luôn xanh là cổng hỏng." >&2
  exit 1
fi

echo "== Độ phức tạp vòng shell (shellmetrics) — trần hàm: $MAX · trần thân script: $MAIN_MAX =="

RAW="$(mktemp)"; trap 'rm -f "$RAW"' EXIT
if ! "$TOOL" --csv "${SH_FILES[@]}" > "$RAW" 2>/dev/null || [ ! -s "$RAW" ]; then
  echo "::error::shellmetrics chạy lỗi hoặc không ra dữ liệu." >&2
  exit 1
fi

# CSV: file,func,lineno,lloc,ccn,lines,comment,blank — ccn là cột 5.
# Biến tên `blk` chứ KHÔNG phải `func`: `func` là TỪ KHOÁ của gawk (viết tắt của `function`) —
# mawk nhận, gawk báo syntax error. Máy dev dùng mawk, runner CI dùng gawk (TRAPS.md mục 23).
# `<begin>` là phần đầu file trước hàm đầu tiên (ccn luôn 0), bỏ qua.
awk -F, -v max="$MAX" -v mainmax="$MAIN_MAX" '
  NR == 1 { next }
  { gsub(/"/, ""); file = $1; sub(/^\.\//, "", file); blk = $2; cc = $5 + 0 }
  blk == "<begin>" { next }
  {
    measured++
    limit = (blk == "<main>") ? mainmax : max
    label = (blk == "<main>") ? "thân script" : "hàm"
    if (cc > worst_cc) { worst_cc = cc; worst = file "::" blk }
    if (cc > limit) {
      bad++
      printf("::error file=%s,line=%d::%s `%s` có CC %d > trần %d — tách bớt nhánh trước khi commit.\n",
             file, $3 + 0, label, blk, cc, limit)
    }
  }
  END {
    printf("Đã đo %d khối shell. Cao nhất: %s = CC %d\n", measured, worst, worst_cc)
    if (bad) {
      printf("\nFAIL — %d khối vượt trần. Đừng nâng trần để CI xanh.\n", bad)
      exit 1
    }
    printf("OK — mọi hàm ≤ CC %d, mọi thân script ≤ CC %d.\n", max, mainmax)
  }
' "$RAW"
