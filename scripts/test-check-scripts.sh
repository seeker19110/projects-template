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
# check-progress-freshness.sh: suite riêng `scripts/test-check-progress-freshness.sh` (tách 2026-10-11, trần 400 dòng).
#
# Chạy: bash scripts/test-check-scripts.sh
set -uo pipefail   # cố ý KHÔNG -e: một ca lỗi không được làm chết cả lượt chạy (docs/CONVENTIONS.md §A)

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
if command -v cygpath >/dev/null 2>&1; then ROOT="$(cygpath -m "$ROOT")"; fi
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

source "$ROOT/scripts/_test-lib.sh"

# shellcheck source=scripts/_check-scripts-test-lib.sh
source "$ROOT/scripts/_check-scripts-test-lib.sh"

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
# Mục 12–14 nằm ở scripts/_docs-consistency-structure.sh (check-docs-consistency.sh source); ca dưới chạy qua script gốc.
# Mục 12: mẫu mới trong templates/ mà không tài liệu nào nhắc tên → phải đỏ (F-R02, 2026-10-09).
# Dựng tên lúc chạy để chính file test này không phải là "tài liệu nhắc tên" hay bị mục 1 bắt.
zeta="ZETA-MO-COI"
printf '# mẫu mồ côi\n' > "$d/docs/framework/templates/${zeta}.template.md"
git -C "$d" add -A
rc="$(run_check "$d" check-docs-consistency.sh)"
[ "$rc" = "1" ] && grep -q "template" "$WORK/check-output" && ok "bắt được mẫu mồ côi (mục 12)" || bad "KHÔNG bắt được mẫu mồ côi (rc=$rc)"

d="$(setup_repo)" || exit 1
# Mục 11: script mới có trong CODEMAP.md nhưng KHÔNG có trong FEATURE-MAP.md → phải đỏ đúng ở mục 11 (F-N01, 2026-10-06:
# FEATURE-MAP từng thiếu 7 engine/cổng mà không cổng nào báo). Khai CODEMAP để cô lập: mục 6 không được là lý do đỏ.
zeta="zeta-engine"   # dựng tên lúc chạy: viết literal trong backtick sẽ bị mục 1 coi là tham chiếu hỏng của chính file test này
printf '#!/usr/bin/env bash\nexit 0\n' > "$d/scripts/$zeta.sh"; chmod +x "$d/scripts/$zeta.sh"
printf '\n| Sửa zeta | `scripts/%s.sh` | test |\n' "$zeta" >> "$d/CODEMAP.md"
git -C "$d" add -A
rc="$(run_check "$d" check-docs-consistency.sh)"
[ "$rc" = "1" ] && grep -q "FEATURE-MAP" "$WORK/check-output" && ok "bắt được script chưa khai trong FEATURE-MAP.md (mục 11)" || bad "KHÔNG bắt được script thiếu trong FEATURE-MAP (rc=$rc)"

d="$(setup_repo)" || exit 1
# Mục 10: bảng Markdown có hàng THỪA Ô. GitHub lặng lẽ bỏ ô thừa và `|` trong backtick VẪN tách ô, nên chữ
# sau đó biến mất (đã gặp thật ở docs/ops/repository-settings.md và báo cáo audit 2026-10-05).
printf '\n| Cot A | Cot B |\n| --- | --- |\n| `a|b` | c |\n' >> "$d/README.md"
rc="$(run_check "$d" check-docs-consistency.sh)"
[ "$rc" = "1" ] && ok "bắt được hàng bảng thừa ô do | trong backtick (mục 10)" || bad "KHÔNG bắt được hàng bảng thừa ô (rc=$rc)"

