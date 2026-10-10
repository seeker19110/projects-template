# FEATURE-MAP — Bản đồ tính năng (bộ khung project-template)

> Nguồn sự thật về "dự án này CÓ NHỮNG GÌ". Cập nhật khi thêm/bỏ tính năng.
> Trạng thái: ✅ ổn · ⚠️ nghi ngờ (có phát hiện audit) · 🚧 dở dang.
>
> **Chủ thể đặc biệt:** repo này LÀ bộ khung, nên "tính năng" = **năng lực khung cung cấp cho dự án
> đích**, không phải route/endpoint của một app. "Điểm vào" = cách người dùng/AI kích hoạt năng lực
> đó. "Dữ liệu đụng tới" = file/thư mục nó đọc-ghi. Lập từ việc đọc file thật (`ls`, `copy-framework.sh`,
> `scripts/*.sh`, `.github/workflows/*`) — không đoán.

## A. Slash command (17; `/maintain` được ghi cùng agent ở mục B) — `.claude/commands/`

| ID | Tính năng / luồng | Điểm vào | Dữ liệu đụng tới | Trạng thái | Test hiện có |
|----|-------------------|----------|------------------|-----------|--------------|
| FT-01 | Tư vấn chọn công nghệ (research-first) | `/consult` | `docs/framework/03-*`, `docs/research/` | ✅ | ✅ có giới hạn: brownfield research-first chạy thật 2026-10-09 với `version-check` nguồn sống (4 gói, `docs/reports/2026-10-09-target-completion.md`); tồn tại + khớp CLAUDE.md qua `check-docs-consistency.sh` §3; chưa có lượt greenfield chọn stack mới |
| FT-02 | Khởi tạo dự án mới (greenfield) | `/bootstrap` | `new-project-runbook.md`, dropins | ✅ | như trên; case-study chạy thật Bước 1–5 |
| FT-03 | Chạy tự động (plan → điều phối) | `/auto` | `orchestration-3-tier.md`, `.claude/agents/` | ✅ | như trên |
| FT-71 | Chạy tới xong, tự quyết theo thứ tự ưu tiên §3d (`/auto` → `/completion` một lượt) | `/auto-complete` | `standard-delivery.md` §3d, `docs/work/<id>/working.md` (dòng quyết định) | ✅ | `tests/test_adaptive_process.py::DecisionOrder` + `check-docs-consistency.sh` §3 |
| FT-04 | Cổng commit/merge + Báo cáo xác thực | `/gate`, `/gate merge` | `package.json` dự án đích | ✅ | như trên |
| FT-05 | Tạo ADR | `/adr` | `docs/adr/`, `0000-template.md` | ✅ | như trên |
| FT-06 | Thiết kế UI/UX | `/ui-ux` | design tokens của dự án đích, `quality-supplements.md` | ✅ | như trên |
| FT-07 | Audit tối ưu mã nguồn | `/audit-optimize` | `docs/ops/code-optimization-audit-prompt.md` | ✅ | như trên |
| FT-08 | Audit toàn diện 12 nhóm | `/audit-full` | `comprehensive-audit-prompt.md`, `COMPREHENSIVE-AUDIT-STATUS.md` | ✅ | như trên |
| FT-09 | Hoàn thiện dự án (5 pha) | `/completion` | `project-completion.md`, `COMPLETION-PLAN.md`, 4 file trạng thái | ✅ | như trên |
| FT-10 | Xử lý sự cố production | `/incident` | `docs/ops/incident-response.md` | ✅ | như trên |
| FT-11 | Phỏng vấn dồn dập làm rõ yêu cầu | `/grill` | `CONTEXT.md` (dự án đích) | ✅ | như trên |
| FT-12 | Chẩn đoán bug khó | `/debug` | `TRAPS.md` | ✅ | như trên |
| FT-53 | Thiết kế hợp đồng dữ liệu/API trước khi code | `/contract` | `docs/specs/` | ✅ | kiểm liên kết với CLAUDE.md; nghiệm thu hợp đồng trong spec |
| FT-54 | Nâng dependency theo yêu cầu cụ thể | `/deps-upgrade` | manifest/lockfile của dự án đích | ✅ | kiểm liên kết với CLAUDE.md; gate theo stack đích |
| FT-55 | Review diff trước PR | `/review` | diff của nhánh đang làm | ✅ | kiểm liên kết với CLAUDE.md; review thủ công |

