# Công việc: cổng khoá brief PLAN.md trước khi dispatch subagent

- Work ID: 2026-10-09-plan-check-gate
- Yêu cầu / outcome: chủ repo: "tối ưu quy trình [phân chia việc phiên chính ↔ subagent] lên mức hoàn hảo nhất, chất lượng cao nhất mà hoàn thành nhanh nhất" → chọn phạm vi: bịt 4 tổn thất đã đo ở nghiệm thu 2026-10-09 bằng mẫu brief + cổng máy.
- Trạng thái: Done
- Chủ trì / writer: phiên chính (một PR → tự làm, §3c)
- Mức rủi ro / số PR: M; 1 PR (feat, spec gọn Approved)
- Scope / non-goal: xem spec §5
- Spec / goal / issue: `docs/specs/2026-10-09-plan-check-gate.md`
- Nhánh / base SHA / thời điểm reconcile: `claude/kind-cori-k7x4p6` từ `origin/main` 3f96c30, 2026-10-09

## Kế hoạch và phân công

Một đơn vị, phiên chính tự làm: test đỏ → engine → mẫu → con trỏ tài liệu → TRAPS → cổng → push.

## Quyết định và bằng chứng

- Căn cứ chọn phạm vi: `adopt-from-outside.md` §luật 2 — mỗi "chưa có" ứng với sự cố thật (báo cáo agent-acceptance đợt 2–3).
- Không sửa prompt 11 agent: mẫu brief đã mang luật chung; xem lại khi nghiệm thu phiên thật lần sau còn lộ lỗi.
- TDD: `TestCheckPlan` 8 ca chạy đỏ (7 fail) trước khi thêm nhánh; sau: 50/50 characterization xanh (42 cũ + 8 mới).
- Bằng chứng cổng (2026-10-09, cây đã stage, base 3f96c30): `dev-task.sh gate` PASS (4 kiểm tra; pwsh 7.5.3 cài tay vì container thiếu); `check-docs-consistency.sh` OK (mục 12: mẫu không mồ côi); `test-py-coverage.sh` TOTAL 96 % ≥ 95; `check-python-complexity.sh` OK (CC mới cao nhất 10); `test-check-scripts.sh` OK sau `git add` (lần đầu đỏ 4 ca vì sandbox copy `git ls-files`, file mới chưa stage — không phải lỗi); `spec-compiler.sh --trace` TRACE COMPLETE 7/7 AC; shellcheck --severity=warning sạch.

## Lần thử / blocker

(chưa có)

## Bàn giao / bước tiếp theo

Chạy đủ cổng (docs-consistency, coverage, characterization, shellcheck, gate), commit `feat(dispatch): …`, push nhánh. PR do chủ repo mở hoặc yêu cầu.

## Nghiệm thu cuối (chỉ điền khi đủ bằng chứng)

DoD đạt: PR #239 MERGED (squash) 2026-10-09 → `main` 9561889; CI required checks xanh trên head `71d5ca5` (framework-lint, framework-lint-windows, copy-framework-smoke, docs-consistency, metadata, protection-guard, gitleaks, CodeQL); 7/7 AC map evidence. Giới hạn: cổng kiểm hình thức kín của brief, không kiểm nội dung khuôn. Nghiệm thu: phiên chính theo ủy quyền §3d, 2026-10-09.
