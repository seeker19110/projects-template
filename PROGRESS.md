# PROGRESS.md — Trạng thái dự án

> Goal giữ phạm vi; Issue/PR/CI giữ kết quả thực thi theo commit. Không suy ra
> đã merge, đã nghiệm thu hoặc đã deploy từ trạng thái trong tài liệu.

## Giai đoạn hiện tại

- Giai đoạn: Đã nghiệm thu phạm vi triển khai lean delivery theo ủy quyền chủ repo (goal `docs/goals/2026-10-07-lean-delivery.md`); LD-01 (#200), LD-03 (#204), LD-02 (#203), LD-04 (#205), LD-07 (#207), LD-05 (#208) đã merge; LD-06 (#209) đã merge; LD-08 (#210) đã merge; LD-01..08 đã tích hợp và đạt nghiệm thu kỹ thuật theo ủy quyền; hồ sơ ở #211, đóng goal ở #212.
- Giai đoạn trước đó: snapshot trước PR #179 được giữ nguyên trong `docs/changelog/0002-2026-09-25-progress-before-runtime-safety.md` (chỉ là lịch sử).
- Default-branch SHA đã đối chiếu: `661f7f6` (`origin/main`, sau PR #212).
- Ngày cập nhật: 2026-10-07

## Goal đã nghiệm thu

`docs/goals/2026-10-07-lean-delivery.md`, spec đã được chủ repo duyệt ngày
2026-10-07; LD-01..08 đã Complete theo ủy quyền quyết định của chủ repo trong cuộc trò chuyện
ngày 2026-10-07. Issue #198 và hồ sơ nghiệm thu giữ các PR/CI cùng giới hạn chưa kiểm chứng.

## Đang làm / chờ

Bản sửa gate bỏ qua thất bại ghi `--evidence` có regression thư mục đích mất,
đích trở thành thư mục và kiểm tra đỏ kèm lỗi ghi evidence. Cổng trả BLOCKED (exit 2)
và không báo PASS khi không lưu được bằng chứng; `scripts/test-dev-task.sh` mục 7b.
Trạng thái tích hợp và bằng chứng CI thuộc PR của bản sửa này.

**Ủy quyền áp riêng repo này (2026-10-07):** chủ repo yêu cầu “chọn theo hướng tốt nhất cho chất lượng cho tôi từ giờ trở đi, không cần hỏi”.
AI tự quyết các phương án và nghiệm thu trong phạm vi dự án đã giao, ưu tiên tính đúng,
bằng chứng kiểm thử và khả năng bảo trì. Không hỏi lại quyết định đã được ủy quyền.
Cổng chất lượng và scope/budget hiện tại vẫn được giữ; đây không phải sửa luật chung của template.

LD-01 (CI parity, mỗi suite Linux chạy đúng một lần) đã merge ở #200.
LD-03 (evidence gắn HEAD/config/working tree, `evidence-check`, chặn no-op/0 ca test,
C-4 + `--trace` nối AC tới bằng chứng) đã merge ở #204.
LD-02 (mức quy trình S/M/L theo rủi ro — `standard-delivery.md` §3c, spec gọn mức M,
agent chính tự làm, 3 tầng tùy chọn cho mức L, ADR-0010) đã merge ở #203; AC-2 nối tới
`tests/test_adaptive_process.py`. TRAPS mục 48 (commit do công cụ sinh làm đỏ `metadata`)
đi PR riêng vì đẩy sau khi #203 đã merge.
LD-04 (`dev-task.sh review-check`, `review-findings/1`: finding không căn cứ bị loại, thiếu
evidence/input không sinh yêu cầu sửa code; ca jq CRLF của Windows) đã merge ở #205.
LD-07 (telemetry `telemetry-record/2`: token thiếu = unknown, lần thử ≠ công việc nghiệm thu,
chi phí gồm cả lần thất bại) đã merge ở #207.
LD-05 (`subagent-dispatch` prepare-only, context thiếu/rỗng/không UTF-8/quá lớn → exit 2) đã merge ở #208.
LD-06 (#209) đã merge ở `fb05bd5`: ma trận bằng chứng hồ sơ C1–C10 × hành vi/UX-DX/
dữ liệu/bảo mật/release và độ sâu S/M/L; `tests/test_profile_quality_matrix.py`, CI Linux/Windows xanh.
Blocker tạo PR GitHub đã được xử lý sau khi chủ repo cho phép thử lại; không hạ cổng.
LD-08 (#210) đã merge ở `2b927e6`, bổ sung `tests/test_lean_adoption.py`: Node/Python runtime thật, copy → evidence → upgrade
bảo toàn config/ghi chú → từ chối evidence cũ và FAIL. Test đăng ký ở gate cục bộ và CI Linux.
`docs/framework/lean-delivery-benchmark.md` đo baseline 17 suite/34 lời gọi so với 17/17 ở c522839;
đây là giảm lời gọi, không phải số đo tiết kiệm token/thời gian. AC-1..8 đã có ánh xạ evidence;
map đầy đủ không thay thế kết quả CI của đúng commit. Required checks Linux/Windows của #210
đã xanh trước merge; pilot/hosted CI dự án đích/model benchmark chưa chạy, ngoài scope hiện tại.
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

Goal LD-01..08 đã Complete theo nghiệm thu kỹ thuật được chủ repo ủy quyền; không còn slice bắt buộc.
Việc tiếp theo chọn theo giá trị chất lượng và bằng chứng sự cố thật; không tự tạo tính năng suy đoán.
Pilot/hosted CI dự án đích/model benchmark thuộc phạm vi riêng và vẫn chưa được kiểm chứng.

## Rủi ro, blocker và giới hạn

C01 pilot sản phẩm thật và C02 hosted CI các stack chưa thử vẫn cần bằng chứng
riêng; Node/Python fixture không chứng minh tất cả dự án. Chi tiết lịch sử ở
`docs/reports/2026-10-05-framework-audit.md` và
`docs/framework/strict-gate-contract.md`. Không hạ quality gate để vượt blocker.
