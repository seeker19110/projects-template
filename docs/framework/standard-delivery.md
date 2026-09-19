# Standard Delivery Contract — nguồn vào duy nhất

Đây là **điểm vào chuẩn duy nhất** cho mọi dự án tạo từ template. Các tài liệu KHUNG, runbook,
completion, OpenSpec và quality supplements là tài liệu chuyên sâu được gọi từ contract này; chúng
không tạo quy trình song song.

## 1. Hai chế độ

- **Greenfield:** Idea → Research → Project Contract → Foundation → Feature loop → Release → Operate.
- **Brownfield:** Inventory → Baseline → Gap/Risk → Incremental adoption → Feature loop.

Không áp stack Web mặc định vào brownfield hoặc loại dự án khác. Chọn profile/tooling sau khi
research và ghi ADR; mọi quality gate phải có công cụ tương đương theo stack.

## 2. Artifact bắt buộc và nguồn sự thật

| Artifact | Vai trò | Template |
| --- | --- | --- |
| `PROJECT.md` | Outcome/phạm vi/kiến trúc/Project DoD | file gốc |
| `PROGRESS.md` | Tóm tắt trạng thái toàn dự án | `PROGRESS.template.md` |
| `docs/goals/<id>.md` | Checkpoint goal nhiều PR | `docs/framework/templates/GOAL.template.md` |
| `docs/specs/<date>-<slug>.md` | Research + feature contract | `docs/framework/templates/FEATURE-SPEC.template.md` |
| ADR | Quyết định khó đảo ngược | `docs/adr/0000-template.md` |
| Issue/PR/CI | Work/evidence/review thực tế | GitHub templates |

Không sao chép cùng trạng thái vào nhiều file. `PROJECT` giữ điều tương đối ổn định; `PROGRESS`
giữ tóm tắt; Goal giữ iteration state; Spec giữ contract capability; GitHub giữ execution evidence.

## 3. Vòng đời chuẩn

| Gate | Điều kiện vào | Việc bắt buộc | Điều kiện ra |
| --- | --- | --- | --- |
| Frame | Ý tưởng/vấn đề | User, outcome, metric, guardrail, non-goal | Goal/Project draft |
| Research | Draft | Code/data/user/source/alternatives/unknowns | Evidence đủ |
| Approve | Research đủ | Project contract hoặc Feature Spec được review | Approved |
| Plan | Contract Approved | Slice/dependency/test/rollout/rollback/budget | Item Ready |
| Build | Item Ready | Một outcome, branch/PR nhỏ, test cùng code | Draft PR |
| Verify | Draft PR | Targeted + full gates + self-review + risk audit | Ready PR |
| Integrate | Review/CI xanh | Merge theo quyền, release/deploy có kiểm soát | Main/release |
| Observe | Đã release | Health/metric/cost/user feedback/reconciliation | Evidence |
| Reconcile | Có evidence | Đo goal gap, cập nhật checkpoint | Next slice/Complete |

**Feature code bị cấm trước khi spec ghi Approved for implementation, người duyệt và ngày duyệt.**

### 3b. Bản đồ 5 tầng SDLC ↔ cơ chế đang có (ADR-0008)

Cùng 9 cổng ở trên, nhìn theo **5 câu hỏi vòng đời**. "Tầng" ở đây là *tầng vòng đời*, khác "Tầng 1/2/3"
của `orchestration-3-tier.md` (*tầng điều phối*) — cột "Ai làm" nói rõ ánh xạ. Không có agent nào mới:
tầng ①②⑤ là **vai của phiên chính**; chỉ ③④ dùng subagent (spawn khi cần, xong thì kết thúc).

