#!/usr/bin/env bash
# _docs-consistency-structure.sh — mục 12–14 của scripts/check-docs-consistency.sh (`source`, KHÔNG chạy trực tiếp):
# mẫu mồ côi, khuôn hồ sơ docs/work/<id>/, bảng Hook ↔ settings.json. Tách 2026-10-10 vì file gốc vượt 400 dòng
# (radar). Chạy ở gốc repo, dùng `fail` của script gọi; negative test ở scripts/test-check-scripts.sh.
# shellcheck disable=SC2034  # fail: đọc bởi check-docs-consistency.sh sau khi source

# VÌ SAO (2026-10-09): ba mẫu DATA-GOVERNANCE/GOVERNANCE/SUPPORT tồn tại mà không tài liệu hướng dẫn
# nào trỏ tới (chỉ có comment trong manifest) → dự án đích không biết có mẫu để dùng. Mỗi file trong
# templates/ phải được ≥ 1 tài liệu NGOÀI templates/, work/, reports/, changelog/ nhắc tên.
echo "== 12. Mẫu (docs/framework/templates/) ↔ tài liệu hướng dẫn trỏ tới =="
TEMPLATES_DIR="docs/framework/templates"
if [ ! -d "$TEMPLATES_DIR" ]; then
  echo "::notice::Không có $TEMPLATES_DIR — bỏ qua mục 12."
else
  for f in "$TEMPLATES_DIR"/*; do
    [ -f "$f" ] || continue
    base="$(basename "$f")"
    hits=$(git grep --untracked -l -F -- "$base" -- '*.md' '*.sh' '*.ps1' \
      ':!docs/framework/templates/*' ':!docs/work/*' ':!docs/reports/*' ':!docs/changelog/*' ':!CHANGELOG.md' 2>/dev/null || true)
    if [ -z "$hits" ]; then
      echo "::error file=$f::Mẫu '$base' MỒ CÔI — không tài liệu hướng dẫn nào nhắc tên. Trỏ tới nó từ tài liệu được copy sang đích (docs/framework/*.md hoặc .claude/commands/*.md), hoặc xoá mẫu nếu không còn dùng."
      fail=1
    fi
  done
fi

# VÌ SAO (2026-10-09): tên thư mục docs/work/<id>/ CHÍNH LÀ Work ID mà mô tả PR phải ghi (pr-policy.yml),
# và tên file CHÍNH LÀ trạng thái (working.md = chưa xong, done.md = đã merge + DoD; standard-delivery §3e).
# Thư mục sai khuôn, có cả hai hoặc không có file nào thì `ls docs/work/*/working.md` báo sai việc còn dở.
echo "== 13. Hồ sơ công việc (docs/work/<id>/) — khuôn Work ID + đúng một trạng thái =="
check_work_record() {  # $1 = thư mục docs/work/<id>/; in lỗi và trả 1 khi sai
  local dir="$1" id n=0 rc=0
  id="$(basename "$dir")"
  if ! [[ "$id" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}-[a-z0-9]+(-[a-z0-9]+)*$ ]]; then
    echo "::error file=$dir::Work ID '$id' sai khuôn YYYY-MM-DD-slug (chữ thường, số, gạch nối)."
    rc=1
  fi
  [ -f "$dir/working.md" ] && n=$((n+1))
  [ -f "$dir/done.md" ] && n=$((n+1))
  if [ "$n" -ne 1 ]; then
    echo "::error file=$dir::Hồ sơ '$id' phải có đúng MỘT trong working.md/done.md (đang có $n)."
    rc=1
  fi
  return "$rc"
}
for dir in docs/work/*/; do
  [ -d "$dir" ] || continue
  check_work_record "$dir" || fail=1
done

echo "== 14. Hook nối trong .claude/settings.json ↔ bảng Hook của models-and-automation.md =="
# VÌ SAO (audit 2026-10-09, F-D-01..03): bảng Hook từng kê 4/9 hook — tài liệu phát sang đích mô tả một bộ hàng rào
# nhỏ hơn bộ thật. Hai chiều: hook nối trong settings phải có hàng trong bảng; hàng trong bảng phải là hook có nối.
hooks_in_settings() {   # tên file hook (basename) nối trong settings.json, mỗi dòng một tên
  grep -oE '\$\{CLAUDE_PROJECT_DIR\}/\.claude/hooks/[A-Za-z0-9_.-]+\.sh' .claude/settings.json 2>/dev/null | sed 's|.*/||' | sort -u
}
hooks_in_table() {      # tên hook trong bảng "**Hook — `.claude/hooks/`**" của models-and-automation.md
  awk '/^\*\*Hook — `\.claude\/hooks\/`\*\*/{f=1; next} f && /^\*\*/{exit} f' docs/framework/models-and-automation.md     | grep -oE '^\| `[A-Za-z0-9_.-]+\.sh`' | tr -d '|` ' | sort -u
}
check_hook_table() {    # in lỗi, trả 1 khi lệch
  local rc=0 h
  for h in $(comm -23 <(hooks_in_settings) <(hooks_in_table)); do
    echo "::error file=docs/framework/models-and-automation.md::Hook '$h' nối trong .claude/settings.json nhưng KHÔNG có hàng trong bảng Hook §6 — thêm hàng (sự kiện + làm gì)."
    rc=1
  done
  for h in $(comm -13 <(hooks_in_settings) <(hooks_in_table)); do
    echo "::error file=docs/framework/models-and-automation.md::Bảng Hook §6 kê '$h' nhưng .claude/settings.json KHÔNG nối hook đó — xoá hàng hoặc nối hook."
    rc=1
  done
  return "$rc"
}
if [ -f .claude/settings.json ] && [ -f docs/framework/models-and-automation.md ]; then
  check_hook_table || fail=1
fi
