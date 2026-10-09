#!/usr/bin/env bash
# _lib.sh — hàm dùng chung cho các hook PreToolUse soi lệnh Bash (block-dangerous-git.sh, pre-commit-gate.sh).
# CHỈ để `source "$(dirname "$0")/_lib.sh"`, không tự chạy, không nối vào settings*.json. Không `set` gì ở đây:
# hook gọi đã tự đặt shell option (cố ý KHÔNG -e — docs/CONVENTIONS.md §A).
#
# VÌ SAO TÁCH RA (O-2, 2026-10-08 — TRAPS.md "bản sao hook lệch nhau"): hai hook từng giữ HAI BẢN SAO bộ lọc
# "bỏ dữ liệu trước khi so khớp". Lần sửa heredoc 2026-09-14 chỉ vào block-dangerous-git, nên pre-commit-gate
# vẫn coi thân heredoc là lệnh: `python3 - <<PY … git commit … PY` chạy cổng oan, message heredoc nhắc
# `git add` bật chế độ tự-stage oan. Một bản duy nhất ở đây = sửa một chỗ, cả hai hook cùng nhận.
# Chốt chặn: `scripts/test-hooks-gate.sh` mục 8 (block-dangerous-git) + mục 16 (pre-commit-gate).

# In lệnh Bash sắp chạy (`.tool_input.command`) từ payload JSON trên stdin; rỗng nếu không có.
# Hook gọi PHẢI tự kiểm `command -v jq` trước (mỗi hook giữ thông báo fail-open-có-cảnh-báo riêng).
read_hook_command() {
  jq -r '.tool_input.command // empty' 2>/dev/null
}

# Bỏ DỮ LIỆU trước khi so khớp, chỉ giữ phần thực sự là lệnh. Hai dạng nhúng dữ liệu nhiều từ vào
# một lệnh shell, và cả hai đều đã gây chặn oan thật:
#
#   1. Trong dấu nháy (audit 2026-09-12): `echo 'git reset --hard ...'` bị coi là lệnh git thật.
#   2. Trong thân heredoc (2026-09-14): `git commit -F - <<EOF ... EOF && git push -u origin
#      claude/<nhánh> --force-with-lease` bị quy tắc 1 chặn vì COMMIT MESSAGE có chữ "main" đứng
#      riêng ("quay về main"), dù nhánh đích là nhánh riêng. Cùng lượt đó quy tắc 2 cũng chặn oan
#      một lệnh `python3 - <<PY` mà thân script có chuỗi `git reset --hard` làm dữ liệu test.
#
# Đây là khuôn "bộ đếm/bộ dò tự khớp văn bản của chính thứ nó đang soi"
# (`docs/framework/quality-supplements-group2.md` §"Sổ trần cho LỐI THOÁT khỏi cổng coverage").
# Nguy hiểm của chặn oan không phải là phiền: nó dạy người ta gõ ALLOW_DANGEROUS_GIT=1 thành phản
# xạ, và lúc đó hàng rào không còn chặn được ca thật.
#
# CẨN TRỌNG khi sửa hàm dưới: bỏ NHẦM một dòng LÀ LỆNH thì hàng rào để lọt — hỏng theo chiều nguy
# hiểm, không phải chiều phiền. Bản đầu của chính lần sửa này dùng `<<-?[[:space:]]*DELIM`, và
# `echo "a << b"` khớp thành heredoc với delimiter `b` → mọi dòng SAU đó bị nuốt, nên
# `git reset --hard` ở dòng kế KHÔNG bị chặn (đo được, không phải suy đoán). Vì thế: KHÔNG cho phép
# khoảng trắng giữa `<<` và delimiter. Ca đó nay là một ca chặn bắt buộc ở `test-hooks-gate.sh` mục 7.
#
# GIỚI HẠN CÒN LẠI (nói ra, không giấu):
#   - dữ liệu KHÔNG nháy và KHÔNG heredoc vẫn bị quét — `git push -f origin claude/x && echo main`
#     vẫn chặn oan. Sửa hẳn cần tách lệnh theo `&&`/`;`/`|` rồi chỉ soi segment bắt đầu bằng `git`;
#     chưa làm vì phạm vi rộng hơn hẳn và chưa có sự cố thật.
#   - `cat << EOF` (có khoảng trắng — POSIX cho phép) không được nhận là heredoc nữa, nên thân nó
#     vẫn bị quét → có thể chặn oan. Đây là đánh đổi CỐ Ý: chặn oan thì người dùng thấy ngay và nói,
#     còn để lọt thì không ai biết. Chọn chiều an toàn.
#   - vỏ bọc chạy chuỗi (`bash -c`, `eval`) chỉ nhận dạng khi chuỗi đứng ngay sau (có thể qua cờ `-c`/`-lc`);
#     `cmd=…; eval "$cmd"` hay script ghi ra file rồi chạy thì hook KHÔNG thấy lệnh thật — hook là lưới đỡ
#     cho lỗi vô ý, không phải hàng rào chống người cố né (ruleset trên GitHub mới là hàng rào cứng).
# \047 = nháy đơn, \042 = nháy kép (escape bát phân của awk). Dùng chúng thay vì viết nháy thật để
# CẢ chương trình awk nằm gọn trong một cặp nháy đơn của shell — không có chỗ nào phải thoát nháy
# lồng nhau, thứ vừa khó đọc vừa dễ hỏng lặng lẽ khi ai đó sửa.
#
# Audit 2026-10-09 (TRAPS.md mục 62) vá thêm hai chỗ bỏ NHẦM dòng lệnh:
#   - `<<-EOF`: bash bỏ TAB đầu dòng trước khi so terminator → so `$0` sau khi bỏ tab; bản cũ so nguyên dòng nên
#     terminator thụt tab không bao giờ khớp và MỌI dòng sau (kể cả `git reset --hard`) bị nuốt.
#   - `<<` nằm TRONG chuỗi nháy (`echo "x <<EOF"`) không phải heredoc: chỉ nhận `<<` khi phần trước nó, sau khi bỏ
#     các cặp nháy đã đóng, không còn ký tự nháy lẻ (tức `<<` không ở trong chuỗi chưa đóng).
strip_heredoc_bodies() {
  awk '
    BEGIN { delim = ""; dash = 0 }
    {
      if (delim != "") {
        line = $0
        if (dash) sub(/^\t+/, "", line)
        if (line == delim) delim = ""
        next
      }
      rest = $0; pre = ""
      while (match(rest, /<<-?[\047\042]?[A-Za-z_][A-Za-z0-9_]*[\047\042]?/)) {
        before = pre substr(rest, 1, RSTART - 1)
        d = substr(rest, RSTART, RLENGTH)
        q = before
        gsub(/\047[^\047]*\047|\042[^\042]*\042/, "", q)
        if (q !~ /[\047\042]/) {
          dash = (d ~ /^<<-/)
          sub(/^<<-?/, "", d)
          gsub(/[\047\042]/, "", d)
          delim = d
          break
        }
        pre = before d
        rest = substr(rest, RSTART + RLENGTH)
      }
      print
    }'
}

