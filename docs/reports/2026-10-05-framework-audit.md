# Rà soát năng lực bộ khung — 2026-10-05

> Phạm vi: chính repo khung, không phải một ứng dụng được tạo từ khung.
> `PROJECT.md` chưa khai sản phẩm cụ thể; vì vậy đây là phép đối chiếu code,
> CI, tài liệu và cấu hình repo. Các nhóm cần UI, dữ liệu người dùng hoặc triển
> khai sản phẩm được ghi N/A thay vì giả định đã đạt.

## Căn cứ snapshot ban đầu

- Base lúc bắt đầu: `f31c912`; PR #184 đưa `main` lên
  `a8dbd446684d34171987e04d49bdee580995e674`.
- Đọc code/cổng đang chạy: `scripts/maintenance-sweep.sh`,
  `scripts/test-maintenance-sweep.sh`, `scripts/test-py-coverage.sh`,
  `.github/workflows/{ci,dependency-review,maintenance}.yml`,
  `.github/rulesets/main.json`, `.gitignore` và `docs/FEATURE-MAP.md`.
- `scripts/dev-task.sh gate` đã PASS trên toolchain đầy đủ ngày 2026-10-05,
  với 96% độ phủ Python và 10 bài runtime safety. Kết quả này đo base/nhánh
  đang làm; CI trên commit cuối của từng PR phải được kiểm riêng.
- Ruleset live qua GitHub API: active, yêu cầu PR + `gate` + `metadata`;
  ban đầu `strict=false` dù file khai `true`. Đã đổi live thành
  `strict=true` và đọc lại effective branch rules cùng ngày. Regression
  `protection-guard` thuộc W-04 vẫn cần merge.
- Sau snapshot, F-K07 đã đóng trên `main` bởi PR #185 (`8f4a181`): hai
  job Analyze, Linux/Windows, `gate` và metadata đều xanh trên head cuối;
  PR #186 trùng thay đổi đã đóng.

## 12 nhóm — snapshot ban đầu

| Nhóm | Đối chiếu theo năng lực khung | Kết cục |
| --- | --- | --- |
| 1. Kiến trúc & thiết kế | Lớp khung/copy, engine và các cổng được khai trong `CODEMAP.md`; không có app runtime. | Không phát hiện Cao; C01 adoption sản phẩm thật còn mở. |
| 2. Bảo mật | Secret scan/CodeQL/ruleset đang chạy; báo cáo bảo trì có thể in dòng chứa chuỗi giống bí mật (F-K01). | Trung, sửa. |
| 3. Chất lượng mã & logic | Cổng độ phức tạp, runtime regression có hiệu lực; bộ quét dependency chỉ chọn hệ sinh thái đầu tiên (F-K03). | Trung, sửa. |
| 4. Kiểm thử & coverage | Gate đạt 96% Python nhưng probe CLI bỏ qua mã thoát kể cả đường thành công (F-K05); lệnh lint cho phép ShellCheck đỏ bị lệnh sau che (F-K10). | Trung, sửa để tín hiệu gate đáng tin. |
| 5. Hiệu năng | Không có yêu cầu tải/độ trễ cho sản phẩm trong `PROJECT.md`; copy và CLI chạy trong CI. | N/A cho benchmark ứng dụng; xem lại khi có dự án đích. |
| 6. Accessibility & UI/UX | Repo không có giao diện sản phẩm; UI intelligence chỉ là hook opt-in. | N/A; kiểm trên dự án có UI. |
| 7. Dependency & chuỗi cung ứng | Dependency review xanh nhưng skip `scripts/requirements-ci.txt` và manifest lồng trong monorepo (F-K02); CodeQL #185/#186 đỏ do lệch version sub-action. | Trung, sửa. |
| 8. CI/CD & vận hành | Required `gate`/`metadata` và CI Linux/Windows hiện diện; live strict từng lệch contract (F-K06), pre-commit hook làm hỏng test repo tạm (F-K09). | Trung, sửa và kiểm CI cuối. |
| 9. Tài liệu & đồng bộ | `FEATURE-MAP.md` ghi 13/9/5/7 trong khi file thật là 16/11/9/9; goal F-11 còn mở. | Trung, cập nhật và đối chiếu. |
| 10. Dữ liệu & migration | Không có DB/migration sản phẩm. Runtime tests kiểm giữ file/manifest khi nâng cấp. | N/A cho dữ liệu sản phẩm; giữ bằng chứng an toàn nâng cấp. |
| 11. Cấu hình môi trường & bí mật | `.gitignore` không bỏ qua `.env.production`/`.env.staging` (F-K04), dù pre-commit và sweep có cổng phụ. | Trung, sửa. |
| 12. Thống nhất chéo tính năng | `FEATURE-MAP`, `PROGRESS`, goal và ruleset live cần khớp code/GitHub; PR CodeQL tách version cho thấy thiếu grouping. | Trung, cập nhật cùng các PR tương ứng. |

