#!/usr/bin/env bash
# Đối chiếu HAI CHIỀU giữa job id thật trong ci.yml/pr-policy.yml và danh sách "required checks —
# nguồn sự thật" trong docs/ops/repository-settings.md.
#
# VÌ SAO CẦN (docs/specs/2026-09-12-traps-codemap-ci-policy.md, lỗ hổng C): ci.yml có nhiều job
# PHẲNG, không `needs:` — không có job tổng hợp để gom, nên branch protection trên GitHub phải
# liệt kê ĐÚNG TÊN từng job. Trước script này, danh sách required checks KHÔNG tồn tại ở đâu trong
# repo — nên đổi tên/xoá một job id sẽ làm required check cũ không bao giờ báo cáo nữa (PR kẹt
# vĩnh viễn, không PR nào hiện đỏ để lần ra nguyên nhân), hoặc thêm job cổng mới mà quên khai báo
# (cổng chạy nhưng đỏ vẫn merge được). Cả hai hỏng theo kiểu IM LẶNG.
#
# CỐ Ý chỉ kiểm CẤU TRÚC (job id có khớp danh sách không), KHÔNG kiểm nội dung từng bước bên trong
# job — ép nội dung sẽ biến script thành vật cản mỗi lần thêm một bước kiểm mới (cùng nguyên tắc
# donghanh/scripts/ci-workflow-policy.test.ts).
#
# Đây là biến thể SHELL cho chính repo khung (không có package.json → không chạy được vitest).
# Dự án đích dùng bản vitest tương đương trong dropins: scripts/ci-workflow-policy.test.ts.
# Hai bản KHÔNG được gộp — xem CODEMAP.md khi có.
#
# BẢNG KIỂM (mỗi kiểm một ID — khai ở ĐÂY là nguồn sự thật; xem mục 8 và W-302):
#   CP-1  job id trong workflow ↔ bản kê required checks (hai chiều)
#   CP-2  mọi `uses:` ghim full commit SHA
#   CP-3  `node-version:` khớp .nvmrc
#   CP-4  mọi job ci.yml có trong `needs:` của job tổng hợp `gate`
#   CP-5  sổ SKIP_ALLOWED của `gate` khớp BẰNG ĐÚNG tập job có `if:` (job nào skip được phải có lý do)
#   CP-6  mọi scripts/test-*.sh được gọi trong ci.yml (test không cổng nào chạy = không tồn tại)
# Thêm một kiểm mới ở đây → PHẢI khai ID đó trong scripts/ci-workflow-policy.test.ts (bản dropins),
# dù chỉ để ghi "không áp dụng cho dự án đích: <lý do>". Mục 8 dưới đây cưỡng chế điều đó.
#
# Chạy: bash scripts/check-ci-policy.sh
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

SETTINGS_FILE="docs/ops/repository-settings.md"
WORKFLOWS=("ci.yml" "pr-policy.yml")

fail=0

# --- 1. Trích job id THẬT từ mỗi workflow (top-level key ngay dưới `jobs:`, thụt lề 2 khoảng). ---
declare -A actual_jobs=() # key "wf:job" -> 1

for wf in "${WORKFLOWS[@]}"; do
  f=".github/workflows/$wf"
  if [ ! -f "$f" ]; then
    echo "::error::Không tìm thấy workflow $f (khai trong WORKFLOWS của script này)"
    fail=1
    continue
  fi
  in_jobs=0
  while IFS= read -r line; do
    line="${line%$'\r'}"
    if [[ "$line" == "jobs:" ]]; then
      in_jobs=1
      continue
    fi
    if [ "$in_jobs" -eq 1 ]; then
      # Job id: đúng 2 khoảng trắng thụt lề rồi "<id>:" (không phải khoá con của một job).
      if [[ "$line" =~ ^\ \ ([A-Za-z0-9_-]+):[[:space:]]*$ ]] || [[ "$line" =~ ^\ \ ([A-Za-z0-9_-]+):[[:space:]]+[^\ ] ]]; then
        actual_jobs["$wf:${BASH_REMATCH[1]}"]=1
      elif [[ "$line" =~ ^[A-Za-z] ]]; then
        # Về lại cột 0 (khoá cấp cao khác của workflow) → hết khối jobs.
        in_jobs=0
      fi
    fi
  done < <(tr -d '\r' < "$f")
done

# --- 2. Trích danh sách khai báo từ khối fenced code block "```" đầu tiên trong repository-settings.md. ---
if [ ! -f "$SETTINGS_FILE" ]; then
  echo "::error::Không tìm thấy $SETTINGS_FILE"
  exit 1
