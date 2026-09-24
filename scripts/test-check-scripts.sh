#!/usr/bin/env bash
# test-check-scripts.sh — CHỨNG MINH 3 gate của chính bộ khung thật sự BẮT được lỗi, không chỉ
# chạy không crash.
#
# VÌ SAO CẦN (audit toàn diện 2026-09-12, G-001): `check-docs-consistency.sh`, `check-ci-policy.sh`,
# `check-progress-freshness.sh` chưa từng có negative-test tự động — các lượt "NT: ... → rc=1" ghi
# trong `docs/ops/COMPLETION-PLAN.md` đều chạy TAY một lần rồi bỏ, không phải cổng lặp lại được. Một
# sửa tương lai có thể vô tình làm gate mất khả năng phát hiện lỗi mà CI không hề biết (gate
# "xanh giả" — cùng khuôn F-002 mà `test-hooks-gate.sh` đã chốt chặn cho hook, giờ áp cho 3 script này).
#
# Sandbox lấy nội dung working tree của file đã track (kể cả staged additions), nên cổng
# trước commit kiểm đúng bản đang sửa. File untracked không được sao chép vào fixture.
# Mỗi ca dùng repo scratch/lịch sử riêng; không sửa repo thật.
#
# Chạy: bash scripts/test-check-scripts.sh
set -uo pipefail   # cố ý KHÔNG -e: một ca lỗi không được làm chết cả lượt chạy (docs/CONVENTIONS.md §A)

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
if command -v cygpath >/dev/null 2>&1; then ROOT="$(cygpath -m "$ROOT")"; fi
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

source "$ROOT/scripts/_test-lib.sh"

# --- Dựng bản sao cây file đã track của repo thật vào một git repo mới, sạch. ---
# Lịch sử mới hoàn toàn khác repo thật (SHA khác) — nên sau khi commit, tự sửa lại dòng
# "Default-branch SHA đã đối chiếu" trong PROGRESS.md trỏ đúng vào chính commit đó (tự tham chiếu,
# luôn là tổ tiên của chính nó), để baseline của check-progress-freshness.sh xanh như thật.
setup_repo() (   # subshell fail-fast: fixture hỏng phải dừng cả suite
  set -e
  local dir="$WORK/repo-$RANDOM-$RANDOM"
  mkdir -p "$dir"
  if command -v cygpath >/dev/null 2>&1; then dir="$(cygpath -m "$dir")"; fi
  (cd "$ROOT" && git ls-files -z | while IFS= read -r -d '' path; do
    if [ -e "$path" ] || [ -L "$path" ]; then printf '%s\0' "$path"; fi
  done | tar --null -T - -cf -) | (cd "$dir" && tar -xf -)
  git -C "$dir" init -q
  git -C "$dir" config core.safecrlf false
  git -C "$dir" -c user.email=t@t.local -c user.name=test add -A
  git -C "$dir" -c user.email=t@t.local -c user.name=test commit -q -m init
  local head_sha; head_sha="$(git -C "$dir" rev-parse HEAD)"
  sed -i.bak "s/^- Default-branch SHA đã đối chiếu:.*/- Default-branch SHA đã đối chiếu: \`$head_sha\`/" "$dir/PROGRESS.md"
  # Các trường fixture được dựng rõ ràng, không phụ thuộc văn xuôi tùy chọn của repo thật.
  sed -i.bak2 '/^- Nhánh đang làm:/d; /^- Giai đoạn:/d' "$dir/PROGRESS.md"
  printf '\n- Nhánh đang làm: `main`\n- Giai đoạn: GĐ 8.\n' >> "$dir/PROGRESS.md"
  rm -f "$dir/PROGRESS.md.bak" "$dir/PROGRESS.md.bak2"
  git -C "$dir" -c user.email=t@t.local -c user.name=test commit -q -am "chuẩn hoá PROGRESS.md cho baseline test"
  printf '%s\n' "$dir"
)

run_check() {   # $1 = thư mục repo, $2 = tên script (đường dẫn tương đối từ scripts/)
  ( cd "$1" && bash "scripts/$2" >"$WORK/check-output" 2>&1 )
  echo $?
}

# Giữ stdout/stderr ca vừa chạy để lỗi CI có đủ bằng chứng chẩn đoán.
bad() {
  echo "  ❌ $1"
  fails=$((fails+1))
  cat "$WORK/check-output" >&2
}

## ============================================================
## 1. check-docs-consistency.sh
## ============================================================
echo "== 1. check-docs-consistency.sh =="

d="$(setup_repo)" || exit 1
rc="$(run_check "$d" check-docs-consistency.sh)"
[ "$rc" = "0" ] && ok "baseline (bản sao sạch) → xanh" || bad "baseline lẽ ra phải xanh (rc=$rc)"

