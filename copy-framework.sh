#!/usr/bin/env bash
#
# copy-framework.sh — Mang bộ khung sang một DỰ ÁN KHÁC (kể cả dự án đã có sẵn).
#
# Cách dùng:
#   1) Clone repo khung này về máy (hoặc bạn đang đứng sẵn trong nó).
#   2) Chạy:   bash copy-framework.sh /đường-dẫn/tới/dự-án-đích
#   3) Mở phiên Claude Code TRONG dự án đích → AI tự đọc CLAUDE.md và tự dò stack.
#
# An toàn cho dự án đã có sẵn (brownfield):
#   - Tài liệu khung (docs/framework, mẫu ADR)  → copy thẳng (chỉ là tài liệu tham khảo mới).
#   - File gốc (CLAUDE.md, PROJECT.md...)        → chỉ copy nếu CHƯA có; nếu đã có thì để bản
#                                                  khung cạnh bên dưới đuôi .framework-new để bạn tự so.
#   - Cấu hình Claude Code (.claude/settings.json, .claude/hooks, .claude/agents,
#     scripts/dev-task.sh, scripts/usage-estimate.sh, 2 file .claude/*.example.sh)
#                                                  → chỉ copy nếu CHƯA có; nếu đã có thì để bản
#                                                  khung cạnh bên (đuôi .framework-new) để bạn tự so.
#   - File CI/quy ước GitHub (workflows, PR template, dependabot...) → KHÔNG đè; đưa vào
#     _framework-dropins/ để bạn tự so/merge với cấu hình CI đã có (nếu có).
#
# NÂNG BẢN khung ở dự án đích đã có khung:   bash copy-framework.sh /đích --upgrade
#   Với từng file Lớp 1: chưa sửa ở đích (hash khớp manifest trong FRAMEWORK-VERSION) → cập nhật;
#   đã sửa + repo khung còn commit cũ → `git merge-file` 3 chiều (marker xung đột nếu có);
#   đã sửa + không có base → giữ nguyên đích, để bản mới ở <file>.framework-new. KHÔNG BAO GIỜ mất
#   nội dung của đích (spec docs/specs/2026-09-23-nang-ban-khung-cho-du-an-dich.md).
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$SCRIPT_DIR"

TARGET=""; UPGRADE=0
for arg in "$@"; do
  case "$arg" in
    --upgrade) UPGRADE=1 ;;
    -*) echo "Lỗi: cờ không hợp lệ '$arg' (chỉ có --upgrade)."; exit 1 ;;
    *) TARGET="$arg" ;;
  esac
done
if [ -z "$TARGET" ]; then
  echo "Lỗi: thiếu đường dẫn dự án đích."
  echo "Dùng:  bash copy-framework.sh /đường-dẫn/tới/dự-án-đích [--upgrade]"
  exit 1
fi
if [ ! -d "$TARGET" ]; then
  echo "Lỗi: '$TARGET' không phải thư mục."
  exit 1
fi
if [ ! -d "$TARGET/.git" ]; then
  echo "Cảnh báo: '$TARGET' không có .git — chắc đây là gốc repo dự án chứ?"
fi

# ── Nâng bản: đọc dấu bản khung CŨ của đích trước khi ghi đè bất cứ gì ──
STAMP_REL="docs/framework/FRAMEWORK-VERSION"
OLD_COMMIT=""; OLD_MANIFEST="$(mktemp)"; trap 'rm -f "$OLD_MANIFEST"' EXIT
N_UPD=0; N_MERGE=0; N_ASIDE=0
if [ "$UPGRADE" -eq 1 ]; then
  if [ -f "$TARGET/$STAMP_REL" ]; then
    OLD_COMMIT="$(grep -m1 '^commit-nguon: ' "$TARGET/$STAMP_REL" | awk '{print $2}')"
    grep '^manifest: ' "$TARGET/$STAMP_REL" > "$OLD_MANIFEST" 2>/dev/null || true
    if [ -z "$OLD_COMMIT" ] || ! git -C "$SRC" cat-file -e "${OLD_COMMIT}^{commit}" 2>/dev/null; then
      echo "  ! commit-nguon '${OLD_COMMIT:-?}' không có trong lịch sử repo khung → không merge 3 chiều được; file đích đã sửa sẽ giữ nguyên, bản mới để cạnh (.framework-new)."
      OLD_COMMIT=""
    fi
  else
    echo "  ! --upgrade nhưng đích chưa có $STAMP_REL → chạy như copy lần đầu."
    UPGRADE=0
  fi
