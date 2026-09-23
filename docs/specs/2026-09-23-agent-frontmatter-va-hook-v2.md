# Feature spec: Frontmatter agent máy đọc (effort/memory/maxTurns), coordinator có luật thất bại, hook SubagentStop + PreCompact

| Thuộc tính | Giá trị |
| --- | --- |
| Issue / Goal | `docs/reports/2026-09-23-de-xuat-nang-cap-khung-toan-dien.md` — Đợt 5 (C11, T1, T2, T6, T9, T15) |
| Spec owner | Phiên Claude Code (Tầng 1) |
| State | **Approved for implementation** |
| Approver / date | Người dùng (chủ repo) duyệt kế hoạch 7 đợt qua chat, 2026-09-23 |
| Last updated | 2026-09-23 |

> Không code khi chưa **Approved for implementation**.

## 1. Problem, user và evidence

- "Opus · low", "trần effort medium" chỉ nằm trong văn xuôi (0/11 agent có khoá `effort:`); `models-and-automation.md`
  tự thừa nhận effort là session-global → `spec-executor` "Opus · low" thực chất chạy Opus · medium. Claude Code hiện hành
  hỗ trợ frontmatter `effort`, `memory`, `maxTurns`, `disallowedTools`, `isolation` (code.claude.com/docs/en/sub-agents,
  xác minh 2026-09-23).
- `coordinator.md` "tối đa vài vòng" — không số; không nói gì về CI đỏ sau auto-merge, worker chạm file ngoài phạm vi,
  timeout, trần song song (trái WIP 3).
- Telemetry chỉ ghi phiên chính (`Stop`), Tầng 2/3 — nơi tốn nhất — không được đo; `SubagentStop` có `agent_type` +
  `transcript_path` riêng. `PreCompact` tồn tại nhưng khung không dùng → sau nén dễ mất dấu việc đang làm.
- `standard` ↔ `mechanical` chồng lấn nguyên văn; hai planner gắn nhãn khác nhau cho cùng việc.
- `coordinator` (tiến trình sống lâu nhất, "không nghĩ") và `spec-executor` ("zero phán đoán") chạy Opus.

## 2. Outcome, baseline, target và guardrails

| Đo | Baseline | Target |
| --- | --- | --- |
| Agent có `effort:` máy đọc | 0/11 | 11/11 (`memory`/`maxTurns` khi hợp lý) |
| Luật thất bại của coordinator | "vài vòng" | 3 vòng → BLOCKED; 5 khuôn thất bại có hành động cụ thể; trần song song min(3, độc lập) |
| Telemetry Tầng 2/3 | không | entry riêng theo `agent_type`, mốc riêng theo transcript |
| Checkpoint trước nén | không | `.claude/.compact-checkpoint` + `compact.log` |
| Model coordinator / spec-executor | Opus / Opus | Sonnet · low / Sonnet · low (Opus khi cần → `route:complex`) |

Guardrails: không dùng `isolation: worktree` cho worker (coordinator đã tự tạo worktree theo **đơn vị PR**, nhiều việc
cùng nhánh — worktree riêng từng worker sẽ tách nhánh sai); không bật `async` cho `auto-format.sh` (đua với lần ghi kế).

## 3. Research current state

Docs Claude Code (sub-agents, hooks) đọc 2026-09-23; `scripts/subagent-dispatch.py` chỉ đọc `name/description/tools/model`;
`test-engine-characterization.sh` khoá header `=== SUBAGENT ROLE: X (model) ===` (giữ nguyên, thêm dòng effort sau header).

## 4. Alternatives và decision

| Option | Benefits | Cost/risk | Decision |
| --- | --- | --- | --- |
| Do nothing | 0 | luật effort không thi hành; Opus cho việc không nghĩ | ✗ |
| A. Frontmatter + hook mới (chọn) | cổng máy thật, không đổi kiến trúc | phụ thuộc bản Claude Code hiện hành (khoá lạ bị bỏ qua, không lỗi) | ✓ |
| B. Chuyển commands → skills, tách CLAUDE.md sang `.claude/rules/` | tận dụng cơ chế mới | đụng cổng `check-docs-consistency.sh` mục 3, phạm vi lớn | để lượt sau (câu hỏi 5 của báo cáo) |
| C. Hook `TaskCompleted` type `agent` xác minh "test pass" | đúng §4 | ngữ nghĩa sự kiện gắn với task list, chưa rõ payload | không làm đợt này — ghi rõ |

## 5. Scope / non-goals

