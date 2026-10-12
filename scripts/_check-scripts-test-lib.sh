#!/usr/bin/env bash
# _check-scripts-test-lib.sh — fixture dùng chung cho test-check-scripts.sh, test-check-ci-policy.sh và test-check-progress-freshness.sh.
# Tách 2026-10-11 khi suite gốc vượt 400 dòng (radar). CHỈ dùng để `source`; cần ROOT, WORK của script gọi
# và ok/fails của scripts/_test-lib.sh. Không set shell option ở đây (docs/CONVENTIONS.md §A).

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
  # stdout của hàm CHỈ là đường dẫn: git commit in "nothing to commit" ra stdout ngay cả với -q (vd tar chết vì
  # fork fail → thư mục rỗng) → chuỗi đó thành tên thư mục rác ở nơi gọi. Đẩy sang stderr để vẫn thấy lỗi.
  git -C "$dir" -c user.email=t@t.local -c user.name=test commit -q -m init >&2
  local head_sha; head_sha="$(git -C "$dir" rev-parse HEAD)"
  sed -i.bak "s/^- Default-branch SHA đã đối chiếu:.*/- Default-branch SHA đã đối chiếu: \`$head_sha\`/" "$dir/PROGRESS.md"
  # Các trường fixture được dựng rõ ràng, không phụ thuộc văn xuôi tùy chọn của repo thật.
  sed -i.bak2 '/^- Nhánh đang làm:/d; /^- Giai đoạn:/d' "$dir/PROGRESS.md"
  printf '\n- Nhánh đang làm: `main`\n- Giai đoạn: GĐ 8.\n' >> "$dir/PROGRESS.md"
  rm -f "$dir/PROGRESS.md.bak" "$dir/PROGRESS.md.bak2"
  git -C "$dir" -c user.email=t@t.local -c user.name=test commit -q -am "chuẩn hoá PROGRESS.md cho baseline test" >&2
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