| Tầng vòng đời | Câu hỏi | Cổng | Ai làm (lệnh / agent) | Artifact ra | Cổng máy kiểm | Fail ở tầng sau → quay về đây khi |
| --- | --- | --- | --- | --- | --- | --- |
| ① Product & UX | Xây gì, tại sao? | Frame · Research · Approve | Phiên chính: `/consult`, `/grill`, `lookup`/`version-check` (tra cứu) | `docs/goals/<id>.md`, `docs/specs/<ngày>-<slug>.md` **Approved** | `pr-policy.yml` (PR `feat` chưa Approved → đỏ) | acceptance criteria sai/thiếu, scope lệch, edge case chưa nêu |
| ② Design | Hoạt động / trông thế nào? | Approve (spec §6, §10, §11) · Plan | Phiên chính: `/ui-ux` (UI) hoặc thiết kế CLI/API/DX theo hồ sơ C4/C5 | Mục journeys-mọi-state, UX/a11y, kiến trúc & điểm chạm **trong cùng spec** | axe/E2E a11y, Lighthouse CI (hồ sơ C1); cổng hồ sơ khác ở `quality-gates-by-profile.md` | thiếu state (tải/rỗng/lỗi), luồng không khớp, contract API/DDL chưa chốt |
| ③ Engineering | Xây bằng cách nào? | Plan · Build | Tầng 1 viết PLAN.md → `coordinator` → worker `route:complex/spec/standard/mechanical` (`subagent-dispatch.sh --tier`) | PR nhỏ, test cùng code (TDD đỏ-trước, ADR-0005) | hook `pre-commit-gate.sh`, `auto-format.sh`; `progress-freshness` | lỗi trong code đã có spec đúng — **mặc định là đây, nhưng phải nêu lý do** (luật dưới) |
| ④ Verify & Operate | Đúng, an toàn, chạy tốt không? | Verify · Integrate · Observe | `/gate` (§5–§7), `tester`, `reviewer`, `security-reviewer`; `release-readiness.md`; `/incident`; `/maintain` | Báo cáo xác thực §7, PR xanh + auto-merge, post-mortem, `MAINTENANCE-*.md` | `ci.yml` job `gate`, `secret-scan`, `dependency-review`, `maintenance.yml` | cổng/CI/hạ tầng sai (máy xanh giả, lockfile lệch — xem `gate.md` Bước 1) |
| ⑤ Knowledge | Hệ thống biết gì, đã đổi gì? | Reconcile (+ mọi PR, §8 bước 0/5) | Phiên chính: `/adr`, cập nhật `PROGRESS.md`, `CONTEXT.md`, `TRAPS.md`, `CODEMAP.md`, `docs/changelog/` | ADR, TRAPS mục mới, PROGRESS mốc + SHA, changelog đợt việc | `progress-freshness` (PF-1..3), `docs-consistency`, `maintenance-sweep` 🟡 `DEBT:` thiếu `xem lại khi:` | (không có tầng sau) — tri thức sai làm ① của chu kỳ kế lệch: sửa tại ADR/TRAPS, không sửa code |

**Luật quy lỗi về tầng (bổ sung trần "3 lần → BLOCKED" của §4):** khi Verify fail, lần sửa **đầu** được
sửa code ngay; trước lần sửa **thứ 2 cùng một failure** phải viết một dòng *"lỗi ở tầng ①/②/③/④ vì …"*
và quay về đúng tầng đó (sửa spec/design trước, rồi mới code). Lần thứ 3 vẫn fail → BLOCKED, xin quyết
định. Cross-cutting (bảo mật, hiệu năng, a11y, quyền riêng tư, chi phí, observability) **không** là tầng
riêng: mỗi tầng có cổng của mình cho chúng (spec §8/§14 → design a11y → code an toàn → scan/test → ADR).

## 4. AI Goal Loop

```text
while Goal DoD chưa đạt:
  reload main + PROJECT/PROGRESS/Goal/Spec + GitHub/CI
  reconcile checklist với code, test và trạng thái thật
  nếu stop condition: checkpoint BLOCKED/WAITING; xin quyết định
  chọn một slice Ready có value/risk-reduction cao nhất
  nếu feature chưa có spec Approved: chỉ research/spec; không code
  plan → implement → verify/repair (tối đa 3 lần cùng failure)
  mở/cập nhật một PR
  nếu chưa có quyền merge hoặc đang chờ CI/review: checkpoint WAITING; dừng
  sau merge/release: đo lại goal gap và checkpoint
final audit → COMPLETE
```

Một iteration = một outcome + một PR. Không xây code phụ thuộc lên base chưa merge nếu tránh được.

