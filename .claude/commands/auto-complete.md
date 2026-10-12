---
description: Làm tới xong, tự quyết thay người dùng — chạy /auto (kế hoạch → thực thi) nối liền /completion (audit → hội tụ → Definition of Complete) trong một lượt; mọi cổng phê duyệt do phiên chính tự duyệt theo thứ tự ưu tiên §3d (đúng+bảo mật+không mất dữ liệu › ít hơn › kiểm được › nhanh), ghi từng quyết định; chỉ dừng ở §9 / BLOCKED
---

> 💡 Model/effort: theo `docs/framework/models-and-automation.md` §3–§4 và ADR-0010 §4.

Bạn là **người quyết định thay chủ repo** cho toàn bộ lượt này. Luật nguồn: `docs/framework/standard-delivery.md` §3d
(ủy quyền + **thứ tự ưu tiên khi xung đột**) và §8 (stop conditions). Lệnh này chỉ nối hai playbook đã có, không thêm pha mới.

## Chuỗi chạy (không bỏ bước, không hỏi giữa chừng ngoài §9)
0. **Bật vòng giữ lượt** (hook Stop `auto-complete-guard.sh`): sau khi đọc/tạo hồ sơ `docs/work/<id>/working.md` (§3e), ghi Work ID
   vào marker: `printf '%s\n' "<work-id>" > .claude/.auto-complete-loop` (gitignored, sống trong một phiên). Từ đó mỗi khi lượt
   định kết thúc mà hồ sơ còn `- Trạng thái: Active`, hook **không cho kết lượt** và nhắc mục "Bàn giao / bước tiếp theo" — nên
   **luôn giữ mục đó là bước cụ thể kế tiếp**. Hook tự cho dừng khi: `- Trạng thái: Blocked — …`/`Waiting — …` (§9/§8), hồ sơ đã
   rename `done.md`, usage-guard đã nhắc wind-down, đủ `AUTO_COMPLETE_MAX_CONTINUES` (mặc định 20) lượt, lời cuối lặp y hệt,
   hoặc cổng commit đỏ ≥ 3 lần cùng failure (`.claude/.gate-red-streak` → ghi Blocked theo §8). Tín hiệu dừng là **file trạng
   thái**, không phải câu "đã xong" (CLAUDE.md §4). Kết thúc lượt (DoC có bằng chứng hoặc BLOCKED) → `rm -f .claude/.auto-complete-loop`.
   Tuỳ chọn thêm lớp: `/goal` của Claude Code với điều kiện đo được + "or stop after 20 turns".
1. **`/auto`** nguyên văn (`.claude/commands/auto.md`): research → kế hoạch toàn bộ → chốt → thực thi theo số PR (§3c; từ 2 PR giao subagent, brief qua `subagent-dispatch.sh --check-plan`). Cổng "chốt kế hoạch" của /auto: **tự duyệt**, ghi "Approved for implementation — phiên chính duyệt theo ủy quyền §3d" + ngày.
   - **Dự án MỚI (repo chưa có code):** trước khi code tính năng, chạy `/consult` (research-first, phiên bản nguồn sống) rồi
     `/bootstrap` (`new-project-runbook.md` Bước 0→9) tới cổng **"Sẵn sàng phát triển"** (Phần C) — không mở PR tính năng khi cổng đó chưa đạt.
   - **Chọn kiến trúc/công nghệ** (stack, lưu trữ, auth, hạ tầng): mỗi quyết định một ADR trong `docs/adr/` từ `0000-template.md`,
     ghi **≥ 2 phương án** kèm vì sao loại (cổng docs-consistency mục 16) — không hội tụ vào ý đầu tiên.
   - **Review tách người viết, trước MỖI PR:** `/review` trên diff (skill `code-review`; chạm auth/thanh toán/dữ liệu người dùng
     → thêm `security-review`), qua subagent `reviewer`/`security-reviewer` chứ không để chính phiên vừa viết tự chấm. Phát hiện
     mức chặn sửa trong cùng PR; còn lại ghi một dòng quyết định vào `working.md`.
   - **Loop → fix:** mỗi vòng một PR; cổng commit đỏ cùng chữ ký lần 3 → ghi `Blocked` (§8), không sửa mù. Không nới cấu hình
     cổng (lint/type/test/coverage/rulesets) để xanh — các file đó ở `permissions.ask`, gặp lời hỏi là dấu hiệu đang đi sai hướng.
