# Hoàn thiện bộ khung — 2026-09-24

## Contract và quyền thực thi

Người dùng duyệt inventory ngày 2026-09-24 và tiếp tục yêu cầu nâng cấp ưu tiên
chất lượng, ủy quyền quyết định ngày 2026-09-25. Phạm vi repo khung này; không tự
triển khai vào repo dẫn xuất hoặc dữ liệu production, không hạ cổng để xanh.

State: IN_PROGRESS. Main đã đối chiếu: `8cba0e0` (PR #179).
Mỗi outcome một PR, FIFO, tối đa 3 PR mở. PR #180 đang nghiệm thu W-05.

## Công việc và bằng chứng

| ID | Outcome | State | Nghiệm thu |
| --- | --- | --- | --- |
| W-01 | Dependency #169 | DONE, merged | Required checks trước merge |
| W-02 | Fixture/spec và adapter UI #177 | DONE, merged | CI Linux/Windows và metadata |
| W-03 | Telemetry integrity/concurrency/duration #178 | DONE, merged | Regression giữ dữ liệu, đơn vị thời gian đúng |
| W-04 | CLI, lease, local work, upgrade safety #179 | DONE, merged | CI #442 tại `7b29ffbd`, merge `8cba0e0`; 10 runtime tests |
| W-05 | Gate thực, trạng thái/quy ước, re-audit | IN_REVIEW, #180 | Doctor/gate, negative tests, fixture Node thật, full CI tại head cuối |

F-01 fixture PF-2; F-02 spec thiếu mã; F-03 metadata; F-04 JSON telemetry;
F-05 concurrency; F-06 duration; F-07 lease; F-08 CLI thiếu giá trị;
F-09 merge fatal; F-10 gate no-op; F-11 trạng thái/quy ước lỗi thời.
Không đóng phát hiện chưa có bằng chứng hoặc lẫn với phạm vi mở rộng.

## Definition of Complete

Mỗi F-01..11 có kết cục và regression phù hợp; gate local chạy kiểm thực;
CI Linux/Windows, copy smoke, metadata và required checks xanh; code/docs khớp;
re-audit giới hạn/phát hiện còn lại được ghi; main chứa các PR nghiệm thu.
Không suy ra toàn sản phẩm hay mọi repo dẫn xuất hoàn thiện từ goal giới hạn này.

## Checkpoint

W-04 đã merge, không còn chờ CI/merge. Báo cáo:
`docs/reports/2026-09-25-runtime-safety.md`.
W-05 spec: `docs/specs/2026-09-25-strict-gate-contract.md`.
Trên bản gốc, test mới có 21 assertion failures (bao gồm kiểm trạng thái mới);
sau sửa, các ca resolver cũ và ca contract mới xanh cục bộ. Doctor chặn đúng
môi trường thiếu ShellCheck. Root contract đầy đủ phải nghiệm thu trên CI,
không được ghi PASS chỉ vì tool chẩn đoán trả READY.

## Phạm vi mở rộng chưa tự động đóng

C01 adoption đầu-cuối trên sản phẩm thật và C02 đầy đủ mọi CI drop-in vẫn mở.
Hook fail-open khi thiếu jq, native PowerShell upgrade, chứng thực phê duyệt spec,
evidence schema theo AC và UX thực tế không được coi là hoàn tất bởi PR #180.
Xem `docs/framework/strict-gate-contract.md` và `PROGRESS.md`.
