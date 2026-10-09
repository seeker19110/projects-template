# Công việc: Nghiệm thu agent bằng phiên thật + nâng trần subagent 3 → 5 (2026-10-09)

- Work ID: 2026-10-09-agent-acceptance
- Yêu cầu / outcome: chủ repo 2026-10-09: "tiếp tục cho đến khi xong dự án, chạy song song tối đa 5 subagent" →
  (U-C) trần subagent toàn cây 3 → 5 ở mọi file luật (CLAUDE.md §2, AGENTS.md, standard-delivery §3c,
  orchestration-3-tier, coordinator.md, auto.md, WORK.template, test) + ADR-0011;
  (U-A) FEATURE-MAP cột Test còn "❌ không có" ở FT-13..20 (11 agent `.claude/agents/`) và "Luồng chính" mục 4
  (chưa chạy PLAN.md đầu-cuối qua ba tầng thật): nghiệm thu bằng PHIÊN SUBAGENT THẬT theo đợt ≤ 5 agent song song,
  ghi báo cáo docs/reports/2026-10-09-agent-acceptance.md (tạo ở A-02), cột Test ghi đúng sự thật ("nghiệm thu phiên thật ngày …;
  không có test tự động").
- Trạng thái: Active
- Chủ trì / writer: phiên chính (Fable); subagent chỉ là ĐỐI TƯỢNG nghiệm thu, không ghi hồ sơ này
- Mức rủi ro / số PR: S (tài liệu + đổi hằng số luật + test cập nhật); dự kiến 2–3 PR tuần tự trên
  `claude/relaxed-knuth-f1ejlq`: A-01 trần 3→5 + ADR-0011; A-02 báo cáo nghiệm thu + FEATURE-MAP; A-03 closeout
- Scope / non-goal: không sửa agent trừ khi nghiệm thu lộ lỗi thật (khi đó PR riêng có test/bằng chứng);
  không chạy hosted CI/pilot/benchmark/harness ngoài Claude Code (không có môi trường).
- Spec / goal / issue: mức S — không spec; kế hoạch ở hồ sơ này
- Nhánh / base SHA / thời điểm reconcile: `claude/relaxed-knuth-f1ejlq` = `origin/main` `7f6bc93` (2026-10-09, sau #230)

## Kế hoạch và phân công

- A-01 (phiên chính): sed 3→5 các câu "tối đa 3 subagent đang chạy trong toàn cây", slot coordinator hai→bốn,
  `tests/test_adaptive_process.py` assert mới; ADR-0011 ghi quyết định (ADR-0010 giữ nguyên, chỉ bổ sung).
- A-02 nghiệm thu agent (đợt, ≤ 5 song song, mỗi agent một việc đóng có đáp án biết trước):
  - Đợt 1 (read-only, repo chính): `lookup`, `version-check`, `reviewer`, `tester` (worktree main riêng),
    `security-reviewer`.
  - Đợt 2 (worktree riêng/agent): `mechanical-worker`, `standard-worker`, `spec-executor`, `complex-implementer`,
    `maintainer` (plan-only).
  - Đợt 3: `coordinator` chạy PLAN.md 2 đơn vị trong sandbox git cục bộ (không mở PR GitHub).
  Tiêu chí mỗi agent: (1) ra đúng đáp án/khuôn output theo hợp đồng trong frontmatter; (2) KHÔNG vượt quyền
  (agent read-only không sửa file — kiểm bằng `git status`); (3) dừng đúng chỗ (không commit/merge).
- A-03: FEATURE-MAP FT-13..20 + Luồng chính mục 4; COMPLETION-PLAN/PROGRESS/CHANGELOG; done.md.

## Quyết định và bằng chứng

- Approved for implementation — phiên chính duyệt theo ủy quyền của chủ repo ngày 2026-10-07; ngày duyệt 2026-10-09;
  trần 5 là chỉ thị trực tiếp của chủ repo trong phiên (không phải suy đoán).
- TDD: A-01 là ngoại lệ 3 (tài liệu/config thuần) + test luật cập nhật.

## Lần thử / blocker

(chưa có)

## Bàn giao / bước tiếp theo

Đang chạy A-01 và đợt 1 của A-02 song song.

## Nghiệm thu cuối (chỉ điền khi đủ bằng chứng)

(chưa)
