# FEATURE-MAP — Bản đồ tính năng (bộ khung project-template)

> Nguồn sự thật về "dự án này CÓ NHỮNG GÌ". Cập nhật khi thêm/bỏ tính năng.
> Trạng thái: ✅ ổn · ⚠️ nghi ngờ (có phát hiện audit) · 🚧 dở dang.
>
> **Chủ thể đặc biệt:** repo này LÀ bộ khung, nên "tính năng" = **năng lực khung cung cấp cho dự án
> đích**, không phải route/endpoint của một app. "Điểm vào" = cách người dùng/AI kích hoạt năng lực
> đó. "Dữ liệu đụng tới" = file/thư mục nó đọc-ghi. Lập từ việc đọc file thật (`ls`, `copy-framework.sh`,
> `scripts/*.sh`, `.github/workflows/*`) — không đoán.

## A. Slash command (13) — `.claude/commands/`

| ID | Tính năng / luồng | Điểm vào | Dữ liệu đụng tới | Trạng thái | Test hiện có |
|----|-------------------|----------|------------------|-----------|--------------|
| FT-01 | Tư vấn chọn công nghệ (research-first) | `/consult` | `docs/framework/03-*`, `docs/research/` | ✅ | ⚠️ chỉ kiểm tồn tại + khớp CLAUDE.md (`check-docs-consistency.sh` §3) |
| FT-02 | Khởi tạo dự án mới (greenfield) | `/bootstrap` | `new-project-runbook.md`, dropins | ✅ | như trên; case-study chạy thật Bước 1–5 |
| FT-03 | Chạy tự động (plan → điều phối) | `/auto` | `orchestration-3-tier.md`, `.claude/agents/` | ✅ | như trên |
| FT-04 | Cổng commit/merge + Báo cáo xác thực | `/gate`, `/gate merge` | `package.json` dự án đích | ✅ | như trên |
| FT-05 | Tạo ADR | `/adr` | `docs/adr/`, `0000-template.md` | ✅ | như trên |
| FT-06 | Thiết kế UI/UX | `/ui-ux` | design tokens của dự án đích, `quality-supplements.md` | ✅ | như trên |
| FT-07 | Audit tối ưu mã nguồn | `/audit-optimize` | `docs/ops/code-optimization-audit-prompt.md` | ✅ | như trên |
| FT-08 | Audit toàn diện 12 nhóm | `/audit-full` | `comprehensive-audit-prompt.md`, `COMPREHENSIVE-AUDIT-STATUS.md` | ✅ | như trên |
| FT-09 | Hoàn thiện dự án (5 pha) | `/completion` | `project-completion.md`, `COMPLETION-PLAN.md`, 4 file trạng thái | ✅ | như trên |
| FT-10 | Xử lý sự cố production | `/incident` | `docs/ops/incident-response.md` | ✅ | như trên |
| FT-11 | Phỏng vấn dồn dập làm rõ yêu cầu | `/grill` | `CONTEXT.md` (dự án đích) | ✅ | như trên |
| FT-12 | Chẩn đoán bug khó | `/debug` | `TRAPS.md` | ✅ | như trên |

## B. Subagent 3 tầng (9) — `.claude/agents/`

| ID | Tính năng / luồng | Điểm vào | Dữ liệu đụng tới | Trạng thái | Test hiện có |
|----|-------------------|----------|------------------|-----------|--------------|
| FT-13 | Điều phối Tầng 2 | `coordinator` (Sonnet·low, frontmatter `effort`) | `PLAN.md`, git worktree | ✅ | ❌ không có |
| FT-14 | Worker `route:spec` | `spec-executor` | theo brief | ✅ | ❌ không có |
| FT-15 | Worker `route:complex` | `complex-implementer` | theo brief | ✅ | ❌ không có |
| FT-16 | Worker `route:standard` | `standard-worker` | theo brief | ✅ | ❌ không có |
| FT-17 | Worker `route:mechanical` | `mechanical-worker` | theo brief | ✅ | ❌ không có |
| FT-18 | Hậu kiểm diff | `reviewer` (skill `code-review`) | diff | ✅ | ❌ không có |
| FT-19 | Tra cứu read-only | `lookup` (Haiku) | codebase | ✅ | ❌ không có |
| FT-20 | Xác minh phiên bản nguồn sống | `version-check` (Haiku) | registry/web | ✅ | ❌ không có |
| FT-21 | Bảo trì toàn diện định kỳ (ngoài bảng route) | `maintainer` (Sonnet) qua `/maintain` hoặc `scripts/maintain-run.sh` (CLI subscription cục bộ, mọi nhà cung cấp) | `scripts/maintenance-sweep.sh` → `docs/ops/MAINTENANCE-REPORT.md`, `docs/ops/MAINTENANCE-PLAN.md`, `docs/ops/MAINTENANCE-LOG.md` | ✅ | `test-maintenance-sweep.sh` (negative+positive) + `test-maintain-run.sh` (stub CLI 5 harness) — job `framework-lint` + smoke dự án đích |
| FT-22b | Bảo trì không giám sát (VPS/cron) — đẩy nhánh + tự mở PR (GitHub REST API) để duyệt, không tự merge | `scripts/maintain-cron.sh` | nhánh `maint/auto-<ngày>`, `docs/ops/MAINTENANCE-*.md`, PR trên GitHub | ✅ | `test-maintain-cron.sh` (bare-repo remote thật + curl giả) — job `framework-lint` + smoke dự án đích |

