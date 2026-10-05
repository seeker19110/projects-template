# COMPLETION-PLAN — trạng thái hiện hành 2026-10-05

> Người dùng duyệt hoàn thiện chính bộ khung ngày 2026-10-05. Kế hoạch chi tiết:
> `docs/reports/2026-10-05-framework-completion-plan.md`; audit 12 nhóm:
> `docs/reports/2026-10-05-framework-audit.md`. Phần "lượt 2026-09-12" bên dưới
> là lịch sử, không dùng các ô chưa tick của lượt cũ để suy ra trạng thái hiện tại.

## Chu kỳ 2026-10-05

| Slice | Finding / outcome | Trạng thái | Bằng chứng cần có |
| --- | --- | --- | --- |
| W-01 | Reconcile goal F-01..11, FEATURE-MAP, PROGRESS | Bàn giao trong PR tài liệu này | Main nguồn `6702994d90ad318142715aa172d79916c71e5b9d`; bản đồ đếm đúng 16/11/9/9, truy vết F→PR→regression |
| W-02 | Audit 12 nhóm năng lực khung | DONE | Snapshot và re-audit trong `docs/reports/2026-10-05-framework-audit.md`; nhóm N/A và giới hạn có lý do |
| W-03 | CodeQL #185/#186, grouping | DONE | #185 `8f4a181` merged, hai Analyze xanh; #186 trùng đóng |
| W-04 | Ruleset strict và regression guard | DONE | #188 `bec5795`; live strict=true, required gate+metadata; false đỏ/true xanh |
| W-05 | F-K01..05/F-K09/F-K10 | DONE | #189–194 và #196 merged; test hồi quy và required CI xanh trên head cuối; progress-freshness skip theo main-only |
| W-06 | Ma trận adoption/copy/gate | DONE đối chiếu, runtime giới hạn | #195: Node/Python tối thiểu chạy thật, các resolver fixture được liệt kê; Go/Make, stack runtime khác, CI hosted chưa kiểm; C01 ngoài phạm vi khung |
| W-07 | Re-audit và Definition of Complete | WAITING | Không phát hiện Cao/Trung mới trong phần code/cổng đã rà; F-K08/F-11 bàn giao ở PR này. Cổng PR phải đạt trước merge; người dùng xác nhận đóng chu kỳ theo Pha 4 |

Bằng chứng source: CI #196 run 37323540706 trên head `8b97ee6`: Linux/Windows,
docs/copy/protection/gate SUCCESS; metadata, CodeQL, dependency-review và gitleaks
SUCCESS. `progress-freshness` SKIPPED trên PR theo main-only. Cổng cuối của hồ sơ
nằm trong PR bàn giao này; không suy ra hosted CI hoặc UAT của sản phẩm thật.

---

# COMPLETION-PLAN — Kế hoạch hoàn thiện khung (lượt 2026-09-12)

> Lượt trước (01/09, 22 việc W-101→W-406) đã ĐÓNG — không mở lại. Đây là **chu kỳ mới**.
> Nguồn phát hiện: `docs/ops/COMPREHENSIVE-AUDIT-STATUS.md` (2 Cao · 8 Trung · 5 Thấp).
> Duyệt: người dùng duyệt "cập nhật toàn diện" (2026-09-12) — phạm vi = cả 15 phát hiện.
> Spec: `docs/specs/2026-09-12-enforcement-guardrails.md` (**Approved for implementation**).
> Trạng thái: ⬜ chưa làm · 🔄 đang làm · ✅ xong (kèm bằng chứng) · ➖ huỷ (kèm lý do).

## Definition of Complete (lượt này)

- [ ] 0 phát hiện **Cao** còn mở (F-001, F-002).
- [ ] Mọi phát hiện Trung/Thấp có kết cục: sửa xong, hoặc chấp nhận rủi ro ghi vào `PROGRESS.md`.
- [ ] Mọi cổng tự kiểm của khung xanh: `check-docs-consistency.sh`, `check-ci-policy.sh`,
      `test-copy-framework.sh`, `verify-dropins.sh`.
- [ ] **Mỗi assertion mới có negative test** (cố tình vi phạm → thấy đỏ) — quy ước A trong `CONVENTIONS.md`.
- [ ] Cổng chặn được **chứng minh chặn thật** (F-002) — không còn hàng rào nào chỉ có luật mà không có cơ chế.
- [ ] `PROGRESS.md` + `CODEMAP.md` + `CONVENTIONS.md` khớp trạng thái sau lượt sửa.

## Đợt 1 — Chuỗi cung ứng (gấp: Node 20 bị xoá khỏi runner 16/09/2026)

