# Feature spec: `dev-task.sh` đa stack thật (alias, venv, 8 stack mới) + hook git harness-agnostic

| Thuộc tính | Giá trị |
| --- | --- |
| Issue / Goal | `docs/reports/2026-09-23-de-xuat-nang-cap-khung-toan-dien.md` — Đợt 6 (T4, T8) |
| Spec owner | Phiên Claude Code (Tầng 1) |
| State | **Approved for implementation** |
| Approver / date | Người dùng (chủ repo) duyệt kế hoạch 7 đợt qua chat, 2026-09-23 |
| Last updated | 2026-09-23 |

> Không code khi chưa **Approved for implementation**.

## 1. Problem, user và evidence

- Dự án Node điển hình khai `type-check` (chính CLAUDE.md §5 dạy) nhưng `dev-task.sh` chỉ dò `typecheck` → cổng commit
  **bỏ qua type-check âm thầm** ("skip: chưa cấu hình"). Python chỉ nhận `pyproject.toml`, tra công cụ trong PATH toàn
  cục (venv chưa activate → no-op hoặc chạy nhầm binary). Bun ≥ 1.2 (`bun.lock`) bị coi là npm. `node_pm()` viết hai
  lần (dev-task, sweep) và đã lệch.
- CLAUDE.md §0b tuyên bố "mọi loại dự án" nhưng `dev-task.sh` chỉ dò node/python/go/rust/make — Java/Kotlin, .NET,
  Flutter/Dart, PHP, Ruby, Elixir, Deno, Swift no-op → cổng xanh giả.
- Hàng rào (chặn commit đỏ, bí mật, main) chỉ có trong Claude Code; harness khác chỉ có "hàng rào thủ công" trong
  AGENTS.md — kỳ vọng tự giác, không phải cổng.

## 2. Outcome, baseline, target và guardrails

| Đo | Baseline | Target |
| --- | --- | --- |
| Node `type-check` được dò | skip | `npm run type-check` (alias typecheck→type-check→tsc→check-types; lint→check; format→fmt) |
| Python trong venv/uv/poetry | PATH toàn cục | `.venv/bin/<tool>` → `uv run` → `poetry run` → PATH |
| Stack có lệnh cổng | 5 | 13 |
| Hàng rào ngoài Claude Code | không | `scripts/githooks/pre-commit` (main / bí mật / file lớn / gate) qua `core.hooksPath` |

Guardrails: mọi stack mới chỉ in lệnh khi có marker file thật; không dò được → rỗng (no-op), **không bịa lệnh**; khai báo
`.claude/project-commands.sh` vẫn thắng.

## 3. Research current state

`dev-task.sh` (đọc toàn bộ), `maintenance-sweep.sh` `node_pm`; lệnh chuẩn từng stack lấy từ công cụ chính thức
(mvn/gradlew, dotnet, dart/flutter, composer/phpstan/phpunit, bundler/rubocop/rspec, mix, deno, swift). Git
`core.hooksPath` là cơ chế chuẩn cho hook trong repo.

## 4. Alternatives và decision

| Option | Benefits | Cost/risk | Decision |
| --- | --- | --- | --- |
| Do nothing | 0 | cổng xanh giả ở dự án Node/Python phổ biến nhất | ✗ |
| A. Mỗi stack một hàm `_cmd_*` + `_stack-detect.sh` chung (chọn) | khớp kiến trúc sẵn có (CC ≤ 12/hàm), test được từng stack | copy list thêm 2 file | ✓ |
| B. Bảng `stacks.json` đọc bằng jq | thêm stack = thêm JSON | thêm phụ thuộc jq bắt buộc cho dev-task (nay tuỳ chọn), đổi kiến trúc | để sau nếu > 13 stack |

## 5. Scope / non-goals

Trong: `_stack-detect.sh`, `dev-task.sh` (alias, py_tool, 8 stack, `--print`, Rust `cargo check`), sweep dùng chung,
`scripts/githooks/pre-commit`, copy list, allowlist settings, test mới `test-dev-task.sh`. Ngoài: format-file cho stack
mới (chỉ per-file formatter phổ biến hiện có), `stacks.json`.

