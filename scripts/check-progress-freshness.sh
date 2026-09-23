#!/usr/bin/env bash
# Kiểm PROGRESS.md có LỖI THỜI so với git thật không.
#
# VÌ SAO CẦN: PROGRESS.md là văn xuôi cập nhật thủ công ("cập nhật sau mỗi mốc") — không có gì ép
# buộc, nên khi một PR merge (đặc biệt PR khác merge trong lúc phiên này đang làm việc khác) mà
# không ai quay lại sửa file, nó lỗi thời NGAY và IM LẶNG: phiên sau đọc phải trạng thái cũ, dễ làm
# lại việc đã xong hoặc mở PR cho nhánh đã merge (xảy ra thật 2026-09-12: PROGRESS.md vẫn ghi nhánh
# `claude/remove-web-scaffold-layer2` "đang hoàn thiện, chưa mở PR" trong khi PR #67 đã merge).
#
# CHỈ kiểm được phần CƠ HỌC (SHA có phải tổ tiên của HEAD không; nhánh nêu tên có còn tồn tại trên
# remote không) — không kiểm được nội dung tường thuật có đúng không. Đó là giới hạn cố ý.
#
# BẢNG KIỂM:
#   PF-1  "Default-branch SHA đã đối chiếu" phải là tổ tiên (ancestor) của HEAD hiện tại
#   PF-2  Nếu PROGRESS.md nêu tên "Nhánh đang làm" thì nhánh đó phải còn tồn tại trên remote
#         (nhánh đã merge/xoá mà PROGRESS.md vẫn nói "đang làm" = lỗi thời)
#   PF-3  Số PR trong dòng "Giai đoạn" phải >= số PR của commit mà "SHA đã đối chiếu" trỏ tới
#   PF-4  Tối đa 1 khối "- Giai đoạn trước đó" (lịch sử đi docs/changelog/, không tích trong file)
#         (hai dòng cùng mô tả MỘT mốc đối chiếu, lệch nhau là lỗi thời)
#
# Job wiring (ci.yml): job này CHỈ chạy khi push thẳng vào main (sau khi một PR vừa merge) — lúc
# PR còn mở, nhánh vẫn tồn tại là bình thường, kiểm lúc đó sẽ báo oan. Cần lịch sử đầy đủ
# (fetch-depth: 0) để đối chiếu ancestor — checkout nông sẽ luôn báo PF-1 sai.
#
# Chạy: bash scripts/check-progress-freshness.sh
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

PROGRESS_FILE="PROGRESS.md"
fail=0

if [ ! -f "$PROGRESS_FILE" ]; then
  echo "OK — không có $PROGRESS_FILE ở repo này (dự án đích chưa dùng khung này), bỏ qua."
  exit 0
fi

# --- PF-1: SHA đã đối chiếu phải là tổ tiên của HEAD. ---
echo "== PF-1: Default-branch SHA đã đối chiếu là tổ tiên của HEAD =="
sha_line="$(grep -m1 -E '^- Default-branch SHA đã đối chiếu:' "$PROGRESS_FILE" || true)"
if [ -z "$sha_line" ]; then
  echo "::error file=$PROGRESS_FILE::Thiếu dòng 'Default-branch SHA đã đối chiếu:' ở mục 'Giai đoạn hiện tại' — không có gì để đối chiếu độ mới."
  fail=1
