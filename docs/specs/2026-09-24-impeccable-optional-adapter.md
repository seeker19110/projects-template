# Feature spec: Impeccable optional adapter

| Thuộc tính | Giá trị |
| --- | --- |
| Issue / Goal | Tích hợp có chọn lọc `pbakaus/impeccable` vào project-template |
| Spec owner | AI |
| State | **Approved for implementation** |
| Approver / date | Người dùng / 2026-09-24 |
| Last updated | 2026-09-24 |

## Problem và outcome

Repo xác minh là [`pbakaus/impeccable`](https://github.com/pbakaus/impeccable), ~70.7k stars lúc kiểm tra:
skill/CLI đa harness với commands UI, context `PRODUCT.md`/`DESIGN.md`, detector/hook. Template đã có
`/ui-ux`, feature spec, token/component và provider contract nhưng chưa có adapter Impeccable.

Target: Impeccable đã được cài sẵn là evidence tùy chọn cho UI work. Không cài/package/submodule, không
thêm hook, không copy skill/engine/dataset và không sinh `PRODUCT.md`/`DESIGN.md` mặc định. Approved spec,
ADR, token/component và framework/a11y luôn thắng recommendation/finding.

## Research, decision và scope

`PROJECT.md` + feature spec + token/component đã giữ product/design truth; thêm context files gây drift,
đúng rủi ro đã ghi ở report năm tầng SDLC. Chọn adapter docs-only: map command hẹp, detector = finding cần
triage, visitor mode = context per-surface. Không chọn installer, hooks, context-file migration, 24 aliases,
vendor binary/dataset hoặc copy catalog.

## Acceptance / rollout

- Provider không có vẫn chạy `/ui-ux`; Impeccable có sẵn được map rõ nhưng không auto-run/cài.
- `PRODUCT.md`/`DESIGN.md` và detector hooks không thành default.
- Docs consistency, copy smoke và gate xanh.

Touchpoints: `.claude/commands/ui-ux.md`, provider contract, index/CODEMAP/CHANGELOG và report đối chiếu.
Rollout qua copy/upgrade framework; rollback là revert PR docs, không có runtime/data migration.

## Approval

- [x] Product/scope, UX/a11y, architecture, security/cost, rollout/rollback
- [x] Blocking decisions closed

**Conclusion:** **Approved for implementation**
**Approver/date:** Người dùng / 2026-09-24
