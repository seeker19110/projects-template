# PROGRESS.md — Trạng thái dự án

> Tóm tắt toàn dự án; cập nhật sau mỗi mốc. Goal nhiều PR theo dõi chi tiết ở `docs/goals/*`.
> Không sao chép iteration log vào đây. (Repo này LÀ bộ khung — file này là nhật ký của chính khung,
> không copy sang dự án đích; dự án đích nhận bản sạch từ `PROGRESS.template.md`.)

## Giai đoạn hiện tại

- Giai đoạn: GĐ 8. **Mốc (2026-09-23, PR #166 — Đợt 1 nâng cấp khung, nhánh `claude/eager-darwin-k1f1y6`):
  audit toàn diện repo khung + kế hoạch 7 đợt** (`docs/reports/2026-09-23-de-xuat-nang-cap-khung-toan-dien.md`,
  người dùng duyệt qua chat). Đợt 1 (PR #166, đã merge — SHA `a7ac853`): copy-framework không đè nhật ký `docs/ops` của dự án đích, telemetry
  số thật + bảng giá theo nguồn sống, sweep đúng chiều Go/pip + vá injection tên file, ID model hiện hành + cổng 5b.
  Đợt 2 (PR kế tiếp, cùng nhánh): hook chặn commit trên main / bí mật / file lớn staged, khuôn 5 push xoá main,
  `session-resume.sh` chỉ nạp 4 mục (trần 8 KB), tách lịch sử PROGRESS.md sang `docs/changelog/0001-…`, PF-4,
  pr-policy: trần WIP 3 + tiêu đề ≤ 72 + nhắc TRAPS cho `fix:`. Còn lại: Đợt 3–7 theo báo cáo §3.
- Giai đoạn trước đó: GĐ 8. Mốc 2026-09-23 PR #165 (nâng cấp `/ui-ux`) và toàn bộ lịch sử cũ hơn: xem
  `docs/changelog/0001-2026-09-23-lich-su-giai-doan-den-2026-09-23.md` (luật: PROGRESS.md chỉ giữ một khối hiện tại).
- Default-branch SHA đã đối chiếu: `a7ac853` (`origin/main`, PR #166)
- Nhánh đang làm: `claude/eager-darwin-k1f1y6` (Đợt 1–7 nâng cấp khung, mỗi đợt một PR, restart nhánh từ `main` sau mỗi merge)
- Ngày cập nhật: 2026-09-23

## Goal đang active

| Goal | Outcome | State | Current gap | Next slice | Link |
| --- | --- | --- | --- | --- | --- |
| Gói A+B+C: TRAPS + CODEMAP + cổng CI | 4 PR merge; TRAPS/CODEMAP thật + cổng `check-ci-policy.sh` chạy trong CI | ✅ ĐÓNG (2026-09-12, PR #62) | — | Không còn goal mở | `docs/specs/2026-09-12-traps-codemap-ci-policy.md` |
| Siết hàng rào (audit 2026-09-12) | 0 phát hiện Cao mở; luật có cơ chế thi hành | ✅ ĐÓNG (2026-09-13) | — | W-308 xong: người dùng đã tự xoá toàn bộ nhánh đã merge qua GitHub UI (`list_branches` xác nhận chỉ còn `main`) | `docs/ops/COMPLETION-PLAN.md` |
| Golden test + kỷ luật TDD | 3 PR merge; TDD lên cấp CLAUDE.md/gate, golden có luật cập nhật | ✅ ĐÓNG (2026-09-12, PR #62) | — | Không còn goal mở | `docs/specs/2026-09-12-golden-tests-and-tdd.md` |
| Hoàn thiện khung theo COMPLETION-PLAN | 0 phát hiện Cao mở; Vừa/Thấp có kết cục ghi nhận; đạt Definition of Complete | ✅ ĐÓNG (2026-09-01) | — | Không còn goal mở | `docs/ops/COMPLETION-PLAN.md` |

## Đã xong (tóm tắt)

- Dựng trọn bộ khung: quy trình 9 giai đoạn + cổng, luật AI (CLAUDE.md/AGENTS.md), research-first,
  slash commands (`/consult` `/gate` `/bootstrap` `/auto` `/audit-full` `/audit-optimize` `/incident`
  `/completion` `/grill` `/debug` `/ui-ux` `/adr`), điều phối 3 tầng + opusplan, `copy-framework.sh`/
  `.ps1` + smoke test, OpenSpec (tùy chọn).
- **(2026-09-12, ADR-0004) Gỡ hẳn scaffold Web mặc định** — repo khung giờ chỉ còn Lớp 1 (phương
  pháp) + Lớp 2 (CI/quy ước GitHub tổng quát). Xem "Quyết định quan trọng" bên dưới.
- Hàng rào tự kiểm cho chính khung: CI `framework-lint` / `docs-consistency`
  (`scripts/check-docs-consistency.sh`) / `copy-framework-smoke`; case-study greenfield (lịch sử,
  chạy khi repo còn scaffold — xem `case-study-greenfield-dry-run.md`).
- Tái cấu trúc tên file sang tiếng Anh (nội dung tiếng Việt), bản đồ tên cũ→mới ở `docs/framework/README.md`.
- **(2026-09-12) PR #68 — tổng quát hoá harness cho mọi AI coding model/provider**: AGENTS.md
  thành entrypoint chung có hàng rào an toàn thủ công cho agent không có hook Claude Code;
  `.mcp.json.example` + `.claude/settings.local.json.example`; bridge file GEMINI.md/.clinerules/
  .windsurfrules/Cursor/Copilot trỏ về AGENTS.md; thêm subagent `tester` + `security-reviewer`.
- **(2026-09-12) PR #69 — cổng chống PROGRESS.md lỗi thời + chia đơn vị PR/trần effort medium/
  auto-merge**: `scripts/check-progress-freshness.sh` + job CI `progress-freshness`; quy trình mới
  sau bước duyệt kế hoạch cho việc đủ lớn cần điều phối 3 tầng — xem `TRAPS.md` mục 8.
- PR đã merge gần nhất: **#114** (ADR-0005 TDD), **#113** (CP-5 sổ job skip), **#112** (sửa hook chặn oan + TRAPS 18/14), **#111** (đóng, thay bằng #112), **#110** (sync PROGRESS), **#109** (ba luật từ đợt đối chiếu Claude-Agents), **#86** (nhãn C1), **#108** (`.gitignore` `__pycache__`), **#106** (agent bảo trì toàn diện — `maintainer`/`/maintain`/`maintenance-sweep`/`maintain-run`/`maintain-cron`), **#105→#104** (PROGRESS sync + fix telemetry/smoke, xem mục "Giai đoạn hiện tại" ở trên), **#69** (freshness gate + PR-splitting/effort/auto-merge), **#68** (tổng quát hoá harness), **#67** (ADR-0004 gỡ scaffold Web), **#66**
  (đóng Nhóm 11 audit), **#62** (TRAPS.md + CODEMAP.md + `check-ci-policy.sh` + golden test/TDD —
  2 spec `docs/specs/2026-09-12-*.md`, 7 PR gộp thành 1, rút từ lượt quét 15 repo dẫn xuất/lân cận),
  **#61** (verify-dropins ERESOLVE), **#52** (hoàn thiện khung theo COMPLETION-PLAN, 4 đợt/22 việc
  W-101→W-406, Pha 4 re-audit hội tụ + nghiệm thu Definition of Complete PASS), **#46** (parallel
  subagent workflow), **#45** (governance & supply-chain), **#44** (hợp nhất chuẩn —
  standard-delivery). Mốc cũ hơn (#19–#32…): xem lịch sử Git của file này + CHANGELOG.

## Đang làm / chờ

- **Không có việc dở.** PR #130 (ADR-0007 — bỏ opusplan mặc định) đã merge — xem mục "Giai đoạn
  hiện tại" ở trên.
- PR #106 (agent bảo trì toàn diện) đã merge — xem mục "Giai đoạn hiện tại"
  ở trên. Dùng thử: `/maintain` (Claude Code), `scripts/maintain-run.sh` (CLI khác), hoặc chờ
  workflow tuần `maintenance.yml` mở issue báo cáo.
- PR #93 (hậu kiểm audit 2026-09-13) đã merge: nối `test-next-gen-engines.sh`
  + `test-telemetry-and-dispatch.sh` vào job `framework-lint`, thêm mục 6 cho
  `check-docs-consistency.sh` (script ↔ `CODEMAP.md`) kèm negative-test hai chiều, tách bảng giá ra
  `scripts/model-rates.json`, đổi default harness về `claude`/`anthropic`. Xem `TRAPS.md` mục 11–12.
- Audit toàn diện 2026-09-12 (12/12 nhóm, G-001..G-004) đã đóng hết qua PR
  #71→#75. Nhánh remote đã dọn sạch (2026-09-13). Người dùng đã import `.github/rulesets/main.json`
  trên GitHub — `protection-guard` xanh thật, đã thêm vào `needs:` của `gate` (nhánh hiện tại), xoá
  khỏi `CP4_BOOTSTRAP_EXEMPT`. Vòng "mượn cơ chế branch-protection từ Claude-Agents" đã khép kín.

## Tiếp theo

- **Ngay lập tức:** không có việc dở. A-01→A-04 đã đóng; độ phủ cổng CI đạt **100%** (18/18
  script) và điểm radar **100/100** — cả hai đều có đối chứng động chứng minh là phép đo thật,
  không phải hằng số in ra.
- Cả 4 phát hiện Trung của audit toàn diện 2026-09-12 đã đóng: G-001 (PR #72), G-002 (dọn trong PR
  #73), G-003 + G-004 (PR #75).
- Có thể làm khi được yêu cầu: bắt đầu dự án đích mới bằng khung này (`/consult` hoặc `/auto`), tiếp
  tục quét thêm repo dẫn xuất khác (gói D–I của lượt quét 2026-09-12: script `check-*` của `xboss`,
  hook `block-dangerous-git.sh`, gitleaks pre-commit, gate-agent `sc-gate-*`, `eval-record.yml`),
  hoặc audit định kỳ khác (`/audit-full`).

## Quyết định quan trọng

- **(ĐẢO NGƯỢC MỘT PHẦN 2026-09-15, ADR-0007) `opusplan` không còn là mặc định** — CLI đã ngừng hỗ
  trợ `/model opusplan`. Chính sách cũ "opusplan là điểm ngọt" (ADR-0006 mục 2) thay bằng hai pha
  làm thủ công: `/model` sang model cao cấp nhất sẵn có để lập kế hoạch, tự `/model claude-sonnet-5`
  quay lại thực thi. Tối ưu token vẫn bằng CHIA VIỆC (subagent, cô lập ngữ cảnh) — không đổi. Chi
  tiết: `docs/framework/models-and-automation.md`, `docs/adr/0007-bo-opusplan-mac-dinh.md`.
- **(ĐẢO NGƯỢC 2026-09-12, ADR-0004) KHÔNG còn scaffold Web mặc định.** Quyết định cũ "giữ scaffold
  Web (Next.js+Supabase) làm hồ sơ mặc định" đã bị đảo ngược theo yêu cầu người dùng — gỡ hẳn khỏi
  repo khung để nhất quán với nguyên tắc "hỗ trợ mọi loại dự án, research-first" (không sửa ADR-0001
  — ghi ADR mới). Repo khung giờ chỉ còn Lớp 1 (phương pháp) + Lớp 2 (CI/quy ước GitHub tổng quát,
  không đặc thù stack).
- Copy-framework KHÔNG đè file có sẵn ở dự án đích (`copy_if_absent`); Lớp 2 (CI/GitHub) vào `_framework-dropins/`.
- ADR: `docs/adr/` (vd `0001-stack-selection.md`, `0004-remove-default-web-scaffold.md`).

## Rủi ro, blocker và nợ kỹ thuật

| Mục | Severity | Owner | Trigger/next action | Link |
| --- | --- | --- | --- | --- |
| ~~B-01 Feature gate né được qua tiêu đề COMMIT~~ | — | — | ✅ ĐÃ SỬA — `pr-policy.yml` nay soi CẢ tiêu đề PR LẪN tiêu đề từng commit; mọi commit phải conventional. Vẫn NÊN bật thêm Settings → 'Default to PR title for squash merge commits' (rẻ hơn, chặn ở tầng nền tảng). Cũ: `pr-policy.yml` kiểm `pr.title`, nhưng squash merge dùng tiêu đề **COMMIT** khi PR chỉ có **một** commit → `main` nhận được commit `feat:` chưa từng qua Feature gate. Xảy ra THẬT ở PR #99 (`76fc65e feat(test): ...` dù tiêu đề PR đã đổi thành `test:`). Sửa: bật "Default to PR title" cho squash trong Settings, HOẶC thêm cổng đối chiếu tiền tố tiêu đề commit ↔ tiêu đề PR | audit 2026-09-13 (lượt 2) |
| ~~B-02 `CLAUDE.md` ↔ `AGENTS.md` không có cổng đối chiếu~~ | — | — | ✅ ĐÃ SỬA — `AGENTS.md` kê đủ 4 engine + mục 7 mới trong `check-docs-consistency.sh` đối chiếu danh sách engine hai file, có negative-test hai chiều. Cũ: `CLAUDE.md` §1 khai 4 engine; `AGENTS.md` chỉ kê 2 (`subagent-dispatch`, `telemetry-log`) — thiếu `spec-compiler` và `arch-health-radar`. `CLAUDE.md` §1 bắt "sửa luật ở đây thì soát lại AGENTS.md" nhưng **không cổng máy nào kiểm**, nên lệch âm thầm | audit 2026-09-13 (lượt 2) |
| ~~B-03 CI chạy shellcheck mức `error`, luật ghi "0 cảnh báo"~~ | — | — | ✅ ĐÃ SỬA — CI nay chạy `shellcheck --severity=warning` đúng luật §5; sửa 1 ca SC2164 và khai directive KÈM LÝ DO cho 3 ca SC1090 + file `.example`. Cũ: `CLAUDE.md` §5 ghi "Lint 0 cảnh báo" nhưng `ci.yml` dùng `--severity=error`. Mức `warning` hiện có 6 phát hiện (4×SC1090 sourcing động — chấp nhận được; 2×SC2164 `cd` không `|| exit` ở `test-copy-framework.sh:10` và một chỗ nữa). Sửa: nâng CI lên `--severity=warning` + sửa 2 ca SC2164, HOẶC sửa luật §5 cho khớp thực tế | audit 2026-09-13 (lượt 2) |
| ~~A-01 `spec-compiler.py` sinh assertion RỖNG~~ | — | — | ✅ ĐÃ SỬA — sinh 3 hợp đồng kiểm được thật (C-1 State, C-2 mã yêu cầu, C-3 đường dẫn touchpoints tồn tại), có negative-test hai chiều. Cũ: 82/82 test sinh ra đều là `assertTrue(len([]) >= 0)` — hằng đúng, không thể đỏ; lại nằm trong `.gitignore` và không job CI nào chạy. Tệ hơn không có vì tạo cảm giác an toàn giả. Sửa: parse `**FR-n**`/`AC-n` thành assertion thật + đưa vào CI, HOẶC gỡ hẳn engine | audit 2026-09-13 |
| ~~A-02 `arch-health-radar.py` không đo kiến trúc~~ | — | — | ✅ ĐÃ SỬA — 5 tín hiệu có trọng số, in công thức, tách `.md` khỏi phép đếm code; điểm 100/100 đạt bằng việc thật. Cũ: Điểm chỉ gồm hai thành phần: trừ 5 cho mỗi file >400 dòng (tối đa 20), trừ 10 nếu tỷ lệ dòng mở đầu bằng dấu thăng < 5%. Không có coupling/complexity/coverage. Còn đếm văn xuôi Markdown là "code" → báo 84% code cho repo 67% là `.md`. Sửa: bỏ `.md` khỏi phép đếm code + đổi tên chỉ số cho đúng cái nó đo | audit 2026-09-13 |
| ~~A-03 `--harness claude` xuất lệnh không tồn tại~~ | — | — | ✅ ĐÃ SỬA — nêu đúng tool Task + `subagent_type`; test cũ vốn khoá chặt chính lỗi này cũng đã sửa. Cũ: Sinh ra `/subagent <tên> <task>`, nhưng `.claude/commands/` không có `subagent.md` — dán vào Claude Code sẽ không chạy. Docstring còn kê Cursor/Windsurf/Gemini trong khi `choices` chỉ có 4. Sửa hoặc bỏ lựa chọn đó | audit 2026-09-13 |
| ~~A-04 chưa có hướng dẫn `user.email` cho phiên AI~~ | — | — | ✅ ĐÃ SỬA — mục 4b `new-project-runbook.md` + `TRAPS.md` mục 13. Cũ: `require_extra_approval_for_unattributed_changes` trong ruleset chặn MỌI PR do AI tạo nếu commit không gắn được vào tài khoản GitHub (đã xảy ra ở PR #93). Sửa: ghi cách cấu hình author/committer vào `new-project-runbook.md` + mục `TRAPS.md` | `.github/rulesets/main.json` |
| F-011 `--theme-transition` dead token | Thấp | AI | **Chấp nhận rủi ro (xác nhận 2026-09-01)** — không sửa | `docs/ops/COMPLETION-PLAN.md` |
| F-014 usage-guard số thập phân | Thấp | AI | **Chấp nhận rủi ro (xác nhận 2026-09-01)** — không sửa | `docs/ops/COMPLETION-PLAN.md` |
| F-309 `dev-task.sh` fallback grep | Thấp | AI | **Chấp nhận rủi ro (xác nhận 2026-09-01)** — không sửa | `docs/ops/COMPLETION-PLAN.md` |
| ~~5 PR dependabot chưa merge~~ | — | — | ➖ Lỗi thời (G-002, audit 2026-09-12) — #53→#57 đã merge từ trước, `list_pull_requests(state=open)` xác nhận 0 PR đang mở | `docs/ops/COMPLETION-PLAN.md` W-101 |
| **C-01 Khung chưa từng dùng trọn vẹn cho một dự án thật** | **Cao** | Người dùng | ~100 PR tự hoàn thiện, chưa lần nào đi hết `/consult`→`/bootstrap`→ra sản phẩm. Bug #104 (telemetry chết ở mọi dự án đích, sống qua nhiều PR trong khi CI xanh 100%) tìm ra chỉ bằng cách copy khung vào thư mục trống rồi chạy thử — tỷ lệ phát hiện mà audit nội bộ không đạt được. Đề xuất: làm một dự án nhỏ có thật (CLI, hoặc API 3 endpoint) | đánh giá tổng thể 2026-09-14 |
| **C-02 Hàng rào lệch về phía repo khung** | Vừa | AI | 6/10 cổng CHỈ phục vụ repo khung; dự án đích chỉ nhận 3 self-test. `dev-task.sh`, `usage-estimate.sh`, `.claude/hooks/` được phát đi nhưng CHƯA từng chạy thật ở dự án đích — cùng loại rủi ro đã gây ra #104, chưa phủ | `TRAPS.md` mục 15 |
| **C-03 Bề mặt đã tới hạn** | Thấp | Người dùng | 12 lệnh · 10 subagent · 10 cổng · 4 engine · 98 file tài liệu (8.6k dòng) · 13 file `CLAUDE.md` §1 bảo phải đọc. Đề xuất ĐÓNG BĂNG: chỉ thêm khi có nhu cầu gặp thật ở C-01 | đánh giá tổng thể 2026-09-14 |
| Case-study Bước 6–8 (branch protection/Supabase/Vercel) chưa kiểm chứng | Thấp | Người dùng | Kiểm khi áp khung vào dự án thật có tài khoản | `docs/framework/case-study-greenfield-dry-run.md` |
| ~~31 nhánh đã merge còn tồn trên remote (F-014)~~ | — | — | ✅ Đã xoá 2026-09-13 (người dùng, qua GitHub UI) — `list_branches` xác nhận chỉ còn `main` | `docs/ops/COMPLETION-PLAN.md` W-308 |
| ~~Ruleset `.github/rulesets/main.json` chưa import trên GitHub~~ | — | — | ✅ Đã import (xác nhận lại 2026-09-15: log job `protection-guard` live trên PR #131 in "OK — main đang được bảo vệ, và mọi required status check khai trong file đều đã bắt buộc"). `protection-guard` đã nằm trong `needs:` của `gate`, `CP4_BOOTSTRAP_EXEMPT` rỗng — dòng này lẽ ra phải gạch từ mốc PR #75 (mục "Đang làm / chờ" ở trên) nhưng bị bỏ sót, nay sửa cho khớp | `docs/ops/repository-settings.md` |
| ~~G-003 (`orchestration-3-tier.md` dòng sơ đồ ASCII còn "Opus·high")~~ | — | — | ✅ Đã sửa — nhánh `fix/g003-g004-stale-effort-label` | `docs/ops/COMPREHENSIVE-AUDIT-STATUS.md` |
| ~~G-004 (effort/model lặp 6 file, không cổng đối chiếu)~~ | — | — | ✅ Đã sửa — mục 5 mới trong `check-docs-consistency.sh` (cấm "Opus · high" sống lại) + negative-test trong `test-check-scripts.sh` | `docs/ops/COMPREHENSIVE-AUDIT-STATUS.md` |
| ~~W-303 test RLS~~ | — | — | ➖ Hết hiệu lực (ADR-0004) — dropins Supabase đã gỡ, không còn gì để test | `docs/ops/COMPLETION-PLAN.md` W-303 |
| ~~PROGRESS.md lỗi thời (nhánh đã merge #67 nhưng vẫn ghi "chưa mở PR")~~ | Vừa | AI | ✅ Đã sửa 2026-09-12 — thêm `scripts/check-progress-freshness.sh` + job CI `progress-freshness` chặn merge nếu tái phạm; xem `TRAPS.md` | `CLAUDE.md` §8, `CODEMAP.md` |

## Bàn giao phiên

- Lần cập nhật: 2026-09-19
- State: DONE, không có việc dở. PR #144 (đối chiếu 6 nguồn ngoài + khuôn severity `ui-ux.md`) đã
  merge vào `main`.
- Việc đã xong và bằng chứng: `docs/reports/2026-09-19-doi-chieu-6-nguon-ngoai.md` (bản đối chiếu
  ba cột đầy đủ); `.claude/commands/ui-ux.md` (mục mới "Khuôn báo cáo khi REVIEW một UI có sẵn").
  CI đỏ một lần trên job `metadata` (PR body thiếu mục `## Research / Spec`) — sửa body PR qua
  `update_pull_request`, chạy lại xanh, merge squash; `subscribe_pr_activity` tự huỷ đăng ký khi
  PR đóng (đúng thiết kế).
- Việc CHƯA xong + lý do: không có.
- Bước tiếp theo: chờ yêu cầu người dùng. Hạng mục `open-code-review` (rule-matching tất định)
  vẫn "chưa cần" — điều kiện xem lại đã ghi trong báo cáo.
- Quyền/quyết định cần thêm: không có.
