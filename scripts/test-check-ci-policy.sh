#!/usr/bin/env bash
# test-check-ci-policy.sh — CHỨNG MINH `check-ci-policy.sh` (CP-1..CP-6, bảng shell ↔ vitest) bắt đúng lỗi, không chặn oan.
#
# VÌ SAO TÁCH khỏi `test-check-scripts.sh` (2026-10-12): suite gốc vượt 400 dòng (radar, 417 dòng);
# fixture dùng chung ở `scripts/_check-scripts-test-lib.sh`. Mỗi ca dùng repo scratch/lịch sử riêng; không sửa repo thật.
#
# Chạy: bash scripts/test-check-ci-policy.sh
set -uo pipefail   # cố ý KHÔNG -e: một ca lỗi không được làm chết cả lượt chạy (docs/CONVENTIONS.md §A)

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
if command -v cygpath >/dev/null 2>&1; then ROOT="$(cygpath -m "$ROOT")"; fi
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

source "$ROOT/scripts/_test-lib.sh"
# shellcheck source=scripts/_check-scripts-test-lib.sh
source "$ROOT/scripts/_check-scripts-test-lib.sh"

## ============================================================
## 2. check-ci-policy.sh
## ============================================================
echo "== 2. check-ci-policy.sh =="

d="$(setup_repo)" || exit 1
rc="$(run_check "$d" check-ci-policy.sh)"
[ "$rc" = "0" ] && ok "baseline (bản sao sạch) → xanh" || bad "baseline lẽ ra phải xanh (rc=$rc)"

d="$(setup_repo)" || exit 1
# Gỡ pin SHA của action đầu tiên tìm thấy trong ci.yml (CP-2).
perl -0pi -e 's/uses: ([^@\s]+)@[0-9a-f]{40}(\s*#[^\n]*)?/uses: $1\@v4/' "$d/.github/workflows/ci.yml" 2>/dev/null || \
  sed -i.bak -E '0,/uses: [^@]+@[0-9a-f]{40}/s//uses: actions\/checkout@v4/' "$d/.github/workflows/ci.yml"
rm -f "$d/.github/workflows/ci.yml.bak"
rc="$(run_check "$d" check-ci-policy.sh)"
[ "$rc" = "1" ] && ok "bắt được action chưa ghim full SHA (CP-2)" || bad "KHÔNG bắt được action chưa ghim SHA (rc=$rc)"

d="$(setup_repo)" || exit 1
# Mẫu CI phát cho đích (ci-target.yml) cũng phải ghim SHA: bản trước chỉ quét .github/workflows/ → mẫu có thể trôi về
# tag di động mà không cổng nào bắt (rà lại audit 2026-10-10, F-A3).
sed -i -E '0,/uses: [^@]+@[0-9a-f]{40}/s//uses: actions\/checkout@v4/' "$d/docs/framework/templates/ci-target.yml"
rc="$(run_check "$d" check-ci-policy.sh)"
[ "$rc" = "1" ] && ok "bắt được action chưa ghim SHA trong mẫu ci-target.yml (CP-2)" || bad "KHÔNG bắt được action chưa ghim trong mẫu ci-target.yml (rc=$rc)"

d="$(setup_repo)" || exit 1
# ci.yml hiện không còn bước Node nào (ADR-0004 gỡ scaffold) — CP-3 vô hại nếu không có dòng
# node-version: nào để so; thêm 1 dòng giả vào job có thật để thực sự bài test được nhánh này.
printf '\n      - run: echo test\n        with:\n          node-version: "99.99.99"\n' >> "$d/.github/workflows/ci.yml"
rc="$(run_check "$d" check-ci-policy.sh)"
[ "$rc" = "1" ] && ok "bắt được node-version lệch .nvmrc (CP-3)" || bad "KHÔNG bắt được node-version lệch (rc=$rc)"

d="$(setup_repo)" || exit 1
sed -i.bak 's/needs: \[framework-lint, /needs: [/' "$d/.github/workflows/ci.yml" && rm -f "$d/.github/workflows/ci.yml.bak"
rc="$(run_check "$d" check-ci-policy.sh)"
[ "$rc" = "1" ] && ok "bắt được job thiếu trong needs: của gate (CP-4)" || bad "KHÔNG bắt được job thiếu trong needs (rc=$rc)"

d="$(setup_repo)" || exit 1
sed -i.bak '/^ci\.yml: framework-lint$/d' "$d/docs/ops/repository-settings.md" && rm -f "$d/docs/ops/repository-settings.md.bak"
rc="$(run_check "$d" check-ci-policy.sh)"
[ "$rc" = "1" ] && ok "bắt được job thật thiếu trong bản kê repository-settings.md (CP-1)" || bad "KHÔNG bắt được job thiếu trong bản kê (rc=$rc)"

