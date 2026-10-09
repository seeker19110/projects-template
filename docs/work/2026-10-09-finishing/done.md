# Công việc: Đưa mọi mục repo còn tự đánh dấu "phải làm" tới kết cục thật (2026-10-09)

- Work ID: 2026-10-09-finishing
- Yêu cầu / outcome: chủ repo 2026-10-09: "tiếp tục cho đến khi xong đi" (sau khi chu kỳ 2026-10-09 đã đóng) →
  "xong" = mọi mục mà CHÍNH REPO còn đánh dấu phải làm có kết cục thật, không chỉ điều kiện xem lại:
  (a) radar "Việc cần làm": 4 file mã > 400 dòng (`spec-compiler.py` 476, `telemetry-log.py` 426,
  `test-check-scripts.sh` 418, `tests/test_runtime_safety.py` 443) → radar 100/100, danh sách rỗng;
  (b) FEATURE-MAP ⚠️ FT-25 (trích F-014) và FT-50 (F-309) → ✅ hoặc đóng có căn cứ; (c) P-C12: tài liệu nội
  bộ lean-delivery-benchmark.md (trước ở docs/framework/) đang phát sang đích → dời sang `docs/reports/`.
- Trạng thái: Done (nghiệm thu 2026-10-09, xem cuối hồ sơ)
- Chủ trì / writer: phiên chính (Fable); 2 `standard-worker` trong worktree riêng cho R-01 và R-02
- Mức rủi ro / số PR: S (refactor không đổi hành vi + tài liệu + 1 sửa nhỏ có test đỏ-trước); 3 PR tuần tự
  trên `claude/relaxed-knuth-f1ejlq`: R-01 engine Python, R-02 suite test, R-03 tài liệu + FT-25/FT-50 + closeout
- Scope / non-goal: không đổi hành vi engine/cổng (golden: output trước–sau giống hệt, số ca test giữ nguyên);
  không mở P-B11 (parser khác ngữ nghĩa — lý do kỹ thuật giữ nguyên); không chạy hosted CI/pilot/benchmark/
  harness ngoài Claude Code (không có môi trường ở phiên này).
- Spec / goal / issue: mức S — không spec; kế hoạch ở hồ sơ này; closeout ghi vào `docs/ops/COMPLETION-PLAN.md`
  và `docs/reports/2026-10-09-finishing.md`
