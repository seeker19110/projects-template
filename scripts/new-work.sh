#!/usr/bin/env bash
# new-work.sh — tạo hồ sơ công việc docs/work/<YYYY-MM-DD>-<slug>/working.md từ mẫu WORK.template.md.
# Tên thư mục là Work ID mà mô tả PR phải ghi (pr-policy.yml); khuôn khớp check-docs-consistency.sh mục 13.
# Spec: docs/specs/2026-10-09-new-work-script.md · Test: scripts/test-new-work.sh
#
# Dùng:   bash scripts/new-work.sh <slug> ["tên công việc"]
# Ngày:   UTC hôm nay; ghi đè bằng WORK_DATE=YYYY-MM-DD.
# Thoát:  0 đã tạo (in đường dẫn) · 1 Work ID đã tồn tại, không ghi đè · 2 sai cách dùng / thiếu hoặc lệch mẫu.
set -euo pipefail

die() { echo "new-work: $2" >&2; exit "$1"; }

slug="${1:-}"
title="${2:-$slug}"
[[ "$slug" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]] \
  || die 2 "slug '$slug' sai khuôn (chữ thường, số, gạch nối). Dùng: bash scripts/new-work.sh <slug> [\"tên công việc\"]"
[[ "$title" != *$'\n'* ]] || die 2 "tên công việc phải nằm trên một dòng."
day="${WORK_DATE:-$(date -u +%F)}"
[[ "$day" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] || die 2 "WORK_DATE '$day' sai khuôn YYYY-MM-DD."

root="$(git rev-parse --show-toplevel 2>/dev/null)" || die 2 "không ở trong repo git."
template="$root/docs/framework/templates/WORK.template.md"
[ -f "$template" ] || die 2 "thiếu mẫu docs/framework/templates/WORK.template.md."

id="$day-$slug"
rel="docs/work/$id"
[ ! -e "$root/$rel" ] || die 1 "Work ID '$id' đã tồn tại ($rel/) — chọn slug khác, không ghi đè (TRAPS 60)."

branch="$(git -C "$root" branch --show-current 2>/dev/null || true)"
sha="$(git -C "$root" rev-parse --short HEAD 2>/dev/null || echo unknown)"
mkdir -p "$root/$rel"
# Giá trị đi qua ENVIRON (không qua awk -v) để '\' trong tên không bị awk diễn giải.
NW_TITLE="$title" NW_ID="$id" NW_REF="\`${branch:-detached}\` @ \`$sha\` · $(date -u +%FT%TZ)" awk '
  index($0, "# Công việc:") == 1          { print "# Công việc: " ENVIRON["NW_TITLE"]; next }
  index($0, "- Work ID:") == 1            { print "- Work ID: " ENVIRON["NW_ID"]; next }
  index($0, "- Trạng thái:") == 1         { print "- Trạng thái: Planned"; next }
  index($0, "- Nhánh / base SHA") == 1    { print "- Nhánh / base SHA / thời điểm reconcile: " ENVIRON["NW_REF"]; next }
  { print }
' "$template" > "$root/$rel/working.md"
if ! grep -qxF -- "- Work ID: $id" "$root/$rel/working.md"; then
  rm -rf "${root:?}/$rel"
  die 2 "mẫu WORK.template.md không còn dòng '- Work ID:' — sửa mẫu hoặc script, không tạo hồ sơ thiếu ID."
fi
echo "Đã tạo $rel/working.md — ghi 'Work ID: $id' vào mô tả PR."