d="$(setup_repo)" || exit 1
# Đối chứng: `\|` đã escape, và bảng nằm trong khối code, đều hợp lệ — chặn là chặn oan.
printf '\n| Cot A | Cot B |\n| --- | --- |\n| `a\\|b` | c |\n\n```\n| x |\n| --- |\n| a | b | c |\n```\n' >> "$d/README.md"
rc="$(run_check "$d" check-docs-consistency.sh)"
[ "$rc" = "0" ] && ok "bảng escape đúng + bảng trong code fence → cho qua (mục 10)" || bad "chặn OAN bảng hợp lệ (rc=$rc)"

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
# Mục 11 cũng đòi script có mặt trong FEATURE-MAP.md (F-N01) — khai cả hai để ca này cô lập đúng mục 6.
printf '| FT-99 | Việc giả lập | script-moi-da-khai.sh | | ✅ | test |\n' >> "$d/docs/FEATURE-MAP.md"
rc="$(run_check "$d" check-docs-consistency.sh)"
[ "$rc" = "0" ] && ok "script đã khai trong CODEMAP.md thì mục 6 XANH (không đỏ oan)" || bad "mục 6 đỏ oan với script đã khai (rc=$rc)"

d="$(setup_repo)" || exit 1
# Mục 7 (audit 2026-09-13, B-02): engine khai ở CLAUDE.md §1 mà AGENTS.md không nhắc -> ĐỎ.
# Xoá đúng một tên engine khỏi AGENTS.md để tái hiện hình dạng lệch đã xảy ra thật.
sed -i 's|scripts/spec-compiler.sh|scripts/DA-XOA-KHOI-AGENTS.sh|g' "$d/AGENTS.md"
rc="$(run_check "$d" check-docs-consistency.sh)"
[ "$rc" = "1" ] && ok "bắt được engine khai ở CLAUDE.md nhưng thiếu trong AGENTS.md (mục 7)" || bad "KHÔNG bắt được lệch CLAUDE.md/AGENTS.md (rc=$rc)"

# Mục 13 (2026-10-09): thư mục docs/work/ là Work ID — khuôn ngày-slug và đúng MỘT hồ sơ trạng thái.
for case_ in "ten-sai:Ten_Sai:working.md" "ca-hai:2026-10-09-ca-hai:working.md done.md" "khong-ho-so:2026-10-09-rong:"; do
  IFS=: read -r label dir files <<<"$case_"
  d="$(setup_repo)" || exit 1
  mkdir -p "$d/docs/work/$dir"
  for f in $files; do printf '# x\n' > "$d/docs/work/$dir/$f"; done
  [ -n "$files" ] || printf 'x\n' > "$d/docs/work/$dir/note.txt"
  rc="$(run_check "$d" check-docs-consistency.sh)"
  [ "$rc" = "1" ] && grep -q 'mục 13\|docs/work' "$WORK/check-output" && ok "bắt được hồ sơ docs/work sai ($label, mục 13)" || bad "KHÔNG bắt được hồ sơ docs/work sai ($label, rc=$rc)"
done

d="$(setup_repo)" || exit 1
# Mục 11b (2026-10-09): ID FT-xx trùng trong FEATURE-MAP (đã xảy ra thật: FT-66 cấp hai lần ở #240).
printf '| FT-01 | Trùng ID giả lập | x | | ✅ | test |\n' >> "$d/docs/FEATURE-MAP.md"
rc="$(run_check "$d" check-docs-consistency.sh)"
[ "$rc" = "1" ] && grep -q 'FT-01' "$WORK/check-output" && ok "bắt được ID trùng trong FEATURE-MAP.md (mục 11b)" || bad "KHÔNG bắt được ID FT trùng (rc=$rc)"

d="$(setup_repo)" || exit 1
# F-201: cổng quét cả đuôi .py/.css — trước đó tham chiếu tới engine Python/stylesheet có thể mục âm thầm.
# Ghép chuỗi lúc chạy để chính mục 1 không bắt file test này.
fake_py="scripts/engine-khong-ton-tai"; fake_py="${fake_py}.py"
printf '\nEngine: `%s`\n' "$fake_py" >> "$d/README.md"
rc="$(run_check "$d" check-docs-consistency.sh)"
[ "$rc" = "1" ] && ok "bắt được tham chiếu .py gãy (mục 1, đuôi mới)" || bad "KHÔNG bắt được .py gãy (rc=$rc)"

d="$(setup_repo)" || exit 1
fake_css="styles/khong-ton-tai"; fake_css="${fake_css}.css"
printf '\nTokens: `%s`\n' "$fake_css" >> "$d/README.md"
rc="$(run_check "$d" check-docs-consistency.sh)"
[ "$rc" = "1" ] && ok "bắt được tham chiếu .css gãy (mục 1, đuôi mới)" || bad "KHÔNG bắt được .css gãy (rc=$rc)"