2. Mọi PR của bước 1 **đã merge thật** (CI xanh, SHA trên `main`) → **`/completion`** nguyên văn (`docs/framework/project-completion.md` Pha 0–4). Cổng "DỪNG trình kế hoạch + DoC" ở Pha 2: **tự duyệt** cùng cách; Bước 0 của /completion không hỏi `AskUserQuestion` — kế hoạch đang mở thì nối tiếp đúng chỗ dở.
3. **Bàn giao sản phẩm:** Definition of Complete có bằng chứng (Pha 4) → **chạy được từ clone sạch**: clone mới vào thư mục tạm,
   làm đúng các bước trong README (cài, `.env.example` → `.env` giá trị giả, build, khởi động) rồi **smoke thật** luồng chính
   (`CLAUDE.md` §6) — bước nào README thiếu thì sửa README trong PR, không bàn giao khi người nhận không tự chạy được → điền `docs/ops/release-readiness.md` tới quyết định
   **GO / NO-GO** kèm bằng chứng (đây là đề xuất; deploy/production vẫn thuộc danh sách "không bao giờ tự quyết" bên dưới) →
   rename hồ sơ thành `done.md` với PR + merge SHA ở "Nghiệm thu cuối" (cổng docs-consistency mục 13b) → báo cáo cuối lượt.
   Hoặc dừng `BLOCKED`/`WAITING` đúng §8.

## Cách quyết định (áp cho MỌI lựa chọn trong lượt)
- Đi thang ưu tiên §3d từ trên xuống, dừng ở bậc đầu tiên phân thắng bại: **(1) đúng + bảo mật + không mất dữ liệu** (loại thẳng phương án hụt) → **(2) ít hơn** (code/nhánh/dependency/cấu hình/bảo trì, thang `CLAUDE.md` §3.4) → **(3) kiểm được** (bằng chứng máy rẻ, rõ) → **(4) nhanh/rẻ**.
- Mỗi quyết định ghi **một dòng** vào `docs/work/<id>/working.md` "Quyết định và bằng chứng": *chọn · loại · bậc phân thắng bại*. Người dùng đọc file này để audit sau, không bị hỏi trước.
- **Không bao giờ tự quyết** (dừng BLOCKED, nêu lựa chọn + đề xuất): xoá/đổi phá vỡ dữ liệu thật, thanh toán/chi phí mới, deploy/production, secret/quyền mới, thay đổi ngoài scope đã giao, cùng một failure quá 3 lần (§8). Quyền merge/deploy không suy ra từ quyền code.
- Mọi cổng máy giữ nguyên: TDD đỏ-trước, `/gate`, spec Approved cho `feat`, PR template, WIP 5/FIFO, auto-merge chỉ khi CI xanh.

## Báo cáo cuối lượt
Một khối ngắn: PR đã merge (số + SHA) · số quyết định tự duyệt (trỏ working.md) · ADR đã chốt · trạng thái Definition of Complete · kết quả smoke từ clone sạch + lệnh chạy sản phẩm · GO/NO-GO của `release-readiness.md` · BLOCKED còn lại (nếu có) kèm câu hỏi duy nhất cần người dùng trả lời.

**Ở dự án đích:** lệnh này đi cùng khung qua `copy-framework.sh`/`.ps1` (cả `.claude/commands/` lẫn `docs/framework/`); thiếu `docs/framework/standard-delivery.md` hoặc `project-completion.md` → báo người dùng chạy copy-framework, không tự suy luật. Dự án CÓ SẴN: `/auto` chạy nhánh brownfield (đọc stack thật, không áp stack mặc định).

Bắt đầu bước 1 ngay.
