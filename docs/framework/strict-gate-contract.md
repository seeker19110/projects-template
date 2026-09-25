# Gate thực thi và chẩn đoán môi trường

Điểm vào vẫn là `scripts/dev-task.sh`; không có quy trình/scheduler thứ hai.
Contract này cụ thể hóa phần Verify của `standard-delivery.md`.

## Bốn kết quả khác nhau

| Kết quả | Exit code | Ý nghĩa |
| --- | --- | --- |
| BLOCKED | 2 | Chưa đủ cấu hình/tool; command/config sai cú pháp; hoặc HEAD/config thay đổi trong lượt kiểm. Không được nghiệm thu. |
| READY | 0 từ doctor | Đủ điều kiện cấu hình để bắt đầu. Chưa chạy build/lint/test, không phải PASS. |
| FAIL | 1 từ gate | Một command kiểm tra đã chạy và thất bại. Dừng, sửa nguyên nhân rồi kiểm lại. |
| PASS | 0 từ gate | Các command đã cố định trong tiền kiểm đều chạy thành công; HEAD/config không đổi giữa hai lần chụp. |

Dùng `bash scripts/dev-task.sh doctor`, sau đó `bash scripts/dev-task.sh gate`.
Các lệnh đơn lẻ và `--print` vẫn phục vụ khảo sát/adoption; không dùng exit 0 của
một lệnh no-op riêng lẻ để thay cho nghiệm thu gate.

## Cấu hình theo dự án

Copy `.claude/project-commands.example.sh` thành `.claude/project-commands.sh`.
Điền command thật cho build/typecheck/lint/test. Bộ dò 13 stack vẫn hoạt động nhưng
không suy ra rằng kiểm tra bị thiếu là không áp dụng. Dự án không cần một loại kiểm
tra phải khai `gate_skip_<task>_reason` có lý do được review trong spec/ADR. Lý do
rỗng, tất cả task N/A, hoặc command và N/A cùng tồn tại đều không được chấp nhận.

`gate_tools` khai executable cần có; `gate_python_modules` khai module cần có.
Bash, Git và jq là tiền đề chung. Các biến là tên không chứa bí mật. Thay đổi
contract/lý do N/A phải được review như thay đổi quality gate, không giao worker
tự nới cấu hình chỉ để biến đỏ thành xanh.

Config là shell tin cậy, được nạp trong shell riêng fail-fast để đọc các biến;
chỉ nên chứa gán biến, không thực thi side effect. Doctor không chạy các command
kiểm tra, nhưng không phải sandbox chống một config shell độc hại.

## Bảo vệ kết quả

Tiền kiểm toàn bộ contract trước khi chạy task đầu tiên; lỗi cấu hình không được
âm thầm rơi xuống autodetect. Command được giữ nguyên trong suốt lượt chạy và thực
thi với errexit/pipefail. HEAD hoặc bytes config thay đổi thì lượt đó BLOCKED.
Output ghi context gồm HEAD và hash config để đối chiếu, không phải attestation
mật mã hoặc snapshot toàn working tree. CI của đúng commit là nguồn nghiệm thu tích hợp.

PASS không chứng minh một command `true` là test có ý nghĩa. Reviewer vẫn phải
đối chiếu acceptance criteria với assertions, dữ liệu, artifact và mức phủ thực.
Doctor cũng không chứng minh credentials/branch protection/thiết bị production
đã được kiểm; các cổng chuyên biệt vẫn giữ nguyên.

## Chính repo khung

`.claude/project-commands.sh` trong repo này chạy syntax, static complexity,
ShellCheck, docs/CI policy, toàn bộ self-test và runtime safety. Nó không được
copy làm cấu hình mặc định sang dự án khác. Hai installer chỉ phát mẫu để dự án
đích lựa chọn command đúng stack. Bộ kiểm resolver 13 stack vẫn là fixture,
ngoại trừ fixture Node nhỏ chạy chương trình/test thật được bổ sung để đối chứng.
Không suy rộng fixture đó thành chứng minh mọi toolchain hay sản phẩm production.

## Các khoảng trống không được coi là đã đóng

C01: kiểm chứng áp dụng đầu-cuối trên một sản phẩm thật vẫn cần thực hiện.
C02: tương thích toàn bộ CI drop-in trên mọi stack vẫn cần đối chiếu đầy đủ.
Hook thiếu jq vẫn có đường fail-open như tài liệu cũ; doctor phát hiện thiếu tool,
không thay thế sandbox hoặc vô hiệu hóa mọi bypass thủ công.
Native PowerShell nâng cấp, spec-approval proof, evidence schema theo từng AC và
đánh giá UX thực tế là các phạm vi riêng, không được đánh dấu hoàn tất bởi gate này.