## C. Hook tự động (5) — `.claude/hooks/`

| ID | Tính năng / luồng | Điểm vào | Dữ liệu đụng tới | Trạng thái | Test hiện có |
|----|-------------------|----------|------------------|-----------|--------------|
| FT-21 | Auto-format sau mỗi lần ghi file | `auto-format.sh` (PostToolUse) | file vừa sửa, `dev-task.sh` | ✅ | ⚠️ chỉ kiểm **được copy** (`test-copy-framework.sh`), không kiểm chạy đúng |
| FT-22 | Cổng chặn commit đỏ | `pre-commit-gate.sh` (PreToolUse) | build/lint/test dự án đích | ✅ | như trên |
| FT-23 | Nhắc giai đoạn đầu phiên | `session-guide.sh` (SessionStart) | `PROGRESS.md`, `CLAUDE.md` | ✅ | như trên |
| FT-24 | Nạp trạng thái để "tiếp tục" | `session-resume.sh` (SessionStart) | `PROGRESS.md`, git log | ✅ | như trên |
| FT-25 | Nhắc ngân sách quota | `usage-guard.sh` | `usage-estimate.sh`, `.claude/usage-budget.sh` | ⚠️ (F-014 đã chấp nhận rủi ro) | như trên |

## D. Cổng tự kiểm của CHÍNH repo khung (3 script) — `scripts/`

| ID | Tính năng / luồng | Điểm vào | Dữ liệu đụng tới | Trạng thái | Test hiện có |
|----|-------------------|----------|------------------|-----------|--------------|
| FT-26 | Kiểm tài liệu đồng bộ (link, tên cũ, lệnh ↔ CLAUDE.md) | `scripts/check-docs-consistency.sh` | mọi `*.md` | ✅ | job CI `docs-consistency`; có negative test |
| FT-27 | Kiểm job CI ↔ required checks 2 chiều | `scripts/check-ci-policy.sh` | `ci.yml`, `pr-policy.yml`, `repository-settings.md` | ✅ | job CI `docs-consistency`; có negative test |
| FT-28 | Smoke test bộ copy khung | `scripts/test-copy-framework.sh` | `copy-framework.sh`/`copy-framework.ps1` | ✅ | job CI `copy-framework-smoke` |
| FT-29 | *(đã gỡ — ADR-0004: scaffold Web đã xoá, không còn dropins Lớp 2 để kiểm chạy thật)* | — | — | ➖ | — |

## E. Bộ copy khung (2 biến thể)

| ID | Tính năng / luồng | Điểm vào | Dữ liệu đụng tới | Trạng thái | Test hiện có |
|----|-------------------|----------|------------------|-----------|--------------|
| FT-30 | Copy khung sang dự án đích (POSIX) | `copy-framework.sh` | Lớp 1 copy thẳng · file gốc `copy_if_absent` · Lớp 2 `stage` → `_framework-dropins/` · `FRAMEWORK-VERSION` | ✅ | `test-copy-framework.sh` |
| FT-31 | Bản Windows | `copy-framework.ps1` | như trên | ✅ | `test-copy-framework.sh` (chỉ chạy khi có `pwsh` — máy local bỏ qua, CI ubuntu có) |

## F. Tài liệu khung (Lớp 1) — 13 file `docs/framework/` + 7 file `docs/ops/`

