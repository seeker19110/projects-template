# Changelog

Mọi thay đổi đáng kể của dự án được ghi ở đây.

Định dạng theo [Keep a Changelog](https://keepachangelog.com/vi/1.1.0/),
và dự án tuân theo [Semantic Versioning](https://semver.org/lang/vi/).

> Repo dùng **release-please** (`.github/workflows/release.yml`): vì commit theo *conventional
> commits*, release PR + ghi chú phát hành được sinh tự động khi phát hành. Phần "Unreleased"
> dưới đây vẫn cập nhật tay cho thay đổi đáng kể giữa các lần phát hành.

## [Unreleased]

### Added (Thêm)

- **Nâng cấp `/ui-ux`** (#165, `.claude/commands/ui-ux.md`) theo bản đối chiếu ba cột với skill `ui-ux-design` v6
  (`docs/reports/2026-09-23-doi-chieu-ui-ux-design-v6.md`): 9 điểm "đã có nhưng nông hơn", mỗi điểm siết một
  luật cứng đang có — trạng thái tầng component (8 trạng thái, disabled ba kênh), tương phản theo từng khối đổi
  nền, không nhảy layout ở input/ảnh/lỗi form (CLS), công thức chống cuộn ngang, chuyển động chỉ
  `transform`/`opacity`, lỗi = nguyên nhân + việc làm tiếp, một primary CTA, không bịa nội dung (§4), a11y chi
  tiết (label hiển thị, WCAG 2.2.2). Sửa câu "File thật: `styles/theme.css`" sai với ADR-0004. Danh mục "mặc
  định của AI", vân tay cấu trúc, tự chấm 6 trục xếp "chưa cần" kèm điều kiện xem lại.
- **Cổng máy CC cho mã shell** (`scripts/check-shell-complexity.sh`, spec:
  `docs/specs/2026-09-15-cong-may-cc-shell.md`) — nối tiếp cổng CC Python: đo bằng
  `vendor/shellmetrics` (shellmetrics 0.5.0, MIT, **vendor + ghim SHA256** nên chạy offline và
  không phụ thuộc GitHub), **hai trần**: hàm ≤ 12 (`SH_CC_MAX`), thân script `<main>` ≤ 45
  (`SH_CC_MAIN_MAX` — nắp chặn trượt đặt trên mức cao nhất đang có là 41). Negative test
  `scripts/test-check-shell-complexity.sh` chứng minh cả hai trần đều chặn thật, tách rời nhau, và
  checksum vendor sai làm cổng ĐỎ. Kèm theo: `dev-task.sh::detected_cmd` (18 → tách 5 hàm theo hệ
  sinh thái) và `maintenance-sweep.sh::detect_deps_cmd` (13 → tách 4) hạ xuống dưới trần, hành vi
  giữ nguyên (đối chiếu bản cũ ↔ mới trên fixture node/python/go/rust/make).

- **Cổng máy cưỡng chế ngưỡng độ phức tạp vòng CC ≤ 12 cho engine Python**
  (`scripts/check-python-complexity.sh`, spec: `docs/specs/2026-09-14-cong-may-cc-12.md`) — trước đây
  ngưỡng này chỉ nằm trong văn xuôi (ADR-0005, chú thích characterization test) nên không cổng nào đỏ
  vì nó, đúng khuôn `TRAPS.md` mục 14. Trần mặc định 12 (`PY_CC_MAX`), **không có miễn trừ theo hàm**;
  thiếu `radon` → ĐỎ chứ không skip. Negative test `scripts/test-check-python-complexity.sh` chứng minh
  cổng bắt đúng vi phạm. Kèm theo: `format_markdown_report` của `arch-health-radar.py` tách
  `_optional_report_blocks` để xuống dưới trần (đầu ra báo cáo giữ nguyên) — trả dấu `DEBT:` duy nhất
  của repo đúng điều kiện xem lại đã ghi.

- **Ba luật rút từ đợt đối chiếu với nguồn ngoài `DietrichGebert/ponytail`** (bản đối chiếu ba cột:
  `docs/reports/2026-09-14-doi-chieu-ponytail.md`; spec: `docs/specs/2026-09-14-ladder-va-dau-no-ky-thuat.md`)
  — (1) `CLAUDE.md` §3 mục A4: **thang kiểm trước khi viết code** (có cần tồn tại → repo đã có chưa →
  thư viện chuẩn → tính năng nền tảng → dependency đã cài → bản tối thiểu), chạy *sau* khi đã hiểu vấn đề,
  dừng ở nấc đầu tiên khớp; (2) `CLAUDE.md` §3 mục A7: quy ước dấu nợ
  `DEBT: <gì> | trần: <giới hạn> | xem lại khi: <điều kiện>` — **có cổng thật**: `maintenance-sweep.sh`
  mảng 3 đếm dấu và cảnh báo 🟡 riêng cho dấu thiếu điều kiện xem lại (khuôn đã tái phát thật ở
  `TRAPS.md` mục 14), kèm negative+positive test; (3) `/audit-optimize` thêm **nhóm 5 "tự viết lại thứ
  đã có"** (nhãn `stdlib:`/`native:` — thứ knip/depcheck không đo được) và dòng tổng
  `net: -N dòng, -M dependency`. Ba mâu thuẫn luật của nguồn (mức cường độ `ultra`, "không bao giờ dừng
  hỏi khi có thể mặc định", luật rút gọn văn nói) được **nêu ra và từ chối**, không tự hoà giải.
- **Agent bảo trì toàn diện** (spec `docs/specs/2026-09-14-maintenance-agent.md`) — subagent
  `maintainer` + lệnh `/maintain` (quét → triage → kế hoạch chờ duyệt → PR nhỏ qua `/gate` → hội tụ)
  + engine `scripts/maintenance-sweep.sh` (6 mảng mục nát theo thời gian, mức 🔴/🟡, `--strict`,
  tự dò stack) + runner `scripts/maintain-run.sh` chạy agent bằng **CLI subscription cục bộ của mọi
  nhà cung cấp AI** (Claude Code/Hermes/Codex/OpenCode, không API key) + workflow tuần
  `.github/workflows/maintenance.yml` (một issue tổng hợp) + wrapper không giám sát
  `scripts/maintain-cron.sh` cho VPS/cron (đồng bộ nhánh chính, chạy agent, đẩy CHỈ
  `docs/ops/MAINTENANCE-*.md` lên nhánh riêng `maint/auto-<ngày>`, không bao giờ đụng nhánh chính,
  có khoá tiến trình chống chạy chồng). Ba self-test có negative-test/bare-repo thật + stub CLI,
  nối vào `framework-lint` và smoke dự án đích. **Bổ sung cùng ngày:**
  `maintain-cron.sh` tự mở PR qua GitHub REST API khi có `GITHUB_TOKEN`/`GH_TOKEN` (kênh báo cáo
  chính cho chủ dự án khi chạy không giám sát), tránh mở PR trùng; sửa hai lỗi thật bắt được khi
  viết test (push same-day rerun chỉ "thành công" nhờ trùng giây → đổi sang `--force-with-lease`
  giới hạn đúng một nhánh; biến gán trong hàm gọi qua subshell không thấy được ở ngoài) — xem
  `TRAPS.md` mục 16–17.

- **Quick Start + adoption preflight** — thêm `docs/framework/quickstart.md` để định hướng nhanh
  Greenfield/Brownfield, dẫn về Standard Delivery Contract và cung cấp checklist xác nhận lệnh/gate
  thật của ứng dụng, CI, bảo mật, ruleset và vận hành. README cùng framework index đã liên kết tới
  trang này. Checklist là preflight thủ công, không thay thế quality gate hay evidence theo profile.

### Removed (Bỏ)

- **Gỡ hẳn scaffold Web mặc định (Next.js + Supabase) khỏi repo khung — ADR-0004.** Xoá `app/`,
  `lib/`, `styles/`, `e2e/`, `i18n/`, `messages/`, `components/`, `supabase/`, cấu hình
  ESLint/Prettier/Vitest/Playwright/Lighthouse/commitlint, `.husky/`, `.env.example`,
  `.github/workflows/{codeql,lighthouse-ci,verify-dropins}.yml`, `scripts/verify-dropins.sh`.
  Lý do: nhất quán với nguyên tắc "hỗ trợ mọi loại dự án, chọn công nghệ research-first" — không
  hồ sơ nào xứng "mặc định" hơn hồ sơ khác (`CLAUDE.md` §0b, KHUNG-3 PHẦN C). `ci.yml` chỉ còn 3
  job tự kiểm của khung (`framework-lint`, `docs-consistency`, `copy-framework-smoke`) + `gate`.
  `copy-framework.sh`/`.ps1` Lớp 2 giờ chỉ còn CI/quy ước GitHub tổng quát (không đặc thù stack).
  Không sửa ADR-0001 (luật bất biến: không sửa ADR cũ) — xem quyết định đảo ngược ở
  `docs/adr/0004-remove-default-web-scaffold.md`.

### Added (Thêm)

- **Hàng rào thi hành cho các luật trước đây chỉ nằm trên giấy** (audit toàn diện 2026-09-12,
  kế hoạch `docs/ops/COMPLETION-PLAN.md`):
  - `scripts/test-hooks-gate.sh` — **chứng minh** `pre-commit-gate.sh` chặn thật (exit 2 khi cổng
    đỏ) và `block-dangerous-git.sh` chặn đúng khuôn, kèm negative test. Trước đây cổng chặn commit
    là hàng rào quan trọng nhất mà không có bất kỳ test nào (F-002).
  - `.claude/hooks/block-dangerous-git.sh` (mới) — chặn force-push nhánh chính, `reset --hard`,
    `merge/rebase --abort`; cờ bỏ qua tường minh `ALLOW_DANGEROUS_GIT=1` (F-004).
  - `.husky/pre-commit` quét bí mật bằng `gitleaks protect --staged` trước khi commit — trước đây
    chỉ quét ở CI, tức bí mật đã vào lịch sử Git rồi mới bị phát hiện (F-005).
  - `scripts/check-ci-policy.sh` thêm 3 kiểm: mọi action phải ghim full commit SHA (F-003),
    `node-version` khớp `.nvmrc` (F-011), mọi job `ci.yml` có trong `needs:` của `gate` (F-010).
  - `scripts/check-docs-consistency.sh` thêm kiểm subagent ↔ bảng `route:` hai chiều + frontmatter
    `name` khớp tên file (F-006); quét cả file chưa `git add` (F-017).
  - Job tổng hợp `gate` trong `ci.yml` + **ADR-0003** — branch protection chỉ cần khoá một tên (F-010).
  - `docs/FEATURE-MAP.md` + `docs/CONVENTIONS.md` cho chính bộ khung (Pha 0 của `/completion`).
- **Miễn trừ PR của bot trong `pr-policy.yml`** — nguyên nhân gốc khiến 5 PR dependabot (gồm 3 bản
  nâng cấp công cụ bảo mật) kẹt 19 ngày: required check `metadata` đòi PR body có đủ mục template,
  thứ dependabot không bao giờ có, nên **không bao giờ xanh được** (F-001).

### Changed (Thay đổi)

- `actions/cache@v4` (tag di động, **Node 20** — bị GitHub xoá khỏi runner 16/09/2026) →
  `actions/cache@caa2961` ghim SHA, v5.1.0 (Node 24). Đây là action duy nhất còn dùng tag di động
  trong 13 action của repo.
- `auto-format.sh` + `test-copy-framework.sh`: fail-open giờ **in cảnh báo** thay vì bỏ qua âm thầm
  (F-007, F-015); CI chạy `REQUIRE_PWSH=1` nên bỏ qua bản `.ps1` sẽ làm job đỏ.
- `scripts/check-docs-consistency.sh`: gỡ 4 file đã tồn tại thật khỏi `ALLOW_MISSING_PATH` (F-016).

- **Golden test — cơ chế thật, ví dụ chạy được trong dropins** (PR-C/3 của spec
  `docs/specs/2026-09-12-golden-tests-and-tdd.md`, đã Approved for implementation — spec hoàn tất
  3/3 PR). `vitest.config.mts` thêm `resolveSnapshotPath` tường minh (đưa mọi
  `toMatchSnapshot`/`toMatchFileSnapshot` vào `__golden__/` cạnh file test, khớp quy ước (b) đã viết
  ở PR-B, thay thư mục `__snapshots__/` mặc định). Thêm `lib/order-summary.ts` (hàm thuần, tiền
  dùng cents — không float) + `lib/order-summary.golden.test.ts` + baseline
  `lib/__golden__/order-summary.golden.test.ts.snap` đã sinh THẬT bằng Vitest. **Sửa 1 chỗ sai đã
  push ở PR-B:** `quality-supplements.md` từng ghi "Vitest có cờ `--ci` chặn tạo snapshot mới" —
  KHÔNG có cờ đó ở Vitest 5 (`CACError: Unknown option`, xác minh thật). Cơ chế đúng là biến môi
  trường `CI` (Vitest tự phát hiện `process.env.CI`; GitHub Actions tự đặt `CI=true`) — đã xác minh
  cả hai chiều: `vitest run` không đặt `CI` tự tạo snapshot thiếu rồi PASS (nguy hiểm); cùng lệnh với
  `CI=true` thì FAIL đúng, không tạo file (đây là FR-9 của spec: xác minh thật trước khi ghi tài
  liệu, không suy đoán — CLAUDE.md §4). `copy-framework.sh`/`.ps1` nối 3 file mới vào Layer 2;
  `test-copy-framework.sh` thêm 2 assertion (đã chạy negative test).
- **Golden test — tài liệu + template** (PR-B/3 của spec `docs/specs/2026-09-12-golden-tests-and-tdd.md`,
  đã Approved for implementation). `docs/framework/quality-supplements.md` (Nhóm 2 mục 6) thêm tiểu
  mục "Golden test" đủ 5 phần: (a) dùng khi nào/KHÔNG dùng khi nào (không mặc định cho snapshot UI
  diện rộng — nguồn test giòn kinh điển), (b) nơi lưu fixture, (c) **luật chuẩn hoá bắt buộc** trước
  khi so (timestamp/id/đường dẫn/thứ tự khoá/timezone), (d) **luật cập nhật** — không `-u` phản xạ,
  PR phải nêu lý do + dán diff golden, (e) CI không được tự tạo snapshot mới. Thêm
  `docs/framework/templates/GOLDEN-TEST.template.md` (28 dòng, checklist dán được thẳng vào PR
  body) và nối vào `.claude/commands/gate.md`. `scripts/test-copy-framework.sh` thêm assertion cho
  template mới (đã chạy negative test: gỡ file → FAIL đúng, phục hồi → PASS lại).
- **TDD "sửa bug phải có test tái hiện đỏ trước khi sửa" nâng từ luật của một lệnh lên luật của
  khung** (PR-A/3 của spec `docs/specs/2026-09-12-golden-tests-and-tdd.md`, đã Approved for
  implementation). Trước đây luật này chỉ sống trong `/completion` + `/audit-full`, nên một PR
  `fix` thường hoặc phiên `/auto` không đi qua nhánh đó. Nay có ở `CLAUDE.md` §3.6/§5, Báo cáo xác
  thực §7 (dòng `Test tái hiện (nếu là fix) ✅/❌/n-a` + `Golden ✅/n-a` — golden `n-a` cho tới khi
  PR-B/PR-C của spec dựng cơ chế thật), `.claude/commands/gate.md` (cảnh báo mềm, không chặn cứng —
  cố ý, vì chặn cứng sẽ dạy người dùng khai sai loại commit) và `AGENTS.md`. Làm rõ trong
  `docs/framework/quality-supplements.md` ranh giới đang bị đọc lẫn: vòng đỏ-xanh TỔNG QUÁT cho code
  MỚI là **khuyến nghị**, còn test-tái-hiện-trước cho bug là **bắt buộc** — hai thứ khác nhau.
  **Sửa nghiên cứu sai của chính spec:** `.claude/commands/debug.md` Pha 5 hoá ra ĐÃ đúng từ trước
  (đã nói "trước khi sửa... đỏ → sửa → xanh" từ PR #36) — claim ban đầu trong spec (§1) rằng
  debug.md yêu cầu test "kèm lúc sửa" là research sai lúc viết spec; không sửa file đó, chỉ ghi
  nhận đúng sự thật ở đây.
- **`CODEMAP.md` — bảng "muốn đổi X → sửa file nào → rồi chạy lại gì", nối vào `/completion`**
  (PR-3/4 của spec `docs/specs/2026-09-12-traps-codemap-ci-policy.md`, đã Approved for implementation).
  Thêm `docs/framework/templates/CODEMAP.template.md` (mẫu rỗng cho dự án đích) và `CODEMAP.md` ở
  gốc repo với bảng tra thật cho chính khung (thêm/đổi job CI → sửa file nào → chạy cổng nào; đổi
  file gốc dự án đích nhận khi copy khung → chạy `test-copy-framework.sh`…). Mảnh còn thiếu giữa
  `docs/FEATURE-MAP.md` ("có gì") và `docs/CONVENTIONS.md` ("viết thế nào") — mẫu này hội tụ độc lập
  ở 4 repo dẫn xuất/lân cận nên có giá trị thật. `docs/framework/project-completion.md` (Pha 0) và
  `.claude/commands/completion.md` nay sinh cả 3 file cùng lượt; nhân đó sửa luôn "Pha 1" → "Pha 0"
  (lỗi sẵn có, không khớp checklist thật của Pha 0). Nguồn thượng nguồn: `CODEMAP.md` của
  `Claude-Agents`/`Sales-Hunter`/`X-Agents`/`X-Studio`.
- **`scripts/ci-workflow-policy.test.ts` — bản vitest của `check-ci-policy.sh` cho dự án đích**
  (PR-4/4 của spec traps-codemap-ci-policy). Đối chiếu HAI CHIỀU job id thật trong
  `ci.yml`/`pr-policy.yml` với danh sách khai báo trong `docs/ops/repository-settings.md`; nối vào
  `stage`/`Add-Dropin` của `copy-framework.sh`/`.ps1` (Layer 2 — không đè file đang chạy). Đã xác
  minh THẬT bằng `verify-dropins.sh` trên Next.js 16.3.5 sạch: 13/13 test pass, và negative test
  (đổi tên một job thật) làm đúng 2 test đỏ ở cả hai chiều trước khi hoàn nguyên. `verify-dropins.sh`
  cũng bắt một lỗi format Prettier do chính đợt sửa `project-completion.md` (PR-3) ở trên gây ra —
  đã sửa và xác nhận idempotent (chạy `--write` lần hai không đổi gì) trước khi commit.
- **`TRAPS.md` — sổ bẫy đã mắc thật, nối vào `/debug`** (PR-2/4 của spec
  `docs/specs/2026-09-12-traps-codemap-ci-policy.md`, đã Approved for implementation).
  Thêm `docs/framework/templates/TRAPS.template.md` (mẫu rỗng cho dự án đích) và `TRAPS.md`
  ở gốc repo với 6 mục **có thật**, mỗi mục trỏ tới commit/PR xác minh được (`59a280f` #18,
  `6a4ac40` #27, `366aeec`, `79dca2f` #43, `d0baf40` #61) — vd bản `copy-framework.ps1` cần BOM
  cho PowerShell 5.1 dù `.sh` không cần, hay job CI gọi GitHub API thiếu `permissions:` tường
  minh gây 403 chỉ lộ ra khi chạy PR thật. `/debug` thêm Pha 0 đọc `TRAPS.md` trước khi ra giả
  thuyết, và Pha 6 ghi mục mới/tái phát sau khi sửa xong. Nối vào `CLAUDE.md` §1 + §3.6 và
  `AGENTS.md`. Nguồn thượng nguồn: TRAPS.md của repo Claude-Agents.
- **`scripts/check-ci-policy.sh` — cổng canh cấu hình CI, chặn hỏng-im-lặng của required checks**
  (PR-1/4 của spec `docs/specs/2026-09-12-traps-codemap-ci-policy.md`, đã Approved for
  implementation). `docs/ops/repository-settings.md` thêm mục "Required checks — nguồn sự thật"
  liệt kê đủ 7 job (`ci.yml`: framework-lint/docs-consistency/copy-framework-smoke/quality/
  source-hygiene/e2e, `pr-policy.yml`: metadata) — trước đây danh sách này KHÔNG tồn tại ở đâu.
  Script đối chiếu HAI CHIỀU job id thật trong workflow với danh sách đó, chạy trong job
  `docs-consistency`; đã kiểm chứng bằng negative test (đổi tên một job thật, xác nhận script đỏ
  đúng cả hai chiều, rồi hoàn nguyên) trước khi nối vào CI.
- **Feature spec golden test + kỷ luật TDD (`docs/specs/2026-09-12-golden-tests-and-tdd.md`)** — *spec, CHƯA thực thi.*
  Rà thật cho thấy: **golden test chưa tồn tại như cơ chế** (chỉ 2 lần nhắc thoáng qua ở
  `01-process-and-standards.md:11` và `03-tech-selection-and-proactive-advice.md:237`, không định nghĩa,
  không nơi lưu fixture, **không luật cập nhật** — nên golden đỏ sẽ bị `vitest -u` làm xanh, tức ghi nhận
  bug thành giá trị kỳ vọng mới); và **TDD chỉ bắt buộc ở một ca hẹp trong một nhánh lệnh** ("bug có test
  tái hiện trước khi sửa" chỉ sống ở `/completion` + `/audit-full`, vắng mặt ở `CLAUDE.md` §3/§5/§6 và
  `/gate`, nên PR `fix` thường hoặc phiên `/auto` không đi qua). Spec nâng luật lên cấp khung + cổng,
  giữ vòng đỏ-xanh tổng quát là khuyến nghị, và cố ý KHÔNG ép test-trước lên scaffolding/rename/docs.
  Nguồn thượng nguồn: repo `Claude-Agents`, workflow eval-record.yml (cập nhật golden là hành động
  thủ công có người bấm nút, tách khỏi việc phát hiện lệch), `donghanh` (`*-fixtures.json`), `xboss`
  (allowlist ngoại lệ tường minh). Kế hoạch 3 PR ở §17.
- **Feature spec gói A+B+C (`docs/specs/2026-09-12-traps-codemap-ci-policy.md`)** — *spec, CHƯA thực thi.*
  Rút ba lỗ hổng có thật của khung từ lượt quét 15 repo dẫn xuất (2026-09-12): (A) không có nơi tích luỹ
  bẫy đã mắc qua thời gian → `TRAPS.template.md`; (B) thiếu bảng tra `Muốn | Sửa | Rồi chạy` giữa
  `FEATURE-MAP` ("có gì") và `CONVENTIONS` ("viết thế nào") → `CODEMAP.template.md`; (C) danh sách
  required checks của branch protection KHÔNG tồn tại ở đâu và `ci.yml` có 6 job phẳng (`framework-lint`, `docs-consistency`, `copy-framework-smoke`, `quality`, `source-hygiene`, `e2e`), 0 `needs:` —
  nên đổi tên một job id sẽ làm required check cũ không bao giờ báo cáo nữa và kẹt merge mọi PR mà
  không PR nào hiện màu đỏ → thêm một script đối chiếu hai chiều (tên dự kiến
  scripts/check-ci-policy.sh, chưa tồn tại).
  Nguồn thượng nguồn: `Claude-Agents` (TRAPS/CODEMAP), `donghanh` (policy-as-test).
  Kế hoạch 4 PR + mục CHANGELOG khi thực thi nằm trong §17–§18 của spec.
- **Hoàn thiện quản trị OSS (Đợt 4 COMPLETION-PLAN):** thêm `CODE_OF_CONDUCT.md`
  (Contributor Covenant v2.1 tiếng Việt), `SUPPORT.md` + `GOVERNANCE.md` thật (từ template);
  dịch `CONTRIBUTING.md` sang tiếng Việt; gộp issue template về một bộ form `.yml`
  (xóa `bug_report.md`/`feature_request.md` cũ); làm mới `PROGRESS.md` theo
  `PROGRESS.template.md`; sửa mô tả `ci.yml` trong README và ghi chú release-please ở đây.
- **`scripts/verify-dropins.sh` + workflow `verify-dropins.yml`** — dựng một dự án Next.js sạch,
  copy khung vào, làm đúng Phần D của runbook rồi chạy lint/type-check/build/test THẬT.
  Trước đây các file dropins (`app/`, `components/`, `lib/`, config) chưa từng được biên dịch
  hay lint lần nào vì repo khung không có `package.json`. Chạy hằng đêm với
  `create-next-app@latest` nên cũng là cảm biến version drift từ thượng nguồn.
- **Cổng nhất quán lệnh:** `scripts/check-docs-consistency.sh` kiểm hai chiều giữa
  `.claude/commands/*.md` và `CLAUDE.md` — lệnh mới mà quên khai TRIGGER, hoặc `CLAUDE.md`
  trỏ tới lệnh không tồn tại, đều bị CI chặn thay vì phải rà tay.
- **Dependabot theo dõi `github-actions`** — các action trong `.github/workflows/` đang dùng
  tag trôi (`@v4`, `@v3`); đây là phụ thuộc thật của chính bộ khung, trước đây không ai canh.
- **Dấu bản khung ở dự án đích:** `copy-framework.sh`/`.ps1` sinh `docs/framework/FRAMEWORK-VERSION`
  (commit nguồn + ngày copy, luôn ghi đè theo lần copy gần nhất) — dự án đích biết mình đang dùng
  khung bản nào và so CHANGELOG này để quyết định khi nào copy lại.
- **`docs/framework/templates/`** — bản mẫu sạch cho 3 file làm việc của `/completion`:
  `FEATURE-MAP.template.md`, `CONVENTIONS.template.md`, `COMPLETION-PLAN.template.md`
  (tách từ khối inline trong `project-completion.md` — một nguồn sự thật, copy thẳng thay vì chép tay).

### Changed (Đổi)

- **Workflow siết quyền tối thiểu:** mọi workflow khai `permissions:` ở cấp workflow
  (`ci.yml`, `lighthouse-ci.yml`, `codeql.yml` trước đây nhận quyền mặc định của repo).
- **`concurrency` cho workflow:** push liên tiếp vào cùng một PR hủy lượt chạy cũ;
  trên `main` không hủy, và `release.yml` xếp hàng (không hủy) để tránh release dở dang.

### Fixed (Sửa)

- **`components/theme-toggle.tsx` fail lint chính config của khung** (`react-hooks/set-state-in-effect`
  của React Compiler, qua `eslint-config-next` bản mới). Viết lại theo `useSyncExternalStore` —
  đọc `data-theme` trên `<html>` (nguồn sự thật do script no-flash đặt) thay vì `useState` +
  `useEffect`; bỏ luôn một lượt render thừa sau hydrate.
- **`app/sw.ts` không type-check được** (`TS2552: Cannot find name 'ServiceWorkerGlobalScope'`)
  vì `lib` của Next chỉ có DOM. Thêm `/// <reference lib="webworker" />` theo từng-file.

### Removed (Bỏ)

-

<!--
Khi phát hành phiên bản, tạo mục mới phía trên, ví dụ:

## [0.1.0] - 2026-01-01
### Added
- Phiên bản đầu tiên.
-->
