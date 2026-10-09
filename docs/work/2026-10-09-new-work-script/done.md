# Công việc: Script tạo hồ sơ công việc tự động

- Work ID: 2026-10-09-new-work-script
- Yêu cầu / outcome: chủ repo 2026-10-09 "thêm script tạo hồ sơ công việc tự động" — một lệnh sinh `docs/work/<ngày>-<slug>/working.md` đúng khuôn Work ID, không phải chép mẫu bằng tay.
- Trạng thái: Done (2026-10-09)
- Chủ trì / writer: phiên chính
- Mức rủi ro / số PR: M (tính năng mới, một PR, không chạm mốc §9) → spec gọn tự duyệt theo §3d; 1 PR, phiên chính tự làm
- Scope / non-goal: tạo hồ sơ mới; không đóng hồ sơ (rename `done.md` cần bằng chứng merge, giữ thủ công), không sửa hồ sơ đã có
- Spec / goal / issue: `docs/specs/2026-10-09-new-work-script.md`
- Nhánh / base SHA: `claude/laughing-clarke-3uzhft` @ `2e80d2f` (`origin/main` sau #245)

## Kế hoạch và phân công

Một PR: spec → `scripts/test-new-work.sh` đỏ → `scripts/new-work.sh` → đăng ký CI/manifest/CODEMAP/FEATURE-MAP/tài liệu → `/gate`.

## Quyết định và bằng chứng

- Bash thay vì Python · loại Python · bậc 2 (ít hơn: không cần `_python-exec.sh`, cùng khuôn `check-docs-consistency.sh`).
- Ngày lấy UTC, ghi đè được bằng `WORK_DATE` cho test · loại tham số `--date` · bậc 2 (ít nhánh parse hơn).
- Work ID đã tồn tại → thoát 1, không ghi đè · loại tự thêm hậu tố · bậc 1 (không mất dữ liệu; TRAPS 60 cấm dùng lại ID).

- Đỏ trước: `scripts/test-new-work.sh` 15/15 ca hỏng (rc=127, chưa có script) → sau khi viết `scripts/new-work.sh`: 17/17 xanh.
- `dev-task.sh gate` PASS (0 ❌) sau khi `git add` file mới (fixture chỉ chép file đã track — lần chạy đầu đỏ vì link CODEMAP tới file chưa stage).

## Lần thử / blocker

Lần 1 gate: 4 ca `test-check-scripts.sh` đỏ do file mới chưa stage (không phải lỗi script) → `git add` → xanh.

## Nghiệm thu cuối

- PR [#246](https://github.com/seeker19110/projects-template/pull/246) MERGED (squash) → `4d4ff79` trên `main`; 12 check xanh/skip đúng, gồm `framework-lint` và `framework-lint-windows` chạy `scripts/test-new-work.sh` (Git Bash); không review thread mở.
- DoD: spec AC-1..AC-5 map tới 17 ca test (đỏ trước 15/15 → xanh 17/17); `dev-task.sh gate` PASS.
- Rủi ro còn lại: ngày Work ID theo UTC; ghi đè bằng `WORK_DATE`.
- Nghiệm thu: phiên chính theo ủy quyền §3d, 2026-10-09.
