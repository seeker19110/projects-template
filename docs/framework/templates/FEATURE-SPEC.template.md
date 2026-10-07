# Feature spec: <Tên capability>

| Thuộc tính | Giá trị |
| --- | --- |
| Issue / Goal | |
| Spec owner | |
| State | Draft / In review / **Approved for implementation** |
| Approver / date | |
| Last updated | |

> Không code khi chưa **Approved for implementation**.
>
> **Spec gọn (mức M)** — tính năng gọn một PR, không chạm mốc §9 (`standard-delivery.md` §3c): chỉ bắt buộc
> mục 1, 2, 5, 9, 11 và Approval; xoá các mục còn lại. AC vẫn đánh mã `AC-n` và map tới test. Mức L dùng
> đủ mẫu; chạm mốc §9 giữa chừng thì nâng lên mức L trước khi code tiếp.

## 1. Problem, user và evidence

## 2. Outcome, baseline, target và guardrails

## 3. Research current state

Code/data/user/source/constraint; ghi link/version/access date cho nguồn thay đổi theo thời gian.

## 4. Alternatives và decision

| Option | Benefits | Cost/risk | Decision |
| --- | --- | --- | --- |
| Do nothing | | | |
| A | | | |
| B | | | |

## 5. Scope / non-goals

## 6. User journeys và mọi state

Happy/loading/empty/error/offline/permission/limit/conflict/retry/recovery.

## 7. Functional requirements

FR-1...

## 8. Non-functional requirements

Security/privacy/a11y/performance/reliability/compatibility/cost/safety.

## 9. Acceptance criteria

AC-1 Given/When/Then; map từng AC tới test/evidence.

## 10. UX/content/accessibility

## 11. Architecture và code touchpoints

## 12. API/event contract

Auth, validation, idempotency, error, pagination, timeout/retry/versioning.

## 13. Data contract/migration

Schema/index/constraint/ownership/retention/backfill/verify/compatibility/recovery.

## 14. Security/privacy/abuse cases

## 15. Observability và operations

Metric/event/log không PII, dashboard/alert/health/runbook/owner.

## 16. Test/eval plan

Unit/integration/E2E/a11y/performance/concurrent/retry/migration/manual/UAT/AI eval phù hợp profile.

## 17. Slice/PR plan

Dependency, một outcome/PR, rollout order.

## 18. Rollout/rollback

Staging/canary/go-no-go/feature flag/migration/revert/reconciliation.

## 19. Risk, assumptions và open decisions

| Item | Verification/mitigation | Owner | Due | Decision |
| --- | --- | --- | --- | --- |

Không Approved khi còn blocking decision.

## Approval

- [ ] Product/scope
- [ ] UX/a11y
- [ ] Architecture/API/data
- [ ] Security/privacy/cost
- [ ] Test/telemetry/rollout/rollback
- [ ] Blocking decisions closed

**Conclusion:** Draft / In review / **Approved for implementation**  
**Approver/date:**
