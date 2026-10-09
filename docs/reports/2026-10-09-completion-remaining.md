# Hoàn thiện phần còn lại của bộ khung — chu kỳ 2026-10-09

## Phạm vi và baseline

Yêu cầu (chủ repo, 2026-10-09): "hoàn thiện tiếp những phần còn lại". Phiên chính chọn `/completion`
trên chính repo khung vì đây là lựa chọn duy nhất đưa MỌI khoảng trống đã ghi (FEATURE-MAP mục "hạn chế",
PROGRESS "Tiếp theo", radar, sweep) tới một kết cục có bằng chứng: sửa được ở đây thì sửa, không thì
ghi rõ vì sao và điều kiện quay lại. Hồ sơ: `docs/work/2026-10-09-completion-remaining/done.md`.

Base `580fc91` (`origin/main` sau #223). Pha 0 đo tại base:

| Thước | Kết quả |
| --- | --- |
| `scripts/arch-health-radar.sh` | 100/100; 3 file mã > 400 dòng (`scripts/telemetry-log.py` 426, `scripts/spec-compiler.py` 476, `tests/test_runtime_safety.py` 443) |
| `scripts/maintenance-sweep.sh --strict --no-deps` | 🔴 0 · 🟡 0; 10 TODO đều là ví dụ tài liệu; 2 `DEBT:` đủ điều kiện xem lại |
| `scripts/check-docs-consistency.sh` | 11/11 OK |
| `docs/FEATURE-MAP.md` | ❌ còn ở FT-43 (mẫu ↔ hướng dẫn), FT-44 (vitest drop-in chưa chạy trên fixture); "chưa có test chạy hook" ở FT-23, FT-51 |

## Pha 1 — đối chiếu 12 nhóm (chỉ đọc + đo)

| Nhóm | Kiểm chứng ở chu kỳ này | Kết quả |
| --- | --- | --- |
| 1 Kiến trúc | Vai của `docs/ops/repository-settings.md` với hai cổng máy (shell repo khung, vitest đích) | F-R01: một khối phục vụ hai consumer có workflow khác nhau |
| 2 Bảo mật | Không đổi vùng nhạy cảm; sweep bí mật/file lớn/SHA ghim | Sạch |
| 3 Logic | Hook `session-guide`/`auto-format` đọc payload thật | F-R03: chưa có ca chạy hook |
| 4 Test | Vitest drop-in trên fixture khung và fixture đích (lần đầu) | F-R01 tái hiện; FT-23/43/51 thiếu test |
| 5 Hiệu năng | Không có UI/CWV; gate cục bộ ~3 phút (< 15, điều kiện P-B11 chưa chạm) | Không việc |
| 6 A11y/UI | Repo không có UI | N/A |
| 7 Dependency | Sweep `--no-deps`; dependency kiểm riêng bằng pip-audit/dependency-review trên PR | Không việc mới |
| 8 CI/vận hành | 9 workflow đều có `concurrency`; required checks `gate`+`metadata` | F-N07 cũ đã hết hiệu lực |
| 9 Tài liệu | Mẫu ↔ hướng dẫn; CODEMAP hàng 54 còn trỏ `CLAUDE.md` §11 (đã gộp vào §1 ở #221) | F-R02, F-R04 |
| 10 Dữ liệu | Không có DB/migration | N/A |
| 11 Cấu hình | `.claude/settings.json` nối đủ hook; tests `test_runtime_safety.py` | Không việc |
| 12 Thống nhất | Tài liệu phát sang đích ↔ workflow phát kèm | F-R01 |

### Phát hiện

| ID | Mức | Bằng chứng tái hiện | Việc |
| --- | --- | --- | --- |
| F-R01 | Trung | Fixture đích = `copy-framework.sh` ra thư mục sạch, chép `_framework-dropins/.github` và `scripts/ci-workflow-policy.test.ts` vào chỗ, vitest 3.2.4 / node 22.22.0: **2 ca đỏ** "Job đã khai nhưng không còn tồn tại trong ci.yml" (framework-lint, framework-lint-windows, docs-consistency, copy-framework-smoke, progress-freshness, protection-guard; hai bản test cùng nội dung, mỗi bản 1 ca). Trên cây khung: 25/25 xanh. Nguyên nhân: khối fenced đầu của `docs/ops/repository-settings.md` là bản kê job của RIÊNG repo khung nhưng file phát nguyên văn sang đích, còn `ci.yml` phát cho đích (`docs/framework/templates/ci-target.yml`) chỉ có `gate`. | W-01 |
| F-R02 | Thấp | `git grep -l -F <tên>` ngoài `templates/`, `work/`, `reports/`, `changelog/`: 0 kết quả cho `DATA-GOVERNANCE.template.md`, `GOVERNANCE.template.md`, `SUPPORT.template.md` (12 mẫu còn lại ≥ 1) | W-02 |
| F-R03 | Thấp | `grep` tên hook trong `scripts/test-*.sh`, `tests/*.py`: `session-guide.sh` chỉ có ca "thiếu jq" (mục 10), `auto-format.sh` không có ca nào chạy hook | W-02 |
| F-R04 | Thông tin | FEATURE-MAP FT-23/43/44/51 lệch sau W-01/W-02; `COMPREHENSIVE-AUDIT-STATUS.md` header còn "đang sửa"; CODEMAP hàng 54 trỏ §11 đã gỡ; radar liệt kê 3 file > 400 dòng | W-03 |

## Pha 2 — kế hoạch và Definition of Complete

Kế hoạch ở `docs/ops/COMPLETION-PLAN.md` (chu kỳ 2026-10-09). **Approved for implementation — phiên chính
duyệt theo ủy quyền của chủ repo ngày 2026-10-07; ngày duyệt thực tế 2026-10-09.** Ba PR S tuần tự; W-01 ∥ W-02
do worker `standard-worker` trong worktree riêng (không chung file), phiên chính review/áp/chạy gate.

Quyết định giữ nguyên (không mở lại, điều kiện xem lại chưa chạm):
- ADR-0003: bản kê hai chiều toàn bộ job của repo khung giữ nguyên; W-01 chỉ tách khối phát cho đích
  (required checks chung `gate`/`metadata`) khỏi khối bản kê của khung (đánh dấu bằng marker HTML comment).
- P-B11/P-C12 (báo cáo `docs/reports/2026-10-08-process-optimization.md`): chưa có parser thứ ba, gate < 15 phút,
  chưa có file nội bộ thứ hai.
- 3 file mã > 400 dòng: `tests/test_runtime_safety.py` có `DEBT:` kèm điều kiện; `telemetry-log.py`/`spec-compiler.py`
  là CLI một mục đích, tách module sẽ thêm file vào manifest/độ phủ/CODEMAP cho một tiêu chí phụ (15% × 3,3 điểm,
  điểm tổng vẫn 100). Xem lại khi một trong hai vượt 500 dòng hoặc nhận lệnh con mới.

Definition of Complete:
1. F-R01 sửa với test đỏ-trước/xanh-sau trong `scripts/test-copy-framework.sh` (cả bash lẫn pwsh) và vitest drop-in
   xanh trên fixture đích sau sửa.
2. F-R02/F-R03 có cổng/test ở lại CI (`check-docs-consistency.sh` mục 12 + negative test; `test-hooks-session.sh` mục 11–12).
3. Mọi PR: CI required xanh, squash merge, không bypass; full gate cục bộ xanh trước mỗi commit.
4. FEATURE-MAP/CODEMAP/TRAPS/PROGRESS/AUDIT-STATUS khớp main thật; mục không làm được ở đây ghi rõ điều kiện.

## Pha 3 — thực thi

| Việc | PR | Merge | Bằng chứng |
| --- | --- | --- | --- |
| W-01 | #224 | `f166369` | `test-copy-framework.sh` đỏ-trước 12 FAIL (6 job × bash/pwsh) → xanh; vitest drop-in trên fixture đích dựng lại: 38/38 (trước sửa 2 đỏ/36); cây khung 25/25; 13 check CI xanh |
| W-02 | #225 | `0e37c6e` | mục 12 đỏ-trước đúng 3 mẫu → xanh; negative test mẫu mồ côi; `test-hooks-session.sh` mục 11–12 (negative hook rỗng bị bắt); `test-check-scripts.sh` 39 ✅ |
| W-03 | PR closeout | — | tài liệu trạng thái khớp main; `DEBT:` cho `scripts/test-check-scripts.sh`; CODEMAP hàng adopt-from-outside trỏ `CLAUDE.md` §1 |

Mỗi commit qua full `scripts/dev-task.sh gate` bằng hook pre-commit (exit 0) trước khi push; worker làm trong worktree
riêng, phiên chính review diff, áp bằng `git apply --index` (hàng CODEMAP của W-02 đụng ngữ cảnh W-01 → sửa tay cùng nội dung).

## Pha 4 — quét lại (sau W-02, cây = main + W-03)

| Thước | Trước (base 580fc91) | Sau |
| --- | --- | --- |
| Radar | 100/100; 3 file mã > 400 dòng | 99/100; 4 file mã > 400 dòng — thêm `scripts/test-check-scripts.sh` (417) do hai ca mới; ghi `DEBT:` kèm điều kiện (gate script thứ tư hoặc > 500 dòng → tách) thay vì tách ngay (tách = thêm suite vào ci.yml/CODEMAP/FEATURE-MAP cho một tiêu chí phụ) |
| Sweep `--strict --no-deps` | 🔴 0 · 🟡 0 | 🔴 0 · 🟡 0 (3 `DEBT:`, đều có điều kiện) |
| docs-consistency | 11 mục | 12 mục, OK |
| FEATURE-MAP | ❌ FT-43/FT-44; "chưa có test chạy hook" FT-23/FT-51 | không còn ❌; FT-25 ⚠️ giữ (F-014 đã chấp nhận rủi ro) |
| Vitest drop-in trên fixture đích | 2 đỏ / 36 | 38 / 38 |

Phát hiện mới ở lượt quét lại: không (Cao/Trung/Thấp). Mọi F-R có kết cục; mục không làm được ở đây ghi ở "Giới hạn".

## Giới hạn được ghi nhận

- Hosted CI của một repo đích thật, pilot sản phẩm, benchmark model, phiên thật của harness ngoài Claude Code
  (Codex/Gemini/OpenCode/Cursor/Copilot) và cưỡng chế trần ngữ cảnh runtime: **không kiểm được ở phiên này**
  (không có repo/tài khoản/máy tương ứng). Điều kiện: chủ repo cấp một repo đích thật hoặc chạy harness tương ứng;
  khi đó dùng `docs/framework/lean-delivery-benchmark.md` làm protocol.
- Vitest drop-in chỉ chạy TAY trên fixture (cần `npm i -D vitest`, mạng); CI của repo khung không chạy vitest
  (không có `package.json`, ADR-0004). Cổng ở lại là bản shell trong `test-copy-framework.sh` (hai chiều khối ↔ job).
- Điểm radar 100 là kỷ luật đo được của chính repo, không phải chứng nhận kiến trúc/bảo mật.
