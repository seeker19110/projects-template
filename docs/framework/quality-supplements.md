# Bổ sung chất lượng & năng lực

> **Một file thay cho 4 tài liệu bổ sung** (Nhóm 1, Nhóm 2, Theme, Nâng cao). Đọc đúng PHẦN cần —
> không nạp cả file mỗi phiên. Tham chiếu cũ kiểu "Nhóm 1/Nhóm 2 mục X" vẫn đúng (giữ nguyên số mục).

| PHẦN | Nội dung |
|------|----------|
| 1 — Nhóm 1 | env validation, migration, PR template, ADR, npm audit, Vercel staging, DoR, sổ tay thuật ngữ (CONTEXT.md), changelog tách khỏi PROGRESS.md, đồng bộ trạng thái duyệt |
| 2 — Nhóm 2 | mobile-first, hiệu năng/Lighthouse, kiểm thử E2E+a11y+coverage, UI/UX, chống lỗi logic, observability, tối ưu mã nguồn |
| 3 — Theme | Dark blue mặc định + Light, design tokens, no-flash |
| 4 — Nâng cao | i18n · PWA · Sentry · SEO · Analytics |

> **Theo ADR-0004: repo khung KHÔNG còn kèm sẵn scaffold Web (Next.js/Supabase).**
> Mọi đường dẫn file trong tài liệu này (`lib/env.ts`, `app/*.tsx`, `styles/theme.css`, `i18n/*`,
> `e2e/*`, `lighthouserc.json`, `.github/workflows/lighthouse-ci.yml`...) là **ví dụ minh hoạ cho
> hồ sơ Web** (C-nào đó trong KHUNG-3 PHẦN C) — bạn tự tạo các file này ở dự án đích khi hồ sơ áp
> dụng là Web, không phải file có sẵn trong repo khung để copy thẳng. Hồ sơ khác thay bằng công cụ
> tương đương của hồ sơ đó.

===============================================================================

> **File này nay là TRANG MỤC LỤC.** Nội dung đã tách thành 4 file theo đúng 4 phần cũ để đọc
> đúng phần cần mà không nạp 888 dòng mỗi phiên. **Tên file này giữ nguyên** nên mọi tham chiếu
> cũ (`docs/framework/quality-supplements.md`) vẫn đúng, và cách đánh số mục cũng giữ nguyên —
> tham chiếu kiểu "Nhóm 2 mục 6" vẫn trỏ đúng chỗ.

| Phần | File | Nội dung |
| --- | --- | --- |
| 1 — Nhóm 1 | `docs/framework/quality-supplements-group1.md` | env validation, migration, PR template, ADR, npm audit, Vercel staging, DoR, sổ tay thuật ngữ `CONTEXT.md`, changelog tách khỏi PROGRESS.md, đồng bộ trạng thái duyệt |
| 2 — Nhóm 2 | `docs/framework/quality-supplements-group2.md` | mobile-first, hiệu năng/Lighthouse, E2E + a11y + coverage, UI/UX, chống lỗi logic, observability, tối ưu mã nguồn |
| 3 — Theme | `docs/framework/quality-supplements-theme.md` | Dark blue mặc định + Light, design tokens, WCAG AA cả hai chế độ |
| 4 — Nâng cao | `docs/framework/quality-supplements-advanced.md` | i18n · PWA · Sentry · SEO · Analytics |