## B. Subagent 3 tầng (11) — `.claude/agents/`

| ID | Tính năng / luồng | Điểm vào | Dữ liệu đụng tới | Trạng thái | Test hiện có |
|----|-------------------|----------|------------------|-----------|--------------|
| FT-13 | Điều phối Tầng 2 | `coordinator` (Sonnet·low, frontmatter `effort`) | `PLAN.md`, git worktree | ⚠️ chỉ khi phiên chính đóng vai Tầng 2 — subagent Claude Code không có tool `Agent` | nghiệm thu phiên thật 2026-10-09 (`docs/reports/2026-10-09-agent-acceptance.md`); không có test tự động |
| FT-14 | Worker `route:spec` | `spec-executor` | theo brief | ✅ | nghiệm thu phiên thật 2026-10-09 (`docs/reports/2026-10-09-agent-acceptance.md`); không có test tự động |
| FT-15 | Worker `route:complex` | `complex-implementer` | theo brief | ✅ | nghiệm thu phiên thật 2026-10-09 (`docs/reports/2026-10-09-agent-acceptance.md`); không có test tự động |
| FT-16 | Worker `route:standard` | `standard-worker` | theo brief | ✅ | nghiệm thu phiên thật 2026-10-09 (`docs/reports/2026-10-09-agent-acceptance.md`); không có test tự động |
| FT-17 | Worker `route:mechanical` | `mechanical-worker` | theo brief | ✅ | nghiệm thu phiên thật 2026-10-09 (`docs/reports/2026-10-09-agent-acceptance.md`); không có test tự động |
| FT-18 | Hậu kiểm diff | `reviewer` (skill `code-review`) | diff | ✅ | nghiệm thu phiên thật 2026-10-09 (`docs/reports/2026-10-09-agent-acceptance.md`); không có test tự động |
| FT-19 | Tra cứu read-only | `lookup` (Haiku) | codebase | ✅ | nghiệm thu phiên thật 2026-10-09 (`docs/reports/2026-10-09-agent-acceptance.md`); không có test tự động |
| FT-20 | Xác minh phiên bản nguồn sống | `version-check` (Haiku) | registry/web | ✅ | nghiệm thu phiên thật 2026-10-09 (`docs/reports/2026-10-09-agent-acceptance.md`); không có test tự động |
| FT-21 | Bảo trì toàn diện định kỳ (ngoài bảng route) | `maintainer` (Sonnet) qua `/maintain` hoặc `scripts/maintain-run.sh` (CLI subscription cục bộ, mọi nhà cung cấp) | `scripts/maintenance-sweep.sh` → `docs/ops/MAINTENANCE-REPORT.md`, `docs/ops/MAINTENANCE-PLAN.md`, `docs/ops/MAINTENANCE-LOG.md` | ✅ | `test-maintenance-sweep.sh` (negative+positive) + `test-maintain-run.sh` (stub CLI 5 harness) — job `framework-lint` + smoke dự án đích |
| FT-56 | Kiểm thử độc lập trước tích hợp | `tester` | lệnh gate và output test | ✅ | frontmatter/route được kiểm; nghiệm thu test cụ thể theo PR |
| FT-57 | Review vùng nhạy cảm | `security-reviewer` | diff và threat model liên quan | ✅ | frontmatter/route được kiểm; review thủ công |
| FT-22b | Bảo trì không giám sát (VPS/cron) — đẩy nhánh + tự mở PR (GitHub REST API) để duyệt, không tự merge | `scripts/maintain-cron.sh` | nhánh `maint/auto-<ngày>`, `docs/ops/MAINTENANCE-*.md`, PR trên GitHub | ✅ | `test-maintain-cron.sh` (bare-repo remote thật + curl giả) — job `framework-lint` + smoke dự án đích |

## C. Hook tự động (9) — `.claude/hooks/`

