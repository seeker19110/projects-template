# Công việc: Port các bản sửa audit 2026-09-15 còn thiếu từ nhánh codex/open-branch-integration

- Work ID: 2026-10-11-port-open-branch
- Yêu cầu / outcome: người dùng 2026-10-11: "port các commit đó thành PR fix" — các bản sửa audit 2026-09-15 trên nhánh local `codex/open-branch-integration` mà `main` còn thiếu (kiểm theo hành vi), mỗi mục một PR `fix:` có test đỏ-trước; xong thì xoá nhánh.
- Trạng thái: Active (PLAN check OK 2026-10-11)
- Chủ trì / writer: phiên chính (Opus 5.5) tích hợp; worker worktree riêng theo `route:` trong PLAN.md.
- Mức rủi ro / số PR: M; 7 PR (`docs/work/2026-10-11-port-open-branch/PLAN.md`) + PR này (hồ sơ) — mỗi phát hiện một PR để review/revert độc lập.
- Scope / non-goal: Scope = F-202, F-306, F-303/F-305, T-2, F-207, F-104, F-201/F-403. Non-goal = mục đã có trên `main` (F-301, F-302/F-404, F-304, F-401, F-102), mục lỗi thời (F-103 số liệu), W-307 (lệch nhẹ, chưa có sự cố) và F-101 phần cứng hoá (thấp) — xem lại khi tái phát.
- Spec / goal / issue: PLAN.md trong hồ sơ; đối chiếu theo hành vi do agent read-only làm 2026-10-11 (bảng ID ↔ ON-MAIN/MISSING/OBSOLETE), phiên chính tự tái hiện lại F-202, F-306, F-303.
- Nhánh / base SHA / thời điểm reconcile: `docs/port-open-branch-plan` @ `ac75f09` · 2026-10-10T23:20:13Z

## Kế hoạch và phân công

Theo PLAN.md: đợt 1 song song T1/T2/T3 (worker worktree riêng), đợt 2 T4/T5 + T6 sau T3, đợt 3 T7 sau T6. Phiên chính: đọc diff, chạy lại cổng, commit, PR, CHANGELOG, auto-merge, cập nhật PROGRESS dưới ngưỡng PF-1.

## Quyết định và bằng chứng

- Quyết định F-104: thiết kế gốc cần dòng "Nhánh đang làm" mà PROGRESS.md đã bỏ từ #177 → port nguyên văn sẽ không bao giờ đỏ. Chọn: trễ first-parent ≥ `PF_MAX_BEHIND` (mặc định 5 = WIP 3 + 1 squash + 1 dư; nay 7 theo WIP 5, xem dưới) → đỏ · loại: ngưỡng 2 (mọi PR song song đỏ oan) · bậc 1 §3d (đúng, không chặn oan).
- Mở rộng phạm vi do người dùng yêu cầu 2026-10-11 ("sửa lại trần mở 5pr", "5pr toàn cục"): trần WIP 3 → **5 PR mở đồng thời toàn repo** (cổng `pr-policy.yml` + test `tests/test_runtime_safety.py`, CLAUDE.md §8, AGENTS.md, pr-flow.md, `/auto-complete`, repository-settings, COMPLETION-PLAN, chú thích dependabot). Hệ quả: ngưỡng PF-1 của T6 đổi 5 → 7 (giữ công thức WIP + 1 squash + 1 dư). Lịch sử (TRAPS, spec, goal, report, ADR-0011) giữ nguyên số cũ.
- Lệch kế hoạch T3 (2026-10-11): ba ca mới đẩy `scripts/test-check-scripts.sh` sát trần 400 dòng của radar → tách suite PF sang `scripts/test-check-progress-freshness.sh`, helper chung `scripts/_check-scripts-test-lib.sh`, bước CI riêng. Hệ quả: T6 đổi điểm chạm sang suite mới; T7 chỉ còn phụ thuộc T3, chạy song song được với T6 · bậc 2 §3d (file nhỏ, ít xung đột).
- Quyết định F-306: theo ngữ nghĩa `Copy-Tree` của `.ps1` (`src/.` + `mkdir -p`) thay vì xoá rồi copy lại · bậc 2 (ít thay đổi, hai bản khớp nhau).

## Lần thử / blocker

- Cổng chạy song song chết rc=127 / fork `Resource temporarily unavailable`: bộ nhớ commit của Windows chỉ còn ~2 GB (trần = RAM, page file gần như tắt). Không phải lỗi mã: chạy lại từng suite một thì xanh. Cách làm: mọi suite/cổng nặng chạy tuần tự.

## Bàn giao / bước tiếp theo

- PR-0 #277 MERGED. T1/T2/T3 code xong trong worktree riêng (scratchpad phiên); đang chạy cổng tổng tuần tự rồi mở PR theo thứ tự T3 → T1 → T2. Tiếp: T4/T5 + T6/T7 sau khi T3 merge.

## Nghiệm thu cuối (chỉ điền khi đủ bằng chứng)

<DoD, mọi PR MERGED + merge SHA và main đã đối chiếu, giới hạn/rủi ro còn lại,
ngày và người nghiệm thu theo ủy quyền. Khi đủ điều kiện rename working.md → done.md
trong cùng thư mục; không overwrite lịch sử. Chưa có PR/merge thì giữ working.md.>