fi

declare -A declared_jobs=() # key "wf:job" -> 1
in_block=0
while IFS= read -r line; do
  line="${line%$'\r'}"
  if [[ "$line" == '```' ]]; then
    if [ "$in_block" -eq 0 ]; then in_block=1; continue; else break; fi
  fi
  if [ "$in_block" -eq 1 ]; then
    if [[ "$line" =~ ^([a-zA-Z0-9_.-]+\.yml):[[:space:]]*([A-Za-z0-9_-]+)[[:space:]]*$ ]]; then
      declared_jobs["${BASH_REMATCH[1]}:${BASH_REMATCH[2]}"]=1
    fi
  fi
done < <(tr -d '\r' < "$SETTINGS_FILE")

if [ "${#declared_jobs[@]}" -eq 0 ]; then
  echo "::error::Không đọc được mục nào trong khối 'Required checks — nguồn sự thật' của $SETTINGS_FILE"
  exit 1
fi

# --- 3. Đối chiếu hai chiều. ---
echo "== Job thật trong workflow nhưng THIẾU trong $SETTINGS_FILE =="
for key in "${!actual_jobs[@]}"; do
  if [ -z "${declared_jobs[$key]+x}" ]; then
    echo "::error::Job '$key' có trong workflow nhưng chưa khai trong $SETTINGS_FILE — thêm dòng '${key/:/: }' vào khối required checks, hoặc xác nhận job này cố ý không phải required check."
    fail=1
  fi
done

echo "== Job khai trong $SETTINGS_FILE nhưng KHÔNG còn tồn tại trong workflow =="
for key in "${!declared_jobs[@]}"; do
  if [ -z "${actual_jobs[$key]+x}" ]; then
    echo "::error::Job '$key' được khai trong $SETTINGS_FILE nhưng không còn tồn tại trong workflow — job đã đổi tên/xoá mà quên cập nhật danh sách (branch protection đang canh một tên đã chết)."
    fail=1
  fi
done

# --- 4. MỌI `uses:` phải ghim full commit SHA (docs/ops/supply-chain.md dòng 10). ---
# VÌ SAO (audit 2026-09-12, F-003): `actions/cache@v4` là action DUY NHẤT còn dùng tag di động
# giữa 13 action — lệch quy ước, và tag di động nghĩa là mã chạy trong CI có thể đổi dưới chân ta
# mà không có PR nào. Trước kiểm này không gì bắt được chuyện đó; dependabot chỉ nâng cái đã ghim.
echo "== Action chưa ghim full commit SHA =="
while IFS= read -r line; do
  line="${line%$'\r'}"
  file="${line%%:*}"; rest="${line#*:}"; lineno="${rest%%:*}"
  ref="$(printf '%s' "$line" | sed -E 's/.*uses:[[:space:]]*//; s/[[:space:]]*#.*$//; s/[[:space:]]*$//')"
  # Bỏ qua action local (./.github/...) và docker://
  case "$ref" in ./*|docker://*) continue ;; esac
  if ! printf '%s' "$ref" | grep -Eq '@[0-9a-f]{40}$'; then
    echo "::error file=$file,line=$lineno::Action '$ref' chưa ghim full commit SHA — vi phạm docs/ops/supply-chain.md. Sửa: uses: <action>@<sha40> # <tag>"
    fail=1
  fi
done < <(grep -rn "uses:" .github/workflows/*.yml | grep -v "#.*uses:")

# --- 5. `node-version:` trong workflow phải khớp .nvmrc (ADR-0002). ---
# VÌ SAO (audit 2026-09-12, F-011): phiên bản Node bị hardcode ở 5 chỗ trong workflow + .nvmrc;
# nâng một chỗ quên chỗ kia thì CI test bằng Node khác với Node dev — lệch IM LẶNG.
echo "== node-version trong workflow khớp .nvmrc =="
if [ -f .nvmrc ]; then
  nvmrc="$(tr -d ' \n\r' < .nvmrc)"
  while IFS= read -r line; do
    line="${line%$'\r'}"
    file="${line%%:*}"; rest="${line#*:}"; lineno="${rest%%:*}"
    val="$(printf '%s' "$line" | sed -E 's/.*node-version:[[:space:]]*//; s/[[:space:]]*$//' | tr -d "'\"")"
    case "$val" in \$\{\{*) continue ;; esac   # biểu thức matrix → bỏ qua
    if [ "$val" != "$nvmrc" ]; then
      echo "::error file=$file,line=$lineno::node-version '$val' lệch .nvmrc ('$nvmrc') — đồng bộ cả hai (ADR-0002)."
      fail=1
    fi
  done < <(grep -rn "node-version:" .github/workflows/*.yml)
else
  echo "::error::.nvmrc không tồn tại — ADR-0002 yêu cầu ghim phiên bản Node của khung."
  fail=1
fi

# --- 6. Mọi job cổng của ci.yml phải có mặt trong `needs:` của job tổng hợp `gate` (ADR-0003). ---
# VÌ SAO: `gate` chỉ mạnh bằng danh sách needs: của nó. Thêm job cổng mới mà quên đưa vào needs
# thì job đó chạy nhưng đỏ KHÔNG chặn merge (branch protection chỉ khoá `gate`) — cổng hình thức.
is_in() { local needle="$1"; shift; for x in "$@"; do [ "$x" = "$needle" ] && return 0; done; return 1; }
echo "== Job của ci.yml có trong needs: của gate =="
if grep -q "^  gate:" .github/workflows/ci.yml; then
  needs_line="$(grep -A3 "^  gate:" .github/workflows/ci.yml | grep -m1 "needs:")"
  # Tach thanh DANH SACH job roi so BANG DUNG tung ten. Ban cu grep ca dong voi ...:
  # "-" khong phai ky tu tu, nen `framework-lint` KHOP ben trong `framework-lint-windows`
  # => mot job bi go khoi needs: van duoc coi la co, chi vi job KHAC co ten bat dau giong.
  # Da do that o negative test CP-4 khi them job cong Windows (PR them framework-lint-windows).
  needs_ids="$(printf '%s' "$needs_line" | sed -E 's/.*needs:[[:space:]]*\[([^]]*)\].*/\1/' | tr ',' ' ')"
  for job in "${!actual_jobs[@]}"; do
    case "$job" in ci.yml:*) ;; *) continue ;; esac
    jid="${job#ci.yml:}"
    [ "$jid" = "gate" ] && continue
    # shellcheck disable=SC2086  # can tach tu: $needs_ids la danh sach ten job
    if ! is_in "$jid" $needs_ids; then
      echo "::error file=.github/workflows/ci.yml::Job '$jid' KHÔNG có trong needs: của job 'gate' — đỏ sẽ không chặn merge (ADR-0003)."
      fail=1
    fi
  done
