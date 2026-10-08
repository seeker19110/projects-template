#!/usr/bin/env bash
# _commit-guard.sh — hằng DÙNG CHUNG cho ba hàng rào bí mật/file lớn: .claude/hooks/pre-commit-gate.sh (hook Claude
# Code), scripts/githooks/pre-commit (hook git chuẩn) và scripts/maintenance-sweep.sh (quét định kỳ).
# VÌ SAO (O-4b, 2026-10-08 — TRAPS.md mục 19/53 "bản sao lệch nhau"): regex + ngưỡng từng chép nguyên văn ba nơi,
# không gì kiểm chúng còn khớp — thêm một loại khoá ở một nơi là hai nơi kia buông. Chỉ rút phần GIỐNG HỆT;
# thông điệp, exit code, cách lấy danh sách file vẫn ở từng nơi gọi.
# Chốt chặn: scripts/test-hooks-gate.sh mục 17 (không còn bản rời ngoài file này).
# CHỈ dùng để `source`; không set shell option ở đây (docs/CONVENTIONS.md §A).
# shellcheck disable=SC2034  # hằng dùng ở file source nó

# Chuỗi giống khoá/token thật: AWS / PEM private key / GitHub / GitLab / Google / OpenAI / Slack.
COMMIT_GUARD_SECRET_RE='(AKIA[0-9A-Z]{16}|-----BEGIN [A-Z ]*PRIVATE KEY-----|ghp_[A-Za-z0-9]{36}|github_pat_[A-Za-z0-9_]{22,}|glpat-[A-Za-z0-9_-]{20}|AIza[0-9A-Za-z_-]{35}|sk-[A-Za-z0-9]{32,}|xox[baprs]-[A-Za-z0-9-]{10,})'
# File lớn hơn ngưỡng này (byte, 1 MB) không nên vào git (Git LFS hoặc loại khỏi repo).
COMMIT_GUARD_MAX_FILE_BYTES=1048576
