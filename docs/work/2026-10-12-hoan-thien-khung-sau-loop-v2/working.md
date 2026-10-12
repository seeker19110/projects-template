# Công việc: Hoàn thiện repo khung sau vòng lặp /auto-complete v2

- Work ID: 2026-10-12-hoan-thien-khung-sau-loop-v2
- Yêu cầu / outcome: chủ repo 2026-10-12 "xong rồi hoàn thiện khung này luôn nha, tham khảo cả repo stored" → `/auto-complete` Giai đoạn B (Pha 0–4 `project-completion.md`) trên chính repo khung: hết lỗi đã biết, sổ sách khớp Git, DoC có bằng chứng.
- Trạng thái: Active
- Chủ trì / writer: phiên chính (tự duyệt mọi cổng theo §3d); worker `standard` cho PR-2/PR-3 nếu tách được, worktree riêng ngoài cây.
- Mức rủi ro / số PR: M (nhiều PR nhỏ, không đổi hành vi người dùng); 4 PR tuần tự (harness chỉ push một nhánh): PR-1 sổ sách, PR-2 DEBT + tách sweep + lint worktree, PR-3 bảng giá, PR-4 re-audit + đóng.
- Scope / non-goal: trong — F-001..F-007 ở `docs/ops/COMPLETION-PLAN.md` chu kỳ 2026-10-12; ngoài — repo xgold/case-study-ft41 (stored 23 §8 chỉ đối chiếu khung với nguồn sống), FT-13/FT-41, quy trình release của khung (F-008).
- Spec / goal / issue: không spec (mức M chore/fix/refactor, không tính năng mới — §3c); kế hoạch + DoC: `docs/ops/COMPLETION-PLAN.md` mục "Chu kỳ 2026-10-12".
- Nhánh / base SHA / thời điểm reconcile: `claude/sharp-goldberg-4owppu` @ `d898fef` · 2026-10-13T01:45Z (lần đầu `eb6430a` 2026-10-12T22:59:22Z)

## Kế hoạch và phân công

Bảng W-401..W-408 ở `docs/ops/COMPLETION-PLAN.md` (nguồn sự thật, không chép lại). Thứ tự PR: PR-1 (W-401, W-402, W-407) →
PR-2 (W-403, W-404, W-406) → PR-3 (W-405) → PR-4 (W-408). Tuần tự vì cùng nhánh harness; PR-2/PR-3 độc lập về file nên worker
có thể code song song trong worktree scratchpad trong lúc PR trước chờ CI, phiên chính tích hợp + chạy cổng (không chạy `/gate`
khi worker còn test trong checkout — TRAPS 63).

## Quyết định và bằng chứng

- Điểm vào Giai đoạn B (bỏ A): việc mới đã xong và merge (#295–#297), yêu cầu là "hoàn thiện" · bậc 1 (đúng điểm vào).
- Pha 0: FEATURE-MAP/CODEMAP/CONVENTIONS có từ chu kỳ trước — rà khớp, không lập lại; cổng Pha 0 tự duyệt §3d.
- Pha 1 (base `eb6430a`): số đo + 10 phát hiện ghi ở COMPLETION-PLAN chu kỳ 2026-10-12. Nguồn sống bảng giá:
  WebFetch trang pricing của platform.claude.com (docs/en/about-claude/pricing) 2026-10-12 (Haiku 5.5 0.10/0.50 ≤ 100K token; Sonnet 4.x 3/15).
- Pha 2: kế hoạch W-401..W-408 + DoC 5 ô tự duyệt §3d 2026-10-12. Chọn 4 PR nhỏ · loại 1 PR gộp (review/revert khó, trộn
  refactor với sửa giá) · bậc 3 (kiểm được). Chọn tách mảng dependency của sweep (khối liền ~95 dòng, đã có ranh giới hàm) · loại
  nén dòng cho dưới 400 (che triệu chứng) · bậc 2.
- F-003 dương tính giả của sweep: DEBT `_gh_list` trải 4 dòng docstring nên dòng chứa `DEBT:` thiếu `xem lại khi:` — sửa nội dung
  về một dòng thay vì nới regex sweep · bậc 2 (ít hơn).
- stored 23 §8 "bảng giá lệch với xgold": không đọc được xgold (ngoài phạm vi phiên) → đối chiếu khung với nguồn sống; ghi giới hạn.
- PR-1 (W-401/402/407): đóng 3 hồ sơ stale có PR/SHA thật từ `gh api …/pulls?state=closed` (REST, GraphQL 403 trong cloud).
- PR-2 làm trong worktree scratchpad `wt-pr2` từ `e8951a0` (TRAPS 63: checkout chính để yên). W-406 bị harness TỪ CHỐI sửa
  `.claude/project-commands.sh` (cấu hình cổng ở `permissions.ask`, #289) → không lách bằng script khác; ghi BLOCKED + patch ở kế hoạch,
  câu hỏi cho chủ repo ở báo cáo cuối · bậc 1 (quyền/cấu hình cổng thuộc "không bao giờ tự quyết").
- W-404 tách nguyên văn khối mảng 2 (dòng 119–209) sang `scripts/_sweep-deps.sh`; lần gate 1 đỏ shellcheck SC2034 (lint chạy từng
  file, không theo `source`) → directive tại 2 phép gán; lần 2 đỏ 31 ca `test-maintain-cron.sh` (fixture chép danh sách helper tường minh,
  thiếu helper mới → `No such file`) → thêm vào 2 danh sách `cp`; lần 3 gate PASS.
- PR-1 #298 merge → `9f6b6f9` (2026-10-12T23:30Z). Main có thêm #299 `e55ed48` + #300 `d898fef` (phiên chủ repo: báo cáo
  `docs/reports/2026-10-13-goi-y-nang-cap.md`) → nhận làm W-410/F-012, phân loại ở PR-4 theo `adopt-from-outside.md` §2.
- F-011 (gốc thật của 13b chập chờn): `printf | grep -q` dưới pipefail → SIGPIPE 141, đo 3/8640 lượt đỏ; here-string 0/8640.
  Bác bỏ giả thuyết "chung checkout" của TRAPS 63 tái phát. Sửa ở PR riêng W-409 KHÔNG auto-merge (file cổng/hook ở `permissions.ask`)
  · bậc 1 (đúng + bảo mật: hook chặn git nguy hiểm fail-open khi bỏ lỡ khớp).

## Lần thử / blocker

- 13b đỏ ở pre-commit 2 lần (PR-3, file `done.md` không đổi) → gốc F-011, không phải lỗi PR-3; chuỗi đỏ dừng ở 2/3.
- W-406 BLOCKED cần chủ repo (patch ở COMPLETION-PLAN).

## Bàn giao / bước tiếp theo

PR-2 (W-403/W-404 + đánh dấu PR-1 ✅) từ `d898fef` → PR, auto-merge. Kế: PR-3 W-405 (bảng giá, đã code + đỏ-trước trong
worktree `wt-pr3`) → PR W-409 (here-string, chờ chủ repo) → PR-4 W-408/W-410 re-audit + đóng.

## Nghiệm thu cuối (chỉ điền khi đủ bằng chứng)

<DoD, mọi PR MERGED + merge SHA và main đã đối chiếu, giới hạn/rủi ro còn lại,
ngày và người nghiệm thu theo ủy quyền. Khi đủ điều kiện rename working.md → done.md
trong cùng thư mục; không overwrite lịch sử. Chưa có PR/merge thì giữ working.md.>
