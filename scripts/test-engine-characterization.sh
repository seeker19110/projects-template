#!/usr/bin/env bash
# test-engine-characterization.sh — CHARACTERIZATION TEST cho hai hàm đo đạc phức tạp nhất
# của hai engine Python:
#   - scripts/arch-health-radar.py :: scan_codebase_health (+ _scripts_inventory, _spec_quality)
#   - scripts/spec-compiler.py     :: parse_spec_markdown
#   - scripts/subagent-dispatch.py :: main (CLI: --list, --json, lỗi thiếu/sai agent, render 4 harness)
#
# VÌ SAO TỒN TẠI: hai hàm này là logic ĐO ĐẠC thật của khung (điểm sức khoẻ repo, hợp đồng spec).
# Trước khi hạ độ phức tạp của chúng (radon CC 18 → < 12) phải KHOÁ HÀNH VI TỪNG NHÁNH lại,
# nếu không một diff "gọn hơn" đặt sai chỗ sẽ âm thầm đổi con số mà không cổng nào bắt được.
# Test dựng repo tổng hợp trong thư mục tạm, trỏ ROOT_DIR của module vào đó, gọi THẲNG hàm và
# assert giá trị trả về — không phải "chạy không crash".
#
# KHÔNG viết bằng .py trong scripts/ là CỐ Ý: scripts/test-py-coverage.sh chạy
# `coverage run --source=scripts`, nên mọi file .py nằm trong scripts/ mà không được chính
# test-py-coverage.sh gọi sẽ bị tính 0% và kéo tụt sàn 95%.
#
# Chạy: bash scripts/test-engine-characterization.sh
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT" || exit 1

PYTHON_CMD="python3"
command -v python3 >/dev/null 2>&1 || PYTHON_CMD="python"

# Thân test nằm ở tests/engine_characterization/ (tách 2026-10-06, W-05: file .sh cũ 455 dòng > ngưỡng 400);
# gồm test_radar.py, test_compiler.py, test_dispatch.py, common.py — hành vi và số ca test không đổi (42 sau LD-05: context thiếu/hỏng/quá lớn báo lỗi thay vì bỏ im lặng).
# PYTHONIOENCODING: console Windows mặc định cp1252 → in tiếng Việt sẽ UnicodeEncodeError (TRAPS.md bẫy 24).
PYTHONIOENCODING=utf-8 "$PYTHON_CMD" -m unittest discover -s tests/engine_characterization -t . -v
