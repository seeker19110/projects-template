# Công việc: TRAPS 48 tái phát: gh pr update-branch sinh commit không conventional

- Work ID: 2026-10-10-traps-48-update-branch
- Yêu cầu / outcome: ghi tái phát TRAPS 48 (vector `gh pr update-branch`, PR #263) + luật ở `pr-flow.md`; checkpoint PROGRESS sau #263.
- Trạng thái: Active
- Chủ trì / writer: phiên chính (Fable 5.1)
- Mức rủi ro / số PR: S; 1 PR chỉ tài liệu (ngoại lệ 3 §3.6)
- Scope / non-goal: TRAPS 48, `pr-flow.md` §2, CHANGELOG, PROGRESS; non-goal: cổng máy mới (job `metadata` đã bắt đúng ca)
- Spec / goal / issue: không (mức S)
- Nhánh / base SHA / thời điểm reconcile: `docs/traps-65-update-branch` @ `75e41ad` · 2026-10-10T04:52:53Z

## Kế hoạch và phân công

Một PR `docs/traps-65-update-branch` (worktree scratchpad riêng theo TRAPS 63). AC: `check-docs-consistency.sh` + `check-progress-freshness.sh` xanh; CI xanh; auto-merge squash.

## Quyết định và bằng chứng

- Tái phát của 48 (không mở mục mới): cùng khuôn "commit do công cụ sinh không conventional", chỉ khác vector (server-side update-branch). Bằng chứng: job `metadata` run 38023894088 đỏ ở commit 2aa29dd; thay bằng 97a3ec3 → xanh.
- Không thêm cổng máy: `metadata` đã chặn đúng trước merge; luật nằm ở `pr-flow.md`.

## Lần thử / blocker

Không.

## Bàn giao / bước tiếp theo

Sau merge: checkpoint PROGRESS + rename → done.md ở PR kế (hoặc gộp vào PR tiếp theo của repo).

## Nghiệm thu cuối (chỉ điền khi đủ bằng chứng)

<DoD, mọi PR MERGED + merge SHA và main đã đối chiếu, giới hạn/rủi ro còn lại,
ngày và người nghiệm thu theo ủy quyền. Khi đủ điều kiện rename working.md → done.md
trong cùng thư mục; không overwrite lịch sử. Chưa có PR/merge thì giữ working.md.>
