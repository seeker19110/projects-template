# PROGRESS.md — Trạng thái dự án

> Trạng thái hiện tại của bộ khung, không phải của một dự án đích. Goal giữ đơn vị
> công việc; PR/CI giữ bằng chứng theo commit. Không coi các audit cũ là kết quả hiện tại.

## Giai đoạn hiện tại

- Giai đoạn: GĐ 8. Sau PR #178, tiếp tục goal hoàn thiện 2026-09-24; PR #179 đang nghiệm thu an toàn runtime, W-05 còn mở.
- Giai đoạn trước đó: lịch sử đến trước đợt sửa runtime được giữ nguyên trong `docs/changelog/0002-2026-09-25-progress-before-runtime-safety.md`; đây là snapshot lịch sử, không phải trạng thái đang chạy.
- Default-branch SHA đã đối chiếu: `23accce8` (`origin/main`, sau PR #178).
- Ngày cập nhật: 2026-09-25

## Goal đang active

| Goal | Outcome | State | Current gap | Next slice | Link |
| --- | --- | --- | --- | --- | --- |
| Hoàn thiện khung 2026-09-24 | Đóng F-01..11, gate thực và re-audit | IN_PROGRESS | W-04 chờ nghiệm thu CI/merge; W-05 chưa hoàn tất | PR #179 an toàn runtime | `docs/goals/2026-09-24-completion.md` |

## Đã xong

- W-01: PR #169 dependency đã merge.
- W-02: PR #177 adapter UI tùy chọn và sửa contract/fixture đã merge.
- W-03: PR #178 telemetry bảo toàn lịch sử và đơn vị thời gian đã merge; không còn ở trạng thái chờ merge.
- Nền tảng hiện có: Standard Delivery Contract, ánh xạ 5 tầng SDLC, điều phối 3 tầng,
  CI Linux/Windows, guard branch protection, coverage/complexity gates và nâng phiên bản khung.

## Đang làm / chờ

- W-04: PR #179 sửa CLI, lease bảo trì, giới hạn phạm vi publish, local commit và merge upgrade.
- Regression đã có đối chứng cục bộ; chỉ nghiệm thu sau khi required checks xanh tại đúng SHA.
- W-05: đóng khoảng trống gate local no-op, đối chiếu bản đồ/quy ước và re-audit.
- Chi tiết phạm vi/bằng chứng/giới hạn: `docs/reports/2026-09-25-runtime-safety.md`.

## Tiếp theo

Hoàn tất review/CI cho W-04, tích hợp qua PR, rồi thực hiện W-05 trên main mới.
Không suy ra Project Complete chỉ từ một suite xanh hoặc một PR đã merge.

## Quyết định quan trọng

- Người dùng ngày 2026-09-25 giao triển khai nâng cấp ưu tiên chất lượng và ủy quyền quyết định trong repo này.
- Giữ framework đa dự án: không thêm scaffold Web mặc định; không áp stack lên brownfield.
- Không tạo scheduler thứ hai cạnh harness; template giữ tiêu chuẩn, contract và bằng chứng.
- CI chỉ kiểm thử, không tự sửa hay push mã. Không giảm ngưỡng test/coverage/complexity hoặc nới ruleset.
- Không tự triển khai các thay đổi này vào repo dẫn xuất hoặc dữ liệu production.

## Rủi ro, blocker và nợ kỹ thuật

| Mục | Trạng thái | Hành động |
| --- | --- | --- |
| Gate local có thể no-op | W-05 còn mở | Không dùng exit 0 của gate cũ làm bằng chứng hoàn thành |
| An toàn runtime | W-04 đang nghiệm thu | Kiểm concurrent push, worker scope, CLI và dữ liệu sau lỗi |
| Upgrade không nguyên tử cho toàn cây | Giới hạn được ghi nhận | Bảo toàn từng file, giữ stamp khi merge lỗi/xung đột; review artifact trước chạy lại |
| PowerShell `-Upgrade` | Chưa có merge engine riêng | Dùng Git Bash với `copy-framework.sh --upgrade`; không tuyên bố tương đương ở tính năng này |
| Lịch sử nợ/đối chiếu cũ | Snapshot, không coi là blocker hiện tại tự động | Xem snapshot lịch sử và xác minh lại trước khi mở việc mới |

## Nguồn sự thật

`docs/framework/standard-delivery.md` → `docs/goals/2026-09-24-completion.md` →
spec → code/test → PR/CI. Nhật ký đầy đủ ở Git history và `docs/changelog/`.
