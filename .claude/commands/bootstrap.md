---
description: Khởi tạo dự án mới (greenfield) — chạy runbook KHOI-TAO theo trình tự, dựng hàng rào chống lỗi đến cổng "Sẵn sàng phát triển"
---

Dẫn dắt **khởi tạo một dự án mới** theo `docs/framework/new-project-runbook.md` (nguồn sự thật: Phần A bước 0→9, Phần C cổng "Sẵn sàng phát triển", Phần D hàng rào). Mục tiêu cuối: đạt cổng Phần C rồi mới code tính năng (GĐ 4); cập nhật `PROGRESS.md`.

> Nối tiếp `/consult`: `/consult` chọn công nghệ (GĐ 0–2, research-first); `/bootstrap` dựng nền (GĐ 2–3). Chưa chốt stack → chạy `/consult` trước. **Đọc đúng phần cần của runbook, không nạp toàn bộ.**

- Bước 1 viết `PROJECT.md` (mẫu: `PROJECT.md` ở gốc repo khung) và chạy KHUNG-3 research-first + ADR (`/adr`).
- Bất biến theo `CLAUDE.md` §3 đúng hồ sơ dự án (§0b): mục 1–7 áp mọi loại; mục 8–10 chỉ hồ sơ có UI/web. Runbook mặc định thiên web (Next.js/Supabase/Vercel) — hồ sơ khác thay bằng cổng tương đương (KHUNG-3 PHẦN C).
- Chuỗi nhiều bước, có việc đụng dịch vụ ngoài (GitHub/hosting/CSDL) và **không thể hoàn tác**: đi **từng bước**, **xin xác nhận trước** các bước tạo tài nguyên/đổi cấu hình từ xa — quyền chưa cấp, không suy từ ủy quyền kỹ thuật (CLAUDE.md §9, contract §3d).

Bắt đầu: xác nhận đã chốt stack chưa (nếu chưa → `/consult`), rồi vào **Bước 0**.
