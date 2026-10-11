#!/usr/bin/env bash
# test-check-progress-freshness.sh — CHỨNG MINH `check-progress-freshness.sh` (PF-1..PF-4) bắt đúng lỗi, không chặn oan.
#
# VÌ SAO TÁCH khỏi `test-check-scripts.sh` (2026-10-11): suite gốc vượt 400 dòng (radar) khi thêm ca F-303/F-305;
# fixture dùng chung ở `scripts/_check-scripts-test-lib.sh`. Mỗi ca dùng repo scratch/lịch sử riêng; không sửa repo thật.
#
# Chạy: bash scripts/test-check-progress-freshness.sh
set -uo pipefail   # cố ý KHÔNG -e: một ca lỗi không được làm chết cả lượt chạy (docs/CONVENTIONS.md §A)

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
if command -v cygpath >/dev/null 2>&1; then ROOT="$(cygpath -m "$ROOT")"; fi
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

source "$ROOT/scripts/_test-lib.sh"
# shellcheck source=scripts/_check-scripts-test-lib.sh
source "$ROOT/scripts/_check-scripts-test-lib.sh"

## ============================================================
## 3. check-progress-freshness.sh
## ============================================================
echo "== 3. check-progress-freshness.sh =="

d="$(setup_repo)" || exit 1
rc="$(run_check "$d" check-progress-freshness.sh)"
[ "$rc" = "0" ] && ok "baseline (bản sao sạch) → xanh" || bad "baseline lẽ ra phải xanh (rc=$rc)"

# PF-1: SHA đã đối chiếu KHÔNG phải tổ tiên của HEAD (tồn tại thật, nhưng ở nhánh khác đã rẽ nhánh).
d="$(setup_repo)" || exit 1
git -C "$d" checkout -qb other-branch
echo "chỉ để tạo commit khác nhánh" >> "$d/README.md"
git -C "$d" -c user.email=t@t.local -c user.name=test commit -qam "commit trên nhánh khác"
other_sha="$(git -C "$d" rev-parse HEAD)"
git -C "$d" checkout -q -
sed -i.bak "s/^- Default-branch SHA đã đối chiếu:.*/- Default-branch SHA đã đối chiếu: \`$other_sha\`/" "$d/PROGRESS.md" && rm -f "$d/PROGRESS.md.bak"
git -C "$d" -c user.email=t@t.local -c user.name=test commit -qam "PROGRESS.md trỏ SHA nhánh khác"
rc="$(run_check "$d" check-progress-freshness.sh)"
[ "$rc" = "1" ] && ok "bắt được SHA không phải tổ tiên của HEAD (PF-1)" || bad "KHÔNG bắt được SHA sai nhánh (rc=$rc)"

# PF-4: tích lịch sử trong PROGRESS.md (≥ 2 khối "Giai đoạn trước đó") phải đỏ.
d="$(setup_repo)" || exit 1
printf -- '- Giai đoạn trước đó: khối cũ A\n- Giai đoạn trước đó: khối cũ B\n' >> "$d/PROGRESS.md"
git -C "$d" -c user.email=t@t.local -c user.name=test commit -qam "PROGRESS.md tích lịch sử"
rc="$(run_check "$d" check-progress-freshness.sh)"
[ "$rc" = "1" ] && ok "bắt được PROGRESS.md tích ≥ 2 khối 'Giai đoạn trước đó' (PF-4)" || bad "KHÔNG bắt được PROGRESS.md tích lịch sử (rc=$rc)"