d="$(setup_repo)" || exit 1
# Ghép chuỗi lúc chạy, KHÔNG để backtick bọc thẳng một đường dẫn có đuôi .md ngay trong SOURCE của
# chính file này — nếu không, mục 1 của check-docs-consistency.sh sẽ tưởng đây là tham chiếu backtick
# thật khi quét scripts/test-check-scripts.sh, gây cổng đỏ OAN trên chính repo thật.
fake_ref="docs/khong-ton-tai-thuc-su"; fake_ref="${fake_ref}.md"
printf '\nTham chiếu hỏng: `%s`\n' "$fake_ref" >> "$d/README.md"
rc="$(run_check "$d" check-docs-consistency.sh)"
[ "$rc" = "1" ] && ok "bắt được link gãy trong backtick (mục 1)" || bad "KHÔNG bắt được link gãy (rc=$rc) — cổng mất tác dụng"

d="$(setup_repo)" || exit 1
sed -i.bak 's/^name: reviewer$/name: reviewer-sai-ten/' "$d/.claude/agents/reviewer.md" && rm -f "$d/.claude/agents/reviewer.md.bak"
rc="$(run_check "$d" check-docs-consistency.sh)"
[ "$rc" = "1" ] && ok "bắt được frontmatter name lệch tên file (mục 4a)" || bad "KHÔNG bắt được name lệch (rc=$rc)"

d="$(setup_repo)" || exit 1
printf '\nroute:ghost     → ma-khong-ton-tai\n' >> "$d/docs/framework/orchestration-3-tier.md"
rc="$(run_check "$d" check-docs-consistency.sh)"
[ "$rc" = "1" ] && ok "bắt được route: trỏ agent ảo (mục 4c)" || bad "KHÔNG bắt được route trỏ agent ảo (rc=$rc)"

d="$(setup_repo)" || exit 1
# G-003/G-004: nhãn effort đã rút lại sống lại — sửa vào bản sao, KHÔNG ghép trực tiếp cụm
# "Opus" + dấu · + từ chỉ effort cũ ngay trong SOURCE của chính test này (cùng bẫy đã gặp ở
# test link gãy phía trên — mục 5 của check-docs-consistency.sh quét mọi *.sh theo đúng chuỗi đó).
stale_word="hi"; stale_word="${stale_word}gh"
sed -i "s/Opus · medium/Opus · ${stale_word}/" "$d/docs/framework/orchestration-3-tier.md"
rc="$(run_check "$d" check-docs-consistency.sh)"
[ "$rc" = "1" ] && ok "bắt được nhãn effort đã rút lại sống lại (mục 5, G-003/G-004)" || bad "KHÔNG bắt được nhãn effort cũ sống lại (rc=$rc)"

d="$(setup_repo)" || exit 1
# Mục 5b: ID model đã ngừng sống lại (dựng chuỗi lúc chạy để chính test này không bị mục 5b bắt).
stale_id="claude-fable-"; stale_id="${stale_id}5\`"
printf '\nNâng \`/model %s cho ca khó.\n' "$stale_id" >> "$d/docs/framework/orchestration-3-tier.md"
rc="$(run_check "$d" check-docs-consistency.sh)"
[ "$rc" = "1" ] && ok "bắt được ID model cũ/thiếu hậu tố sống lại (mục 5b)" || bad "KHÔNG bắt được ID model cũ sống lại (rc=$rc)"

d="$(setup_repo)" || exit 1
# Mục 9: CLAUDE.md phình bằng một dòng dài > 2000 ký tự → phải đỏ.
printf -- '- %s\n' "$(head -c 2100 /dev/zero | tr '\0' 'x')" >> "$d/CLAUDE.md"
rc="$(run_check "$d" check-docs-consistency.sh)"
[ "$rc" = "1" ] && ok "bắt được CLAUDE.md có dòng > 2000 ký tự (mục 9)" || bad "KHÔNG bắt được dòng dài trong CLAUDE.md (rc=$rc)"

d="$(setup_repo)" || exit 1
# Mục 8: ký tự điều khiển vô hình trong *.md. Chèn BACKSPACE (0x08) — đúng ca đã gặp thật khi
# một chuỗi Python thường chứa  sinh ra tài liệu (2026-09-15). Ký tự được DỰNG LÚC CHẠY bằng
# printf, không viết thẳng vào source của test này: một ký tự điều khiển nằm trong chính file test
# sẽ làm mục 8 đỏ oan trên repo thật (cùng bẫy đã mắc ở ca link gãy và ca nhãn effort phía trên).
printf 'Dong co ky tu %svo hinh
' "$(printf '')" >> "$d/README.md"
rc="$(run_check "$d" check-docs-consistency.sh)"
[ "$rc" = "1" ] && ok "bắt được ký tự điều khiển vô hình trong *.md (mục 8)" || bad "KHÔNG bắt được ký tự điều khiển trong *.md (rc=$rc)"

