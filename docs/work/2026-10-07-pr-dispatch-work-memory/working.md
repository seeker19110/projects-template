# Công việc: phân chia theo PR và hồ sơ nối phiên

- Work ID: 2026-10-07-pr-dispatch-work-memory
- Trạng thái: Ready — cổng cục bộ xanh; chờ PR/CI/merge, chưa Done.
- Chủ trì: phiên chính; yêu cầu này dự kiến một PR, phiên chính tự thực hiện.
- Yêu cầu: một PR có thể tự làm; từ hai PR giao subagent đủ năng lực, tối đa ba subagent chạy đồng thời; mỗi việc có working.md rồi đổi thành done.md sau hoàn thiện và merge.
- Scope: luật chung, cách lưu hồ sơ từng việc, mẫu hồ sơ, hook nạp đầu phiên hiện có và kiểm thử liên quan.
- Nhánh/base SHA: feat/work-memory-and-dispatch / 661f7f6; đọc lại Git/PR theo nhánh khi resume, không suy trạng thái từ dòng này.
- Ghi chú kế thừa: working tree có thay đổi chưa commit từ các yêu cầu trước trong cùng cuộc trò chuyện; không bỏ hoặc giả định đã merge.

## Kế hoạch / PR

1. Research và đối chiếu cơ chế đang có; chốt contract.
2. Đồng bộ phân chia theo số PR, ghi hồ sơ working/done và cách bàn giao.
3. Test đỏ trước cho hook nạp hồ sơ, sửa tối thiểu, kiểm tra docs/hook/copy.
4. Review diff, cập nhật bằng chứng; giữ working.md cho tới khi PR thật sự merge.

## Bằng chứng / lần thử

- Đã đọc PROGRESS, contract, session-resume, PreCompact và các cổng đang chạy.
- Baseline lúc bắt đầu: chưa có working.md/done.md; hook chỉ nạp PROGRESS và Git.
- Research/approval: `docs/specs/2026-10-07-pr-dispatch-work-memory.md`, có đối chiếu ba cột và duyệt theo ủy quyền trước sửa hook.
- TDD: `bash scripts/test-hooks-session.sh` trước sửa hook exit 1, đúng 4 ca thiếu đường dẫn active khi PROGRESS thiếu/dài; sau sửa exit 0, toàn suite xanh.
- `python3 tests/test_adaptive_process.py`: 8/8 xanh; cổng docs và ShellCheck file sửa exit 0.
- `spec-compiler.sh --trace`: AC-1..4 mapped/manual, không phải nghiệm thu hoặc bằng chứng merge.
- Full gate lần đầu bị chặn do thiếu coverage/radon; đã cài đúng bản ghim trong môi trường riêng `/tmp/projects-template-work-memory-ci-uv`, không thêm dependency vào repo.
- Full gate tiếp theo: build/typecheck/lint xanh; test-check-scripts có 5 ca đỏ vì fixture chỉ sao chép file đã track còn WORK.template.md chưa staged. Đưa file mới vào index trước khi chạy lại; không bỏ cổng.
- Sau staged, các ca trên xanh; cổng contract bắt đổi tên test làm gãy evidence của spec lean-delivery đã Approved. Giữ tên test cũ, bổ sung assertion trong cùng test; không sửa spec lịch sử để né cổng.
- 2026-10-08: full `scripts/dev-task.sh gate` (PATH môi trường CI riêng) exit 0: đủ build/typecheck/lint/test; 17 shell suite và 5 Python suite chạy, không lỗi. Log: `/tmp/projects-template-work-memory-full-gate.log` (cục bộ, không thay evidence CI). Source và contract đã review; docs/config thuần áp ngoại lệ TDD-3, logic hook có đỏ-trước.

## Tiếp theo / bàn giao

Commit qua hook đầy đủ, mở PR với spec/evidence, đối chiếu CI đúng head rồi merge theo FIFO/WIP.
Không đổi thành done.md khi chỉ hoàn thành diff/test hoặc PR chưa merge.
