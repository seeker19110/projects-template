# Thiết kế lại vòng lặp `/auto-complete` — đối chiếu KIẾN TRÚC vòng lặp (2026-10-12)

Yêu cầu chủ repo 2026-10-12: *"thiết kế lại vòng lặp để tự động code hoàn thiện dự án, thiết kế cả workflow, tham khảo stored và
các nguồn khác, bằng tất cả năng lực"*. Hồ sơ: `docs/work/2026-10-12-redesign-auto-complete-loop/done.md`.
Phương pháp: `docs/framework/adopt-from-outside.md` (ba cột · cổng §2 "tốt hơn bản hiện có, tính ròng" · §3 grep cổng đang chạy ·
§4 mâu thuẫn luật). Đích: `projects-template` @ `3954c65` (`origin/main` sau #293).

**Khác hai bản đối chiếu cùng ngày** (`2026-10-12-doi-chieu-stored.md` lấy 4, `2026-10-12-doi-chieu-vong-lap-coding.md` 41 cơ chế
lấy 3): hai bản đó so **từng cơ chế** (trần lặp, streak, evidence…). Bản này so **cấu trúc vòng lặp**: trạng thái nằm ở đâu và ai đọc,
ai tính bước kế tiếp, chuyển pha do ai quyết, dừng theo kiểu gì, bàn giao chứng minh thế nào. Cơ chế đã xếp cột ở hai bản trước
**không xếp lại** — chỉ trỏ.

## 0. Kết luận

Kiểm kê cổng đang chạy (4 agent read-only, 2026-10-12) cho thấy vòng lặp hiện tại là **"hook giữ lượt + văn xuôi"**: hook Stop
`auto-complete-guard.sh` chỉ đọc 1 dòng `- Trạng thái:` và chép ≤ 12 dòng mục "Bàn giao" (do model tự viết) làm "bước kế tiếp";
**không script nào** tính bước kế tiếp từ trạng thái thật (git/PR/CI/goal/kế hoạch), không script nào đọc
`COMPLETION-PLAN.md`/DoC/`release-readiness.md`, marker vòng do model `printf` (quên là hook vô hiệu), tiến triển đo bằng
cksum *lời cuối* chứ không bằng *artifact*. Mọi nguồn ngoài có vòng lặp chạy bền (Anthropic harness, Beads/agent-teams, spec-kit,
Codex Goals, ralph plugin) đều có **một bước máy tính trạng thái/độ sẵn sàng** trước khi model hành động.

**Lấy 6 hạng mục, gói thành MỘT kiến trúc** (ADR-0012, spec `docs/specs/2026-10-12-auto-complete-loop-v2.md`): engine
`scripts/loop-state.sh` tính **trạng thái vòng lặp máy đọc được + verdict có kiểu + bước kế tiếp** từ artifact thật; `/auto-complete`
nạp output đó bằng cú pháp `!` (chạy trước khi prompt tới model) và tự ghi marker; hook Stop dùng cùng engine để đo **tiến triển
theo artifact** và nhắc đúng tầng. Không runner ngoài, không backlog JSON thứ hai, không đổi §3d/§8/§9.

| # | Lấy | Nguồn | Dạng "tốt hơn" (§2) |
| --- | --- | --- | --- |
| L1 | Bước máy "reconcile" đầu mỗi vòng: git (HEAD/ahead-behind/dirty) + PR/CI (`gh`, suy giảm "unknown") + hồ sơ + goal + kế hoạch → một khối trạng thái | Anthropic 11/2025 (`pwd`+progress+`git log`+smoke đầu session), stored 21 §2.1, Codex Goals "so bằng chứng với mục tiêu ở ranh an toàn" | **kiểm được hơn** — §4 Goal Loop dòng 1–2 là văn xuôi, 0 script (kiểm kê mục 3) |
| L2 | Độ sẵn sàng slice **do máy tính** từ cột Dependency của goal (`bd ready`: sẵn sàng khi mọi phụ thuộc DONE) | Beads, Claude Code agent-teams ("cannot be claimed until dependencies completed") | **bắt thêm lớp lỗi** — chọn slice có phụ thuộc chưa xong; hiện model đọc bảng và tự chọn |
| L3 | **Verdict có kiểu** thay văn xuôi: `continue · refine-spec · refine-code · waiting · request-input · stop` + `stop_kind` | stored 23 §6.1 (design-os-3d-blender), X-Agents ADR-0052 `stop_kind`, Codex trạng thái active/paused/complete/budget | **kiểm được hơn** — luật quy lỗi về tầng ①–④ (§3b) hiện chỉ là lời nhắc ở streak lần 2 |
| L4 | Tiến triển đo bằng **artifact** (HEAD, hash `working.md`, tập PR mở) thay cksum lời cuối | Codex "no tool call → suppress", OpenHands StuckDetector (action/observation lặp), /goal stall detector | **bắt thêm lớp lỗi** — lời cuối khác nhau nhưng không commit/PR/ghi hồ sơ nào đổi = vòng quay không; cksum hiện bỏ lọt |
| L5 | Marker vòng + trạng thái nạp bằng **lệnh `!` trong file lệnh** (máy chạy trước khi model đọc prompt) | Claude Code slash-commands: "The !`<command>` syntax runs shell commands before the skill content is sent to Claude" | **ít hơn + kiểm được** — bỏ bước model `printf` marker (gap: quên → hook vô hiệu); 0 hook mới |
| L6 | Đếm máy cho checklist hoàn thiện/bàn giao: ô ⬜/🔄/✅ của `COMPLETION-PLAN.md`, `- [ ]` của DoC và `release-readiness.md` → GO/NO-GO máy | spec-kit `/speckit.implement` đếm `- [ ]` (PASS chỉ khi 0 ô trống), stored 09 §1.5/§1.9 GO/NO-GO làm điều kiện dừng | **kiểm được hơn** — Pha 0–4, DoC, GO/NO-GO hiện 0 reader (kiểm kê mục 8–9) |

Kèm 5 sửa lỗi thật phát hiện khi kiểm kê (không phải "lấy ngoài"): §2.5 dưới.

## 1. Phép đo đã chạy (cổng đang chạy, không đọc văn xuôi)

Kiểm kê đầy đủ (12 mảng, file:dòng) do agent read-only thực hiện; các dữ kiện quyết định thiết kế:

- `grep -rn next\|select\|reconcile scripts/ .claude/hooks/ .github/` → **0** script tính bước kế tiếp; `_plan_check.py` chỉ kiểm hình thức PLAN.
- `grep -rn 'COMPLETION-PLAN\|release-readiness' scripts/ .claude/hooks/` → chỉ danh sách miễn trừ/đường dẫn; **0 reader** nội dung.
- `auto-complete-guard.sh:43-62`: đọc `- Trạng thái:`; cho dừng khi `Blocked|Waiting|Done|Ready` (**`Planned` — giá trị `new-work.sh:36` ghi — không có trong danh sách**); tiến triển = `cksum` `last_assistant_message` (`:28,49`); `n` chỉ reset khi xoá marker (không reset sau lần dừng Blocked hợp lệ, `:45`).
- Marker: chỉ `auto-complete.md:24` bảo model `printf`; không hook/script nào tạo.
- `_docs-consistency-structure.sh:96`: regex COMPLETE của goal không khớp `State: DONE` (`docs/goals/2026-09-24-completion.md:9` dùng DONE → cổng mục 15 không áp lên file đó).
- `standard-delivery.md:109` + `docs/adr/0011…:19` ghi "ba PR mở" — `pr-policy.yml:34` cưỡng chế **5**.
- `telemetry-record.sh:100-103`: luôn `attempt`, không `--work-id`/`--outcome` → `accepted/rejected` chưa từng được ghi ngoài test.
- Dự án đích: `copy-framework.manifest` không chứa `check-docs-consistency.sh`/`check-progress-freshness.sh`/`test-hooks-loop.sh`; đích nhận `auto-complete-guard.sh` (tin `done.md`) nhưng không nhận cổng 13b/15/16 đứng sau nó.
- `usage-guard.sh` bất hoạt khi thiếu `.claude/usage-budget.sh` (repo chỉ có `.example.sh`) → điều kiện dừng "wind-down" của hook thực tế không bao giờ kích ở repo này.

## 2. Ba cột (kiến trúc)

### 2.1 Đã có và SÂU HƠN (không lấy)

| Hạng mục ngoài | Ở khung | Sâu hơn ở chỗ |
| --- | --- | --- |
| Backlog JSON `passes` chỉ-lật-cờ (Anthropic, ralph `prd.json`) | Goal file bảng slice State/Evidence + cổng mục 15 (DONE phải có Evidence) + `spec-compiler --trace` | Cờ `passes` là lời khai; khung đòi Evidence và gắn AC → test. Thiếu phần "máy chọn" → L2. |
| Vòng = session mới, bộ nhớ = file (Ralph, Anthropic v1, Gas Town polecat) | `session-resume.sh` + `working.md` §3e + `precompact-checkpoint.sh`; Anthropic 3/2026 tự bỏ reset cho Opus 4.5+ | Khung không cưỡng ép reset (đã quyết S1 báo cáo trước); giữ. |
| Promise string làm tín hiệu dừng (ralph plugin, ralph-tui) | Hook đọc **file trạng thái** §3e | Mâu thuẫn CLAUDE.md §4 — đã quyết ở báo cáo 41 cơ chế. |
| Generator ≠ evaluator, ngưỡng cứng (Anthropic 3/2026, superpowers 2 verdict) | reviewer/security-reviewer/tester + cổng máy; `/auto-complete` K4 bắt review tách người viết | Máy làm verifier chính, model hậu kiểm (S3). |
| Sprint contract thương lượng (Anthropic v1, Codex Goal template, Devin postconditions) | Spec AC Approved + PLAN "Tiêu chí chấp nhận" + `--check-plan` | Có cổng máy trên brief (TRAPS 59). |
| Vòng sửa có thang leo + breaker (superpowers 5 vòng, /goal 3 retry, X-Agents retry→replan→người) | Streak chữ ký + luật quy lỗi về tầng + BLOCKED lần 3 | Khung bắt **đổi tầng** (spec/design) thay vì chỉ đổi model. Verdict có kiểu bổ sung cách biểu diễn → L3. |
| Claim lock bằng git/file (C compiler, agent-teams, Beads `--claim`) | Trần 5 subagent, Tầng 1 phân việc, worktree mỗi worker (TRAPS 63) | Chưa có hai agent tranh một việc (X2 báo cáo trước). |
| Merge queue bisect (Gas Town Refinery) | GitHub auto-merge khi CI xanh + ruleset + WIP 5 | Cổng trên GitHub, không cần tiến trình riêng (S13). |
| Trạng thái vòng lặp lưu ở harness (Codex thread state, /goal restore) | Marker + `working.md` là file trong repo, audit được, đi cùng PR | Bền hơn phiên; người đọc được. |
| Stop hook `decision: block` + cap 8 + `stop_hook_active` | `auto-complete-guard.sh` (#287), trần 20 lượt riêng | Có suite 11 ca; cap 8 của CC là lưới thứ hai. |
| Checkpoint `awaiting_human` phải kết lượt (OpenMontage), `WAITING` (xboss) | `- Trạng thái: Waiting — …` → hook cho dừng | Tương đương. |
| Hive file thuần, single-committer, circuit breaker 3 nấc (Munder Difflin) | Tầng 1 commit/tích hợp; worker không commit (PLAN luật 4) | Tương đương cho ≤ 5 agent. |
| `assign_task(mission, context, acceptance_criteria, assignee)` (OpenCompany) | PLAN.md 4 trường bắt buộc + `route:` + `--check-plan` | Có cổng máy. |
| Policy chỉ-thêm, reviewer khác hãng (Omnigent Polly) | ADR-0006 đa nhà cung cấp; `permissions.ask` cho cấu hình cổng (K3) | Tuỳ chọn, không ràng buộc. |
| `runtime.yaml` + `run_smoke.sh` máy đọc (qlkh) | `scripts/dev-task.sh` dò stack + `.claude/project-commands.sh` + `doctor` | Lệnh chạy dò từ repo thật, có contract 4 kết quả (`strict-gate-contract.md`). |
| Gate G0–G8 mỗi gate một chủ, 3 lane, timeout leo thang (xboss-manager) | 9 cổng §3 + 5 tầng §3b + mức S/M/L §3c | Tương đương về cấu trúc; lane = mức S/M/L. |
| `SCOPE.md` hai điều kiện + `.out-of-scope/` (mattpocock) | `adopt-from-outside.md` ba cột + "chưa cần kèm điều kiện xem lại" | Sâu hơn: bắt chứng minh *tốt hơn bản hiện có*. |
| Harness bench đo năng lực harness (Omnigent) | `test-hooks-*.sh`, `test-engine-characterization.sh`, negative control mục 11 | Đã là khuôn. |

### 2.2 Đã có nhưng NÔNG HƠN (lấy đúng điểm nông)

| # | Hạng mục ngoài | Điểm nông CỤ THỂ ở khung (đo) | Lấy gì |
| --- | --- | --- | --- |
| **L1** | Đầu mỗi vòng: định vị bằng máy (Anthropic: `pwd` + progress + `git log` + smoke; Codex: so bằng chứng ở ranh an toàn; stored 21 §2.1) | §4 Goal Loop "reload main + GitHub/CI, reconcile" là văn xuôi; `session-resume.sh` chỉ liệt kê đường dẫn + `git log -5` ở **đầu phiên**, không ở đầu **mỗi vòng**; 0 script gọi `gh` | Engine `loop-state` tính khối trạng thái: git (branch, HEAD, ahead/behind `origin/main`, dirty), PR/CI của nhánh (`gh` có thì đọc, không thì `unknown`), hồ sơ (Work ID, Trạng thái, base SHA, Bàn giao có nội dung?), goal (slice theo state), kế hoạch hoàn thiện (đếm ô), streak/marker. **Không** chạy smoke/gate mỗi vòng (X8 giữ "chưa cần": cổng chạy ở commit). |
| **L2** | `bd ready` / agent-teams: sẵn sàng = mọi phụ thuộc đã xong, máy tính | Goal có cột Dependency; `check_goal_file` chỉ kiểm DONE có Evidence; chọn slice do model | Engine liệt kê `ready` (phụ thuộc toàn DONE/không có), `blocked_by`, `open`; `/auto-complete` chọn **trong tập ready** (giữ luật §4 "value/risk cao nhất" cho model quyết thứ tự). |
| **L3** | Verdict enum `continue·refine-spec·refine-code·request-input·stop` (stored 23 §6.1); `stop_kind` có kiểu (X-Agents); Codex trạng thái có kiểu | Hook block/allow + lời nhắc văn xuôi; luật tầng ①–④ chỉ hiện ở streak lần 2 | Engine xuất `verdict` + `reason` + `next`; ánh xạ: streak lần 2 → `refine-spec`/`refine-code` theo tầng model ghi; Blocked/Waiting → `request-input`/`waiting`; done.md + DoC 0 ô trống → `stop`. Hook dùng verdict để chọn thông điệp. |
| **L4** | Stall theo hành động/quan sát (OpenHands), "no tool call → suppress" (Codex), /goal | Hook so cksum `last_assistant_message` — lời khác là "có tiến triển" | Engine ghi dấu vân tay tiến triển `HEAD + hash(working.md) + tập PR mở` vào marker; hook: **≥ 2 lượt liên tiếp không đổi vân tay → cho dừng** (nudge trước ở lượt 1). Giữ cksum lời cuối như lưới phụ. |
| **L5** | Lệnh slash chạy `!cmd` trước khi prompt tới model | `/auto-complete` bảo model tự `printf` marker; kiểm kê: không hook nào tạo | File lệnh thêm `!`bash scripts/loop-state.sh --enter`` → ghi marker (Work ID từ hồ sơ Active duy nhất hoặc tham số) và in trạng thái; model bắt đầu lượt với sự thật máy đo. Harness không hỗ trợ `!` → lệnh vẫn có bước tay (ghi rõ). |
| **L6** | Đếm checklist bằng script trước implement (spec-kit); GO/NO-GO làm điều kiện dừng (stored 09) | `COMPLETION-PLAN.md`, DoC, `release-readiness.md` 0 reader | Engine đếm ⬜/🔄/✅/➖ theo đợt, `- [ ]` DoC, `- [ ]` release-readiness → `completion: {open, doing, done}`, `handoff: GO/NO-GO/unknown`. Chỉ đếm, không đánh giá nội dung (model/người vẫn điền). |

### 2.3 CHƯA CÓ — "chưa cần" kèm điều kiện xem lại

| Hạng mục | Vì sao chưa cần | Xem lại khi |
| --- | --- | --- |
| Backlog JSON riêng (`features.json`) | Thêm nguồn sự thật thứ hai cạnh goal file + spec AC → lệch sổ (adopt §0); L2 lấy phần "máy đọc" trên bảng goal có sẵn | goal file > 50 slice hoặc nhiều agent cùng lật cờ |
| Runner ngoài `while true; claude -p` / Routine mỗi giờ / gh-aw | **Mâu thuẫn luật đã quyết 2026-10-10** (threat model); nguồn mới (Routines "green ≠ task succeeded", gh-aw read-only + safe-outputs) không đổi dữ kiện | threat model riêng được duyệt |
| Agent teams (task list dùng chung, file lock) | Experimental; trần 5 subagent + Tầng 1 phân việc đủ; "teammates sometimes fail to mark completed" | > 5 worker song song thật |
| Dynamic workflow (`ultracode`, 16+ agent) | Chỉ khi người dùng gõ từ khoá; tốn token; không sign-off giữa chừng | người dùng yêu cầu bằng từ khoá |
| Evaluator model riêng chấm sản phẩm chạy (Playwright) | Hồ sơ C1 có E2E/axe; chấm thẩm mỹ bằng model tuỳ dự án đích (X5) | dự án đích C1 yêu cầu |
| Smoke/`init.sh` mỗi vòng | X8 giữ: cổng chạy ở commit; mỗi vòng tốn phút | một vòng mất > 10 phút chỉ để biết lệnh chạy |
| Thang `model_tier` + enum side-effect trong PLAN (Sales-Hunter) | Đã quyết "chưa cần" (stored §3) | worker có side effect mạng/publish |
| Merge queue bisect | GitHub auto-merge + WIP đủ | > 5 PR/giờ |
| Memory decay / `bd prime` | changelog + `done.md` + trần 8 KB session-resume | session-resume cắt thường xuyên |
| `/goal` làm lớp chính | Evaluator không chạy lệnh/đọc file (đính chính (A) báo cáo trước) | — (giữ tuỳ chọn) |
| Stop hook chạy build/test mỗi lượt (pattern 7 báo cáo workflow) | Cổng đã chạy ở commit; chạy mỗi lượt tốn phút, cap 8 | một PR merge với cổng commit bị `--no-verify` |

### 2.4 Mâu thuẫn luật (§4) — không tự hoà giải

| Nguồn | Luật khung | Xử lý |
| --- | --- | --- |
| "Sự thật tự tra, quyết định hỏi người" (mattpocock); Devin/Jules plan-approval; Kiro duyệt từng doc | §3d ủy quyền toàn cục | Không lấy. |
| Ralph/Continuous Claude tự merge khi test xanh | §8 merge qua PR + CI; "passed 28 tests, then failed review" (stored 03 §3) | Giữ luật khung. |
| Bắt buộc reset ngữ cảnh mỗi feature | §5.2 khuyến nghị | Anthropic 3/2026 tự rút lại; giữ. |

### 2.5 Sửa lỗi thật lộ ra khi kiểm kê (không phải "lấy ngoài", đi cùng PR)

1. `auto-complete-guard.sh`: `Planned` không nằm trong danh sách cho dừng → coi là "chưa bắt đầu, phải nối" (giữ hành vi block nhưng lời nhắc đúng); `n` reset khi dừng hợp lệ Blocked/Waiting.
2. `_docs-consistency-structure.sh:96`: regex goal COMPLETE thêm `DONE`.
3. `standard-delivery.md:109`: "ba PR mở" → 5 (khớp `pr-policy.yml`); ADR-0011 không sửa (luật ADR), ghi chú ở ADR-0012.
4. `telemetry-record.sh`: ghi `--work-id` từ marker khi có (outcome vẫn `attempt`; `accepted` cần evidence — ngoài scope).
5. Hook đọc `stop_hook_active` để log (không đổi quyết định — cap 8 của Claude Code là lưới thứ hai).

## 3. Lựa chọn kiến trúc (tóm tắt ADR-0012)

| Phương án | Mô tả | Bậc §3d phân thắng bại |
| --- | --- | --- |
| A. Giữ nguyên + vá 5 lỗi | Hook giữ lượt + văn xuôi; sửa §2.5 | Hụt bậc 3 (kiểm được): bước kế tiếp/reconcile vẫn là lời khai |
| **B. Engine trạng thái vòng lặp (chọn)** | `loop-state` tính trạng thái + verdict + ready slices + đếm checklist từ artifact có sẵn; `/auto-complete` nạp bằng `!`; hook dùng vân tay artifact | Đạt bậc 1; bậc 2 (ít hơn) hơn C: 0 dependency, 0 file trạng thái mới, 0 runner; bậc 3: cổng máy mới có test |
| C. Backlog JSON + runner ngoài (Anthropic/ralph) | `features.json` + `while true` | Loại ở bậc 1 (mâu thuẫn threat model 2026-10-10) và bậc 2 (nguồn sự thật thứ hai) |
| D. `/goal` làm lớp chính | Evaluator Haiku đọc transcript | Loại: không đọc file/chạy lệnh (CLAUDE.md §4) |

## 4. Đính chính giữa chừng (giữ nguyên)

- (A) Giả thuyết ban đầu "hook chỉ kiểm *còn Active* chứ không kiểm tiến triển" — **sai một nửa**: hook có kiểm tiến triển bằng cksum
  lời cuối (`:49`). Điểm nông đúng là *đo bằng lời* thay vì *bằng artifact* → L4 viết lại cho đúng.
- (B) Định đưa `check-docs-consistency.sh` (13b/15/16) + PF-1..4 sang dự án đích để lấp gap 11 của kiểm kê. Đọc script: mục 1–12
  đặc thù repo khung (CODEMAP/FEATURE-MAP/AGENTS). Tách 13b/15/16 thành script riêng cho đích là việc **ngoài scope** vòng lặp —
  ghi "chưa cần, xem lại khi dự án đích đầu tiên chạy `/auto-complete` tới `done.md`".
- (C) Định cho engine gọi `dev-task.sh gate` để biết "xanh/đỏ hiện tại". Mỗi vòng tốn phút, trùng cổng commit; dùng
  `.claude/.gate-red-streak` (đã có) làm tín hiệu thay vì chạy lại — giữ X8.