| ID | F gốc | Việc | Tiêu chí nghiệm thu | Phụ thuộc | Sức | Trạng thái |
| --- | --- | --- | --- | --- | --- | --- |
| W-106 | F-001 | **(mới — chặn W-101)** Miễn trừ PR bot khỏi yêu cầu mục PR template trong `pr-policy.yml` | PR dependabot có check `metadata` xanh | — | S | ✅ merge ở **PR #64** (`1a2a45f`); bằng chứng: `metadata` chuyển từ đỏ 2/2 lượt → **xanh** trên cả 5 PR dependabot |
| W-101 | F-001 | Merge 5 PR dependabot theo **FIFO** (#53→#54→#55→#56→#57) | 5 PR MERGED; `main` không còn action Node 20 | **W-106** | S | ✅ 5/5 merged; đo lại trên `main`: **0 action node20** (kèm 1 lỗi tự bắt — xem dưới) |
| W-102 | F-003 | Pin `actions/cache@v4` → full SHA | `ci.yml:205` có SHA + comment `# v4.x.y` | W-101 | S | ✅ `ci.yml:205` → `actions/cache@caa2961 # v5.1.0` (Node 24, thay vì v4 Node 20 sắp bị xoá khỏi runner) |
| W-103 | F-003 | Thêm kiểm "mọi `uses:` phải pin SHA" vào `scripts/check-ci-policy.sh` + negative test | Script bắt được action không pin (chứng minh bằng lượt chạy đỏ có chủ đích) | W-102 | S | ✅ `ci.yml:205` → `actions/cache@caa2961 # v5.1.0` (Node 24, thay vì v4 Node 20 sắp bị xoá khỏi runner) |
| W-104 | F-005 | gitleaks ở pre-commit (dropins `.husky/pre-commit`) | Commit chứa bí mật mẫu bị chặn tại local, trước khi vào lịch sử | — | S | ✅ `.husky/pre-commit` + kiểm 4 nhánh (chặn/cho qua/thiếu gitleaks/cờ bỏ qua) |
| W-105 | F-001 | Hàng rào chống tái phát: cảnh báo khi có PR mở cũ hơn PR đang xử lý (FIFO) | Có cơ chế nhắc FIFO; hoặc ghi nhận không tự động hoá được + lý do | W-101 | M | ✅ `.github/workflows/stale-pr-alert.yml` (tuần) — 4 ca logic chạy offline với `github`/`core` giả: bỏ qua draft+PR mới, update issue cũ, không vỡ khi API check lỗi |

## Đợt 2 — Chứng minh cổng chặn thật + dựng hàng rào cho luật

| ID | F gốc | Việc | Tiêu chí nghiệm thu | Phụ thuộc | Sức | Trạng thái |
| --- | --- | --- | --- | --- | --- | --- |
| W-201 | F-002 | Test chứng minh `pre-commit-gate.sh` **chặn** (exit 2) khi cổng đỏ, và fail-open có cảnh báo khi thiếu `jq` | Test chạy thật, đỏ nếu hook ngừng chặn | — | M | ✅ `scripts/test-hooks-gate.sh` 6 ca + negative test, 21/21 assertion xanh |
| W-202 | F-002 | `verify-dropins.sh` phải **commit thật** một lần để husky `pre-commit` + `commit-msg` được chạy | Bước mới trong verify: commit sai quy ước → bị chặn; commit đúng → qua | W-201 | M | ✅ `scripts/test-hooks-gate.sh` 6 ca + negative test, 21/21 assertion xanh |
| W-203 | F-004 | Hook `block-dangerous-git.sh`: chặn force-push vào nhánh chính, `reset --hard`, `merge/rebase --abort` | Thử từng lệnh → bị chặn; có cờ bỏ qua tường minh | — | M | ✅ `block-dangerous-git.sh` + 12 ca test (5 chặn, 5 không chặn oan, cờ, NT); khai trong cả 2 settings.json |
| W-204 | F-007 | `auto-format.sh` cảnh báo ra stderr khi no-op (thống nhất với `pre-commit-gate.sh`) | Thiếu `jq` → có dòng cảnh báo, vẫn `exit 0` | — | S | ✅ fail-open có cảnh báo (thống nhất `pre-commit-gate.sh`) |

## Đợt 3 — Thống nhất chéo + phần còn lại

| ID | F gốc | Việc | Tiêu chí nghiệm thu | Phụ thuộc | Sức | Trạng thái |
| --- | --- | --- | --- | --- | --- | --- |
| W-301 | F-006 | Cổng kiểm `.claude/agents/` ↔ bảng nhãn `route:` trong `orchestration-3-tier.md` (2 chiều) + frontmatter | Thêm/xoá agent mà quên tài liệu → CI đỏ; có negative test | — | S | ✅ `check-docs-consistency.sh` §4 + 3 NT (agent thiếu tài liệu, name lệch, route trỏ agent ảo) |
| W-302 | F-008 | Ràng `check-ci-policy.sh` ↔ `ci-workflow-policy.test.ts` (danh sách assertion khớp nhau) | Sửa một bên mà quên bên kia → đỏ | — | M | ✅ bảng kiểm `CP-*` — thêm kiểm ở bản shell mà quên bản vitest → CI đỏ; CP-2/CP-3 đã implement ở dropins (26/26 test `verify-dropins`) |
| W-303 | F-009 | Test RLS "thử vượt quyền" trong dropins | Test đọc/ghi hàng của user khác → bị từ chối | — | M | ➖ hết hiệu lực (2026-09-12, ADR-0004) — dropins Supabase đã gỡ khỏi repo khung, không còn RLS mẫu để test |
| W-304 | F-010 | ADR + job tổng hợp `gate: needs: [...]` trong `ci.yml`; cập nhật `repository-settings.md` | ADR-0003 tồn tại; `check-ci-policy.sh` xanh; branch protection chỉ cần 1 tên | W-103 | M | ✅ `check-ci-policy.sh` §4 + NT: gỡ pin → rc=1 |
| W-305 | F-011 | Ràng `.nvmrc` ↔ mọi `node-version:` trong workflow | Lệch → đỏ; có negative test | — | S | ✅ `check-ci-policy.sh` §5 + NT: đổi node-version → rc=1 |
| W-306 | F-012 | Cập nhật `PROGRESS.md` (SHA, goal, nợ kỹ thuật) | Khớp `main` thật cuối lượt | mọi W | S | ⬜ |
| W-307 | F-013 | Comment `# cố ý KHÔNG -e` tại 8 file dùng `set -uo pipefail` | 8/8 file có comment; `CONVENTIONS.md` đã ghi (xong ở Pha 0) | — | S | ✅ 9/9 file `set -uo pipefail` có comment giải thích |
| W-308 | F-014 | Xoá nhánh đã merge; bật auto-delete branch | Còn `main` + nhánh đang mở; ô trong `repository-settings.md` được tick | W-101 | S | 🔄 đã tra cứu qua GitHub API: 31/32 nhánh có PR `merged_at` thật (danh sách dưới) — 1 nhánh (`claude/opusplan-model-config-2ojq58`, PR #28) **closed KHÔNG merge**, giữ lại. **Bị chặn xoá:** `git push --delete` bị auto-mode classifier từ chối (destructive git) — cần người dùng tự xoá qua GitHub UI/Settings→Branches, hoặc cấp quyền Bash cho lệnh này. Bật auto-delete branch vẫn `⬜` (thuộc `repository-settings.md`, cần chủ repo bật trên GitHub Settings). |
| W-309 | F-015 | `test-copy-framework.sh` báo RÕ khi bỏ qua `.ps1` (không im lặng) + CI khẳng định đã chạy | Máy không có pwsh → in cảnh báo nổi bật; CI có bước xác nhận đã test `.ps1` | — | S | ✅ cảnh báo nổi bật + `REQUIRE_PWSH=1` trên CI + NT: rc=1 khi thiếu pwsh |
| W-311 | F-016 | Gỡ 4 file giờ đã tồn tại thật (`docs/CONVENTIONS.md`, `docs/FEATURE-MAP.md`, `docs/ops/COMPLETION-PLAN.md`, `docs/ops/COMPREHENSIVE-AUDIT-STATUS.md`) khỏi `ALLOW_MISSING_PATH` | Xoá một trong 4 file → cổng đỏ | — | S | ✅ gỡ 4 file khỏi allowlist + NT: xoá `docs/FEATURE-MAP.md` → cổng đỏ |
| W-312 | F-017 | `check-docs-consistency.sh` dùng `git grep` nên **không quét file chưa `git add`** → lượt chạy local báo PASS oan (đã xảy ra thật trong phiên này) | Sửa tham chiếu gãy ở file chưa track → cổng vẫn bắt được | — | S | ✅ `git grep --untracked` + NT: file chưa track có link gãy → cổng đỏ |
| W-310 | Nhóm 11 | Quét nốt Nhóm 11 (`.env.example` ↔ `lib/env.ts`) ở phiên có quyền đọc `.env*` | `COMPREHENSIVE-AUDIT-STATUS.md` Nhóm 11 → ✅ | — | S | ✅ đối chiếu xong, 0 phát hiện mới — `COMPREHENSIVE-AUDIT-STATUS.md` Nhóm 11 → ✅ |

## Truy vết F → W

F-001→W-101,W-105 · F-002→W-201,W-202 · F-003→W-102,W-103 · F-004→W-203 · F-005→W-104 ·
F-006→W-301 · F-007→W-204 · F-008→W-302 · F-009→W-303 · F-010→W-304 · F-011→W-305 ·
F-012→W-306 · F-016→W-311 · F-017→W-312 · F-013→W-307 · F-014→W-308 · F-015→W-309 · Nhóm 11 (dở)→W-310


## Ghi chú thực thi (2026-09-12)

**W-101 bị chặn bởi W-106 — thứ tự FIFO phải nhường cho việc gỡ blocker.** Điều tra CI cho thấy
`pr-policy.yml: metadata` **fail trên mọi PR dependabot** từ 24/08 (2/2 lượt chạy của #53 đều đỏ):
required check này đòi PR body có 6 mục template, dependabot không điền được → không bao giờ xanh.
Vì vậy 5 PR không thể merge cho tới khi bản sửa `pr-policy.yml` (W-106) có mặt **trên `main`**.

**Kết quả sau khi W-106 vào `main` (PR #64, `1a2a45f`)** — giả thuyết được chứng minh: `metadata`
chuyển sang **xanh** trên từng PR dependabot ngay lượt chạy đầu sau `update_pull_request_branch`.
Merge theo đúng FIFO:

| PR | Nội dung | Squash | Bằng chứng đáng chú ý |
| --- | --- | --- | --- |
| #53 | `github-script` 7.0.1 → 9.0.0 | `862aaf5` | v9 có breaking change (`require('@actions/github')`); đã đọc 2 chỗ dùng — chỉ `core`/`github.rest`/`context` → không ảnh hưởng |
| #54 | `dependency-review-action` 4.9.0 → 5.0.0 | `a76805d` | `verify-dropins` không chạy (paths filter) — đúng, PR không chạm dropins |
| #55 | `gitleaks-action` 2.3.9 → 3.0.0 | `a528f6f` | job `gitleaks` **xanh bằng chính bản v3** — không chỉ tin release notes |
| #56 | `codeql-action/init` 4.37.8 → 4.37.9 | `e67e611` | job `analyze` xanh |
| #57 | `codeql-action/analyze` 4.37.8 → 4.37.9 | `67ce69b` | job `analyze` xanh |

**Nghiệm thu W-101 KHÔNG dựa vào "đã merge 5/5" mà đo lại trên `main`** — và lượt đo bắt được lỗi
thật: vẫn còn **một** `actions/github-script@v7.0.1` (node20) trong `.github/workflows/stale-pr-alert.yml`,
tức file do **chính PR #64 thêm vào** một giờ trước đó. PR #53 (tạo 24/08) chỉ phủ các file tồn tại
lúc nó được tạo. Đã nâng lên v9.0.0 (đã kiểm: script chỉ dùng `core`/`github.rest`/`github.paginate`/
`context` → không chạm breaking change của v9). Đo lại: **0 action node20 trên `main`**.
Khuôn bẫy ghi ở `TRAPS.md` mục 7.

**W-105 đã chọn cơ chế:** workflow theo lịch (tuần) thay vì nhắc trong `session-guide.sh` — hook
không nên gọi mạng (chậm, cần auth, và dự án đích có thể không có `gh`). Workflow đọc PR + check run
bằng `GITHUB_TOKEN` rồi mở/cập nhật **một** issue tổng hợp.

**W-302 đã chọn cơ chế:** hai bản kiểm **không** phải giống nhau (phạm vi khác thật — bản vitest
không giả định dự án đích có job `gate`). Thay vào đó mỗi kiểm có **ID `CP-*`**, và thêm/bỏ một ID ở
bản shell **buộc** phải khai ở bản vitest — implement, hoặc ghi "không áp dụng cho dự án đích: lý do".

**Còn mở (chưa làm trong đợt này, kèm lý do):**

| ID | Lý do hoãn |
| --- | --- |
| W-202 | Cần chạy thật `verify-dropins.sh` (npm install Next.js, nhiều phút) để kiểm chứng bước commit mới; không đẩy bước CI chưa được chạy thử — nguyên tắc "một push đã kiểm chứng hơn ba push phỏng đoán" |
| W-303 | ➖ Hết hiệu lực (2026-09-12, ADR-0004): dropins Supabase/RLS đã gỡ khỏi repo khung, không còn gì để viết test |
| W-107 | ✅ (mới, sinh trong lúc nghiệm thu W-101) Nâng `github-script` trong `stale-pr-alert.yml` v7.0.1 → v9.0.0 — file mới của #64 không nằm trong phạm vi PR #53 |
| W-306 | Làm cuối cùng, sau khi đợt này merge (SHA `main` chưa cố định) |
| W-308 | Xoá ~32 nhánh đã merge là thao tác trên remote, không hoàn tác dễ → xin xác nhận người dùng (`CLAUDE.md` §9) |
| W-310 | Môi trường phiên này chặn đọc `.env*` — cần phiên có quyền |
