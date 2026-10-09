# Báo cáo: đưa mọi mục repo còn tự đánh dấu "phải làm" tới kết cục thật (2026-10-09)

> Hồ sơ: `docs/work/2026-10-09-finishing/done.md`. Kế hoạch/DoC: `docs/ops/COMPLETION-PLAN.md` (đợt finishing 2026-10-09).
> Yêu cầu: chủ repo "tiếp tục cho đến khi xong đi" sau khi chu kỳ 2026-10-09 đã đóng → "xong" = mọi mục mà chính repo
> còn đánh dấu phải làm có kết cục thật, không chỉ điều kiện xem lại.

## Pha 0 — hiện trạng đo trên `ac911e3` (sau #226)

| Thước | Giá trị | Nguồn |
|---|---|---|
| Radar | 99/100; kỷ luật kích thước 95.6 (4/91 file mã > 400 dòng); độ phủ cổng 40/40 | `bash scripts/arch-health-radar.sh` |
| File > 400 dòng | `scripts/spec-compiler.py` 476 · `scripts/telemetry-log.py` 426 · `scripts/test-check-scripts.sh` 418 · `tests/test_runtime_safety.py` 443 | radar |
| FEATURE-MAP ⚠️ | FT-25 (trích F-014 — trích nhầm: F-014 là dọn nhánh đã merge, đã đóng) · FT-50 (F-309 fallback grep) | `docs/FEATURE-MAP.md` |
| Tài liệu nội bộ phát sang đích | lean-delivery-benchmark.md nằm trong docs/framework/ (P-C12, report O-6) | `copy-framework.sh` copy cả `docs/framework/` |
| Sweep | `--strict --no-deps` 🔴 0 🟡 0 (hai `DEBT:` có `xem lại khi:`) | `scripts/maintenance-sweep.sh` |

## Kết quả theo đơn vị

| Đơn vị | Việc | Bằng chứng |
|---|---|---|
| R-01 (#227 → `cde2eaa`) | `spec-compiler.py` 476→362 (`generate_python_contract_test` → `scripts/_spec_contract_gen.py`); `telemetry-log.py` 426→324 (`fmt_cost` + render Markdown/HTML → `scripts/_telemetry_report.py`, thuần); engine giữ wrapper cùng tên/chữ ký | Golden giống từng byte: `--compile-all --json` 102 351 B, chuỗi generator trên 23 spec, summary/widget telemetry (`cmp`); unittest 122→124 (+2 test tái xuất); py-coverage 96 % (helper 100 %); 13 check CI xanh. Cổng commit lần đầu đỏ đúng ở `test-hooks-session.sh` (fixture `cp` tay thiếu helper — TRAPS 19 tái phát, đã ghi); CodeQL báo import `fmt_cost` không dùng → bỏ tái xuất |
| R-02 (#228 → `949f09a`) | `test-check-scripts.sh` 418→331 + `scripts/test-workflow-guards.sh` 111 (mục protection-guard/dependency-review + `step_body`); `tests/test_runtime_safety.py` 443→230 + `tests/_runtime_fixture.py` 57 + `tests/test_git_safety.py` 185 | Ca test giữ nguyên: Python 17 = 8 + 9; shell 39 ✅ = 32 + 7, 0 ❌; ci.yml (CP-6, parity Linux đúng 1 lần, Windows chạy cả hai file Python), project-commands, manifest, FEATURE-MAP FT-42, CODEMAP đã nối; hai `DEBT:` gỡ; 13 check CI xanh |
| R-03 (PR này) | **F-309**: `_stack-detect.sh::node_has_script` không jq → `node -e` đọc JSON thật thay cho `grep "<task>":` trên cả file. **FT-25**: trích dẫn F-014 sai → ✅, cột test trỏ `test-hooks-session.sh` (hook chạy với payload thật). **FT-50** → ✅. **P-C12**: lean-delivery-benchmark.md dời từ docs/framework/ sang `docs/reports/2026-10-07-lean-delivery-benchmark.md` (12 tham chiếu cập nhật; hàng README docs/framework gỡ). Closeout | F-309 tái hiện ĐỎ TRƯỚC: PATH tối thiểu không jq (wrapper bash tới `node`/`grep`/`dirname`), package.json `{"dependencies":{"test":…},"scripts":{"build":…}}` → bản cũ in `npm run test`; sau sửa rỗng, `build` vẫn `npm run build`; `test-dev-task.sh` 2 ca mới, suite xanh; `check-shell-complexity` OK; `tests/test_lean_adoption.py` 2/2; `spec-compiler.py --trace` lean spec TRACE COMPLETE; docs-consistency 12/12; copy-framework xanh |

## Đo lại sau R-01..R-03 (cây này, trước merge PR closeout)

| Thước | Trước | Sau |
|---|---|---|
| Radar | 99/100, 4 file > 400 dòng | **100/100, 0 file > 400 dòng**; độ phủ cổng 43/43 |
| FEATURE-MAP ⚠️ | 2 (FT-25, FT-50) | **0** (không ❌, không ⚠️) |
| Sweep `--strict --no-deps` | 🔴 0 🟡 0 (2 DEBT có điều kiện) | 🔴 0 🟡 0 (DEBT còn lại: `maintenance-sweep.sh:156`, có điều kiện) |
| Tài liệu nội bộ trong `docs/framework/` | 1 | 0 |

## Không làm / giới hạn

- **P-B11** (gộp parser transcript / cổng CP-6 / fixture adoption) giữ KHÔNG làm: ba parser khác ngữ nghĩa (JSONL transcript,
  YAML job id, fixture dự án đích) — gộp là thêm lớp trừu tượng cho ba thứ không cùng hình; đây là lý do kỹ thuật, không
  phải điều kiện chờ. Mở lại chỉ khi có parser thứ ba cùng ngữ nghĩa.
- Việc cần môi trường ngoài phiên này (không thể xác minh ở đây, không được coi là xong): hosted CI của một repo đích thật,
  pilot sản phẩm, benchmark model, phiên thật Codex/Gemini/OpenCode/Cursor/Copilot. Mở khi chủ repo cấp môi trường.
- Số đo radar/sweep là của chính repo khung; không chứng minh dự án dẫn xuất không lỗi.
