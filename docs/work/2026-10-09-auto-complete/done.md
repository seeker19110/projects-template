# Công việc: `/auto-complete` — làm tới xong, tự quyết theo thứ tự ưu tiên

- Work ID: 2026-10-09-auto-complete
- Yêu cầu / outcome: chủ repo: "1 agent thay tôi quyết định tất cả khi ở chế độ /auto-complete, ưu tiên chất lượng cao, ít code, bảo mật"; "gộp cả 2 vào" → một lệnh nối `/auto` → `/completion`, phiên chính là người quyết định theo thang ưu tiên §3d.
- Trạng thái: Done
- Chủ trì / writer: phiên chính (một PR)
- Mức rủi ro / số PR: M; 1 PR (feat, spec gọn Approved)
- Scope / non-goal: spec §5
- Spec / goal / issue: `docs/specs/2026-10-09-auto-complete.md`
- Nhánh / base SHA / thời điểm reconcile: `claude/kind-cori-k7x4p6` restart từ `origin/main` sau khi #239 merge (chờ), 2026-10-09

## Kế hoạch và phân công

Một đơn vị, phiên chính tự làm; đi sau #239 theo FIFO.

## Quyết định và bằng chứng

- Chọn: lệnh mỏng + thang ưu tiên trong §3d · Loại: agent `decider` riêng · Bậc: (1) harness không cho subagent điều phối (sai chức năng), (2) ít hơn một hop.
- Chọn: thang 4 bậc cố định · Loại: để §3d mô tả chung như cũ · Bậc: (3) kiểm được — test hợp đồng khoá thứ tự.
- TDD: tài liệu/lệnh/test hợp đồng → ngoại lệ 3 (§3.6); test `DecisionOrder` 3 ca xanh, `check-docs-consistency.sh` OK.

## Lần thử / blocker

- Bằng chứng cổng 2026-10-09 (cây đã stage): `dev-task.sh gate` PASS 4/4; `check-docs-consistency.sh` OK (lệnh ↔ CLAUDE.md hai chiều); `test-check-scripts.sh` OK; `test-copy-framework.sh` OK (lệnh + docs/framework đi sang đích); `test_adaptive_process.py` 8/8 (3 ca `DecisionOrder` mới).

## Bàn giao / bước tiếp theo

Đã xong: PR #240.

## Nghiệm thu cuối (chỉ điền khi đủ bằng chứng)

DoD đạt: PR #240 MERGED (squash) 2026-10-09 → `main` 06c3368; required checks xanh trên head `a4c867f`; 3/3 AC map test. Giới hạn: thang ưu tiên là luật cho model tuân, không có cổng máy đếm quyết định. Nghiệm thu: phiên chính theo ủy quyền §3d, 2026-10-09.