## 5. Definition of Ready

- problem/user/outcome/baseline/target/guardrail rõ;
- research có bằng chứng và alternatives kể cả không làm;
- scope/non-goals/dependency/owner rõ;
- UX/states và API/data/contracts đủ để không tự đoán;
- security/privacy/a11y/performance/reliability/cost/failure modes đã đánh giá;
- AC map được tới test;
- migration/rollout/telemetry/rollback cụ thể;
- không còn quyết định product/architecture blocking;
- spec Approved có người/ngày duyệt.

## 6. Definition of Done

- implementation khớp spec; deviation được review;
- AC có bằng chứng; test mới chứng minh behavior/bug;
- targeted và full quality gates xanh;
- authorization, validation, privacy, concurrency/idempotency và error recovery được xử lý;
- không secret/production data/debug/dead/generated output ngoài ý muốn;
- contract/migration/docs/ADR/telemetry/runbook cập nhật;
- rollout/rollback và residual risk rõ;
- review threads đóng; required checks xanh.

## 7. Definition of Goal/Project Complete

- mọi AC bắt buộc có bằng chứng trên default branch/release;
- target metric đạt trong cửa sổ đo; guardrail không suy giảm;
- không còn milestone bắt buộc, P0/P1, migration/reconciliation dở;
- regression/security/privacy/a11y/performance/operational gates liên quan xanh;
- UAT/production verification/restore drill hoàn tất nếu thuộc scope;
- ownership, docs, runbook, observability và rollback hoàn chỉnh;
- out-of-scope/residual risks được ghi;
- owner xác nhận completion khi cần quyết định nghiệp vụ.

Backlog trống không đồng nghĩa Project Complete; backlog ngoài scope không ngăn completion.

## 8. Repair, budget và stop conditions

Cùng failure tối đa ba lần: ghi error/giả thuyết → sửa nguyên nhân nhỏ nhất → chạy lại test lỗi và
gate liên quan. Cấm skip/xóa test, hạ threshold, nới auth/validation hoặc che lỗi để xanh.

Dừng `BLOCKED` khi thiếu approval; trade-off product/architecture; destructive/breaking change;
security/payment/user data; cần secret/production/chi phí/quyền mới; CI/review ngoài scope; vượt
budget/guardrail; main làm plan mất hiệu lực; hoặc không còn item Ready. `WAITING` khi chỉ chờ
CI/review/merge. AI không suy ra quyền merge/deploy từ quyền code.

## 9. Governance, data và supply-chain gates

- Public/multi-contributor project: instantiate Governance, Support và Code of Conduct phù hợp.
- Sensitive/personal/regulated data: tạo Data Governance artifact; review retention/export/delete.
- Auth/payment/multi-tenant/automation/high-impact change: threat model trước implementation.
- Release artifact: áp `docs/ops/supply-chain.md` và `docs/ops/release-readiness.md`.
- Repository settings: cấu hình và lưu evidence theo `docs/ops/repository-settings.md`.
- Không claim compliance/SLSA/security level nếu chưa audit đủ requirement.

## 10. Quality gate theo profile

Mỗi project phải điền command thật trong `CLAUDE.md`. Tối thiểu có format/lint/type-or-static
analysis/unit/integration/build-package/security scan; thêm E2E/a11y/performance cho UI/Web,
migration/data tests cho DB, eval/cost/safety cho AI, platform/device tests cho mobile/desktop.

## 11. Cách dùng tài liệu chuyên sâu

- Greenfield bootstrap: `new-project-runbook.md`.
- Brownfield: `existing-project-adoption.md`.
- Quy trình 9 giai đoạn: `01-process-and-standards.md`.
- Research/stack profiles: `03-tech-selection-and-proactive-advice.md`.
- Feature spec nâng cao/OpenSpec: `spec-driven-openspec.md`.
- Audit/hội tụ Project Complete: `project-completion.md`.
- Checklist chất lượng: `quality-supplements.md`.

Nếu tài liệu chuyên sâu mâu thuẫn contract này, dừng và sửa mâu thuẫn trước khi tiếp tục.
