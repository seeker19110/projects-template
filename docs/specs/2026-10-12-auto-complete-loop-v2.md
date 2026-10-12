# Feature spec: Vòng lặp `/auto-complete` v2 — trạng thái máy tính, verdict có kiểu, workflow tham chiếu

| Thuộc tính | Giá trị |
| --- | --- |
| Issue / Goal | Yêu cầu chủ repo 2026-10-12 "thiết kế lại vòng lặp để tự động code hoàn thiện dự án, thiết kế cả workflow, tham khảo stored và các nguồn khác". Goal `docs/goals/2026-10-12-auto-complete-loop-v2.md`; hồ sơ `docs/work/2026-10-12-redesign-auto-complete-loop/working.md` |
| Spec owner | Phiên chính |
| State | **Approved for implementation** |
| Approver / date | Phiên chính duyệt theo ủy quyền toàn cục (`standard-delivery.md` §3d) sau research 4 nguồn; 2026-10-12 |
| Last updated | 2026-10-12 |

> Mức **L** (đổi lệnh tự động cốt lõi + hook Stop + engine mới, 2 PR mã + 1 PR đóng hồ sơ). ADR: `docs/adr/0012-trang-thai-vong-lap-may-tinh.md`.
> Đối chiếu ba cột: `docs/reports/2026-10-12-thiet-ke-lai-vong-lap.md`. Workflow tham chiếu: `docs/framework/auto-complete-workflow.md`.

## 1. Problem, user và evidence

Người dùng bật `/auto-complete` và muốn phiên chạy tới xong mà không phải gõ "tiếp tục". Hôm nay (kiểm kê 2026-10-12, báo cáo §1):
bước kế tiếp mỗi lượt do model đọc 3–6 tài liệu rồi tự suy; hook giữ lượt chỉ đọc 1 dòng trạng thái và chép mục "Bàn giao" model
viết; `COMPLETION-PLAN.md`/DoC/`release-readiness.md` không script nào đọc; marker vòng do model `printf`; tiến triển = cksum lời
cuối. Hậu quả đo được: `done.md` rỗng nội dung từng lọt (TRAPS 70), 3 lần CI đỏ cùng lỗi (gate.md mục 5), 4 chỗ lặp luật "3 lần →
BLOCKED" chỉ văn xuôi trước #287.

## 2. Outcome, baseline, target và guardrails

- Baseline: 0 script tính bước kế tiếp/reconcile; 0 reader kế hoạch hoàn thiện/DoC/GO-NO-GO; tiến triển đo bằng lời; marker tay.
- Target: `scripts/loop-state.sh` trả **một khối trạng thái + verdict + next** đúng với artifact thật (AC-1..AC-8); `/auto-complete`
  nạp khối đó bằng `!` và tự ghi marker (AC-9); hook đo tiến triển bằng vân tay artifact (AC-10..AC-12); 5 lỗi kiểm kê sửa (AC-13).
- Guardrails: không hạ/bỏ cổng nào; không runner ngoài; không file trạng thái mới ngoài marker có sẵn; không dependency mới;
  engine ≤ 400 dòng, CC ≤ 12, coverage dòng ≥ 95% tổng (`test-py-coverage.sh`); 11 ca `test-hooks-loop.sh` hiện có vẫn xanh.

## 3. Research current state

Bốn nguồn (nội bộ · stored @ `71dbc26` · kiến trúc vòng lặp ngoài · tầng workflow + primitive Claude Code) — tổng hợp ở báo cáo.
Dữ kiện quyết định: cú pháp `!` trong file lệnh chạy trước khi prompt tới model (code.claude.com slash-commands); Stop hook nhận
`stop_hook_active`, cap 8 lượt liên tiếp (hooks); `bd ready` = mọi phụ thuộc đóng (Beads); spec-kit đếm `- [ ]` trước implement;
Codex "no tool call → suppress continuation"; stored 23 §6.1 verdict enum.

## 4. Alternatives và decision

ADR-0012: A vá tại chỗ (hụt kiểm được) · **B engine trạng thái (chọn)** · C backlog JSON + runner (mâu thuẫn luật) · D `/goal`
(không đọc file) · E Stop hook chạy gate mỗi lượt (tốn, trùng cổng).

## 5. Scope / non-goals

