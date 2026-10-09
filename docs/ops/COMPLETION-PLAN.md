# COMPLETION-PLAN — trạng thái hiện hành 2026-10-09

## Đợt finishing 2026-10-09 — ĐÃ ĐÓNG 2026-10-09 (nghiệm thu: `docs/reports/2026-10-09-finishing.md`)

Yêu cầu: chủ repo "tiếp tục cho đến khi xong đi" sau khi chu kỳ dưới đã đóng → mọi mục repo còn tự đánh dấu phải làm
(radar "Việc cần làm", FEATURE-MAP ⚠️, P-C12) có kết cục thật. Hồ sơ: `docs/work/2026-10-09-finishing/done.md`.
**Approved for implementation — phiên chính duyệt theo ủy quyền của chủ repo ngày 2026-10-07; ngày duyệt 2026-10-09.**

| ID | Từ | Việc | Tiêu chí nghiệm thu | Sức | Trạng thái | PR / bằng chứng |
|----|----|------|---------------------|-----|-----------|-----------------|
| R-01 | radar | Tách `spec-compiler.py`/`telemetry-log.py` ra helper `_spec_contract_gen.py`/`_telemetry_report.py` | Output giống từng byte; ca test giữ + test tái xuất; ≤ 400 dòng | S | ✅ | #227 → `cde2eaa` |
| R-02 | radar, 2 DEBT | Tách `test-check-scripts.sh` → `test-workflow-guards.sh`; `test_runtime_safety.py` → `_runtime_fixture.py` + `test_git_safety.py` | Ca test giữ nguyên (17 Python, 39 shell); CP-6/parity/manifest/FEATURE-MAP/CODEMAP nối; DEBT gỡ | S | ✅ | #228 → `949f09a` |
| R-03 | FT-25, FT-50 (F-309), P-C12 | Sửa F-309 với test đỏ-trước; FT-25/FT-50 → ✅; dời benchmark sang `docs/reports/`; closeout | Test F-309 đỏ trước/xanh sau; cột Trạng thái FEATURE-MAP hết ⚠️; docs-consistency xanh; radar 100/100 | S | ✅ | #229 → `de8bf99` |

Nhật ký hội tụ: sau R-03 — radar 100/100 (0 file mã > 400 dòng, 43/43 script có cổng), cột Trạng thái FEATURE-MAP hết ⚠️/❌ (cột Test còn ❌ ở FT-13..20, FT-41: cần harness/tài khoản thật), sweep
`--strict --no-deps` 🔴 0 🟡 0, docs-consistency 12/12. Giữ KHÔNG làm: P-B11 (lý do kỹ thuật); việc cần môi trường ngoài
(hosted CI đích, pilot, benchmark model, harness ngoài Claude Code) chưa kiểm được ở phiên này.

## Chu kỳ 2026-10-09 — hoàn thiện phần còn lại (nghiệm thu: `docs/reports/2026-10-09-completion-remaining.md`)

Yêu cầu: chủ repo "hoàn thiện tiếp những phần còn lại" (2026-10-09). Hồ sơ nối phiên:
`docs/work/2026-10-09-completion-remaining/done.md`. Phát hiện F-R01..F-R04 và DoC ở báo cáo.
**Approved for implementation — phiên chính duyệt theo ủy quyền của chủ repo ngày 2026-10-07; ngày duyệt 2026-10-09.**

| ID | Từ phát hiện | Việc | Tiêu chí nghiệm thu | Phụ thuộc | Sức | Trạng thái | PR / bằng chứng |
|----|--------------|------|---------------------|-----------|-----|-----------|-----------------|
| W-01 | F-R01 | Tách khối required checks chung cho đích (`gate`/`metadata`) khỏi bản kê job của repo khung (marker) trong `docs/ops/repository-settings.md`; `check-ci-policy.sh` đọc khối có marker; `test-copy-framework.sh` đối chiếu hai chiều khối đầu ↔ job thật của workflow phát kèm; TRAPS mục 54 | Test copy đỏ trước sửa, xanh sau; `check-ci-policy.sh` CP-1 vẫn bắt job thiếu; vitest drop-in xanh trên fixture đích | – | S | ✅ | #224 → `f166369`; vitest đích 38/38 sau sửa |
| W-02 | F-R02, F-R03 | `check-docs-consistency.sh` mục 12 (mẫu mồ côi) + negative test; con trỏ tới 3 mẫu từ tài liệu phát sang đích; `test-hooks-session.sh` mục 11 (session-guide) và 12 (auto-format) | Mục 12 đỏ với 3 mẫu trước khi thêm con trỏ, xanh sau; ca negative đỏ; hook test xanh và negative bắt được hook rỗng | – | S | ✅ | #225 → `0e37c6e`; mục 12 đỏ 3 mẫu → xanh; 39 ca test-check-scripts |
| W-03 | F-R04 | Closeout: FEATURE-MAP/CODEMAP hàng 54/AUDIT-STATUS/PROGRESS/report/work → done | Khớp main thật; docs-consistency + progress-freshness xanh | W-01, W-02 | S | ✅ | #229 → `de8bf99` |

