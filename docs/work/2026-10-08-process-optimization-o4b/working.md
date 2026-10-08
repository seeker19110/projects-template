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
- Hai worker xong (A: 14 file +94/−16; B: 14 file +76/−101), mỗi worker full gate PASS trong worktree riêng. Phiên chính
  review toàn bộ diff, apply bằng `git apply --index`, rồi tự làm phần giáp ranh: 6 suite còn lại sang `finish`
  (quyết exit 1 thống nhất — `exit "$fails"` ≥ 256 quay về 0), `maintenance-sweep.sh` dùng `declared_cmd` chung
  (kiểm tay: lệnh khai báo chạy, config hỏng → sweep vẫn rc 0 như trước), fixture `test-maintain-run/cron` thêm
  `_stack-detect.sh` (hết "No such file"), CODEMAP + `_test-lib.sh` comment, SC2034 `DECL` trong sweep.
- Chính sách fail-closed khi thiếu `_commit-guard.sh` (worker A đề xuất, phiên chính chốt theo §3d): chặn + nhắc copy;
  lý do + so sánh với `_lib.sh` ghi trong report.
- Số đo trước commit (so với 843581a): `scripts/` + hooks 26 file +174/−152 (test 14 file +76/−79; code 12 file
  +98/−73 — phần tăng là comment giải thích + nhánh fail-closed mới của 3 nơi source). Kiểm chứng trong repo chính:
  shellcheck -S warning rc 0; docs-consistency rc 0; test-maintenance-sweep, test-maintain-run, test-maintain-cron,
  test-hooks-session, test-check-scripts, test-adoption-smoke đều `OK —`, 0 dòng ❌; full gate chạy qua hook ở mỗi commit.

## Lần thử / blocker

- Hook pre-commit kích hoạt oan khi lệnh kiểm tay có chuỗi `git … commit` (TRAPS mục 53) và báo lint đỏ SC2034 `DECL` → sửa bằng directive có lý do; kiểm fixture chuyển sang file script riêng.

## Bàn giao / bước tiếp theo

Commit theo đơn vị (A: guard/hook · B+giáp ranh: test-lib/declared_cmd/telemetry/engine) → push → PR (template đủ mục, auto-merge SQUASH) → subscribe + check-in 5 phút → sau merge: PROGRESS SHA mới, đổi hồ sơ này thành done.md.

## Nghiệm thu cuối (chỉ điền khi đủ bằng chứng)

Chưa.