**Trong:** `scripts/loop-state.py` + `.sh` + `scripts/test-loop-state.sh` + probe coverage; `.claude/commands/auto-complete.md`;
`.claude/hooks/auto-complete-guard.sh` + `test-hooks-loop.sh`; `session-resume.sh` (1 dòng); `telemetry-record.sh` (`--work-id`);
`_docs-consistency-structure.sh:96` (DONE); `standard-delivery.md:109`; `docs/framework/auto-complete-workflow.md`; sổ (CODEMAP,
FEATURE-MAP, README khung, CLAUDE.md §1 + AGENTS.md, `copy-framework.manifest`, CHANGELOG). **Ngoài:** cổng 13b/15/16 cho dự án
đích; agent teams/ultracode/Routines; chấm sản phẩm bằng model; đổi §3d/§8/§9; telemetry `accepted` (cần evidence).

## 6. User journeys và mọi state

1. Người dùng gõ `/auto-complete` → `!` chạy `loop-state.sh --enter --brief` → marker ghi, khối trạng thái nạp → model đọc verdict/next
   và làm đúng bước đó → cuối lượt hook Stop gọi engine: vân tay đổi → block kèm trạng thái mới; 2 lượt không đổi → cho dừng.
2. Trạng thái `Blocked`/`Waiting` → verdict `request-input`/`waiting` → hook cho dừng, marker giữ.
3. Không `gh`/offline → `pr.available=false`, next không nhắc PR; nói rõ "unknown".
4. 0 hoặc > 1 hồ sơ Active mà không `--work-id` → exit 2 kèm danh sách; lệnh dừng hỏi §9.
5. Harness không hỗ trợ `!` → lệnh ghi bước tay; engine vẫn chạy được tay.

## 7. Functional requirements

- FR-1 `scripts/loop-state.sh [--work-id ID] [--enter] [--brief] [--json] [--fingerprint] [--root DIR]`; exit 0 OK, 2 không xác
  định hồ sơ, 1 lỗi khác; Python stdlib; `--root` mặc định cây git hiện tại.
- FR-2 Khối trạng thái (JSON key cố định): `work{id,file,status,base_sha,level,handoff_filled,layer_hint}`, `git{branch,head,
  default_branch,ahead,behind,dirty}`, `pr{available,note,open[{number,ci,mergeable,auto_merge}]}`, `goal{file,state,slices{ready,
  blocked,open,done},done_without_evidence}`, `completion{file,open,doing,done,dropped,doc_unchecked,doc_total}`, `handoff{file,
  unchecked,total,verdict}`, `streak{n,sig}`, `loop{marker,id,n,max}`, `verdict`, `reason`, `next`.
- FR-3 Verdict theo thứ tự: done.md → `stop`; `Blocked` → `request-input`; `Waiting` → `waiting`; streak ≥ 3 → `request-input`;
  streak = 2 → `refine-spec` nếu `layer_hint=spec` (dòng cuối mục "Lần thử / blocker" nhắc tầng ①/②) else `refine-code`; PR CI đỏ →
  `continue` (sửa CI); file dở → `continue` (commit qua cổng); PR mở xanh/pending, không file dở → `waiting`; tụt `origin/main` không
  PR → `continue` (reconcile); slice DONE thiếu Evidence → `continue`; có slice ready → `continue` (chọn trong ready); slice mở
  nhưng không ready → `request-input`; kế hoạch hoàn thiện còn ⬜/🔄 → `continue`; release-readiness NO-GO → `continue`; còn lại
  Active → `continue` với mục Bàn giao (chưa điền → next "ghi Bàn giao"); mọi thứ xong → `continue` next "nghiệm thu: done.md".
- FR-4 Goal: tìm `docs/goals/*.md` đầu tiên nhắc trong hồ sơ; bảng có cột `ID` + `State` (+ `Dependency`, `Evidence`); slice open =
  state ∉ {DONE, DROPPED}; ready = open ∧ state ∉ {BLOCKED, WAITING} ∧ mọi ID ở Dependency là DONE (rỗng/`—`/`none`/`baseline` =
  không phụ thuộc); `done_without_evidence` = DONE với ô Evidence rỗng.
