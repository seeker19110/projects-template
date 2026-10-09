---
description: Làm tới xong, tự quyết thay người dùng — chạy /auto (kế hoạch → thực thi) nối liền /completion (audit → hội tụ → Definition of Complete) trong một lượt; mọi cổng phê duyệt do phiên chính tự duyệt theo thứ tự ưu tiên §3d (đúng+bảo mật+không mất dữ liệu › ít hơn › kiểm được › nhanh), ghi từng quyết định; chỉ dừng ở §9 / BLOCKED
---

Bạn là **người quyết định thay chủ repo** cho toàn bộ lượt này. Luật nguồn: `docs/framework/standard-delivery.md` §3d
(ủy quyền + **thứ tự ưu tiên khi xung đột**) và §8 (stop conditions). Lệnh này chỉ nối hai playbook đã có, không thêm pha mới.

## Chuỗi chạy (không bỏ bước, không hỏi giữa chừng ngoài §9)
1. **`/auto`** nguyên văn (`.claude/commands/auto.md`): research → kế hoạch toàn bộ → chốt → thực thi theo số PR (§3c; từ 2 PR giao subagent, brief qua `subagent-dispatch.sh --check-plan`). Cổng "chốt kế hoạch" của /auto: **tự duyệt**, ghi "Approved for implementation — phiên chính duyệt theo ủy quyền §3d" + ngày.
2. Mọi PR của bước 1 **đã merge thật** (CI xanh, SHA trên `main`) → **`/completion`** nguyên văn (`docs/framework/project-completion.md` Pha 0–4). Cổng "DỪNG trình kế hoạch + DoC" ở Pha 2: **tự duyệt** cùng cách; Bước 0 của /completion không hỏi `AskUserQuestion` — kế hoạch đang mở thì nối tiếp đúng chỗ dở.
3. Kết thúc khi **Definition of Complete** có bằng chứng (Pha 4), hoặc dừng `BLOCKED`/`WAITING` đúng §8.

## Cách quyết định (áp cho MỌI lựa chọn trong lượt)
- Đi thang ưu tiên §3d từ trên xuống, dừng ở bậc đầu tiên phân thắng bại: **(1) đúng + bảo mật + không mất dữ liệu** (loại thẳng phương án hụt) → **(2) ít hơn** (code/nhánh/dependency/cấu hình/bảo trì, thang `CLAUDE.md` §3.4) → **(3) kiểm được** (bằng chứng máy rẻ, rõ) → **(4) nhanh/rẻ**.
- Mỗi quyết định ghi **một dòng** vào `docs/work/<id>/working.md` "Quyết định và bằng chứng": *chọn · loại · bậc phân thắng bại*. Người dùng đọc file này để audit sau, không bị hỏi trước.
- **Không bao giờ tự quyết** (dừng BLOCKED, nêu lựa chọn + đề xuất): xoá/đổi phá vỡ dữ liệu thật, thanh toán/chi phí mới, deploy/production, secret/quyền mới, thay đổi ngoài scope đã giao, cùng một failure quá 3 lần (§8). Quyền merge/deploy không suy ra từ quyền code.
- Mọi cổng máy giữ nguyên: TDD đỏ-trước, `/gate`, spec Approved cho `feat`, PR template, WIP 3/FIFO, auto-merge chỉ khi CI xanh.

## Báo cáo cuối lượt
Một khối ngắn: PR đã merge (số + SHA) · số quyết định tự duyệt (trỏ working.md) · trạng thái Definition of Complete · BLOCKED còn lại (nếu có) kèm câu hỏi duy nhất cần người dùng trả lời.

**Ở dự án đích:** lệnh này đi cùng khung qua `copy-framework.sh`/`.ps1` (cả `.claude/commands/` lẫn `docs/framework/`); thiếu `docs/framework/standard-delivery.md` hoặc `project-completion.md` → báo người dùng chạy copy-framework, không tự suy luật. Dự án CÓ SẴN: `/auto` chạy nhánh brownfield (đọc stack thật, không áp stack mặc định).

Bắt đầu bước 1 ngay.
