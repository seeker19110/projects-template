# PROGRESS.md — Trạng thái dự án

> Goal giữ phạm vi; Issue/PR/CI giữ kết quả thực thi theo commit. Không suy ra
> đã merge, đã nghiệm thu hoặc đã deploy từ trạng thái trong tài liệu.

## Giai đoạn hiện tại

- Giai đoạn: GĐ 4, triển khai lean delivery (goal `docs/goals/2026-10-07-lean-delivery.md`); LD-01 đã merge (#200), LD-02 mở ở #203, LD-03 đang làm.
- Giai đoạn trước đó: snapshot trước PR #179 được giữ nguyên trong `docs/changelog/0002-2026-09-25-progress-before-runtime-safety.md` (chỉ là lịch sử).
- Default-branch SHA đã đối chiếu: `fd178faa368a6a36931824d9f567fc7401a5be6a` (`origin/main`, sau PR #200).
- Ngày cập nhật: 2026-10-07

## Goal đang active

`docs/goals/2026-10-07-lean-delivery.md`, spec đã được chủ repo duyệt ngày
2026-10-07. Issue #198 theo dõi các slice, PR/CI và phần chưa được kiểm chứng.

## Đang làm / chờ

LD-01 (CI parity, mỗi suite Linux chạy đúng một lần) đã merge ở #200.
LD-02 (mức quy trình theo rủi ro) mở ở #203, do phiên khác làm.
LD-03 trên nhánh `claude/blissful-bardeen-penh5b`: gate ghi evidence gắn HEAD/config/working
tree, `evidence-check` từ chối evidence cũ/thiếu, lệnh no-op và test 0 ca bị chặn, C-4 + `--trace`
nối mọi AC tới bằng chứng có thật. Bằng chứng: `scripts/test-dev-task.sh` mục 7b,
`scripts/test-next-gen-engines.sh` mục 1b, `tests/test_acceptance_trace.py`. `--trace` của spec lean-delivery vẫn INCOMPLETE
(AC-2, AC-4..8 chưa có) — đúng trạng thái goal. Chưa coi là tích hợp trước khi PR merge.
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

Sau LD-02/LD-03: LD-04 review/repair, LD-05 context/harness, LD-06 profile sản phẩm,
LD-07 telemetry, LD-08 adoption. Khi #203 vào main: đổi dòng AC-2 trong bản đồ của spec
lean-delivery sang test thật của nó. Không thêm scheduler hay gọi model trả phí.

## Rủi ro, blocker và giới hạn

C01 pilot sản phẩm thật và C02 hosted CI các stack chưa thử vẫn cần bằng chứng
riêng; Node/Python fixture không chứng minh tất cả dự án. Chi tiết lịch sử ở
`docs/reports/2026-10-05-framework-audit.md` và
`docs/framework/strict-gate-contract.md`. Không hạ quality gate để vượt blocker.
