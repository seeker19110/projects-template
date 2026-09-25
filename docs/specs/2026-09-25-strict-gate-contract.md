# Strict gate contract và chẩn đoán môi trường

Status: Approved for implementation
Approved by: Chủ dự án qua yêu cầu triển khai nâng cấp và ủy quyền quyết định ngày 2026-09-25.
Approval date: 2026-09-25
Baseline: main `8cba0e0`, sau PR #179.

## Problem và outcome

`dev-task.sh gate` đang có thể thành công dù không chạy kiểm tra nào. W-05 cần
phân biệt thiếu cấu hình, sẵn sàng và đã kiểm chứng; không thêm scheduler hoặc
scaffold mặc định. Gate cần dùng contract riêng theo dự án, không đoán mọi stack
đều có một bộ công cụ giống nhau.

## Requirements và acceptance criteria

- FR-1 / AC-1: Gate mặc định chặn khi một trong build/typecheck/lint/test chưa được cấu hình; tiền kiểm toàn bộ trước khi chạy bất kỳ task nào.
- FR-2 / AC-2: Task không áp dụng phải có `gate_skip_<task>_reason` không rỗng trong cấu hình được review; tất cả task đều skip hoặc command và lý do cùng tồn tại phải bị chặn.
- FR-3 / AC-3: `doctor` kiểm tool, cú pháp và contract, báo READY chứ không PASS; không chạy lệnh build/lint/test. Config shell là mã tin cậy và được nạp để đọc khai báo, không phải sandbox.
- FR-4 / AC-4: Config lỗi, command lỗi cú pháp, tool/module khai báo nhưng thiếu phải báo BLOCKED (exit 2); lỗi trong kiểm tra báo FAIL (exit 1); chỉ chạy thành công các kiểm tra đã phân giải mới PASS (exit 0).
- FR-5 / AC-5: Gate chạy shell fail-fast và pipefail; không để pipeline hoặc lệnh tiếp theo che lỗi. Lệnh được cố định sau tiền kiểm; HEAD/config thay đổi trong khi chạy làm kết quả BLOCKED.
- FR-6 / AC-6: Có contract chạy thật cho chính bộ khung, không phát cấu hình riêng đó như mặc định cho dự án đích. Giữ tương thích lệnh `--print` và mọi ca phân giải 13 stack hiện có.
- FR-7 / AC-7: Kiểm thử đối chứng thiếu cấu hình/lỗi và một fixture Node thực tế đỏ→xanh, không dùng API hoặc cài package trong fixture.

## Thiết kế và phạm vi

Mở rộng `scripts/dev-task.sh` với tiền kiểm dùng chung cho gate/doctor. Bổ sung
regression trong `scripts/test-dev-task.sh` vốn đã nối CI. Profile khung nằm trong
`.claude/project-commands.sh`; hướng dẫn cấu hình dự án đích ở mẫu hiện có và tài
liệu gate. Không thêm engine Python, không đổi branch rules hoặc ngưỡng coverage.

## Giới hạn và bảo mật

READY chỉ nói contract/tool đủ để bắt đầu, không khẳng định chương trình đúng.
PASS là kết quả các lệnh đã khai báo, không chứng minh một lệnh `true` là test có
ý nghĩa. Nội dung contract/lý do N/A cần review; CI của đúng commit vẫn là bằng
chứng tích hợp. Không thay thế sandbox, approval, kiểm UX trên thiết bị hay kiểm
thử sản phẩm production. Hook thiếu jq và cơ chế ngoại lệ thủ công không được
coi là đã sửa chỉ nhờ thêm doctor.

## Validation, rollout và rollback

Test mới phải đỏ trên bản gốc, xanh sau sửa; giữ toàn bộ test resolver cũ.
CI Linux/Windows và các gate cũ phải đạt trước merge. Nâng cấp có chủ ý: dự án
chưa cấu hình đầy đủ giờ bị BLOCKED; dùng doctor rồi khai command hoặc lý do
không áp dụng, không tắt kiểm tra để xanh. Rollback bằng revert PR; không tự áp
khung mới vào repo dẫn xuất. W-05 chỉ đóng khi bằng chứng phù hợp thực sự đủ.