d="$(setup_repo)" || exit 1
# Đối chứng: tham chiếu tới file .py/.css CÓ THẬT thì xanh (không chặn oan).
real_py="scripts/spec-compiler"; real_py="${real_py}.py"
real_css="styles/co-that"; real_css="${real_css}.css"
mkdir -p "$d/styles"; printf 'body{}\n' > "$d/$real_css"
printf '\nEngine: `%s`, tokens: `%s`\n' "$real_py" "$real_css" >> "$d/README.md"
git -C "$d" add -A
rc="$(run_check "$d" check-docs-consistency.sh)"
[ "$rc" = "0" ] && ok "KHÔNG chặn oan tham chiếu .py/.css có thật (mục 1)" || bad "chặn OAN .py/.css có thật (rc=$rc)"

# F-403: 4 nhánh docs-consistency trước đây không có ca đỏ nào. Mỗi ca cài đúng một lỗi, đòi rc khác 0 VÀ đúng mục.
d="$(setup_repo)" || exit 1
# Mục 2 — tên file cũ còn sót. Dựng tên cũ lúc chạy để chính mục 2 không bắt file test này.
old_name="KHUNG-1"; old_name="${old_name}.md"
printf '\nTài liệu cũ: %s\n' "$old_name" >> "$d/README.md"
rc="$(run_check "$d" check-docs-consistency.sh)"
[ "$rc" != "0" ] && grep -q 'Tên cũ' "$WORK/check-output" && ok "bắt được tên file CŨ còn sót (mục 2)" || bad "KHÔNG bắt được tên cũ còn sót (rc=$rc)"

d="$(setup_repo)" || exit 1
# Mục 3 chiều A — có file lệnh nhưng CLAUDE.md chưa khai.
printf -- '---\ndescription: lệnh giả cho test\n---\nNội dung.\n' > "$d/.claude/commands/lenh-chua-khai.md"
rc="$(run_check "$d" check-docs-consistency.sh)"
[ "$rc" != "0" ] && grep -q 'chưa được CLAUDE.md khai' "$WORK/check-output" && ok "bắt được lệnh có file nhưng CLAUDE.md chưa khai (mục 3 chiều A)" || bad "KHÔNG bắt được lệnh chưa khai (rc=$rc)"

d="$(setup_repo)" || exit 1
# Mục 3 chiều B — CLAUDE.md nhắc /tên nhưng không có file lệnh.
ghost="lenh-khong-ton-tai"
printf '\nGõ `/%s` để thử.\n' "$ghost" >> "$d/CLAUDE.md"
rc="$(run_check "$d" check-docs-consistency.sh)"
[ "$rc" != "0" ] && grep -q 'nhưng không có .claude/commands' "$WORK/check-output" && ok "bắt được CLAUDE.md nhắc lệnh không có file (mục 3 chiều B)" || bad "KHÔNG bắt được lệnh ma (rc=$rc)"

d="$(setup_repo)" || exit 1
# Mục 4b — agent có file nhưng không được nhắc trong bảng route.
printf -- '---\nname: agent-mo-coi\ndescription: >-\n  Agent giả cho test.\n---\nNội dung.\n' > "$d/.claude/agents/agent-mo-coi.md"
rc="$(run_check "$d" check-docs-consistency.sh)"
[ "$rc" != "0" ] && grep -q "agent-mo-coi.*KHÔNG được nhắc" "$WORK/check-output" && ok "bắt được subagent không có trong bảng route (mục 4b)" || bad "KHÔNG bắt được agent mồ côi (rc=$rc)"

## ============================================================
## 2. check-ci-policy.sh
## ============================================================
# Mục 14 (audit 2026-10-09, T5): hook nối trong settings phải có trong bảng Hook của models-and-automation.md và ngược lại.
d="$(setup_repo)" || exit 1
sed -i '/^| `block-dangerous-git.sh` | PreToolUse(Bash) |/d' "$d/docs/framework/models-and-automation.md"
rc="$(run_check "$d" check-docs-consistency.sh)"
[ "$rc" != "0" ] && ok "negative: hook có trong settings nhưng mất khỏi bảng Hook → đỏ" || bad "negative: xoá dòng bảng Hook mà vẫn xanh (mục 14 chưa bắt)"
d="$(setup_repo)" || exit 1
sed -i '/^| `precompact-checkpoint.sh` | PreCompact |/a | `ma-hook.sh` | Stop | dòng mồ côi trong bảng |' "$d/docs/framework/models-and-automation.md"
rc="$(run_check "$d" check-docs-consistency.sh)"
[ "$rc" != "0" ] && ok "negative: bảng Hook có hook không nối trong settings → đỏ" || bad "negative: hook mồ côi trong bảng mà vẫn xanh"

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

