# Feature spec: Sổ bẫy (TRAPS), bản đồ sửa-ở-đâu (CODEMAP) và cổng policy-as-check cho CI

| Thuộc tính | Giá trị |
| --- | --- |
| Issue / Goal | — (khởi phát từ lượt quét 15 repo của người dùng, 2026-09-12) |
| Spec owner | AI (Claude Code) |
| State | **Approved for implementation** |
| Approver / date | donghanhcungban.org@gmail.com / 2026-09-12 |
| Last updated | 2026-09-12 |

> Không code khi chưa **Approved for implementation**.

## 1. Problem, user và evidence

Người dùng là chủ sở hữu bộ khung này và của 15 repo dẫn xuất/lân cận. Lượt quét ngày 2026-09-12 cho thấy
**ba lỗ hổng có thật** của bộ khung, mỗi lỗ hổng đã được một repo hậu duệ tự vá theo cách riêng — nghĩa là
bài học đã tồn tại nhưng chưa chảy ngược về khung, nên mọi dự án đích mới sẽ mắc lại.

**Lỗ hổng A — không có nơi tích luỹ bài học qua thời gian.** Khung có `CONTEXT.md` (thuật ngữ),
`COMPLETION-PLAN` (một lượt hoàn thiện, đã đóng), `docs/adr/` (quyết định). Không file nào ghi *"lỗi này
đã xảy ra, đây là khuôn của nó, đây là cách rà, đây là test chốt chặn"*. Bằng chứng thượng nguồn:
`Claude-Agents/TRAPS.md` (161 dòng) ghi 5 khuôn lỗi có ngày + PR + cách rà + test chốt, và **quan trọng
nhất là ghi nhận tái phát**: mục "Khuôn 3" chép lại rằng cùng một bug khoá chống-trùng đã sống tiếp ở
orchestrator thứ hai nhiều ngày sau khi vá ở orchestrator thứ nhất, kèm hai bài học tổng quát hoá
("vá một khuôn thì vá ở mọi nơi sao chép cùng thiết kế"; "test canh quy ước phải nói rõ nó canh tới đâu").
Đó là loại tri thức mà `/debug` và `/completion` hiện phải suy lại từ đầu mỗi phiên.

**Lỗ hổng B — không có bảng tra "muốn đổi X thì sửa file nào, rồi phải chạy lại gì".** `/completion` sinh
`docs/FEATURE-MAP.md` (có tính năng gì) và `docs/CONVENTIONS.md` (quy ước). Cả hai trả lời "cái gì" và
"viết thế nào", không trả lời **"chạm vào đâu và sau đó phải chạy lại cổng nào"**. Bằng chứng thượng nguồn:
`CODEMAP.md` xuất hiện **độc lập ở 4 repo** (`Claude-Agents`, `Sales-Hunter`, `X-Agents`, `X-Studio`) với
cùng một hình dạng bảng 3 cột `Muốn | Sửa | Rồi chạy`. Bốn lần hội tụ độc lập là dấu hiệu mẫu này có giá trị
thật, không phải sở thích của một repo.

**Lỗ hổng C — cấu hình cổng merge của chính repo hỏng theo kiểu IM LẶNG, không ai canh.** Hai dữ kiện đã
xác minh trong repo này hôm nay:
1. `.github/workflows/ci.yml` có 6 job (`framework-lint`, `docs-consistency`, `copy-framework-smoke`,
   `quality`, `source-hygiene`, `e2e`) và **không có một `needs:` nào** — các job phẳng, độc lập. Nghĩa là
   branch protection phải liệt kê **đúng tên từng job**; không có job tổng hợp nào để gom. (Sửa
   2026-09-12: bản đầu ghi nhầm "5 job" — grep dùng lớp ký tự `[a-z-]` bỏ sót job `e2e` có chữ số;
   đã đối chiếu lại bằng cách liệt kê thật cả 8 workflow, xem CODEMAP.md khi có.)