# Bỏ phần TRONG DẤU NHÁY (đơn và kép) — dạng 1 ở trên. MỘT lượt trái→phải (một regex xen kẽ), không phải hai lượt
# nối tiếp: bản cũ bỏ nháy đơn trước nên `"don't" && git push --force origin main && echo "it's"` mất cả lệnh giữa
# (cặp `'…'` ghép từ hai chuỗi nháy kép khác nhau) — TRAPS.md mục 62.
strip_quoted() {
  sed -E "s/'[^']*'|\"[^\"]*\"//g"
}

# Chỉ bỏ KÝ TỰ nháy, giữ nội dung: dùng khi phần trong nháy có thể LÀ lệnh/tên nhánh (`-f origin "main"`,
# `bash -c 'git reset --hard'`). Rộng hơn strip_quoted → chỉ dùng ở chỗ chặn oan rẻ hơn để lọt.
strip_quote_marks() {
  tr -d "'\""
}

# Vỏ bọc chạy CHUỖI như lệnh: `bash -c '…'`, `sh -c "…"`, `zsh -lc '…'`, `eval "…"`.
HOOK_WRAPPER_RE="(^|[[:space:]])(bash|sh|zsh|eval)[[:space:]]+(-[A-Za-z]+[[:space:]]+)*[\"']"

# Văn bản để so khớp: bỏ thân heredoc, rồi bỏ phần trong nháy — TRỪ KHI lệnh có vỏ bọc chạy chuỗi, lúc đó phần trong
# nháy chính là lệnh nên chỉ bỏ ký tự nháy (chặn oan `echo "bash -c '…'"` là đánh đổi cố ý, chiều an toàn).
hook_scan_text() {   # $1 = lệnh gốc
  local body
  body="$(printf '%s' "$1" | strip_heredoc_bodies)"
  if printf '%s' "$body" | grep -Eq "$HOOK_WRAPPER_RE"; then
    printf '%s' "$body" | strip_quote_marks
  else
    printf '%s' "$body" | strip_quoted
  fi
}
