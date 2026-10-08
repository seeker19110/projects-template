#!/usr/bin/env bash
# _test-lib.sh — thư viện dùng chung cho các script `scripts/test-*.sh` của khung.
#
# Rút ra đúng phần GIỐNG HỆT NHAU ở các script test-*.sh: biến đếm `fails`, hai hàm báo ca
# `ok`/`bad`, và `finish` (kết luận cuối file — luôn exit 1 khi đỏ: `exit "$fails"` với ≥ 256 ca hỏng
# sẽ quay về 0). Các phần KHÁC nhau (cách tính ROOT, set -e/-u, suite có `skips`) CỐ Ý không rút vào đây.
#
# CHỈ dùng để `source`, KHÔNG tự chạy trực tiếp. Không set -e/-u/set khác ở đây: script gọi
# `source` này có thể đã set (hoặc cố ý KHÔNG set) shell option riêng — nạp lại ở đây sẽ ghi đè
# ngoài ý muốn (xem docs/CONVENTIONS.md §A: một số test cố ý không dùng `-e`).
#
# Cách dùng (đặt SAU khi đã tính $ROOT):
#   source "$ROOT/scripts/_test-lib.sh"
#   ok "..."   # in "  ✅ ..."
#   bad "..."  # in "  ❌ ...", tăng $fails
#   finish "..." # cuối file: fails=0 → "OK — ..." exit 0; ngược lại "FAIL — N ca hỏng." exit 1

fails=0
ok()  { echo "  ✅ $1"; }
bad() { echo "  ❌ $1"; fails=$((fails+1)); }
finish() { # $1 = thông điệp OK (dòng kết luận phải bắt đầu "OK —": CI/test-check-scripts grep nó)
  if [ "$fails" -eq 0 ]; then echo "OK — $1"; exit 0; fi
  echo "FAIL — $fails ca hỏng."; exit 1
}
