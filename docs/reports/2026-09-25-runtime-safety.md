# W-04 — an toàn runtime và nghiệm thu

Ngày: 2026-09-25. Baseline main: `23accce8`. PR tích hợp: #179.
Contract: `docs/specs/2026-09-25-runtime-safety.md`.

## Phạm vi đã thực hiện

| Vấn đề | Cơ chế sửa | Nơi sửa / kiểm chứng |
| --- | --- | --- |
| Thiếu giá trị CLI gây treo hoặc chạy sai | Kiểm trước `shift 2`, exit 2 trước side effect | Ba script maintenance; 45 subcase CLI |
| Retry/fetch làm mới lease, đè báo cáo concurrent | Expected SHA bất biến từ trước khi agent chạy; remote thay đổi thì dừng | `scripts/maintain-cron.sh`; Git bare remote + hai checkout |
| Working tree sạch nhưng có commit chưa push | Kiểm local base là ancestor của remote trước reset | Cron; ca local unpublished commit |
| Agent có thể đưa file khác vào commit | Kiểm phạm vi staged/unstaged/untracked và HEAD/nhánh | Cron; ca staged file và worker commit |
| Merge fatal bị coi là thành công | Merge trên bản tạm, phân biệt exit status; giữ đích và incoming | `copy-framework.sh`; fault injection exit 255 |
| Merge conflict bị áp vào đích như đã xong | Giữ đích, lưu `.framework-conflict`, exit 2 | Real Git three-way conflict |
| Manifest nâng cấp khi chưa giải quyết lỗi | Không thay stamp khi lỗi/xung đột; ghi stamp qua bản tạm | So bytes stamp trước/sau lỗi |
| Test mới chỉ tồn tại nhưng không được chạy | Nối vào cả framework-lint Linux/Windows, giữ required `gate` | `.github/workflows/ci.yml` |
| Test được tham chiếu nhưng không phát cho dự án đích | Hai installer cùng phát suite | `copy-framework.sh`, `copy-framework.ps1` |

Suite: `tests/test_runtime_safety.py`. Đây là regression bổ sung; không thay các
suite maintenance/copy/telemetry/hook/coverage/complexity hiện có.

## Bằng chứng cục bộ và cách diễn giải

Bốn file nguồn được lấy từ GitHub và đối chiếu đúng Git blob SHA trước chỉnh sửa.
Baseline chức năng: 8 bài, 6 assertion failure, 2 pass, không lỗi hạ tầng fixture.
CLI thiếu giá trị được tái hiện; lượt đầu chạy toàn bộ baseline bị timeout và không
được tính là một suite hoàn tất. Sau sửa, 9 bài ban đầu (gồm 45 subcase CLI) xanh.
Rà soát tiếp phát hiện worker tự commit ngoài phạm vi; thêm ca đỏ trước sửa,
kiểm HEAD/nhánh rồi chạy lại 10 bài xanh. Bash syntax của bốn script xanh.

CI có checkout đầy đủ và toolchain riêng. Bằng chứng cục bộ không thay thế kết quả
CI; chưa đánh dấu W-04 DONE trước khi required checks và review tại SHA cuối đạt.
Không suy ra coverage mới từ số test. Ngưỡng coverage 95% và complexity giữ nguyên.

## Bẫy cần tránh ở các lần sửa sau

Lease không kèm expected SHA có thể mất ý nghĩa khi remote-tracking ref được fetch
cập nhật. Không fetch rồi thử lại báo cáo cũ với lease mới. Local working tree sạch
không có nghĩa là local commit đã an toàn trên remote. Chỉ `git add` đúng file không
loại file đã staged hoặc commit trước đó bởi CLI; phải kiểm trạng thái Git sau worker.

`shift 2` khi chỉ còn một đối số không tiêu thụ argv: kiểm trước khi shift. Mã lỗi
merge fatal có thể là 255 trong shell; `rc >= 0` không phải phép kiểm merge thành công.

## Giới hạn, vận hành và rollback

- Đây là bảo toàn từng file khi merge, không phải transaction nguyên tử cho toàn cây.
  Các file merge sạch trước một lỗi sau đó có thể đã được cập nhật; stamp cũ vẫn được giữ.
- Legacy upgrade thiếu base tiếp tục giữ đích + incoming; không gọi đó là merge sạch.
- Bản PowerShell chưa có engine `-Upgrade`; dùng Git Bash. Không thay đổi giới hạn này trong W-04.
- Kiểm tra sau worker không thay thế sandbox/quyền hệ điều hành: chỉ chạy CLI tin cậy,
  quyền tối thiểu và checkout riêng. Không khẳng định script có thể cách ly CLI độc hại.
- W-05 gate local và re-audit còn mở; một PR an toàn xanh không đồng nghĩa Project Complete.
- Rollback bằng revert PR. Không xóa báo cáo, commit cục bộ hay artifact xung đột của dự án đích.

Snapshot PROGRESS trước đối chiếu được giữ nguyên tại
`docs/changelog/0002-2026-09-25-progress-before-runtime-safety.md`; chỉ dùng như lịch sử.
