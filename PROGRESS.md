# PROGRESS.md — Trạng thái dự án

> Goal giữ phạm vi; Issue/PR/CI giữ kết quả thực thi theo commit. Không suy ra
> đã merge, đã nghiệm thu hoặc đã deploy từ trạng thái trong tài liệu.

## Giai đoạn hiện tại

- Giai đoạn: GĐ 4, triển khai lean delivery từ baseline PR #197.
- Default-branch SHA đã đối chiếu: `e2b70bffd8f6adadd14b96b31d7b0ab62f63cc61`.
- Ngày cập nhật: 2026-10-07

## Goal đang active

`docs/goals/2026-10-07-lean-delivery.md`, spec đã được chủ repo duyệt ngày
2026-10-07. Issue #198 theo dõi các slice, PR/CI và phần chưa được kiểm chứng.

## Đang làm / chờ

LD-01 giảm chạy lặp CI, giữ parity với full local gate và ma trận Windows.
Chưa coi thay đổi là tích hợp trước khi PR merge và cổng của đúng head xanh.
Kế hoạch hoàn thiện khung trước đó đã có hồ sơ ở PR #197; phần nghiệm thu cũ
không được tự thay đổi bởi việc bắt đầu goal mới.

## Tiếp theo

Theo phụ thuộc trong goal: quy trình thích ứng, evidence, review/context,
profile sản phẩm và telemetry. Không thêm scheduler hay gọi model trả phí.

## Rủi ro, blocker và giới hạn

C01 pilot sản phẩm thật và C02 hosted CI các stack chưa thử vẫn cần bằng chứng
riêng; Node/Python fixture không chứng minh tất cả dự án. Chi tiết lịch sử ở
`docs/reports/2026-10-05-framework-audit.md` và
`docs/framework/strict-gate-contract.md`. Không hạ quality gate để vượt blocker.