elif [ -f "$TARGET/$STAMP_REL" ]; then
  echo "  ℹ Đích đã có khung ($(grep -m1 '^commit-nguon: ' "$TARGET/$STAMP_REL" | awk '{print $2}')). Không có --upgrade → Lớp 1 bị GHI ĐÈ như cũ; muốn giữ chỉnh sửa cục bộ: thêm --upgrade."
fi

# ── Trợ giúp ──────────────────────────────────────────────
upgrade_file() {        # $1 = MỘT file Lớp 1 (đường dẫn tương đối) — chế độ --upgrade
  local rel="$1" src="$SRC/$1" dst="$TARGET/$1" cur old rc
  mkdir -p "$(dirname "$dst")"
  if [ ! -f "$dst" ]; then cp "$src" "$dst"; echo "  + $rel"; N_UPD=$((N_UPD+1)); return 0; fi
  if cmp -s "$src" "$dst"; then echo "  = $rel"; return 0; fi
  cur="$(git hash-object "$dst")"
  old="$(awk -v r="$rel" '$3==r{print $2; exit}' "$OLD_MANIFEST")"
  if [ -n "$old" ] && [ "$cur" = "$old" ]; then
    cp "$src" "$dst"; echo "  + $rel (đích chưa sửa → cập nhật)"; N_UPD=$((N_UPD+1)); return 0
  fi
  if [ -n "$OLD_COMMIT" ] && git -C "$SRC" show "$OLD_COMMIT:$rel" > "$dst.framework-base" 2>/dev/null; then
    rc=0; git merge-file -L "dự án đích" -L "khung cũ ($OLD_COMMIT)" -L "khung mới" "$dst" "$dst.framework-base" "$src" || rc=$?
    rm -f "$dst.framework-base"
    if [ "$rc" -ge 0 ] 2>/dev/null; then echo "  ~ $rel merge 3 chiều ($rc xung đột — tìm '<<<<<<<' nếu > 0)"; N_MERGE=$((N_MERGE+1)); return 0; fi
  fi
  rm -f "$dst.framework-base"
  cp "$src" "$dst.framework-new"; echo "  ~ $rel đích đã sửa, không có base → giữ đích, bản khung ở $rel.framework-new"; N_ASIDE=$((N_ASIDE+1))
}
copy_into() {           # copy thẳng (thư mục → copy NỘI DUNG vào đích, không lồng thừa khi chạy lại)
  local rel="$1"
  [ -e "$SRC/$rel" ] || return 0
  if [ "$UPGRADE" -eq 1 ]; then
    if [ -d "$SRC/$rel" ]; then
      while IFS= read -r -d '' f; do upgrade_file "${f#"$SRC"/}"; done < <(find "$SRC/$rel" -type f -print0 | sort -z)
    else
      upgrade_file "$rel"
    fi
    return 0
  fi
  if [ -d "$SRC/$rel" ]; then
    mkdir -p "$TARGET/$rel"
    cp -R "$SRC/$rel/." "$TARGET/$rel/"
  else
    mkdir -p "$TARGET/$(dirname "$rel")"
    cp "$SRC/$rel" "$TARGET/$rel"
  fi
  echo "  + $rel"
}
copy_if_absent() {      # chỉ copy nếu đích chưa có; nếu có thì để bản .framework-new
  local rel="$1"
  [ -e "$SRC/$rel" ] || return 0
  mkdir -p "$TARGET/$(dirname "$rel")"
  if [ -e "$TARGET/$rel" ]; then
    cp -R "$SRC/$rel" "$TARGET/$rel.framework-new"
    echo "  ~ $rel đã tồn tại → bản khung để ở $rel.framework-new (tự so/merge)"
  else
    cp -R "$SRC/$rel" "$TARGET/$rel"
    echo "  + $rel"
  fi
}
stage() {               # đưa vào _framework-dropins/ (không đụng file đang chạy)
  local rel="$1"
  [ -e "$SRC/$rel" ] || return 0
  if [ -d "$SRC/$rel" ]; then
    mkdir -p "$TARGET/_framework-dropins/$rel"
    cp -R "$SRC/$rel/." "$TARGET/_framework-dropins/$rel/"
  else
    mkdir -p "$TARGET/_framework-dropins/$(dirname "$rel")"
    cp "$SRC/$rel" "$TARGET/_framework-dropins/$rel"
  fi
  echo "  → _framework-dropins/$rel"
}

echo ""
echo "Nguồn:  $SRC"
echo "Đích:   $TARGET"
echo ""

