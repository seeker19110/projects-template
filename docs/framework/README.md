# docs/framework — chỉ mục tài liệu khung

> Tên file dùng tiếng Anh (chuẩn hóa); nội dung tiếng Việt. Trong văn bản, các tên gọi
> **KHUNG-1 / KHUNG-2 / KHUNG-3** vẫn được dùng làm tên khái niệm — bảng dưới là bản đồ tra cứu.

| File | Tên khái niệm (trong văn bản) | Nội dung | Đọc khi nào |
|------|-------------------------------|----------|-------------|
| `standard-delivery.md` | **STANDARD** | **Nguồn vào duy nhất:** artifact, Research/Spec gate, AI Goal Loop, DoR/DoD/Complete | Đọc đầu tiên, mọi dự án |
| `quickstart.md` | QUICKSTART | Định hướng Greenfield/Brownfield trong 10 phút + adoption preflight; không thay Standard Delivery | Lần đầu áp khung |
| `01-process-and-standards.md` | **KHUNG-1** | Quy trình 9 giai đoạn + cổng + tiêu chuẩn từng giai đoạn | Bắt đầu dự án; trước khi chuyển giai đoạn |
| `02-ai-rules-and-project-template.md` | **KHUNG-2** | Luật AI (cổng commit/merge, chống ảo giác, báo cáo xác thực) + mẫu `PROJECT.md` | Sinh PROJECT.md/CLAUDE.md; ôn luật |
| `03-tech-selection-and-proactive-advice.md` | **KHUNG-3** | Research-first: chọn công nghệ/phiên bản + đề xuất chủ động 19 khía cạnh + hồ sơ C1–C10 | GĐ 0–2; thêm/đổi công nghệ |
| `new-project-runbook.md` | KHOI-TAO | **Trang mục lục + Phần 0/A/B/C**: cấu trúc repo, trình tự triển khai, quy tắc bất biến, cổng "sẵn sàng phát triển" | Greenfield (`/bootstrap`) |
| `new-project-runbook-part-d-guardrails.md` | KHOI-TAO · Phần D | Cấu hình chi tiết hàng rào — 14 bước sao chép được (Prettier/ESLint/TS strict/Husky/commitlint/Vitest/CI/branch protection/Dependabot) | Khi dựng nền thật |
| `new-project-runbook-part-e-checklist.md` | KHOI-TAO · Phần E | Checklist triển khai trên DỰ ÁN THẬT (secrets, Supabase/Vercel, analytics, release) | Khi đã có dự án thật |
| `adopt-from-outside.md` | HOC-NGOAI | Học từ repo/khung/skill BÊN NGOÀI: ba cột (sâu hơn / nông hơn / chưa có), cổng "phải ứng với sự cố thật", luật **grep cổng đang chạy đừng đọc văn xuôi**, kiểm mâu thuẫn luật | Được đưa một nguồn ngoài và bảo "lấy cái hay về" |
| `ui-ux-intelligence-provider.md` | UI-INTELLIGENCE | Contract provider-neutral cho design intelligence bên ngoài: precedence, query nhỏ nhất, verify/fallback, adapter `ui-ux-pro-max`; provider chỉ là recommendation | Khi `/ui-ux` cần nguồn gợi ý bên ngoài hoặc dự án đã có provider UI/UX |\n| `existing-project-adoption.md` | AP-DUNG | Áp khung lên dự án CÓ SẴN: tự dò stack, hàng rào tăng dần, không big-bang (Bước 0→4) | Brownfield (`/consult`) |
| `project-completion.md` | HOAN-THIEN | Hoàn thiện dự án: bản đồ tính năng + kế hoạch chi tiết + vòng hội tụ + Definition of Complete | Muốn hết lỗi đã biết (`/completion`) |
| `quality-supplements.md` | BO-SUNG | **Trang mục lục** trỏ tới 4 phần dưới đây | Tra checklist chi tiết |
| `quality-supplements-group1.md` | BO-SUNG · Nhóm 1 | env validation, migration, PR template, ADR, npm audit, Vercel staging, DoR, sổ tay thuật ngữ `CONTEXT.md` | Tra Nhóm 1 mục N |
| `quality-supplements-group2.md` | BO-SUNG · Nhóm 2 | mobile-first, hiệu năng/Lighthouse, E2E + a11y + coverage, UI/UX, chống lỗi logic, observability, tối ưu mã nguồn | Tra Nhóm 2 mục N |
| `quality-supplements-theme.md` | BO-SUNG · Theme | Dark blue mặc định + Light, design tokens, WCAG AA cả hai chế độ | Khi làm UI/theme |
| `quality-supplements-advanced.md` | BO-SUNG · Nâng cao | i18n · PWA · Sentry · SEO · Analytics | Khi cần năng lực nâng cao |
| `models-and-automation.md` | MODEL | Chọn model (Sonnet/Opus/Fable) + effort + kỷ luật vận hành tối ưu token + bản đồ chế độ chạy tự động | Bắt đầu/đổi quy mô; cân chi phí |
| `spec-driven-openspec.md` | SPEC-DRIVEN | (Tùy chọn) Lớp spec cấp từng thay đổi với OpenSpec: proposal→spec→design→tasks trong Git, bản đồ khái niệm ↔ khung, khi nào dùng/không | Thay đổi vừa/lớn GĐ 4+; nhiều phiên/nhiều người |
| `case-study-greenfield-dry-run.md` | — | Chạy thật runbook trên `create-next-app` thật: 3 lỗi tìm được + đã vá, bằng chứng chạy đầu-cuối | Kiểm chứng khung / trước khi tin runbook |
| `templates/` | — | Bản mẫu sạch: `GOAL.template.md`, `FEATURE-SPEC.template.md`, `THREAT-MODEL.template.md`, `DATA-GOVERNANCE.template.md`, `GOVERNANCE.template.md`, `SUPPORT.template.md`, `FEATURE-MAP.template.md`, `CONVENTIONS.template.md`, `COMPLETION-PLAN.template.md`, `AI-EVAL.template.md`, `GOLDEN-TEST.template.md`, `TRAPS.template.md`, `CODEMAP.template.md`, `PROGRESS.template.md` | Pha 1/3 của `/completion` |
| `FRAMEWORK-VERSION` | — | (Chỉ có ở DỰ ÁN ĐÍCH — sinh tự động bởi `copy-framework.sh`/`.ps1`) `version:` (file `VERSION` của khung, SemVer) + commit + ngày + **manifest hash từng file Lớp 1**; nâng bản: `bash copy-framework.sh <đích> --upgrade` (giữ chỉnh sửa cục bộ: hash khớp manifest → cập nhật, đã sửa → merge 3 chiều hoặc để `.framework-new`); `maintenance-sweep.sh` 🟡 khi quá 90 ngày | Muốn biết dự án đích dùng khung bản nào / nâng bản |

