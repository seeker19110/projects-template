#!/usr/bin/env bash
# Kiểm tra tính nhất quán tài liệu của repo khung:
#   1. Đường dẫn file trong backtick (`path/to/file.ext`) phải tồn tại thật — trừ các file
#      được sinh ra sau này tại dự án đích, hoặc do người dùng tự tạo từ `.example.*`.
#   2. Tên file/lệnh cũ (trước lần đổi tên sang tiếng Anh, PR #24) không còn sót lại
#      ngoài bảng ánh xạ (docs/framework/README.md) và nhật ký lịch sử (PROGRESS.md).
# Chạy: bash scripts/check-docs-consistency.sh
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

fail=0

# Các file này CỐ Ý chứa tên cũ/đường dẫn chưa-tồn-tại trong repo này: PROGRESS.md ghi lại
# lịch sử (tên gọi đúng lúc viết), docs/framework/README.md là bảng ánh xạ tên cũ → tên mới,
# case-study-*.md tường thuật đường dẫn của một dự án demo tạm thời (không phải repo này).
# CHANGELOG.md/TRAPS.md: nhật ký/append-only — không viết lại lịch sử (ADR-0004: các file scaffold
# Web mà chúng nhắc tới đã bị xoá khỏi repo khung 2026-09-12, nhưng ghi chép lúc đó là đúng).
# docs/ops/COMPLETION-PLAN.md, COMPREHENSIVE-AUDIT-STATUS.md: bản ghi audit ĐÃ ĐÓNG của một lượt
# quét cụ thể — cùng lý do, không viết lại phát hiện đã ghi nhận tại thời điểm quét.
EXCLUDE_SOURCE=(
  "PROGRESS.md" "docs/framework/README.md" "docs/framework/case-study-greenfield-dry-run.md"
  "CHANGELOG.md" "TRAPS.md" "docs/ops/COMPLETION-PLAN.md" "docs/ops/COMPREHENSIVE-AUDIT-STATUS.md"
  "docs/adr/0004-remove-default-web-scaffold.md"
  # Characterization test dựng repo TỔNG HỢP trong thư mục tạm: mọi đường dẫn trong nó
  # (scripts/beta.sh, docs/specs/weak.md …) là FIXTURE cố ý không tồn tại, không phải
  # tham chiếu tài liệu hỏng.
  "scripts/test-engine-characterization.sh"
)

# Thư mục nguồn được miễn trừ theo TIỀN TỐ. `docs/specs/` là contract HƯỚNG TỚI TƯƠNG LAI: một
# feature spec mô tả file nó sẽ tạo khi được thực thi, nên tham chiếu tới file chưa tồn tại là
# BẢN CHẤT của nó, không phải lỗi. Nếu không miễn trừ, mọi spec mới đều làm cổng này đỏ và áp lực
# sẽ là viết spec mờ đi (bỏ backtick) — tức cổng làm hỏng đúng thứ nó bảo vệ.
EXCLUDE_SOURCE_PREFIX=("docs/specs/")

# Đường dẫn được nhắc tới trong docs nhưng KHÔNG đóng gói sẵn trong repo khung này:
# sinh ra tại dự án đích (`/completion`, `/audit-full`), hoặc người dùng tự tạo từ
# `.example.*`, hoặc là file chuẩn của scaffold Next.js sau khi `create-next-app`.
# Gỡ khỏi danh sách này khi repo khung BẮT ĐẦU có file thật (audit 2026-09-12, F-016): giữ lại
# entry cho file đã tồn tại sẽ khiến cổng im lặng khi file bị xoá.
ALLOW_MISSING_PATH=(
  "app/layout.tsx" "lib/example.test.ts"
  ".claude/project-commands.sh" ".claude/settings-sonnet.json" ".claude/usage-budget.sh"
  # Ví dụ minh hoạ hồ sơ Web (ADR-0004, 2026-09-12) — scaffold thật đã gỡ khỏi repo khung;
  # các đường dẫn này chỉ còn xuất hiện trong tài liệu như PATTERN cho dự án đích tự tạo.
  "app/error.tsx" "app/global-error.tsx" "app/manifest.ts" "app/not-found.tsx" "app/robots.ts" \
  "app/sitemap.ts" "app/sw.ts" "components/theme-toggle.tsx" "e2e/smoke.spec.ts" \
  "i18n/request.ts" "lib/env.ts" "messages/en.json" "messages/vi.json" \
  ".github/workflows/lighthouse-ci.yml" "scripts/verify-dropins.sh"
  # Sinh tại runtime bởi /maintain (maintenance-sweep.sh + agent maintainer), không đóng gói sẵn.
  "docs/ops/MAINTENANCE-REPORT.md" "docs/ops/MAINTENANCE-PLAN.md" "docs/ops/MAINTENANCE-LOG.md"
  # Ví dụ minh hoạ quy ước đặt tên changelog (quality-supplements-group1.md mục 9) — file thật
  # sinh ở dự án đích khi cần, không đóng gói sẵn trong repo khung.
  "docs/changelog/0012-2026-09-19-them-xac-thuc-2fa.md"
)