# ── LỚP 1 — Quy trình & tiêu chuẩn (áp mọi stack): copy thẳng ──
echo "[1/4] Tài liệu khung (Lớp 1 — dùng được ngay, mọi stack):"
copy_into "docs/framework"
# docs/ops: chỉ copy TÀI LIỆU hướng dẫn. Bốn file *-PLAN/*-LOG/*-STATUS là TRẠNG THÁI nội bộ của repo
# khung (nhật ký /maintain, /completion, /audit-full của chính khung) — copy sang là nhiễu, và chạy lại
# để nâng bản sẽ ĐÈ MẤT nhật ký thật của dự án đích (sự cố ghi ở docs/reports/2026-09-23-de-xuat-nang-cap-khung-toan-dien.md C1).
for f in "$SRC"/docs/ops/*.md; do
  case "$(basename "$f")" in
    *-PLAN.md|*-LOG.md|*-STATUS.md) ;;                   # trạng thái riêng của khung — KHÔNG copy
    *) copy_into "docs/ops/$(basename "$f")" ;;
  esac
done
copy_if_absent "docs/specs/README.md"                # pr-policy.yml (Lớp 2) đòi docs/specs/ tồn tại cho PR feat
copy_if_absent "docs/goals/README.md"
copy_into ".claude/commands"                   # slash commands của khung: /consult /bootstrap /auto /gate /adr /ui-ux /audit-optimize /audit-full /completion /incident /grill /debug /maintain
copy_if_absent "docs/adr/0000-template.md"

# ── Dấu bản khung (luôn ghi đè — phản ánh LẦN COPY GẦN NHẤT) ──
# version (file VERSION của khung) + commit + ngày + MANIFEST hash từng file Lớp 1 vừa copy —
# để lần --upgrade sau biết file nào đích đã sửa tay (không cần lịch sử git của khung).
FRAMEWORK_COMMIT="$(git -C "$SRC" rev-parse --short HEAD 2>/dev/null || echo 'khong-ro')"
FRAMEWORK_VER="$(tr -d '[:space:]' < "$SRC/VERSION" 2>/dev/null || echo '0.0.0')"
layer1_files() {        # mọi file Lớp 1 (đúng tập copy_into ở trên), đường dẫn tương đối, NUL-separated
  find "$SRC/docs/framework" "$SRC/.claude/commands" -type f -print0
  find "$SRC/docs/ops" -maxdepth 1 -name '*.md' ! -name '*-PLAN.md' ! -name '*-LOG.md' ! -name '*-STATUS.md' -print0
}
{
  echo "# FRAMEWORK-VERSION — dấu bản khung đã copy (sinh tự động bởi copy-framework.sh — đừng sửa tay)"
  echo "version: $FRAMEWORK_VER"
  echo "commit-nguon: $FRAMEWORK_COMMIT"
  echo "ngay-copy: $(date +%F)"
  echo "# Nâng bản: clone repo khung mới nhất rồi chạy  bash copy-framework.sh <đích> --upgrade  (giữ chỉnh sửa cục bộ; xem CHANGELOG.md từ ${FRAMEWORK_COMMIT}..HEAD)"
  echo "# manifest: <git hash-object> <file> — file đích có hash KHÁC dòng này = đã sửa tay (--upgrade sẽ merge/để cạnh, không ghi đè)"
  while IFS= read -r -d '' f; do printf 'manifest: %s %s\n' "$(git hash-object "$f")" "${f#"$SRC"/}"; done < <(layer1_files | sort -z)
} > "$TARGET/$STAMP_REL"
echo "  + $STAMP_REL (bản khung: v$FRAMEWORK_VER @ $FRAMEWORK_COMMIT, manifest $(grep -c '^manifest: ' "$TARGET/$STAMP_REL") file)"
[ "$UPGRADE" -eq 1 ] && echo "  → --upgrade: $N_UPD cập nhật · $N_MERGE merge 3 chiều · $N_ASIDE giữ đích + .framework-new"

# ── File gốc dự án: chỉ copy nếu chưa có ──
copy_if_absent "CLAUDE.md"
copy_if_absent "AGENTS.md"                     # chuẩn mở agents.md — cho AI agent ngoài Claude Code (Cursor/Codex/Copilot...)
# File cầu nối sang AGENTS.md cho công cụ CHƯA tự đọc agents.md — không lặp nội dung, chỉ trỏ sang.
copy_if_absent "GEMINI.md"                     # Gemini CLI
# (Codex CLI đọc thẳng AGENTS.md — không cần file cầu nối riêng.)
copy_if_absent ".clinerules"                   # Cline / Roo Code
copy_if_absent ".windsurfrules"                # Windsurf
copy_if_absent ".cursor/rules"                 # Cursor
copy_if_absent ".github/copilot-instructions.md"  # GitHub Copilot
copy_if_absent "PROJECT.md"
# PROGRESS.md: dự án đích nhận bản MẪU SẠCH (PROGRESS.template.md) — KHÔNG nhận
# nhật ký phát triển của chính repo khung (PROGRESS.md ở repo khung là log của khung).
if [ -e "$TARGET/PROGRESS.md" ]; then
  echo "  ~ PROGRESS.md đã tồn tại → giữ nguyên"
else
  cp "$SRC/PROGRESS.template.md" "$TARGET/PROGRESS.md"
  echo "  + PROGRESS.md (từ mẫu sạch PROGRESS.template.md)"
fi
copy_if_absent "CHANGELOG.md"
copy_if_absent "CONTRIBUTING.md"
copy_if_absent "SECURITY.md"
# Quy tắc ứng xử: bản Contributor Covenant chung, dự án đích chỉ cần đổi kênh liên hệ.
# SUPPORT/GOVERNANCE KHÔNG copy bản của khung (nội dung riêng repo này) — dự án đích tự sinh
# từ docs/framework/templates/SUPPORT.template.md và GOVERNANCE.template.md.
copy_if_absent "CODE_OF_CONDUCT.md"
copy_if_absent ".editorconfig"
copy_if_absent ".nvmrc"
copy_if_absent ".mcp.json"                     # MCP Context7 — tài liệu đúng phiên bản cho research-first (KHUNG-3)
copy_if_absent ".mcp.json.example"             # mẫu MCP server phổ biến (github/filesystem/postgres) — dự án tự bật khi cần
copy_if_absent ".claude/settings.local.json.example"  # mẫu permission cá nhân, không dùng chung nhóm
# LICENSE KHÔNG copy: mỗi dự án tự chọn giấy phép + chủ sở hữu riêng.

# ── Cấu hình Claude Code + script tự động: copy thẳng (KHÔNG đè cấu hình đã có) ──
echo ""
echo "[2/4] Cấu hình Claude Code (model tiêu chuẩn Sonnet 5 — tối ưu token) + script tự động (hook gọi qua dev-task.sh):"
mkdir -p "$TARGET/.claude"
if [ -e "$TARGET/.claude/settings.json" ]; then
  cp "$SRC/.claude/settings-shared-default.json" "$TARGET/.claude/settings.json.framework-new"
  echo "  ~ .claude/settings.json đã tồn tại → bản khung để ở settings.json.framework-new (tự so/merge)"
else
  cp "$SRC/.claude/settings-shared-default.json" "$TARGET/.claude/settings.json"
  echo "  + .claude/settings.json (Sonnet 5; fallback Sonnet 5 → Haiku 4.5)"
fi
copy_if_absent ".claude/hooks"
copy_if_absent ".claude/agents"
# Hook phụ thuộc các script này — thiếu thì hook no-op (mất auto-format + cổng chặn commit đỏ + nhắc quota):
copy_if_absent "scripts/dev-task.sh"
copy_if_absent "scripts/_stack-detect.sh"          # dev-task.sh + maintenance-sweep.sh source file này
copy_if_absent "scripts/githooks/pre-commit"       # hàng rào harness-agnostic: git config core.hooksPath scripts/githooks
copy_if_absent "scripts/usage-estimate.sh"
copy_if_absent "scripts/test-usage-estimate.sh"
copy_if_absent "scripts/subagent-dispatch.py"
# Helper dùng chung — PHẢI phát trước các script source/exec chúng, nếu không dự án đích nhận
# script gãy (khuôn lỗi TRAPS.md mục 19: danh sách file viết tay không biết về file mới).
copy_if_absent "scripts/_python-exec.sh"
copy_if_absent "scripts/_test-lib.sh"
copy_if_absent "scripts/subagent-dispatch.sh"
copy_if_absent "scripts/model-rates.json"
copy_if_absent "scripts/model-capability-tiers.json"
copy_if_absent "scripts/telemetry-log.py"
copy_if_absent "scripts/telemetry-log.sh"
copy_if_absent "scripts/spec-compiler.py"
copy_if_absent "scripts/spec-compiler.sh"
copy_if_absent "scripts/arch-health-radar.py"
copy_if_absent "scripts/arch-health-radar.sh"
copy_if_absent "scripts/test-telemetry-and-dispatch.sh"
copy_if_absent "tests/test_telemetry_integrity.py"  # required by the shipped telemetry self-test
copy_if_absent "scripts/test-next-gen-engines.sh"
# Agent bảo trì toàn diện (spec 2026-09-14): engine quét + runner đa-provider + 2 self-test (smoke ở dự án đích)
copy_if_absent "scripts/maintenance-sweep.sh"
copy_if_absent "scripts/maintain-run.sh"
copy_if_absent "scripts/test-maintenance-sweep.sh"
copy_if_absent "scripts/test-maintain-run.sh"
copy_if_absent "scripts/maintain-cron.sh"
copy_if_absent "scripts/test-maintain-cron.sh"
# Test chứng minh hook cổng CHẶN thật (audit 2026-09-12, F-002) — đi cùng .claude/hooks ở trên.
copy_if_absent "scripts/test-hooks-gate.sh"
copy_if_absent "scripts/requirements-ci.txt"       # ghim radon/coverage cho ci.yml dropin (Dependabot pip theo dõi)
# 2 file mẫu để dự án tự điền (bản điền thật .claude/*.sh đã nằm trong .gitignore của khung):
copy_if_absent ".claude/project-commands.example.sh"
copy_if_absent ".claude/usage-budget.example.sh"
chmod +x "$TARGET/scripts/dev-task.sh" "$TARGET/scripts/githooks/pre-commit" "$TARGET/scripts/usage-estimate.sh" "$TARGET/scripts/test-hooks-gate.sh" "$TARGET/scripts/maintenance-sweep.sh" "$TARGET/scripts/maintain-run.sh" "$TARGET/scripts/maintain-cron.sh" 2>/dev/null || true
chmod +x "$TARGET/.claude/hooks/"*.sh 2>/dev/null || true

echo ""
echo "[3/4] File CI/quy ước GitHub (Lớp 2 — KHÔNG đè; để bạn tự so/merge với CI đã có):"
for f in \
  .github/workflows/ci.yml .github/workflows/stale-pr-alert.yml .github/workflows/maintenance.yml \
  .github/workflows/secret-scan.yml .github/workflows/dependency-review.yml \
  .github/workflows/pr-policy.yml .github/workflows/release.yml \
  .github/workflows/codeql.yml .github/workflows/scorecard.yml \
  .github/pull_request_template.md .github/dependabot.yml .github/ISSUE_TEMPLATE .github/CODEOWNERS \
  .github/rulesets/main.json \
  .gitignore .gitattributes \
  scripts/ci-workflow-policy.test.ts \
; do
  stage "$f"
done

echo ""
echo "[4/4] Xong. Tiếp theo trong dự án đích:"
cat <<'NEXT'

  1) Cấu hình Claude Code đã sẵn sàng: .claude/settings.json dùng model tiêu chuẩn Sonnet 5.
     → Việc lập kế hoạch lớn: chủ động /model sang model cao cấp nhất đang sẵn có, xong tự /model
       claude-sonnet-5 quay lại — không còn chế độ opusplan tự chuyển (ADR-0007, CLI đã ngừng hỗ trợ).
     → Hook tự động (auto-format + chặn commit đỏ + nhắc quota) chạy qua scripts/dev-task.sh
       (tự dò stack). Dự án có lệnh riêng → copy .claude/project-commands.example.sh
       thành .claude/project-commands.sh rồi điền.
     ✅ Dự án rất phức tạp: nâng riêng lúc cần bằng /model claude-opus-5-5 (hoặc claude-fable-5-1).

  2) Mở phiên Claude Code NGAY TRONG dự án đích.
     → AI tự đọc CLAUDE.md + .claude/settings.json (model tiêu chuẩn sẵn sàng).
     → Chạy Bước 0 của docs/framework/existing-project-adoption.md
       (tự dò stack bằng cách đọc package.json/config — không cần bạn khai stack).

  3) Soát thư mục _framework-dropins/ : so/merge các file CI (.github/workflows/*,
     PR template, dependabot, CODEOWNERS, .gitignore, .gitattributes) với cấu hình
     CI đã có (nếu có) rồi merge cho khớp dự án. Xong thì có thể xóa _framework-dropins/.

  4) Commit, rồi áp khung tăng dần theo existing-project-adoption.md
     (Prettier → ESLint → TS strict → hook → CI → lấp lỗ hổng test/a11y/hiệu năng).

  5) Muốn hoàn thiện toàn dự án (hết lỗi đã biết, tính năng thống nhất, có bằng chứng):
     gõ /completion — audit 12 nhóm → kế hoạch chi tiết (duyệt) → sửa từng đợt → quét lại đến khi sạch.

  (Tùy chọn) Muốn luật áp cho MỌI dự án trên máy: chép CLAUDE.md vào ~/.claude/CLAUDE.md.
NEXT
echo ""
