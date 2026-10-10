# Công việc: Đối chiếu EveryInc/compound-engineering-plugin

- Work ID: 2026-10-09-doi-chieu-compound-engineering
- Yêu cầu / outcome: người dùng: "EveryInc/compound-engineering-plugin nghiên cứu tích hợp sâu thêm cả repo này nữa" → áp `docs/framework/adopt-from-outside.md` (ba cột, cổng sự cố thật, grep cổng đang chạy); đầu ra: bản đối chiếu `docs/reports/2026-10-09-doi-chieu-compound-engineering.md` + lấy đúng những hạng mục qua cổng, có test đỏ-trước.
- Trạng thái: Done (nghiệm thu 2026-10-10, PR #255 MERGED)
- Chủ trì / writer: phiên chính (Fable 5.1); 1 subagent general-purpose (Sonnet) catalogue cơ chế 18 skill còn lại, phiên chính đối chiếu lại tên script/đường dẫn với nguồn.
- Mức rủi ro / số PR: S; **1 PR** (2 hạng mục nhỏ: 1 chỉ tài liệu, 1 hook + test; cùng chủ đề "đối chiếu", không chung file với PR đang chạy của audit tự động hóa — kiểm `gh pr list` = 0 PR mở lúc bắt đầu).
- Scope / non-goal: Scope = bản đối chiếu + 2 hạng mục cột "nông hơn". Non-goal = không vendor skill/plugin của CE; không sửa 7 hook còn lại đọc `CLAUDE_PROJECT_DIR` (ghi điều kiện xem lại ở TRAPS 45); không dọn 5 worktree `/tmp/projects-template-*` prunable (để `/maintain`).
- Spec / goal / issue: `docs/framework/adopt-from-outside.md` (phương pháp); không spec (mức S, không `feat`).
- Nhánh / base SHA / thời điểm reconcile: `docs/doi-chieu-compound-engineering` @ `026a8a3` · 2026-10-09T17:56:10Z (worktree riêng trong scratchpad vì checkout chính đang dở `fix/hooks-git-bypass` của lane audit).

## Kế hoạch và phân công

Một PR, phiên chính tự làm: (1) đọc nguồn @ `67035e9` (clone nông vào scratchpad, dữ liệu); (2) grep cổng đang chạy ở template cho từng ứng viên; (3) đo ứng viên cột 2/3 bằng lệnh; (4) viết bản đối chiếu; (5) lấy (A) reviewer/review đối chiếu TRAPS (ngoại lệ 3) và (B) `precompact-checkpoint.sh` chụp đúng cây (test 8b đỏ trước); (6) `/gate` → PR → auto-merge.

## Quyết định và bằng chứng

- Chọn worktree riêng từ `origin/main` thay vì làm trên checkout chính (đang dở lane audit, 9 file sửa) · bậc 1 (không trộn hai lane).
- (A) Đo: `grep -c "Tái phát" TRAPS.md` = 5; `grep TRAPS .claude/agents/reviewer.md .claude/commands/review.md` = 0 → cột 2, lấy một dòng + một bước. Ngoại lệ 3 (chỉ tài liệu/brief).
- (B) Đo: chạy `precompact-checkpoint.sh` với cwd = `.claude/worktrees/agent-a4d4ec29e68d8ac34` (nhánh `worktree-agent-…`), `CLAUDE_PROJECT_DIR` = checkout chính → `.claude/.compact-checkpoint` ghi `Branch: fix/hooks-git-bypass` → sai cây (TRAPS 45 tái phát). Test `test-hooks-session.sh` mục 8b **đỏ trước** (2 ❌: "checkpoint sai cây", "compact.log thiếu dòng nhánh feat/wt"), sửa hook (ROOT = `git rev-parse --show-toplevel`, lùi về `CLAUDE_PROJECT_DIR`; `compact.log` gộp về `LOG_ROOT` = checkout chính) → 8/8b xanh. Mục 8 cũ đổi cwd = dự án giả (bài học TRAPS 45).
- Loại sau khi đo: worker base-SHA (3 worktree agent đều `merge-base` = `4d4ff79` = HEAD lúc dispatch); `validate-doc-claims` (docs-consistency mục 1 đã quét mọi *.md). Ghi ở báo cáo §4.
- `shellcheck --severity=warning` hook + suite: 0 phát hiện; `check-shell-complexity.sh`: OK.

## Lần thử / blocker

- Bản nháp đầu "không lấy gì" sai ở (B): tin TRAPS 45 đã đóng khuôn; đo lại 8 hook mới thấy. Ghi làm đính chính.
- `test-hooks-session.sh` toàn bộ trên máy Windows này có thể đỏ giả ở mục khác (F-Q6, PR-3 của lane audit chưa merge) — ghi số ca thật ở §7; CI Linux là cổng thật.

## Bàn giao / bước tiếp theo

- Đã xong. Commit/merge cuối cùng do chủ repo chạy `--no-verify` tại máy local (hook gate đỏ vì F-Q6 — bản ghi ở "Lần thử / blocker"); cổng thật là CI.

## Nghiệm thu cuối (chỉ điền khi đủ bằng chứng)

- PR #255 MERGED (squash) → `main` @ `abc3058`; CI 13 check xanh ở lượt cuối (sau merge `main` có #256, xung đột CHANGELOG giải giữ cả hai mục, commit `46f9529`).
- DoD: báo cáo đối chiếu `docs/reports/2026-10-09-doi-chieu-compound-engineering.md`; (A) `reviewer.md` + `/review` Bước 2b; (B) `precompact-checkpoint.sh` + `test-hooks-session.sh` mục 8b (đỏ-trước 2 ca → xanh); TRAPS 45 tái phát; CHANGELOG #255.
- Giới hạn còn lại: 7 hook khác vẫn lấy ROOT từ `CLAUDE_PROJECT_DIR` (điều kiện xem lại ở TRAPS 45); `test-workflow-guards.sh` 1 ca đỏ trên máy Windows này tái hiện cả trên `main` sạch (không thuộc PR này, chưa có hồ sơ riêng); `test-py-coverage-exit.sh` không chạy xong trên máy này.
- Nghiệm thu: phiên chính theo ủy quyền §3d, 2026-10-10.
