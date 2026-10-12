# Công việc: Nghiên cứu vòng lặp coding để nâng /auto-complete tới tự hoàn thành

- Work ID: 2026-10-12-loop-research-auto-complete
- Yêu cầu / outcome: chủ repo 2026-10-12: "nghiên cứu sâu vòng lặp trong coding phát triển phần mềm để nâng cấp cho dự án tiến đến việc tự động hoàn thành khi có mục tiêu, yêu cầu và người dùng bật /auto-complete — bằng tất cả khả năng, tìm kiếm, học hỏi". Outcome: báo cáo đối chiếu ba cột theo `adopt-from-outside.md` (luật §2 mới 2026-10-12: tốt hơn bản hiện có là lấy) giữa vòng lặp hiện có (`standard-delivery.md` §4/§8, `/auto-complete`, hook, cổng) và nguồn ngoài (Anthropic, runner mã mở, sản phẩm thương mại, nghiên cứu) → thực hiện những hạng mục qua cổng §2.
- Trạng thái: Done 2026-10-12 (PR #287 squash merge `be58a19`)
- Chủ trì / writer: phiên chính (Fable 5.1); 4 agent read-only nghiên cứu web song song (Anthropic / mã mở / thương mại / học thuật).
- Mức rủi ro / số PR: M; **1 PR** gộp 3 đơn vị (mỗi đơn vị một commit riêng: `4740901` C, `e03887a` B, A + closeout) — harness phiên này chỉ cho push một nhánh (`claude/trusting-cori-2i53gj`), nên không tách PR; phiên chính tự làm (§3c: một PR).
- Scope / non-goal: Scope = cơ chế vòng lặp (lặp tới goal, verify, phát hiện kẹt/giậm chân, ngân sách, dừng, trạng thái qua phiên, cổng người). Non-goal = runner sửa source không giám sát (quyết 2026-10-10 "chưa", cần threat model riêng — chỉ nêu lại nếu nguồn ngoài cho bằng chứng mới); đổi luật merge/ủy quyền (C1/C2 báo cáo loop-engineering).
- Spec / goal / issue: spec gọn `docs/specs/2026-10-12-loop-guard-auto-complete.md` (Approved 2026-10-12, viết sau code — lệch ghi ở PR); báo cáo đối chiếu ở `docs/reports/` (tên `2026-10-12-doi-chieu-vong-lap-coding`); bốn báo cáo đối chiếu trước là nền: ralph (2026-10-10), loop-engineering (2026-10-11), compound-engineering (2026-10-09), SDD ba vai (2026-10-10).
- Nhánh / base SHA / thời điểm reconcile: `claude/trusting-cori-2i53gj` @ `770af27` · 2026-10-12T03:40:35Z

## Kế hoạch và phân công

1. Research ngoài: 4 agent song song (chỉ đọc web, không chạy code ngoài). 2. Đo nội bộ (§3 phương pháp): grep cổng đang chạy cho từng cơ chế ứng viên; đếm sự cố lặp thật trong TRAPS/work/CHANGELOG. 3. Tái đánh giá các mục "chưa cần" của 4 báo cáo trước theo luật §2 mới (ứng viên đầu tiên: N1 bộ đếm 3 lần, goal file chưa có cổng (đính chính B ralph), N3 thoát sớm, N7 ngân sách). 4. Báo cáo ba cột + danh sách lấy. 5. Thực hiện mục lấy: mỗi mục một PR qua `/gate`, TDD đỏ-trước cho cổng máy mới.

## Quyết định và bằng chứng

- Nguồn: 4 agent read-only (Anthropic · mã mở · thương mại · học thuật) + 1 agent kiểm kê `ConardLi/garden-skills` (chủ repo hỏi thêm giữa chừng); không chạy mã ngoài. Báo cáo `docs/reports/2026-10-12-doi-chieu-vong-lap-coding.md`: 41 cơ chế → lấy 3 (N1, N2, N3), garden-skills lấy 0.
- Chọn: một PR gộp 3 commit · loại: 3 PR theo §3c · bậc 1 §3d — luật harness "chỉ push nhánh được giao" là ràng buộc quyền (§9), không tự mở nhánh khác; đánh đổi: review/revert theo commit thay vì theo PR.
- N2 chọn: hook Stop đọc **file trạng thái** (`- Trạng thái:` của working.md, done.md, wind-down marker, chuỗi đỏ) · loại: (a) `/goal` của Claude Code (evaluator không đọc file, phán từ transcript — lời khai, §4), (b) chuỗi `<promise>` (ralph; §4), (c) runner ngoài (quyết 2026-10-10) · bậc 1 (không mở đường ghi không giám sát) rồi bậc 3 (kiểm được).
- N2 trần lượt: 20 (`AUTO_COMPLETE_MAX_CONTINUES`) · loại: 8 (cap của Claude Code đếm block liên tiếp không tool call, khác nghĩa) · bậc 1 (đúng ngữ nghĩa); đính chính (B) báo cáo.
- N1 chữ ký: dòng FAIL:/BLOCKED: đầu, khác chữ ký → về 1 · loại: đếm mọi lần đỏ · bậc 1 (ba BLOCKED thiếu ba công cụ khác nhau trong chính phiên này sẽ bị nhắc §8 oan); đính chính (C).
- N3 đặt ở `check-docs-consistency.sh` (helper `_docs-consistency-structure.sh`) · loại: `check-progress-freshness.sh` · bậc 2 (goal không phụ thuộc git).
- Marker `/auto-complete` sống một phiên: `session-resume.sh` xoá khi `source` ∉ {compact, resume} · loại: xoá mọi SessionStart · bậc 1 (xoá lúc nén sẽ tắt vòng đang chạy — ca test mục 10).
- Bằng chứng TDD đỏ-trước (chạy thật trong phiên): C — `test-check-scripts.sh` 2/3 ca mới đỏ trước, 3/3 xanh sau, cổng thật OK (3 goal hiện có không bị chặn oan); B — `test-hooks-gate-guard.sh` mục 20: 5 đỏ trước, 6/6 xanh sau; `test-hooks-gate.sh` OK; A — `test-hooks-loop.sh` đỏ (thiếu hook) → 8 đỏ do helper test nuốt output rỗng (sửa helper, không sửa hook) → OK 11 mục; `test-hooks-session.sh` OK; mục 19 settings khớp OK.
- Cổng tài liệu/CI sau khi nối: `check-docs-consistency.sh` OK (mục 6/11/14 đòi CODEMAP/FEATURE-MAP/bảng Hook — đã thêm), `check-ci-policy.sh` OK, `tests/test_ci_suite_parity.py` OK (suite mới chạy đúng một lần Linux), `tests/test_adaptive_process.py` OK. Commit qua `pre-commit-gate` (cổng đầy đủ) từng đơn vị.

## Lần thử / blocker

Lượt đầu bị chủ repo ngắt để đổi luật §2 trước (hồ sơ `2026-10-12-adopt-better-than-current`, commit 770af27); tiếp tục theo luật mới.

## Bàn giao / bước tiếp theo

Đã xong: PR #287 (6 commit, cả hồ sơ `2026-10-12-adopt-better-than-current`) merge `be58a19`; spec gọn `docs/specs/2026-10-12-loop-guard-auto-complete.md` thêm trước PR vì cổng `metadata` đòi (lệch trình tự ghi ở spec + PR). Việc kế thừa: TRAPS chưa cần mục mới (không sự cố mới); điều kiện xem lại của N4/N5/N6 và X-list ghi trong báo cáo; lượt `/auto-complete` thật kế tiếp là ca nghiệm thu hook giữ vòng.

## Nghiệm thu cuối (chỉ điền khi đủ bằng chứng)

- DoD: 3 cổng máy (hook Stop `auto-complete-guard.sh`, chuỗi đỏ cùng chữ ký ở `pre-commit-gate.sh`, docs-consistency mục 15) có test đỏ-trước, suite nối CI; báo cáo ba cột `docs/reports/2026-10-12-doi-chieu-vong-lap-coding.md` (41 → lấy 3; garden-skills lấy 0); spec AC-1..AC-7 TRACE COMPLETE.
- PR MERGED: #287 → `be58a19` trên `main`; CI 16/16 xanh ở head `cfcf1c8` (lần `metadata` đỏ đầu do tiêu đề PR 74 ký tự, sửa tiêu đề là xanh — không sửa code).
- Giới hạn/rủi ro còn lại: hook fail-open khi thiếu `jq` (có cảnh báo); mục 15 chỉ soi bảng có ô `State` ≥ 3 cột; runner không giám sát vẫn "chưa" (quyết 2026-10-10).
- Nghiệm thu: phiên chính theo ủy quyền §3d, 2026-10-12.