2. `docs/ops/repository-settings.md` **không liệt kê tên job nào cả** — dòng 10 chỉ ghi
   "Required checks theo project profile". Nên **không tồn tại nguồn sự thật** cho danh sách required checks.

Hệ quả: đổi tên hoặc xoá một job id trong `ci.yml` sẽ làm required check cũ **không bao giờ báo cáo nữa** →
PR kẹt vĩnh viễn mà không PR nào hiện màu đỏ để lần ra nguyên nhân; hoặc ngược lại, thêm job cổng mới mà
quên thêm vào branch protection → cổng chạy nhưng **đỏ vẫn merge được**. Bằng chứng thượng nguồn:
`donghanh/scripts/ci-workflow-policy.test.ts` khoá đúng ba luật này, và comment đầu file ghi rõ lý do là
"hỏng theo kiểu IM LẶNG — workflow vẫn chạy, vẫn xanh, nhưng cổng merge của repo hỏng theo cách không ai
thấy cho tới lúc quá muộn".

## 2. Outcome, baseline, target và guardrails

| | Baseline (2026-09-12) | Target |
| --- | --- | --- |
| A | 0 nơi ghi bẫy đã mắc; `/debug` bắt đầu từ trang trắng mỗi lần | Có `TRAPS.template.md` + luật ghi bẫy sau mỗi lần sửa bug; `/debug` và `/completion` đọc `TRAPS.md` **trước** khi ra giả thuyết |
| B | 2/3 bảng tra (`FEATURE-MAP`, `CONVENTIONS`), thiếu cột "rồi chạy lại gì" | Có `CODEMAP.template.md`; `/completion` sinh cả 3; chính repo khung có `CODEMAP.md` thật của nó |
| C | 0 cổng canh cấu hình CI; 0 nguồn sự thật cho required checks | `docs/ops/repository-settings.md` liệt kê tên job; `scripts/check-ci-policy.sh` đối chiếu **hai chiều** và chạy trong job `docs-consistency` |

**Guardrails:** không tăng thời gian CI quá +10 s (C là grep trên 2 file text); không thêm phụ thuộc runtime
nào (repo khung không có `package.json` — xem §11); không đè file nào của dự án đích (`copy_if_absent`).

## 3. Research current state

Nguồn đã đọc trực tiếp (không suy đoán), đều là repo của chính người dùng, clone `--depth 1` ngày 2026-09-12:

| Nguồn | Dùng cho | Dữ kiện lấy ra |
| --- | --- | --- |
| `seeker19110/Claude-Agents` — `TRAPS.md`, `CODEMAP.md`, `ARCHITECTURE.md`, `.pre-commit-config.yaml` | A, B | Hình dạng mục bẫy (khuôn → cách rà → test chốt → ngày/PR → tái phát); bảng CODEMAP 3 cột; quy ước "chi tiết từng package ở `<pkg>/TRAPS.md`" |
| `seeker19110/donghanh` — `scripts/ci-workflow-policy.test.ts`, `ui-policy.test.ts`, `a11y-gate-policy.test.ts`, `.claude/report-status.sh` | C | Ba luật CI cần khoá; nguyên tắc **chỉ kiểm cấu trúc, không kiểm nội dung từng bước** ("ép nội dung sẽ biến test thành vật cản mỗi lần thêm một bước kiểm mới") |
| `seeker19110/X-Studio`, `X-Agents`, `Sales-Hunter` | B | `CODEMAP.md` hội tụ độc lập ở cả 3 |
| Repo này — `.github/workflows/ci.yml`, `docs/ops/repository-settings.md`, `scripts/check-docs-consistency.sh` (107 dòng), `.github/workflows/pr-policy.yml`, `vitest.config.mts`, `copy-framework.sh` | C, §11 | 6 job phẳng (kể cả `e2e`), 0 `needs:`; required checks chưa được liệt kê ở đâu; cổng của khung là **shell script**, không phải vitest |

**Ràng buộc then chốt phát hiện trong lúc research:** repo khung **không có `package.json`** (ghi rõ ở
`CLAUDE.md` §10, ghi chú cuối). Nên mẫu của `donghanh` (vitest policy test) **không port trực tiếp được**
vào chính repo khung. Đây là lý do §4 chọn Option B thay vì bê nguyên.

