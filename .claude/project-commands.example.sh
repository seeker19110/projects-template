#!/usr/bin/env bash
# Copy thành .claude/project-commands.sh và điền lệnh THẬT của dự án.
# Đây là shell tin cậy được nạp để đọc biến: chỉ dùng gán biến, không side effect.
# Command đã khai được ưu tiên; để trống sẽ tự dò stack. Task đơn lẻ có thể skip,
# nhưng gate/doctor BLOCKED nếu thiếu kiểm tra bắt buộc. Không dùng true để né gate.
#
# Kiểm cấu hình/tool (không chạy các lệnh kiểm tra): bash scripts/dev-task.sh doctor
# Kiểm thật: bash scripts/dev-task.sh gate
# READY khác PASS; nội dung command và lý do N/A phải được review theo profile.
#
# Ví dụ Node (chỉnh theo package scripts thực tế):
# export gate_tools='node npm'
# export format='npm run format'
# export build='npm run build'
# export typecheck='npm run type-check'
# export lint='npm run lint'
# export test='npm test'
#
# Ví dụ Python: dùng build-package thực nếu phát hành thư viện; dự án không có
# bước đóng gói chỉ được N/A với lý do đã review, không tự suy ra từ thiếu command.
# export gate_tools='python3 ruff mypy pytest'
# export gate_python_modules='pytest'
# export lint='ruff check .'
# export typecheck='mypy .'
# export test='pytest -q'
# export gate_skip_build_reason='CLI nội bộ chạy trực tiếp, không tạo artifact đóng gói; đã review trong spec.'
#
# Monorepo: khai lệnh tổng hợp tất cả thành phần liên quan, không chỉ workspace đầu.
# export test='pnpm -r test && pytest -q'
#
# Gate chạy Bash errexit + pipefail. Mọi pipeline/chuỗi lệnh phải phản ánh lỗi thật.
# Không được vừa có command vừa N/A cho cùng task, hoặc N/A toàn bộ bốn task.
# Các biến hỗ trợ: gate_skip_build_reason, gate_skip_typecheck_reason,
# gate_skip_lint_reason, gate_skip_test_reason; tất cả là ngoại lệ cần review.
# gate_tools chứa tên executable cách nhau bằng khoảng trắng; gate_python_modules
# chứa tên module Python. Không đưa secret/token vào command vì command được log.
#
# Bảo trì (scripts/maintenance-sweep.sh), có thể khai riêng khi tự dò không đúng:
# export deps_outdated='npm outdated'
# export deps_audit='npm audit --audit-level=high'
