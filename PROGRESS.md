# PROGRESS.md — Trạng thái dự án

> Goal giữ đơn vị công việc; PR/CI giữ bằng chứng theo commit. Không dùng audit cũ
> hoặc lời báo DONE của worker để kết luận trạng thái hiện tại.

## Giai đoạn hiện tại

- Giai đoạn: GĐ 8. PR #179 đã merge; PR #180 đang nghiệm thu strict gate và doctor, thuộc W-05.
- Giai đoạn trước đó: snapshot trước PR #179 được giữ nguyên trong `docs/changelog/0002-2026-09-25-progress-before-runtime-safety.md` (chỉ là lịch sử).
- Default-branch SHA đã đối chiếu: `8cba0e0` (`origin/main`, sau PR #179).
- Ngày cập nhật: 2026-09-25

## Goal đang active

| Goal | Outcome | State | Current gap | Next slice | Link |
| --- | --- | --- | --- | --- | --- |
| Hoàn thiện khung 2026-09-24 | Đóng F-01..11, gate thực và re-audit | IN_PROGRESS | W-05 nghiệm thu CI và đối chiếu cuối | PR #180 | `docs/goals/2026-09-24-completion.md` |

## Đã xong

W-01 dependency #169, W-02 UI/contract #177, W-03 telemetry #178 và W-04 runtime
safety #179 đã merge. PR #179 đạt CI Linux/Windows, metadata và các scan liên quan
trước merge. Runtime regression có 10 bài, gồm 45 subcase CLI và Git local thật.

## Đang làm / chờ

PR #180 bổ sung gate fail-closed, doctor, contract của chính khung và test Node
thật. Giữ các ca phân giải 13 stack trước đó. Nội dung mới phải qua đầy đủ CI tại
head cuối; không coi test cục bộ thay cho nghiệm thu tích hợp.

## Tiếp theo

Nghiệm thu W-05 và đối chiếu phát hiện còn lại; không tuyên bố Project Complete
chỉ vì hai PR an toàn/gate đã merge. Các phần proof spec, evidence theo AC và
adoption thực tế cần bằng chứng riêng trước khi đánh dấu hoàn tất.

## Quyết định quan trọng

Ưu tiên chất lượng theo ủy quyền ngày 2026-09-25. Giữ framework đa dự án, không
scaffold mặc định, không scheduler thứ hai. CI chỉ kiểm thử, không tự sửa/push mã.
Không giảm coverage/complexity, không nới branch protection, không rollout repo dẫn xuất.

## Rủi ro, blocker và nợ kỹ thuật

| Mục | Trạng thái / xử lý |
| --- | --- |
| W-05 strict gate | Đang nghiệm thu PR #180; READY khác PASS |
| C01 adoption sản phẩm thật | Còn mở; fixture Node không thay thế sản phẩm đầy đủ |
| C02 toàn bộ CI drop-in | Còn mở; cần đối chiếu phát hành tất cả phụ thuộc trên từng loại dự án |
| Hook thiếu jq | Còn đường fail-open; doctor phát hiện tool thiếu, không thay mọi cơ chế bypass |
| PowerShell native upgrade | Dùng Git Bash; chưa có engine merge riêng |
| Upgrade transaction toàn cây | Chỉ bảo toàn từng file; không hứa atomic toàn thư mục |
| Spec approval / evidence / UX | Không suy ra đã đủ chỉ từ metadata, CI hay điểm tự động |

Chi tiết: `docs/framework/strict-gate-contract.md`, `docs/CONVENTIONS.md`,
`docs/reports/2026-09-25-runtime-safety.md`.
