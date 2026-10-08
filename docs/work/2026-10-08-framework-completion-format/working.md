# Công việc: W-01 — đường dẫn là dữ liệu khi qua shell

- Work ID: 2026-10-08-framework-completion-format
- Yêu cầu / outcome: sửa F-C01 (filename formatter thực thi shell) và F-C03 (venv tool path không quote).
- Trạng thái: Ready cho phiên chính review/tích hợp; chưa commit/PR/merge.
- Chủ trì / writer: worker format_safety; phiên chính review và tích hợp.
- Mức rủi ro / số PR: S fix, một PR W-01 trong goal FC-2026-10-08.
- Scope: scripts/dev-task.sh, scripts/_stack-detect.sh, scripts/test-dev-task.sh, tests/test_runtime_safety.py, CODEMAP/TRAPS, quy ước/example và hồ sơ đơn vị.
- Non-goal: sandbox shell config tin cậy, đổi công cụ/dependency, sửa WIP, commit/push/merge.
- Goal / acceptance: docs/goals/2026-10-08-framework-completion.md; F-C01/F-C03 trong docs/reports/2026-10-08-framework-completion.md.
- Nhánh / base: codex/framework-completion-2026-10-08 / 6c3e3ce0fb7e236704d86fbf654b93046dbbffbb; reconcile 2026-10-08.

## Kế hoạch và phân công

Worker đọc luật, caller và regression; đợi baseline gate của phiên chính xong trước khi ghi.
Viết test runtime đỏ trước source: argv filename literal ở mọi formatter và template;
venv tool dưới root có khoảng trắng/ký tự shell phải được gọi đúng. Sửa tối thiểu bằng
Bash positional parameter cho filename, printf %q cho executable path. Chạy targeted
test/static checks, cập nhật tài liệu; phiên chính giữ full gate, PR và nghiệm thu.

## Quyết định và bằng chứng

- Đã đọc CLAUDE, contract, vai complex-implementer, orchestration, PROJECT/PROGRESS, TRAPS và hồ sơ tổng/lịch sử liên quan.
- Phiên chính duyệt kế hoạch theo ủy quyền; cho phép sửa sau baseline gate exit 0 (log /tmp/framework-completion-20261008-baseline-gate.log).
- Config format_file vẫn là shell tin cậy. Hỗ trợ placeholder {}, "{}", '{}' dùng như một đối số độc lập; filename truyền riêng qua "$1".
- Relative filename bắt đầu dấu '-' thêm './' để tránh thành cờ formatter.
- maintenance-sweep chỉ dùng node_pm/py_present từ shared helper; hiện không gọi py_tool. F-C03 tác động lệnh venv Python của dev-task.
- RED trước source: `python3 -m unittest discover -s tests -p test_runtime_safety.py -k format_file -v` exit 1, 5 method/25 subcase fail; log /tmp/framework-completion-W01-format-red.log. Formatter giả nhận sai argv/thực thi sentinel; template bị hỏng quote.
- RED trước source: cùng lệnh với `-k venv_executable` exit 1, lint 127/tool không chạy; log /tmp/framework-completion-W01-venv-red.log. Đã đọc đầy đủ cả hai log.
- GREEN sau source: hai lệnh focused exit 0, 5/5 và 1/1; log /tmp/framework-completion-W01-format-green.log, /tmp/framework-completion-W01-venv-green.log.
- `python3 tests/test_runtime_safety.py` exit 0, 16/16 method; log /tmp/framework-completion-W01-runtime-green.log. Có tất cả fallback npx/ruff/black/gofmt/rustfmt, ba dạng template, trusted operator, leading dash, missing path/tool, formatter lỗi và venv root.
- `bash scripts/test-dev-task.sh` exit 0; log /tmp/framework-completion-W01-dev-task-green.log. Resolver venv bin và Windows Scripts, gate/evidence/review/lint regressions đều xanh.
- ShellCheck mức warning exit 0 (0 cảnh báo), bash syntax/Python compile và git diff --check exit 0. Log ShellCheck /tmp/framework-completion-W01-shellcheck.log (rỗng).
- Shell complexity exit 0, 274 khối, trần hàm 12/thân 45; log /tmp/framework-completion-W01-shell-complexity.log. Python complexity exit 0, 78 khối scripts/trần 12; log /tmp/framework-completion-W01-python-complexity.log.
- docs-consistency exit 0, đủ 11 nhóm; log /tmp/framework-completion-W01-docs-consistency.log. Đã tự đọc diff source/test/docs; không thêm dependency/abstraction, không golden/snapshot.
- Đã gọi dev-task format-file cho từng file; skip do repo chưa có per-file formatter cho các loại đó. Không lấy skip làm bằng chứng formatter thật.
- Bằng chứng trên cây sửa chưa commit ở base nêu trên, không phải CI/merge. Runtime Windows và formatter thật chờ CI/bằng chứng riêng; không suy ra từ binary giả.

## Lần thử / blocker

Expected RED là bằng chứng tái hiện, không phải ba lần sửa cùng failure. Lần source fix đầu tiên GREEN.
Lượt Python complexity đầu chỉ lỗi thiếu radon vì PATH trỏ venv chưa cài; đổi sang
PATH=/tmp/framework-completion-20261008-ci/bin:$PATH của phiên chính và chạy lại xanh,
không sửa source/cổng. Không có blocker kỹ thuật đã biết.

## Bàn giao / bước tiếp theo

Phiên chính đã review diff và chạy full scripts/dev-task.sh gate --evidence (exit 0,
coverage 96%, runtime 16/16) cùng evidence-check VERIFIED tại cây staged trước cập nhật
bản ghi này; log /tmp/framework-completion-W01-gate.log. Tiếp theo hook Git kiểm lại,
tích hợp một PR W-01 cùng tài liệu, rồi chờ CI Linux/Windows. Worker đã ngừng ghi;
mọi thay đổi nằm trong checkout chung, chưa commit. Giới hạn template: placeholder là
đối số độc lập, không shell lồng/phần của đối số; config vẫn là shell tin cậy đã review.

## Nghiệm thu cuối

Chưa nghiệm thu; giữ working.md đến khi phiên chính xác minh DoD/PR MERGED và SHA thật.
