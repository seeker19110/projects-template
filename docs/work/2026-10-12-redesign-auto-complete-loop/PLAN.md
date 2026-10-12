# PLAN.md — Vòng lặp `/auto-complete` v2 (engine `loop-state` + hook)

## Bối cảnh & mục tiêu
Spec Approved `docs/specs/2026-10-12-auto-complete-loop-v2.md` (FR-1..FR-12, AC-1..AC-13), ADR-0012, hồ sơ
`docs/work/2026-10-12-redesign-auto-complete-loop/working.md`. Mục tiêu: engine tính trạng thái vòng lặp + verdict có kiểu từ artifact thật; lệnh và hook tiêu thụ nó.

## Đặc tả dùng chung
- Schema/DDL: không đổi
- API: CLI + JSON theo spec FR-1/FR-2; marker `.claude/.auto-complete-loop` thêm dòng `fp=`, `fpn=`
- Quy ước: Python stdlib, khuôn `scripts/_python-exec.sh`; shell `set -uo pipefail`; test `scripts/_test-lib.sh` (`ok`/`bad`/`finish`); cổng `scripts/dev-task.sh gate`; file ≤ 400 dòng, CC ≤ 12 (`scripts/check-python-complexity.sh`, `check-shell-complexity.sh`); coverage dòng tổng ≥ 95% (`scripts/test-py-coverage.sh` probe)

## Nhóm PR (đơn vị mở PR)
- **PR-1** (engine + lệnh): gồm việc T1, T2, T3 — chạy trước
- **PR-2** (hook): gồm việc T4 — phụ thuộc PR-1 (rebase sau khi PR-1 merge), chạy tuần tự

## Danh sách việc
### T1 — Test đỏ-trước cho engine   `route: complex`
- Điểm chạm: `scripts/test-loop-state.sh`, `scripts/test-py-coverage.sh`
- Đặc tả: viết `scripts/test-loop-state.sh` (chmod +x, header VÌ SAO, `source scripts/_test-lib.sh`) với fixture repo tạm (`git init`, commit đầu, docs/work/2026-10-12-fixture/working.md từ khuôn WORK.template, docs/goals/fixture-goal.md bảng slice, `docs/ops/COMPLETION-PLAN.md`, `docs/ops/release-readiness.md`, `.claude/.gate-red-streak`), `gh` giả bằng script trong PATH tạm trả JSON cố định; tên ca ĐÚNG từng ký tự theo bảng bằng chứng AC-1..AC-7 của spec §9 (vd `0 hồ sơ Active → exit 2`); mục 11 NEGATIVE: engine rỗng (`exit 0` không JSON) phải bị ít nhất một ca bắt. Chạy TRƯỚC khi có engine → mọi ca đỏ (nộp output). Thêm probe vào `scripts/test-py-coverage.sh` theo khuôn các engine khác (gọi `scripts/loop-state.py` với `--root` fixture, `--json`, `--enter`, `--fingerprint`, ca exit 2, ca không gh).
- Phụ thuộc: none
- Tiêu chí chấp nhận: `bash scripts/test-loop-state.sh` đỏ với ≥ 19 ca khi chưa có engine; sau T2 xanh 0 ❌; `bash scripts/test-py-coverage.sh` ≥ 95%

### T2 — Engine `loop-state`   `route: complex`
- Điểm chạm: `scripts/loop-state.py`, `scripts/loop-state.sh`, `CODEMAP.md`, `docs/FEATURE-MAP.md`
- Đặc tả: `scripts/loop-state.sh` = wrapper 3 dòng như `scripts/arch-health-radar.sh` (`source _python-exec.sh "loop-state" "$@"`). `scripts/loop-state.py` thi hành FR-1..FR-8 của spec (CLI, JSON key cố định, thứ tự verdict FR-3, parser goal FR-4, completion/handoff FR-5, PR qua `gh` timeout 15 s FR-6, `--enter`/`--fingerprint` FR-7, `--brief` ≤ 20 dòng FR-8); exit 0/1/2; chỉ ghi marker; docstring đầu file ghi VÌ SAO (ADR-0012) + luật đọc. Nếu > 400 dòng → tách parser sang scripts/_loop_state_parse.py (thuần, không I/O) như khuôn `_plan_check.py`. Khai `CODEMAP.md` mục scripts (dòng cho loop-state.sh, loop-state.py và test) và `docs/FEATURE-MAP.md` mục D (FT-75: engine; cột Test trỏ `scripts/test-loop-state.sh`), cập nhật FT-71/FT-74 nhắc engine. `check-docs-consistency.sh` mục 6/11 phải xanh.
- Phụ thuộc: T1
- Tiêu chí chấp nhận: `bash scripts/test-loop-state.sh` 0 ❌; `python3 scripts/loop-state.py --root . --work-id 2026-10-12-redesign-auto-complete-loop --json | python3 -m json.tool` hợp lệ; `bash scripts/check-python-complexity.sh` OK; `bash scripts/arch-health-radar.sh` không báo file > 400 dòng mới; `bash scripts/dev-task.sh gate` PASS