else
  recorded_sha="$(printf '%s' "$sha_line" | grep -oE '`[0-9a-f]{7,40}`' | head -1 | tr -d '\`')"
  if [ -z "$recorded_sha" ]; then
    echo "::error file=$PROGRESS_FILE::Không đọc được SHA trong dòng: $sha_line (cần dạng \`abc1234\`)."
    fail=1
  elif ! git cat-file -e "${recorded_sha}^{commit}" 2>/dev/null; then
    echo "::error file=$PROGRESS_FILE::SHA '$recorded_sha' không tồn tại trong lịch sử git (checkout nông, hoặc SHA gõ sai) — không đối chiếu được PF-1."
    fail=1
  elif ! git merge-base --is-ancestor "$recorded_sha" HEAD 2>/dev/null; then
    echo "::error file=$PROGRESS_FILE::SHA '$recorded_sha' KHÔNG phải tổ tiên của HEAD hiện tại — PROGRESS.md đối chiếu nhầm nhánh/lịch sử, hoặc lịch sử đã bị viết lại. Cập nhật lại dòng 'Default-branch SHA đã đối chiếu' cho khớp main thật."
    fail=1
  else
    behind="$(git rev-list --count "${recorded_sha}..HEAD" 2>/dev/null || echo "?")"
    if [ "$behind" != "0" ] && [ "$behind" != "?" ]; then
      echo "::warning file=$PROGRESS_FILE::HEAD hiện đã đi trước SHA đã đối chiếu ('$recorded_sha') $behind commit — bình thường nếu đang làm dở; cập nhật lại dòng này khi đóng phiên/mốc."
    else
      echo "OK: SHA đã đối chiếu khớp HEAD hiện tại."
    fi
  fi
fi

# --- PF-2: nhánh nêu trong "Nhánh đang làm" (nếu có) phải còn tồn tại. ---
echo "== PF-2: 'Nhánh đang làm' (nếu có) phải còn tồn tại trên remote =="
branch_line="$(grep -m1 -E '^- Nhánh đang làm:' "$PROGRESS_FILE" || true)"
if [ -z "$branch_line" ]; then
  echo "OK — không có dòng 'Nhánh đang làm' (không áp dụng)."
else
  branch="$(printf '%s' "$branch_line" | grep -oE '`[A-Za-z0-9._/-]+`' | head -1 | tr -d '\`')"
  if [ -z "$branch" ]; then
    echo "::warning file=$PROGRESS_FILE::Có dòng 'Nhánh đang làm' nhưng không đọc được tên nhánh trong dấu \`...\` — bỏ qua PF-2."
  elif [ "$branch" = "main" ]; then
    echo "OK — 'Nhánh đang làm' là main (không áp dụng)."
  else
    remote_name="$(git remote | head -1)"
    if [ -z "$remote_name" ]; then
      echo "::warning::Không có remote nào cấu hình — bỏ qua PF-2 (không tra được nhánh '$branch' trên remote)."
    elif git ls-remote --exit-code --heads "$remote_name" "$branch" >/dev/null 2>&1; then
      echo "OK: nhánh '$branch' còn tồn tại trên remote '$remote_name'."
    else
      echo "::error file=$PROGRESS_FILE::PROGRESS.md ghi 'Nhánh đang làm: $branch' nhưng nhánh này KHÔNG còn tồn tại trên remote '$remote_name' — rất có thể đã merge/xoá mà quên cập nhật PROGRESS.md (đúng khuôn lỗi TRAPS.md 2026-09-12). Cập nhật lại mục 'Giai đoạn hiện tại' cho khớp thực tế trước khi merge/đóng phiên."
      fail=1
    fi
  fi
fi

# --- PF-3: dòng "Giai đoạn" phải nhất quán với "SHA đã đối chiếu" (audit 2026-09-13). ---
# VÌ SAO: PR #96 cập nhật SHA + "Nhánh đang làm" nhưng SÓT dòng "Giai đoạn" (vẫn ghi PR #69→#93
# trong khi SHA trỏ tới PR #95). PF-1/PF-2 đều xanh vì hai trường đó đúng — không cổng nào bắt.
#
# CỐ Ý so với SỐ PR CỦA CHÍNH SHA ĐÃ ĐỐI CHIẾU, không so với PR mới nhất trên main: hai dòng này
# cùng mô tả MỘT mốc nên phải khớp nhau, và cách so này KHÔNG bị đệ quy (so với PR mới nhất thì
# mỗi PR đồng bộ PROGRESS.md lại tự làm file lệch thêm một bậc, không bao giờ xanh được).
echo "== PF-3: dòng 'Giai đoạn' nhất quán với SHA đã đối chiếu =="
stage_line="$(grep -m1 -E '^- Giai đoạn:' "$PROGRESS_FILE" || true)"
if [ -z "$stage_line" ] || [ -z "${recorded_sha:-}" ]; then
  echo "OK — thiếu dòng 'Giai đoạn' hoặc SHA đã đối chiếu (không áp dụng)."