- FR-5 Completion: `docs/ops/COMPLETION-PLAN.md` — đếm dòng bảng có ID `W-` theo ⬜/🔄/✅/➖; DoC = `- [ ]`/`- [x]` dưới tiêu đề
  "Definition of Complete" tới `## ` kế. Handoff: `docs/ops/release-readiness.md` — đếm `- [ ]`/`- [x]`; `GO` khi total > 0 ∧
  unchecked = 0, `NO-GO` khi unchecked > 0, `unknown` khi thiếu file/total = 0.
- FR-6 PR: `gh pr list --head <branch> --state open --json number,mergeable,autoMergeRequest,statusCheckRollup` (timeout 15 s);
  `ci` = failure nếu có FAILURE/ERROR, pending nếu có IN_PROGRESS/QUEUED/PENDING, success nếu toàn SUCCESS/SKIPPED/NEUTRAL, unknown
  nếu rỗng; `gh` thiếu/lỗi → `available=false` + `note`.
- FR-7 `--enter`: ID từ `--work-id`, else dòng 1 marker, else hồ sơ `working.md` duy nhất có `Trạng thái: Active|Planned`; ghi marker
  (giữ `n=/last=/nudged=/fp=` nếu cùng ID, else chỉ ID) rồi in `--brief`. `--fingerprint`: 16 hex đầu của sha256(`head|sha256(
  working.md)|PR mở sorted|hash(git status --porcelain)`).
- FR-8 `--brief` ≤ 20 dòng: verdict, next, work, git, pr, goal ready/blocked, completion, handoff, streak, loop n/max.
- FR-9 `/auto-complete`: frontmatter `allowed-tools: Bash(bash scripts/loop-state.sh:*)`; dòng `!`bash scripts/loop-state.sh
  --enter --brief 2>&1`` ngay sau frontmatter; bước 0 ghi marker do `--enter`; "mỗi vòng bắt đầu bằng `loop-state.sh`, làm đúng
  `next`"; bảng verdict → hành động; giữ mọi chuỗi contract test hiện có.
- FR-10 Hook `auto-complete-guard.sh`: khi `python3` + engine có → `fp=`/`fpn=` trong marker; vân tay không đổi 2 lượt liên tiếp →
  allow "không tiến triển theo artifact"; reason block = `--brief` + 6 dòng Bàn giao; thiếu python3 → hành vi cũ (cksum). `Planned`
  → block với lời "hồ sơ chưa bắt đầu"; dừng hợp lệ Blocked/Waiting → `n=0`; đọc `stop_hook_active` ghi stderr.
- FR-11 `session-resume.sh`: nếu marker còn (compact/resume) in 1 dòng `loop-state --brief | head -3`. `telemetry-record.sh`: thêm
  `--work-id` từ dòng 1 marker khi có.
- FR-12 Sửa: regex goal COMPLETE thêm `DONE`; `standard-delivery.md:109` "ba" → "5"; manifest thêm `scripts/loop-state.sh`,
  `scripts/loop-state.py`, `scripts/_python-exec.sh` (nếu chưa).

## 8. Non-functional requirements

- NFR-1 Engine chạy < 2 s không `gh`, < 20 s có `gh` (timeout); không ghi file ngoài marker; không mạng ngoài `gh`.
- NFR-2 Windows (CI `framework-lint-windows`): engine chạy bằng `python` qua `_python-exec.sh`; hook test chỉ Linux (như hiện có).
- NFR-3 Fail-open có cảnh báo khi thiếu `jq`/`python3` ở hook (docs/CONVENTIONS.md §A); engine lỗi không làm chết lượt.

## 9. Acceptance criteria