| ID | Tính năng / luồng | Điểm vào | Dữ liệu đụng tới | Trạng thái | Test hiện có |
|----|-------------------|----------|------------------|-----------|--------------|
| FT-32 | Hợp đồng bàn giao chuẩn (điểm vào duy nhất) | `standard-delivery.md` | `docs/specs/`, `docs/goals/` | ✅ | link-check |
| FT-33 | Quy trình 9 giai đoạn + cổng | `01-process-and-standards.md` | — | ✅ | link-check |
| FT-34 | Luật AI đầy đủ + mẫu dự án | `02-ai-rules-and-project-template.md` | `CLAUDE.md`, `AGENTS.md` | ✅ | link-check + §3 khớp lệnh |
| FT-35 | Research-first chọn công nghệ | `03-tech-selection-and-proactive-advice.md` | `docs/research/` | ✅ | link-check |
| FT-36 | Điều phối 3 tầng | `orchestration-3-tier.md` | `.claude/agents/` | ✅ | link-check |
| FT-37 | Bổ sung chất lượng (Nhóm 1+2, theme, i18n/PWA/SEO) | `quality-supplements.md` | dropins | ✅ | link-check |
| FT-38 | Áp khung lên dự án có sẵn | `existing-project-adoption.md` | — | ✅ | link-check |
| FT-39 | Model + tự động hoá + tối ưu token | `models-and-automation.md` | `.claude/settings*.json` | ✅ | link-check |
| FT-40 | Spec-driven tuỳ chọn (OpenSpec) | `spec-driven-openspec.md` | `openspec/` | ✅ | link-check |
| FT-41 | Case-study greenfield chạy thật | `case-study-greenfield-dry-run.md` | — | 🚧 Bước 6–8 chưa kiểm chứng (cần tài khoản thật) | ❌ |
| FT-42 | Vận hành: sự cố, post-mortem, release, repo settings, chuỗi cung ứng | `docs/ops/*` | GitHub settings thật | ⚠️ branch protection chưa bật thật (việc người dùng) | `check-ci-policy.sh` cho phần required checks |

## G. Bản mẫu (12) — `docs/framework/templates/`

| ID | Tính năng / luồng | Điểm vào | Trạng thái | Test hiện có |
|----|-------------------|----------|-----------|--------------|
| FT-43 | 12 bản mẫu: FEATURE-MAP, CONVENTIONS, CODEMAP, COMPLETION-PLAN, FEATURE-SPEC, GOAL, GOLDEN-TEST, TRAPS, THREAT-MODEL, DATA-GOVERNANCE, GOVERNANCE, SUPPORT | copy thủ công / theo pha | ✅ | link-check; ❌ không kiểm "mẫu ↔ tài liệu hướng dẫn còn khớp" |

## H. Dropins Lớp 2 (CI/quy ước GitHub tổng quát — KHÔNG đè dự án đích)

> **Theo ADR-0004:** scaffold Web (Next.js/Supabase — theme, i18n, golden test ví dụ,
> migration RLS mẫu, cấu hình Vitest/Playwright/Lighthouse/ESLint/Prettier/husky) đã xoá khỏi repo
> khung. Lớp 2 giờ chỉ còn CI/quy ước GitHub tổng quát (không đặc thù stack nào).

| ID | Tính năng / luồng | Điểm vào | Dữ liệu đụng tới | Trạng thái | Test hiện có |
|----|-------------------|----------|------------------|-----------|--------------|
| FT-44 | Cổng CI dự án đích (7 workflow tổng quát) | `.github/workflows/*` | ci (3 job tự kiểm khung), secret-scan, dependency-review, pr-policy, release, stale-pr-alert, maintenance (quét bảo trì tuần → 1 issue) | ✅ | `check-ci-policy.sh` + `ci-workflow-policy.test.ts` (dropins — cần Node ở dự án đích để chạy) |
| FT-50 | Script tiện ích dự án đích | `scripts/dev-task.sh`, `scripts/usage-estimate.sh` | tự dò `package.json`/công cụ theo stack | ⚠️ (F-309 fallback grep, chấp nhận rủi ro) | `test-copy-framework.sh` (kiểm copy) |

## Luồng chính (bắt buộc có test đi qua — đối chiếu Definition of Complete)

1. **Copy khung → dự án đích chạy được** (FT-30/31 → FT-44, FT-50): `test-copy-framework.sh`. ✅ có test thật (không còn dropins chạy thật để kiểm — ADR-0004).
2. **Cổng chặn commit/merge đỏ** (FT-04, FT-22, FT-44): `test-hooks-gate.sh` chứng minh hook local chặn thật; ⚠️ dự án đích tự thêm cổng build/test theo stack đã chọn, chưa có test "thử vi phạm phải bị chặn" cho phần đó (không có ở repo khung).
3. **Tài liệu ↔ code khung không lệch** (FT-26, FT-27): ✅ có test 2 chiều + negative test.
4. **Điều phối 3 tầng thực thi được một PLAN.md** (FT-03, FT-13..20): ❌ **không có test/nghiệm thu nào**; chỉ có case-study thủ công.
5. **Vòng hoàn thiện/audit chạy đúng trên dự án thật** (FT-08, FT-09): ⚠️ đã chạy trên chính repo khung nhưng **chưa chạy trên dự án đích thật**.
