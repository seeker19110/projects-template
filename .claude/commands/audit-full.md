---
description: Audit toàn diện mọi khía cạnh dự án — quét lại từ đầu hoặc tiếp tục phần chưa xong
---

Đọc kỹ `docs/ops/comprehensive-audit-prompt.md` và **làm theo đúng quy trình trong đó** (nguồn sự thật: Bước -1, Bước 0, 12 nhóm, 2 giai đoạn, mẫu file trạng thái). Lệnh này chỉ thêm phần dưới.

> 💡 Model/effort: theo `docs/framework/models-and-automation.md` §3–§4 và ADR-0010 §4.

- Khác `/audit-optimize` (chỉ tối ưu mã nguồn); muốn đi đến "không còn lỗi đã biết" → `/completion`.
- Chạy **Bước -1 trước cả Bước 0**: nếu là khung trống → DỪNG, gợi ý `/consult` hoặc `/bootstrap`, không bịa phát hiện.
- Ở Bước 0, khi đã có `docs/ops/COMPREHENSIVE-AUDIT-STATUS.md`: tóm tắt trạng thái rồi hỏi (quét lại / tiếp tục) bằng `AskUserQuestion` theo ủy quyền contract §3d.
- Giai đoạn 1 chỉ đọc & đo; xong báo cáo thì **DỪNG chờ duyệt** (§3d). Giai đoạn 2 chỉ sau khi duyệt, từng PR nhỏ qua `/gate`.
- Thiếu `docs/ops/comprehensive-audit-prompt.md` (chưa áp khung) → báo người dùng cân nhắc `copy-framework.sh`; không tự suy ra quy trình.

Bắt đầu **Bước -1** ngay.