## Tên cũ (tiếng Việt) → tên mới — cho dự án đã copy khung bản trước

| Tên cũ | Tên mới |
|--------|---------|
| `KHUNG-1-quy-trinh-va-tieu-chuan.md` | `01-process-and-standards.md` |
| `KHUNG-2-luat-AI-va-mau-du-an.md` | `02-ai-rules-and-project-template.md` |
| `KHUNG-3-chon-cong-nghe-va-de-xuat-chu-dong.md` | `03-tech-selection-and-proactive-advice.md` |
| `KHOI-TAO-du-an-moi.md` | `new-project-runbook.md` |
| `AP-DUNG-vao-du-an-co-san.md` | `existing-project-adoption.md` |
| `BO-SUNG-chat-luong.md` | `quality-supplements.md` |
| `MODEL-va-TU-DONG.md` | `models-and-automation.md` |
| `docs/ops/audit-toan-dien-prompt.md` | `docs/ops/comprehensive-audit-prompt.md` |
| `docs/ops/audit-toi-uu-prompt.md` | `docs/ops/code-optimization-audit-prompt.md` |
| `docs/ops/AUDIT-TOAN-DIEN-TRANG-THAI.md` | `docs/ops/COMPREHENSIVE-AUDIT-STATUS.md` |
| `docs/adr/0001-chon-stack.md` | `docs/adr/0001-stack-selection.md` |

## Slash command cũ → mới

| Cũ | Mới | | Cũ | Mới |
|----|-----|-|----|-----|
| `/tu-van` | `/consult` | | `/audit-toan-dien` | `/audit-full` |
| `/cong` | `/gate` | | `/audit-toi-uu` | `/audit-optimize` |
| `/khoi-tao` | `/bootstrap` | | `/su-co` | `/incident` |
| `/tu-dong` | `/auto` | | *(mới)* | `/completion` |

Subagent: `tra-cuu` → `lookup` · `kiem-tra-phien-ban` → `version-check` · `thuc-thi` → `standard-worker`.
Điều phối 3 tầng: `coordinator` (Tầng 2) · workers `complex-implementer`/`spec-executor`/`standard-worker`/`mechanical-worker` (Tầng 3) · `reviewer` (hậu kiểm). Xem `orchestration-3-tier.md`.