## Phát hiện có thể hành động

| ID | Vị trí và bằng chứng | Rủi ro nếu giữ | Việc và tiêu chí đóng |
| --- | --- | --- | --- |
| F-K01 | `scripts/maintenance-sweep.sh` mục `sweep_hygiene` đưa tối đa 10 dòng grep vào báo cáo; `maintenance.yml` sao chép báo cáo ra summary/issue. | Giá trị nghi là token đi từ file được theo dõi sang bề mặt rộng hơn. | Chỉ xuất đường dẫn/dòng/loại; test đỏ trước với mẫu giả, bảo đảm báo cáo không chứa giá trị. |
| F-K02 | `dependency-review.yml` chỉ thử tên manifest ở gốc; `scripts/requirements-ci.txt` bị bỏ. Run PR #184 in notice “Framework source has no project manifest”. | Review xanh giả khi CI dependency hoặc package lồng đổi. | Nhận diện các manifest/lockfile được hỗ trợ ở đường dẫn con; negative test bỏ lọt và CI head cuối. |
| F-K03 | `maintenance-sweep.sh` `detect_deps_cmd` trả ngay sau hệ sinh thái gốc đầu tiên. | Báo cáo bỏ sót dependency ở repo đa stack; trái tuyên bố monorepo C10. | Chốt contract quét nhiều stack, test fixture hai hệ và thư mục con, giữ báo cáo/mức cảnh báo đúng. |
| F-K04 | `.gitignore` chỉ có `.env` và `.env*.local`; `git check-ignore --no-index .env.production .env.staging` không khớp. | Dễ đưa file môi trường thật vào staging. | Bỏ qua các biến thể `.env*`, giữ mẫu `.env.example`/`.sample`/`.template`; test `check-ignore`. |
| F-K05 | `test-py-coverage.sh` hàm `run` dùng `|| true` cho cả happy path; % coverage không chứng minh mã thoát 0. | CLI hỏng vẫn có thể được tính phủ. | Phân biệt probe kỳ vọng thành công/lỗi; regression cho mã thoát và full gate. |
| F-K06 | API ruleset trả `strict=false` trong khi `.github/rulesets/main.json` khai `true`; `protection-guard` chưa đối chiếu tham số. | PR có thể merge khi không cập nhật base. | Live `strict=true`, test false đỏ/true xanh, CI trên PR W-04 xanh. |
| F-K07 | #185/#186 nâng `github/codeql-action/init` và `analyze` riêng; log CodeQL báo version 4.38.1/4.38.2 không khớp. | Check CodeQL đỏ, chặn merge và tạo hai PR thừa. | Một PR cập nhật cả hai bước cùng SHA, Dependabot grouping, hai Analyze xanh; đóng PR trùng. |
| F-K08 | `FEATURE-MAP.md` và goal/PROGRESS ghi số lượng/trạng thái cũ. | Nghiệm thu F-11 sai. | Bản đồ đếm đúng file thật, goal/PROGRESS gắn SHA và bằng chứng mới. |
| F-K09 | `scripts/githooks/pre-commit` gọi `dev-task.sh gate` khi còn biến Git của hook. Lần commit 2026-10-05 khiến test tạo repo tạm lỗi và cấu hình Git chung đổi `core.bare=true`; đã khôi phục `false`. | Commit bị chặn oan và các worktree cùng repo có thể ngừng hoạt động trong lúc test. | Test đỏ trước cho môi trường hook, dọn biến Git nội bộ trước khi chạy gate, xác nhận repo tạm và config chung không bị đổi. |
| F-K10 | `.claude/project-commands.sh` khai `lint='... shellcheck ...; bash check-docs; bash check-ci'`; dấu `;` làm mã thoát ShellCheck bị lệnh cuối che. Chạy ShellCheck trực tiếp hiện báo SC2154 ở `test-hooks-gate.sh`, trong khi gate vẫn xanh. | Gate báo PASS dù có cảnh báo lint, trái điều kiện 0 warning. | Nối fail-closed, xử lý cảnh báo hiện hữu, negative test ShellCheck đỏ phải làm `dev-task.sh lint/gate` đỏ. |

