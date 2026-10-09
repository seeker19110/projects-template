# Công việc: Work ID cho mọi công việc — kiểm soát đã làm/chưa

- Work ID: 2026-10-09-task-id-tracking
- Yêu cầu / outcome: chủ repo muốn mỗi công việc có mã ID trước khi làm để kiểm soát đã làm/chưa; sau nghiên cứu, chốt làm phần bổ sung tùy chọn (2026-10-09).
- Trạng thái: Done (2026-10-09)
- Chủ trì / writer: phiên chính
- Mức rủi ro / số PR: S; 1 PR (cổng tài liệu + một step CI, không đổi kiến trúc)
- Scope / non-goal: không lập sổ ID thứ hai; dùng tên thư mục `docs/work/<id>/` làm ID, tên file làm trạng thái
- Nhánh / base SHA: `claude/laughing-clarke-3uzhft` @ `9d589c0`

## Nghiên cứu (đối chiếu cổng đang chạy)

- Đã có và đủ sâu: Work ID tạo trước research (§3e); `T1…Tn` trong PLAN có `--check-plan`; trạng thái = `working.md`/`done.md`, hook đầu phiên liệt kê việc dở.
- Đã có nhưng nông: PR không ghi Work ID; không cổng nào kiểm khuôn tên thư mục / đúng một file trạng thái; ID `FT-xx` không kiểm trùng.
- Chưa có: sổ ID tập trung — không làm (sẽ thành nguồn sự thật song song, khuôn TRAPS 8).
- Sự cố thật tìm thấy khi làm: `FT-66` cấp hai lần (#240) → TRAPS 60.

## Quyết định và bằng chứng

- Mục 13 `check-docs-consistency.sh` (khuôn `YYYY-MM-DD-slug`, đúng một trạng thái) + mục 11b (ID FT trùng); step `Work ID trỏ tới hồ sơ có thật` trong job `metadata` của `pr-policy.yml` (cùng miễn trừ draft/bot), không thêm job nên required checks không đổi.
- Đỏ trước: `test-check-scripts.sh` 3 ca mục 13 + 1 ca 11b đỏ (rc=0); `test-workflow-guards.sh` mục 6 đỏ (chưa có step). Sau sửa: xanh.
- `tests/test_runtime_safety.py` trích thân github-script tới hết file → vỡ khi có step sau; sửa cho dừng ở dòng thụt < 12.
- `FT-66` (/auto-complete) → `FT-71`; hàng mới `FT-72`.

## Nghiệm thu cuối

- PR [#244](https://github.com/seeker19110/projects-template/pull/244) MERGED (squash) → `ed2019b` trên `main`; 12 check xanh/skip đúng (`progress-freshness` chỉ chạy trên main), không review thread mở.
- Lượt chạy thật đầu tiên của step Work ID trong job `metadata` (#244): log `Work ID 2026-10-09-task-id-tracking → docs/work/2026-10-09-task-id-tracking/`.
- DoD: cổng `dev-task.sh gate` PASS trước commit; test đỏ-trước → xanh (mục 13 ×3, 11b, workflow mục 6 ×8). Rủi ro còn lại: PR do bot ngoài danh sách miễn trừ phải ghi Work ID.
- Nghiệm thu: phiên chính theo ủy quyền §3d, 2026-10-09.
