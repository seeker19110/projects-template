# Release readiness

## Product và change control

- [ ] Scope/version/commit/tag/artifact rõ; AC/UAT có evidence.
- [ ] Breaking/deprecation/data migration và communication được phê duyệt.
- [ ] Known issues, residual risks và go/no-go owner ghi rõ.

## Quality/security/data

- [ ] Full profile gate xanh trên release candidate; bằng chứng từng chiều theo ma trận hồ sơ ở `docs/framework/quality-gates-by-profile.md` (mức L: đủ 5 chiều).
- [ ] Dependency, secret, SAST và threat-model findings trong SLA.
- [ ] Migration chạy fresh/repeat/upgrade; backup restore đã kiểm; reconciliation query sẵn.
- [ ] Privacy/retention/consent và authorization negative tests phù hợp.

## Artifact/supply chain

- [ ] Build từ protected source trên trusted runner.
- [ ] Version/digest/checksum; SBOM/provenance/attestation theo release profile.
- [ ] Artifact được verify trước deploy và có retention/revoke procedure.

## Operations

- [ ] Config/secrets/env/infrastructure change reviewed; staging parity đủ.
- [ ] Dashboards, alerts, SLO/error budget, health/smoke và on-call owner sẵn.
- [ ] Canary/feature flag/concurrency/rollback rehearsed.
- [ ] Runbook/status/support/incident communication cập nhật.

## Post-release

- [ ] Xác minh critical flows và metric/guardrail trong cửa sổ đã định.
- [ ] Theo dõi error/latency/cost/security/data reconciliation.
- [ ] Update Goal/PROGRESS/CHANGELOG; tạo follow-up có owner.
- [ ] Go/no-go hoặc rollback decision được ghi timestamp và evidence.

**Release decision:** GO / NO-GO / ROLLBACK  
**Owner/date/artifact digest:**