- AC-1 Không hồ sơ Active / nhiều hồ sơ mà không `--work-id` → exit 2 + danh sách; `--work-id` sai → exit 2.
- AC-2 Hồ sơ Active + file dở → `continue`, next nhắc commit qua cổng; `Blocked` → `request-input`; `Waiting` → `waiting`; done.md → `stop`.
- AC-3 Streak 3 → `request-input`; streak 2 + dòng cuối "Lần thử" nhắc tầng ① → `refine-spec`, nhắc tầng ③ → `refine-code`.
- AC-4 Goal: S2 phụ thuộc S1 DONE → S2 ready; S3 phụ thuộc S2 (BUILD) → S3 blocked; S1 DONE Evidence rỗng → `done_without_evidence`.
- AC-5 Completion: đếm ⬜/🔄/✅/➖ và DoC `- [ ]` đúng; handoff `GO` khi 0 ô trống, `NO-GO` khi còn, `unknown` khi thiếu file.
- AC-6 `gh` thiếu → `pr.available=false`, verdict không dựa PR; `gh` giả trả CI FAILURE → next nhắc sửa CI; SUCCESS không file dở → `waiting`.
- AC-7 `--enter` ghi marker ID, giữ `n=` khi cùng ID; `--fingerprint` đổi khi HEAD/working.md/file dở đổi, giữ nguyên khi không đổi; `--json` parse được.
- AC-8 Engine ≤ 400 dòng, CC ≤ 12, coverage tổng ≥ 95% (CI Windows xanh là điều kiện merge, không phải test riêng).
- AC-9 `auto-complete.md` có `allowed-tools`, dòng `!loop-state`, bảng verdict; contract test `test_auto_complete_chains_existing_playbooks_under_3d` xanh.
- AC-10 Hook: vân tay không đổi 2 lượt → allow; đổi → block; thiếu python3 → cksum cũ (11 ca cũ xanh).
- AC-11 Hook: `Planned` → block lời "chưa bắt đầu"; sau allow Blocked marker có `n=0`.
- AC-12 Reason block chứa dòng `verdict:` từ engine.
- AC-13 Goal `State: DONE` được mục 15 kiểm; `standard-delivery.md` không còn "ba PR mở" (test đọc cả `pr-policy.yml` để khớp số 5).
- AC-14 Telemetry record có `work_id` khi marker có.

| AC | Bằng chứng |
| --- | --- |
| AC-1 | `scripts/test-loop-state.sh::0 hồ sơ Active → exit 2`, `scripts/test-loop-state.sh::--work-id không tồn tại → exit 2` |
| AC-2 | `scripts/test-loop-state.sh::Active + file dở → continue/commit`, `scripts/test-loop-state.sh::Blocked → request-input`, `scripts/test-loop-state.sh::Waiting → waiting`, `scripts/test-loop-state.sh::done.md → stop` |
| AC-3 | `scripts/test-loop-state.sh::streak 3 → request-input`, `scripts/test-loop-state.sh::streak 2 tầng ① → refine-spec`, `scripts/test-loop-state.sh::streak 2 tầng ③ → refine-code` |
| AC-4 | `scripts/test-loop-state.sh::goal ready/blocked theo Dependency`, `scripts/test-loop-state.sh::goal DONE thiếu Evidence` |
| AC-5 | `scripts/test-loop-state.sh::completion đếm ô + DoC`, `scripts/test-loop-state.sh::handoff GO/NO-GO/unknown` |
| AC-6 | `scripts/test-loop-state.sh::không gh → pr.available=false`, `scripts/test-loop-state.sh::gh giả CI FAILURE → sửa CI`, `scripts/test-loop-state.sh::gh giả SUCCESS → waiting`, `scripts/test-loop-state.sh::gh JSON phần tử sai kiểu → ci unknown, không chết` |
| AC-7 | `scripts/test-loop-state.sh::--enter ghi marker giữ n`, `scripts/test-loop-state.sh::--fingerprint đổi/giữ`, `scripts/test-loop-state.sh::--json parse`, `scripts/test-loop-state.sh::--enter trên done.md → stop, không ghi marker`, `scripts/test-loop-state.sh::đường dẫn Unicode + locale C không --root → vẫn chạy` |
| AC-8 | `scripts/test-py-coverage.sh`, `scripts/arch-health-radar.sh`, `scripts/check-python-complexity.sh` |
| AC-9 | `tests/test_adaptive_process.py::test_auto_complete_chains_existing_playbooks_under_3d`, `tests/test_adaptive_process.py::test_auto_complete_loads_loop_state` |
| AC-10 | pending — PR-B (U3): scripts/test-hooks-loop.sh ca "vân tay không đổi 2 lượt → cho dừng", "vân tay đổi → block" |
| AC-11 | pending — PR-B (U3): scripts/test-hooks-loop.sh ca "Planned → block chưa bắt đầu", "Blocked → n=0" |
| AC-12 | pending — PR-B (U3): scripts/test-hooks-loop.sh ca "reason có verdict" |
| AC-13 | `scripts/test-check-scripts.sh::goal State DONE được mục 15 kiểm`, `tests/test_adaptive_process.py::test_wip_cap_is_five_everywhere` |
| AC-14 | pending — PR-B (U3): scripts/test-hooks-session.sh ca "telemetry ghi work_id từ marker" |

