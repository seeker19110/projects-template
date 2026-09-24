#!/usr/bin/env bash
# _stack-detect.sh — hàm dò stack DÙNG CHUNG cho scripts/dev-task.sh và scripts/maintenance-sweep.sh.
# Trước 2026-09-23 `node_pm()` viết hai lần ở hai file và đã lệch nhau (Bun ≥ 1.2 dùng `bun.lock` dạng
# text, cả hai bản chỉ nhận `bun.lockb` → dự án Bun mới bị coi là npm). Một nguồn, hai nơi source.
# CHỈ dùng để `source` (sau khi đã có $ROOT); không set shell option ở đây (docs/CONVENTIONS.md §A).

# Trình quản lý gói Node theo lockfile (npm là mặc định).
node_pm() {
  if   [ -f "$ROOT/pnpm-lock.yaml" ]; then echo "pnpm"
  elif [ -f "$ROOT/yarn.lock" ];      then echo "yarn"
  elif [ -f "$ROOT/bun.lockb" ] || [ -f "$ROOT/bun.lock" ]; then echo "bun"
  else echo "npm"; fi
}

# Dự án Python có mặt? (pyproject / requirements / setup.py — cùng một tập ở cả dev-task lẫn sweep)
py_present() {
  [ -f "$ROOT/pyproject.toml" ] || [ -f "$ROOT/requirements.txt" ] || [ -f "$ROOT/setup.py" ]
}

# In tiền tố để chạy công cụ Python ĐÚNG môi trường của dự án: ưu tiên venv/uv/poetry, cuối cùng PATH.
# Trả về rỗng + return 1 nếu không tìm thấy công cụ ở đâu cả (để caller no-op thay vì chạy sai binary).
#   $1 = tên công cụ (ruff/mypy/pytest…)  → in "path/tool" hoặc "uv run tool" hoặc "poetry run tool" hoặc "tool"
py_tool() {
  local t="$1"
  if [ -x "$ROOT/.venv/bin/$t" ]; then echo "$ROOT/.venv/bin/$t"; return 0; fi
  if [ -x "$ROOT/.venv/Scripts/$t.exe" ]; then echo "$ROOT/.venv/Scripts/$t.exe"; return 0; fi   # Windows venv
  if [ -f "$ROOT/uv.lock" ] && command -v uv >/dev/null 2>&1; then echo "uv run $t"; return 0; fi
  if [ -f "$ROOT/poetry.lock" ] && command -v poetry >/dev/null 2>&1; then echo "poetry run $t"; return 0; fi
  command -v "$t" >/dev/null 2>&1 && { echo "$t"; return 0; }
  return 1
}
