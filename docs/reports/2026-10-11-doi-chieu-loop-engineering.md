# Đối chiếu cobusgreyling/loop-engineering → projects-template — 2026-10-11

Nguồn: `cobusgreyling/loop-engineering` @ `f914d15376ee963dd5bbedf9e22adf8bd3e61653` (HEAD `main`, push 2026-10-11T02:45Z;
clone `--depth 1` chỉ để đọc, **không chạy** script/CLI/`npx` nào của repo đó). Đích: `projects-template` @ `74d236f`
(`origin/main`). Phương pháp: `docs/framework/adopt-from-outside.md` (ba cột, cổng sự cố thật, **grep cổng đang chạy**, kiểm
mâu thuẫn luật §4).

Quy ước: đường dẫn có tiền tố `le:` là file của repo ngoài (vd `le:patterns/ci-sweeper.md`); không tiền tố là file của khung.

**Kết quả: 56 hạng mục (55 trong phạm vi + 1 nhóm cộng đồng/marketing) → lấy 0.** Sâu hơn 35 · Nông hơn 8 (đều "chưa cần",
không điểm nào có sự cố thật chưa được cổng phủ) · Chưa có 13 (12 "chưa cần" + 1 ngoài phạm vi). Chín điểm mâu thuẫn luật
(§Mâu thuẫn), phần lớn quy về một câu: loop-engineering mặc định **không tự merge, người duyệt mọi PR, leo thang tự trị theo
tuần**; khung mặc định **ủy quyền §2/§3d + auto-merge khi cổng xanh, chạy không giám sát chỉ ở mức báo cáo**. Một phát hiện
phụ do phép đo §3 lộ ra (không đến từ repo ngoài): văn xuôi `threat-model-maintain-cron.md` T6 đã lỗi thời so với cổng
TRAPS 37 — sửa một dòng trong cùng PR với báo cáo này.

## loop-engineering là gì (một đoạn, để bác lại được)

Một **thư viện mẫu vận hành agent quanh một codebase**, không phải runner: 8 pattern (Daily Triage, Thin loop, PR Babysitter,
CI Sweeper, Dependency Sweeper, Changelog Drafter, Post-Merge Cleanup, Issue Triage) mô tả nhịp chạy, state file, verifier,
điểm giao người; 7 skill (`loop-triage`, `loop-verifier`, `minimal-fix`, `loop-constraints`, `loop-budget`,
`budget-negotiator`, `install-loop`) + 14 mẫu skill trong `templates/` (`loop-guard`, `loop-intake`, `goal-scoper`,
`goal-verifier`…); 17 CLI npm trong `tools/` (`loop` front door, `loop-init`, `loop-audit` chấm điểm "Loop Ready" 0–100,
`loop-gate` cưỡng chế denylist/`maxFiles`/allowlist auto-merge từ `gate.yaml`, `loop-context` ledger + circuit breaker,
`loop-drill` diễn tập guardrail, `loop-worktree`/`loop-sandbox`/`loop-swarm` cô lập, `loop-cost`/`loop-metrics`,
`loop-sync`, `mcp-server`, `loop-action`, `goal-audit`/`goal-init`); tài liệu `docs/` (primitives, failure-modes,
anti-patterns, safety, operating-loops, multi-loop, checklist L0–L3); 22 "story" (thắng **và** thua). Repo tự chạy chính nó:
`daily-triage.yml` ghi `STATE.md` + `loop-run-log.md` mỗi ngày làm việc rồi mở PR cho người merge.

## Phép đo đã chạy (không đọc văn xuôi)

```bash
# Repo ngoài (chỉ đọc)
gh api repos/cobusgreyling/loop-engineering/commits/HEAD --jq .sha                       # f914d15…
grep -c '"tokens_estimate":52000' loop-run-log.md     # 22/22 lượt — hằng số cứng (daily-triage.yml:110)
python -I <quét Cc/Cf/bidi/tag-block>                  # chỉ fixture test + BOM ở loop-audit — không có chữ ẩn
gh api repos/cobusgreyling/loop-engineering/commits?path=scripts/github-triage.mjs     # sanitizer vào main 2026-10-10 (#641)

# Repo khung (origin/main)
git grep -n -i "3 lần|tối đa 3|max.attempt|circuit|stagnat" origin/main -- scripts .claude .github
    # → chỉ văn xuôi: coordinator.md:43,52, auto-complete.md:18, maintain.md:17; KHÔNG script nào đếm lần thử
git grep -n -i "lần thứ 4|quá 3 lần|lặp vô hạn|vòng lặp sửa" origin/main -- TRAPS.md docs/work docs/reports   # → 0 sự cố
git grep -n -i "prompt injection|untrusted|zero-width|bidi|invisible" origin/main               # ADR-0009 + 3 agent; 0 bộ lọc ký tự ẩn
git show origin/main:.github/workflows/stale-pr-alert.yml | sed -n 71,80p                         # chỉ ghi #số, tuổi, @tác giả, tên check
git show origin/main:scripts/maintenance-sweep.sh | sed -n 247,248p\;276,291p                    # TODO chỉ đếm; bí mật chỉ path:dòng + nhãn redacted
git show origin/main:scripts/maintain-run.sh | sed -n 94,139p                                     # luôn gọi CLI AI, kể cả 🔴0 · 🟡0
git log origin/main -40 --shortstat | awk …                                                        # 12/40 PR đã merge chạm > 10 file
git grep -n -i "mutation|mutant" origin/main -- docs                                               # spec 2026-09-12 dòng 93, 243: "Để mở, không chặn"
git grep -n "require_code_owner_review" origin/main -- .github                                     # rulesets/main.json:26 false (repo một người)
git grep -n "@[0-9a-f]{40}" origin/main -- scripts/check-ci-policy.sh                              # CP-2 ghim full SHA (dòng 124–137)
gh issue list --state all --limit 100                                                              # 2 issue cả đời repo
```

