# Audit toàn diện 2026-10-09 — trọng tâm: tự động hóa cho dự án đích lên tối đa, giữ chất lượng tối đa

- Work ID: `2026-10-09-audit-full-automation` · base `2e80d2f` (`origin/main`, sau #245) · lệnh `/audit-full` GIAI ĐOẠN 1 (chỉ đọc + đo).
- Chủ thể: chính repo khung, audit theo **năng lực khung phát cho dự án đích** (settings/hooks/agents/commands/scripts/CI drop-ins/copy-framework). Bước -1: không phải template trống (tiền lệ các chu kỳ trước). Bước 0: quét lại từ đầu (base đổi, trọng tâm mới).
- Cách đo: phiên chính đọc bề mặt tự động hóa + chạy engine (radar 100/100; sweep 🔴 0 🟡 2; docs-consistency OK; ci-policy CP-1..6 OK; `dev-task.sh doctor` BLOCKED trên máy này vì thiếu `shellcheck`); 5 auditor read-only song song (tài liệu Claude Code nguồn sống; Nhóm 8; Nhóm 1/9/12; Nhóm 2/7/11; Nhóm 3/4 chạy 9 suite thật). **Mọi phát hiện Cao được phiên chính tự tái hiện lại** trước khi ghi.
- ID giữ nguyên tiền tố của auditor để truy vết: `F-A` (CI/CD đích), `F-S` (bảo mật), `F-D` (tài liệu/thống nhất), `F-Q` (logic/test), `F-M` (phiên chính: cấu hình tự động hóa).

## 1. Dữ kiện nền đã xác minh (tài liệu Claude Code, 2026-10-09)

| Dữ kiện | Hệ quả cho khung |
|---|---|
| `permissions.defaultMode` nhận `default/acceptEdits/plan/dontAsk`; `auto` và `bypassPermissions` **không có hiệu lực** trong `.claude/settings.json` của dự án | Không bake chế độ bypass; `dontAsk` là lựa chọn cho chạy không giám sát nhưng tự **từ chối** mọi thứ ngoài allow → chỉ hợp làm opt-in cục bộ, không bake cho mọi phiên tương tác |
| Deny thắng mọi mode; hook PreToolUse exit 2 chặn; `PermissionRequest` hook có thể trả lời prompt bằng `decision.behavior` | Hàng rào hook + deny là lớp bền; không cần hook PermissionRequest ở mức này |
| Lệnh ghép `a && b` phải khớp allow ở **từng vế**; `git -C . push` không khớp `Bash(git push *)` | Allow list hiện nay làm `npm run lint && npm test` vẫn hỏi; chấp nhận (tách lệnh) |
| `enabledMcpjsonServers: [..]` tự duyệt server của `.mcp.json` (bị bỏ qua ở thư mục chưa trust) | Thêm `["context7"]` để research-first không bị hỏi |
| `mcp__context7` / `WebFetch(domain:…)` / `Agent(tên)` là cú pháp rule hợp lệ; tool `Agent` không tự hỏi quyền | Thêm allow cho tra cứu nguồn sống |
| `anthropics/claude-code-action` cần `ANTHROPIC_API_KEY` hoặc `CLAUDE_CODE_OAUTH_TOKEN` (subscription) | Secret/chi phí mới → **quyết định của chủ repo**, không bake |

## 2. Phát hiện theo 12 nhóm

Mức: **Cao** = tự động hóa thành kẹt/mất hàng rào ở đích; **Trung** = tự động hóa dở dang hoặc lệch tài liệu-cổng; **Thấp** = nhiễu/nợ.

### Nhóm 1 — Kiến trúc & thiết kế — ✅ 0 Cao · 1 Trung
- **F-D-06 · Trung** — `.claude/settings.json` ≡ `settings-shared-default.json` hôm nay (`cmp` = 0) nhưng không cổng nào giữ chúng khớp; `CODEMAP.md:48` trỏ một cổng không tồn tại. Khuôn TRAPS 19. → thêm `cmp -s` vào `test-hooks-gate.sh`.
- **F-D-12 · Thấp** — 3 cổng trước commit (hook Claude, githook, CI gate) cùng nguồn `_commit-guard.sh`, khác biệt có chủ đích; `pre-commit-gate.sh` fail-open khi thiếu `jq` chưa được ghi ở `models-and-automation.md:303`.

### Nhóm 2 — Bảo mật — ❌ 2 Cao · 4 Trung · 2 Thấp
- **F-S01 + F-Q1 + F-Q3 + F-Q2 + F-Q4 · Cao** — `block-dangerous-git.sh` / `pre-commit-gate.sh` / `_lib.sh` để lọt (phiên chính tái hiện, exit 0 = không chặn): `git commit -m "don't break" && git push --force origin main` (nháy đơn trong nháy kép nuốt lệnh giữa — `_lib.sh:65`); `git push origin +refs/heads/main`; `+HEAD:refs/heads/main`; `-fu origin main`; `-f origin "main"`; `-f origin HEAD:refs/heads/main`; `bash -c 'git reset --hard'`; `<<-EOF` thụt tab và `"a <<EOF"` nuốt phần sau. Lớp permission cũng không chặn (allow `Bash(git push *)`; deny chỉ dạng `--force * main`). Chỉ còn ruleset GitHub bảo vệ → đích chưa import ruleset thì mất `main`. → PR `fix(hooks)` với test đỏ-trước ở `test-hooks-gate.sh` + deny bổ sung.
- **F-S02 · Cao** — allow `Edit`/`Write` vô điều kiện → agent (bị prompt injection, ADR-0009) sửa được chính hook/`project-commands.sh` rồi gọi `scripts/dev-task.sh gate` (đã allow) → thực thi tùy ý không prompt. → `ask` cho `Edit|Write(.claude/**)`, `(.github/workflows/**)`, `scripts/_commit-guard.sh`, `scripts/dev-task.sh`, `scripts/_stack-detect.sh`.
- **F-S03 · Trung** — deny `Read(.env)` không phủ `**/.env.*`, `*.pem`, `id_rsa*`, `.npmrc`, `.netrc`; `git diff --no-index /dev/null .env` được allow; tool Grep không chịu rule Read (giới hạn nền tảng, ghi tài liệu).
- **F-S06 · Trung** — `_commit-guard.sh:12` thiếu Anthropic `sk-ant-`, GitHub `gho_/ghs_/ghu_/ghr_`, Stripe `sk_live_`, JWT, npm `npm_`, Slack webhook, generic `password=` (cổng này chặn TRƯỚC khi vào git; gitleaks chỉ chạy ở CI).
- **F-S07 · Trung** — allow rộng cho lệnh xuất bản/tải mã (`deno run -A https://…`, `mvn deploy`, `dotnet nuget push`, `flutter pub publish`, `./gradlew publish`) và git mất dữ liệu (`stash drop/clear`, `branch -D`, `checkout -- .`, `restore -- .`). → deny đích danh các lệnh đó, giữ allow build/test (ít hơn, không hạ tự động).
- **F-S04/F-S05/F-S10 · Trung** — `maintain-cron.sh:245` token trong argv `curl -H` (lộ qua `ps`, trái threat-model T3 đang khẳng định ngược); lock dir `/tmp` đoán được, không kiểm owner/symlink. → `-H @file` mode 600; lock trong `$ROOT/.git/`; sửa threat-model.
- **F-S08 · Thấp** — `maintenance.yml` đổ report thẳng vào issue body (markdown injection từ nội dung repo) → bọc khối code. **F-S09 · Thấp** — template formatter thiếu `--` trước `"$1"`.

### Nhóm 3 — Chất lượng mã & chống lỗi logic — ❌ 1 Cao (gộp F-Q1 ở Nhóm 2) · 2 Trung · 4 Thấp
- **F-Q7 · Trung** — `copy-framework.sh copy_if_absent` không `cmp` → chạy lần 2 sinh 60 `.framework-new` (57 giống hệt đích) và làm `test-hooks-gate.sh` mục 17 **đỏ 2 ca ở đích** (phiên chính tái hiện). → `cmp -s`/`diff -rq` bỏ qua khi giống; mục 17 loại `*.framework-new`.
- **F-Q5 · Thấp** — `--no-verify` ở lệnh khác trong chuỗi cũng bỏ cổng. **F-Q9 · Thấp** — `usage-estimate.sh` chỉ dò `python3`, tắt im lặng. **F-Q10 · Thấp** — `auto-format.sh` nuốt stderr formatter. **F-Q11/F-Q12 · Thấp** — dò stack chỉ ở gốc (monorepo), `project-commands.sh` là shell tin cậy — ghi rõ ở example.

### Nhóm 4 — Kiểm thử & coverage — ⚠️ 0 Cao · 2 Trung · 2 Thấp
- 9 suite chạy thật: 8 OK; `test-hooks-session.sh` **12 đỏ giả trên Windows** (**F-Q6 · Trung**: đường dẫn MSYS trong `python -c`, copy binary `bash`; job `framework-lint-windows` không chạy suite này nên không ai thấy).
- **F-Q8 · Thấp** — smoke ở đích chạy 5/7 self-test phát kèm (bỏ `test-hooks-gate.sh`, `test-usage-estimate.sh`) → chính vì thế F-Q7 không bị bắt.
- **F-D-05 · Trung** — `copy-framework.ps1` không set exec-bit (`.sh` có `chmod +x`) → đích tạo bằng `.ps1`, đồng đội Linux/macOS clone → **9 hook chết im lặng** (khuôn `test-hooks-gate.sh:262`); stamp `.ps1` thiếu `version:`/`manifest:`.
- Thấp — thiếu test đỏ-trước ở đích cho `dev-task`/hook session (test không phát); `tests/*.py` + `requirements-ci.txt` phát sang đích nhưng `ci-target.yml` không chạy → file chết, comment manifest lỗi thời.

### Nhóm 5 — Hiệu năng — ➖ Không áp dụng (repo khung không có runtime; ADR-0004)
### Nhóm 6 — Accessibility & UI/UX — ➖ Không áp dụng (không có UI)

### Nhóm 7 — Dependency & chuỗi cung ứng — ✅ 0 Cao · 0 Trung · 1 Thấp
- 25/25 `uses:` ghim SHA 40 ký tự + comment version; không `pull_request_target`; quyền tối thiểu theo job; `requirements-ci.txt` ghim; `vendor/shellmetrics` kiểm SHA256 trước khi chạy; dependabot phủ actions/npm/pip. **F-A9 · Thấp** — `ci-target.yml:18` comment `# v4` thiếu patch.

### Nhóm 8 — CI/CD & vận hành — ❌ 3 Cao · 4 Trung · 1 Thấp
- **F-A1 · Cao** — `release.yml` dùng `GITHUB_TOKEN` mặc định → release PR do release-please tạo **không kích `pull_request`** (GitHub docs) → `gate`/`metadata` required không bao giờ báo → PR không merge được, chiếm 1/3 trần WIP vĩnh viễn (khuôn TRAPS 5b tái phát). Repo chưa cảnh báo. → `token: ${{ secrets.RELEASE_PLEASE_TOKEN || secrets.GITHUB_TOKEN }}` + tài liệu secret + TRAPS. **Việc tạo secret = chủ repo.**
- **F-A2 · Cao** — PR dependabot xanh được (bot miễn PR template/Work ID) nhưng **không có đường tự merge** → chờ người, dễ vượt trần WIP 3 rồi chặn PR của người (sự cố F-001 dạng khác). Ruleset cho phép (`required_approving_review_count: 0`). → dropin `dependabot-auto-merge.yml` (`dependabot/fetch-metadata` + `gh pr merge --auto --squash`, chỉ patch/minor, GITHUB_TOKEN + `contents/pull-requests: write`, không cần secret).
- **F-A3 · Cao** — `ci-target.yml` chỉ cài dependency cho `package-lock.json`/`requirements.txt`; `_stack-detect.sh` hỗ trợ pnpm/yarn/bun/uv/poetry/Go/Rust/Java/.NET/Dart/PHP/Ruby/Elixir/Deno/Swift → `gate` required **đỏ ngày đầu** cho các stack đó (S-05/TRAPS 57 tái phát). → bước `if: hashFiles(<lockfile>)` + setup action ghim SHA đã xác minh.
- **F-A4 · Trung** — `allow_auto_merge`/`delete_branch_on_merge` (setting repo, không phải rule) không được khai/kiểm; **đích không nhận job `protection-guard`** (chỉ có ở `ci.yml` khung) dù `repository-settings.md:30` mô tả như có. → phát `protection-guard` + guard setting repo (`GET /repos/{repo}`, GITHUB_TOKEN đọc được) vào `ci-target.yml`.
- **F-A5 · Trung** — `CODEOWNERS` phát sang đích hard-code `@seeker19110`, không cổng; bật `require_code_owner_review` ở đích = deadlock. → placeholder khi stage + ca test + sweep 🟡.
- **F-A6 · Trung** — `codeql.yml` cố định `[python, actions]`; `release.yml` cố định `release-type: node` + chỉ chạy khi có `package.json` → SAST không quét app, non-Node không có release. → matrix động từ `/repos/{repo}/languages`; `release-type` dò theo manifest, mặc định `simple`.
- **F-A7 · Trung** — githook harness-agnostic phải bật tay (`core.hooksPath`); copy-framework/doctor/sweep không làm/kiểm → với Cursor/Codex/Copilot toàn bộ cổng commit tắt mặc định. → copy-framework set `core.hooksPath` khi đích là repo git; doctor cảnh báo.
- **F-A8 · Thấp (hiện trạng)** — issue bảo trì → PR chỉ qua `maintain-cron.sh` trên VPS (PR kế hoạch); không có workflow chạy agent (cần API key — chủ đích theo threat model). Giữ nguyên.

### Nhóm 9 — Tài liệu ↔ code thật — ❌ 1 Cao · 4 Trung · 3 Thấp
- **F-D-01 · Cao** — `models-and-automation.md §6` khai "4 hook tự động"/4 sự kiện; thật 9 hook/6 sự kiện (thiếu `SubagentStop`, `PreCompact`, `block-dangerous-git`, `ui-intelligence`, `precompact-checkpoint`); sơ đồ §6 cũng thiếu. Người dùng "bỏ hook không cần" theo tài liệu sẽ thiếu hiểu biết. → sửa + cổng docs-consistency đối chiếu hook `settings.json` ↔ bảng.
- **F-D-02 · Trung** — §6 bảng Subagent 9/11 (thiếu `tester`, `security-reviewer`). **F-D-03 · Trung** — §0/§6/§7/§8 nói copy "2 file scripts, thiếu thì no-op"; thật manifest phát ~43 mục và thiếu `_commit-guard.sh` thì hook **chặn commit**. **F-D-07 · Trung** — `.codex/config.toml` (trần 500k) không trong manifest → đích dùng Codex không nhận. **F-D-08 · Trung** — `AGENTS.md` thiếu luật `Work ID:` trong PR (cổng `pr-policy.yml` từ #244) → agent ngoài Claude Code đỏ CI mà không biết vì sao.
- **F-D-04 · Thấp** header copy-framework liệt kê tay lỗi thời; **F-D-09 · Thấp** CODEMAP trỏ `MAINTENANCE-REPORT.md` (gitignored); **F-D-10 · Thấp** 10/17 command thiếu dòng 💡 Model/effort.

### Nhóm 10 — Dữ liệu & migration — ➖ Không áp dụng (không có CSDL/migration trong khung)

### Nhóm 11 — Cấu hình môi trường & bí mật — ✅ 0 Cao · 2 Trung
- `.gitignore`, `.gitleaks.toml` (allowlist 1 commit có lý do), `.mcp.json` (HTTPS, không key), `.mcp.json.example` (placeholder) đạt.
- **F-M01 · Trung** — allow list chưa phủ thao tác mà `/auto` & PR flow cần: `gh pr create/edit/view/checks/merge --auto`, `gh run view/watch`, `scripts/{maintenance-sweep,arch-health-radar,subagent-dispatch,spec-compiler,telemetry-log}.sh`, `python3/node` chạy script của khung, `WebFetch(domain:registry.npmjs.org|pypi.org|nodejs.org|github.com)`, `WebSearch`, `mcp__context7` → mỗi lượt đều hỏi, phiên không giám sát kẹt. Giữ "ask" cho `gh api`, `gh repo *`, `gh secret *`, `gh release *`, `gh pr merge` không `--auto`.
- **F-M02 · Trung** — thiếu `enabledMcpjsonServers: ["context7"]` → research-first bị hỏi duyệt MCP mỗi máy. `defaultMode: "dontAsk"` chỉ ghi vào `settings.local.json.example` làm opt-in cho phiên không giám sát (không bake).

### Nhóm 12 — Thống nhất chéo tính năng — ✅ 0 Cao · 0 Trung · 1 Thấp
- FEATURE-MAP đếm 17/11/9 khớp `ls`; 6 file cầu nối đều trỏ AGENTS.md; mọi đường dẫn trong commands tồn tại; frontmatter agent khớp docs. **F-D-11 · Thấp** — tools của `coordinator` trong repo (`Read, Glob, Grep, Bash, Agent`) ≠ danh sách harness đang nạp (có `Write, Edit`) — cần chủ repo xác nhận nguồn (cache/cấp user).

## 3. Tổng hợp & ưu tiên toàn cục

| Mức | Số | ID |
|---|---|---|
| Cao | 7 | F-S01(+F-Q1/Q2/Q3/Q4), F-S02, F-A1, F-A2, F-A3, F-D-01 |
| Trung | 19 | F-A4..A7, F-S03..S07, F-Q6, F-Q7, F-D-02/03/05/06/07/08, F-M01, F-M02 |
| Thấp | 14 | F-A8, F-A9, F-S08, F-S09, F-Q5, F-Q8..Q12, F-D-04/09/10/11/12 |

**Ưu tiên (giá trị cao / rủi ro thấp trước):** (1) hàng rào hook + settings deny/ask (F-S01/F-Q*, F-S02/03/07) — không có nó, mọi "tự động" khác là tự động mất `main`; (2) copy-framework idempotent + exec-bit + hooksPath (F-Q7/Q8, F-D-05, F-A7) — đích có hàng rào ngay sau copy; (3) CI đích không đỏ ngày đầu + có guard (F-A3, F-A4, F-A9); (4) dependabot auto-merge + release token + codeql/release generic (F-A2, F-A1, F-A6); (5) allow list cho `/auto` (F-M01/M02); (6) maintain-cron/secret regex (F-S04/05/06/08/09/10); (7) test session Windows (F-Q6/Q9/Q10); (8) tài liệu (F-D-*, F-A5).

**Cần chủ repo (BLOCKED §3d — secret/chi phí mới):** tạo secret `RELEASE_PLEASE_TOKEN` (PAT fine-grained contents+pull-requests write hoặc GitHub App) ở repo khung và mỗi đích muốn release tự động (F-A1); có bật `anthropics/claude-code-action` (review/`@claude` trên PR) hay không — cần `CLAUDE_CODE_OAUTH_TOKEN`/API key; bật "Allow auto-merge" + "Automatically delete head branches" ở Settings của mỗi đích (guard mới sẽ đỏ cho tới khi bật).

## 4. Giới hạn trung thực
- Chạy ở Windows, không có `shellcheck` → cổng tổng `dev-task.sh gate` của khung BLOCKED tại máy này; CI Linux là nơi chứng minh.
- Chưa chạy hosted CI trên một repo đích thật; hành vi auto-merge dependabot với `strict_required_status_checks_policy: true` (cần rebase khi `main` tiến) cần kiểm trên repo thật.
- `test-adoption-smoke.sh` chỉ kiểm cấu trúc CI drop-in offline.