| ID | Tính năng / luồng | Điểm vào | Dữ liệu đụng tới | Trạng thái | Test hiện có |
|----|-------------------|----------|------------------|-----------|--------------|
| FT-51 | Auto-format sau mỗi lần ghi file | `auto-format.sh` (PostToolUse) | file vừa sửa, `dev-task.sh` | ✅ | `test-copy-framework.sh` kiểm hook được copy; `tests/test_runtime_safety.py` kiểm formatter nhận filename literal (binary giả), template và best-effort; `scripts/test-hooks-session.sh` mục 12 chạy hook với payload thật (đúng file, no-op khi thiếu, best-effort) |
| FT-52 | Cổng chặn commit đỏ | `pre-commit-gate.sh` (PreToolUse) | build/lint/test dự án đích | ✅ | `scripts/test-hooks-gate.sh` chạy hook thật với gate fixture đỏ/xanh |
| FT-23 | Nhắc giai đoạn đầu phiên | `session-guide.sh` (SessionStart) | `PROGRESS.md`, `CLAUDE.md` | ✅ | `scripts/test-hooks-session.sh` mục 11 (có GĐ / chưa có tiến độ / không phải dự án khung, negative test) + mục 10 (thiếu jq) |
| FT-24 | Nạp trạng thái để "tiếp tục" | `session-resume.sh` (SessionStart) | `docs/work/*/working.md`, `PROGRESS.md`, git log | ✅ | `scripts/test-hooks-session.sh` kiểm active trước PROGRESS, không nạp lịch sử done/nội dung, chọn trạng thái và giới hạn ngữ cảnh |
| FT-72 | Work ID cho mọi công việc: tên thư mục `docs/work/<id>/` là ID, tên file là trạng thái; PR ghi `Work ID:` | `check-docs-consistency.sh` mục 13, `pr-policy.yml` step Work ID | `docs/work/*/`, mô tả PR | ✅ | negative test ở `test-check-scripts.sh` (3 ca) + `test-workflow-guards.sh` mục 6 (8 ca) |
| FT-73 | Tạo hồ sơ công việc một lệnh (Work ID UTC, nhánh/SHA, không ghi đè) | `scripts/new-work.sh` | `docs/work/<id>/working.md`, `WORK.template.md` | ✅ | `scripts/test-new-work.sh` (17 ca, CI Linux + Windows) |
| FT-25 | Nhắc ngân sách quota | `usage-guard.sh` | `usage-estimate.sh`, `.claude/usage-budget.sh` | ✅ (trích dẫn F-014 cũ là nhầm: F-014 = dọn nhánh đã merge, đã đóng) | `test-usage-estimate.sh` kiểm engine; `scripts/test-hooks-session.sh` chạy hook với payload thật (thiếu công cụ → nói ra rồi exit 0; `usage-estimate.sh` lỗi → stderr `[usage-guard] … (exit 4)`, không nuốt); `test-copy-framework.sh` kiểm hook được copy |
| FT-58 | Chặn lệnh Git nguy hiểm | `block-dangerous-git.sh` | lệnh Git sắp chạy | ✅ | `scripts/test-hooks-gate.sh` có ca chặn và không chặn oan |
| FT-59 | Ghi checkpoint trước nén ngữ cảnh | `precompact-checkpoint.sh` | `PROGRESS.md` và trạng thái phiên | ✅ | `scripts/test-hooks-session.sh` |
| FT-60 | Ghi telemetry khi dừng phiên/subagent | `telemetry-record.sh` | transcript và `.ai-telemetry/` | ✅ | `scripts/test-hooks-session.sh` |
| FT-61 | Trí tuệ UI opt-in | `ui-intelligence.sh` | cấu hình provider của dự án đích | ✅ | `scripts/test-hooks-session.sh` kiểm tắt/bật/lỗi provider |

## D. Cổng tự kiểm và engine của CHÍNH repo khung — `scripts/`