# PF-2: "Nhánh đang làm" nêu tên một nhánh KHÔNG còn tồn tại trên remote (đã merge/xoá).
d="$(setup_repo)" || exit 1
git init -q --bare "$WORK/origin.git"
git -C "$d" remote add origin "$WORK/origin.git"
git -C "$d" push -q origin HEAD:main 2>/dev/null
sed -i.bak 's/^- Nhánh đang làm:.*/- Nhánh đang làm: `nhanh-da-bi-xoa-mat-roi`/' "$d/PROGRESS.md" && rm -f "$d/PROGRESS.md.bak"
git -C "$d" -c user.email=t@t.local -c user.name=test commit -qam "PROGRESS.md trỏ nhánh đã xoá"
rc="$(run_check "$d" check-progress-freshness.sh)"
[ "$rc" = "1" ] && ok "bắt được nhánh 'đang làm' không còn tồn tại trên remote (PF-2)" || bad "KHÔNG bắt được nhánh đã xoá (rc=$rc)"

# Đối chứng: nhánh còn tồn tại trên remote → PHẢI xanh (không chặn oan).
d="$(setup_repo)" || exit 1
git init -q --bare "$WORK/origin2.git"
git -C "$d" remote add origin "$WORK/origin2.git"
git -C "$d" checkout -qb feature-that-exists
git -C "$d" push -q origin HEAD:feature-that-exists 2>/dev/null
git -C "$d" push -q origin HEAD:main 2>/dev/null
sed -i.bak 's/^- Nhánh đang làm:.*/- Nhánh đang làm: `feature-that-exists`/' "$d/PROGRESS.md" && rm -f "$d/PROGRESS.md.bak"
git -C "$d" -c user.email=t@t.local -c user.name=test commit -qam "PROGRESS.md trỏ nhánh còn tồn tại"
git -C "$d" push -q origin HEAD:feature-that-exists 2>/dev/null
rc="$(run_check "$d" check-progress-freshness.sh)"
[ "$rc" = "0" ] && ok "KHÔNG chặn oan nhánh còn tồn tại trên remote (đối chứng PF-2)" || bad "chặn OAN nhánh còn tồn tại (rc=$rc) — false positive"

## ============================================================
echo ""

d="$(setup_repo)" || exit 1
# PF-3 (audit 2026-09-13): dòng "Giai đoạn" nêu số PR NHỎ HƠN PR của SHA đã đối chiếu -> ĐỎ.
# Đây đúng khuôn lỗi PR #96 (sửa SHA nhưng quên dòng "Giai đoạn"), mà PF-1/PF-2 đều xanh.
# setup_repo đặt SHA = commit của chính sandbox (không có "(#NN)") nên phải dựng mốc giả lập:
# tạo một commit có tiêu đề dạng squash-merge rồi trỏ SHA đã đối chiếu vào đó.
git -C "$d" -c user.email=t@t.local -c user.name=test commit -q --allow-empty -m "feat: mốc giả lập (#500)"
fake_sha="$(git -C "$d" rev-parse --short HEAD)"
sed -i "s/^- Default-branch SHA đã đối chiếu:.*/- Default-branch SHA đã đối chiếu: \`$fake_sha\` (mốc giả lập, PR #500)/" "$d/PROGRESS.md"
sed -i "s/^- Giai đoạn:.*/- Giai đoạn: GĐ 8. PR #69→#499 đã merge./" "$d/PROGRESS.md"
git -C "$d" -c user.email=t@t.local -c user.name=test commit -q -am "chuẩn bị ca PF-3"
rc="$(run_check "$d" check-progress-freshness.sh)"
[ "$rc" = "1" ] && ok "bắt được dòng 'Giai đoạn' lệch sau SHA đã đối chiếu (PF-3)" || bad "KHÔNG bắt được 'Giai đoạn' lỗi thời (rc=$rc)"

d="$(setup_repo)" || exit 1
# Đối chứng: "Giai đoạn" KHỚP (>=) thì PF-3 phải XANH — chứng minh không đỏ oan.
git -C "$d" -c user.email=t@t.local -c user.name=test commit -q --allow-empty -m "feat: mốc giả lập (#500)"
fake_sha="$(git -C "$d" rev-parse --short HEAD)"
sed -i "s/^- Default-branch SHA đã đối chiếu:.*/- Default-branch SHA đã đối chiếu: \`$fake_sha\` (mốc giả lập, PR #500)/" "$d/PROGRESS.md"
sed -i "s/^- Giai đoạn:.*/- Giai đoạn: GĐ 8. PR #69→#501 đã merge./" "$d/PROGRESS.md"
git -C "$d" -c user.email=t@t.local -c user.name=test commit -q -am "chuẩn bị ca đối chứng PF-3"
rc="$(run_check "$d" check-progress-freshness.sh)"
[ "$rc" = "0" ] && ok "PF-3 XANH khi 'Giai đoạn' >= PR của SHA (không đỏ oan)" || bad "PF-3 đỏ oan dù 'Giai đoạn' đã khớp (rc=$rc)"