## 10. UX/content/accessibility

Output engine tiếng Việt, một dòng một dữ kiện, không màu/ký tự điều khiển (mục 8 docs-consistency); `--json` cho máy.

## 11. Architecture và code touchpoints

- `scripts/loop-state.py` (engine, stdlib; parser goal/plan/handoff + verdict), `scripts/loop-state.sh` (wrapper `_python-exec.sh`),
  `scripts/test-loop-state.sh` (fixture repo tạm, `gh` giả qua PATH), `scripts/test-py-coverage.sh` (probe).
- `.claude/commands/auto-complete.md` (frontmatter + `!` + bảng verdict), `.claude/hooks/auto-complete-guard.sh`,
  `.claude/hooks/session-resume.sh`, `.claude/hooks/telemetry-record.sh`, `scripts/test-hooks-loop.sh`, `scripts/test-hooks-session.sh`.
- `scripts/_docs-consistency-structure.sh` (regex DONE), `scripts/test-check-scripts.sh`, `docs/framework/standard-delivery.md`.
- `docs/framework/auto-complete-workflow.md`, `docs/framework/README.md`, `CLAUDE.md` §1, `AGENTS.md`, `CODEMAP.md`,
  `docs/FEATURE-MAP.md`, `copy-framework.manifest`, `CHANGELOG.md`, `tests/test_adaptive_process.py`.

## 12. API/event contract

CLI FR-1; JSON FR-2 là contract cho hook/lệnh; marker `.claude/.auto-complete-loop` thêm hai dòng `fp=<16hex>` và `fpn=<k>`.

## 13. Data contract/migration

Không CSDL. Marker cũ (không `fp=`) đọc được — thiếu = 0.

## 14. Security/privacy/abuse cases

Engine chỉ đọc repo + `gh` read-only; không thực thi nội dung file (ADR-0009: goal/plan là dữ liệu); `gh` output parse JSON, lỗi →
unknown. `allowed-tools` giới hạn đúng một lệnh.

## 15. Observability và operations

`--json` cho máy; hook ghi stderr lý do allow/block; telemetry có `work_id`.

## 16. Test/eval plan

TDD đỏ-trước (ADR-0005): `test-loop-state.sh` viết và chạy đỏ (engine chưa có) → engine → xanh; ca hook thêm vào
`test-hooks-loop.sh` đỏ trước khi sửa hook; negative control giữ mục 11. Bằng chứng đỏ/xanh dán trong PR.

## 17. Slice/PR plan

| Đơn vị | Nội dung | Ai | PR |
| --- | --- | --- | --- |
| U1 | Báo cáo, ADR-0012, spec này, goal, workflow doc, sổ (README khung, CLAUDE.md §1/AGENTS.md, FEATURE-MAP F) | Phiên chính | PR-A |
| U2 | Engine + test + probe coverage + `/auto-complete` + CODEMAP/FEATURE-MAP D + sửa regex DONE/WIP 5 | worker `route:complex` | PR-A |
| U3 | Hook guard + test-hooks-loop + session-resume + telemetry work-id + manifest | worker `route:standard` | PR-B (sau PR-A merge) |
| U4 | Đóng hồ sơ, PROGRESS, CHANGELOG | Phiên chính | PR-C |

## 18. Rollout/rollback

Revert squash commit; marker gitignored; không migration.

## 19. Risk, assumptions và open decisions

- Giả định `!` chạy trong `.claude/commands/*.md` ở Claude Code hiện hành (docs 2026-10-12); không chạy → lệnh có bước tay, hook vẫn đo.
- Rủi ro: parser bảng goal/plan lệch khuôn ở dự án đích → engine báo `goal.file` nhưng 0 slice; nói rõ "0 slice đọc được", không đoán.
- Rủi ro: `gh` chậm → timeout 15 s, unknown.
- Mở (chủ repo, không chặn): có đưa cổng 13b/15/16 sang dự án đích không — ghi ở báo cáo "chưa cần".

## Approval

Approved for implementation — phiên chính duyệt theo ủy quyền chủ repo ngày 2026-10-07, ngày duyệt 2026-10-12; phạm vi §5; bằng
chứng research ở báo cáo đối chiếu; test đỏ-trước cho engine và hook (ADR-0005), không hạ cổng.