else
  echo "::error file=.github/workflows/ci.yml::Thiếu job tổng hợp 'gate' — ADR-0003 yêu cầu có (required check duy nhất)."
  fail=1
fi


# --- 6b. CP-5: sổ job ĐƯỢC PHÉP skip phải khớp bằng đúng tập job có `if:`. ---
# VÌ SAO: `gate` tính `skipped` là đạt (cần thế, vì `progress-freshness` cố ý chỉ chạy trên push vào
# nhánh chính). Hệ quả không ai canh: một job bị `if:` viết hỏng loại ra sẽ KHÔNG chạy và vẫn qua
# cổng — cổng xanh giả, cùng họ với CP-4 nhưng vào bằng cửa khác. Sổ `SKIP_ALLOWED` trong bước
# "Kết luận từ mọi job cổng" là danh sách tường minh; kiểm này giữ nó khớp CHÍNH XÁC hai chiều:
# thêm `if:` cho một job mà quên kê ⇒ đỏ (job mới skip được mà không ai biết); kê thừa một job không
# còn `if:` ⇒ cũng đỏ (sổ nói dối, và sẽ che đúng job đó nếu sau này nó skip vì lý do khác).
# Chỉ soi ci.yml: `gate` chỉ hội tụ job của ci.yml.
echo "== CP-5: sổ SKIP_ALLOWED khớp tập job có 'if:' =="
skippable=""
cur_job=""
in_jobs=0
while IFS= read -r line; do
  if [[ "$line" == "jobs:" ]]; then in_jobs=1; continue; fi
  [ "$in_jobs" -eq 1 ] || continue
  if [[ "$line" =~ ^\ \ ([A-Za-z0-9_-]+): ]]; then
    cur_job="${BASH_REMATCH[1]}"
  elif [[ "$line" =~ ^[A-Za-z] ]]; then
    in_jobs=0
  elif [[ "$line" =~ ^\ \ \ \ if: ]] && [ -n "$cur_job" ] && [ "$cur_job" != "gate" ]; then
    # `gate` tự nó có `if: always()` — đó là thứ khiến nó CHẠY dù job con đỏ, không phải thứ khiến
    # nó bị bỏ qua. Loại ra, nếu không sổ sẽ phải kê chính người đang cầm sổ.
    skippable+="$cur_job "
  fi