is_in() { local needle="$1"; shift; for x in "$@"; do [ "$x" = "$needle" ] && return 0; done; return 1; }

# `--untracked` (audit 2026-09-12, F-017): git grep mặc định CHỈ quét file đã track → file .md mới
# chưa `git add` không được kiểm, cổng báo PASS oan cho tới lúc commit. Xảy ra thật trong phiên
# 2026-09-12: một tham chiếu gãy chỉ lộ ra sau khi commit.
grep_files() {
  git grep --untracked -l "$@" -- '*.md' '*.sh' '*.ps1' 2>/dev/null || true
}

echo "== 1. Đường dẫn file tham chiếu trong backtick =="
mapfile -t refs < <(
  git grep --untracked -hoE '`[A-Za-z0-9_./-]+\.(md|sh|ps1|json|ts|tsx|yml|cjs|mjs)`' \
    -- '*.md' '*.sh' '*.ps1' 2>/dev/null \
  | tr -d '`' | sort -u
)
for ref in "${refs[@]}"; do
  [[ "$ref" == */* ]] || continue
  [[ -e "$ref" ]] && continue
  is_in "$ref" "${ALLOW_MISSING_PATH[@]}" && continue
  # Chỉ báo lỗi nếu tham chiếu này KHÔNG xuất phát duy nhất từ file được miễn trừ.
  refFiles=$(grep_files -F -- "\`$ref\`")
  onlyExcluded=1
  for f in $refFiles; do
    f="${f#./}"
    if is_in "$f" "${EXCLUDE_SOURCE[@]}"; then continue; fi
    excludedByPrefix=0
    for pre in "${EXCLUDE_SOURCE_PREFIX[@]}"; do
      case "$f" in "$pre"*) excludedByPrefix=1 ;; esac
    done
    [ "$excludedByPrefix" -eq 1 ] || onlyExcluded=0
  done
  if [ "$onlyExcluded" -eq 0 ] || [ -z "$refFiles" ]; then
    echo "::error::Tham chiếu file không tồn tại: $ref (trong: $refFiles)"
    fail=1
  fi
done

echo "== 2. Tên file/lệnh cũ còn sót (ngoài bảng ánh xạ + nhật ký) =="
OLD_NAMES=(
  "KHUNG-1.md" "KHUNG-2.md" "KHUNG-3.md"
  "KHOI-TAO-du-an-moi.md" "AP-DUNG-vao-du-an-co-san.md" "BO-SUNG-chat-luong.md" "MODEL-va-TU-DONG.md"
  "audit-toan-dien-prompt.md" "audit-toi-uu-prompt.md"
  "thuc-thi.md" "tra-cuu.md" "kiem-tra-phien-ban.md"
  "HUONG-DAN"
)
for name in "${OLD_NAMES[@]}"; do
  hits=$(grep_files -F -- "$name")
  for f in $hits; do
    f="${f#./}"
    is_in "$f" "${EXCLUDE_SOURCE[@]}" "scripts/check-docs-consistency.sh" && continue
    echo "::error::Tên cũ \"$name\" còn sót ngoài bảng ánh xạ/nhật ký: $f"
    fail=1
  done
done

echo "== 3. Lệnh (.claude/commands) ↔ CLAUDE.md khớp hai chiều =="
# CLAUDE.md bị ép ngắn (< 200 dòng) trong khi số lệnh cứ tăng → rất dễ lệch:
# thêm lệnh mà quên khai TRIGGER, hoặc xóa/đổi tên lệnh mà CLAUDE.md vẫn trỏ tới.
# Kiểm cả hai chiều để máy bắt thay vì rà tay.

# Chiều A: mỗi file lệnh phải được CLAUDE.md nhắc tới (qua đường dẫn hoặc `/tên`).
for cmd in .claude/commands/*.md; do
  [ -e "$cmd" ] || continue
  name="$(basename "$cmd" .md)"
  if ! grep -qF -e "\`$cmd\`" -e "\`/$name\`" CLAUDE.md; then
    echo "::error::Lệnh $cmd chưa được CLAUDE.md khai (thiếu \`$cmd\` hoặc \`/$name\`)"
    fail=1
  fi
done

# Chiều B: mỗi `/tên` CLAUDE.md nhắc tới phải có file lệnh thật.
# Miễn trừ: skill dựng sẵn của Claude Code, không nằm trong .claude/commands/ của repo.
BUILTIN_COMMANDS=("code-review" "security-review" "simplify" "loop")
mapfile -t slashRefs < <(
  grep -hoE '`/[a-z][a-z0-9-]*`' CLAUDE.md | tr -d '`/' | sort -u
)
for name in "${slashRefs[@]}"; do
  is_in "$name" "${BUILTIN_COMMANDS[@]}" && continue
  [ -f ".claude/commands/$name.md" ] && continue
  echo "::error::CLAUDE.md nhắc \`/$name\` nhưng không có .claude/commands/$name.md"
  fail=1
done

# ── 4. Subagent (.claude/agents) ↔ bảng nhãn `route:` trong orchestration-3-tier.md ──
# VÌ SAO (audit 2026-09-12, F-006): 8 subagent + kiến trúc điều phối 3 tầng trước đây KHÔNG có
# cổng máy nào — thêm/xoá/đổi tên agent mà quên tài liệu thì `/auto` dispatch tới một nhãn
# `route:` trỏ vào agent không tồn tại, và hỏng đó chỉ lộ ra giữa lúc đang chạy tự động.
echo "== 4. Subagent ↔ bảng route trong orchestration-3-tier.md =="
ORCH="docs/framework/orchestration-3-tier.md"
for f in .claude/agents/*.md; do
  [ -e "$f" ] || continue
  base="$(basename "$f" .md)"
  # (a) frontmatter `name:` phải khớp tên file
  nm="$(grep -m1 '^name:' "$f" | sed -E 's/^name:[[:space:]]*//; s/[[:space:]]*$//')"
  if [ -z "$nm" ]; then
    echo "::error file=$f::Thiếu frontmatter 'name:' — Claude Code không nạp được subagent này."
    fail=1
  elif [ "$nm" != "$base" ]; then
    echo "::error file=$f::frontmatter name '$nm' lệch tên file '$base' — giao việc theo tên file sẽ không tìm thấy agent."
    fail=1
  fi
  # (b) phải được nhắc tới trong tài liệu điều phối
  if ! grep -q "$base" "$ORCH"; then
    echo "::error file=$ORCH::Subagent '$base' tồn tại nhưng KHÔNG được nhắc trong $ORCH — bổ sung vào bảng route/hậu kiểm."
    fail=1
  fi
done
# (c) chiều ngược: mọi nhãn route: trong tài liệu phải trỏ tới agent có thật
while IFS= read -r agent; do
  [ -n "$agent" ] || continue
  if [ ! -e ".claude/agents/$agent.md" ]; then
    echo "::error file=$ORCH::Bảng route trỏ tới agent '$agent' nhưng .claude/agents/$agent.md không tồn tại."
    fail=1
  fi
done < <(grep -oE 'route:[a-z]+[[:space:]]+→[[:space:]]+[a-z-]+' "$ORCH" | sed -E 's/.*→[[:space:]]*//' | sort -u)

# --- 5. Nhãn effort đã bị RÚT LẠI không được sống lại (audit 2026-09-12, G-003/G-004). ---
# VÌ SAO: chốt 2026-09-12 hạ effort trần của route:complex từ "Opus · high" xuống "Opus · medium"
# (PR #69). Quy ước đó được chép tay ở NHIỀU file (orchestration-3-tier.md có 2 chỗ trong CÙNG
# file, .claude/agents/, models-and-automation.md, auto.md) — không có nguồn duy nhất, nên PR #69
# sửa xong vẫn sót một chỗ ngay trong chính file nó vừa sửa (bắt được ở audit toàn diện kế tiếp,
# không phải bởi cổng nào). Đây là chốt hẹp: cấm CHUỖI CỤ THỂ đã biết là sai sống lại, không cố
# tổng quát hoá thành trình phân tích ngữ nghĩa (prose mỗi nơi viết một kiểu, dễ báo oan).
echo "== 5. Nhãn effort đã rút lại ('Opus · high') không còn sót =="
STALE_EFFORT_EXCLUDE=(
  "TRAPS.md" "CHANGELOG.md" "PROGRESS.md" "docs/ops/COMPREHENSIVE-AUDIT-STATUS.md"
  "docs/ops/COMPLETION-PLAN.md" "scripts/check-docs-consistency.sh"
)
while IFS= read -r hit; do
  [ -n "$hit" ] || continue
  file="${hit%%:*}"; rest="${hit#*:}"; lineno="${rest%%:*}"
  is_in "$file" "${STALE_EFFORT_EXCLUDE[@]}" && continue
  case "$file" in docs/specs/*) continue ;; esac
  echo "::error file=$file,line=$lineno::Nhãn 'Opus · high' đã bị rút lại (route:complex trần effort medium từ 2026-09-12) nhưng còn sót ở đây — sửa thành 'Opus · medium' hoặc xoá nếu không còn liên quan (G-003/G-004)."
  fail=1
done < <(git grep --untracked -noE 'Opus[[:space:]]*·[[:space:]]*\*{0,2}high' -- '*.md' '*.sh' '*.ps1' 2>/dev/null || true)

# --- 5b. ID model đã ngừng / sai chính tả không được sống lại (audit 2026-09-23, C6). ---
# VÌ SAO: `audit-full.md` dạy người dùng gõ `/model claude-opus-4-8` (không còn) và `claude-fable-5`
# (thiếu `-1`) — làm theo là lỗi ngay trước bước tổng hợp. Tên model được chép tay ở ~10 file; đây là
# chốt hẹp cùng khuôn mục 5: cấm CHUỖI đã biết là sai, không phân tích ngữ nghĩa. ID hiện hành:
# scripts/model-capability-tiers.json (nguồn duy nhất). Thêm chuỗi mới vào STALE_MODEL_RE khi một ID ngừng.
echo "== 5b. ID model cũ (claude-opus-4-*, claude-fable-5 thiếu -1, 'Opus 4.8') không còn sót =="
STALE_MODEL_RE='claude-opus-4-[0-9]|claude-fable-5([^-0-9]|$)|Opus 4\.8'
while IFS= read -r hit; do
  [ -n "$hit" ] || continue
  file="${hit%%:*}"; rest="${hit#*:}"; lineno="${rest%%:*}"
  is_in "$file" "${STALE_EFFORT_EXCLUDE[@]}" && continue
  case "$file" in docs/specs/*|docs/reports/*|docs/research/*|docs/adr/*) continue ;; esac
  echo "::error file=$file,line=$lineno::ID model đã ngừng/sai (claude-opus-4-x, claude-fable-5 thiếu '-1', 'Opus 4.8') còn sót — dùng ID hiện hành trong scripts/model-capability-tiers.json (claude-opus-5-5 / claude-fable-5-1)."
  fail=1
done < <(git grep --untracked -noE "$STALE_MODEL_RE" -- '*.md' '*.sh' '*.ps1' '*.json' 2>/dev/null || true)


# ── 6. Mọi script trong scripts/ phải được CODEMAP.md khai (audit 2026-09-13, CAO-2). ──
# VÌ SAO: PR #89/#91 thêm 4 engine (~650 dòng Python) mà KHÔNG thêm dòng nào vào CODEMAP.md và
# không khai trong CLAUDE.md §1. Hậu quả không phải "docs xấu" mà là CODE CHẾT: một phiên AI mới
# chỉ đọc CLAUDE.md/CODEMAP.md nên không bao giờ biết 4 engine đó tồn tại. Cổng cũ chỉ kiểm hai
# chiều LỆNH ↔ CLAUDE.md (mục 3), không kiểm SCRIPT ↔ CODEMAP — nên lỗ hổng này lọt sạch.
# CỐ Ý chỉ kiểm SỰ CÓ MẶT của tên file trong CODEMAP.md, không kiểm nội dung mô tả: ép nội dung sẽ
# biến cổng thành vật cản mỗi lần sửa một dòng bảng (cùng lý lẽ với ci-workflow-policy.test.ts).
echo "== 6. Script (scripts/) ↔ CODEMAP.md =="
CODEMAP_FILE="CODEMAP.md"
# Script phụ trợ CỐ Ý không cần dòng riêng trong CODEMAP (bản wrapper mỏng gọi thẳng file .py cùng
# tên đã được khai, hoặc dữ liệu đi kèm). Thêm vào đây phải kèm lý do, không thêm để né cổng.
CODEMAP_EXEMPT=(
  "arch-health-radar.sh" "spec-compiler.sh" "subagent-dispatch.sh" "telemetry-log.sh"
)
if [ ! -f "$CODEMAP_FILE" ]; then
  echo "::error::Không tìm thấy $CODEMAP_FILE — không đối chiếu được script ↔ bản đồ sửa-ở-đâu."
  fail=1
else
  seen_any=0
  for f in scripts/*.sh scripts/*.py scripts/*.json scripts/*.ts; do
    [ -e "$f" ] || continue
    seen_any=1
    base="$(basename "$f")"
    is_in "$base" "${CODEMAP_EXEMPT[@]}" && continue
    if ! grep -qF "$base" "$CODEMAP_FILE"; then
      echo "::error file=$CODEMAP_FILE::Script '$f' tồn tại nhưng KHÔNG được khai trong $CODEMAP_FILE — thêm một dòng 'sửa ở đâu → cổng nào chặn' cho nó (CLAUDE.md §8 bước 0: tài liệu đi CÙNG PR), hoặc khai lý do miễn trừ ở CODEMAP_EXEMPT trong $0."
      fail=1
    fi
  done
  # Tự bảo vệ khỏi test rỗng luôn xanh (cùng nguyên tắc F-002): glob không khớp gì là bất thường.
  if [ "$seen_any" -eq 0 ]; then
    echo "::error::Không tìm thấy script nào trong scripts/ — glob hỏng, mục 6 đang xanh giả."
    fail=1
  fi
fi

# ── 7. Engine khai ở CLAUDE.md §1 phải có mặt trong AGENTS.md (audit 2026-09-13, B-02). ──
# VÌ SAO: CLAUDE.md §1 bắt "sửa luật cốt lõi ở đây thì soát lại AGENTS.md cho khớp", nhưng KHÔNG
# cổng nào kiểm — nên CLAUDE.md khai 4 engine trong khi AGENTS.md chỉ kê 2, lệch âm thầm suốt
# nhiều PR. Đúng khuôn TRAPS.md mục 11: luật có, cơ chế thi hành không có.
# CỐ Ý hẹp: chỉ đối chiếu DANH SÁCH ENGINE (thứ agent ngoài Claude Code cần biết để gọi), không
# so ngữ nghĩa toàn văn hai file — prose mỗi bên viết một kiểu, so toàn văn sẽ báo oan liên tục
# (cùng lý lẽ đã ghi ở mục 5).
echo "== 7. Engine trong CLAUDE.md §1 ↔ AGENTS.md =="
if [ ! -f AGENTS.md ] || [ ! -f CLAUDE.md ]; then
  echo "OK — thiếu CLAUDE.md hoặc AGENTS.md (không áp dụng)."
else
  engine_line="$(grep -m1 -F 'Engine chạy được trong' CLAUDE.md || true)"
  if [ -z "$engine_line" ]; then
    echo "OK — CLAUDE.md không có mục khai engine (không áp dụng)."
  else
    mapfile -t engines < <(printf '%s' "$engine_line" | grep -oE '`scripts/[a-z0-9-]+\.sh`' | tr -d '\`' | sort -u)
    if [ "${#engines[@]}" -eq 0 ]; then
      echo "::error file=CLAUDE.md::Có mục 'Engine chạy được trong scripts/' nhưng không đọc được tên engine nào trong dấu \`...\` — mục 7 đang xanh giả."
      fail=1
    else
      for eng in "${engines[@]}"; do
        base="$(basename "$eng")"
        if ! grep -qF "$base" AGENTS.md; then
          echo "::error file=AGENTS.md::CLAUDE.md §1 khai engine '$eng' nhưng AGENTS.md KHÔNG nhắc tới — agent ngoài Claude Code sẽ không biết engine này tồn tại. Bổ sung vào mục engine của AGENTS.md (CLAUDE.md §1: sửa luật ở CLAUDE.md thì soát lại AGENTS.md cho khớp)."
          fail=1
        fi
      done
    fi
  fi
fi

echo "== 8. Ký tự điều khiển vô hình trong *.md =="
# VÌ SAO CẦN (2026-09-15, gặp thật khi rút gọn PROGRESS.md): một chuỗi Python thường chứa "\b"
# KHÔNG phải hai ký tự literal mà là BACKSPACE (0x08). Khi sinh tài liệu bằng script, ký tự đó
# lọt vào giữa hai backtick của PROGRESS.md và KHÔNG cổng nào bắt — docs-consistency xanh cả
# trước lẫn sau. Phát hiện được chỉ vì tình cờ đọc lại `cat -A`.
#
# Tổng quát: **ký tự điều khiển trong tài liệu là hỏng IM LẶNG** — trình soạn thảo và trình xem
# Markdown đều không hiển thị, diff cũng không nêu, nên nó sống vô thời hạn và làm bẩn mọi bản
# sao chép về sau. Cùng họ với TRAPS mục 27 (CRLF): thứ Git/công cụ coi là "văn bản" vẫn có thể
# mang byte mà con người không thấy.
#
# Mẫu được DỰNG LÚC CHẠY bằng printf: nếu viết ký tự điều khiển thật vào source của chính script
# này thì nó sẽ tự khớp chính mình (khuôn "bộ dò tự khớp văn bản của thứ nó đang soi" — xem
# block-dangerous-git.sh). Giữ lại TAB (011), LF (012), CR (015) vì đó là ký tự văn bản hợp lệ.
# KHÔNG soi NUL (000): không truyền được qua biến shell, và một .md có NUL thì đã là file nhị
# phân chứ không phải lỗi tài liệu.
ctrl_class="$(printf '[\001-\010\013\014\016-\037\177]')"
while IFS= read -r mdfile; do
  [ -f "$mdfile" ] || continue
  if hits="$(LC_ALL=C grep -n "$ctrl_class" "$mdfile" 2>/dev/null)"; then
    line_no="$(printf '%s' "$hits" | head -1 | cut -d: -f1)"
    echo "::error file=$mdfile,line=$line_no::Co ky tu dieu khien vo hinh (vi du backspace 0x08) trong file Markdown -- trinh xem khong hien thi nen loi song im lang. Tim bang: LC_ALL=C grep -n \"\$(printf '[\001-\010\013\014\016-\037\177]')\" $mdfile | cat -A"
    fail=1
  fi
done < <(git ls-files '*.md')


if [ "$fail" -eq 0 ]; then
  echo "OK — không phát hiện link gãy, tên cũ sót lại, lệnh lệch với CLAUDE.md, hay ký tự điều khiển trong *.md."
fi
exit "$fail"
