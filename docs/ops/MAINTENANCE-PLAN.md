# Kế hoạch bảo trì — 2026-09-21
Nguồn: docs/ops/MAINTENANCE-REPORT.md (2026-09-21) · Trạng thái: **ĐÓNG** (duyệt 2026-09-21, M-01 đã xong cùng ngày — xem `docs/ops/MAINTENANCE-LOG.md`)

| ID | Mức | Mảng | Việc | route: | Tiêu chí xong (đo được) | Cổng kiểm | Trạng thái |
| --- | --- | --- | --- | --- | --- | --- | --- |
| M-01 | 🟡 | Git | Xoá nhánh local + remote `claude/brave-gates-tn5hak` (đã merge vào `main` từ PR #153, cùng SHA `2c62723`) | mechanical | `git branch --list` và `git branch -r` không còn liệt kê nhánh này | `bash scripts/maintenance-sweep.sh --out docs/ops/MAINTENANCE-REPORT.md` → mục Git không còn dòng "nhánh local đã merge còn sót" | ✅ Xong (nhánh local đã xoá; nhánh remote thực ra đã không còn tồn tại trên `origin` — GitHub tự dọn sau merge — xác minh bằng `git push origin --delete` báo "remote ref does not exist") |

## Không làm / chờ quyết định
- Không có mục nào cần DỪNG & HỎI trong lượt quét này — không phát hiện vấn đề bảo mật, dữ liệu người dùng thật, hay breaking change.
- Dependency outdated/audit: script báo `n-a` vì repo khung không có stack ứng dụng thật (không có `package.json`/lockfile ở gốc để dò). Không khai `deps_outdated`/`deps_audit` trong `.claude/project-commands.sh` — đây là hành vi đúng của repo khung (theo CLAUDE.md §10 ghi chú riêng cho repo khung), không phải thiếu sót cần sửa.
- 10 TODO/FIXME/HACK trong mã: đã rà, toàn bộ nằm trong tài liệu hướng dẫn (CLAUDE.md, AGENTS.md, các spec/skill mô tả khuôn `TODO`/`DEBT:`/`HACK` như ví dụ minh hoạ cho tác giả dự án đích đọc), không phải nợ kỹ thuật thật của chính repo khung. Không cần hành động — nếu muốn giảm nhiễu, có thể đề xuất sửa engine (xem mục dưới) để loại trừ các dòng mang tính ví dụ/tài liệu.

## Báo oan đã loại (đề xuất sửa engine)
- Không có báo oan cần loại trong lượt quét này — cả 6 mảng đều khớp thực tế khi đối chiếu thủ công (nhánh còn sót đúng là đã merge; TODO đếm được đúng là tồn tại dù không phải nợ thật; cổng docs-consistency/ci-policy/arch-health-radar đều đã tự chạy lại và xanh).