## 4. Alternatives và decision

| Option | Benefits | Cost/risk | Decision |
| --- | --- | --- | --- |
| Do nothing | 0 công | Ba lỗ hổng tiếp tục chảy xuống **mọi** dự án đích tương lai; lỗi C hỏng im lặng | ❌ |
| A. Copy nguyên `TRAPS.md`/`CODEMAP.md` + `ci-workflow-policy.test.ts` từ repo hậu duệ | Nhanh nhất | Copy **nội dung** của dự án khác vào khung là sai bản chất (khung phát template rỗng); vitest test không chạy được ở repo khung | ❌ |
| **B. Template rỗng cho A+B; cổng C viết bằng shell cho repo khung + bản vitest trong dropins cho dự án đích** | Đúng kiến trúc hiện có (`docs/framework/templates/` + `scripts/*.sh` + dropins); không thêm phụ thuộc | Phải viết 2 biến thể cho C (shell + ts) | ✅ **Chọn** |
| C. Chỉ làm A+B, bỏ C | Rẻ nhất | Bỏ đúng lỗ hổng nghiêm trọng nhất (hỏng im lặng, chặn merge toàn bộ PR) | ❌ |

Ghi chú chủ động (§2 CLAUDE.md): việc `ci.yml` không có `needs:` và **không có job tổng hợp** là một
quan sát đáng bàn riêng — thêm một job `gate: needs: [tất cả]` sẽ khiến branch protection chỉ cần khoá
**một** tên. Đó là thay đổi kiến trúc CI, **cố ý để ngoài phạm vi spec này** (xem §5) và nên đi bằng ADR.

## 5. Scope / non-goals

**Trong phạm vi**
1. `docs/framework/templates/TRAPS.template.md` (mới).
2. `docs/framework/templates/CODEMAP.template.md` (mới).
3. `TRAPS.md` + `CODEMAP.md` thật cho **chính repo khung** (điền từ lịch sử có thật: COMPLETION-PLAN, CHANGELOG, TRAPS đã biết như ERESOLVE `@types/node` ở `d0baf40`).
4. Nối vào quy trình: `.claude/commands/debug.md`, `.claude/commands/completion.md`, `docs/framework/project-completion.md`, `CLAUDE.md` §1 + §5/§6, `AGENTS.md`.
5. `docs/ops/repository-settings.md`: liệt kê **tên job** required checks (nguồn sự thật).
6. `scripts/check-ci-policy.sh` (mới) + nối vào job `docs-consistency` của `ci.yml`.
7. Bản dropins cho dự án đích: `scripts/ci-workflow-policy.test.ts` theo mẫu `donghanh` (chỉ kiểm cấu trúc).
8. CHANGELOG + PROGRESS.md.

**Non-goals (cố ý loại)**
- Gói D–I của lượt quét (script `check-*` của `xboss`, hook `block-dangerous-git.sh`, gitleaks pre-commit, gate-agent `sc-gate-*`, `eval-record.yml`) — **đợt sau**.
- Thêm job tổng hợp `gate` vào `ci.yml` hoặc đổi bất kỳ job id nào hiện có (xem §4).
- `ui-policy.test.ts` / `a11y-gate-policy.test.ts` của `donghanh` (thuộc gói D).
- Golden test và kỷ luật TDD — tách sang spec riêng `docs/specs/2026-09-12-golden-tests-and-tdd.md` (capability khác; chồng file ở `CLAUDE.md` và `quality-supplements.md`, xử lý theo FIFO §8).
- Bật branch protection thật trên GitHub (việc của người dùng; spec chỉ tạo nguồn sự thật để đối chiếu).

## 6. User journeys và mọi state

Dự án dạng tài liệu + script, "user" là AI trong phiên làm việc và người dùng.

