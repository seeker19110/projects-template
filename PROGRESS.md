# PROGRESS.md — Trạng thái dự án

> Goal giữ đơn vị công việc; PR/CI giữ bằng chứng theo commit. Không dùng audit cũ
> hoặc lời báo DONE của worker để kết luận trạng thái hiện tại.

## Giai đoạn hiện tại

- Giai đoạn: GĐ 8, Reconcile. Các PR sửa khung đến #197 đã merge; hồ sơ reconciliation cuối sẵn sàng nghiệm thu sau CI của PR tài liệu này.
- Giai đoạn trước đó: snapshot trước PR #179 được giữ nguyên trong `docs/changelog/0002-2026-09-25-progress-before-runtime-safety.md` (chỉ là lịch sử).
- Default-branch SHA đã đối chiếu: `e2b70bffd8f6adadd14b96b31d7b0ab62f63cc61` (`origin/main`, sau PR #197).
- Ngày cập nhật: 2026-10-06

## Goal đang active

| Goal | Outcome | State | Current gap | Next slice | Link |
| --- | --- | --- | --- | --- | --- |
| Hoàn thiện khung 2026-09-24 | Đóng F-01..11, gate thực và re-audit | WAITING | Reconciliation F-11/F-K08 nằm trong PR tài liệu này; xác nhận đóng kế hoạch còn chờ | CI/merge hồ sơ cuối, rồi nghiệm thu của người dùng | `docs/goals/2026-09-24-completion.md` |

## Đã xong

W-01 dependency #169, W-02 UI/contract #177, W-03 telemetry #178 và W-04 runtime
safety #179 đã merge. PR #179 đạt CI Linux/Windows, metadata và các scan liên quan
trước merge. Runtime regression có 10 bài, gồm 45 subcase CLI và Git local thật.

## Đang làm / chờ

PR đối chiếu X-Agents lần 2 (2026-10-06): sửa mode hook, cổng commit tự-stage, cổng bảng Markdown thừa ô;
báo cáo `docs/reports/2026-10-06-doi-chieu-x-agents-v2.md`. Kế hoạch 2026-10-05 vẫn chờ xác nhận đóng.

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

Sau khi CI/merge hồ sơ cuối đạt, người dùng xác nhận đóng kế hoạch 2026-10-05
(theo Pha 4 của `docs/framework/project-completion.md`). C01 ngoài phạm vi repo
khung; C02 còn giới hạn hosted CI và runtime các stack chưa thử. Chi tiết nằm
trong `docs/reports/2026-10-05-framework-audit.md`.

## Quyết định quan trọng

Ưu tiên chất lượng theo ủy quyền ngày 2026-09-25. Giữ framework đa dự án, không
scaffold mặc định, không scheduler thứ hai. CI chỉ kiểm thử, không tự sửa/push mã.
Không giảm coverage/complexity, không nới branch protection, không rollout repo dẫn xuất.

## Rủi ro, blocker và nợ kỹ thuật

| Mục | Trạng thái / xử lý |
| --- | --- |
| W-05 strict gate | #180, #188 và #196 đã merge; hồ sơ F-11/re-audit trong PR tài liệu này |
| F-11 / F-K08 bản đồ tính năng | Đã đối chiếu 16 command, 11 agent, 9 hook, 9 workflow; 13 mẫu Markdown + 1 CI. Reconciliation trong PR tài liệu này; có hiệu lực khi merge |
| C01 adoption sản phẩm thật | Ngoài phạm vi repo khung đã chọn; xem lại khi người dùng chỉ định repo sản phẩm và quyền thử |
| C02 toàn bộ CI drop-in | #195 chứng minh copy/gate Node/Python tối thiểu và CI offline. Xem lại khi có repo đích để chạy hosted CI hoặc cần stack khác |
| Quét dependency tự dò | #194 quét root + một cấp `apps/*`/`packages/*`; khai lệnh riêng cho cây sâu hơn. Xem lại khi gặp workspace lồng sâu |
| Hook thiếu jq | Còn đường fail-open có cảnh báo; xem lại khi yêu cầu chặn cứng ngay cả trên máy chưa cài jq |
| PowerShell native upgrade | Dùng Git Bash; xem lại khi cần nâng cấp mà không có Git Bash |
| Upgrade transaction toàn cây | Bảo toàn từng file; xem lại khi có yêu cầu atomic cho toàn cây |
| Spec approval / evidence / UX | Metadata không chứng thực phê duyệt hay UAT; xem lại trên sản phẩm có AC/UX thật |

Chi tiết: `docs/framework/strict-gate-contract.md`, `docs/CONVENTIONS.md`,
`docs/reports/2026-09-25-runtime-safety.md`.

## Bàn giao PR #181 — 2026-09-27

- Đã sửa mô tả PR đủ sáu mục bắt buộc và dẫn approval từ spec; metadata xanh.
- CI run 36250649109 chạy lại: Linux/Windows, smoke, docs và aggregate gate xanh;
  dev-task gate PASS đủ 4 kiểm tra, coverage 96%. Progress-freshness skip đúng điều kiện main-only.
- Review thread về kiểu import unittest đã resolve sau khi rà: dùng TestCase/main và
  submodule mock có chủ đích, không phát hiện lỗi hành vi; cảnh báo style CodeQL vẫn còn.
- GitHub xác nhận merge lúc 2026-09-27T02:58:20Z bởi seeker19110, SHA f42bb5f.
- Bàn giao được ghi nhận trong PR tài liệu riêng theo yêu cầu chủ repo.
  Không thay trạng thái nghiệm thu goal cũ nếu chưa đối chiếu riêng.
