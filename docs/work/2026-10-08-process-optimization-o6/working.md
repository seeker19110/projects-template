# Công việc: O-6 — một manifest cho hai script copy khung (P-B10); P-B11/P-C12 quyết không làm

- Work ID: 2026-10-08-process-optimization-o6
- Yêu cầu / outcome: hạng mục cuối của chu kỳ tối ưu quy trình 2026-10-08 (`docs/reports/2026-10-08-process-optimization.md`
  O-6), mở theo yêu cầu "tiếp các việc khác cho đến khi xong" của chủ repo. Outcome: `copy-framework.sh` và `.ps1` đọc
  cùng một danh sách file; cây đích không đổi.
- Trạng thái: Đang làm (chờ PR merge).
- Chủ trì / writer: phiên chính (một PR → tự làm, §2).
- Mức rủi ro / số PR: S refactor không đổi hành vi; một PR.
- Scope / non-goal: `copy-framework.sh`, `copy-framework.ps1`, `copy-framework.manifest` (mới), `scripts/test-copy-framework.sh`,
  CODEMAP, report, hồ sơ, PROGRESS. Non-goal: P-B11, P-C12 (quyết không làm — xem dưới), đổi tập file phát sang đích.
- Spec / goal / issue: kế hoạch + Approved §3d trong report (O-5/O-6 duyệt bổ sung 2026-10-08); hồ sơ trước:
  `docs/work/2026-10-08-process-optimization-o5/done.md` (#221).
- Nhánh / base SHA / thời điểm reconcile: claude/relaxed-knuth-f1ejlq (reset từ origin/main) / 7ab88e6 / 2026-10-09T00:00Z.

## Quyết định và bằng chứng

- **P-B10 làm:** `copy-framework.manifest` 4 mục `[docs]`/`[root]`/`[scripts]`/`[dropins]` (cột 2 = nguồn khác tên đích);
  `.sh` đọc bằng `manifest_section` (awk), `.ps1` bằng `Get-ManifestSection`. Thư mục copy thẳng, `settings.json`,
  `PROGRESS.md` từ mẫu, FRAMEWORK-VERSION giữ nguyên trong script (có thứ tự/điều kiện riêng). Hai script −114 dòng ròng
  (+43/−157 kể cả test), +107 dòng manifest (chủ yếu chú thích giữ nguyên từ hai script).
- Bằng chứng không đổi hành vi: chạy script cũ (HEAD main) và mới vào 4 đích trống → `diff -r` (trừ FRAMEWORK-VERSION có
  ngày/commit) rc 0 cho cả Bash lẫn PowerShell, 162 file mỗi cây. `test-copy-framework.sh` OK (+ `check_manifest`: 3+17+34
  file + 17 drop-in có ở nguồn và ở đích, cả hai runner), `test-adoption-smoke.sh` OK, `test_lean_adoption` OK,
  shellcheck 0, docs-consistency OK. Lần chạy đầu `check_structure` bắt thiếu `.claude/commands/gate.md` — đoạn cắt làm
  mất dòng `copy_into ".claude/commands"`; khôi phục ngay, test có sẵn bắt đúng (không phải lỗi mới của khuôn).
- **P-B11 không làm** (căn cứ §3.4 nấc 1 + §11 luật 2): (a) hai parser transcript (`telemetry-record.sh` delta theo mốc
  state; `usage-estimate.sh` cửa sổ 5 h, trọng số cache, ngân sách theo alias) khác ngữ nghĩa, phần chung ~25 dòng; gộp
  = thêm một module Python dùng chung vào hook + script + mọi danh sách copy/fixture (đúng khuôn TRAPS 19) để tiết kiệm ít
  hơn số dòng thêm vào. (b) CP-6 (`check-ci-policy.sh`) ⊂ `test_ci_suite_parity.py` về mặt logic nhưng cho thông báo lỗi
  trỏ đúng file; bỏ CP-6 tiết kiệm ~15 dòng, kéo theo sửa tài liệu ở ≥ 5 nơi và bản dropins vitest. (c) fixture adoption
  chạy copy-framework 4 lần nhưng gate cục bộ ~3 phút, chưa chạm điều kiện "gate > 15 phút" của report. **Xem lại khi:**
  xuất hiện parser transcript thứ ba, hoặc gate > 15 phút.
- **P-C12 không làm:** trong 3 file report nêu, chỉ `lean-delivery-benchmark.md` là nội bộ thuần (test đọc nó không được
  phát sang đích); `case-study-greenfield-dry-run.md` được `new-project-runbook-part-d-guardrails.md` (phát sang đích)
  tham chiếu 2 lần, `strict-gate-contract.md` là contract của `dev-task.sh gate` mà đích chạy. Một file nhiễu không đáng
  thêm nhánh loại trừ vào `copy_into` + `upgrade_file` ở hai script. **Xem lại khi:** có file nội bộ thứ hai trong
  `docs/framework/` (khi đó chuyển các file đó sang `docs/reports/`, không thêm nhánh loại trừ).

## Lần thử / blocker

- Không có blocker; một lần test đỏ do lỗi cắt dán, sửa trong cùng lượt (ghi ở trên).

## Bàn giao / bước tiếp theo

- Sau khi PR merge: đổi hồ sơ này thành `done.md`, cập nhật SHA ở PROGRESS (closeout nhỏ, như #220). Chu kỳ tối ưu quy
  trình 2026-10-08 đóng hoàn toàn (O-0..O-6).