| Journey | Hành vi mong đợi |
| --- | --- |
| Happy — gặp bug lạ | `/debug` đọc `TRAPS.md` trước tiên, khớp triệu chứng với khuôn cũ, tiết kiệm một vòng chẩn đoán |
| Happy — cần đổi một thứ | Tra `CODEMAP.md`: ra file cần sửa **và** cổng cần chạy lại |
| Empty — dự án đích mới copy khung | `TRAPS.md`/`CODEMAP.md` chưa tồn tại → template có dòng "chưa có mục nào; thêm mục đầu tiên khi…"; không có file thì `/debug` **không** được chặn, chỉ ghi nhận rồi tiếp tục |
| Error — job id đổi mà quên cập nhật danh sách | `check-ci-policy.sh` exit ≠ 0, in đúng tên job lệch và file cần sửa |
| Error — danh sách ghi tên job không tồn tại | Cùng script, báo chiều ngược lại |
| Conflict — dự án đích đã có `CODEMAP.md` riêng | `copy-framework.sh` `copy_if_absent` → không đè |
| Recovery — bẫy tái phát | Template yêu cầu **thêm ngày/PR vào mục cũ**, không tạo mục mới (mẫu `Claude-Agents`) |

## 7. Functional requirements

- **FR-1** `TRAPS.template.md` tồn tại, mỗi mục có đủ 5 trường: triệu chứng/khuôn · vì sao im lặng · cách rà · test/cổng chốt chặn · ngày + PR (và mục "tái phát" nếu có).
- **FR-2** `CODEMAP.template.md` tồn tại, bảng 3 cột `Muốn | Sửa | Rồi chạy`, kèm hướng dẫn tách theo package/khu vực khi repo lớn.
- **FR-3** Repo khung có `TRAPS.md` + `CODEMAP.md` thật, mọi mục **có thật, truy được về commit/PR** — không mục minh hoạ hư cấu.
- **FR-4** `/debug` đọc `TRAPS.md` (nếu có) ở bước dựng feedback loop, **trước** khi ra giả thuyết; kết thúc bằng việc ghi mục mới.
- **FR-5** `/completion` sinh/cập nhật `CODEMAP.md` cùng lượt với `FEATURE-MAP.md` và `CONVENTIONS.md`.
- **FR-6** `docs/ops/repository-settings.md` liệt kê **tên job** required checks của `ci.yml` + `pr-policy.yml`.
- **FR-7** `scripts/check-ci-policy.sh` đối chiếu hai chiều job id ↔ danh sách FR-6; exit 1 khi lệch, in tên job lệch + file cần sửa.
- **FR-8** `check-ci-policy.sh` chạy trong job `docs-consistency` của `ci.yml`.
- **FR-9** Bản vitest `ci-workflow-policy.test.ts` nằm ở dropins, khoá job id + `needs` + chia mảnh E2E cho dự án đích hồ sơ Web.
- **FR-10** `copy-framework.sh`/`.ps1` phát 2 template mới và bản dropins; `check-docs-consistency.sh` vẫn PASS.

## 8. Non-functional requirements

- **Security/privacy:** không file nào chứa secret/tên host nội bộ. `TRAPS.md` ghi bẫy kỹ thuật — template cảnh báo rõ **không dán giá trị token/khoá thật** vào mục bẫy, chỉ ghi vị trí.
- **Performance:** `check-ci-policy.sh` là grep/sed trên 2 file YAML → mục tiêu < 1 s, ngân sách CI +10 s.
- **Reliability:** script dùng `set -euo pipefail`, không phụ thuộc thư viện YAML (cùng lối `check-docs-consistency.sh` đang dùng).
- **Compatibility:** `bash` + coreutils, như 5 script hiện có. Không thêm dependency.
- **Cost:** 0 (không gọi API, không thêm job CI mới).
- **A11y:** không áp dụng (không có UI).

## 9. Acceptance criteria