- Nhánh / base SHA / thời điểm reconcile: `claude/relaxed-knuth-f1ejlq` = `origin/main` `ac911e3` (2026-10-09, sau #226)

## Kế hoạch và phân công

Pha 0 (đo 2026-10-09 trên `ac911e3`): radar 99/100, kỷ luật kích thước 95.6 (4/91 file mã > 400 dòng), độ phủ cổng
40/40, sweep `--strict --no-deps` 🔴 0 🟡 0 (hai DEBT có `xem lại khi:`), docs-consistency 12/12.
Dữ kiện chi phối cách tách (đọc từ code, không suy đoán):
- Radar đếm MỌI `scripts/*.sh|*.py` (kể cả `_`) vào độ phủ cổng; module `_x.py` được coi là có cổng khi tên file
  hoặc `"stem"` xuất hiện trong thân một test Python mà `test-py-coverage.sh` gọi (`_scripts_covered_by_python_tests`).
- Test nạp engine bằng `spec_from_file_location` → engine phải tự thêm thư mục `scripts/` vào `sys.path` trước khi
  import helper; test đặt `engine.LOG_DIR` → helper telemetry phải THUẦN (nhận `st`, không đọc LOG_DIR).
- `copy-framework.manifest` [scripts] phát `telemetry-log.py`, `spec-compiler.py`, `tests/test_runtime_safety.py`
  → helper/fixture mới phải được kê (TRAPS mục 19; `check_manifest` kiểm).
- `test-*.sh` mới phải có trong `ci.yml` (CP-6 + `test_ci_suite_parity`), FEATURE-MAP (mục 11), CODEMAP (mục 6);
  test Python mới phải có ở `.claude/project-commands.sh` + `ci.yml` Linux/Windows + parity assert.
- FT-25 trích F-014 là trích SAI: F-014 = dọn nhánh đã merge (COMPLETION-PLAN W-308, repository-settings đã tick);
  `usage-guard.sh` đã được `test-hooks-session.sh` chạy với payload thật (O-2 P-A2, O-4b) → ⚠️ đã lỗi thời.
- FT-50/F-309: `_stack-detect.sh::node_has_script` fallback không jq dùng `grep -Eq "\"$1\"[[:space:]]*:"` trên CẢ
  package.json → dương tính giả khi tên task là khoá ở mục khác (vd `dependencies.test`). Sửa 1 dòng: jq → `node -e`
  đọc JSON thật (dự án có package.json mà không có node thì cũng không chạy được `npm run`) + test đỏ-trước.

Pha 1 (đơn vị):
- R-01 (worker A, worktree): `scripts/_spec_contract_gen.py` nhận `generate_python_contract_test` (dời nguyên văn);
  `scripts/_telemetry_report.py` nhận `fmt_cost` + render Markdown/HTML thuần; engine giữ wrapper cùng tên/chữ ký;
  test khẳng định engine tái xuất đúng hàm của helper (`assertIs`); manifest + CODEMAP; golden trước–sau.
- R-02 (worker B, worktree): `scripts/test-workflow-guards.sh` nhận mục 4–5 (+`step_body`) của `test-check-scripts.sh`;
  `tests/_runtime_fixture.py` (helper dùng chung) + `tests/test_git_safety.py` (lease/report publish + upgrade merge);
  wiring ci.yml/project-commands/parity/manifest/FEATURE-MAP/CODEMAP; gỡ 2 DEBT; số ca test giữ nguyên.
- R-03 (phiên chính): dời `lean-delivery-benchmark.md` → `docs/reports/2026-10-07-lean-delivery-benchmark.md` + mọi
  tham chiếu; FT-25 → ✅ (sửa trích dẫn + test cột); FT-50 → ✅ sau sửa F-309 với test đỏ-trước trong
  `test-dev-task.sh`; closeout COMPLETION-PLAN/report/PROGRESS/CHANGELOG; radar đo lại.
R-01 ∥ R-02 (file không chung ngoài CODEMAP/manifest — phiên chính hợp nhất khi áp patch) → PR tuần tự.

## Quyết định và bằng chứng

- Approved for implementation — phiên chính duyệt theo ủy quyền của chủ repo ngày 2026-10-07; ngày duyệt 2026-10-09;
  phạm vi R-01..R-03; căn cứ: radar/FEATURE-MAP/report O-6 là ba nơi repo còn tự đánh dấu việc; P-B11 giữ vì
  lý do kỹ thuật (không phải "chưa chạm điều kiện").
- TDD: R-01/R-02 là ngoại lệ 2 (di chuyển cơ học, không đổi hành vi) + test mới cho tái xuất; F-309 là `fix:` có
  test tái hiện đỏ trước.

## Lần thử / blocker

- R-01 (worker A, wt-r01): spec-compiler 476→362, telemetry-log 426→324; helper `_spec_contract_gen.py` 124, `_telemetry_report.py` 116.
  Golden giống từng byte (compile-all --json 102351 B; summary/widget telemetry qua `cmp`; chuỗi generator trên 23 spec);
  unittest 122→124 (+2 test tái xuất); py-coverage 96% (helper 100%); next-gen-engines/telemetry-and-dispatch/copy-framework/
  docs-consistency/python-complexity xanh; radar trong worktree 100/100 (còn 2 file của R-02). Phiên chính review diff, áp `git apply --index`. PR #227 MERGED (squash) → `cde2eaa`, 13 check xanh; cổng commit lần đầu đỏ đúng ở `test-hooks-session.sh` (fixture `cp` tay thiếu helper — TRAPS 19 tái phát, đã ghi); CodeQL báo `fmt_cost` import không dùng → bỏ tái xuất.
- R-02 (worker B, wt-r02): test-check-scripts 418→331 + `test-workflow-guards.sh` 111; test_runtime_safety 443→230 +
  `test_git_safety.py` 185 + `_runtime_fixture.py` 57; ca test giữ nguyên (Python 17=8+9; shell 39 ✅=32+7); ci.yml/
  project-commands/parity/manifest/FEATURE-MAP/CODEMAP đã nối; 2 DEBT gỡ; sweep --strict 0 🟡 DEBT. PR #228 MERGED (squash) → `949f09a`, 13 check xanh.
- R-03 (phiên chính, wt-r03): F-309 tái hiện đỏ-trước bằng PATH không jq (`npm run test` cho package.json chỉ có
  `dependencies.test`) → sửa `node_has_script` (jq → node) → xanh; benchmark dời `docs/reports/2026-10-07-lean-delivery-benchmark.md`;
  FT-25/FT-50 → ✅; docs-consistency, test_lean_adoption, --trace lean spec, copy-framework xanh. Áp vào PR closeout (PR này) cùng COMPLETION-PLAN/report/PROGRESS/CHANGELOG/AUDIT-STATUS/TRAPS 55.

## Bàn giao / bước tiếp theo

- Không còn việc mở. Radar 100/100 (0 file > 400 dòng, 43/43 script có cổng); cột Trạng thái FEATURE-MAP hết ⚠️/❌ (cột Test còn ❌ FT-13..20/FT-41 — cần harness/tài khoản thật); sweep 🔴 0 🟡 0;
  docs-consistency 12/12. P-B11 giữ không làm (lý do kỹ thuật). Việc cần môi trường ngoài (hosted CI đích, pilot, benchmark
  model, harness ngoài) ghi ở "Không làm / giới hạn" của báo cáo.

## Nghiệm thu cuối (chỉ điền khi đủ bằng chứng)

- R-01 PR #227 MERGED (squash) → `cde2eaa`; R-02 PR #228 MERGED (squash) → `949f09a`; cả hai 13 check xanh, không review thread.
- R-03 = PR closeout này (F-309 fix có test đỏ-trước; FT-25/FT-50 ✅; benchmark dời; closeout). DoD đạt khi PR này merge với CI xanh;
  PROGRESS đã trỏ SHA `949f09a` (sau #228).
