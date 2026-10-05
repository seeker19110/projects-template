# PROGRESS.md — Trạng thái dự án

> Goal giữ đơn vị công việc; PR/CI giữ bằng chứng theo commit. Không dùng audit cũ
> hoặc lời báo DONE của worker để kết luận trạng thái hiện tại.

## Giai đoạn hiện tại

- Giai đoạn: GĐ 8, Reconcile. Các PR sửa khung đến #195 đã merge; đang nghiệm thu #196 và bản đồ/trạng thái cuối.
- Giai đoạn trước đó: snapshot trước PR #179 được giữ nguyên trong `docs/changelog/0002-2026-09-25-progress-before-runtime-safety.md` (chỉ là lịch sử).
- Default-branch SHA đã đối chiếu: `430b4b96626433e481a13da2a0f2b2e4a2b3b3de` (`origin/main`, sau PR #195).
- Ngày cập nhật: 2026-10-05

## Goal đang active

| Goal | Outcome | State | Current gap | Next slice | Link |
| --- | --- | --- | --- | --- | --- |
| Hoàn thiện khung 2026-09-24 | Đóng F-01..11, gate thực và re-audit | IN_PROGRESS | F-11 chờ PR tài liệu; F-K10 chờ CI #196 | Nghiệm thu #196, re-audit và merge bản đồ/trạng thái | `docs/goals/2026-09-24-completion.md` |

## Đã xong

W-01 dependency #169, W-02 UI/contract #177, W-03 telemetry #178 và W-04 runtime
safety #179 đã merge. PR #179 đạt CI Linux/Windows, metadata và các scan liên quan
trước merge. Runtime regression có 10 bài, gồm 45 subcase CLI và Git local thật.

## Đang làm / chờ

PR #180 đã merge (`071faea`), bổ sung gate fail-closed, doctor và test Node thật.
Các PR #188–195 đã sửa ruleset strict, môi trường Git của hook, báo cáo secret,
ignore môi trường, nhận diện manifest lồng, probe coverage, quét đa stack và
CI mẫu cho dự án đích. #185 đồng bộ CodeQL/grouping; #186 trùng đã đóng.
F-01..10 có regression/CI; bản đồ được cập nhật theo file thật nhưng F-11 chỉ
đóng khi PR tài liệu merge. #196 sửa lint nuốt lỗi; Windows CI đầu tiên bắt
fixture phụ thuộc ShellCheck không được cài, bản sửa fixture đang nghiệm thu.

## Tiếp theo

Merge #196 sau gate và CI cuối; đối chiếu lại 12 nhóm trên `main`, hoàn tất PR
tài liệu F-11/F-K08 và báo cáo nghiệm thu. Kế hoạch 2026-10-05 chờ người dùng
xác nhận đóng sau khi có bằng chứng. Adoption sản phẩm thật và CI hosted của
repo đích chưa được chứng minh.

## Quyết định quan trọng

Ưu tiên chất lượng theo ủy quyền ngày 2026-09-25. Giữ framework đa dự án, không
scaffold mặc định, không scheduler thứ hai. CI chỉ kiểm thử, không tự sửa/push mã.
Không giảm coverage/complexity, không nới branch protection, không rollout repo dẫn xuất.

## Rủi ro, blocker và nợ kỹ thuật

| Mục | Trạng thái / xử lý |
| --- | --- |
| W-05 strict gate | #180 và #188 đã merge; còn nghiệm thu F-11/re-audit |
| F-11 / F-K08 bản đồ tính năng | Đã đối chiếu 16 command, 11 agent, 9 hook, 9 workflow; 13 mẫu Markdown + 1 CI. Chờ PR tài liệu merge |
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