| AC | Given / When / Then | Bằng chứng |
| --- | --- | --- |
| AC-1 | Given repo sạch · When `bash scripts/check-ci-policy.sh` · Then exit 0 | chạy thật, dán output |
| AC-2 | Given đổi `quality:` → `quality-x:` trong `ci.yml` · When chạy script · Then exit 1 và in `quality` là job thiếu trong `repository-settings.md` | thử nghiệm nghịch (negative test), hoàn nguyên sau |
| AC-3 | Given thêm tên job không tồn tại vào `repository-settings.md` · When chạy script · Then exit 1 chiều ngược lại | như trên |
| AC-4 | Given `bash scripts/check-docs-consistency.sh` · Then vẫn PASS sau mọi thay đổi tài liệu | chạy thật |
| AC-5 | Given `bash scripts/test-copy-framework.sh` · Then 2 template mới + dropins có mặt ở đích, không đè file có sẵn | chạy thật |
| AC-6 | Given `TRAPS.md` của repo khung · Then **mọi** mục trỏ tới commit/PR có thật (`git log` xác minh được) | kiểm từng mục |
| AC-7 | Given `/debug` và `/completion` · Then `check-docs-consistency.sh` thấy TRIGGER khai trong `CLAUDE.md` khớp, và `CLAUDE.md` §1 trỏ tới 2 template mới | cổng tự động |
| AC-8 | Given `scripts/verify-dropins.sh` · Then bản `ci-workflow-policy.test.ts` trong dropins lint + type-check + chạy được trên dự án Next.js sạch | chạy thật (đây là cổng duy nhất biên dịch dropins) |

## 10. UX/content/accessibility

Tài liệu tiếng Việt, tên file tiếng Anh — đúng quy ước đang dùng (`docs/framework/README.md`). Template phải
**ngắn và điền được ngay**: `TRAPS.template.md` ≤ 60 dòng, `CODEMAP.template.md` ≤ 50 dòng. Mỗi template mở
đầu bằng 2–3 dòng "file này dùng khi nào / không dùng để làm gì" để AI phiên sau không nhầm vai với
`CONVENTIONS.md` hay `docs/adr/`.

## 11. Architecture và code touchpoints

| Muốn | Sửa | Rồi chạy |
| --- | --- | --- |
| Thêm template TRAPS/CODEMAP | `docs/framework/templates/{TRAPS,CODEMAP}.template.md` (mới) | `scripts/test-copy-framework.sh` |
| Điền bẫy/bản đồ thật của khung | `TRAPS.md`, `CODEMAP.md` (mới, ở gốc) | — |
| Nối vào quy trình | `.claude/commands/debug.md`, `.claude/commands/completion.md`, `docs/framework/project-completion.md`, `CLAUDE.md` §1/§5/§6, `AGENTS.md` | `scripts/check-docs-consistency.sh` |
| Nguồn sự thật required checks | `docs/ops/repository-settings.md` | `scripts/check-ci-policy.sh` |
| Cổng canh cấu hình CI | `scripts/check-ci-policy.sh` (mới) + job `docs-consistency` trong `.github/workflows/ci.yml` | mở PR để chạy thật |
| Bản cho dự án đích | `scripts/ci-workflow-policy.test.ts` (mới, vào dropins) | `scripts/verify-dropins.sh` |

**Quyết định kỹ thuật:** C viết **shell** cho repo khung (không có `package.json` → không chạy được vitest)
và **vitest** cho dự án đích (đã có `vitest.config.mts` trong dropins). Hai biến thể là **cố ý**, phải ghi
một dòng lý do ở đầu cả hai file, kèm trỏ chéo — nếu không, người sau sẽ thấy trùng lặp rồi gộp nhầm.
`check-ci-policy.sh` **chỉ kiểm cấu trúc** (job id, sự tồn tại trong danh sách), không kiểm nội dung bước —
theo đúng lý do `donghanh` ghi trong file gốc.

## 12. API/event contract

Không có API. Hợp đồng duy nhất là **exit code + định dạng output** của `check-ci-policy.sh`: 0 = đạt,
1 = lệch (in danh sách lệch theo từng chiều, kèm đường dẫn file cần sửa), ≥ 2 = lỗi môi trường
(thiếu file đầu vào). Định dạng output theo cùng lối `check-docs-consistency.sh` để đọc log CI thống nhất.