d="$(setup_repo)" || exit 1
# Xoá dòng marker (dựng lúc chạy) → không còn bản kê job của repo khung; KHÔNG được xanh giả vì đọc nhầm
# khối required checks chung (chỉ gate+metadata).
marker_head='<!-- check-ci-policy:'
sed -i.bak "/^${marker_head}/d" "$d/docs/ops/repository-settings.md" && rm -f "$d/docs/ops/repository-settings.md.bak"
rc="$(run_check "$d" check-ci-policy.sh)"
[ "$rc" = "1" ] && ok "bắt được thiếu marker bản kê repo khung (CP-1, không đọc nhầm khối required checks chung)" || bad "KHÔNG bắt được thiếu marker (rc=$rc)"

# CP-5 — sổ job ĐƯỢC PHÉP skip. `gate` tính `skipped` là đạt, nên một job bị `if:` hỏng loại ra
# sẽ im lặng qua cổng. Hai chiều, vì sổ chỉ có giá trị khi khớp CHÍNH XÁC cả hai phía.
d="$(setup_repo)" || exit 1
# (a) thêm `if:` cho một job KHÔNG có trong sổ → job đó giờ skip được mà sổ không biết
perl -0pi -e 's/^(  framework-lint:\n)/$1    if: github.event_name == '"'"'push'"'"'\n/m' "$d/.github/workflows/ci.yml"
rc="$(run_check "$d" check-ci-policy.sh)"
[ "$rc" = "1" ] && ok "bắt được job skip-được nhưng thiếu trong sổ SKIP_ALLOWED (CP-5)" || bad "KHÔNG bắt được job skip-được ngoài sổ (rc=$rc)"

d="$(setup_repo)" || exit 1
# (b) chiều ngược: sổ kê tên một job KHÔNG có `if:` (không skip được) → sổ nói dối
sed -i 's/SKIP_ALLOWED: ""/SKIP_ALLOWED: "protection-guard"/' "$d/.github/workflows/ci.yml"
rc="$(run_check "$d" check-ci-policy.sh)"
[ "$rc" = "1" ] && ok "bắt được sổ SKIP_ALLOWED kê thừa một job không còn skip được (CP-5)" || bad "KHÔNG bắt được sổ kê thừa (rc=$rc)"

d="$(setup_repo)" || exit 1
# CP-6: thêm một scripts/test-*.sh mà không nối vào ci.yml — đúng khuôn đã làm 2 suite engine
# nằm đỏ im lặng qua nhiều PR sạch.
printf '#!/usr/bin/env bash
exit 0
' > "$d/scripts/test-mo-coi.sh"
rc="$(run_check "$d" check-ci-policy.sh)"
[ "$rc" = "1" ] && ok "bắt được test-*.sh không được ci.yml gọi (CP-6)" || bad "KHÔNG bắt được test mồ côi (rc=$rc)"

# F-303 (TRAPS 69): gọi từ scripts/ — script từng đọc chính nó qua `$0` sau `cd` về gốc repo nên grep
# không thấy file, 0 mục CP-* được đối chiếu mà vẫn in OK (rc 0). Kỳ vọng: rc 0 VÀ không có "No such file".
d="$(setup_repo)" || exit 1
( cd "$d/scripts" && bash check-ci-policy.sh >"$WORK/check-output" 2>&1 ); rc=$?
if [ "$rc" = "0" ] && ! grep -q 'No such file' "$WORK/check-output"; then
  ok "gọi từ thư mục scripts/ vẫn đọc được bảng CP-* của chính nó (F-303)"
else
  bad "gọi từ scripts/ hỏng (rc=$rc) hoặc grep không thấy file — gate xanh giả"
fi

# F-305 (TRAPS 69): xoá dòng `needs:` của job `gate` → phải ::error tường minh nhắc needs, không chết im lặng.
d="$(setup_repo)" || exit 1
awk '/^  gate:/{g=1} g&&/^    needs:/{g=0; next} {print}' "$d/.github/workflows/ci.yml" > "$d/ci.tmp" && mv "$d/ci.tmp" "$d/.github/workflows/ci.yml"
rc="$(run_check "$d" check-ci-policy.sh)"
if [ "$rc" = "1" ] && grep -q '::error.*needs' "$WORK/check-output"; then
  ok "thiếu dòng needs: của job gate → ::error nhắc needs (F-305)"
else
  bad "thiếu needs: của gate không có ::error chẩn đoán (rc=$rc)"
fi

# F-403: check-ci-policy mục 7 — bảng CP-* lệch shell ↔ vitest. Xoá CP-6 khỏi bản vitest → phải đỏ đúng mục 7.
d="$(setup_repo)" || exit 1
vitest="$d/scripts/ci-workflow-policy.test.ts"
if [ -f "$vitest" ]; then
  sed -i.bak '/CP-6/d' "$vitest" && rm -f "$vitest.bak"
  rc="$(run_check "$d" check-ci-policy.sh)"
  [ "$rc" != "0" ] && grep -q "CP-6.*KHÔNG được khai ở bản dropins" "$WORK/check-output" && ok "bắt được bảng CP-* lệch shell ↔ vitest (mục 7)" || bad "KHÔNG bắt được CP-* lệch (rc=$rc)"
else
  bad "không tìm thấy $vitest — ca mục 7 không chạy được"
fi

finish "check-ci-policy.sh bắt đúng lỗi + không chặn oan."
