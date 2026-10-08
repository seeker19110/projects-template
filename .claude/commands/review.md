---
description: Review code trước khi mở PR — gọi skill code-review (+ security-review nếu chạm vùng nhạy cảm) đọc logic/thiết kế trên diff, khác /gate (chỉ máy chạy build/lint/test)
---

Kích hoạt **rà soát code trước khi mở Pull Request**. Đây là bước đọc-hiểu (logic/thiết kế/tái sử dụng), bổ sung cho `/gate` (chỉ chạy máy build/type/lint/test) — làm **cả hai**, không thay thế nhau.

> **TRIGGER:** người dùng nói đã xong một tính năng/sửa lỗi và sắp mở PR ("xong rồi", "review giúp trước khi PR", "chuẩn bị PR"), hoặc tự thấy diff đủ lớn/đủ rủi ro logic trước khi đề xuất mở PR.

## Bước 1 — Xác định phạm vi diff
- Mặc định: diff hiện tại so với nhánh chính (`git diff origin/<nhánh-chính>...HEAD`).
- Nếu người dùng chỉ định PR/nhánh/đường dẫn cụ thể → dùng đúng phạm vi đó.

## Bước 2 — Gọi skill `code-review`
Dùng `Skill(code-review)` ở effort phù hợp độ rủi ro của diff (mặc định `medium`; nâng `high` nếu diff chạm nhiều file/luồng nghiệp vụ chính). Skill tìm lỗi correctness + cơ hội tái sử dụng/đơn giản hóa/hiệu quả.

## Bước 3 — Gọi thêm `security-review` nếu chạm vùng nhạy cảm
Diff đụng auth, thanh toán, dữ liệu người dùng thật, quyền truy cập, hoặc input từ bên ngoài chưa rõ đã validate → gọi thêm `Skill(security-review)` (vùng nhạy cảm theo `docs/framework/standard-delivery.md` §3d).

## Bước 4 — Xử lý phát hiện
- Ghi phát hiện thành `review-findings/1` (khuôn ở `.claude/agents/reviewer.md`) và chạy `scripts/dev-task.sh review-check <file>`: finding `UNSUPPORTED` (không bằng chứng/không trỏ được dòng thật) bị loại; mỗi finding còn lại có đúng một hành động.
- `REPAIR-CODE` (lỗi **correctness/bảo mật** xác nhận thật) → test đỏ trước, sửa, chạy lại `/gate`, review lại phần đã sửa.
- `RERUN-EVIDENCE` → chạy lại kiểm tra/gate cho đúng phiên bản; `ASK-UPSTREAM` → hỏi người dùng hoặc sửa spec/thiết kế trước. Hai loại này **không** là lý do viết lại code.
- Gợi ý **đơn giản hóa/tái sử dụng** không bắt buộc → nêu cho người dùng quyết định (không tự ý refactor ngoài phạm vi PR).
- Không phát hiện gì đáng kể → báo ngắn gọn "review sạch, sẵn sàng PR".

## Ranh giới
- **Không thay `/gate`** — vẫn phải chạy `/gate` (build/type/lint/format/test) trước khi commit/merge như CLAUDE.md §5–§6 yêu cầu.
- **Không tự merge/tạo PR** thay người dùng nếu chưa được yêu cầu.
- Nếu review phát hiện vấn đề kiến trúc lớn (không phải bug cục bộ) → dừng và hỏi chỉ theo CLAUDE.md §9 (thiếu mục tiêu/dữ kiện không tự xác minh · không có phương án đạt chất lượng trong scope/budget · cần quyền chưa cấp) và `docs/framework/standard-delivery.md` §3d, thay vì tự quyết sửa.