| ID | Tính năng / luồng | Điểm vào | Dữ liệu đụng tới | Trạng thái | Test hiện có |
|----|-------------------|----------|------------------|-----------|--------------|
| FT-26 | Kiểm tài liệu đồng bộ (link, tên cũ, lệnh ↔ CLAUDE.md) | `scripts/check-docs-consistency.sh` | mọi `*.md` | ✅ | job CI `docs-consistency`; có negative test |
| FT-27 | Kiểm job CI ↔ required checks 2 chiều | `scripts/check-ci-policy.sh` | `ci.yml`, `pr-policy.yml`, `repository-settings.md` | ✅ | job CI `docs-consistency`; có negative test |
| FT-28 | Smoke test bộ copy khung | `scripts/test-copy-framework.sh` | `copy-framework.sh`/`copy-framework.ps1` | ✅ | job CI `copy-framework-smoke` |
| FT-29 | *(đã gỡ — ADR-0004: scaffold Web đã xoá, không còn dropins Lớp 2 để kiểm chạy thật)* | — | — | ➖ | — |
| FT-63 | Biên dịch spec thành contract test | `scripts/spec-compiler.sh` → `spec-compiler.py` | `docs/specs/*.md` (chỉ State đã chọn trong metadata) | ✅ | `test-next-gen-engines.sh`, `test-engine-characterization.sh`, `tests/test_delivery_handoff_integrity.py` |
| FT-64 | Radar sức khoẻ repo (độ phủ cổng, spec, kích thước file, nợ TODO) | `scripts/arch-health-radar.sh` → `arch-health-radar.py` | `scripts/`, `ci.yml`, `tests/*.py` được test cổng gọi, `docs/specs/` | ✅ | `test-next-gen-engines.sh`, `test-engine-characterization.sh` |
| FT-65 | Chuẩn bị prompt subagent đa harness theo nhãn `route:` (prepare-only, không thực thi/cưỡng chế quyền) + `--check-plan` khoá brief PLAN.md trước khi dispatch (mẫu `PLAN.template.md`) | `scripts/subagent-dispatch.sh` → `subagent-dispatch.py`, `model-capability-tiers.json` | `.claude/agents/*.md` | ✅ (4 harness: claude, hermes, codex, generic) | `test-telemetry-and-dispatch.sh`, `test-engine-characterization.sh` |
| FT-66 | Telemetry thời gian/LOC/chi phí tác vụ AI | `scripts/telemetry-log.sh` → `telemetry-log.py`, `model-rates.json` | `.ai-telemetry/` | ✅ | `test-telemetry-and-dispatch.sh`, `tests/test_telemetry_integrity.py` |
| FT-67 | Kiểm PROGRESS.md không lỗi thời so với git thật (PF-1..4) | `scripts/check-progress-freshness.sh` | `PROGRESS.md`, git remote | ✅ | job CI `progress-freshness` (PR + main); `test-check-scripts.sh` có negative test |
| FT-68 | Trần độ phức tạp vòng cho mã Python và shell | `scripts/check-python-complexity.sh`, `scripts/check-shell-complexity.sh` | mọi engine/script trong `scripts/` | ✅ | `test-check-python-complexity.sh`, `test-check-shell-complexity.sh` (có ca đỏ) |
| FT-69 | Độ phủ dòng Python thật (sàn 95%) và probe mã thoát | `scripts/test-py-coverage.sh` | engine Python, `tests/*.py` | ✅ (đo 96% ngày 2026-10-06) | `test-py-coverage-exit.sh` |
| FT-70 | Khoá hành vi 3 engine và kiểm chính các cổng tài liệu/CI | `scripts/test-engine-characterization.sh` (thân ở `tests/engine_characterization/`), `scripts/test-check-scripts.sh` | `check-*.sh`, radar, compiler, dispatcher | ✅ | tự chạy trong job CI `framework-lint` |

## E. Bộ copy khung (2 biến thể)

| ID | Tính năng / luồng | Điểm vào | Dữ liệu đụng tới | Trạng thái | Test hiện có |
|----|-------------------|----------|------------------|-----------|--------------|
| FT-30 | Copy khung sang dự án đích (POSIX) | `copy-framework.sh` | Lớp 1 copy thẳng · file gốc `copy_if_absent` · Lớp 2 `stage` → `_framework-dropins/` (CODEOWNERS đổi owner thành `@OWNER-CHANGE-ME`) · `enable_hooks_path` đặt `core.hooksPath=scripts/githooks` ở đích có `.git` (cờ `--no-hooks` bỏ) · `FRAMEWORK-VERSION` | ✅ | `test-copy-framework.sh` |
| FT-31 | Bản Windows | `copy-framework.ps1` | như trên (cùng `copy-framework.manifest`; chạy lại trên đích chưa sửa không tạo `.framework-new`); exec-bit ghi vào index git của đích (`update-index --add --chmod=+x`, đích không có `.git` → cảnh báo); `FRAMEWORK-VERSION` đủ `version:` + `manifest:` như bản `.sh`; `Enable-HooksPath` (`-NoHooks`) và CODEOWNERS placeholder như bản `.sh`. **Chưa có `--upgrade`** (DEBT trong `.ps1` giữ nguyên — dùng `bash copy-framework.sh <đích> --upgrade`) | ✅ | `test-copy-framework.sh` (chạy khi có `pwsh`; CI yêu cầu phải có và lượt nghiệm thu local này đã chạy) |