Không ghi “Project Complete” từ audit này. F-K01..10 và giới hạn C01/C02
cần được nghiệm thu theo PR, rồi quét lại một lượt trên `main`.

---

## Re-audit sau các slice — 2026-10-05

### Căn cứ và trạng thái

Main nguồn đã đối chiếu: `6702994d90ad318142715aa172d79916c71e5b9d` (#196).
PR #188–196 đã merge; F-K01..07/F-K09/F-K10 có kết cục trên main.
F-K08/F-11 được bàn giao trong PR tài liệu này, có hiệu lực khi bản này vào main.
#196 ban đầu Windows thất bại trên head `71a4d3c` vì fixture yêu cầu ShellCheck;
fixture được sửa và head cuối `8b97ee6` đạt Linux/Windows và gate (run 37323540706),
docs/copy/protection, metadata, CodeQL, dependency-review và gitleaks SUCCESS.
`progress-freshness` SKIPPED trên PR theo điều kiện main-only. Full local gate
và hook pre-commit trên diff source cuối PASS, coverage Python tổng 96%, 10 runtime tests.
Live main rules: strict=true, required gate+metadata; GitHub open Dependabot alerts: 0.
Sweep `maintenance-sweep.sh --strict --no-deps` exit0, 0 đỏ/2 vàng: 7 file hồ sơ
chưa commit và 1 nhánh local đã merge còn nằm trong worktree. Sweep bỏ qua dependency
và gate; không gọi nó là full dependency audit. Cổng final của docs được ghi ở PR này.

### 12 nhóm sau re-audit

| Nhóm | Kết quả hiện hành trên main #196 / hồ sơ này | Kết cục / residual |
| --- | --- | --- |
| 1. Kiến trúc & thiết kế | Không có app runtime; lớp copy và engine được mô tả trong bản đồ. | Không phát hiện Cao; C01 còn chờ adoption trên sản phẩm thật. |
| 2. Bảo mật | Credential redaction và ignore env variants đã merge. | F-K01 #190, F-K04 #191 đóng; tiếp tục rà khi mở rộng output/log hay thêm loại secret. |
| 3. Chất lượng mã & logic | Sweep quét mọi ecosystem đã nhận diện. | F-K03 #194 đóng; cần fixture mới khi thêm package manager/monorepo layout khác. |
| 4. Kiểm thử & coverage | Happy-path coverage probes fail đúng; command lint fail-closed đã merge #196. | F-K05 #193 đóng; F-K10 #196 đóng, head cuối xanh trên Linux/Windows và required checks. |
| 5. Hiệu năng | Không có app/service để đo benchmark sản phẩm. | N/A; xem lại khi có dự án đích với mục tiêu tải/độ trễ. |
| 6. Accessibility & UI/UX | Không có giao diện sản phẩm trong repo khung. | N/A; kiểm trên dự án đích có UI. |
| 7. Dependency & chuỗi cung ứng | Phát hiện manifest lồng đã được thêm vào dependency review; CodeQL đã đồng bộ. | F-K02 #192, F-K07 #185 đóng; còn giới hạn hosted CI của dự án đích. |
| 8. CI/CD & vận hành | Guard strict ruleset và cô lập Git hook env đã merge. | F-K06 #188, F-K09 #189 đóng; F-K10/#196 đóng; tiếp tục đối chiếu ruleset sau mỗi lần đổi settings. |
| 9. Tài liệu & đồng bộ | Bản đồ đã được sửa ở working diff cho đúng file thật. | F-K08/F-11 được bàn giao ở PR này, đóng khi bản này vào main; tiếp tục reconcile counts mỗi khi thêm/xóa artifact. |
| 10. Dữ liệu & migration | Repo khung không có dữ liệu ứng dụng/migration. Upgrade safety có regression cũ. | N/A cho dữ liệu sản phẩm; đánh giá lại khi consumer thêm migration/dữ liệu thật. |
| 11. Cấu hình môi trường & bí mật | `.env` variants được ignore; secret scan và sweep là lớp bổ sung. | F-K04 #191 đóng; xác minh lại ignore policy khi thêm biến thể template mới. |
| 12. Thống nhất chéo tính năng | F-K01..07/09 đã đối chiếu; map/goal thay đổi trong PR đang mở. | F-K08/F-11 theo PR bàn giao này; W-07 WAITING. |

### F-K01..10 — PR closure ledger

| Finding | PR / kết cục | Regression / evidence | State |
| --- | --- | --- | --- |
| F-K01 | #190 `54425a2`, merged | Maintenance report redacts credential-like values; framework CI/security checks passed. | CLOSED |
| F-K02 | #192 `b368f7e`, merged | Nested tracked dependency manifests are detected; PR checks passed. | CLOSED |
| F-K03 | #194 `4bf9504`, merged | Sweep handles every detected dependency ecosystem; PR checks passed. | CLOSED |
| F-K04 | #191 `0ddb4e8`, merged | Ignore variants regression; PR checks passed. | CLOSED |
| F-K05 | #193 `6bfbb3a`, merged | Coverage probes distinguish expected failures from successful probes; PR checks passed. | CLOSED |
| F-K06 | #188 `bec5795`, merged | Protection guard compares live strict setting with repository ruleset; negative/positive tests; live setting reread as `true`. | CLOSED |
| F-K07 | #185 `8f4a181`, merged | Both CodeQL Analyze jobs green on aligned versions; duplicate #186 closed. | CLOSED |
| F-K08 | PR tài liệu này | FEATURE-MAP/goal/PROGRESS đã đối chiếu; cổng PR bàn giao xác minh diff. | CLOSED khi bản này vào main |
| F-K09 | #189 `4b51643`, merged | Git hook environment isolation regression; PR checks passed. | CLOSED |
| F-K10 | #196 `6702994`, merged | `scripts/test-dev-task.sh` ca 8; lint thật và fixture Windows scoped. CI cuối trên head `8b97ee6` xanh. | CLOSED |

For PRs #188–196, required checks reported success on the respective final heads;
`progress-freshness` was skipped where its main-only condition applied. Do not infer
these results apply to later commits or to hosted CI in a consumer repository.

### W-06 evidence matrix: copy, resolver, runtime, hosted CI

| Evidence source | Actual runtime tested | Resolver/fixture-only coverage | Hosted CI in target repo |
| --- | --- | --- | --- |
| `scripts/test-dev-task.sh` | `dev-task.sh` itself runs. One real Node gate fixture executes Node checks/test and proves red on wrong arithmetic, green after correction. | `--print` resolver cases cover Node with npm/Bun/pnpm; Python with venv/uv/Poetry/PATH; Rust, Java/Maven, Kotlin/Gradle, .NET, Flutter, Dart, PHP, Ruby, Elixir, Deno and Swift. This confirms selected command strings on marker fixtures; it does not run each ecosystem's build/test. Some fixture binaries are stubs. Gate/doctor contract tests use `true`, sentinel and deliberately invalid fixture commands. | No. Framework CI runs these tests against fixtures. |
| Go và Make | Chưa chạy runtime trong ma trận này. | Resolver có trong `scripts/dev-task.sh` nhưng chưa có ca resolver độc lập trong `scripts/test-dev-task.sh`. Go xuất hiện trong fixture quét dependency; đó không chứng minh gate Go chạy thật. | Chưa kiểm. |
| `scripts/test-adoption-smoke.sh` | Copies to minimal Node and Python target fixtures. Real Node/Python commands execute build/lint/test; each fixture gate fails on incorrect arithmetic and passes after correction. Exercises clean-clone config behavior. | CI drop-in checks are offline structural assertions (required gate call, pinned actions, referenced files); they do not execute GitHub Actions. PowerShell copy/parity runs only where `pwsh` exists and is required in framework CI. | No; the script itself says hosted CI requires a separate target repository. |

Accordingly, W-06 is complete only for the two minimal Node/Python target fixtures
and the listed resolver behavior. C01 remains open until adoption is exercised on an
actual product repository. Revisit hosted workflow behavior after a target repo exists;
add stack-specific runnable fixtures when the corresponding consumer profile is in
scope. Full three-tier PLAN execution also remains untested end-to-end.

### Residual risks and revisit triggers

- **C01: no actual product adoption.** Revisit when a consumer repo is selected; copy,
  configure, run its own full gate, and observe a hosted CI run before claiming adoption.
- **Hosted CI and other stacks:** offline YAML checks and resolver selection do not prove
  GitHub execution or runtime correctness for every language. Add target CI evidence when
  a consumer repository and stack are in scope.
- **Three-tier orchestration:** dispatcher CLI/payload tests are not agent execution.
  Revisit when a safe authorized harness is available to run a complete PLAN end-to-end.
- **Audit sweep:** `--strict --no-deps` returned 0 red and 2 yellow; dependency checks were
  omitted. Do not describe this as a full dependency sweep or substitute it for CI.

## Đối chiếu Definition of Complete của chu kỳ

| Tiêu chí | Bằng chứng / kết cục |
| --- | --- |
| F-01..11 và F-K01..10 truy vết | Goal và ledger trên; F-11/F-K08 bàn giao ở PR này |
| 12 nhóm, không Cao mở | Bảng re-audit; không phát hiện Cao/Trung mới trong phần đã rà; nhóm sản phẩm N/A có lý do |
| Live protection khớp | API strict=true, gate+metadata; #188 negative/positive regression và CI |
| Gate/CI chặn thật | Source full local gate+hook PASS; CI #196 head `8b97ee6` SUCCESS; cổng PR tài liệu kiểm diff cuối |
| Tài liệu khớp | FEATURE-MAP/CODEMAP/quy ước đã soát; PROGRESS và goal ghi source SHA; không bịa product trong PROJECT |
| Giới hạn có quyết định | C01 ngoài phạm vi; C02 runtime/hosted CI còn giới hạn; các rủi ro có trigger ở PROGRESS và ma trận trên |
| Xác nhận đóng chu kỳ | Chờ người dùng sau CI/merge hồ sơ, theo Pha 4 `docs/framework/project-completion.md` |

Không suy ra Project Complete cho mọi sản phẩm dẫn xuất. Chu kỳ ở trạng thái
WAITING; các giới hạn được bàn giao tường minh.
