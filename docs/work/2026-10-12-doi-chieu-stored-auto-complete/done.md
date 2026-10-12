# Công việc: doi-chieu-stored-auto-complete

- Work ID: 2026-10-12-doi-chieu-stored-auto-complete
- Yêu cầu / outcome: chủ repo 2026-10-12: "nghiên cứu https://github.com/seeker19110/stored lấy những điểm tốt tích hợp sâu vào dự án để hiện thực hoá: chỉ cần /auto-complete là tự động nghiên cứu, lập kế hoạch, chọn kiến trúc… → code → loop → fix → bàn giao sản phẩm"; sau đó hỏi thêm "thiếu gì không? bổ sung cho tôi". Outcome: bản đối chiếu ba cột + các hạng mục tốt hơn bản hiện có thành cổng máy.
- Trạng thái: Done 2026-10-12 (PR #289 squash merge `59bd1d1`)
- Chủ trì / writer: phiên chính (không giao subagent: một PR, §3c)
- Mức rủi ro / số PR: M; 1 PR (bốn đơn vị nhỏ độc lập, cùng chủ đề; harness chỉ cho một nhánh)
- Scope / non-goal: Scope = K1–K4 (spec §5). Non-goal = các mục "chưa cần" ở báo cáo §3; sửa kho `stored` (chỉ báo sai lệch).
- Spec / goal / issue: `docs/specs/2026-10-12-auto-complete-tron-vong.md` (Approved 2026-10-12, trước khi sửa cổng); báo cáo `docs/reports/2026-10-12-doi-chieu-stored.md`.
- Nhánh / base SHA / thời điểm reconcile: `claude/trusting-cori-2i53gj` @ `23f5100` (main sau #288) · 2026-10-12, đặt lại nhánh sau merge

## Kế hoạch và phân công

1. Đọc `stored` (README/WORKFLOW, mục 03/09/13/21/23). 2. Grep cổng đang chạy ở đây cho từng ứng viên. 3. Spec gọn + test đỏ-trước. 4. Cổng 13b, 16, `ask`, `/auto-complete`. 5. Báo cáo, sổ, commit, push.

## Quyết định và bằng chứng

- K1 chọn: cổng nội dung `done.md` trong docs-consistency (mục 13b) · loại: hook Stop tự đọc nội dung `done.md` (đặt cổng ở chỗ chạy mỗi PR, bắt cả lúc không có vòng) · bậc 3. Đo 29 `done.md`: 1 thiếu mục "Nghiệm thu cuối" → tìm PR/SHA cả file (bậc 1, không chặn oan).
- K2 chọn: ≥ 2 phương án, nhận bullet/bảng/đoạn in đậm · loại: kiểm nội dung lý do (không máy được) · bậc 2. Đính chính A (ADR-0005).
- K3 chọn: `ask` (người vẫn duyệt được) · loại: `deny` (chặn cả sửa chính đáng), hook PreToolUse soi Bash (thêm code, chưa có ca) · bậc 2; giới hạn ghi TRAPS 70.
- K4 chọn: nối playbook có sẵn trong `auto-complete.md` · loại: lệnh/agent mới · bậc 2. Bổ sung theo câu hỏi chủ repo: `/review` tách người viết, clone sạch + smoke.
- Đỏ-trước (chạy thật): `test-check-scripts.sh` 5 ca đỏ (13b ×3, 16 ×2) → OK; `test-hooks-gate-guard.sh` mục 19 thiếu `ask` đỏ → OK; `test_adaptive_process` đỏ hai lần (bản đầu, rồi `/review`…) → OK.
- Cổng sau sửa: `check-docs-consistency.sh` OK trên repo thật (16 mục), `spec-compiler --trace` TRACE COMPLETE, contract C-1..C-4 OK.

## Lần thử / blocker

Không blocker. Đính chính A–D ghi trong báo cáo §6.

## Bàn giao / bước tiếp theo

Không còn việc. PR #289 đã merge; hồ sơ đóng cùng PR #290 (theo §3e: checkpoint sau merge tích hợp vào PR kế tiếp).

## Nghiệm thu cuối (chỉ điền khi đủ bằng chứng)

- DoD: K1–K4 có test đỏ-trước (`test-check-scripts.sh` mục 13b/16, `test-hooks-gate-guard.sh` mục 19, `test_adaptive_process`);
  báo cáo ba cột `docs/reports/2026-10-12-doi-chieu-stored.md`; spec `docs/specs/2026-10-12-auto-complete-tron-vong.md` TRACE COMPLETE.
- PR MERGED: #289 → `59bd1d1` trên `main` (merge 2026-10-12T06:13Z); CI 15/15 xanh ở head `6997858`, `automerge` skipped.
- Giới hạn/rủi ro còn lại: `permissions.ask` chỉ che Edit/Write, không che Bash ghi file (TRAPS 70, có điều kiện xem lại);
  9 hạng mục "chưa cần" ở báo cáo §3. Sau đó `/auto` + `/completion` gộp vào `/auto-complete` (PR #290) — K4 sống trong lệnh gộp.
- Nghiệm thu: phiên chính theo ủy quyền §3d, 2026-10-12, theo yêu cầu chủ repo "đóng luôn hồ sơ stored-auto-complete".