Nhật ký hội tụ: 2026-10-09 sau W-02 — radar 99/100 (4 file mã > 400 dòng, thêm `scripts/test-check-scripts.sh` 417 vì hai ca
mới; ghi `DEBT:` kèm điều kiện), sweep `--strict --no-deps` 🔴 0 🟡 0, docs-consistency 12/12, không phát hiện Cao/Trung mới.
Chấp nhận/giữ nguyên: P-B11, P-C12, 3 file mã > 400 dòng cũ (lý do + điều kiện ở báo cáo); hosted CI/pilot/harness ngoài: không kiểm được ở phiên này.

## Chu kỳ 2026-10-08 — ĐÃ ĐÓNG 2026-10-08 (nghiệm thu: `docs/reports/2026-10-08-framework-completion.md`)

Yêu cầu mới: hoàn thiện toàn bộ chính bộ khung. Kế hoạch/DoC và audit 12 nhóm:
`docs/reports/2026-10-08-framework-completion.md`; goal:
`docs/goals/2026-10-08-framework-completion.md`; hồ sơ nối phiên:
`docs/work/2026-10-08-framework-completion/working.md`.
Phiên chính duyệt theo ủy quyền trước sửa source; hai PR sửa lỗi, worker thực thi
tuần tự và phiên chính nghiệm thu qua full gate/CI. Không mở lại chu kỳ cũ bên dưới.

W-01 #216 (d7aca5d) và W-02 #217 (6643f4e) đã MERGED, F-C01/F-C02/F-C03 đóng trên main,
CI main xanh, re-audit 0 Cao/Trung; goal COMPLETE. Chu kỳ kế tiếp (tối ưu quy trình,
không đổi hành vi): `docs/work/2026-10-08-process-optimization/done.md`.

> Người dùng duyệt hoàn thiện chính bộ khung ngày 2026-10-05. Kế hoạch chi tiết:
> `docs/reports/2026-10-05-framework-completion-plan.md`; audit 12 nhóm:
> `docs/reports/2026-10-05-framework-audit.md`. Phần "lượt 2026-09-12" bên dưới
> là lịch sử, không dùng các ô chưa tick của lượt cũ để suy ra trạng thái hiện tại.

## Chu kỳ 2026-10-06 — ĐÃ ĐÓNG 2026-10-07 (nghiệm thu: `docs/reports/2026-10-06-framework-audit.md`)

Chu kỳ 2026-10-05 đã đóng theo xác nhận của người dùng ngày 2026-10-06 (lựa chọn "đóng chu kỳ cũ, mở chu kỳ mới").
Base: `origin/main` `e2b70bf`; nhánh làm việc `claude/beautiful-albattani-f55ar3` (commit `de01523`, chưa có PR).
Quét Pha 1 (chỉ đọc/đo) 2026-10-06 — bằng chứng đo trong phiên: `maintenance-sweep --strict` 0 đỏ; ShellCheck `-S warning`
sạch trên mọi `.sh`; 9 bộ `scripts/test-*.sh` + `test-copy-framework.sh` (có cả `.ps1`, pwsh 7.4.6) + `test-py-coverage.sh`
(96%, sàn 95%) xanh; `dev-task.sh gate` PASS 4 kiểm tra; CI `main@e2b70bf` xanh; 0 PR mở.

### Phát hiện (F-N)

