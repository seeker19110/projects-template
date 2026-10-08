---
description: Hoàn thiện dự án — lập kế hoạch chi tiết từ hiện trạng + audit, thực thi từng đợt qua cổng, re-audit hội tụ đến khi không còn lỗi đã biết, nghiệm thu theo Definition of Complete
---

Đọc kỹ `docs/framework/project-completion.md` và **làm theo đúng 5 pha trong đó** (nguồn sự thật: Pha 0–4, tiêu chí thoát, Definition of Complete, 4 file trạng thái). Lệnh này chỉ thêm phần dưới.

> 💡 Model/effort: theo `docs/framework/models-and-automation.md` §3–§4 và ADR-0010 §4.

- **Bước -1** (mượn từ `/audit-full`): xác nhận là dự án cụ thể đã phát triển; khung/template trống → DỪNG, gợi ý `/consult` hoặc `/bootstrap`.
- **Bước 0:** đọc `docs/ops/COMPLETION-PLAN.md` nếu có; kế hoạch đang mở → tóm tắt trạng thái rồi hỏi bằng `AskUserQuestion` (tiếp tục đúng chỗ dở / lập lại; theo ủy quyền contract §3d). Chưa có → chạy từ Pha 0.
- Không bỏ pha, không đảo; Pha 2 xong thì **DỪNG chờ duyệt kế hoạch + DoC** (§3d), chưa duyệt chưa sửa.
- Dừng và hỏi chỉ theo CLAUDE.md §9 và `docs/framework/standard-delivery.md` §3d, kể cả giữa Pha 3.
- Thiếu `docs/framework/project-completion.md` (chưa áp khung) → báo người dùng cân nhắc `copy-framework.sh`; không tự suy ra quy trình.

Bắt đầu **Bước -1** ngay.