done < <(tr -d '\r' < .github/workflows/ci.yml)

declared="$(grep -m1 'SKIP_ALLOWED:' .github/workflows/ci.yml | sed -E 's/.*SKIP_ALLOWED:[[:space:]]*"?([^"]*)"?.*/\1/')"
norm() { printf '%s\n' $1 | LC_ALL=C sort | tr '\n' ' '; }
if ! grep -q 'SKIP_ALLOWED:' .github/workflows/ci.yml; then
  echo "::error file=.github/workflows/ci.yml::Thiếu sổ SKIP_ALLOWED trong job 'gate' — không có sổ thì mọi 'skipped' lại được tính là đạt (CP-5)."
  fail=1
elif [ "$(norm "$skippable")" != "$(norm "$declared")" ]; then
  echo "::error file=.github/workflows/ci.yml::SKIP_ALLOWED lệch tập job có 'if:'. Job có 'if:': [$(norm "$skippable")] — sổ ghi: [$(norm "$declared")]. Thêm 'if:' cho một job thì kê tên + LÝ DO vào sổ; bỏ 'if:' thì xoá khỏi sổ. Sổ chỉ có giá trị khi khớp đúng hai chiều (CP-5)."
  fail=1
else
  echo "OK: sổ SKIP_ALLOWED khớp tập job có 'if:' ($(norm "$declared"))"
fi


# --- 6c. CP-6: mọi scripts/test-*.sh phải được một job trong ci.yml gọi. ---
# VÌ SAO CẦN: `test-next-gen-engines.sh` và `test-telemetry-and-dispatch.sh` được thêm cùng 2
# engine mới (PR #89, #91) nhưng KHÔNG job nào gọi — 3 ca đỏ nằm im qua nhiều PR sạch (đã nối tay ở PR trước; đây là cổng chống tái phát).
# Test không cổng nào chạy thì về thực chất là không tồn tại — cùng khuôn hỏng IM LẶNG với F-002.
# Tách thành hàm để không đẩy CC của thân script sát trần 45 (đo được: 43 nếu để inline).
check_cp6_orphan_tests() {
  local ci_file=".github/workflows/ci.yml" t
  for t in scripts/test-*.sh; do
    [ -e "$t" ] || continue
    grep -q "$(basename "$t")" "$ci_file" && continue
    echo "::error file=$t::$t không được job nào trong $ci_file gọi — test không chạy thì không chứng minh được gì (CP-6)."
    fail=1
  done
}
echo "== CP-6: mọi scripts/test-*.sh được ci.yml gọi =="
check_cp6_orphan_tests


# --- 7. Hai bản kiểm CI song song không được phân kỳ âm thầm (W-302, F-008). ---
# VÌ SAO: repo khung dùng bản SHELL (không có package.json → không chạy vitest), dự án đích dùng
# bản VITEST `scripts/ci-workflow-policy.test.ts`. CỐ Ý không gộp — nhưng trước kiểm này không gì
# ràng hai bên: thêm một kiểm vào bản shell mà quên bản dropins thì dự án đích thiếu cổng đó mà
# không ai biết. Hai bản KHÔNG cần giống nhau (phạm vi khác thật), nhưng mỗi ID phải được bên kia
# KHAI TƯỜNG MINH — implement, hoặc ghi "không áp dụng cho dự án đích: <lý do>".
echo "== Bảng kiểm CP-* được khai ở cả hai bản (shell ↔ vitest) =="
DROPIN_TEST="scripts/ci-workflow-policy.test.ts"
if [ -f "$DROPIN_TEST" ]; then
  while IFS= read -r cp; do
    [ -n "$cp" ] || continue
    if ! grep -q "$cp" "$DROPIN_TEST"; then
      echo "::error file=$DROPIN_TEST::Kiểm '$cp' có trong scripts/check-ci-policy.sh nhưng KHÔNG được khai ở bản dropins — implement nó, hoặc ghi rõ '$cp: không áp dụng cho dự án đích: <lý do>' (W-302)."
      fail=1
    fi
  done < <(grep -oE '^#   CP-[0-9]+' "$0" | sed 's/^#   //')
else
  echo "::error::Thiếu $DROPIN_TEST — dự án đích sẽ không có cổng kiểm CI nào."
  fail=1
fi


if [ "$fail" -eq 0 ]; then
  echo "OK — CP-1..CP-6 đạt; bảng kiểm khớp hai bản (shell ↔ vitest dropins)."
fi

exit "$fail"
