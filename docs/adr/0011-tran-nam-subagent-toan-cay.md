# ADR-0011: Trần subagent đang chạy trong toàn cây là 5 (thay cho 3)

- **Trạng thái:** Đã chấp nhận (chỉ thị trực tiếp của chủ repo trong phiên 2026-10-09)
- **Ngày:** 2026-10-09
- **Bổ sung cho:** ADR-0010 (phần "Bổ sung theo yêu cầu chủ repo 2026-10-07" ghi trần ba — nay là năm;
  ADR-0010 giữ nguyên, không sửa).

## Bối cảnh

Trần "tối đa 3 subagent đang chạy trong toàn cây" (coordinator/reviewer/tester/agent lồng tính cả) được đặt
2026-10-07 để giữ chi phí token và tránh tranh chấp file giữa worker. Đợt finishing 2026-10-09 cho thấy các
đơn vị độc lập (worktree riêng, không chung file) chờ nhau chỉ vì trần slot, không vì phụ thuộc thật.
Chủ repo yêu cầu: "chạy song song tối đa 5 subagent".

## Quyết định

1. Trần toàn cây = **5 subagent đang chạy**, vẫn tính cả coordinator, reviewer, tester và agent do subagent tạo.
2. Coordinator đang chạy còn tối đa **bốn** slot cho agent khác; phiên chính quản lý ngân sách slot, coordinator
   không tự cấp thêm.
3. Điều kiện song song KHÔNG đổi: chỉ các đơn vị độc lập (không chung file/dependency/migration/lockfile) chạy
   song song; phụ thuộc vẫn tuần tự. Trần WIP 3 PR mở/FIFO (`CLAUDE.md` §8) là cổng riêng, không đổi.
4. Trần ngữ cảnh 500.000 token/phiên áp cho TỪNG agent, không cộng dồn — nhiều agent hơn không nới ngân sách
   mỗi agent.

Nơi ghi luật: `CLAUDE.md` §2, `AGENTS.md`, `docs/framework/standard-delivery.md` §3c,
`docs/framework/orchestration-3-tier.md`, `.claude/agents/coordinator.md`, `.claude/commands/auto.md`,
`docs/framework/templates/WORK.template.md`; cổng: `tests/test_adaptive_process.py`.

## Lý do

Giới hạn thật của song song là tranh chấp file và chi phí, không phải con số 3; với worktree riêng cho từng
đơn vị (đã là luật ở §3c) thì 5 agent độc lập vẫn an toàn. Chi phí tăng theo số việc, không theo trần —
trần chỉ chặn bùng nổ khi agent lồng agent.

## Các phương án đã cân nhắc

- **Giữ 3:** an toàn nhưng chủ repo đã quyết khác; không có dữ kiện cho thấy 3 ngăn được lỗi nào mà 5 không.
- **Bỏ trần:** agent lồng agent có thể bùng nổ token không kiểm soát — bị loại.

## Hệ quả

Hồ sơ công việc (`docs/work/*/working.md`) ghi số slot đang dùng khi giao ≥ 2 agent; xem lại ADR này nếu
telemetry (`scripts/telemetry-log.py`) cho thấy chi phí/lỗi tăng rõ rệt khi chạy ≥ 4 agent song song.