# Mục 15 (2026-10-12, đối chiếu vòng lặp coding N3): goal file "tuyên bố xong" phải có bằng chứng — failure mode #1 của
# loop dài là "declares victory". Slice DONE không có ô Evidence → đỏ; file COMPLETE còn slice mở → đỏ; đủ bằng chứng → xanh.
d="$(setup_repo)" || exit 1
printf '# Goal: x\n\n| ID | Outcome | State | Evidence |\n| --- | --- | --- | --- |\n| S1 | a | DONE | |\n' > "$d/docs/goals/2026-10-12-giả.md"
rc="$(run_check "$d" check-docs-consistency.sh)"
[ "$rc" = "1" ] && grep -q 'docs/goals/2026-10-12-giả.md' "$WORK/check-output" && ok "bắt được slice DONE không có Evidence (mục 15)" || bad "KHÔNG bắt được DONE thiếu Evidence (rc=$rc)"

d="$(setup_repo)" || exit 1
printf '# Goal: x\n\n| Thuộc tính | Giá trị |\n| --- | --- |\n| State | COMPLETE |\n\n| ID | Outcome | State | Evidence |\n| --- | --- | --- | --- |\n| S1 | a | DONE | PR #1 |\n| S2 | b | BUILD | |\n' > "$d/docs/goals/2026-10-12-giả.md"
rc="$(run_check "$d" check-docs-consistency.sh)"
[ "$rc" = "1" ] && grep -q 'S2' "$WORK/check-output" && ok "bắt được goal COMPLETE còn slice BUILD (mục 15)" || bad "KHÔNG bắt được COMPLETE còn slice mở (rc=$rc)"

d="$(setup_repo)" || exit 1
printf '# Goal: x\n\n| Thuộc tính | Giá trị |\n| --- | --- |\n| State | COMPLETE |\n\n| ID | Outcome | State | Nghiệm thu |\n| --- | --- | --- | --- |\n| S1 | a | DONE, merged | PR #1 → abc |\n| S2 | b | DROPPED | ngoài scope |\n' > "$d/docs/goals/2026-10-12-giả.md"
git -C "$d" add -A
rc="$(run_check "$d" check-docs-consistency.sh)"
[ "$rc" = "0" ] && ok "KHÔNG chặn oan goal COMPLETE đủ bằng chứng (DONE/DROPPED, cột Nghiệm thu) (mục 15)" || bad "chặn OAN goal đủ bằng chứng (rc=$rc)"

# Mục 13b (2026-10-12, đối chiếu stored K1): done.md là tín hiệu DỪNG của auto-complete-guard → nội dung phải có nghiệm thu thật.
# Sự cố thật: b7bd718 đưa done.md còn "Trạng thái: Active" + placeholder lên nhánh (git mv sau khi sửa giữ blob cũ, TRAPS 70).
mk_done() {  # $1 = repo giả, $2 = dòng trạng thái, $3 = nội dung "Nghiệm thu cuối"
  mkdir -p "$1/docs/work/2026-10-12-gia-done"
  printf '# Công việc: x\n\n- Work ID: 2026-10-12-gia-done\n- Trạng thái: %s\n\n## Nghiệm thu cuối (chỉ điền khi đủ bằng chứng)\n\n%s\n' "$2" "$3" > "$1/docs/work/2026-10-12-gia-done/done.md"
}
d="$(setup_repo)" || exit 1
mk_done "$d" "Active (chờ PR)" "- PR MERGED: #12 → abc1234"
rc="$(run_check "$d" check-docs-consistency.sh)"
[ "$rc" = "1" ] && grep -q 'mục 13b' "$WORK/check-output" && ok "bắt được done.md chưa Done (mục 13b)" || bad "KHÔNG bắt được done.md còn Active (rc=$rc)"