## 13. Data contract/migration

Không có schema/CSDL. "Migration" duy nhất: dự án đích đã copy khung bản cũ sẽ **không** tự có 2 file mới —
`docs/framework/FRAMEWORK-VERSION` + CHANGELOG là cơ chế để họ biết cần copy lại (đã có sẵn, không đổi).

## 14. Security/privacy/abuse cases

- `TRAPS.md` là nơi dễ vô tình dán chuỗi bí mật khi kể lại bug xác thực → template ghi cảnh báo rõ; `secret-scan.yml` + `gitleaks` vẫn là hàng rào sau cùng.
- `check-ci-policy.sh` chỉ **đọc** file trong repo, không gọi mạng, không nhận input ngoài.
- Abuse: người/AI có thể "làm xanh" cổng C bằng cách xoá tên job khỏi cả hai phía. Không chống được bằng script; giảm nhẹ bằng việc `repository-settings.md` là file cần review trong PR.

## 15. Observability và operations

Không có runtime service. Quan sát được qua: log job `docs-consistency` trên mỗi PR; `TRAPS.md` chính là
"sổ sự cố" của repo. Owner: người dùng. Runbook: khi cổng C đỏ → đọc output → sửa **một** trong hai phía
cho khớp, rồi cập nhật branch protection thật trên GitHub nếu đó là thay đổi cố ý.

## 16. Test/eval plan

| Loại | Nội dung |
| --- | --- |
| Cổng có sẵn | `check-docs-consistency.sh`, `test-copy-framework.sh`, `verify-dropins.sh` — cả 3 phải xanh |
| Negative test (bắt buộc) | AC-2 và AC-3: **cố ý làm lệch** rồi xác nhận script đỏ, sau đó hoàn nguyên. Cổng chưa bao giờ thấy đỏ là cổng chưa được kiểm chứng |
| Kiểm chứng nội dung | AC-6: đối chiếu từng mục `TRAPS.md` với `git log` |
| CI thật | Job `docs-consistency` chạy trên PR |
| Không cần | E2E, a11y, perf, migration, AI eval (không có UI/dữ liệu/LLM trong phạm vi) |

## 17. Slice/PR plan

Một outcome / một PR, thứ tự có phụ thuộc:

| PR | Nội dung | Phụ thuộc | Nhãn route |
| --- | --- | --- | --- |
| PR-1 | **C** — `repository-settings.md` liệt kê job + `check-ci-policy.sh` + nối `ci.yml` + negative test | — | `route:spec` |
| PR-2 | **A** — `TRAPS.template.md` + `TRAPS.md` thật + nối `/debug`, `CLAUDE.md`, `AGENTS.md` | PR-1 merge (tránh trùng `ci.yml`/`CLAUDE.md`) | `route:standard` |
| PR-3 | **B** — `CODEMAP.template.md` + `CODEMAP.md` thật + nối `/completion`, `project-completion.md` | PR-2 merge | `route:standard` |
| PR-4 | Dropins `ci-workflow-policy.test.ts` + `copy-framework.*` phát file mới + `verify-dropins.sh` | PR-1..3 merge | `route:standard` |

Làm C trước vì nó là lỗ hổng nghiêm trọng nhất và độc lập nhất. **FIFO, không nhảy cóc** (CLAUDE.md §8).

## 18. Rollout/rollback

Không có staging/flag (thay đổi tài liệu + 1 script CI). Rollout = merge squash tuần tự PR-1→PR-4.
Rollback = `git revert` từng PR; mỗi PR độc lập revert được. Rủi ro triển khai duy nhất: PR-1 làm job
`docs-consistency` đỏ trên các PR **đang mở** khác — hiện không có PR nào mở, nên bằng 0.

### Mục CHANGELOG sẽ thêm khi thực thi (vào `## [Unreleased]` → `### Added`)