## Ba cột

### Đã có và SÂU HƠN (35)

| # | loop-engineering (file nguồn) | Ở khung | Sâu hơn ở chỗ nào |
|---|---|---|---|
| 1 | Daily Triage → `STATE.md` mỗi ngày (`le:patterns/daily-triage.md`, `le:scripts/github-triage.mjs`, `daily-triage.yml`) | `maintenance.yml` + `stale-pr-alert.yml` (thứ Hai, MỘT issue, đóng khi 🔴0·🟡0) + `PROGRESS.md` có cổng `progress-freshness` PF-1..4 | Khung có cổng đo trạng thái lệch git (TRAPS 8); bản ngoài mở một PR bot mỗi ngày — ở khung sẽ ăn trần WIP 3 (TRAPS 61). |
| 2 | Thin loop: một GitHub Action, gần như không file (`le:patterns/thin-loop.md`, `starters/thin-loop`) | `maintenance.yml`/`stale-pr-alert.yml` là đúng dạng đó, `permissions:` tường minh (TRAPS 4) + `test-workflow-guards.sh` | Ngang về hình thức; khung có test cho workflow, bản ngoài không. |
| 3 | PR Babysitter 5–15 phút (`le:patterns/pr-babysitter.md`) | `pr-flow.md:10` subscribe + check-in 5 phút; `coordinator.md:52` CI đỏ → tắt auto-merge, 3 lần → BLOCKED | Đã đối chiếu ở báo cáo compound-engineering; khung có luật dừng + FIFO + WIP bằng cổng `pr-policy.yml:28-35`. |
| 4 | Dependency Sweeper patch-only, verifier `npm ci && npm test` (`le:patterns/dependency-sweeper.md`) | Dependabot nhóm multi-ecosystem + `dependabot-auto-merge.yml:32-40` (patch/minor tự merge, major chờ người) + `/deps-upgrade` + TRAPS 7/34/61 | Khung có 3 sự cố dependency đã thành cổng; bản ngoài là prompt. (Mâu thuẫn về auto-merge dep: §Mâu thuẫn C3.) |
| 5 | Changelog Drafter: LLM soạn release notes (`le:patterns/changelog-drafter.md`) | release-please sinh từ conventional commits + job `metadata` + `_commit-guard.sh` | Tất định từ type commit; bản ngoài tự liệt kê rủi ro "hallucinated features" trong chính pattern. |
| 6 | Post-Merge Cleanup (`le:patterns/post-merge-cleanup.md`) | `coordinator.md:46` dọn worktree (DỪNG nếu bẩn) + `maintenance-sweep.sh:104` nhánh đã merge + `progress-freshness` | Khung có cổng; bản ngoài là lịch chạy agent. |
| 7 | Maker/checker: verifier riêng, mặc định REJECT, tự chạy test (`skills/loop-verifier`, `anti-patterns.md` #1) | `reviewer.md` (`review-findings/1`, `review-check` loại finding không căn cứ) + `tester` + evidence gắn HEAD/config/worktree (`_dev-task-verify.sh:12-34`) | "Verifier tự chạy test" ở khung là **bằng chứng máy không giả được**, không phải lời verifier khai lại. |
| 8 | `minimal-fix`: diff nhỏ nhất, một vấn đề, không tiện tay refactor (`skills/minimal-fix`) | CLAUDE.md §3.4 thang 6 nấc + §3.6 `fix:` cần test đỏ-trước + `coordinator.md:51` chạm file ngoài `path` → loại kết quả | Khung bắt test tái hiện đỏ trước khi sửa; bản ngoài chỉ "reproduce if possible". |
| 9 | `STATE.md` có `Last run`, prune mục đã đóng mỗi lượt (`primitives.md`, `failure-modes.md` State Rot) | `PROGRESS.md` + `working.md`/`done.md` + `check-progress-freshness.sh` + docs-consistency mục 13 | Sự cố State Rot của khung (TRAPS 8, tái phát #245) đã có cổng CI; bản ngoài prune bằng lời dặn. |
| 10 | Run log append-only (`loop-run-log.md`, `append-run-log.mjs`) | `telemetry-log.sh` (`telemetry-record/2`, token thật từ transcript, thiếu = `null`) + `test_telemetry_integrity.py` (CODEMAP:66) | Đo được: **22/22** lượt trong log ngoài ghi `tokens_estimate: 52000` cứng (`daily-triage.yml:110`); khung cấm số "trông hợp lý" (CODEMAP:44, TRAPS 32/33). |
| 11 | `loop-cost`: ước tính token theo nhịp/pattern (`tools/loop-cost`) | `usage-estimate.sh` + `model-rates.json` + `usage-guard.sh` (đo % quota từ transcript) | Khung đo thực tế thay vì nhân một hằng số theo pattern — chính hằng số đó sinh ra số 52000 ở dòng 10. |
| 12 | `loop-metrics` ROI: +10 mỗi action, −5 mỗi escalation (`tools/loop-metrics`) | telemetry `--outcome accepted` cần `--evidence` gate PASS (LD-07) | Khung tính kết quả theo bằng chứng; công thức ngoài phạt leo thang — ngược §9 (xem C8). |
| 13 | `loop-sync`: báo lệch `safety.md` ↔ `gate.yaml` (`tools/loop-sync`) | `check-docs-consistency.sh` (13 mục) + `protection-guard` so ruleset live (TRAPS 35) + CLAUDE.md ↔ AGENTS.md mục 7 | Khung phủ nhiều cặp nguồn hơn và chạy trong CI bắt buộc. |
| 14 | `loop-drill` gate/breaker: mỗi guardrail một ca phải chặn + một ca lành phải qua; bằng chứng gắn sha256 `gate.yaml` (`tools/loop-drill`, `loop-drill.json`) | `test-hooks-gate.sh` "mỗi khuôn một ca chặn + một ca không chặn oan" (CODEMAP:45); evidence gắn `config_sha` (`_dev-task-verify.sh:12`) | Cùng nguyên lý sensitivity/specificity; khung chạy trên Linux + Windows trong CI, không cần file record tự khai. |
| 15 | `loop-audit` Loop Ready 0–100, "present is not proven", lượt gần đây nặng hơn file (`le:tools/loop-audit/README.md`) | `arch-health-radar.sh` + `check-ci-policy.sh` CP-6 (test phải có job gọi, TRAPS 25) + `test-check-scripts.sh` (TRAPS 11/12) + `progress-freshness` | Khung kiểm "code có nối cổng" bằng máy; câu chuyện `le:stories/thirty-weekday-runs.md` của chính họ: điểm 100 che 22 lượt report-only. |
| 16 | Phối hợp nhiều loop: thứ tự ưu tiên, `acting_on`, state riêng mỗi loop (`le:docs/multi-loop.md`) | WIP + FIFO (`pr-policy.yml`; trần 3 lúc đo, nâng 5 cùng ngày), trần 5 subagent (ADR-0011), "chung file/lockfile/migration → tuần tự" (`standard-delivery.md:105`) | Khung có cổng đếm; `acting_on` ngoài là quy ước tay. |
| 17 | `loop-intake`: làm rõ mục tiêu mơ hồ trước khi hành động (`templates/SKILL.md.loop-intake`) | `/grill` (đợt + đề xuất + tự tra sự kiện) + CLAUDE.md §9 | Khung không hỏi điều tự tra được; "một câu mỗi lần" mâu thuẫn `/grill` (C5). |
| 18 | Goal engineering: `GOAL.md`, `goal-scoper`, `goal-verifier`, `goal-audit` (`templates/GOAL.md.template`, `tools/goal-*`) | `docs/goals/` + Goal Loop `standard-delivery.md:220-227` + spec Approved (cổng `pr-policy.yml`) + `spec-compiler.sh --trace` | AC→test bằng máy; `goal-verifier` in "VERIFIER: PASS" là lời khai. Ghi chú cũ vẫn đúng: goal file chưa có cổng (đối chiếu ralph, đính chính B). |
| 19 | `loop-constraints.md` "binding", skill đọc đầu mỗi lượt và in "N rules active" (`skills/loop-constraints`) | CLAUDE.md tự nạp mỗi phiên + hook `block-dangerous-git.sh`/`pre-commit-gate.sh` + `settings.json` deny (dòng 95-120) | Khung **chặn bằng máy**; bản ngoài nhờ model tự đọc lại luật trước mỗi hành động. |
| 20 | An toàn test: không tắt test, không tăng timeout mù, cách ly flake (`le:docs/safety.md`, `stories/ci-sweeper-symptom-patching…`) | Sổ lối thoát coverage/skip "so bằng đúng" (`quality-supplements-group2.md:136-170`), golden không `-u`, `/debug` cho chập chờn | Khung có phép đếm lệch-chiều-nào-cũng-đỏ; bản ngoài là lời dặn. |
| 21 | Redact bí mật trước khi ghi state (`le:docs/safety.md`) | `maintenance-sweep.sh:276-291` chỉ ghi `path:dòng [credential-like match — redacted]` + `test-maintenance-sweep.sh` mục 3 (TRAPS 37) | Khung có sự cố thật + test; bản ngoài là câu dặn skill. |
| 22 | Ứng phó sự cố khi loop merge code xấu + checklist trước L3 (`le:docs/safety.md`) | `docs/ops/incident-response.md` + `/incident` + Security acceptance của threat model + `standard-delivery.md` §9 (automation → threat model trước) | Khung có mẫu post-mortem và threat model có test; bản ngoài 4 bước văn xuôi. |
| 23 | Catalog failure mode S1–S3 + anti-patterns + 22 story có token/nguyên nhân (`le:docs/failure-modes.md`, `stories/`) | `TRAPS.md` 69 mục: khuôn → cách rà → **cổng chốt chặn** → tái phát | Mỗi mục TRAPS phải chỉ ra cổng; story ngoài dừng ở "Lesson". |
| 24 | "Post-Run Critique": mỗi lượt ghi một thay đổi cho lượt sau (`patterns/*.md`) | Cổng Reconcile (`standard-delivery.md:42`) + TRAPS sau mỗi bug + re-audit hội tụ `/completion` | Khung biến bài học thành cổng; critique ngoài không có nơi nhận. |
| 25 | Chỉ báo khi cần người quyết, digest cho report-only (`failure-modes.md` Notification Fatigue) | `maintenance.yml:69-82` một issue, chỉ issue do workflow tạo (người ngoài chèn MARKER không chiếm được), tự đóng khi sạch | Khung còn chặn chiếm kênh báo cáo — thứ bản ngoài chưa nghĩ tới. |
| 26 | Front door `loop init/doctor/status`, exit 0/1/2 (`tools/loop`, `tools/loop-init`, `skills/install-loop`) | `copy-framework.sh`/`copy-framework.ps1` + manifest + `test-copy-framework.sh`; `dev-task.sh gate` PASS/FAIL/BLOCKED; `new-work.sh` | Có smoke test idempotent ở dự án đích (TRAPS 15/30); `doctor` ngoài chấm file. |
| 27 | Registry pattern YAML + schema + validate (`patterns/registry.yaml`, `validate-registry.mjs`) | `model-capability-tiers.json` + `copy-framework.manifest` + docs-consistency mục 4 (route ↔ agent) | Ngang; không có gì để lấy. |
| 28 | Đa công cụ: Claude/Grok/Codex/OpenCode/Cursor/Windsurf/Hermes/OpenClaw (`examples/`, `starters/*-opencode`) | `maintain-run.sh` 6 harness có test + `subagent-dispatch.sh --harness generic` + `AGENTS.md` | Khung chỉ liệt kê harness đã xác minh cú pháp (`verify_before_use`); thêm harness = theo điều kiện cũ. |
| 29 | Plugin manifest `.claude-plugin/` | Ranh giới đã ghi (đối chiếu X-Agents v2): template không vendor plugin, phát qua manifest | Không đổi. |
| 30 | Bộ nhớ ba tầng L1/L2/L3 (`le:templates/memory-tiers.md`) | CLAUDE.md/PROGRESS/working/TRAPS/ADR + hook `session-resume.sh`/`precompact-checkpoint.sh` | Khung nạp lại tự động bằng hook; mẫu ngoài là danh sách 9 dòng. |
| 31 | Lộ trình refactor: một todo = một worktree = một PR (`le:docs/refactor.md`) | §3c S/M/L, "một outcome một PR", `--check-plan` (TRAPS 59), `/audit-optimize` PR riêng | Khung có cổng brief; bản ngoài là hướng dẫn. |
| 32 | Ruleset `main` commit vào repo (`le:.github/ruleset-main-protection.json`) | `.github/rulesets/main.json` + `protection-guard` so live (TRAPS 35) | Khung phát hiện ruleset live yếu hơn file; bản ngoài chỉ lưu file. |
| 33 | Mục "Untrusted input" chép vào mọi skill đọc văn bản bên thứ ba, giữ đồng nhất bằng `sync-untrusted-input.mjs --check` trong CI | ADR-0009 một nguồn ở CLAUDE.md §4 (mọi phiên **và subagent** đều nạp — chính subagent đối chiếu này nhận nó) + AGENTS.md cho harness khác + 3 agent nhắc lại + docs-consistency mục 7 | Bản ngoài phải đồng bộ 55 bản vì skill phát tán rời; khung tránh được nguồn lệch bằng một nguồn. Xem đính chính (B). |
| 34 | Ghi văn bản bên thứ ba vào state ở dạng trơ: code span, bỏ Cc/Cf, cắt 160 ký tự (`github-triage.mjs:30-56`) | Khung **không chép** tiêu đề/thân PR-issue vào file agent đọc lại: `stale-pr-alert.yml:79` chỉ `#số`, tuổi, `@tác giả`, tên check; sweep chỉ đếm TODO (`:247-248`) | Không có đường "giặt" văn bản để phải lọc; sanitizer ngoài mới vào `main` 2026-10-10 (PR #641). Xem đính chính (C). |
| 35 | Thang tự trị L0→L3, tuần đầu report-only, leo khi verifier đúng một tuần (`loop-design-checklist.md`, `operating-loops.md`) | Đường không giám sát duy nhất khoá cứng ở mức báo cáo (`maintain-cron.sh` chỉ ghi `docs/ops/MAINTENANCE-*.md`, `test-maintain-cron.sh`); trong phiên: ủy quyền §3d | Khung khoá bằng test thay vì thang tự leo; leo lên L2+ chính là câu hỏi đã quyết "chưa" ở đối chiếu ralph. |

Cộng thêm (gộp vào dòng 22/19): bảng quyền tối thiểu cho connector MCP (`safety.md`) ↔ `permissions:` tường minh mỗi job
(TRAPS 4) + `GITHUB_TOKEN`/`GH_TOKEN` unset khi gọi CLI AI (threat model T3, `test-maintain-cron.sh` 10a).

### Đã có nhưng NÔNG HƠN (8) — chỉ ra đúng điểm nông; không điểm nào qua cổng §2

| # | Hạng mục | Điểm nông CỤ THỂ | Sự cố thật? | Quyết định |
|---|---|---|---|---|
| N1 | Trần 3 lần + circuit breaker tất định (`loop-context` ledger: stagnation theo độ giống lỗi, no-progress, trần lượt, token; từ chối cấu hình làm tắt luật; `templates/SKILL.md.loop-guard`) | Khung có **cùng trần 3** (`standard-delivery.md:227`, `coordinator.md:43,52`) nhưng **không có bộ đếm máy** — grep `scripts .claude .github` ra 0 script đếm lần thử | Không: grep "quá 3 lần/lặp vô hạn/vòng lặp sửa" ở TRAPS/work/reports → 0. (Đồng bộ `main` 5 lần ở #263 là `BEHIND` do lane khác merge, không phải sửa cùng failure — TRAPS 48.) | **Chưa cần.** Trần do Tầng 1 có người trong vòng tự giữ. **Xem lại khi:** chủ repo mở runner sửa source không giám sát (điều kiện (b) báo cáo ralph — khi đó bộ đếm phải là máy, đọc từ goal file/CI), hoặc một hồ sơ ghi > 3 lần sửa cùng failure. |
| N2 | Verifier chạy model mạnh hơn implementer cho việc không giám sát (`failure-modes.md` Verifier Theater, `operating-loops.md`) | `reviewer` = Sonnet·medium soát cả output của `complex-implementer` Opus (`model-capability-tiers.json`, `reviewer.md` frontmatter) | Không: `2026-10-09-agent-acceptance.md:14` — reviewer Sonnet bắt lỗi THẬT mà #229 bỏ sót; không ghi nhận lỗi nào lọt reviewer | **Chưa cần**; khung bù bằng evidence máy. **Xem lại khi:** một lỗi lọt `reviewer` trên việc `route:complex` rồi CI/audit sau mới bắt được. |
| N3 | Thoát sớm khi không có gì để làm (< 5k token, không spawn) (`skills/loop-budget`, `operating-loops.md`) | `maintain-run.sh:94-139` luôn dựng prompt và gọi CLI AI, kể cả khi sweep ra 🔴 0 · 🟡 0 | Không có sự cố chi phí. Đo hai chiều: 2/3 đợt trong `MAINTENANCE-LOG.md` là 0/0 (thoát sớm sẽ tiết kiệm), nhưng đợt 2026-09-19 0/0 vẫn ra 1 phát hiện nhờ rà tay | **Chưa cần.** **Xem lại khi:** cron chạy dày hơn hằng tuần, hoặc telemetry `--agent maintainer` cho thấy lượt 0/0 tốn đáng kể quota. Xem đính chính (A). |
| N4 | Leo thang theo ĐƯỜNG DẪN nhạy cảm (auth/payments/migrations/infra) + `maxFiles: 10` (`gate.yaml`, `tools/loop-gate`) | `CODEOWNERS` chỉ auto-assign (`require_code_owner_review: false`, `rulesets/main.json:26`); ở đích là ô checklist `repository-settings.md:75`; không cổng máy theo path | Không. Đo `maxFiles`: **12/40** PR merge gần nhất chạm > 10 file (mỗi PR mang `docs/work` + `PROGRESS` + `CHANGELOG`) → 30% leo thang oan | **Chưa cần** cho path-gate (xem lại khi một PR auto-merge chạm auth/payments/migration ở dự án đích mà không qua `security-reviewer`). **`maxFiles` không lấy kể cả khi có sự cố** — dương tính giả đã đo (C4). |
| N5 | Canary cho verifier: gieo N lỗi vào code, verifier phải từ chối; canary injection (`tools/loop-drill` `--only verifier/injection`) | Khung có thực hành negative test theo từng ca (TRAPS 20 "Cách rà", `test-py-coverage-exit.sh` cho TRAPS 39) nhưng không phép đo chung "suite có đỏ khi code bị phá" | **Có** họ sự cố test xanh giả: TRAPS 20, 31, 39 — nhưng mỗi mục đã có cổng riêng, chưa tái phát | **Không lấy, đưa lại cho chủ repo:** đã có quyết định mở `docs/specs/2026-09-12-golden-tests-and-tdd.md:93,243` ("Mutation testing… để mở, không chặn", người quyết: người dùng). §4: không tự hoà giải. Xem đính chính (E). Canary injection: chưa cần (0 sự cố injection). |
| N6 | Worktree mỗi lần thử + manifest + dọn mồ côi + khoá path tư vấn (`tools/loop-worktree`, `le:docs/multi-loop.md`) | `coordinator.md:34-46` mạnh hơn về an toàn (bỏ qua nếu đã cô lập, DỪNG khi worktree bẩn, không đụng worktree không tự tạo) nhưng không có bộ quét worktree mồ côi và không khoá giữa phiên | TRAPS 63 (một lần) — nhưng khoá path giữa các worktree **không** bắt được ca "hai phiên MỘT checkout" (và `loop-worktree create` không tự kiểm khoá) | **Chưa cần**; DEBT ở TRAPS 63 đã có điều kiện riêng ("tái phát lần 2"). Xem đính chính (D). |
| N7 | Ngân sách token theo loop/ngày, 80% → report-only, nhãn kill switch `loop-pause-all` (`loop-budget.md`, `skills/loop-budget`) | `usage-guard.sh` chỉ nhắc wind-down một lần ở ngưỡng quota 5h (không chặn cứng); không trần/ngày, không nhãn tạm dừng | Không: grep "quota/đốt token/hết quota" ở TRAPS/work → 0 sự cố | **Chưa cần**: đường không giám sát duy nhất là một cron tuần, có `flock` (T5). **Xem lại khi:** có loop chạy dày hơn ngày, hoặc một lượt cron đo được vượt quota. |
| N8 | Khi gắn cờ injection, **không chép nguyên văn** đoạn đáng ngờ vào output/state — chỉ trỏ số/path (khối `untrusted-input` trong mọi skill) | `maintainer.md:23` bảo "ghi vào kế hoạch dưới mục DỪNG & HỎI" nhưng không cấm chép nguyên văn; `MAINTENANCE-PLAN.md` được commit lên nhánh `maint/auto-*` | Không: `maintain-cron` chưa ghi nhận lượt thật nào gặp văn bản chỉ thị | **Chưa cần.** **Xem lại khi:** một kế hoạch tự sinh (`maint/auto-*`) chứa văn bản chỉ thị chép từ nguồn ngoài. Phiên tương tác không đổi: trích cho người dùng là đúng (ADR-0009 §2). |

### CHƯA CÓ (13) — không lấy, kèm điều kiện xem lại

| # | Hạng mục (file nguồn) | Quyết định |
|---|---|---|
| X1 | CI Sweeper: agent tự sửa CI đỏ, L2/L3 (`le:patterns/ci-sweeper.md`) | **Chưa cần + mâu thuẫn (C6):** sửa source không giám sát = câu hỏi đã quyết "chưa" ngày 2026-10-10 (báo cáo ralph). Xem lại cùng điều kiện (b) ở đó. |
| X2 | Issue Triage (`le:patterns/issue-triage.md`) | Chưa cần: đo `gh issue list --state all` → **2 issue** cả đời repo. Xem lại khi repo/dự án đích nhận issue từ người ngoài đều đặn (vd > 5/tuần). |
| X3 | Tỉa ngữ cảnh tất định: tóm tắt lần thử, gộp lỗi lặp, chỉ tiêm phần cốt lõi (`loop-context --inject`) | Chưa cần: chỉ có nghĩa với vòng lặp ngoài nhiều lượt; khung có `precompact-checkpoint.sh` + `session-resume.sh` + §5.2.1. Xem lại cùng điều kiện (a) báo cáo ralph (phiên > 450k hoặc mất ngữ cảnh tái hiện được). |
| X4 | `budget-negotiator`: agent xin thêm ngân sách, cấm tự nâng trần (`skills/budget-negotiator`) | Chưa cần: không có trần/ngày để thương lượng (N7). Xem lại khi N7 được lấy. |
| X5 | `loop-sandbox`: chạy agent trong worktree tạm, thu patch, xoá worktree (`tools/loop-sandbox`) | Chưa cần: phục vụ sửa source không giám sát (điều kiện (b) ralph). Bản thân README thừa nhận agent vẫn thoát được worktree. |
| X6 | `loop-swarm`: N lượt, chỉ nhận patch trùng từng byte theo đa số (`tools/loop-swarm`) | Chưa cần: tốn ×N, không có sự cố patch bất định; README tự nêu hai bản đúng ngữ nghĩa khác khoảng trắng bị coi là lệch. |
| X7 | MCP server phục vụ tài liệu loop theo yêu cầu (`tools/mcp-server`) | Chưa cần: CLAUDE.md §1 đã là "con trỏ + đọc khi liên quan" (tiết lộ dần), không có sự cố tràn ngữ cảnh do tài liệu. |
| X8 | Fork PR gate qua `pull_request_target`, không checkout code PR (`le:.github/workflows/fork-pr-gate.yml`) | Chưa cần: repo một chủ, không PR fork. Xem lại khi dự án đích nhận PR fork và required check kẹt (cùng họ TRAPS 5b). |
| X9 | `loop-action`: composite Action chạy lệnh agent trong CI (`tools/loop-action`) | **Chưa cần + mâu thuẫn (C6, C9):** agent chạy trong CI đã có câu hỏi treo `claude-code-action` (BLOCKED chờ chủ repo, `PROGRESS.md`); mẫu dùng `@main` không ghim SHA. |
| X10 | Từ vựng: intent debt, comprehension debt, cognitive surrender, orchestration tax (`le:docs/concepts.md`) | Chưa cần: từ vựng, không sự cố. Nếu cần thì vào `CONTEXT.md` của dự án đích, không vào khung. |
| X11 | Fleet inbox/registry cho nhiều agent nhắn nhau (`templates/fleet-*.md`) | Chưa cần: Tầng 1 giữ kế hoạch, agent không nhắn ngang (orchestration-3-tier); chưa có sự cố phối hợp ngang. |
| X12 | Dò ký tự vô hình/bidi/tag-block trong văn bản đưa cho agent | Chưa cần: khung không chép văn bản bên thứ ba vào state (dòng 34), GitHub tự cảnh báo bidi trong diff. Xem lại khi khung bắt đầu chép tiêu đề/thân PR-issue vào file agent đọc lại, hoặc nhận PR fork. |
| X13 | Cộng đồng/marketing: adopters, area owners, star history, badge `last-run.json`, showcase, README zh-CN, script `good first issue`, GIF demo | Ngoài phạm vi (không phải thực hành phát triển). |

## Mâu thuẫn luật (§4 của phương pháp) — không tự hoà giải

| # | loop-engineering | Luật đang có ở khung | Hệ quả nếu chép |
|---|---|---|---|
| C1 | "Default: no auto-merge" + allowlist path (`le:docs/safety.md` Auto-Merge Policy, `gate.yaml autoMergeAllowlist`, `AGENTS.md` "Never auto-merge…") | CLAUDE.md §8 + `pr-flow.md:10`: **bắt buộc** bật auto-merge khi mô tả đủ và cổng xanh | Đảo ngược luật merge cốt lõi; mọi PR chờ người. Quyết định của chủ repo, không của phiên. |
| C2 | `loop-constraints.md`: "Don't push before telling me", "Always tell me what you're about to do", "Always create a draft PR first" | CLAUDE.md §2 ủy quyền toàn cục + `standard-delivery.md` §3d: không hỏi lại việc đã giao | Cấy lại đúng kiểu hỏi-xin-phép mà §3d loại bỏ. |
| C3 | Human gate cho **mọi** nâng dependency; "Dependency version bumps" không được auto-merge (`le:docs/safety.md`) | `dependabot-auto-merge.yml:32-40` tự merge patch/minor (quyết định F-41a, TRAPS 61) | Bản vá bảo mật đọng lại — chính sự cố F-001/W-105 (`stale-pr-alert.yml:3-6`: PR bảo mật kẹt 19 ngày). |
| C4 | `maxFiles: 10` → leo thang (`gate.yaml`, `safety.md` Human Gates) | §2/§3c phiên chính chọn số PR; PR mang hồ sơ + PROGRESS + CHANGELOG cùng PR (§8 bước 0) | Đo: 30% PR merge gần nhất leo thang oan. |
| C5 | `loop-intake`: hỏi **một câu mỗi lần** | `/grill`: hỏi theo **đợt**, mỗi câu kèm đề xuất, tự tra sự kiện | Đúng ví dụ ghi sẵn ở `adopt-from-outside.md` §4. |
| C6 | Loop sửa code không giám sát L2/L3 (CI Sweeper, Dependency Sweeper L2, `loop-action` + `loop-sandbox`) | Threat model `maintain-cron` (chỉ ghi báo cáo) + quyết định 2026-10-10 "chưa" runner xây dựng không giám sát | Mở đường ghi source không người duyệt tại chỗ — §9 "quyền mới". |
| C7 | Bot mở PR cập nhật `STATE.md`/`loop-run-log.md` mỗi ngày (`daily-triage.yml:140`) | Trần WIP đếm cả bot (`pr-policy.yml:28`; 3 lúc đo, nâng 5 cùng ngày), TRAPS 61 | PR của người kẹt sau PR bot — sự cố đã mắc. |
| C8 | ROI = +10 × action − 5 × escalation (`tools/loop-metrics`) | §9 + Goal Loop: BLOCKED/hỏi đúng lúc là hành vi đúng | Thước đo khuyến khích agent né leo thang. |
| C9 | `uses: cobusgreyling/loop-engineering/tools/loop-action@main` (`le:tools/loop-action/README.md`) | `check-ci-policy.sh` CP-2 (dòng 124–137): mọi `uses:` ghim full SHA | Đỏ cổng chuỗi cung ứng ngay. |

## Đính chính giữa chừng (giữ nguyên dấu vết)

- **(A)** Lúc đọc `skills/loop-budget` định xếp "thoát sớm khi không có gì" vào **lấy** — rẻ (vài dòng ở `maintain-run.sh`),
  lợi rõ. Đo `MAINTENANCE-LOG.md`: 2/3 đợt là 🔴0·🟡0 (ủng hộ), nhưng đợt 2026-09-19 0/0 vẫn ra một phát hiện nhờ rà tay
  (phản bác: 0/0 của máy ≠ không có gì), và không có sự cố chi phí nào. Hạ xuống N3 "chưa cần".
- **(B)** Định xếp mục "Untrusted input" vào **nông hơn** vì chỉ 3/11 agent của khung nhắc lại ADR-0009 (`version-check` đọc web
  và `reviewer` đọc diff PR thì không). Kiểm lại: CLAUDE.md §4 được nạp vào **mọi** phiên và subagent Claude Code (subagent
  đối chiếu này nhận nguyên văn), AGENTS.md phủ harness khác, docs-consistency mục 7 giữ hai bản khớp. Lý do bản ngoài cần 55
  bản sao + script sync là skill của họ phát tán rời từng file — vấn đề khung không có. Chuyển sang dòng 33 "sâu hơn".
- **(C)** Định xếp "ghi văn bản bên thứ ba dạng trơ (bỏ ký tự ẩn, code span)" vào **chưa có**. Đo: khung không có đường nào chép
  tiêu đề/thân PR-issue vào file agent đọc lại (`stale-pr-alert.yml:79`, `maintenance-sweep.sh:247-248,284`). Vector mà
  sanitizer ngoài canh không tồn tại ở đây → dòng 34; phần "dò ký tự ẩn" còn lại tách thành X12. Ghi thêm: chính repo ngoài
  chỉ có sanitizer từ 2026-10-10 (`STATE.md` ngày 10-09 còn tiêu đề trần) — văn xuôi `safety.md` mô tả cổng **mới hơn** output
  đang commit, đúng chiều ngược của bẫy §3.
- **(D)** Định ghép `loop-worktree lock` với TRAPS 63 làm ứng viên "nông hơn có sự cố". Đọc lại TRAPS 63: nguyên nhân là **hai
  phiên trên MỘT working tree** (`git switch` mang staged change), còn khoá của `loop-worktree` là khoá path tư vấn giữa các
  worktree và `create` không tự kiểm khoá — không bắt được ca đó. Loại khỏi ứng viên; DEBT của TRAPS 63 giữ điều kiện riêng.
- **(E)** Định xếp "canary verifier" vào **chưa có + có sự cố** (TRAPS 20/31/39 đều là test xanh giả). Grep `mutation` trong
  `docs/` ra quyết định mở có chủ ở `docs/specs/2026-09-12-golden-tests-and-tdd.md:243` — người dùng để mở. Theo §4 không tự
  hoà giải: xếp N5, nêu lại cho chủ repo, không lấy. Nếu chủ repo mở lại: hình thức rẻ nhất học từ `loop-drill` là "gieo vài lỗi
  cố định vào một script, suite phải đỏ" (cùng dạng `test-py-coverage-exit.sh` đã có), không cần công cụ mutation tổng quát.
- **(F)** Phát hiện phụ của §3 (văn xuôi nói sai so với cổng): `docs/ops/threat-model-maintain-cron.md` dòng T6 ghi *"sweep chỉ in
  160 ký tự đầu mỗi dòng nghi bí mật … vẫn có thể lộ tiền tố khoá"*; nhưng từ TRAPS 37 (2026-10-05) `maintenance-sweep.sh:278-284`
  chỉ ghi `path:dòng [credential-like match — redacted]`, `cut -c1-160` (dòng 291) chỉ còn cắt chính chuỗi đã redact. Câu này
  sẽ khiến người sau tưởng còn rủi ro lộ tiền tố và làm lại việc đã xong.

- **(G)** Phiên chính, khi chốt báo cáo vào repo: bản nháp trích `proof.test.mjs` sai thư mục (ghi như ở gốc repo ngoài);
  file thật là `le:tools/loop-audit/test/proof.test.mjs` — cổng link của khung bắt được. Kết luận dòng đó không đổi.

## Chỉ thị trong repo ngoài (ghi như phát hiện, không làm theo)

Không thấy chỉ thị độc hại hay chữ ẩn. Quét Cc/Cf/bidi/tag-block: chỉ có trong fixture test (`le:scripts/github-triage.test.mjs`)
và xử lý BOM (`le:tools/loop-audit/src/auditor.ts`, `le:tools/loop-audit/test/proof.test.mjs`) — hợp lệ. Comment HTML trong `.md`: chỉ mẫu PR/khung
skill. Các câu dạng mệnh lệnh nhắm agent (đều dành cho loop vận hành repo đó, đã đọc như dữ liệu):
- `loop-constraints.md:3-4` — "Constraints here are **binding** — the agent MUST follow them."
- `le:skills/install-loop/SKILL.md` — bảo agent chạy `npx @cobusgreyling/loop init …`/`doctor` (không chạy).
- `le:skills/budget-negotiator/SKILL.md` — bảo agent ghi `[BUDGET NEGOTIATION]` vào `STATE.md` và tự treo.
- `README.md`/`AGENTS.md` — khuyến khích `npx @cobusgreyling/*` và `uses: …/loop-action@main` (không ghim) — không chạy.

## Danh sách thực sự lấy

**Từ repo ngoài: không có.** Đề xuất duy nhất là phát hiện phụ (F), không đến từ loop-engineering:
- Sửa dòng T6 của `docs/ops/threat-model-maintain-cron.md` cho khớp cổng TRAPS 37 (sweep chỉ ghi `path:dòng` + nhãn redacted;
  rủi ro còn lại là lộ **vị trí**, không lộ tiền tố). Sự cố thật: TRAPS 37. File chạm: `docs/ops/threat-model-maintain-cron.md`
  (+ hồ sơ `docs/work/<id>/` + con trỏ `PROGRESS.md` theo §2). Mức S, `docs:`, không cần test đỏ-trước (ngoại lệ 3).

## Quyết định cần chủ repo (không tự quyết)

1. **Mutation/canary verifier (N5):** quyết định đang mở từ spec 2026-09-12 dòng 243. Đối chiếu này thêm dữ kiện: họ sự cố test
   xanh giả có 3 mục (TRAPS 20/31/39), cả ba đã có cổng riêng, chưa tái phát. Đề xuất của phiên: **giữ để mở**; xem lại khi một
   mục test-xanh-giả tái phát hoặc mục thứ tư xuất hiện.
2. Các mâu thuẫn C1–C9 không cần quyết mới: đều trùng quyết định đã có (auto-merge §8, §3d, F-41a, ralph 2026-10-10, CP-2).
