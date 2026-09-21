---
description: Thiết kế schema DB/API contract TRƯỚC khi viết code, cho tính năng cần DB schema mới hoặc endpoint mới — nối vào feature gate (docs/specs), chốt schema/API trước khi implement
---

Kích hoạt bước **thiết kế contract (schema DB và/hoặc API) trước khi code**, cho tính năng cần schema mới hoặc endpoint mới. Đây là bước **bổ sung nằm bên trong feature gate** (CLAUDE.md §2 "Feature gate") — không thay thế spec, mà là phần schema/API phải chốt **trước khi** spec được "Approved for implementation".

> **TRIGGER:** người dùng mô tả một tính năng cần bảng/cột DB mới, thay đổi schema hiện có, hoặc một API endpoint mới/đổi chữ ký — **trước khi** bắt đầu sửa source code.

## Bước 1 — Xác định phạm vi contract
- **DB:** bảng/cột mới, thay đổi kiểu dữ liệu, ràng buộc (FK/unique/check), index cần thêm.
- **API:** route, method, request/response schema, mã lỗi, auth/quyền yêu cầu.
Đọc `PROJECT.md` mục schema/kiến trúc hiện có trước — không bịa cấu trúc, không đoán tên bảng/field đã tồn tại (CLAUDE.md §4).

## Bước 2 — Viết contract vào spec tính năng
Ghi vào `docs/specs/<ngày>-<slug>.md` (mẫu `FEATURE-SPEC.template.md`), mục "Architecture và code touchpoints":
- **DB:** DDL thật (`CREATE TABLE`/`ALTER TABLE`) hoặc thay đổi migration cụ thể, kèm rollback được (CLAUDE.md §6).
- **API:** chữ ký endpoint đủ để `spec-compiler.sh` kiểm được (path, method, request/response, mã lỗi) — theo đúng khuôn OpenAPI nếu dự án đã dùng, hoặc bảng rõ ràng nếu chưa.
- Đối chiếu breaking change: đổi contract hiện có ảnh hưởng client/consumer khác → nêu rõ, thuộc CLAUDE.md §9.

## Bước 3 — Đối chiếu ràng buộc bất biến trước khi chốt
- Bảo mật: input từ client validate ở server, không tin client (CLAUDE.md §3 mục A2).
- Không secret/PII lộ trong response mặc định.
- Migration có phiên bản, rollback được (CLAUDE.md §6).

## Bước 4 — Chờ duyệt (đúng feature gate)
Spec (gồm contract vừa viết) phải có **"Approved for implementation"** + người duyệt + ngày **trước khi sửa source code** (CLAUDE.md §2). Chưa duyệt → chỉ được tiếp tục research/viết spec, không code.

## Ranh giới
- Không tự chế schema khi thiếu thông tin nghiệp vụ — hỏi người dùng (CLAUDE.md §9 "yêu cầu mơ hồ").
- Không code trước khi contract trong spec được duyệt.
- Tính năng nhỏ không đụng DB/API mới (chỉ sửa logic nội bộ) → không cần lệnh này, feature gate thường vẫn áp dụng nhưng khỏi bước contract riêng.
