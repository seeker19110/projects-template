# Công việc: Hoàn thiện repo khung sau vòng lặp /auto-complete v2

- Work ID: 2026-10-12-hoan-thien-khung-sau-loop-v2
- Yêu cầu / outcome: chủ repo 2026-10-12 "xong rồi hoàn thiện khung này luôn nha, tham khảo cả repo stored" → `/auto-complete` Giai đoạn B (Pha 0–4 `project-completion.md`) trên chính repo khung: hết lỗi đã biết, sổ sách khớp Git, DoC có bằng chứng.
- Trạng thái: Done 2026-10-13 (PR #298 `9f6b6f9`, #301 `d671436`, #302 `5aabe93`, #303 `5eda743`, #304 `39093d6` — squash merge; đóng hồ sơ ở PR đóng)
- Chủ trì / writer: phiên chính (tự duyệt mọi cổng theo §3d); worker `standard` cho PR-2/PR-3 nếu tách được, worktree riêng ngoài cây.
- Mức rủi ro / số PR: M (nhiều PR nhỏ, không đổi hành vi người dùng); 4 PR tuần tự (harness chỉ push một nhánh): PR-1 sổ sách, PR-2 DEBT + tách sweep + lint worktree, PR-3 bảng giá, PR-4 re-audit + đóng.
- Scope / non-goal: trong — F-001..F-007 ở `docs/ops/COMPLETION-PLAN.md` chu kỳ 2026-10-12; ngoài — repo xgold/case-study-ft41 (stored 23 §8 chỉ đối chiếu khung với nguồn sống), FT-13/FT-41, quy trình release của khung (F-008).
- Spec / goal / issue: không spec (mức M chore/fix/refactor, không tính năng mới — §3c); kế hoạch + DoC: `docs/ops/COMPLETION-PLAN.md` mục "Chu kỳ 2026-10-12".
- Nhánh / base SHA / thời điểm reconcile: `claude/sharp-goldberg-4owppu` @ `39093d6` · 2026-10-13T06:10Z (lần đầu `eb6430a` 2026-10-12T22:59:22Z)

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
- PR-3 (W-405): test cũ chỉ kiểm "có khoá giá" (không rơi về `default`) nên chuỗi con `haiku` che lỗi Haiku 5.5 → thêm ca kiểm CHI PHÍ
  thật 1M+1M cho 4 model (đỏ-trước 2 ca) · loại chỉ thêm khoá không test · bậc 3 (kiểm được). Không đổi model gợi ý cho subagent
  (Haiku 4.5 → 5.5 rẻ hơn 10×) — đổi agent/model là quyết định chính sách, đưa vào báo cáo cuối làm góp ý.
- Chủ repo 2026-10-13 "xem thêm đề xuất nâng cấp" → đối chiếu #299 + stored @ `f98ccdb` (23 §7b, 12 §3, 16 §2c–§2d) theo
  `adopt-from-outside.md`: báo cáo `docs/reports/2026-10-13-doi-chieu-goi-y-nang-cap.md`. Lấy 1 (W-411 khoá hash requirements-ci, bắt
  thêm lớp lỗi: phụ thuộc bắc cầu trôi) · loại cổng `author_association` (0 workflow có trigger đó) · bậc 1–2. Đổi model mặc định và
  job lan chuẩn sang repo con vượt ủy quyền (settings `permissions.ask`, token + hành động ra repo khác) → câu hỏi cho chủ repo.

## Lần thử / blocker

- 13b đỏ ở pre-commit 2 lần (PR-3, file `done.md` không đổi) → gốc F-011, không phải lỗi PR-3; chuỗi đỏ dừng ở 2/3.
- W-406 BLOCKED cần chủ repo (patch ở COMPLETION-PLAN).

## Bàn giao / bước tiếp theo

Lượt đã đóng. Việc còn lại thuộc chủ repo (vượt ủy quyền §3d, ghi ở `docs/reports/2026-10-13-doi-chieu-goi-y-nang-cap.md` §4):
W-406 patch lint `.claude/project-commands.sh` (bỏ `./.claude/worktrees/*`); Q1 job lan chuẩn sang repo con (cần PAT + danh sách repo);
Q2 đổi model mặc định Sonnet 5 → 5.5 và subagent `model: haiku` → Haiku 5.5 (ADR mới, PR không auto-merge).

## Nghiệm thu cuối (chỉ điền khi đủ bằng chứng)

- DoD (DoC 5 ô ở `docs/ops/COMPLETION-PLAN.md` chu kỳ 2026-10-12): đủ 5/5, mỗi ô kèm bằng chứng. 0 Cao mở (F-013 sửa đỏ-trước:
  `test-hooks-gate-guard.sh` mục 17 ❌ cả 2 hook → ✅; mục 21 quét tĩnh `… | grep -q` 28 chỗ → 0); F-001..F-012 có kết cục.
- PR MERGED (squash): #298 → `9f6b6f9` (PR-1 sổ sách), #301 → `d671436` (PR-2 tách `sweep_deps` + DEBT một dòng),
  #302 → `5aabe93` (PR-3 bảng giá), #303 → `5eda743` (W-409 F-011/F-013, chủ repo duyệt + merge), #304 → `39093d6` (PR-4 đối chiếu
  đề xuất nâng cấp + khoá hash `requirements-ci.txt`). `origin/main` đã đối chiếu `39093d6` trước PR đóng.
- Re-audit Pha 4 trên `39093d6` (2026-10-13): `dev-task.sh gate` `PASS: 4 kiểm tra`; radar `100/100`, "Không còn tín hiệu nợ kỹ thuật";
  `maintenance-sweep.sh --strict --no-deps` 🔴 0 · 🟡 0; docs-consistency / ci-policy / progress-freshness OK;
  `loop-state.sh --brief`: `open 1 doing 0 done 43 dropped 2` (ô ⬜ duy nhất W-408 = PR đóng).
- Giới hạn/rủi ro còn lại: W-406 BLOCKED (gate đỏ thoáng qua chỉ khi dùng `Agent(isolation=worktree)` và harness dọn worktree giữa
  lượt lint); `release-readiness.md` NO-GO 18/18 là mẫu cho dự án đích (F-008 chấp nhận); alias `haiku` của Claude Code trỏ bản nào
  chưa xác minh (chi phí ước tính của 4 agent `model: haiku` có thể lệch); sweep 🟡 0 cần `core.hooksPath` đã bật ở checkout.
- Nghiệm thu: phiên chính theo ủy quyền §3d, 2026-10-13.