## 6. User journeys và mọi state

Dự án Node có `type-check` → hook chặn commit khi type-check đỏ (trước: bỏ qua). Dự án uv → `uv run pytest`. Dự án
.NET → `dotnet build/test`. Dev dùng Cursor: `git config core.hooksPath scripts/githooks` → commit trên main bị chặn.

## 7. Functional requirements

FR-1 `scripts/_stack-detect.sh`: `node_pm` (bun.lock/bun.lockb), `py_present`, `py_tool`; được `dev-task.sh` và
`maintenance-sweep.sh` source (một nguồn).
FR-2 `_cmd_node` thử alias theo thứ tự; `_cmd_python` dùng `py_tool`; Rust `typecheck` = `cargo check`.
FR-3 Thêm `_cmd_java` (maven/gradle), `_cmd_dotnet`, `_cmd_dart`, `_cmd_php`, `_cmd_ruby`, `_cmd_elixir`, `_cmd_deno`
(đứng trước Node), `_cmd_swift`; task không hỗ trợ → return 1.
FR-4 `dev-task.sh --print <task>` in lệnh phân giải, không chạy; task lạ → exit 2.
FR-5 `scripts/githooks/pre-commit`: chặn main/master (`ALLOW_COMMIT_ON_MAIN=1`), bí mật/file > 1 MB staged, `dev-task.sh
gate`; AGENTS.md hướng dẫn `core.hooksPath`; copy sang dự án đích.
FR-6 `settings*.json` allow: `dotnet`, `mvn`, `./gradlew`, `flutter`, `dart`, `composer`, `bundle exec`, `mix`, `deno`,
`swift` (hai file khớp).

## 8. Non-functional requirements

CC ≤ 12/hàm, thân `<main>` ≤ 45; ShellCheck 0; không dependency; chạy Git Bash Windows (`.venv/Scripts/*.exe`).

## 9. Acceptance criteria

AC-1 `test-dev-task.sh`: 13 stack fixture → đúng lệnh (bảng trong test); Node alias; Bun `bun.lock`; Python venv/uv/poetry/PATH;
Deno thắng Node; khai báo thắng tự dò; negative test gỡ alias → đỏ.
AC-2 `test-hooks-gate.sh` mục 13: `scripts/githooks/pre-commit` chặn trên main (exit 1), cho qua nhánh riêng diff sạch.
AC-3 `test-copy-framework.sh`: đích có `scripts/_stack-detect.sh` + `scripts/githooks/pre-commit`; smoke `dev-task.sh --print`
chạy được ở đích.
AC-4 `test-maintenance-sweep.sh` xanh sau khi sweep source `_stack-detect.sh` (kể cả trong dự án đích).

## 10. UX/content/accessibility

`--print` giúp dev thấy lệnh sẽ chạy trước khi tin cổng.

## 11. Architecture và code touchpoints

`scripts/_stack-detect.sh`, `scripts/dev-task.sh`, `scripts/maintenance-sweep.sh`, `scripts/githooks/pre-commit`,
`scripts/test-dev-task.sh`, `scripts/test-hooks-gate.sh`, `scripts/test-copy-framework.sh`, `copy-framework.sh`,
`copy-framework.ps1`, `.claude/settings.json`, `.claude/settings-shared-default.json`, `AGENTS.md`,
`.github/workflows/ci.yml`, `CODEMAP.md`, `CHANGELOG.md`.

## 12. API/event contract

CLI: `dev-task.sh format|lint|typecheck|test|build|gate|format-file <p>|--print <task>`.

## 13. Data contract/migration

Không. `_stack-detect.sh` là file mới ở dự án đích (copy_if_absent).

## 14. Security/privacy/abuse cases

Lệnh chỉ dựng từ marker file + hằng trong script, không từ input ngoài; `--print` không chạy gì.

## 15. Rollout, observability, rollback

Có hiệu lực khi merge; dự án đích nhận qua `copy-framework --upgrade`. Rollback: revert PR.