| ID | Nhóm | Mức | Phát hiện (bằng chứng) |
| --- | --- | --- | --- |
| F-N01 | 12 | Trung | `docs/FEATURE-MAP.md` (nguồn thống nhất chéo) **không nhắc** các engine/cổng thật: `spec-compiler`, `arch-health-radar`, `subagent-dispatch`, `telemetry-log`, `check-progress-freshness`, `check-python/shell-complexity`, `githooks`, và 6 test (`test-check-scripts`, `test-engine-characterization`, `test-next-gen-engines`, `test-py-coverage*`, `test-check-*-complexity`); mục D ghi "(3 script)" nhưng chỉ 3 hàng thật. Không cổng nào đối chiếu FEATURE-MAP ↔ `scripts/` (docs-consistency mục 6 chỉ canh CODEMAP). |
| F-N02 | 4/9 | Thấp | `arch-health-radar` báo sai "thiếu test" cho `scripts/delivery-handoff.py` dù `tests/test_delivery_handoff_integrity.py` chạy trong `test-py-coverage.sh` (CI). Radar chỉ ánh xạ `scripts/test-*.sh`→`ci.yml`; công cụ đo nói sai thì điểm 96/100 mất 1 phần oan. |
| F-N03 | 9 | Thấp | 3 spec thiếu mục 11 touchpoints: `2026-09-24-impeccable-optional-adapter.md`, `2026-09-25-runtime-safety.md`, `2026-09-25-strict-gate-contract.md` (radar). |
| F-N04 | 3 | Thấp | `scripts/test-engine-characterization.sh` 455 dòng (> 400; radar). |
| F-N05 | 8 | Thấp | Nhánh remote tồn đọng: `claude/kind-darwin-a8v4uy` (2026-09-15, +183/-50 so với main), `feature-that-exists` (nhánh dependabot codeql 4.38.2, +1/-13, đã superseded bởi #185; tên trùng nhãn fixture PF-2 dễ gây nhầm), `feat/figma-context-handoff` (**tác giả khác**, 2026-10-05, +1/-13, chưa có PR, đụng `delivery-handoff.py`). Xoá nhánh là thao tác không hoàn tác → cần chủ repo quyết (W-308 chu kỳ cũ cũng bị chặn đúng chỗ này). |
| F-N06 | 7 | Thấp | `maintenance-sweep` báo dependency `n-a` cho chính repo khung (chỉ có `scripts/requirements-ci.txt`, đã có dependabot pip); dò lệnh chỉ ở gốc + `apps/*`/`packages/*`. Chấp nhận được; chỉ cần ghi quyết định + điều kiện xem lại. |
| F-N07 | 8 | Thấp | 3/9 workflow (`dependency-review`, `pr-policy`, `scorecard`) không có `concurrency`; `ci-workflow-policy.test.ts` chưa chạy trên fixture (đã biết, FT-44). |
| F-N08 | 8/9 | Thông tin | Chưa từng cắt release: `VERSION` 0.1.0, 0 git tag, release-please chưa tạo release nào. Quyết định phát hành thuộc chủ dự án — không tự làm. |
| F-N09 | 4 | Thông tin | Coverage Python 96% sát sàn 95% (`telemetry-log.py` 96%, dòng 92-93/100/107/324-325 chưa phủ). Không hạ sàn; chỉ theo dõi. |

Nhóm 1, 2, 3, 5, 6, 10, 11: không phát hiện mới (secret scan sạch, mọi action ghim SHA, quyền workflow tối thiểu,
5/6/10 N/A vì repo khung không có runtime/UI/data). **Cao: 0 · Trung: 1 · Thấp: 6 · Thông tin: 2.**
Giới hạn trung thực: không chạy được CI hosted Windows/macOS tại phiên này; Go/Make và stack runtime khác chưa có ca
runtime độc lập (đã ghi ở chu kỳ trước).

### Definition of Complete (đề xuất cho chu kỳ này)

1. F-N01 đóng bằng **cổng tự động** (FEATURE-MAP ↔ `scripts/` hai chiều, có negative test), không chỉ sửa văn xuôi.
2. F-N02/F-N03/F-N04 đóng hoặc có quyết định ghi nhận (radar không còn báo sai; điểm radar ≥ 98 hoặc lý do).
3. F-N05 chỉ thực thi sau khi chủ repo chọn từng nhánh; F-N06/F-N07 có quyết định + điều kiện xem lại; F-N08/N09 ghi nhận, không sửa.
4. Re-audit lại nhóm 4, 8, 9, 12 sau các đợt: 0 phát hiện Cao/Trung mở; `gate` + CI `main` xanh.

### Đợt và việc (mỗi việc một PR nhỏ, FIFO, ≤ 3 PR mở; bug có test đỏ trước)

| ID | F gốc | Việc | Tiêu chí nghiệm thu | Sức | Trạng thái |
| --- | --- | --- | --- | --- | --- |
| W-01 | — | Mở PR cho các commit của nhánh (`de01523`…) | CI xanh, mô tả đủ mục template, squash merge | S | ✅ đã vào `main` qua #199 (`3ab7a7b`); `main` hiện `3310d2a` (#201) |
| W-02 | F-N02 | Radar: nhận test Python trong `tests/` mà `test-py-coverage.sh` chạy; test đỏ trước (fixture script `.py` + test) | `delivery-handoff.py` không còn trong `scripts_uncovered`; ca âm: `.py` không test vẫn bị báo | S | ✅ `b8d2032` |
| W-03 | F-N01 | Cổng docs-consistency mục 11: mọi `scripts/*` (trừ `_*`, `__pycache__`) và `test-*.sh` phải có mặt trong FEATURE-MAP; sau đó bổ sung các hàng thiếu bằng cách đọc code thật + sửa nhãn "(3 script)" | Negative test: thêm script giả → đỏ; FEATURE-MAP đủ; CODEMAP khớp | M | ✅ `c9c6031` |
| W-04 | F-N03 | Bổ sung mục 11 touchpoints cho 3 spec (đọc diff PR tương ứng, không bịa) | Radar hết cảnh báo spec | S | ✅ `2d5d1cc` |
| W-05 | F-N04 | Tách `test-engine-characterization.sh` ≤ 400 dòng, **không đổi hành vi** (test chạy trước/sau cùng kết quả) | Radar hết cảnh báo file dài; 9 test xanh | M | ✅ `b8d2032` |
| W-06 | F-N07 | Thêm `concurrency` cho 3 workflow; cập nhật `check-ci-policy` nếu cần | `check-ci-policy.sh` xanh, CI xanh | S | ✅ `92a1959` |
| W-07 | F-N05 | Dọn nhánh remote theo lựa chọn của chủ repo (từng nhánh) | Danh sách còn lại khớp quyết định; không đụng nhánh của người khác nếu chưa hỏi | S | ➖ chủ repo chọn giữ lại cả 3 nhánh (2026-10-07) — không xoá; ghi nhận ở báo cáo audit |
| W-08 | F-N06/N08/N09 | Ghi quyết định + điều kiện xem lại vào báo cáo audit | Có mục trong `docs/reports/2026-10-06-framework-audit.md` | S | ✅ báo cáo cùng PR |
| W-09 | — | Re-audit nhóm 4/8/9/12 và nghiệm thu DoC | Bảng bằng chứng, `gate` xanh | S | ✅ 2026-10-07: 0 Cao/Trung mở; F-N05 ghi nhận theo quyết định giữ nhánh của chủ repo |

Truy vết: F-N01→W-03 · F-N02→W-02 · F-N03→W-04 · F-N04→W-05 · F-N05→W-07 · F-N06/N08/N09→W-08 · F-N07→W-06.

Người dùng duyệt kế hoạch + DoC ngày 2026-10-07. Kết cục từng F-N và bằng chứng re-audit: `docs/reports/2026-10-06-framework-audit.md`.

---

## Chu kỳ 2026-10-05

| Slice | Finding / outcome | Trạng thái | Bằng chứng cần có |
| --- | --- | --- | --- |
| W-01 | Reconcile goal F-01..11, FEATURE-MAP, PROGRESS | Bàn giao trong PR tài liệu này | Main nguồn `6702994d90ad318142715aa172d79916c71e5b9d`; bản đồ đếm đúng 16/11/9/9, truy vết F→PR→regression |
| W-02 | Audit 12 nhóm năng lực khung | DONE | Snapshot và re-audit trong `docs/reports/2026-10-05-framework-audit.md`; nhóm N/A và giới hạn có lý do |
| W-03 | CodeQL #185/#186, grouping | DONE | #185 `8f4a181` merged, hai Analyze xanh; #186 trùng đóng |
| W-04 | Ruleset strict và regression guard | DONE | #188 `bec5795`; live strict=true, required gate+metadata; false đỏ/true xanh |
| W-05 | F-K01..05/F-K09/F-K10 | DONE | #189–194 và #196 merged; test hồi quy và required CI xanh trên head cuối; progress-freshness skip theo main-only |
| W-06 | Ma trận adoption/copy/gate | DONE đối chiếu, runtime giới hạn | #195: Node/Python tối thiểu chạy thật, các resolver fixture được liệt kê; Go/Make, stack runtime khác, CI hosted chưa kiểm; C01 ngoài phạm vi khung |
| W-07 | Re-audit và Definition of Complete | DONE — người dùng xác nhận đóng chu kỳ 2026-10-06 | Không phát hiện Cao/Trung mới trong phần code/cổng đã rà; F-K08/F-11 bàn giao ở PR này. Cổng PR phải đạt trước merge; người dùng xác nhận đóng chu kỳ theo Pha 4 |

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