## F. Tài liệu khung (Lớp 1) — `docs/framework/` và `docs/ops/`

| ID | Tính năng / luồng | Điểm vào | Dữ liệu đụng tới | Trạng thái | Test hiện có |
|----|-------------------|----------|------------------|-----------|--------------|
| FT-32 | Hợp đồng bàn giao chuẩn (điểm vào duy nhất) | `standard-delivery.md` | `docs/specs/`, `docs/goals/` | ✅ | link-check |
| FT-33 | Quy trình 9 giai đoạn + cổng | `01-process-and-standards.md` | — | ✅ | link-check |
| FT-34 | Quy trình sinh PROJECT.md/CLAUDE.md (luật AI/mẫu: con trỏ tới `CLAUDE.md`, `PROJECT.md`) | `02-ai-rules-and-project-template.md` | `CLAUDE.md`, `AGENTS.md` | ✅ | link-check + §3 khớp lệnh |
| FT-35 | Research-first chọn công nghệ | `03-tech-selection-and-proactive-advice.md` | `docs/research/` | ✅ | link-check |
| FT-36 | Điều phối 3 tầng | `orchestration-3-tier.md` | `.claude/agents/` | ✅ | link-check |
| FT-37 | Bổ sung chất lượng (Nhóm 1+2, theme, i18n/PWA/SEO) | `quality-supplements.md` | dropins | ✅ | link-check |
| FT-38 | Áp khung lên dự án có sẵn | `existing-project-adoption.md` | — | ✅ cho copy/gate Node và Python tối thiểu; các stack khác chưa nghiệm thu | `test-adoption-smoke.sh` (đỏ/xanh Node/Python, clone sạch, CI offline); `tests/test_lean_adoption.py` (upgrade giữ config/ghi chú, evidence cũ/FAIL bị từ chối); protocol `docs/reports/2026-10-07-lean-delivery-benchmark.md` (metric model unknown); báo cáo `docs/reports/2026-10-05-adoption-smoke.md` |
| FT-39 | Model + tự động hoá + tối ưu token | `models-and-automation.md` | `.claude/settings*.json` | ✅ | link-check |
| FT-40 | Spec-driven tuỳ chọn (OpenSpec) | `spec-driven-openspec.md` | `openspec/` | ✅ | link-check |
| FT-41 | Case-study greenfield chạy thật | `case-study-greenfield-dry-run.md` | — | 🚧 Bước 6/11 (GitHub) ✅ chạy thật 2026-10-09; Bước 7–8 (Supabase/Vercel) chưa kiểm chứng (ngoài scope, cần tài khoản) | ⚠️ repo thật `case-study-ft41` + `test_dependabot_version_prs_leave_wip_room_for_humans` |
| FT-42 | Vận hành: sự cố, post-mortem, release, repo settings, chuỗi cung ứng | `docs/ops/*` | GitHub settings thật | ✅ ruleset active, `strict=true` qua API 2026-10-05 | `protection-guard` kiểm live; W-04 bổ sung kiểm tham số `strict` và negative test; `scripts/test-workflow-guards.sh` chạy thân step `protection-guard`/`Detect project manifest` với API/manifest giả lập |

## G. Bản mẫu (13 Markdown + 1 CI) — `docs/framework/templates/`

| ID | Tính năng / luồng | Điểm vào | Trạng thái | Test hiện có |
|----|-------------------|----------|-----------|--------------|
| FT-43 | 13 bản mẫu Markdown: AI-EVAL, FEATURE-MAP, CONVENTIONS, CODEMAP, COMPLETION-PLAN, FEATURE-SPEC, GOAL, GOLDEN-TEST, TRAPS, THREAT-MODEL, DATA-GOVERNANCE, GOVERNANCE, SUPPORT | copy thủ công / theo pha | ✅ | link-check; `check-docs-consistency.sh` mục 12: mỗi mẫu được ≥ 1 tài liệu hướng dẫn trỏ tới (negative test ở `test-check-scripts.sh`) |

## H. Dropins Lớp 2 (CI/quy ước GitHub tổng quát — KHÔNG đè dự án đích)