# Nối dây: job `progress-freshness` phải chạy CẢ ở PR (không có `if:` chỉ-main). Khi nó chỉ chạy
# trên main, PROGRESS.md lỗi thời vẫn để PR xanh rồi làm đỏ main SAU khi merge (TRAPS 8, tái phát #245).
pf_if="$(awk '/^  progress-freshness:/{f=1;next} f&&/^  [A-Za-z]/{f=0} f&&/^    if:/' "$ROOT/.github/workflows/ci.yml")"
[ -z "$pf_if" ] && ok "job progress-freshness chạy cả ở PR (không có 'if:' chỉ-main)" || bad "job progress-freshness vẫn bị 'if:' loại khỏi PR: $pf_if"

# Đối chứng ngữ cảnh PR: CI checkout merge ref (main + nhánh PR, HEAD tách rời) và "Nhánh đang làm"
# là chính nhánh PR còn mở → PHẢI xanh, chạy ở PR không được báo oan.
d="$(setup_repo)" || exit 1
git init -q --bare "$WORK/origin-pr.git"
git -C "$d" remote add origin "$WORK/origin-pr.git"
git -C "$d" push -q origin HEAD:main 2>/dev/null
git -C "$d" checkout -qb feat-dang-mo
sed -i 's/^- Nhánh đang làm:.*/- Nhánh đang làm: `feat-dang-mo`/' "$d/PROGRESS.md"
git -C "$d" -c user.email=t@t.local -c user.name=test commit -qam "PR: PROGRESS.md trỏ nhánh đang mở"
git -C "$d" push -q origin HEAD:feat-dang-mo 2>/dev/null
git -C "$d" checkout -q --detach main
git -C "$d" -c user.email=t@t.local -c user.name=test merge -q --no-ff -m "Merge feat-dang-mo into main" feat-dang-mo
rc="$(run_check "$d" check-progress-freshness.sh)"
[ "$rc" = "0" ] && ok "XANH trên merge ref của PR đang mở (không báo oan khi chạy ở PR)" || bad "đỏ OAN trên merge ref của PR (rc=$rc)"


# F-305 (TRAPS 69): dòng SHA mất backtick → `grep -o` không khớp dưới pipefail từng giết script ngay PF-1,
# không ::error, không chạy PF-2/3/4. Kỳ vọng: rc khác 0 + ::error + các mục sau VẪN chạy (có tiêu đề).
d="$(setup_repo)" || exit 1
sed -i '/^- Default-branch SHA đã đối chiếu:/s/`//g' "$d/PROGRESS.md"
git -C "$d" -c user.email=t@t.local -c user.name=test commit -qam "PROGRESS.md mất backtick quanh SHA"
rc="$(run_check "$d" check-progress-freshness.sh)"
if [ "$rc" != "0" ] && grep -q '::error' "$WORK/check-output" \
   && grep -q 'PF-2' "$WORK/check-output" && grep -q 'PF-3' "$WORK/check-output" && grep -q 'PF-4' "$WORK/check-output"; then
  ok "SHA mất backtick → ::error và PF-2/PF-3/PF-4 vẫn chạy (F-305)"
else
  bad "SHA mất backtick: script chết im lặng hoặc bỏ các mục sau (rc=$rc)"
fi

finish "check-progress-freshness.sh bắt đúng lỗi (PF-1..PF-4, F-305) + không chặn oan."
