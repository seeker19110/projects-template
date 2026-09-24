# Hoàn thiện bộ khung — 2026-09-24

## Contract và quyền thực thi

Người dùng duyệt hồ sơ `docs/reports/2026-09-24-completion-inventory.md` và yêu cầu
“triển khai cho đến khi hoàn thiện, mọi quyết định theo hướng chất lượng cao nhất”
ngày 2026-09-24. Cho phép thực thi và tích hợp các sửa lỗi/kiểm thử/tài liệu trong
phạm vi này; không áp thay đổi lên dự án đích hoặc dữ liệu người dùng thật.

State: IN_PROGRESS. Mốc nền: `f3f29ef`; PR #169 và #177 đã merge. Mỗi đơn vị một PR,
FIFO, tối đa 3 PR mở toàn repo. Không hạ cổng hay coi no-op là kiểm chứng.

## Phát hiện đã tái hiện và đơn vị PR

| ID | Outcome / phạm vi ghi | Ưu tiên / cỡ | Phụ thuộc | Nghiệm thu |
| --- | --- | --- | --- | --- |
| W-01 | Đóng PR dependency #169 đã có CI xanh; kiểm lại sau cập nhật main | Thấp / S | Không | required checks xanh, merge FIFO |
| W-02 | Sửa fixture PF-2, in lỗi contract đúng, chuẩn hóa spec và test hook UI trong PR #177 | Trung / M | W-01 khi merge | test tái hiện đỏ→xanh, CI Linux/Windows và metadata xanh |
| W-03 | Giữ log telemetry khi JSON/ghi lỗi; khóa transaction chống mất entry; sửa đơn vị thời gian hook | Cao / M | Độc lập về code; merge sau W-02 | corruption giữ nguyên bytes, ghi lỗi atomic, process đồng thời đủ entry, 720s ghi đúng 720 |
| W-04 | Giữ lease khi cron gặp concurrent push; chặn thiếu giá trị CLI; xử lý git merge-file fatal | Cao / M | Độc lập về code; merge sau W-03 | remote report không bị đè, CLI thoát 2 hữu hạn, file đích còn nguyên và có bản incoming |
| W-05 | Nối gate local thật; đồng bộ bản đồ/quy ước/tiến độ; re-audit | Trung / M | W-02..04 | gate không skip các kiểm tra repo; toàn bộ suite/CI xanh, bản đồ khớp file thật |

Các phát hiện: F-01 fixture PF-2 sửa dòng không tồn tại; F-02 spec thiếu mã AC/FR;
F-03 metadata thiếu mục; F-04 telemetry nuốt JSON lỗi; F-05 telemetry mất cập nhật
đồng thời; F-06 giờ truyền vào duration_sec; F-07 cron refresh lease ghi đè báo cáo
mới; F-08 thiếu giá trị CLI gây vòng lặp; F-09 merge fatal 255 bị coi thành công;
F-10 gate local no-op; F-11 bản đồ và tiến độ lỗi thời.

## Phân công và thứ tự

- Phiên chính: spec/metadata, hook UI, điều phối Git/FIFO, gate local, tài liệu và
  tự review diff/tích hợp; không dùng kết quả agent thay cho nghiệm thu.
- Worker CI: chỉ hai suite test-check-scripts và test-next-gen-engines trong checkout hiện tại.
- Worker telemetry: worktree riêng, engine telemetry + hook + các test tương ứng.
- Worker data safety: worktree riêng, copy-framework + ba script bảo trì + test tương ứng.
- Worker không sửa lockfile/workflow/tài liệu dùng chung, không commit/push/merge.
- PR W-03/W-04 chuẩn bị song song; mở khi WIP cho phép; tích hợp theo FIFO.

## Definition of Complete

- Mọi F-01..11 có kết cục và bằng chứng; không còn phát hiện Cao mở.
- Mọi sửa logic có test hồi quy đã chứng minh đỏ trước sửa.
- Gate local chạy kiểm thực; CI Linux/Windows, copy smoke, metadata và checks bắt buộc xanh.
- Không đổi API/định dạng log lịch sử; không tự sửa số liệu lịch sử không xác định được đơn vị.
- Bản đồ, quy ước, CODEMAP/TRAPS/PROGRESS khớp trạng thái cuối.
- Re-audit các nhóm áp dụng, đo thời gian và coverage, ghi giới hạn của kiểm chứng.
- Main chứa các PR đã nghiệm thu; working tree không còn thay đổi dở của nhiệm vụ.

## Checkpoint

- Inventory đã duyệt; audit song song xác thực F-04..09 trong fixture tạm.
- Baseline local gate exit 0 nhưng skip cả bốn bước; Python thiếu coverage/radon,
  ShellCheck/PowerShell chưa có trong PATH. Đang dựng toolchain cô lập để kiểm thật.
- Lịch sử audit cũ giữ nguyên, không coi kết quả năm/ngày trước là bằng chứng hiện tại.
- W-01/02: PR #169/#177 đã merge; #177 qua framework-lint Linux/Windows,
  copy smoke, metadata, CodeQL, dependency review và secret scan.
- W-03: test đỏ trước sửa (JSON lỗi, schema, atomic replace, process đồng thời,
  đơn vị thời gian); sau sửa 6 ca integrity, hook, telemetry, copy smoke và Python
  coverage 95% xanh cục bộ. Chờ CI và merge theo FIFO.