```
- **Sổ bẫy + bản đồ sửa-ở-đâu + cổng canh cấu hình CI** (gói A+B+C, spec
  `docs/specs/2026-09-12-traps-codemap-ci-policy.md`): thêm
  `docs/framework/templates/TRAPS.template.md` (ghi bẫy ĐÃ mắc thật: khuôn → cách rà → test chốt
  → ngày/PR, kèm mục tái phát) và `CODEMAP.template.md` (bảng `Muốn | Sửa | Rồi chạy` — mảnh còn
  thiếu giữa FEATURE-MAP "có gì" và CONVENTIONS "viết thế nào"); `/debug` đọc `TRAPS.md` trước khi
  ra giả thuyết, `/completion` sinh CODEMAP cùng lượt với 2 file kia. Thêm
  `scripts/check-ci-policy.sh` đối chiếu HAI CHIỀU giữa job id trong `ci.yml` và danh sách required
  checks trong `docs/ops/repository-settings.md` — trước đây danh sách này KHÔNG tồn tại ở đâu, nên
  đổi tên một job id sẽ làm required check cũ không bao giờ báo cáo nữa và kẹt merge toàn bộ PR mà
  không PR nào hiện màu đỏ. Bản vitest tương đương cho dự án đích nằm trong dropins.
  Nguồn: rút từ `Claude-Agents` (TRAPS/CODEMAP) và `donghanh` (policy-as-test).
```

## 19. Risk, assumptions và open decisions

| Item | Verification/mitigation | Owner | Due | Decision |
| --- | --- | --- | --- | --- |
| `TRAPS.md`/`CODEMAP.md` thành tài liệu chết (viết một lần rồi thôi) | Nối vào **quy trình**, không chỉ tạo file: `/debug` đọc+ghi, `/completion` sinh lại; `check-docs-consistency.sh` canh phần khai báo | AI | PR-2/3 | Chấp nhận rủi ro còn lại |
| Bịa mục bẫy cho "đẹp template" | AC-6 buộc mọi mục truy được về `git log`; template ghi rõ "không phải danh sách nên tránh chung chung" | AI | PR-2 | Đã khoá bằng AC |
| Hai biến thể C (shell + ts) lệch nhau về sau | Ghi lý do + trỏ chéo ở đầu cả hai file; thêm dòng vào `CODEMAP.md` | AI | PR-4 | Chấp nhận |
| Người dùng chưa bật branch protection thật → danh sách FR-6 là danh sách "mong muốn" | Ghi rõ trong `repository-settings.md` rằng đây là nguồn sự thật **phải** khớp cấu hình GitHub; việc bật là của người dùng | Người dùng | khi triển khai thật | Ngoài phạm vi spec |
| Có nên thêm job tổng hợp `gate: needs: [...]` vào `ci.yml`? | **Không blocking** cho spec này (§4/§5 loại khỏi phạm vi); nếu muốn thì đi bằng ADR riêng | Người dùng | sau | **Để mở, không chặn approve** |

Không còn blocking decision.

## Approval

- [ ] Product/scope
- [ ] UX/a11y — _không áp dụng (không có UI), xác nhận bỏ qua_
- [ ] Architecture/API/data
- [ ] Security/privacy/cost
- [ ] Test/telemetry/rollout/rollback
- [ ] Blocking decisions closed

**Conclusion:** **Approved for implementation**
**Approver/date:** donghanhcungban.org@gmail.com / 2026-09-12

<!-- contract-exempt: scripts/verify-dropins.sh — gỡ khỏi repo khung theo ADR-0004 (bỏ scaffold Web mặc định, commit 98546db); spec này viết TRƯỚC quyết định đó nên giữ nguyên làm hồ sơ lịch sử -->
<!-- contract-exempt: package.json — file của DỰ ÁN ĐÍCH, repo khung cố ý không có (CLAUDE.md §10) -->
<!-- contract-exempt: .claude/commands/completion.md — gộp vào `.claude/commands/auto-complete.md` 2026-10-12 (docs/specs/2026-10-12-gop-auto-completion.md); spec này viết TRƯỚC quyết định đó nên giữ nguyên làm hồ sơ lịch sử -->
