# Repository settings baseline

Các setting này không nằm hết trong Git, nên phải cấu hình và lưu evidence (ảnh/link/audit output). Rà
khi tạo repo, đổi visibility/owner, sau incident và tối thiểu mỗi quý.

## Access và governance

- [ ] Owner/admin tối thiểu cần thiết; 2FA/SSO theo tổ chức; review dormant/outside collaborators.
- [ ] Default branch rõ; cấm force-push/delete; mọi thay đổi qua PR.
- [ ] Required checks theo project profile; branch up-to-date hoặc merge queue khi concurrency cao.

### Required checks & branch protection — nguồn sự thật (đối chiếu tự động, 2 lớp)

**Cách bật (một lần, chủ repo làm trên GitHub):** import `.github/rulesets/main.json` — Settings →
Rules → Rulesets → **New ruleset → Import a ruleset** → chọn file đó → Create. File này (cơ chế mượn
từ repo `seeker19110/Claude-Agents`, tài liệu QUY-TRINH-GIT.md §8 của repo đó) khai: bắt buộc PR, chỉ **squash**, cấm
xoá/force-push `main`, **required status checks = `gate` + `metadata`** (chỉ HAI tên — ADR-0003),
**không ai bypass được kể cả admin** (`bypass_actors` rỗng), `required_approving_review_count: 0`
(không phải hạ chuẩn — GitHub không cho tự duyệt PR của chính mình; đặt 1 sẽ khoá vĩnh viễn mọi PR
khi repo chỉ có một người, xem case PR #40 của Claude-Agents nếu tò mò tại sao). Đặt lại thành ≥ 1
khi repo có thêm collaborator khác. **`strict_required_status_checks_policy: true`** (từ 2026-09-23, audit T1):
nhánh phải cập nhật với `main` trước khi merge — đúng CLAUDE.md §6; với trần WIP 3 + auto-merge, PR sau merge
của PR trước phải "Update branch" (GitHub tự làm khi bật auto-merge, hoặc tay) rồi CI chạy lại. **Đổi file này
thì chủ repo phải import lại ruleset** — `protection-guard` chỉ đối chiếu rule/check có mặt, không đối chiếu
tham số `strict`.

`gate` là job tổng hợp `needs:` mọi job cổng của `ci.yml`, nên thêm job cổng mới **không cần**
sửa cấu hình GitHub nữa — chỉ thêm vào `needs:` của `gate` trong cùng PR.

**Job `protection-guard` trong `ci.yml` xác nhận ruleset đã import THẬT SỰ có hiệu lực** (không chỉ
là lời hứa trong tài liệu này) và **khớp file `.github/rulesets/main.json`** theo hai chiều: thiếu
rule/check khai trong file → lỗi (bảo vệ yếu hơn thứ repo khai); có rule đang áp nhưng không khai
trong file → cảnh báo (không yếu đi, nhưng import lại sẽ xoá mất). Lý do cần vế hai: sửa ruleset qua
UI có thể làm rơi một rule mà không báo gì — CI vẫn xanh nếu không có đối chiếu này.

Khối dưới đây là **bản kê toàn bộ job** của hai workflow đó (không phải danh sách cần tick):
`scripts/check-ci-policy.sh` đối chiếu hai chiều bản kê này với job thật và chặn CI nếu lệch
(job `docs-consistency`), đồng thời kiểm mọi job của `ci.yml` đều có mặt trong `needs:` của `gate`.
Đổi tên/xoá/thêm job thì sửa bản kê này **trong cùng PR**.

Không liệt kê job của `secret-scan.yml`, `dependency-review.yml`, `release.yml`, `stale-pr-alert.yml`, `maintenance.yml` ở đây — các workflow
đó không thuộc cổng merge bắt buộc cho mọi PR (scheduled/optional/advisory theo cấu hình từng dự án
đích); bật required check cho chúng là lựa chọn riêng của mỗi dự án, không phải bất biến của khung.

```
ci.yml: framework-lint
ci.yml: framework-lint-windows
ci.yml: docs-consistency
ci.yml: copy-framework-smoke
ci.yml: progress-freshness
ci.yml: protection-guard
ci.yml: gate
pr-policy.yml: metadata
```

- [ ] Require conversation resolution; code-owner approval cho vùng nhạy cảm.
- [x] Nhánh đã merge dọn sạch (audit 2026-09-12, F-014) — người dùng đã tự xoá qua GitHub UI
      2026-09-13; `list_branches` xác nhận repo chỉ còn `main`.
- [x] Auto-delete branch sau merge — **đã bật** (bằng chứng: nhánh `claude/eager-darwin-k1f1y6` biến mất khỏi
      remote ngay sau khi PR #166 merge 2026-09-23, `check-progress-freshness.sh` PF-2 báo; `MAINTENANCE-LOG.md`
      2026-09-21 ghi nhận tương tự).
- [ ] Không cho workflow tự approve PR; default `GITHUB_TOKEN` read-only.
- [ ] Chọn squash/rebase/merge strategy và auto-delete branch.
- [ ] **Require signed commits** (chỉ khi dự án ở ASVS L2+ hoặc nhiều người đóng góp không quen biết
      trực tiếp — xem `docs/framework/industry-standards.md` §C) — không bật mặc định cho mọi dự án.

## Security

- [ ] Dependency graph, Dependabot alerts/security updates và dependency review.
- [ ] Secret scanning + push protection; private vulnerability reporting cho public repo.
- [ ] Code scanning phù hợp ngôn ngữ; security policy/contact đã điền.
- [ ] Actions chỉ từ nguồn tin cậy; pin full SHA; review Dependabot action updates.
- [ ] Self-hosted runner được cô lập; không chạy untrusted fork code trên runner có secret/network nhạy cảm.
- [ ] Audit log/vulnerability alerts có owner và SLA.

## Environments và deploy

- [ ] dev/staging/prod tách dữ liệu, credentials và cloud account/project khi khả thi.
- [ ] Production environment có required reviewer, branch/tag rules và concurrency.
- [ ] Dùng OIDC short-lived credentials thay long-lived cloud secret khi provider hỗ trợ.
- [ ] Secret scope tối thiểu; rotation/revocation owner; không đưa secret vào PR workflow từ fork.
- [ ] Deploy ghi artifact digest/version/provenance; có health check và rollback.

## Community/project metadata

- [ ] Description, topics, homepage, README, license và template-repository setting đúng.
- [ ] CONTRIBUTING, SECURITY; Code of Conduct/Support/Governance khi public hoặc nhiều contributor.
- [ ] Discussions/Issues phù hợp; Issue Forms không chứa URL của repo template nguồn.
- [ ] Citation/funding chỉ thêm khi project thực sự cần.

## Evidence

| Setting/control | Value | Owner | Verified date | Evidence/link | Next review |
| --- | --- | --- | --- | --- | --- |
| Ruleset `main` import từ `.github/rulesets/main.json` | active, bypass_actors rỗng | chủ repo | 2026-09-13 | job `protection-guard` xanh trên mọi PR (đối chiếu live rules ↔ file) | mỗi quý / khi đổi file ruleset (đổi gần nhất 2026-09-23: `strict_required_status_checks_policy: true` — **cần import lại**) |
| Auto-delete branch sau merge | bật | chủ repo | 2026-09-23 | nhánh `claude/eager-darwin-k1f1y6` biến mất ngay sau PR #166 merge (PF-2 báo) | mỗi quý |
| Auto-merge (squash) cho PR | bật | chủ repo | 2026-09-23 | `enable_pr_auto_merge` thành công ở PR #166–#172 | mỗi quý |
| Secret scanning (gitleaks) + CodeQL + Scorecard | workflow chạy trên PR/push/lịch | khung | 2026-09-23 | check run `gitleaks`, `Analyze (python|actions)`, `CodeQL` trên PR #170 | khi đổi workflow |
