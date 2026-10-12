# Công việc: Tách test-check-scripts.sh (> 400 dòng)

- Work ID: 2026-10-12-tach-test-check-scripts
- Yêu cầu / outcome: chủ repo 2026-10-12 "tách test-check-scripts.sh luôn" → suite dưới trần 400 dòng (radar), giữ nguyên số ca.
- Trạng thái: Done 2026-10-12 (PR #293 squash merge `3954c65`)
- Chủ trì / writer: phiên chính
- Mức rủi ro / số PR: S, 1 PR (refactor test, không đổi hành vi cổng)
- Scope / non-goal: tách ca `check-ci-policy.sh` sang suite riêng; không sửa ca nào; không tách `maintenance-sweep.sh` (403 dòng)
- Spec / goal / issue: không cần spec (mức S, §3c); tiền lệ tách `test-check-progress-freshness.sh` 2026-10-11
- Nhánh / base SHA / thời điểm reconcile: `claude/sharp-goldberg-4owppu` @ `21d4c69` · 2026-10-12T15:55:38Z

## Kế hoạch và phân công

Một PR, phiên chính tự làm. Đo baseline → tách theo script mỗi ca gọi → nối CI/CODEMAP/FEATURE-MAP → đếm lại ca → cổng → PR.

## Quyết định và bằng chứng

- Tách theo script mỗi ca gọi (`run_check … check-ci-policy.sh` → suite mới) · loại "cắt theo nửa file" (khối "2." cũ trộn ca
  docs-consistency mục 13b/14/15/16) · bậc (1) đúng. 12 ca CP-* + baseline sang `scripts/test-check-ci-policy.sh` (123 dòng); ca
  mục 14 trước tiêu đề "2." chuyển về khối docs-consistency; tiêu đề step CI cũ đổi cho khớp phạm vi.
- Bằng chứng không đổi hành vi: baseline `test-check-scripts.sh` 54 ✅ / 0 ❌ → sau tách 41 + 13 = 54 ✅ / 0 ❌.
- Lần chạy đầu sau tách đỏ đúng chỗ: docs-consistency mục 6/FEATURE-MAP bắt script mới chưa khai → nối CODEMAP, FEATURE-MAP FT-70,
  step CI Linux; `test_ci_suite_parity` OK (mỗi suite chạy đúng một lần trên Linux), `check-ci-policy.sh` OK.
- Radar: hết `test-check-scripts.sh` (315 dòng); còn `maintenance-sweep.sh` 403 dòng — ngoài scope.

## Lần thử / blocker

- Cổng commit lần 1 đỏ ở `test-hooks-loop.sh` ca 1 (rc=141) — ngoài diff. Không gọi "flake": tái hiện 13/400 lượt pipeline
  `jq | auto-complete-guard.sh` đỏ 141 (hook `exit 0` trước khi đọc stdin → jq SIGPIPE + pipefail). Sửa `run_guard` sang
  here-string: 0/400 lượt pipeline, 0/60 lượt cả suite. Commit riêng `test(hooks)` trong cùng PR; TRAPS 71.

## Bàn giao / bước tiếp theo

Xong. Còn lại ngoài scope: `scripts/maintenance-sweep.sh` 403 dòng (radar); ba chỗ `printf | hook` cùng khuôn TRAPS 71 chưa tái hiện đỏ.

## Nghiệm thu cuối (chỉ điền khi đủ bằng chứng)

- DoD: suite dưới trần 400 dòng (`test-check-scripts.sh` 315, `test-check-ci-policy.sh` 123); số ca giữ nguyên 54 ✅ = 41 + 13;
  CODEMAP, FEATURE-MAP FT-70, step CI Linux đã khai; `test_ci_suite_parity` OK.
- PR MERGED: #293 → `3954c65` trên `main` (auto-merge squash, 2026-10-12T16:29Z); CI 15/15 xanh ở head `b73fbf0` (`automerge`
  skipped), gồm `framework-lint-windows`.
- Kèm theo: `test(hooks)` sửa race SIGPIPE ở `test-hooks-loop.sh` (13/400 → 0/400), TRAPS 71.
- Giới hạn/rủi ro còn lại: xem "Bàn giao".
- Nghiệm thu: phiên chính theo ủy quyền §3d, 2026-10-12.