else
  # Số PR LỚN NHẤT nêu trong dòng "Giai đoạn" (dòng hay viết dạng "PR #69→#96").
  # `|| true`: grep không khớp trả 1, mà `set -euo pipefail` sẽ giết script ngay ở đây
  # (đã mắc thật — PF-3 im lặng chết giữa chừng, baseline đỏ mà không nói lý do).
  stage_pr="$(printf '%s' "$stage_line" | grep -oE '#[0-9]+' | tr -d '#' | sort -n | tail -1 || true)"
  # Số PR của commit mà SHA trỏ tới — squash merge để lại "(#NN)" ở cuối tiêu đề.
  sha_subject="$(git log -1 --format=%s "$recorded_sha" 2>/dev/null || true)"
  sha_pr="$(printf '%s' "$sha_subject" | grep -oE '\(#[0-9]+\)' | tr -d '(#)' | sort -n | tail -1 || true)"
  if [ -z "$stage_pr" ] || [ -z "$sha_pr" ]; then
    echo "OK — không đọc được số PR ở một trong hai dòng (không áp dụng)."
  elif [ "$stage_pr" -ge "$sha_pr" ]; then
    echo "OK: dòng 'Giai đoạn' nêu PR #$stage_pr >= PR #$sha_pr của SHA đã đối chiếu."
  else
    echo "::error file=$PROGRESS_FILE::Dòng 'Giai đoạn' nêu PR #$stage_pr nhưng 'SHA đã đối chiếu' ($recorded_sha) trỏ tới PR #$sha_pr — hai dòng cùng mô tả MỘT mốc nên lệch nhau là PROGRESS.md lỗi thời. Cập nhật dòng 'Giai đoạn' cho khớp (khuôn lỗi: PR #96 sửa SHA nhưng quên dòng này)."
    fail=1
  fi
fi

# --- PF-4: PROGRESS.md không tích lịch sử (audit 2026-09-23, C5). ---
# VÌ SAO: luật quality-supplements-group1 §9 ("chỉ sửa TẠI CHỖ, không chèn lịch sử") không có cổng nên
# file tích 21 khối "Giai đoạn trước đó" (58 KB) và hook session-resume nạp hết vào ngữ cảnh mỗi phiên.
# Cho phép TỐI ĐA 1 khối "trước đó" (đủ để trỏ sang docs/changelog/), từ khối thứ hai là đỏ.
echo "== PF-4: tối đa 1 khối 'Giai đoạn trước đó' (lịch sử đi docs/changelog/) =="
prev_n="$(grep -cE '^- Giai đoạn trước đó' "$PROGRESS_FILE" || true)"
if [ "${prev_n:-0}" -le 1 ]; then
  echo "OK: $prev_n khối 'Giai đoạn trước đó'."
else
  echo "::error file=$PROGRESS_FILE::PROGRESS.md có $prev_n khối 'Giai đoạn trước đó' (tối đa 1) — chuyển các khối cũ sang docs/changelog/NNNN-<ngày>-<slug>.md và để lại một dòng trỏ link (quality-supplements-group1 §9; hook session-resume nạp file này mỗi phiên)."
  fail=1
fi

if [ "$fail" -eq 0 ]; then
  echo "OK — PROGRESS.md khớp git thật (PF-1, PF-2, PF-3, PF-4)."
fi

exit "$fail"
