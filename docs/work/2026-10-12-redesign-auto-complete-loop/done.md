# Công việc: redesign-auto-complete-loop

- Work ID: 2026-10-12-redesign-auto-complete-loop
- Yêu cầu / outcome: chủ repo 2026-10-12 "thiết kế lại vòng lặp để tự động code hoàn thiện dự án, thiết kế cả workflow, tham khảo stored và các nguồn khác, bằng tất cả năng lực" → vòng lặp `/auto-complete` v2 có **trạng thái máy đọc được + bước kế tiếp do máy tính từ trạng thái thật**, và một tài liệu workflow tham chiếu đầu-cuối (idea → bàn giao).
- Trạng thái: Done 2026-10-12 (PR #295 squash merge `e524b49`, PR #296 squash merge `28c57a3`, đóng hồ sơ PR-C)
- Chủ trì / writer: phiên chính (Fable 5.1 cho quyết định kiến trúc mức L)
- Mức rủi ro / số PR: **L** (đổi lệnh tự động cốt lõi + hook Stop + engine mới + nhiều PR); số PR chốt sau research (dự kiến 3–4, tuần tự vì harness chỉ push một nhánh)
- Scope / non-goal: trong — kiến trúc vòng lặp (trạng thái, chọn bước, cổng chuyển pha, dừng/bàn giao), workflow tham chiếu, cổng máy mới có test đỏ-trước; ngoài — runner không giám sát (X1, quyết 2026-10-10), đổi luật §3d/§8/§9, vendor plugin ngoài
- Spec / goal / issue: dự kiến tạo sau research (chưa tồn tại) — spec đầy đủ mức L docs/specs/2026-10-12-auto-complete-loop-v2.md + goal docs/goals/2026-10-12-auto-complete-loop-v2.md + ADR-0012; báo cáo đối chiếu docs/reports/2026-10-12-thiet-ke-lai-vong-lap.md
- Nhánh / base SHA / thời điểm reconcile: `claude/sharp-goldberg-4owppu` @ `dd9de33` · 2026-10-12T16:44:23Z

## Kế hoạch và phân công

Bước 1 — Research (4 agent read-only song song, ≤ 5 toàn cây): (a) kiểm kê cơ chế vòng lặp ĐANG CHẠY vs văn xuôi (grep cổng,
`adopt-from-outside.md` §3); (b) kiến trúc vòng lặp ở nguồn ngoài (Anthropic harness, ralph plugin, /goal, Codex Goals, OpenHands,
Beads, superpowers, BMAD, spec-kit…) theo trục *cấu trúc* — khác hai đối chiếu hôm nay (so từng cơ chế); (c) tầng workflow +
primitive Claude Code; (d) `stored` @ `71dbc26` (10 commit mới so với a4c8376; mục 03/21 không đổi).
Bước 2 — Báo cáo ba cột + spec L (≥ 2 phương án, Approved §3d) + goal + ADR-0012 + tài liệu workflow.
Bước 3 — Thực thi theo số PR trong spec, mỗi PR qua `/gate`, test đỏ-trước cho engine/hook mới; Bước 4 — đóng hồ sơ.

## Quyết định và bằng chứng

- Research 4 agent read-only xong 2026-10-12 (nội bộ 55 tool-use · stored 25 · kiến trúc ngoài 53 · workflow 35); kết quả gộp ở
  `docs/reports/2026-10-12-thiet-ke-lai-vong-lap.md` (lấy 6 · sâu hơn 18 · chưa cần 11 · mâu thuẫn 3 · sửa lỗi kiểm kê 5).
- Chọn phương án **B engine trạng thái** · loại A (vá tại chỗ, hụt bậc 3 kiểm được), C (backlog JSON + runner: bậc 1 mâu thuẫn threat
  model 2026-10-10 + bậc 2 nguồn sự thật thứ hai), D (`/goal`: không đọc file), E (Stop hook chạy gate mỗi lượt: bậc 2) · bậc phân thắng
  bại: 2 (ít hơn) rồi 3 (kiểm được). ADR-0012.
- Gộp U1 (thiết kế) + U2 (engine) một PR · loại tách 2 PR · bậc 4 (harness push một nhánh, mỗi PR ~15 phút CI; không mất kiểm được vì
  spec Approved trước khi worker code).
- Spec Approved §3d 2026-10-12 TRƯỚC khi dispatch worker; PLAN.md qua `--check-plan` rc=0 (lần 1 đỏ: placeholder `<id>` → sửa).
- Giao T1→T2 cho `complex-implementer` (route:complex: parser + verdict có chỗ tự quyết trong ranh giới spec); T3 `standard`; T4 sau PR-A.
- Kiểm kê lộ 5 lỗi thật ngoài scope yêu cầu nhưng cùng vùng: Planned không trong danh sách dừng, regex goal thiếu DONE, `n` không reset,
  WIP "ba" ≠ 5, telemetry thiếu work-id → sửa trong cùng hai PR (ghi ở báo cáo §2.5).
- PR #294 merge → `fbb99dd`; nhánh rebase lên `origin/main` mới (chỉ còn commit mở hồ sơ), PROGRESS/goal ghi SHA.
- T3 xong (standard-worker): `auto-complete.md` nạp `!loop-state --enter --brief` + bảng 6 verdict; 2 test mới đỏ→xanh
  (`Ran 14 tests OK`); ca `goal State DONE được mục 15 kiểm` đỏ trước sửa regex (rc=1) → xanh; "ba PR mở" = 0.
- Regex DONE mới bắt goal thật `docs/goals/2026-09-24-completion.md` (State DONE, W-07 còn WAITING) → đóng W-07 có bằng chứng
  (người dùng xác nhận đóng 2026-10-06) thay vì thu hẹp regex — bậc 1 (đúng) thắng bậc 2.
- Worker engine lần 1 treo 20 phút không sự kiện (0 file tạo) → dừng, giao lại T1→T2 với brief ghi rõ lệnh đơn giản, viết sớm.
- Engine về (worker 2, 29 ca đỏ→xanh, coverage 96%, CC ≤ 12, 2 file < 400 dòng); nối `test-loop-state.sh` vào job
  `framework-lint` (CP-6); `git add` file mới để fixture `test-check-scripts.sh` (chép theo `git ls-files`) thấy; gate PASS.
- Dogfood trên chính repo: verdict `continue — 26 file dở`; lộ ra `gh pr list --json` (GraphQL) bị 403 trong phiên cloud →
  `pr.available=false` đúng spec (suy giảm có nói ra); ghi DEBT tại `_gh_list` kèm điều kiện xem lại (REST fallback).
- `--trace` spec: AC-1..9, 13 MAPPED; AC-10..12, 14 PENDING (PR-B).
- Review độc lập (`reviewer`, lần 1 chết vì giới hạn phiên, lần 2 xong): 2 lỗi tái hiện — F1 `subprocess text=True` theo locale
  (TRAPS 24: đường dẫn Unicode + locale C → chết khi không `--root`), F2 gh JSON phần tử sai kiểu → AttributeError; F4 `--enter`
  ghi marker cả khi `done.md`; F6/F7 dọn. Sửa cả 5 với 3 ca đỏ-trước (FAIL 3 → OK, 32 ca). **Không sửa** F3 (vân tay đổi khi gh
  chập chờn → hook thấy "tiến triển" thêm một lượt, hướng fail-open, đã nằm trong DEBT `_gh_list`) và F5 (`layer_hint` ưu tiên
  ①② trước ③④ trên cùng dòng — heuristic cho streak=2, giá trị thấp; xem lại khi ca thật định tuyến sai).
- Phát hiện khung: `Agent(isolation=worktree)` tạo worktree ở `.claude/worktrees/` (trong cây repo, base origin/main chứ không
  HEAD) → cổng lint `find . -name '*.sh'` quét vào đó và đỏ khi worktree bị dọn giữa chừng. Việc cho lượt hoàn thiện (#4): lint/
  docs-consistency loại trừ `.claude/worktrees/`; worktree cho worker tạo tay ngoài cây (scratchpad) từ HEAD.
- PR-A #295 merge → `e524b49` (20:29Z). Nhánh restart từ `origin/main`; patch T4 (worktree tay) áp sạch; session-resume đổi
  từ stderr sang `additionalContext` (model phải đọc được trạng thái máy tính) — ca test sửa theo.
- Cổng tổng đỏ chập chờn 2 lần ở docs-consistency mục 13b trên `done.md` không đổi (2026-10-08-…, 2026-10-10-…), cả hai lần
  đều khi subagent đang chạy suite test trong CÙNG checkout; chạy riêng 30 lần: 0 lần 13b (4 lần đỏ khác do file probe
  `scripts/zz-probe-*` của subagent). Kết luận: nhiễu do chia sẻ checkout khi tải cao (TRAPS 63), không phải lỗi code PR;
  luật phiên: không chạy `/gate` khi subagent đang chạy test trong checkout; xem lại khi tái hiện không có subagent.
- Review độc lập T4 (`reviewer`): F1 vân tay mù nội dung file đã dirty (`git status` chỉ thấy đường dẫn) → engine thêm hash
  `git diff HEAD` + size/mtime file untracked, bỏ `.claude/.*`; F2 Planned đứng trước wind-down/trần và không đếm n → dời xuống
  sau trần, `save n+1`; F4 Blocked giữ fpn → đặt fpn=0. 3 ca đỏ-trước (FAIL 3 → OK; hook 20 ca, engine 33 ca). Không sửa: F3 echo
  `stop_hook_active` (FR-10 yêu cầu), F5 hai lần gọi engine mỗi Stop (fail-open, timeout mặc định hook; xem lại khi đo > 5 s/lượt),
  F6 `|| true` vô hại. `loop-state.py` chạm đúng 400 dòng (trần radar) — tách tiếp khi thêm tính năng.

## Lần thử / blocker

- Cổng commit đỏ 2 lần cùng chữ ký khi mở hồ sơ: hook PreToolUse chạy gate TRƯỚC phần sửa trong cùng lệnh Bash (tầng ④ harness,
  không phải nội dung) → tách sửa/commit thành hai lệnh → xanh (`d7c9a85`).

## Bàn giao / bước tiếp theo

Xong. Việc kế tiếp (chủ repo giao 2026-10-12 "xong rồi hoàn thiện khung này luôn, tham khảo cả repo stored"): lượt `/auto-complete`
Giai đoạn B (Pha 0–4 `project-completion.md`) trên chính repo khung, hồ sơ mới. Đầu vào đã ghi cho lượt đó: stored 23 §8
`scripts/model-rates.json` lệch; DoC `docs/ops/COMPLETION-PLAN.md` dạng bold không phải checklist → engine đếm `0/0`; cổng lint
`find . -name '*.sh'` quét vào `.claude/worktrees/` (worktree của harness); cổng tổng chập chờn khi subagent chạy test cùng checkout
(TRAPS 63); `loop-state.py` chạm trần 400 dòng — tách tiếp khi thêm tính năng; DEBT `_gh_list` (GraphQL 403 cloud → REST fallback).

## Nghiệm thu cuối (chỉ điền khi đủ bằng chứng)

- DoD (Goal DoD GOAL-2026-012): `scripts/loop-state.sh` tính verdict có kiểu + `next` từ artifact (AC-1..9, 13); `/auto-complete`
  nạp bằng `!` (AC-9); hook Stop đo vân tay artifact, 2 lượt không đổi → cho dừng, Planned/Blocked/Waiting/done.md đúng (AC-10..12);
  telemetry có `work_id` (AC-14); spec `--trace` TRACE COMPLETE 14/14; workflow tham chiếu `docs/framework/auto-complete-workflow.md`;
  ADR-0012 (5 phương án); guardrail: không hạ cổng, 11 ca hook cũ xanh, coverage 96–97 %, 0 file mã mới > 400 dòng (`loop-state.py`
  đúng 400).
- PR MERGED: #295 → `e524b49` (U1 + U2, 2026-10-12T20:29Z) và #296 → `28c57a3` (U3, 2026-10-12T21:14Z), đều auto-merge squash,
  CI run xanh ở head cuối (`framework-lint`, `framework-lint-windows`, `docs-consistency`, `copy-framework-smoke`,
  `progress-freshness`, `protection-guard`, CodeQL, gitleaks); `gate` đỏ một lần ở mỗi PR trên head CŨ do `framework-lint-windows`
  bị huỷ khi push mới — không phải lỗi mã. `origin/main` đã đối chiếu `28c57a3` trước khi đóng.
- Test: `test-loop-state.sh` 33 ✅, `test-hooks-loop.sh` 20 ✅, `test-hooks-session.sh` +1, `tests/test_adaptive_process.py` 14 OK;
  review độc lập 2 lượt (PR-A 7 phát hiện → 5 sửa đỏ-trước; PR-B 6 → 3 sửa đỏ-trước), lý do không sửa ghi ở "Quyết định".
- Giới hạn/rủi ro còn lại: `gh pr list --json` (GraphQL) 403 trong phiên Claude Code cloud → `pr.available=false`, verdict
  `waiting` không tự động trong cloud (DEBT `_gh_list`, REST fallback khi cần); mỗi Stop gọi engine 2 lần (F5, xem lại khi > 5 s/lượt);
  F3 vân tay đổi khi `gh` chập chờn (fail-open); `loop-state.py` ở trần 400 dòng; `COMPLETION-PLAN.md` của repo khung DoC chưa
  phải checklist → engine đếm `0/0` (việc của lượt hoàn thiện kế).
- Nghiệm thu: phiên chính theo ủy quyền §3d, 2026-10-12.