d="$(setup_repo)" || exit 1
mk_done "$d" "Done 2026-10-12" "<DoD, mọi PR MERGED + merge SHA và main đã đối chiếu, giới hạn/rủi ro còn lại,
ngày và người nghiệm thu theo ủy quyền.>"
rc="$(run_check "$d" check-docs-consistency.sh)"
[ "$rc" = "1" ] && grep -q 'placeholder' "$WORK/check-output" && ok "bắt được done.md còn placeholder (mục 13b)" || bad "KHÔNG bắt được done.md còn placeholder mẫu (rc=$rc)"

d="$(setup_repo)" || exit 1
mk_done "$d" "Done 2026-10-12" "- DoD đạt, đã merge."
rc="$(run_check "$d" check-docs-consistency.sh)"
[ "$rc" = "1" ] && grep -q 'PR/SHA' "$WORK/check-output" && ok "bắt được done.md không có PR/SHA (mục 13b)" || bad "KHÔNG bắt được done.md thiếu PR/SHA (rc=$rc)"

d="$(setup_repo)" || exit 1
mk_done "$d" "Done 2026-10-12 (PR #12)" "- PR MERGED: #12 → \`abc1234\` trên main; DoD đạt."
git -C "$d" add -A
rc="$(run_check "$d" check-docs-consistency.sh)"
[ "$rc" = "0" ] && ok "KHÔNG chặn oan done.md đủ nghiệm thu (mục 13b)" || bad "chặn OAN done.md đủ nghiệm thu (rc=$rc)"

# Mục 16 (2026-10-12, đối chiếu stored K2): ADR phải ghi ≥ 2 phương án đã cân nhắc/loại — chọn kiến trúc tự động mà không có
# phương án loại là hội tụ sớm (ADR 0003/0004 dùng tiêu đề "Phương án đã loại": chấp nhận cả hai tiêu đề).
mk_adr() { printf '# ADR-0099: giả\n\n## Bối cảnh\n\nx\n\n## Quyết định\n\ny\n%s\n## Hệ quả\n\nz\n' "$1" > "$d/docs/adr/0099-gia.md"; }
d="$(setup_repo)" || exit 1
mk_adr ""
rc="$(run_check "$d" check-docs-consistency.sh)"
[ "$rc" = "1" ] && grep -q 'mục 16' "$WORK/check-output" && ok "bắt được ADR không có mục phương án (mục 16)" || bad "KHÔNG bắt được ADR thiếu mục phương án (rc=$rc)"

d="$(setup_repo)" || exit 1
mk_adr $'\n## Các phương án đã cân nhắc\n\n- Phương án A: chỉ một.\n'
rc="$(run_check "$d" check-docs-consistency.sh)"
[ "$rc" = "1" ] && grep -q '0099-gia' "$WORK/check-output" && ok "bắt được ADR chỉ 1 phương án (mục 16)" || bad "KHÔNG bắt được ADR 1 phương án (rc=$rc)"

d="$(setup_repo)" || exit 1
mk_adr $'\n## Phương án đã loại\n\n| Phương án | Vì sao loại |\n| --- | --- |\n| A | đắt |\n| B | chậm |\n'
git -C "$d" add -A
rc="$(run_check "$d" check-docs-consistency.sh)"
[ "$rc" = "0" ] && ok "KHÔNG chặn oan ADR 2 phương án (mục 16)" || bad "chặn OAN ADR 2 phương án dạng bảng (rc=$rc)"

d="$(setup_repo)" || exit 1
mk_adr $'\n## Các phương án đã cân nhắc\n\n**A. Giữ nguyên.** rẻ nhưng không kiểm được.\n\n**B. Cổng máy.** chọn.\n'
git -C "$d" add -A
rc="$(run_check "$d" check-docs-consistency.sh)"
[ "$rc" = "0" ] && ok "KHÔNG chặn oan ADR phương án dạng đoạn in đậm (mục 16)" || bad "chặn OAN ADR phương án '**A. …**' (rc=$rc)"


finish "check-docs-consistency.sh + check-ci-policy.sh bắt đúng lỗi + không chặn oan."
