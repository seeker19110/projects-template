#!/usr/bin/env bash
# _sweep-deps.sh — mảng 2 "Dependency" của scripts/maintenance-sweep.sh: dò lệnh outdated/audit theo hệ sinh thái
# (_deps_*), thư mục manifest (dep_manifest_dirs), chạy và chấm mức 🔴/🟡 (sweep_deps).
# Tách 2026-10-12 (W-404, chu kỳ hoàn thiện) vì maintenance-sweep.sh vượt trần 400 dòng của radar; di chuyển
# nguyên văn, không đổi hành vi (test-maintenance-sweep.sh giữ nguyên số ca).
# CHỈ dùng để `source` từ maintenance-sweep.sh (sau khi đã có has/line/info/yel/red/block/run_capture,
# _stack-detect.sh, $ROOT/$DO_DEPS/$DEPS_TIMEOUT); không set shell option ở đây (docs/CONVENTIONS.md §A).
# Mỗi hệ sinh thái một hàm: in lệnh cho loại quét $1 (outdated|audit), hoặc return 1 nếu hệ sinh
# thái này không có mặt / không có lệnh. Tách ra vì bản gộp từng ở CC 13 — trên trần 12 mà
# `scripts/check-shell-complexity.sh` cưỡng chế.
_deps_node() {
  [ -f package.json ] || return 1
  local pm; pm="$(node_pm)"
  case "$1" in
    outdated) echo "$pm outdated" ;;
    audit)    [ "$pm" = yarn ] && echo "yarn npm audit --severity high" || echo "$pm audit --audit-level=high" ;;
  esac
  return 0   # hệ sinh thái CÓ MẶT → thắng, kể cả khi không có lệnh (bản cũ cũng dừng tại đây)
}
_deps_python() {
  py_present || return 1
  case "$1" in
    outdated) has pip && echo "! pip list --outdated --format=freeze 2>/dev/null | grep -q ." ;;   # có dòng = có gói cũ → exit 1 (pip luôn exit 0); sigpipe-ok: chạy trong bash -c mới, không pipefail
    audit)    has pip-audit && echo "pip-audit" ;;
  esac
  return 0   # hệ sinh thái CÓ MẶT → thắng, kể cả khi không có lệnh (bản cũ cũng dừng tại đây)
}
_deps_go() {
  [ -f go.mod ] || return 1
  case "$1" in
    outdated) echo "test -z \"\$(go list -m -u all 2>/dev/null | grep '\\[')\"" ;;   # có '[vX]' = có gói cũ → exit 1 (bản cũ đảo chiều: grep khớp → exit 0 → báo 'sạch')
    audit)    has govulncheck && echo "govulncheck ./..." ;;
  esac
  return 0   # hệ sinh thái CÓ MẶT → thắng, kể cả khi không có lệnh (bản cũ cũng dừng tại đây)
}
_deps_rust() {
  [ -f Cargo.toml ] || return 1
  case "$1" in
    outdated) has cargo-outdated && echo "cargo outdated --exit-code 1" ;;
    audit)    has cargo-audit && echo "cargo audit" ;;
  esac
  return 0   # hệ sinh thái CÓ MẶT → thắng, kể cả khi không có lệnh (bản cũ cũng dừng tại đây)
}
dep_manifest_dirs() { # root + trực tiếp apps/* và packages/*; không đệ quy vào vendor/build output
  # DEBT: chỉ quét root và một cấp apps/*, packages/* | trần: manifest sâu hơn không được dò tự động | xem lại khi: dự án đích có workspace lồng sâu cần báo cáo dependency đầy đủ
  local base dir
  printf '%s\0' .
  for base in apps packages; do
    [ -d "$base" ] || continue
    for dir in "$base"/*; do
      [ -d "$dir" ] && printf '%s\0' "$dir"
    done
  done
}
detect_deps_cmd() { # $1=outdated|audit → in các dòng dir<TAB>lệnh
  local dir eco cmd target_root="$ROOT"
  while IFS= read -r -d '' dir; do
    for eco in _deps_node _deps_python _deps_go _deps_rust; do
      cmd="$(cd "$target_root/$dir" && ROOT="$target_root/$dir" "$eco" "$1")"
      [ -n "$cmd" ] && printf '%s\t%s\n' "$dir" "$cmd"
    done
  done < <(dep_manifest_dirs)
  return 0
}
sweep_deps() {
  sec "2. Dependency"
  if [ "$DO_DEPS" -eq 0 ]; then line "bỏ qua (--no-deps)"; info Dependency "bỏ qua theo --no-deps" "—"; return; fi
  local kind cmd specs dep_dir dep_cmd safe_dir dep_prefix dep_label out rc
  for kind in outdated audit; do
    cmd="$(declared_cmd "deps_$kind" 2>/dev/null || true)"   # declared_cmd: _stack-detect.sh; config hỏng → coi như không khai báo, như trước
    if [ -n "$cmd" ]; then
      specs=".$(printf '\t%s' "$cmd")"  # lệnh khai báo tiếp tục chạy ở root, như hợp đồng hiện tại
    else
      specs="$(detect_deps_cmd "$kind")"
    fi
    if [ -z "$specs" ]; then
      line "- $kind: n-a (không dò được lệnh cho stack này — khai \`deps_$kind\` ở \`.claude/project-commands.sh\`)"
      info Dependency "$kind: chưa có lệnh cho stack này" "khai deps_$kind trong .claude/project-commands.sh"
      continue
    fi
    while IFS=$'\t' read -r dep_dir dep_cmd; do
      [ -n "$dep_cmd" ] || continue
      printf -v safe_dir '%q' "$dep_dir"
      dep_prefix=""; dep_label="$kind"
      if [ "$dep_dir" != . ]; then dep_prefix="$safe_dir: "; dep_label="$kind ($safe_dir)"; fi
      out="$(cd "$ROOT/$dep_dir" && run_capture "$DEPS_TIMEOUT" "$dep_cmd")"; rc=$?
      line "- $dep_label: \`$dep_cmd\` → exit $rc"
      if [ "$rc" -eq 124 ]; then
        yel Dependency "$dep_label: hết giờ sau ${DEPS_TIMEOUT}s (mạng/proxy?)" "chạy tay trong $safe_dir: $dep_cmd"
      elif [ "$rc" -ne 0 ] && [ "$kind" = audit ]; then
        red Dependency "${dep_prefix}audit báo lỗ hổng (exit $rc)" "chạy tay trong $safe_dir: $dep_cmd — nâng gói bị ảnh hưởng"
      elif [ "$rc" -ne 0 ]; then
        yel Dependency "${dep_prefix}có gói lỗi thời (exit $rc)" "chạy tay trong $safe_dir: $dep_cmd — lên kế hoạch nâng theo lô"
      fi
      [ -n "$out" ] && block <<<"$(printf '%s\n' "$out" | tail -n 25)"
    done <<< "$specs"
  done
}
