# Runtime safety: bảo trì và nâng phiên bản khung

Status: Approved for implementation
Approved by: Chủ dự án qua yêu cầu triển khai và ủy quyền quyết định ngày 2026-09-25.
Approval date: 2026-09-25
Goal: Hoàn tất W-04 trong `docs/goals/2026-09-24-completion.md`.

## Problem và research

Baseline `23accce8`: parser thiếu giá trị có thể lặp vô hạn; retry với lease mới có
thể đè báo cáo concurrent; merge fatal có thể bị nhận là thành công. Đã đọc trực
tiếp code và các suite kiểm thử. Tham chiếu Git đã kiểm ngày 2026-09-25:
https://git-scm.com/docs/git-push và https://git-scm.com/docs/git-merge-file.

## Requirements và acceptance criteria

- FR-1 / AC-1: CLI thiếu/rỗng/cờ kế tiếp thoát 2 trước side effect; không treo.
- FR-2 / AC-2: Lease gắn expected SHA bất biến; concurrent push/background fetch không được ghi đè remote report.
- FR-3 / AC-3: Không reset mất local base commit; không publish file ngoài ba báo cáo cho phép.
- FR-4 / AC-4: Merge trên bản tạm; fatal 255 giữ bytes đích/stamp và incoming, thoát 3.
- FR-5 / AC-5: Conflict giữ đích/stamp, lưu conflict artifact, thoát 2; merge sạch giữ cả sửa đổi local/upstream.
- FR-6 / AC-6: Kiểm thử Git local thật, đối chứng đỏ trước sửa và xanh sau sửa; các suite cũ không hồi quy.

## Phạm vi và kiến trúc

Sửa incremental các script bảo trì và `copy-framework.sh`; không scaffold mặc định,
không scheduler thứ hai, không đổi ruleset hay triển khai vào repo dẫn xuất.
Mọi sửa đổi qua PR. CI chỉ chạy kiểm thử, không tự sửa hoặc push mã nguồn.
Atomicity theo từng file, không tuyên bố transaction nguyên tử toàn cây.

## Validation, rollout và rollback

Kiểm thử CLI hữu hạn, concurrent push, background fetch, staged file ngoài phạm vi,
local commit chưa push, merge fatal/conflict/clean. Giữ PR mở khi còn check đỏ.
Required checks và review phải đạt trước merge. Rollback bằng revert PR, không tự
reset dữ liệu ở dự án đích hoặc xóa artifact conflict.
