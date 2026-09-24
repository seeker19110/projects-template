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
thêm hook chạy mặc định, không copy skill/engine/dataset và không sinh `PRODUCT.md`/`DESIGN.md` mặc định. Approved spec,
ADR, token/component và framework/a11y luôn thắng recommendation/finding.

## Research, decision và scope

`PROJECT.md` + feature spec + token/component đã giữ product/design truth; thêm context files gây drift,
đúng rủi ro đã ghi ở report năm tầng SDLC. Chọn mapping command hẹp và hook detector opt-in:
detector = finding cần triage, visitor mode = context per-surface. Không chọn installer, hook tự bật,
context-file migration, 24 aliases, vendor binary/dataset hoặc copy catalog.

## Functional requirements

- **FR-1** Provider không có hoặc chưa opt-in thì `/ui-ux` và thao tác sửa file vẫn chạy bình thường.
- **FR-2** Khi opt-in và có executable hợp lệ, hook chỉ gọi detector với file UI tồn tại.
- **FR-3** Lỗi từ detector không chặn thao tác sửa file và không tạo file product/design song song.

## Acceptance / rollout

- **AC-1** Provider không có vẫn chạy `/ui-ux`; Impeccable có sẵn được map rõ nhưng không auto-run/cài.
- **AC-2** `PRODUCT.md`/`DESIGN.md` và detector hook không thành default.
- **AC-3** Hook opt-in chỉ gọi file UI tồn tại; detector thoát lỗi vẫn không chặn edit.
- Docs consistency, copy smoke và gate xanh.

Touchpoints: `.claude/commands/ui-ux.md`, `.claude/hooks/ui-intelligence.sh`, hai settings files,
provider contract, index/CODEMAP/CHANGELOG và report đối chiếu.
Rollout qua copy/upgrade framework; rollback là revert adapter PR, không có data migration.

## Approval

- [x] Product/scope, UX/a11y, architecture, security/cost, rollout/rollback
- [x] Blocking decisions closed

**Conclusion:** **Approved for implementation**
**Approver/date:** Người dùng / 2026-09-24
