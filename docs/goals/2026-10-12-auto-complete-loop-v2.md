# Goal: Vòng lặp `/auto-complete` v2 — trạng thái máy tính, workflow tham chiếu

| Thuộc tính | Giá trị |
| --- | --- |
| Goal ID | GOAL-2026-012 |
| Owner | Chủ repo; phiên chính nghiệm thu theo ủy quyền §3d |
| State | ACTIVE |
| Default-branch SHA đã reconcile | e524b49 |
| Bắt đầu / review | 2026-10-12 |
| Quyền AI | research, branch, PR, auto-merge khi CI xanh theo luật repo; không production |
| Budget | Không dependency mới, không model/API trả phí, ≤ 3 PR |

## Outcome và Goal DoD

- User/job: người dùng gõ `/auto-complete` một lần; mỗi vòng bắt đầu bằng trạng thái máy đo, bước kế tiếp do máy đề xuất từ artifact
  thật; vòng dừng khi artifact không đổi 2 lượt, khi Blocked/Waiting, hoặc khi `done.md`.
- Baseline → target: 0 script tính bước kế tiếp → `scripts/loop-state.sh` (AC-1..AC-8 spec); hook đo bằng lời → bằng vân tay artifact
  (AC-10..AC-12); 0 reader kế hoạch/DoC/GO-NO-GO → đếm máy (AC-5).
- Measurement window: CI xanh trên `main` sau PR-B; `test-loop-state.sh` + `test-hooks-loop.sh` chạy trong `framework-lint`.
- Guardrails: không hạ cổng; 11 ca hook cũ xanh; coverage ≥ 95%; radar 0 file > 400 dòng mới.
- Completion approver: phiên chính theo §3d, ghi ở `done.md`.

## Scope / non-goals

Spec `docs/specs/2026-10-12-auto-complete-loop-v2.md` §5. Ngoài: runner ngoài, agent teams, cổng 13b/15/16 cho đích.

## Milestones và slices

| ID | Outcome/AC | Dependency | Spec | Issue | PR | State | Evidence |
| --- | --- | --- | --- | --- | --- | --- | --- |
| U1 | Thiết kế: báo cáo, ADR-0012, spec Approved, goal, workflow doc, sổ | — | spec §17 | — | PR-A | DONE | #295 → `e524b49`; CI framework-lint/windows/docs-consistency/progress-freshness SUCCESS |
| U2 | Engine `loop-state` + test đỏ-trước + `/auto-complete` nạp `!` + sửa regex DONE/WIP 5 (AC-1..9, AC-13a-b) | U1 | spec §7 | — | PR-A | DONE | #295 → `e524b49`; `test-loop-state.sh` 32 ✅, coverage 97 %, review độc lập 2 lỗi sửa đỏ-trước |
| U3 | Hook guard vân tay artifact + session-resume + telemetry work-id + manifest (AC-10..12, AC-14) | U2 | spec §7 FR-10..12 | — | PR-B | BUILD | |
| U4 | Đóng hồ sơ `done.md` + PROGRESS + CHANGELOG | U3 | — | — | PR-C | BACKLOG | |

## Risk register

| Risk | Trigger | Mitigation/rollback | Owner | State |
| --- | --- | --- | --- | --- |
| `!` không chạy ở harness khác | Codex/Cursor | lệnh ghi bước tay; engine chạy tay | phiên chính | open |
| Parser goal/plan lệch khuôn ở đích | bảng không có cột ID/State | báo "0 slice đọc được", không đoán | worker U2 | open |
| `gh` chậm/thiếu | offline | timeout 15 s → unknown | worker U2 | mitigated (test `không gh`, `gh lỗi`) |
| `gh pr list --json` (GraphQL) 403 trong phiên Claude Code cloud | chạy vòng lặp trong cloud | `pr.available=false` có note; DEBT tại `_gh_list` → REST fallback khi cần `waiting` tự động | phiên chính | open |

## Current truth

- Goal gap: U1, U2 DONE (#295); U3 đang BUILD (PR-B); U4 BACKLOG.
- Blocker/open decision: không.
- Next best slice + reason: U3 (hook) — slice ready duy nhất.
- Permission needed: không.

## Iteration log

### Iteration 1 — 2026-10-12

- State/default-branch SHA: ACTIVE / 3954c65.
- Slice and gap before/after: research 4 nguồn xong → báo cáo + ADR + spec + goal + workflow doc.
- Research/spec/issue/PR: spec Approved §3d; PR-A mở sau U2.
- Checks/test counts/metric: chưa (U2 chưa chạy).
- Risk/decision: chọn phương án B (ADR-0012); gộp U1+U2 một PR vì harness push một nhánh.
- Blocker/next slice/permission: U2.

### Iteration 2 — 2026-10-12

- State/default-branch SHA: ACTIVE / e524b49.
- Slice and gap before/after: U1+U2 BUILD → DONE (#295 merge 20:29Z); U3 BACKLOG → BUILD.
- Research/spec/issue/PR: PR-A #295 squash; review độc lập 7 phát hiện → 5 sửa (3 ca đỏ-trước), 2 ghi lý do.
- Checks/test counts/metric: test-loop-state 32 ✅; coverage 97 %; CI xanh (gate đỏ một lần trên head cũ do run bị huỷ khi push mới).
- Risk/decision: `gh` GraphQL 403 trong cloud → DEBT + risk register; worktree harness trong cây repo → tạo tay ngoài cây.
- Blocker/next slice/permission: U3 (PR-B).

## Final audit

- [ ] AC có evidence trên default branch/release.
- [ ] Metrics đạt; guardrails không suy giảm.
- [ ] Không còn mandatory milestone/P0/P1/migration/reconciliation.
- [ ] Quality/security/privacy/a11y/performance/ops gates xanh.
- [ ] UAT/production/restore verification hoàn tất nếu thuộc scope. (n-a)
- [ ] Docs/ownership/telemetry/runbook/rollback hoàn chỉnh.
- [ ] Residual risk/out-of-scope ghi rõ.
- [ ] Owner xác nhận khi cần.

**Kết luận:** NOT COMPLETE  
**Người/ngày xác nhận:**
