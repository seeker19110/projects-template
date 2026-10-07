# Công việc: phân chia theo PR và hồ sơ nối phiên

- Work ID: 2026-10-07-pr-dispatch-work-memory
- Trạng thái: Done — DoD đạt, PR #213 đã MERGED; đối chiếu main ngày 2026-10-08.
- Chủ trì: phiên chính; yêu cầu này dự kiến một PR, phiên chính tự thực hiện.
- Yêu cầu: một PR có thể tự làm; từ hai PR giao subagent đủ năng lực, tối đa ba subagent chạy đồng thời; mỗi việc có working.md rồi đổi thành done.md sau hoàn thiện và merge.
- Scope: luật chung, cách lưu hồ sơ từng việc, mẫu hồ sơ, hook nạp đầu phiên hiện có và kiểm thử liên quan.
- Nhánh/base SHA triển khai: feat/work-memory-and-dispatch / 661f7f6; sau merge đã về main `dfb1855a215dd5545c2752322cc9bf53cd8f5712`.
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
- PR: https://github.com/seeker19110/projects-template/pull/213; head `c986f0bae50d9d51f5f8141bfb4ec715c60286ce`. Hook Git đã chạy lại đủ cổng rồi commit; source sạch tại thời điểm push. Checkpoint này đang lưu cục bộ, chưa commit.
- CI tại checkpoint mở PR: docs-consistency/dependency-review/gitleaks/protection-guard xanh; Linux/Windows/CodeQL còn chạy. Phải tra lại trạng thái thật, không dùng dòng này như kết quả cuối.

## Nghiệm thu cuối / bàn giao

- PR #213 MERGED lúc 2026-10-07T17:16:02Z (2026-10-08 tại Asia/Bangkok); merge SHA `dfb1855a215dd5545c2752322cc9bf53cd8f5712`.
- Head kiểm chứng `c986f0bae50d9d51f5f8141bfb4ec715c60286ce`; Linux/Windows/gate, metadata, CodeQL, gitleaks, dependency-review, docs/copy/protection xanh; progress-freshness N/A theo điều kiện workflow. CI: https://github.com/seeker19110/projects-template/actions/runs/37656429153.
- Không có review thread chưa giải quyết tại nghiệm thu; phiên chính tự review/duyệt theo ủy quyền, không giả review độc lập.
- Main đã fast-forward tới merge SHA; diff tree giữa head PR và commit merge rỗng. AC-1..4 đạt bằng test/đối chiếu contract và lifecycle thật; chỉ rename sau xác minh MERGED.
- Giới hạn: runner khác Claude cần tự đọc luật/checkpoint; chưa đo cưỡng chế ngữ cảnh runtime mọi provider; file/Git hỗ trợ phục hồi, không bảo đảm model luôn nhớ.
- Bản ghi sau merge (rename và đường dẫn trong PROGRESS/spec) đang lưu cục bộ trên main, chưa commit/push; đưa vào PR công việc kế tiếp theo contract §3e. Không còn việc triển khai của yêu cầu này; không push thẳng main.
