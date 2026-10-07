# PROGRESS.md — Trạng thái dự án

> Goal giữ phạm vi; Issue/PR/CI giữ kết quả thực thi theo commit. Không suy ra
> đã merge, đã nghiệm thu hoặc đã deploy từ trạng thái trong tài liệu.

## Giai đoạn hiện tại

- Giai đoạn: GĐ 4, triển khai lean delivery (goal `docs/goals/2026-10-07-lean-delivery.md`); LD-01 (#200), LD-03 (#204), LD-02 (#203) đã merge; tiếp theo LD-04.
- Giai đoạn trước đó: snapshot trước PR #179 được giữ nguyên trong `docs/changelog/0002-2026-09-25-progress-before-runtime-safety.md` (chỉ là lịch sử).
- Default-branch SHA đã đối chiếu: `3cee6a7be1aa3ee203bd0a52d4f3e29641ec1c8c` (`origin/main`, sau PR #203).
- Ngày cập nhật: 2026-10-07

## Goal đang active

`docs/goals/2026-10-07-lean-delivery.md`, spec đã được chủ repo duyệt ngày
2026-10-07. Issue #198 theo dõi các slice, PR/CI và phần chưa được kiểm chứng.

## Đang làm / chờ

LD-01 (CI parity, mỗi suite Linux chạy đúng một lần) đã merge ở #200.
LD-03 (evidence gắn HEAD/config/working tree, `evidence-check`, chặn no-op/0 ca test,
C-4 + `--trace` nối AC tới bằng chứng) đã merge ở #204.
LD-02 (mức quy trình S/M/L theo rủi ro — `standard-delivery.md` §3c, spec gọn mức M,
agent chính tự làm, 3 tầng tùy chọn cho mức L, ADR-0010) đã merge ở #203; AC-2 nối tới
`tests/test_adaptive_process.py`. TRAPS mục 48 (commit do công cụ sinh làm đỏ `metadata`)
đi PR riêng vì đẩy sau khi #203 đã merge.
Kế hoạch hoàn thiện khung trước đó đã có hồ sơ ở PR #197; phần nghiệm thu cũ
không được tự thay đổi bởi việc bắt đầu goal mới.

Đã merge #199: đối chiếu X-Agents lần 2 và chu kỳ hoàn thiện 2026-10-06
(radar, FEATURE-MAP↔scripts, specs, concurrency). Báo cáo `docs/reports/2026-10-06-framework-audit.md`; F-N05: chủ repo chọn giữ lại 3 nhánh remote (ghi nhận).

PR #180 đã merge (`071faea`), bổ sung gate fail-closed, doctor và test Node thật.
Các PR #188–195 đã sửa ruleset strict, môi trường Git của hook, báo cáo secret,
ignore môi trường, nhận diện manifest lồng, probe coverage, quét đa stack và
CI mẫu cho dự án đích. #185 đồng bộ CodeQL/grouping; #186 trùng đã đóng.
F-01..10 và F-K01..07/F-K09/F-K10 có regression và CI trên main.
#196 sửa lint nuốt lỗi; sau sửa fixture Windows, head `8b97ee6` đạt các cổng
bắt buộc trên Linux/Windows. Bản đồ F-11/F-K08, re-audit và ma trận bằng chứng
được bàn giao trong PR tài liệu này. Không phát hiện Cao/Trung mới trong phạm vi
code/cổng đã rà; đây không phải chứng nhận không có lỗi trên mọi dự án dẫn xuất.

## Tiếp theo

Theo goal: LD-04 review/repair, LD-05 context/harness, LD-06 profile sản phẩm,
LD-07 telemetry, LD-08 adoption. Không thêm scheduler hay gọi model trả phí.

## Rủi ro, blocker và giới hạn

C01 pilot sản phẩm thật và C02 hosted CI các stack chưa thử vẫn cần bằng chứng
riêng; Node/Python fixture không chứng minh tất cả dự án. Chi tiết lịch sử ở
`docs/reports/2026-10-05-framework-audit.md` và
`docs/framework/strict-gate-contract.md`. Không hạ quality gate để vượt blocker.
