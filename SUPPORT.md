# Support — Kênh hỗ trợ

> Repo này là **bộ khung/template** (không phải app chạy production). Hỗ trợ do một người bảo trì
> duy nhất (@seeker19110) đảm nhận, best-effort.

## Kênh được hỗ trợ

| Nhu cầu | Kênh | SLA (best-effort) | Dữ liệu KHÔNG được chia sẻ |
| --- | --- | --- | --- |
| Câu hỏi sử dụng khung | GitHub Issue (form 💡/🎯) hoặc Discussion nếu bật | phản hồi trong ~1 tuần | bí mật/PII |
| Bug của khung (script, CI, drop-ins, tài liệu) | GitHub Issue form 🐛 (`type: bug`) | xác nhận trong ~1 tuần | secrets/PII, log chưa lọc |
| Lỗ hổng bảo mật | Kênh riêng tư trong [SECURITY.md](SECURITY.md) (Security Advisory / email người bảo trì) | xác nhận trong 72 giờ | **không bao giờ công khai** trước khi vá |
| Sự cố production (dự án ĐÍCH dùng khung) | Xử lý tại repo dự án đích theo `docs/ops/incident-response.md` — không phải ở đây | — | dữ liệu người dùng thật |

## Phiên bản/môi trường được hỗ trợ

- Nhánh `main` (bản mới nhất; phiên bản ở file `VERSION`, SemVer — đổi luật cứng = minor, bỏ/đổi cổng = major) —
  dự án đích so `docs/framework/FRAMEWORK-VERSION` với `CHANGELOG.md`, nâng bản bằng
  `bash copy-framework.sh <đích> --upgrade` (giữ chỉnh sửa cục bộ).
- Drop-ins hồ sơ Web nhắm Next.js hiện hành + Node theo `.nvmrc`; hồ sơ khác: chỉ phương pháp, không
  hỗ trợ công cụ cụ thể.

## Triage và escalation

- Mức độ: dùng nhãn `type: bug/feature/goal/incident` + `status: *` trong issue form; bảo mật đi kênh
  riêng SECURITY.md (mục tiêu xác nhận 72 giờ, thống nhất mốc vá trước công bố).
- Người xử lý duy nhất: @seeker19110. Đóng issue khi có bằng chứng (CI xanh / bước tái hiện hết lỗi).

## Ngoài phạm vi

- Tư vấn riêng cho dự án đích, debug app của bạn, sự cố dịch vụ bên thứ ba (GitHub/Vercel/Supabase…),
  phiên bản khung cũ đã sao chép đi (hãy copy lại bản mới), và các loại dự án "cấm" (CLAUDE.md §0b).
