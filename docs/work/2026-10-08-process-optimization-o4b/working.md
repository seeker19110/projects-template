# Công việc: O-4b — phần còn lại của tối ưu quy trình (một nguồn guard, helper test, declared_cmd)

- Work ID: 2026-10-08-process-optimization-o4b
- Yêu cầu / outcome: hoàn tất O-4b theo kế hoạch đã duyệt ở `docs/reports/2026-10-08-process-optimization.md` (P-A4, P-B2, P-B6, P-B8 một phần, P-B9 phần telemetry, `usage-guard` cảnh báo khi estimate lỗi). Không đổi hành vi hàng rào; bug/hành vi mới có test đỏ trước.
- Trạng thái: Active.
- Chủ trì / writer: phiên chính; hai worker trong worktree riêng (A: guard/hook · B: test-lib/declared_cmd/telemetry/engine).
- Mức rủi ro / số PR: S/M refactor; một PR (ràng buộc nhánh của phiên), nhiều commit theo đơn vị.
- Scope / non-goal: `scripts/`, `.claude/hooks`, copy-framework.sh/.ps1, test. Non-goal: O-5/O-6, đổi luật, dependency mới.
- Spec / goal / issue: kế hoạch + Approved §3d trong report; hồ sơ trước: `docs/work/2026-10-08-process-optimization/done.md` (#218).
- Nhánh / base SHA / thời điểm reconcile: claude/relaxed-knuth-f1ejlq (reset từ origin/main) / 843581a000402955a3f28eb04306bd838522b4de / 2026-10-08T16:17Z.

## Kế hoạch và phân công

- Worker A (complex): P-A4 scripts/_commit-guard.sh (file mới) một nguồn `secret_re` + kiểm >1 MB cho `pre-commit-gate.sh`, `scripts/githooks/pre-commit`, `maintenance-sweep.sh`; thêm vào hai copy script; test đồng bộ (không còn regex rời). `usage-guard.sh:15` cảnh báo khi `usage-estimate.sh` lỗi (đỏ trước).
- Worker B (standard): P-B2 `finish` trong `_test-lib.sh` (trừ hai suite hook thuộc A); P-B6 `declared_cmd` vào `_stack-detect.sh`, bỏ `eval` (trừ `maintenance-sweep.sh` thuộc A); P-B9 test telemetry/probe chạy trên bản tạm; P-B8 gọn `subagent-dispatch.py` payload, `spec-compiler._display_path`, `arch-health-radar` read helper.
- Phiên chính: review diff, apply tuần tự A rồi B, full gate qua hook, commit, push, PR.

## Quyết định và bằng chứng

- #218 merge SHA 843581a; main Release/Secret scan SUCCESS, CI 37807540551 đang chạy lúc mở hồ sơ.

## Lần thử / blocker

—

## Bàn giao / bước tiếp theo

Chờ hai worker; review + apply; gate; PR.

## Nghiệm thu cuối (chỉ điền khi đủ bằng chứng)

Chưa.
