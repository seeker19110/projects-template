#!/usr/bin/env bash
# test-new-work.sh — CHỨNG MINH scripts/new-work.sh tạo hồ sơ docs/work/<ngày>-<slug>/working.md đúng khuôn
# Work ID (cổng check-docs-consistency mục 13 + pr-policy), không ghi đè hồ sơ có sẵn, từ chối đầu vào sai.
# Spec: docs/specs/2026-10-09-new-work-script.md (AC-1..AC-5). Mỗi ca dùng repo git tạm; không chạm repo thật.
#
# Chạy: bash scripts/test-new-work.sh
set -uo pipefail   # cố ý KHÔNG -e: một ca lỗi không được làm chết cả lượt chạy (docs/CONVENTIONS.md §A)

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
if command -v cygpath >/dev/null 2>&1; then ROOT="$(cygpath -m "$ROOT")"; fi
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

source "$ROOT/scripts/_test-lib.sh"

bad() {
  echo "  ❌ $1"
  fails=$((fails+1))
  cat "$WORK/out" >&2
}

fixture() {   # repo git tạm có mẫu WORK thật, một commit, nhánh feat/x
  local d="$WORK/repo-$RANDOM-$RANDOM"
  mkdir -p "$d/docs/framework/templates"
  cp "$ROOT/docs/framework/templates/WORK.template.md" "$d/docs/framework/templates/"
  git -C "$d" init -q -b feat/x
  git -C "$d" -c user.email=t@t.local -c user.name=test add -A
  git -C "$d" -c user.email=t@t.local -c user.name=test commit -q -m init
  printf '%s\n' "$d"
}

run() {   # $1 = repo; phần còn lại = tham số new-work.sh; in mã thoát
  local d="$1"; shift
  (cd "$d" && WORK_DATE="${WORK_DATE:-2026-10-09}" bash "$ROOT/scripts/new-work.sh" "$@" >"$WORK/out" 2>&1)
  echo $?
}

echo "== AC-1: slug hợp lệ → tạo hồ sơ đúng khuôn =="
d="$(fixture)"
rc="$(run "$d" them-script "Thêm script tạo hồ sơ")"
f="$d/docs/work/2026-10-09-them-script/working.md"
sha="$(git -C "$d" rev-parse --short HEAD)"
if [ "$rc" = 0 ] && [ -f "$f" ] \
  && grep -qx '# Công việc: Thêm script tạo hồ sơ' "$f" \
  && grep -qx -- '- Work ID: 2026-10-09-them-script' "$f" \
  && grep -qx -- '- Trạng thái: Planned' "$f" \
  && grep -q -- "^- Nhánh / base SHA / thời điểm reconcile: \`feat/x\` @ \`$sha\`" "$f" \
  && grep -q '## Bàn giao / bước tiếp theo' "$f" \
  && grep -q 'docs/work/2026-10-09-them-script/working.md' "$WORK/out"; then
  ok "tạo docs/work/2026-10-09-them-script/working.md với tiêu đề, Work ID, Planned, nhánh @ SHA"
else
  bad "slug hợp lệ không tạo đúng hồ sơ (rc=$rc)"
fi
rc="$(run "$d" khong-ten)"
grep -qx '# Công việc: khong-ten' "$d/docs/work/2026-10-09-khong-ten/working.md" 2>/dev/null \
  && [ "$rc" = 0 ] && ok "thiếu tên → tiêu đề lấy slug" || bad "thiếu tên không lấy slug làm tiêu đề (rc=$rc)"

echo "== AC-2: Work ID đã tồn tại → thoát 1, không ghi đè =="
before="$(cksum < "$f")"
rc="$(run "$d" them-script "Tên khác")"
[ "$rc" = 1 ] && [ "$(cksum < "$f")" = "$before" ] && ok "Work ID trùng → rc=1, hồ sơ cũ giữ nguyên" \
  || bad "Work ID trùng: muốn rc=1 và không đổi file (rc=$rc)"
mkdir -p "$d/docs/work/2026-10-09-da-dong" && : > "$d/docs/work/2026-10-09-da-dong/done.md"
rc="$(run "$d" da-dong)"
[ "$rc" = 1 ] && [ ! -e "$d/docs/work/2026-10-09-da-dong/working.md" ] && ok "hồ sơ đã done → rc=1, không tạo working.md" \
  || bad "hồ sơ done bị tạo lại working.md (rc=$rc)"

echo "== AC-3: đầu vào sai → thoát 2, không tạo gì =="
d="$(fixture)"
for slug in "Ten_Sai" "../x" "a/b" "" "-dau-gach" "cuoi-gach-"; do
  rc="$(run "$d" "$slug")"
  [ "$rc" = 2 ] && [ ! -d "$d/docs/work" ] && ok "slug '$slug' → rc=2" || bad "slug '$slug': muốn rc=2, không tạo (rc=$rc)"
done
rc="$(WORK_DATE=2026-1-9 run "$d" ok-slug)"
[ "$rc" = 2 ] && [ ! -d "$d/docs/work" ] && ok "WORK_DATE sai khuôn → rc=2" || bad "WORK_DATE sai không bị chặn (rc=$rc)"
rc="$(run "$d" ok-slug $'dòng 1\ndòng 2')"
[ "$rc" = 2 ] && [ ! -d "$d/docs/work" ] && ok "tên nhiều dòng → rc=2" || bad "tên nhiều dòng không bị chặn (rc=$rc)"

echo "== AC-4: mẫu thiếu/lệch → thoát 2, không để lại thư mục =="
d="$(fixture)"
rm "$d/docs/framework/templates/WORK.template.md"
rc="$(run "$d" thieu-mau)"
[ "$rc" = 2 ] && [ ! -e "$d/docs/work/2026-10-09-thieu-mau" ] && ok "thiếu mẫu → rc=2" || bad "thiếu mẫu (rc=$rc)"
printf '# Công việc: <tên>\n\n- Trạng thái: x\n' > "$d/docs/framework/templates/WORK.template.md"
rc="$(run "$d" mau-lech)"
[ "$rc" = 2 ] && [ ! -e "$d/docs/work/2026-10-09-mau-lech" ] && ok "mẫu không còn dòng Work ID → rc=2, dọn thư mục" \
  || bad "mẫu lệch không bị chặn hoặc để lại rác (rc=$rc)"

echo "== AC-5: tên có ký tự đặc biệt giữ nguyên văn =="
d="$(fixture)"
rc="$(run "$d" ky-tu 'A & B \1 a/b $HOME')"
grep -qxF '# Công việc: A & B \1 a/b $HOME' "$d/docs/work/2026-10-09-ky-tu/working.md" 2>/dev/null && [ "$rc" = 0 ] \
  && ok "tên '&', '\\', '/', '\$' giữ nguyên văn" || bad "tên ký tự đặc biệt bị biến đổi (rc=$rc)"

finish "new-work.sh tạo hồ sơ đúng khuôn, không ghi đè, chặn đầu vào sai."