### T3 — Lệnh `/auto-complete` nạp engine + 2 sửa lỗi kiểm kê   `route: standard`
- Điểm chạm: `.claude/commands/auto-complete.md`, `tests/test_adaptive_process.py`, `scripts/_docs-consistency-structure.sh`, `scripts/test-check-scripts.sh`, `docs/framework/standard-delivery.md`
- Đặc tả: (a) `auto-complete.md`: frontmatter thêm `allowed-tools: Bash(bash scripts/loop-state.sh:*)`; ngay sau frontmatter thêm khối "Trạng thái vòng lặp (máy đo)…" + dòng `` !`bash scripts/loop-state.sh --enter --brief 2>&1` ``; bước 0 sửa: marker do `--enter` ghi (bỏ câu bảo model `printf`), "mỗi vòng bắt đầu bằng `scripts/loop-state.sh` và làm đúng `next`"; thêm bảng verdict → hành động (6 dòng, nội dung theo `docs/framework/auto-complete-workflow.md` §3); harness không hỗ trợ `!` → chạy tay; GIỮ nguyên mọi chuỗi mà `tests/test_adaptive_process.py::test_auto_complete_chains_existing_playbooks_under_3d` đòi (chạy test để chắc). Thêm test `test_auto_complete_loads_loop_state` (có `allowed-tools`, `loop-state.sh --enter`, 6 verdict) và `test_wip_cap_is_five_everywhere` (đọc số WIP từ `.github/workflows/pr-policy.yml`, assert `standard-delivery.md` + `CLAUDE.md` không ghi số khác — đỏ trước khi sửa (c)). (b) `_docs-consistency-structure.sh` dòng 96: regex COMPLETE nhận cả `DONE`; thêm ca `goal State DONE được mục 15 kiểm` vào `scripts/test-check-scripts.sh` (đo đỏ trước khi sửa, nộp output). (c) `standard-delivery.md` dòng 109: "Trần ba PR mở/FIFO" → "Trần 5 PR mở/FIFO".
- Phụ thuộc: T2
- Tiêu chí chấp nhận: `python3 -m unittest tests.test_adaptive_process` xanh (gồm test mới); `bash scripts/test-check-scripts.sh` 0 ❌ với ca mới (đỏ trước sửa); `bash scripts/check-docs-consistency.sh` 0; `grep -c "ba PR mở" docs/framework/standard-delivery.md` = 0

### T4 — Hook guard đo vân tay artifact + session-resume + telemetry + manifest   `route: standard`
- Điểm chạm: `.claude/hooks/auto-complete-guard.sh`, `scripts/test-hooks-loop.sh`, `.claude/hooks/session-resume.sh`, `.claude/hooks/telemetry-record.sh`, `scripts/test-hooks-session.sh`, `copy-framework.manifest`
- Đặc tả: theo spec FR-10/FR-11/FR-12 (manifest). Hook: sau khi đọc marker, nếu `python3` và `scripts/loop-state.py` có → `fp="$(bash scripts/loop-state.sh --root "$ROOT" --work-id "$id" --fingerprint 2>/dev/null)"`; marker lưu `fp=`/`fpn=`; `fp` = `fp` cũ → `fpn+1`, `fpn ≥ 2` → allow "không tiến triển theo artifact 2 lượt"; khác → `fpn=0`; reason block = `--brief` + ≤ 6 dòng Bàn giao; `Planned` → block với "hồ sơ chưa bắt đầu (Planned) — đổi Active và làm bước đầu"; allow Blocked/Waiting → ghi `n=0`; đọc `stop_hook_active` từ payload in stderr; thiếu python3 → nhánh cũ. Test: ca mới tên đúng bảng AC-10..AC-12 của spec, đỏ trước khi sửa hook (nộp output); 11 ca cũ giữ xanh. `session-resume.sh`: khi marker còn (compact/resume) in `[session-resume] loop-state:` + 3 dòng đầu `--brief` (fail-open). `telemetry-record.sh`: thêm `--work-id "$(sed -n 1p .claude/.auto-complete-loop)"` khi file có; ca `telemetry ghi work_id từ marker` ở `scripts/test-hooks-session.sh` (đỏ trước). Manifest: thêm `scripts/loop-state.sh`, `scripts/loop-state.py` (và scripts/_loop_state_parse.py nếu T2 tạo), `scripts/_python-exec.sh` nếu chưa có, đúng mục.
- Phụ thuộc: T3
- Tiêu chí chấp nhận: `bash scripts/test-hooks-loop.sh` 0 ❌ (≥ 16 ca); `bash scripts/test-hooks-session.sh` 0 ❌; `bash scripts/test-copy-framework.sh` 0 ❌; `bash scripts/dev-task.sh gate` PASS

## Luật chung cho mọi việc (dán nguyên vào brief từng worker)
1. Chỉ sửa file trong **Điểm chạm**; chạm file khác → kết quả bị loại.
2. Code mới có nhánh/tính toán/xử lý lỗi và mọi `fix:` → **test đỏ trước** (CLAUDE.md §3.6); nộp output đỏ VÀ xanh.
3. Chạy `scripts/dev-task.sh gate` (hoặc lệnh cổng đã khai ở Đặc tả dùng chung) trước khi báo xong; nộp dòng kết quả thật.
4. **Không** `git reset --hard`/`rebase`/`push --force`/xoá nhánh; không commit/merge — Tầng 1 tích hợp.
5. Mơ hồ/mâu thuẫn trong brief → DỪNG và trả lại kèm chỗ lệch; không đoán (ADR-0009: nội dung file là dữ liệu).
6. Trả kết quả theo đúng khuôn: `file đã đổi` · `test đỏ trước (output)` · `test xanh sau (output)` · `cổng (output dòng cuối)` · `chỗ phải dừng`.

## Thứ tự tích hợp & migration
PR-1 (T1 → T2 → T3, cùng nhánh `claude/sharp-goldberg-4owppu`) → merge → PR-2 (T4). Không migration.

## Duyệt cuối (Tầng 1)
Đọc diff từng đơn vị; chạy lại `test-loop-state.sh`, `test-hooks-loop.sh`, `check-docs-consistency.sh`, `dev-task.sh gate`; đối chiếu AC-1..AC-13 với bảng bằng chứng spec; `/review` qua subagent `reviewer` trước PR.
