# Hoàn thiện bộ khung — 2026-09-24

## Contract và quyền thực thi

Người dùng duyệt hồ sơ `docs/reports/2026-09-24-completion-inventory.md` và yêu cầu
“triển khai cho đến khi hoàn thiện, mọi quyết định theo hướng chất lượng cao nhất”
ngày 2026-09-24. Ngày 2026-09-25 tiếp tục yêu cầu nâng cấp ưu tiên chất lượng và
ủy quyền quyết định. Phạm vi là repo khung này; không tự triển khai vào dự án đích
hoặc dữ liệu production. Không hạ cổng để đạt kết quả xanh.

State: IN_PROGRESS. Mốc main đã đối chiếu: `23accce8` (PR #178).
Mỗi đơn vị một PR; FIFO, tối đa 3 PR mở toàn repo. PR #179 đang nghiệm thu W-04.

## Đơn vị công việc và nghiệm thu

| ID | Outcome / phạm vi ghi | Ưu tiên / cỡ | Trạng thái | Nghiệm thu |
| --- | --- | --- | --- | --- |
| W-01 | Dependency PR #169 | Thấp / S | DONE, đã merge | required checks xanh |
| W-02 | Fixture PF-2, contract/spec và adapter UI PR #177 | Trung / M | DONE, đã merge | CI Linux/Windows và metadata xanh |
| W-03 | Telemetry giữ log, ghi atomic, khóa transaction, đúng duration | Cao / M | DONE, PR #178 đã merge | integrity/concurrency/duration regression; không đổi lịch sử không rõ đơn vị |
| W-04 | Lease bất biến, CLI hữu hạn, giữ local work, upgrade lỗi | Cao / M | IN_REVIEW, PR #179 | remote report không bị đè; lỗi giữ dữ liệu; full CI xanh trước merge |
| W-05 | Gate local thực, đối chiếu trạng thái/bản đồ, re-audit | Trung / M | TODO | không coi no-op là PASS; kiểm tra repo và CI liên quan xanh |

F-01 fixture PF-2; F-02 spec thiếu mã; F-03 metadata; F-04 JSON telemetry lỗi;
F-05 concurrent telemetry; F-06 duration sai đơn vị; F-07 cron refresh lease;
F-08 CLI thiếu giá trị; F-09 merge fatal bị coi là thành công; F-10 local gate no-op;
F-11 bản đồ/tiến độ lỗi thời. Không xóa phát hiện chưa nghiệm thu khỏi danh sách.

## Phân công và thứ tự

Phiên chính giữ quyền tích hợp Git và nghiệm thu, không dùng lời báo DONE của worker
thay cho code/test/CI. Worker độc lập dùng phạm vi file/worktree riêng; không tự sửa
workflow, lockfile hoặc tài liệu chung. Thực hiện FIFO, không xây trên base chưa merge
khi có thể tránh. Cùng failure tối đa ba lần rồi quay lại phân tích tầng/nguyên nhân.

## Definition of Complete

- Mọi F-01..11 có kết cục và bằng chứng, không còn phát hiện Cao mở trong phạm vi goal.
- Mọi sửa logic có regression, chứng minh lỗi trước sửa và đạt sau sửa.
- Gate local chạy kiểm thực; CI Linux/Windows, copy smoke, metadata và checks bắt buộc xanh.
- Không đổi API/định dạng log lịch sử; không tự sửa số liệu lịch sử không rõ đơn vị.
- Tài liệu, CODEMAP/TRAPS/PROGRESS và bản đồ/quy ước khớp trạng thái cuối.
- Re-audit các nhóm áp dụng, ghi rõ phạm vi và giới hạn kiểm chứng.
- Main chứa các PR đã nghiệm thu; không còn thay đổi dở của nhiệm vụ.

## Checkpoint hiện tại

- W-01/02/03 đã merge (#169/#177/#178); checkpoint cũ “W-03 chờ CI” không còn đúng.
- W-04: spec `docs/specs/2026-09-25-runtime-safety.md`, PR #179.
  Regression dùng Git local thật: lease sau concurrent push/background fetch,
  local base commit, worker ngoài phạm vi, CLI thiếu giá trị, merge fatal/conflict/clean.
  Bằng chứng cục bộ và giới hạn ở `docs/reports/2026-09-25-runtime-safety.md`;
  kết quả CI phải đọc tại đúng SHA của PR trước merge.
- W-05 chưa hoàn tất. Không dùng “không có việc dở” hoặc điểm radar cũ để đóng goal.
