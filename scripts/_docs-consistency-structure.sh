#!/usr/bin/env bash
# _docs-consistency-structure.sh — mục 12–16 của scripts/check-docs-consistency.sh (`source`, KHÔNG chạy trực tiếp):
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
  [ -f "$dir/done.md" ] && { check_done_record "$dir/done.md" || rc=1; }
  return "$rc"
}
# Mục 13b (2026-10-12, đối chiếu stored K1): done.md là tín hiệu DỪNG của auto-complete-guard.sh → tên file thôi chưa đủ,
# nội dung phải là nghiệm thu thật. Sự cố thật: b7bd718 đưa lên nhánh done.md còn "Trạng thái: Active" + placeholder mẫu
# (git mv SAU khi sửa nội dung → index giữ blob cũ, TRAPS 70). PR/SHA tìm trong "Nghiệm thu cuối"; hồ sơ cũ không có mục đó
# thì tìm trong cả file.
check_done_record() {  # $1 = docs/work/<id>/done.md; in lỗi, trả 1 khi sai
  local f="$1" rc=0 sec
  grep -Eq '^- Trạng thái:[[:space:]]*Done' "$f" || { echo "::error file=$f::done.md không ghi '- Trạng thái: Done …' — tên file nói xong mà nội dung chưa (mục 13b)."; rc=1; }
  grep -q '<DoD, mọi PR MERGED' "$f" && { echo "::error file=$f::done.md còn placeholder mẫu WORK.template ở 'Nghiệm thu cuối' — điền DoD, PR + merge SHA, giới hạn (mục 13b)."; rc=1; }
  sec="$(awk '/^## Nghiệm thu cuối/{f=1;next} f&&/^## /{exit} f' "$f")"
  [ -n "$sec" ] || sec="$(cat "$f")"
  # here-string, KHÔNG nối pipe từ printf: dưới pipefail grep -q thoát ngay khi khớp → printf ăn SIGPIPE (141) → khớp
  # thành "không khớp" (TRAPS 71; đo 2026-10-12: 3/8640 lượt đỏ oan khi máy tải cao, here-string 0/8640).
  grep -Eq '#[0-9]+|\b[0-9a-f]{7,40}\b' <<<"$sec" || { echo "::error file=$f::done.md không có PR/SHA làm bằng chứng nghiệm thu (vd '#123 → abc1234') (mục 13b)."; rc=1; }
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

# VÌ SAO (2026-10-12, đối chiếu vòng lặp coding — N3): failure mode #1 của vòng lặp dài là "tuyên bố xong sớm"; goal file có cột
# State/Evidence nhưng trước đây không script nào đọc (đính chính B báo cáo ralph). Slice DONE phải có ô bằng chứng; file đã
# COMPLETE không được còn slice mở; `State | DONE` ở bảng thuộc tính cũng là tuyên bố xong (2026-10-12, kiểm kê vòng lặp v2).
# Cột bằng chứng = `Evidence`/`Nghiệm thu`/`Bằng chứng`, không có thì lấy cột cuối.
echo "== 15. docs/goals: slice DONE có bằng chứng; goal COMPLETE không còn slice mở =="
check_goal_file() {   # $1 = docs/goals/<id>.md; in lỗi, trả 1 khi sai
  local f="$1" complete=0
  grep -Eq '^\|[[:space:]]*State[[:space:]]*\|[[:space:]]*(COMPLETE|DONE)|^State:[[:space:]]*(COMPLETE|DONE)' "$f" && complete=1
  awk -v file="$f" -v complete="$complete" '
    function trim(s) { gsub(/^[[:space:]]+|[[:space:]]+$/, "", s); return s }
    /^\|/ {
      n = split($0, c, "|"); for (i = 1; i <= n; i++) c[i] = trim(c[i])
      if (!intable) {                       # dòng tiêu đề: cần ô "State" và ≥ 3 cột
        si = 0; ei = 0
        for (i = 2; i < n; i++) { if (c[i] == "State") si = i; if (c[i] ~ /^(Evidence|Nghiệm thu|Bằng chứng)$/) ei = i }
        if (si && n - 2 >= 3) { intable = 1; if (!ei) ei = n - 1 }
        next
      }
      if ($0 ~ /^\|[[:space:]]*-+/) next     # dòng gạch
      st = c[si]; ev = c[ei]
      if (st ~ /^DONE/ && ev == "") { printf "::error file=%s::Slice `%s` ghi DONE nhưng ô bằng chứng rỗng — DONE phải kèm PR/merge SHA/test (mục 15).\n", file, c[2]; bad = 1 }
      if (complete == 1 && st ~ /^(BACKLOG|RESEARCH|SPEC|READY|BUILD|VERIFY|WAITING|BLOCKED|ACTIVE)/) { printf "::error file=%s::Goal ghi State COMPLETE nhưng slice `%s` còn %s — đóng slice (DONE có bằng chứng/DROPPED) hoặc bỏ COMPLETE (mục 15).\n", file, c[2], st; bad = 1 }
      next
    }
    { intable = 0 }
    END { exit bad ? 1 : 0 }' "$f"
}
for f in docs/goals/*.md; do
  [ -f "$f" ] && [ "$(basename "$f")" != "README.md" ] || continue
  check_goal_file "$f" || fail=1
done

# VÌ SAO (2026-10-12, đối chiếu stored K2): /auto-complete tự chọn kiến trúc; ADR không ghi phương án đã loại thì không ai
# kiểm được là đã cân nhắc hay hội tụ sớm vào ý đầu tiên. Mỗi ADR (trừ template) phải có mục "Các phương án…" hoặc
# "Phương án đã loại" với ≥ 2 phương án (dòng bullet/đánh số, đoạn "**A. …**", hoặc hàng dữ liệu của bảng). Không chấm nội dung.
echo "== 16. docs/adr: mỗi ADR ghi ≥ 2 phương án đã cân nhắc/loại =="
check_adr_alternatives() {  # $1 = docs/adr/NNNN-*.md; in lỗi, trả 1 khi sai
  local f="$1" n
  n="$(awk '
    /^## (Các phương án|Phương án)/ { f = 1; seen = 1; tbl = 0; next }
    f && /^## / { exit }
    f && /^[[:space:]]*([-*]|[0-9]+\.)[[:space:]]/ { c++ }
    f && /^\*\*[A-Z0-9]+[.)]/ { c++ }        # đoạn in đậm "**A. …**" (ADR-0005)
    f && /^\|/ { if (/^\|[[:space:]]*:?-+/) next; tbl++; if (tbl > 1) c++ }
    f && !/^\|/ { tbl = 0 }
    END { print (seen ? c + 0 : -1) }' "$f")"
  if [ "$n" = "-1" ]; then
    echo "::error file=$f::ADR không có mục '## Các phương án đã cân nhắc' / '## Phương án đã loại' (mục 16)."; return 1
  elif [ "$n" -lt 2 ]; then
    echo "::error file=$f::ADR chỉ ghi $n phương án — cần ≥ 2 (phương án chọn so với ít nhất một phương án loại, kèm vì sao) (mục 16)."; return 1
  fi
}
for f in docs/adr/[0-9]*.md; do
  [ -f "$f" ] && [ "$(basename "$f")" != "0000-template.md" ] || continue
  check_adr_alternatives "$f" || fail=1
done
