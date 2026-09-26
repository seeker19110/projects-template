# Changelog

Mọi thay đổi đáng kể của dự án được ghi ở đây.

Định dạng theo [Keep a Changelog](https://keepachangelog.com/vi/1.1.0/),
và dự án tuân theo [Semantic Versioning](https://semver.org/lang/vi/).

> Vì commit theo *conventional commits*, phần "Unreleased" có thể được sinh tự động sau
> (ví dụ `standard-version` / `changesets`). Trước mắt cập nhật tay khi có thay đổi đáng kể.

## Chưa phát hành — cầu nối X-Agents

- Added: exporter delivery offline nhận policy/schema từ native X-Agents; ghim bytes spec,
  map đủ AC tới test, JSON có giới hạn và đường dẫn không thoát root. Không chạy command hoặc cấp quyền.
- Fixed: spec-compiler chỉ nhận State được chọn trong metadata; không nhận câu Approved trong Draft,
  từ chối key metadata trùng; hỗ trợ CRLF nhưng hash vẫn giữ nguyên bytes nguồn.
- Test: thêm integrity tests vào runner coverage hiện có, lỗi test làm cổng đỏ; không hạ sàn.
  Đối chiếu và cách dùng: `docs/reports/2026-09-26-bidirectional-delivery-handoff.md`.

## [Unreleased]

### Added (Thêm)

-

### Changed (Đổi)

-

### Fixed (Sửa)

-

### Removed (Bỏ)

-

<!--
Khi phát hành phiên bản, tạo mục mới phía trên, ví dụ:

## [0.1.0] - 2026-01-01
### Added
- Phiên bản đầu tiên.
-->