Trong: 11 file agent, `coordinator.md` mục "Thất bại & giới hạn", `orchestration-3-tier.md` tiêu chí đếm được + ghi
chú effort máy đọc, `models-and-automation.md` §4, `FEATURE-MAP`, `subagent-dispatch.py` đọc `effort`, hook
`telemetry-record.sh` (SubagentStop) + `precompact-checkpoint.sh` (mới), `settings*.json`, test. Ngoài: skills/rules,
eval route tự động (5c — để sau, chưa có sự cố thật ngoài chồng lấn văn bản), `TaskCompleted`, `async`.

## 6. User journeys và mọi state

- `/auto` → coordinator (Sonnet · low) dispatch worker; worker chạy đúng effort khai; SubagentStop ghi telemetry theo agent.
- Nén ngữ cảnh (auto hoặc `/compact`) → checkpoint ghi ra file, stderr nhắc đọc lại.
- Worker hỏng 3 vòng → BLOCKED trong báo cáo, không vòng 4.

## 7. Functional requirements

FR-1 Mỗi `.claude/agents/*.md` có `effort:` (coordinator/spec-executor/mechanical/lookup/version-check/tester `low`;
complex/standard/maintainer/reviewer `medium`; security-reviewer `high`); `memory: project` cho coordinator/maintainer/
reviewer; `maxTurns` cho mechanical (30), lookup/version-check/tester (20). `tools: … Agent` thay `Task`.
FR-2 `coordinator.md`: "3 vòng" + mục "Thất bại & giới hạn" (5 khuôn) + trần song song min(3, độc lập).
FR-3 `subagent-dispatch.py` đọc `effort` và in `(effort: X)` ngay sau header vai (header giữ nguyên).
FR-4 `telemetry-record.sh`: `--agent` = `agent_type` (mặc định `session`); mốc theo `git hash-object` của đường dẫn transcript.
FR-5 `precompact-checkpoint.sh`: ghi `.claude/.compact-checkpoint` (branch, status, 5 commit, mục Đang làm + Bàn giao) và
một dòng `.ai-telemetry/compact.log`; fail-open.
FR-6 `settings.json` ≡ `settings-shared-default.json`: thêm `SubagentStop` → telemetry, `PreCompact` → checkpoint.

## 8. Non-functional requirements

ShellCheck 0; CC ≤ 12; không dependency; Windows Git Bash chạy được (không `sha256sum`).

## 9. Acceptance criteria

AC-1 `grep -c '^effort:' .claude/agents/*.md` = 11; `test-telemetry-and-dispatch.sh`: dispatch coordinator in `(effort: low)`.
AC-2 `test-hooks-session.sh` mục 7: payload SubagentStop `agent_type=mechanical-worker` → entry `agent` đúng, token riêng;
mốc phiên chính không bị ghi đè (không entry thừa).
AC-3 `test-hooks-session.sh` mục 8: PreCompact → checkpoint có `Branch:`, mục Đang làm, Bàn giao; `compact.log` có trigger.
AC-4 `test-engine-characterization.sh` xanh (header không đổi). `check-docs-consistency.sh` mục 4 (route ↔ agent) xanh.
AC-5 `coordinator.md` không còn chuỗi "tối đa vài vòng".

## 10. UX/content/accessibility

Thông điệp BLOCKED nêu: đơn vị, tiêu chí, số vòng, bằng chứng cuối.

## 11. Architecture và code touchpoints

`.claude/agents/*.md` (11), `.claude/hooks/telemetry-record.sh`, `.claude/hooks/precompact-checkpoint.sh`,
`.claude/settings.json`, `.claude/settings-shared-default.json`, `.gitignore`, `scripts/subagent-dispatch.py`,
`scripts/model-capability-tiers.json`, `scripts/test-hooks-session.sh`, `scripts/test-telemetry-and-dispatch.sh`,
`docs/framework/orchestration-3-tier.md`, `docs/framework/models-and-automation.md`, `docs/FEATURE-MAP.md`, `CODEMAP.md`,
`CHANGELOG.md`.

## 12. API/event contract

Hook stdin JSON của Claude Code (`agent_type`, `transcript_path`, `trigger`); không đổi contract engine telemetry.

## 13. Data contract/migration

Mốc telemetry cũ `.ai-telemetry/last-stop-ts` không còn được đọc (lần Stop kế sẽ tính từ đầu transcript một lần) — chấp
nhận, gitignored.

## 14. Security/privacy/abuse cases

Checkpoint chỉ chứa git status/log + trích PROGRESS.md, nằm trong `.claude/` gitignored; không ghi nội dung file.

## 15. Rollout, observability, rollback

Có hiệu lực ở phiên kế tiếp sau merge; rollback = revert PR. Quan sát: `telemetry-log.sh --summary` có cột agent.