d="$(setup_repo)" || exit 1
# Đối chứng: TAB và CR là ký tự văn bản HỢP LỆ — chặn chúng là chặn oan (bảng Markdown dùng tab,
# file checkout trên Windows có CR). Mục 8 phải bỏ qua cả hai.
printf 'Cot1%sCot2%s
' "$(printf '	')" "$(printf '
')" >> "$d/README.md"
rc="$(run_check "$d" check-docs-consistency.sh)"
[ "$rc" = "0" ] && ok "KHÔNG chặn oan TAB/CR trong *.md (đối chứng mục 8)" || bad "chặn OAN tab/CR (rc=$rc)"

d="$(setup_repo)" || exit 1
# Mục 6 (audit 2026-09-13, CAO-2): script mới mà quên khai trong CODEMAP.md phải làm ĐỎ.
printf '#!/usr/bin/env bash\nexit 0\n' > "$d/scripts/script-moi-chua-khai.sh"
rc="$(run_check "$d" check-docs-consistency.sh)"
[ "$rc" = "1" ] && ok "bắt được script mới chưa khai trong CODEMAP.md (mục 6)" || bad "KHÔNG bắt được script chưa khai CODEMAP (rc=$rc)"

d="$(setup_repo)" || exit 1
# Chiều ngược: khai đủ thì phải XANH — chứng minh mục 6 không đỏ oan mọi lúc.
printf '#!/usr/bin/env bash\nexit 0\n' > "$d/scripts/script-moi-da-khai.sh"
# CỐ Ý không bọc backtick quanh đường dẫn fixture: mục 1 quét đường dẫn trong backtick ở mọi
# *.sh và sẽ báo file giả lập này "không tồn tại" (đã mắc thật khi viết ca test này). Mục 6 chỉ
# grep tên file nên không cần backtick.
printf '| Việc giả lập | scripts/script-moi-da-khai.sh | test |\n' >> "$d/CODEMAP.md"
rc="$(run_check "$d" check-docs-consistency.sh)"
[ "$rc" = "0" ] && ok "script đã khai trong CODEMAP.md thì mục 6 XANH (không đỏ oan)" || bad "mục 6 đỏ oan với script đã khai (rc=$rc)"

d="$(setup_repo)" || exit 1
# Mục 7 (audit 2026-09-13, B-02): engine khai ở CLAUDE.md §1 mà AGENTS.md không nhắc -> ĐỎ.
# Xoá đúng một tên engine khỏi AGENTS.md để tái hiện hình dạng lệch đã xảy ra thật.
sed -i 's|scripts/spec-compiler.sh|scripts/DA-XOA-KHOI-AGENTS.sh|g' "$d/AGENTS.md"
rc="$(run_check "$d" check-docs-consistency.sh)"
[ "$rc" = "1" ] && ok "bắt được engine khai ở CLAUDE.md nhưng thiếu trong AGENTS.md (mục 7)" || bad "KHÔNG bắt được lệch CLAUDE.md/AGENTS.md (rc=$rc)"

d="$(setup_repo)" || exit 1
# Đối chứng: không đụng gì thì mục 7 phải XANH (bản sao sạch đã có đủ 4 engine ở cả hai file).
rc="$(run_check "$d" check-docs-consistency.sh)"
[ "$rc" = "0" ] && ok "mục 7 XANH khi CLAUDE.md và AGENTS.md khớp (không đỏ oan)" || bad "mục 7 đỏ oan trên bản sao sạch (rc=$rc)"

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

# CP-5 — sổ job ĐƯỢC PHÉP skip. `gate` tính `skipped` là đạt, nên một job bị `if:` hỏng loại ra
# sẽ im lặng qua cổng. Hai chiều, vì sổ chỉ có giá trị khi khớp CHÍNH XÁC cả hai phía.
d="$(setup_repo)" || exit 1
# (a) thêm `if:` cho một job KHÔNG có trong sổ → job đó giờ skip được mà sổ không biết
perl -0pi -e 's/^(  framework-lint:\n)/$1    if: github.event_name == '"'"'push'"'"'\n/m' "$d/.github/workflows/ci.yml"
rc="$(run_check "$d" check-ci-policy.sh)"
[ "$rc" = "1" ] && ok "bắt được job skip-được nhưng thiếu trong sổ SKIP_ALLOWED (CP-5)" || bad "KHÔNG bắt được job skip-được ngoài sổ (rc=$rc)"

d="$(setup_repo)" || exit 1
# (b) chiều ngược: bỏ `if:` của progress-freshness → nó không skip được nữa mà sổ vẫn kê tên
perl -0pi -e "s/^    if: github\.event_name == 'push' && github\.ref == 'refs\/heads\/main'\n//m" "$d/.github/workflows/ci.yml"
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

if [ "$fails" -eq 0 ]; then
  echo "OK — cả 3 gate (docs-consistency, ci-policy, progress-freshness) đều bắt đúng lỗi + không chặn oan."
else
  echo "❌ $fails ca thất bại — xem chi tiết ở trên."
fi
exit "$fails"
