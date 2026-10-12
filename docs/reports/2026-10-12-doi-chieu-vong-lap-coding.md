# Đối chiếu vòng lặp coding tự động (agentic loops) → `/auto-complete` của khung — 2026-10-12

Yêu cầu chủ repo: *"nghiên cứu sâu vòng lặp trong coding phát triển phần mềm để nâng cấp cho dự án tiến đến việc tự động
hoàn thành khi có mục tiêu, yêu cầu và người dùng bật `/auto-complete`"*. Hồ sơ: `docs/work/2026-10-12-loop-research-auto-complete/`.
Phương pháp: `docs/framework/adopt-from-outside.md` — ba cột, **cổng §2 bản 2026-10-12** ("tốt hơn bản hiện có, chứng minh được,
tính ròng"; sự cố thật là bằng chứng mạnh nhất nhưng không bắt buộc), **grep cổng đang chạy** (§3), kiểm mâu thuẫn luật (§4).
Đích: `projects-template` @ `aab9f88` (`origin/main` sau #286).

**Kết quả: 41 cơ chế riêng biệt (gộp từ ~110 dòng của 4 báo cáo nguồn) → lấy 3.** Sâu hơn 23 · Nông hơn 6 (lấy 3, "chưa cần" 3)
· Chưa có 12 ("chưa cần" 11 + 1 mâu thuẫn luật đã quyết). Ba thứ lấy đều cùng một dạng "tốt hơn": **biến luật chỉ có văn xuôi
thành cổng máy** cho đúng ba điểm mà mọi nguồn — Anthropic, runner mã mở, sản phẩm thương mại, nghiên cứu — đều cưỡng chế
bằng máy còn khung chỉ cưỡng chế bằng lời: *không kết lượt khi việc còn dở*, *trần lặp cùng một failure*, *"xong" phải có bằng
chứng trong file trạng thái*.

## Nguồn (đọc 2026-10-12, bởi 4 agent read-only; không chạy mã ngoài)

| Nhóm | Nguồn chính |
| --- | --- |
| Anthropic | [Effective harnesses for long-running agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents) (11/2025); [Harness design for long-running apps](https://www.anthropic.com/engineering/harness-design-long-running-apps) (3/2026); [Building a C compiler with parallel Claudes](https://www.anthropic.com/engineering/building-c-compiler) (2/2026); [Claude Code auto mode](https://www.anthropic.com/engineering/claude-code-auto-mode) (3/2026); docs Claude Code: [hooks](https://code.claude.com/docs/en/hooks), [/goal](https://code.claude.com/docs/en/goal), [scheduled tasks](https://code.claude.com/docs/en/scheduled-tasks), [Agent SDK loop](https://code.claude.com/docs/en/agent-sdk/agent-loop); plugin chính thức [ralph-wiggum](https://github.com/anthropics/claude-code/tree/main/plugins/ralph-wiggum) |
| Mã mở | OpenHands StuckDetector ([docs](https://docs.openhands.dev/sdk/guides/agent-stuck-detector)); SWE-agent (`per_instance_cost_limit`, `max_requeries`, RetryAgent); Aider (`max_reflections=3`, auto-lint/test); Ralph (Huntley; snarktank; ralph-tui); Gas Town/Beads (Yegge); [autoresearch](https://github.com/karpathy/autoresearch) (Karpathy); obra/superpowers; Continuous Claude; BMAD; spec-kit; OpenSpec |
| Thương mại | OpenAI Codex (Goals: [cookbook](https://developers.openai.com/cookbook/examples/codex/using_goals_in_codex)); GitHub Copilot cloud agent + CLI `/pr auto`; Google Jules; Devin (ACU, Session Insights); Cursor cloud agents (trần 10 lần sửa CI); Amp; Factory; Replit; Lovable |
| Nghiên cứu | Reflexion 2303.11366; Self-Refine 2303.17651; Self-Debugging 2304.05128; "LLMs cannot self-correct" 2310.01798; "Is self-repair a silver bullet" 2306.09896; SWE-agent 2405.15793; Agentless 2407.01489; Coherence Collapse 2603.24631; SWE-Protégé 2602.22124; SWE-Dev 2506.07636; Terminal-Bench 2 2601.11868; METR time horizon 2503.14499 + [TH1.1](https://metr.org/blog/2026-1-29-time-horizon-1-1/); τ-bench 2406.12045; TDD for codegen 2402.13521; Agent-as-a-Judge 2410.10934; CliffCompaction 2609.26779 |

## Phép đo đã chạy (cổng đang chạy, không đọc văn xuôi)

```bash
grep -rn -i "stagnat|no.progress|cùng failure|lần thử|retry" scripts/*.sh scripts/*.py .claude/hooks/*.sh .github/workflows/*.yml   # → 0 bộ đếm (telemetry chỉ ĐẾM attempts để báo cáo, không chặn)
grep -rln "docs/goals|goals/" scripts .claude .github tests      # → maintenance-sweep (grep BLOCKED), copy-test, 1 contract test: KHÔNG script nào đọc State/Evidence của goal
grep -n '"Stop"' -A8 .claude/settings.json                         # → usage-guard (nhắc wind-down 1 lần, không chặn), telemetry-record: KHÔNG hook nào ngăn kết lượt khi việc dở
grep -n "stop_hook_active|decision" .claude/hooks/*.sh             # → 0
grep -n "Trạng thái" scripts/*.sh                                   # → 0: dòng trạng thái của working.md không được cổng nào đọc (chỉ mục 13 kiểm có đúng một file)
sed -n 66,76p docs/framework/standard-delivery.md                   # luật quy lỗi về tầng + "3 lần → BLOCKED" (văn xuôi)
grep -n "3 lần\|ba lần\|lần liên tiếp\|mất một vòng" TRAPS.md .claude/commands/gate.md   # sự cố lặp thật: gate.md mục 5 (CI đỏ 3 lần dù local xanh), TRAPS 48 (tái phát 3 lần, #263 đồng bộ main 5 lần), 59, 65, 66
```

## Ba cột

### Đã có và SÂU HƠN (23) — không lấy

| # | Cơ chế ngoài (nguồn) | Ở khung | Sâu hơn ở chỗ nào |
| --- | --- | --- | --- |
| S1 | Initializer + coding agent, mỗi phiên một feature, đọc progress + git log đầu phiên (Anthropic 11/2025) | `/auto` wind-down/resume, `session-resume.sh` liệt kê `working.md` trước PROGRESS, "một iteration = một outcome + một PR" (§4) | Có cổng `progress-freshness` PF-1..4 đo file tiến độ lệch git (sự cố 2026-09-12); nguồn chỉ có văn xuôi. Anthropic 3/2026 còn ghi: reset ngữ cảnh "trở thành gánh nặng" trên Opus 4.5+ — khung đã không cưỡng ép reset. |
| S2 | Feature list JSON chỉ được lật `passes` (Anthropic) / `prd.json` (ralph) | Goal file bảng slice có cột **Evidence**; `spec-compiler.sh --trace` nối AC → test | `passes` là lời khai; khung đòi bằng chứng gắn HEAD (`dev-task.sh gate --evidence`, LD-03). **Nhưng** cột State/Evidence chưa có cổng đọc → xem N3. |
| S3 | Verifier/evaluator tách khỏi generator, ngưỡng cứng từng tiêu chí (Anthropic 3/2026; Jules Critic; Augment Verifier; Agent-as-a-Judge 88–92% khớp người) | `reviewer`/`tester`/`security-reviewer` + `dev-task.sh review-check` (LD-04: finding không căn cứ bị loại) + cổng máy | Khung dùng **máy** (test/gate/CI) làm verifier chính, model chỉ hậu kiểm — đúng kết luận nghiên cứu: tự-phê-bình không tín hiệu ngoài làm giảm chất lượng (2310.01798, 2306.09896); Anthropic ghi evaluator "tự thuyết phục mình bỏ qua lỗi". |
| S4 | "Không tuyên bố xong khi chưa có bằng chứng mới" 5 bước (superpowers `verification-before-completion`; Codex Goals "budget hit ≠ done") | CLAUDE.md §4 năm bước **từng chữ giống nhau** (xác định lệnh → chạy đủ lượt này → đọc toàn bộ → khớp → mới nói) | Ngang về lời; khung còn `evidence-check` (bằng chứng cũ/khác HEAD bị từ chối). |
| S5 | TDD/test-first: tests trong prompt +9..+30 điểm (2402.13521); AgentCoder test-designer độc lập | ADR-0005 đỏ-trước bắt buộc, `_spec_contract_gen.py` sinh contract test từ AC, PR template đòi output đỏ/xanh | Khung có cổng (`pr-policy`, review brief); nghiên cứu còn cảnh báo overfit test yếu → khung giữ golden/characterization. |
| S6 | Luật quy lỗi/leo thang: superpowers 5 vòng, đổi model mạnh hơn ở vòng 4; OpenHands nudge một lần khi chạm ngưỡng | `standard-delivery.md` dòng 71: lần 1 sửa code, **trước lần 2 phải ghi lỗi ở tầng ①–④** và quay về tầng đó, lần 3 → BLOCKED | Khung bắt **đổi tầng** (spec/design) chứ không chỉ đổi model — bắt đúng nguyên nhân hơn. Thiếu bộ đếm máy → N1. |
| S7 | Append-only learnings (`progress.txt`, `SHARED_TASK_NOTES.md`) | `TRAPS.md` (khuôn → cách rà → cổng → tái phát), `CONTEXT.md`, `docs/work/<id>/working.md` | Có cấu trúc, có cổng (sweep, docs-consistency), đánh dấu tái phát. |
| S8 | Auto-lint/test sau mỗi edit, sửa khi exit ≠ 0 (Aider; SWE-agent lint +3 điểm) | `auto-format.sh` (PostToolUse), `pre-commit-gate.sh` chặn cứng commit đỏ | Khung chặn ở ranh giới commit (không thể lọt), Aider chỉ nhắc. |
| S9 | Auto-commit mỗi thay đổi + `/undo` (Aider); edit-commit checkpoint chống "thrash" (2603.24631: 5/5 patch vàng cứu được) | §8 commit nhỏ mỗi thay đổi logic; Claude Code checkpoint/`/rewind`; `precompact-checkpoint.sh` | Tương đương; thrash chưa đo thấy ở repo (0 sự cố). |
| S10 | Ngân sách USD/ACU/turn cứng (SWE-agent $3; OpenHands 250–500 lượt; Devin ACU; SDK `max_budget_usd`) | `usage-guard.sh` (ước % quota 5h), trần ngữ cảnh 500k §5.2.1, `telemetry-log` chi phí thật, `GOAL.template.md` Budget | Khung đo **chi phí thật** từ transcript (TRAPS 32/33 sửa số bịa); trần USD cứng không có nghĩa trong CLI subscription. Trần lượt → đi cùng N2. |
| S11 | Stop condition/exit status có kiểu (SWE-agent `exit_cost`…; Codex stop set; BLOCKED/WAITING) | §8 BLOCKED/WAITING + gate PASS/FAIL/BLOCKED + telemetry `attempt/accepted/rejected/abandoned` | Tương đương, có test (`test_telemetry_integrity`). |
| S12 | Bỏ qua sửa CI khi check đỏ cả ở base, khi người vừa push (Cursor) | `pr-flow.md` + luật harness "CI red on base → không phải của PR" | Tương đương; khung còn luật ported-fix. |
| S13 | Merge queue, bisect lô đỏ, không push thẳng main (Gas Town Refinery; Copilot không được merge) | §8 auto-merge chỉ khi cổng xanh, ruleset, `protection-guard`, WIP 5 FIFO | Cổng máy trên GitHub; Gas Town là tiến trình riêng phải vận hành. |
| S14 | Spec → converge → lặp tới "Converged" (spec-kit); OpenSpec archive | Feature gate Approved, `spec-compiler`, `/completion` Pha 4 hội tụ (0 Cao mở, re-audit) | Có tiêu chí thoát đo được + cổng `pr-policy`. |
| S15 | Ưu tiên slice theo giá trị/rủi ro; phụ thuộc dạng đồ thị, chỉ nhận việc không bị chặn (Beads `bd ready`) | PLAN.md `Phụ thuộc` + `_plan_check.py::_check_dependency_cycle`; §4 "slice Ready có value/risk-reduction cao nhất" | Có cổng chu trình phụ thuộc; Beads cần Dolt + CLI riêng. |
| S16 | Brief kín cho worker, hai verdict (spec + chất lượng) (superpowers; BMAD session dev/review tách) | `subagent-dispatch.sh --check-plan` (TRAPS 59), `reviewer` đọc diff trong phiên riêng | Cổng máy trên brief. |
| S17 | Worktree mỗi worker, khoá claim bằng git (C compiler) | `coordinator.md`, TRAPS 63 (mỗi phiên một worktree), trần 5 subagent (ADR-0011) | Tương đương cho quy mô hiện tại. |
| S18 | Ngữ cảnh: compaction + note-taking + subagent trả tóm tắt (Anthropic context engineering; CliffCompaction) | §5.2 (token rẻ nhất là token không nạp), `session-resume` trần 8 KB, `precompact-checkpoint`, 500k/90% | Có số đo (C5: 58 KB → 8 KB). |
| S19 | Nội dung ngoài là dữ liệu; auto mode leo thang sau 3 từ chối liên tiếp/20 tổng (Anthropic auto mode) | ADR-0009, threat model `maintain-cron`, hook `block-dangerous-git` + deny list | Khung chặn ở lớp settings + hook, không chỉ classifier. |
| S20 | Time blindness: test mẫu 1–10% để không "chạy test hàng giờ" (C compiler) | §5 test liên quan trước commit, toàn bộ trước merge; CI parity (một suite chạy đúng một lần, TRAPS 46) | Tương đương. |
| S21 | Thoát sớm khi không có gì làm (loop-engineering N3 cũ; Codex "no tool call → suppress") | Đã đối chiếu 2026-10-11 (N3 "chưa cần", đo 2/3 đợt 0/0 vẫn có phát hiện tay) | Giữ kết luận cũ; phần "không tool call → cho dừng" lấy vào N2 (monologue guard). |
| S22 | Session/goal cloud (Codex Goals, Cursor `/goal`, Devin child sessions) | Ngoài harness khung; `/auto-complete` chạy trong phiên có người | Không áp dụng. |
| S23 | pass^k / reliability metric (τ-bench) | Telemetry `accepted` chỉ khi gate PASS có evidence; CI required checks | Khung đo "mọi lần đều đạt cổng" ở từng PR; chưa cần chỉ số tổng hợp. |

### Đã có nhưng NÔNG HƠN (6) — lấy 3, "chưa cần" 3

| # | Cơ chế ngoài | Điểm nông CỤ THỂ ở khung (đo) | Tốt hơn ở dạng nào (§2) | Quyết định |
| --- | --- | --- | --- | --- |
| **N1** | Trần lặp cùng failure có **bộ đếm máy** + nhắc một lần khi chạm ngưỡng (OpenHands 3; Aider 3; SWE-agent 3; Cursor 10; Continuous Claude stall 3; superpowers 5; SWE-Protégé: can thiệp khi chuỗi lặp ≥ L giảm trajectory lặp >10 bước từ 31% → 0,8%) | Luật "3 lần cùng failure → BLOCKED" + "trước lần 2 ghi lỗi ở tầng" ở 4 chỗ (§4, §8, dòng 71, `/auto-complete`) nhưng `grep` scripts/.claude/.github → **0 bộ đếm**; `pre-commit-gate.sh` chạy cổng rồi quên kết quả | **Kiểm được hơn**: cổng commit đã thấy từng lần đỏ — đếm chuỗi đỏ liên tiếp **cùng chữ ký** (dòng FAIL/BLOCKED đầu tiên) tốn ~20 dòng, 0 dependency; lần 2 nhắc "ghi lỗi ở tầng", lần 3 nhắc §8. Sự cố thật ủng hộ: TRAPS 65 (3 commit liên tiếp đỏ), gate.md mục 5 (CI đỏ 3 lần). Ròng: +1 file marker gitignored, +20 dòng hook, +1 mục test. | **LẤY** — mục B dưới. |
| **N2** | Vòng lặp **không kết lượt khi mục tiêu chưa đạt**: Stop hook `decision: block` (plugin ralph chính thức; `/goal` của Claude Code; Codex Goals "continue only when idle ∧ active ∧ within budget", "no tool call → suppress"), trần lượt là lưới an toàn (`--max-iterations`, `stop_hook_active`, cap 8 liên tiếp của Claude Code) | `/auto-complete` chỉ nói "chỉ dừng ở §9/BLOCKED"; `grep '"Stop"' settings.json` → chỉ usage-guard/telemetry; **không gì ngăn lượt kết thúc sớm**, người dùng phải gõ "tiếp tục". Dòng `- Trạng thái:` của working.md (§3e bắt buộc) không cổng nào đọc | **Kiểm được hơn** (luật văn xuôi → hook) và **ít hơn** so với phương án khác: không runner ngoài, không `--dangerously-skip-permissions` (quyết 2026-10-10 giữ nguyên), không chuỗi `<promise>` (CLAUDE.md §4) — tín hiệu dừng đọc từ **file trạng thái §3e** (Blocked/Waiting hoặc đã rename done.md), trần lượt, wind-down của usage-guard, chuỗi đỏ N1, và "không tiến triển" (lời cuối lặp y hệt). Ròng: +1 hook ~70 dòng, +1 suite test, +2 dòng settings, +3 dòng lệnh, +1 dòng session-resume (xoá marker khi phiên mới). | **LẤY** — mục A dưới. |
| **N3** | Trạng thái goal/feature **máy đọc được** và kiểm được: JSON `passes` (Anthropic), BMAD status frontmatter, Beads; failure mode #1 của loop dài là "declares victory" (Anthropic 11/2025; METR 16% run thành công là bất hợp lệ khi xem lại) | Đính chính (B) báo cáo ralph: **0 script đọc `docs/goals/`**; goal `lean-delivery` ghi COMPLETE, bảng slice có cột State/Evidence là văn bản tự do | **Bắt thêm lớp lỗi** (COMPLETE/DONE không bằng chứng) với chi phí một mục docs-consistency (~35 dòng, parser bảng Markdown đã có khuôn ở mục 10/11b). Ròng: +1 mục cổng, +3 ca test. | **LẤY** — mục C dưới. |
| N4 | Stagnation theo **hành động lặp** (OpenHands: 4 action+obs giống nhau, 3 lỗi giống nhau, ABAB 6; thresholds 3/0,85 ở DeepEval) | Khung không soi chuỗi tool call; `/goal` của Claude Code tự dừng khi nhiều lượt không tool | Cần PreToolUse ghi lịch sử lệnh + so khớp; OpenHands tự nhận dương tính giả khi poll hợp lệ; chưa đo được lợi ròng trên repo (0 sự cố lệnh lặp y hệt). | **Chưa cần** — xem lại khi một phiên ghi nhận ≥ 4 lệnh y hệt cùng kết quả trong `.ai-telemetry` hoặc N2 cho thấy monologue guard không đủ. |
| N5 | Trần thời gian tường (Copilot 59 phút; Lovable 10 h + 30 phút wrap-up; autoresearch 10 phút/run) | `usage-guard` theo quota; không trần thời gian | Trần thời gian không đo "xong"; khung dừng theo trạng thái/quota. Thêm đồng hồ = thêm cấu hình, không bắt thêm lỗi. | **Chưa cần** — xem lại khi có lượt `/auto-complete` chạy quá một ca làm việc mà không checkpoint. |
| N6 | Best-of-N + verifier (SWE-agent RetryAgent; R2E-Gym 34→51% Best@26; CodeMonkeys; Codex `--attempts 4`) | Một lần thử, sửa tới 3 lần | Tăng chất lượng đo được nhưng ×N chi phí; bậc 4 §3d chỉ khi ba bậc trên hoà — ở đây bậc 2 (ít hơn) thua. | **Chưa cần** — xem lại khi một việc `route:complex` thất bại 3 lần liên tiếp cùng spec kín (khi đó 2 lần thử song song rẻ hơn 3 lần tuần tự). |

### CHƯA CÓ (12) — "chưa cần" 11, mâu thuẫn 1

| # | Cơ chế | Quyết định (tốt hơn ròng? điều kiện xem lại) |
| --- | --- | --- |
| X1 | Vòng lặp ngoài không giám sát (`while true; claude --dangerously-skip-permissions`; C compiler 16 agent; Continuous Claude) | **Mâu thuẫn luật đã quyết 2026-10-10** (threat model, không runner sửa source không người duyệt). Nguồn mới không đổi dữ kiện: Anthropic 3/2026 và auto mode đều cần classifier/sandbox riêng. Giữ. N2 là bản **trong phiên có người** của cùng ý. |
| X2 | Lock-file claim việc qua xung đột git giữa 16 agent | Chưa cần: trần 5 subagent, Tầng 1 phân việc; chưa có hai agent tranh một việc. Xem lại khi > 5 worker song song. |
| X3 | Supervisor hierarchy heartbeat 5/20 phút (Gas Town Witness/Deacon) | Chưa cần: không có agent chạy nền dài ngày; `maintain-cron` có flock. Xem lại khi có loop chạy dày hơn hằng ngày. |
| X4 | Memory decay/tóm tắt task đã đóng (Beads), Proactive Memory Agent (+8,3 điểm Terminal-Bench) | Chưa cần: `docs/changelog/` + `done.md` + session-resume không nạp lịch sử (C5) đã là decay thủ công có cổng. Xem lại khi `session-resume` cắt ở trần 8 KB thường xuyên. |
| X5 | Evaluator riêng chấm 4 trục thẩm mỹ 5–15 vòng (Anthropic 3/2026 frontend) | Chưa cần: `/ui-ux` + axe/Lighthouse là cổng đo; chấm thẩm mỹ bằng model là hồ sơ C1 tùy dự án đích. Xem lại khi dự án đích C1 yêu cầu. |
| X6 | Sprint contract thương lượng giữa generator/evaluator | Chưa cần: AC trong spec Approved là contract; Anthropic V2 cũng bỏ. |
| X7 | Trajectory-prefix replay, MCTS/LATS, SWE-Search | Chưa cần: cần harness batch; ×chi phí. |
| X8 | Lệnh `init.sh` dựng môi trường mỗi phiên (Anthropic) | Chưa cần: `dev-task.sh doctor` + `project-commands.sh`; SessionStart không chạy cổng (tốn phút mỗi phiên). Xem lại khi một phiên mất > 10 phút chỉ để biết chạy thế nào. |
| X9 | Confidence-gated proceed (Devin 🟡/🔴 chờ duyệt; chờ 30 giây) | Chưa cần + ngược §3d (ủy quyền, không hỏi lại). |
| X10 | Credit check-in mỗi N credit (Lovable) | Chưa cần: `usage-guard` nhắc ở ngưỡng; CLI subscription không có credit đếm được. |
| X11 | Rubric do agent viết làm verifier không cần chạy (Agentic Rubrics +3,5 điểm) | Chưa cần: khung ưu tiên verifier chạy được; xem lại cho hồ sơ không có test chạy được (docs/content). |
| X12 | Hard timeout + "give up after a few attempts" ghi `crash` (autoresearch) | Chưa cần: N1 phủ "give up"; timeout cổng là việc của `dev-task.sh` (TRAPS 66 đã có cổng). |

## Mâu thuẫn luật (§4) — không tự hoà giải

| Nguồn | Luật khung | Xử lý |
| --- | --- | --- |
| `<promise>COMPLETE</promise>` làm tín hiệu dừng (ralph, plugin chính thức, ralph-tui, Continuous Claude 3 lần liên tiếp) | CLAUDE.md §4 "không tin lời khai" | N2 **không** đọc chuỗi model in; đọc dòng `- Trạng thái:` của `working.md` (artifact §3e bắt buộc, người dùng audit được, đi cùng PR) + marker do lệnh tạo. Vẫn là tự khai ở mức file, nhưng bền và có dấu vết — ghi rõ giới hạn này ở hook. |
| Reset ngữ cảnh mỗi feature bắt buộc (Anthropic 11/2025) | §5.2 "mở phiên mới sau mỗi mảng" là khuyến nghị, không cưỡng ép | Anthropic 3/2026 tự rút lại cho Opus 4.5+ → không lấy. |
| Hỏi/chờ duyệt mặc định (Devin, spec-kit "human review mỗi bước", Copilot không chạy workflow tới khi người duyệt) | §3d ủy quyền toàn cục | Không lấy (C2 báo cáo loop-engineering). |

## Đính chính giữa chừng (giữ nguyên dấu vết)

- **(A)** Định xếp "`/goal` của Claude Code" làm phương án **ít hơn** N2 (0 code). Đọc docs: evaluator Haiku "không chạy lệnh, không
  đọc file", chỉ phán từ transcript → đúng loại tín hiệu §4 cấm; không chạy ở harness khác. Giữ hook đọc file trạng thái; ghi `/goal`
  trong lệnh như tuỳ chọn khi người dùng muốn thêm một lớp.
- **(B)** Định lấy trần lượt mặc định 8 (bằng cap của Claude Code). Cap 8 của Claude Code đếm **liên tiếp không tool call**; trần của
  N2 đếm **tổng lượt tiếp tục** trong một lần bật — một lượt là cả một PR. Chọn 20 (`/goal` khuyên "stop after 20 turns"), đổi
  được bằng `AUTO_COMPLETE_MAX_CONTINUES`.
- **(C)** N1 lúc đầu định đếm "mọi lần cổng không xanh". Thử lại trên chính phiên này: ba lần BLOCKED liên tiếp vì thiếu
  `shellcheck`/`pwsh`/`coverage` là **ba failure khác nhau** — đếm gộp sẽ nhắc §8 oan ở lần thứ ba dù mỗi lần đã sửa đúng. Chốt:
  chuỗi chỉ tăng khi **chữ ký** (dòng FAIL/BLOCKED đầu) giống lần trước; khác → về 1.
- **(D)** Định ghi N3 vào `check-progress-freshness.sh`. Goal không phụ thuộc git → thuộc `check-docs-consistency.sh` (helper
  `_docs-consistency-structure.sh`, cùng chỗ mục 13 hồ sơ công việc).

## Danh sách thực sự lấy (3) — mỗi mục một commit, cùng một PR (harness phiên này chỉ cho push một nhánh)

- **A — `auto-complete-guard.sh` (Stop hook)**: marker `.claude/.auto-complete-loop` (do `/auto-complete` ghi Work ID, gitignored) →
  mỗi lần lượt kết thúc: hồ sơ còn `Active` và chưa chạm trần/wind-down/chuỗi đỏ/không tiến triển → `decision: block` kèm mục
  "Bàn giao / bước tiếp theo"; `Blocked`/`Waiting`/đã `done.md` → cho dừng. `session-resume.sh` xoá marker ở phiên mới (giữ khi
  `compact`/`resume`). Test: `scripts/test-hooks-loop.sh`. FT mới trong FEATURE-MAP.
- **B — chuỗi đỏ cùng chữ ký trong `pre-commit-gate.sh`**: file `.claude/.gate-red-streak` (`n=<k>`, `sig=<dòng FAIL/BLOCKED đầu>`);
  lần 2 nhắc "ghi lỗi ở tầng ①–④" (dòng 71), lần ≥ 3 nhắc §8 BLOCKED; cổng xanh → xoá. Hook A đọc file này. Test: mục 20
  `test-hooks-gate-guard.sh`.
- **C — mục 15 docs-consistency**: `docs/goals/*.md` — slice `DONE` phải có ô Evidence/Nghiệm thu; file `State | COMPLETE` không
  được còn slice ở trạng thái mở. Test: `test-check-scripts.sh`.

Cả ba là cổng máy mới có nhánh logic → TDD đỏ-trước (ADR-0005), không ngoại lệ.

## Phụ lục — `ConardLi/garden-skills` (chủ repo hỏi thêm 2026-10-12: "repo này giúp ích gì cho dự án không")

Kiểm kê (agent read-only, HEAD `7a6d5a7` 2026-10-11, MIT, ~12,8k sao): **6 skill lĩnh vực** — `web-design-engineer`, `beautiful-article`,
`web-video-presentation`, `motion-showreel`, `gpt-image-2`, `kb-retriever` — cho Claude Code/Cursor/Codex/Gemini/OpenCode; **0 command,
0 agent, 0 hook**, 0 skill về quy trình phát triển (không planning/spec/TDD/review/PR/loop). Vì vậy không có hạng mục nào đối chiếu
được với vòng lặp; chỉ 4 **mẫu quy trình nằm trong skill lĩnh vực** đáng xếp cột:

| Mẫu trong garden-skills | Ở khung | Cột |
| --- | --- | --- |
| Reviewer độc lập **không được xem code/log của người làm** để khỏi bị dẫn dắt (motion-showreel `review.md`) | `reviewer` nhận diff trong phiên riêng, không nhận lý luận của worker; `review-check` loại finding không căn cứ | Sâu hơn (có cổng máy cho finding) |
| "Mục chưa kiểm = chưa đạt" trong output QA (`inspect.mjs qa`: NOT CHECKED ≠ PASS) | `dev-task.sh gate`: thiếu kiểm tra là **BLOCKED**, không phải PASS (`strict-gate-contract.md`) | Sâu hơn |
| Trần lặp: kb-retriever 5 vòng; motion-showreel "cùng một lỗi sống qua 3 vòng/2 lần sửa → đổi cách, không mài tiếp" | §8 3 lần → BLOCKED + luật quy lỗi về tầng; nay có bộ đếm máy (mục B) | Sâu hơn |
| `field-notes.md`: ghi thực hành có bằng chứng, **thăng cấp** vào craft/tooling khi xác nhận ≥ 3 lần (hiện **0 mục**) | `TRAPS.md` cột "cổng chốt chặn" + đánh dấu tái phát; `DEBT: … xem lại khi:` có sweep 🟡 | Sâu hơn (đã có 69 mục, có cổng) |

**Kết luận: không lấy gì vào khung.** Giá trị của garden-skills với *dự án đích* là **nội dung lĩnh vực** (thiết kế web, bài viết HTML,
video thuyết trình, ảnh AI, Q&A trên knowledge base): dự án đích thuộc hồ sơ C1 (web) có thể cài riêng `web-design-engineer` bằng
`npx skills add ConardLi/garden-skills` khi cần — khung **không vendor plugin bên thứ ba** (ranh giới đã ghi ở đối chiếu X-Agents v2),
và `/ui-ux` + design tokens + WCAG AA của khung vẫn là luật áp lên output của skill đó. Hai lưu ý nếu dự án đích cài: (1) các
skill có **checkpoint hỏi người dùng từng mục, cấm tự chọn** — ngược §3d, phải nói rõ với người dùng rằng luật khung thắng; (2)
`gpt-image-2` đọc `OPENAI_API_KEY` từ `.env`/`~/.gateway.env` và gọi API trả phí — thuộc "không bao giờ tự quyết" (chi phí mới).

## Quyết định cần chủ repo

Không có quyết định mới. X1 (runner không giám sát) giữ nguyên kết luận 2026-10-10; điều kiện xem lại không đổi.
