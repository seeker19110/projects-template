---
description: Audit tối ưu mã nguồn (brownfield) — đo baseline rồi dừng chờ duyệt
---

> 💡 Model/effort: theo `docs/framework/models-and-automation.md` §3–§4 và ADR-0010 §4.

Đọc kỹ `docs/ops/code-optimization-audit-prompt.md` và **làm theo đúng quy trình trong đó** (nguồn sự thật: lệnh đo, 5 nhóm báo cáo, dòng tổng `net:`, Giai đoạn 2). Lệnh này chỉ thêm phần dưới.

- Chỉ chạy **Giai đoạn 1** (đo baseline, chỉ đọc & đo, KHÔNG sửa) rồi **DỪNG chờ người dùng duyệt**; Giai đoạn 2 chỉ sau khi duyệt.
- Bám `quality-supplements.md` Nhóm 2 mục 9, `existing-project-adoption.md` Bước 2–3, `CLAUDE.md` §3 mục 7.
- Thiếu `docs/ops/code-optimization-audit-prompt.md` (chưa áp khung) → báo người dùng cân nhắc `copy-framework.sh`; không tự suy ra quy trình.

Bắt đầu **Giai đoạn 1** ngay.
