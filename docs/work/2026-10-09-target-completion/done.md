# Công việc: Chạy vòng hoàn thiện (`/completion`) trên một DỰ ÁN ĐÍCH thật (2026-10-09)

- Work ID: 2026-10-09-target-completion
- Yêu cầu / outcome: chủ repo "tiếp tục cho đến khi xong đi" (sau đợt nghiệm thu agent) → mục duy nhất repo còn tự
  đánh dấu ⚠️ mà kiểm được ở đây: FEATURE-MAP "Luồng chính" mục 5 — vòng hoàn thiện/audit "chưa chạy trên dự án đích
  thật" (FT-08/FT-09) và FT-01 cột Test (`/consult` chỉ kiểm tồn tại). Outcome: chạy đủ Pha 0→4 của
  `docs/framework/project-completion.md` trên một dự án Node/vitest đích (copy khung bằng `copy-framework.sh`), audit bằng
  agent thật, sửa lỗi lộ ra theo TDD, re-audit hội tụ; ghi báo cáo docs/reports/2026-10-09-target-completion.md (tạo ở T-03).
- Trạng thái: Done
- Chủ trì / writer: phiên chính (Tầng 1 kiêm Tầng 2 — theo phát hiện 2026-10-09); auditor/worker là subagent (≤ 5 song song)
- Mức rủi ro / số PR: S cho repo khung (chỉ tài liệu + FEATURE-MAP); dự án đích là sandbox ngoài repo (git cục bộ)
- Scope / non-goal: dự án đích là fixture do phiên chính viết (`invoice-calc`, 4 module, 4 test) — KHÔNG phải sản phẩm
  production của chủ repo; kết luận ghi đúng giới hạn đó. Không sửa khung trừ khi vòng chạy lộ lỗi thật của khung.
- Spec / goal / issue: mức S — không spec
- Nhánh / base SHA / thời điểm reconcile: `claude/relaxed-knuth-f1ejlq` = `origin/main` `28f1e77` (2026-10-09, sau #233)

## Kế hoạch và phân công

- T-01 Pha 0 (phiên chính): `copy-framework.sh` → đích; `dev-task.sh doctor/gate` baseline; Bước 0 adoption (hồ sơ dự án,
  FEATURE-MAP/CONVENTIONS/CODEMAP đích); `/consult` brownfield một lượt (FT-01).
- T-02 Pha 1–4 (agent): audit nhóm 2/3/4/7/9/11/12 song song (read-only, mỗi agent ≤ 3 nhóm) → F-xxx → COMPLETION-PLAN đích
  (tự duyệt theo ủy quyền) → worker sửa theo TDD trong worktree riêng → reviewer/tester → merge cục bộ → re-audit.
- T-03 (phiên chính): báo cáo + FEATURE-MAP Luồng chính 5 / FT-01 cột Test + closeout → 1 PR.

## Quyết định và bằng chứng

- Approved for implementation — phiên chính duyệt theo ủy quyền của chủ repo ngày 2026-10-07; ngày duyệt 2026-10-09.
- TDD: PR khung là ngoại lệ 3 (tài liệu); sửa lỗi ở đích theo đỏ-trước (ghi trong báo cáo).

## Lần thử / blocker

- 3 worker bị hook `pre-commit-gate.sh` của phiên khung chặn khi commit trong worktree đích (gate sai repo, 2 lần đỏ giả do suite chạy đồng thời); không bypass, phiên chính commit thay sau khi xác nhận cổng đích xanh. Ghi trong báo cáo.
- #234: cổng `metadata` đỏ vì tiêu đề PR 75 ký tự → rút còn 66; squash vẫn lấy tiêu đề commit 90 ký tự → TRAPS 58 + cổng mới ở T-03.

## Bàn giao / bước tiếp theo

Đã xong T-01..T-03. Ngoài tầm: hosted CI trên repo đích thật, pilot, model benchmark, harness khác.

## Nghiệm thu cuối (chỉ điền khi đủ bằng chứng)

- Đích `9bb2127`: 76 test pass ở TZ=UTC và TZ=America/New_York; `dev-task.sh gate` PASS, evidence VERIFIED; re-audit Cao 0 · Trung 0 · Thấp 4 ghi nhận.
- Khung: #234 → `db9bda6` (F-T01/S-05); PR closeout T-03 (báo cáo `docs/reports/2026-10-09-target-completion.md`, FEATURE-MAP Luồng chính 5 + FT-01 ✅ có giới hạn, TRAPS 58).