> **Theo ADR-0004:** scaffold Web (Next.js/Supabase — theme, i18n, golden test ví dụ,
> migration RLS mẫu, cấu hình Vitest/Playwright/Lighthouse/ESLint/Prettier/husky) đã xoá khỏi repo
> khung. Lớp 2 giờ chỉ còn CI/quy ước GitHub tổng quát (không đặc thù stack nào).

| ID | Tính năng / luồng | Điểm vào | Dữ liệu đụng tới | Trạng thái | Test hiện có |
|----|-------------------|----------|------------------|-----------|--------------|
| FT-44 | Cổng CI dự án đích (9 workflow nguồn; `ci.yml` phát bản riêng) | `.github/workflows/*`, `docs/framework/templates/ci-target.yml` | ci, secret-scan, dependency-review, pr-policy, release, stale-pr-alert, maintenance, codeql, scorecard | ✅ cho template Node/Python offline; hosted CI của repo đích chưa nghiệm thu | `check-ci-policy.sh`, `test-adoption-smoke.sh` (gồm bước "Spec contracts" của `ci.yml` đích chạy thật 3 ca: chưa có spec/trỏ file không có/file có thật — đối chiếu SDD 2026-10-10); khối required checks phát cho đích được `test-copy-framework.sh` đối chiếu với workflow phát kèm; vitest drop-in đã chạy tay trên fixture (xem báo cáo chu kỳ 2026-10-09) |
| FT-50 | Script tiện ích dự án đích | `scripts/dev-task.sh`, `scripts/usage-estimate.sh` | tự dò `package.json`/công cụ theo stack | ✅ (F-309 đã sửa 2026-10-09: không jq → đọc JSON bằng `node`, hết dương tính giả từ khoá cùng tên ngoài `scripts`) | `test-copy-framework.sh`, `test-dev-task.sh` + `test-dev-task-evidence.sh` (LD-03/LD-04; helper chung `scripts/_dev-task-test-lib.sh`) (resolver/doctor/gate fixture; một số binary giả; ca PATH không jq cho F-309), `test-usage-estimate.sh`, `tests/test_runtime_safety.py` (Python venv path có khoảng trắng/ký tự shell); Node/Python runtime thật trong adoption smoke |
| FT-62 | Cầu nối delivery opt-in | `scripts/delivery-handoff.py` | spec/goal và contract từ consumer đã pin | ✅ | `tests/test_delivery_handoff_integrity.py`; CI Linux/Windows |

## Luồng chính (bắt buộc có test đi qua — đối chiếu Definition of Complete)

1. **Copy khung → dự án đích chạy được** (FT-30/31 → FT-44, FT-50): `test-copy-framework.sh` và `test-adoption-smoke.sh` kiểm Node/Python thật, CI drop-in offline và bản PowerShell; hosted CI của một repo đích vẫn chưa có bằng chứng.
2. **Cổng chặn commit/merge đỏ** (FT-04, FT-52, FT-44): `test-hooks-gate.sh` chứng minh hook local chặn thật; smoke Node/Python bắt phép cộng sai ở `test` rồi xanh sau sửa. Stack khác cần bằng chứng riêng.
3. **Tài liệu ↔ code khung không lệch** (FT-26, FT-27): ✅ có test 2 chiều + negative test.
4. **Điều phối 3 tầng thực thi được một PLAN.md** (FT-03, FT-13..20): `test-telemetry-and-dispatch.sh` kiểm CLI dispatcher, payload và định tuyến; ✅ có giới hạn: PLAN.md 2 đơn vị đã chạy đầu-cuối bằng agent thật (worker ∥ → reviewer/tester → merge) ngày 2026-10-09 với **phiên chính đóng vai Tầng 2**; `coordinator` chạy như subagent KHÔNG dispatch được trong Claude Code (không có tool `Agent` cho subagent) — xem `docs/reports/2026-10-09-agent-acceptance.md`. Vẫn là nghiệm thu thủ công, không phải test tự động.
5. **Vòng hoàn thiện/audit chạy đúng trên dự án thật** (FT-08, FT-09): ✅ có giới hạn — đã chạy trọn Pha 0→4 trên một dự án đích Node/vitest thật (fixture do phiên chính viết, không phải sản phẩm production; `docs/reports/2026-10-09-target-completion.md`); chưa chạy hosted CI trên repo đích thật.
