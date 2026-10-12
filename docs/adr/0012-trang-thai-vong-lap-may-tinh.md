# ADR-0012: Trạng thái vòng lặp `/auto-complete` do máy tính từ artifact, không do model tự suy

- **Trạng thái:** Đã chấp nhận
- **Ngày:** 2026-10-12

## Bối cảnh

Vòng lặp `/auto-complete` (ADR-0010 §4, #287, #289, #290) tới nay là **hook giữ lượt + văn xuôi**: `auto-complete-guard.sh` đọc một
dòng `- Trạng thái:` của `docs/work/<id>/working.md` và chép ≤ 12 dòng mục "Bàn giao" do model tự viết làm "bước kế tiếp". Kiểm kê
cổng đang chạy 2026-10-12 (`docs/reports/2026-10-12-thiet-ke-lai-vong-lap.md` §1) cho thấy: **0 script** tính bước kế tiếp từ
trạng thái thật (git, PR/CI, goal, kế hoạch hoàn thiện), **0 reader** cho `COMPLETION-PLAN.md`/Definition of Complete/
`release-readiness.md`, marker vòng do model `printf` (quên là hook vô hiệu), tiến triển đo bằng cksum *lời cuối* chứ không bằng
*artifact*. Mọi vòng lặp chạy bền ở nguồn ngoài (Anthropic harness 11/2025 + 3/2026, Beads/agent-teams, spec-kit, Codex Goals, plugin
ralph) đều có **một bước máy** tính trạng thái/độ sẵn sàng trước khi model hành động. Ràng buộc giữ nguyên: không runner không giám
sát (quyết 2026-10-10), §3d ủy quyền, CLAUDE.md §4 không tin lời khai, trần 5 subagent (ADR-0011), harness phiên này push một nhánh.

## Quyết định

Thêm engine **`scripts/loop-state.sh`** (Python stdlib, cùng khuôn `_python-exec.sh`) tính **một khối trạng thái vòng lặp máy đọc
được** từ artifact có sẵn — git (HEAD, ahead/behind `origin/main`, file dở), PR/CI của nhánh (`gh`, không có thì `unknown`), hồ sơ
§3e (Work ID, Trạng thái, mục Bàn giao, dấu "tầng"), goal (slice **ready** = mọi phụ thuộc DONE), `COMPLETION-PLAN.md` (đếm ô),
`release-readiness.md` (GO/NO-GO), streak đỏ, marker — và xuất **verdict có kiểu** `continue · refine-spec · refine-code · waiting ·
request-input · stop` kèm `next`. Ba điểm tiêu thụ: (1) `/auto-complete` nạp output bằng cú pháp `!` (chạy trước khi prompt tới
model) và `--enter` tự ghi marker; (2) `auto-complete-guard.sh` đo tiến triển bằng **vân tay artifact** (HEAD + hash `working.md`
+ tập PR mở + file dở) — 2 lượt không đổi → cho dừng — và nhắc theo verdict; (3) `session-resume.sh` in một dòng trạng thái. Engine
**chỉ đo và đếm**, không đánh giá nội dung, không chạy cổng (cổng vẫn ở commit/CI), không quyết thay §3d.

## Lý do

Thang §3d: bậc 1 — không hạ cổng nào, không side effect ngoài marker gitignored; bậc 2 — ít hơn mọi phương án khác đạt bậc 1
(0 dependency, 0 file trạng thái mới, 0 runner, 0 định dạng backlog mới; dùng đúng artifact §3e/goal/plan đã bắt buộc); bậc 3 —
biến bốn luật văn xuôi (§4 dòng 1–2 reconcile, §3b quy lỗi về tầng, Pha 0–4 tiêu chí thoát, GO/NO-GO) thành số máy đếm có test
đỏ-trước. Tín hiệu dừng vẫn đọc từ **file trạng thái** (ADR-0010/#287), không từ chuỗi model in.

## Các phương án đã cân nhắc

- **A. Giữ nguyên + vá 5 lỗi lộ ra khi kiểm kê** (Planned không trong danh sách dừng, regex goal thiếu DONE, `n` không reset, WIP
  "3" lệch "5", telemetry thiếu work-id): ít nhất nhưng **hụt bậc 3** — bước kế tiếp và reconcile vẫn là lời khai của model; vá
  vẫn làm, gộp vào phương án B.
- **B. Engine trạng thái + verdict có kiểu, tiêu thụ ở lệnh/hook (chọn).**
- **C. Backlog JSON `passes` + runner ngoài `while true; claude -p`** (Anthropic 11/2025, ralph): **loại ở bậc 1** (mâu thuẫn
  threat model không runner sửa source không người duyệt, 2026-10-10) và bậc 2 (nguồn sự thật thứ hai cạnh goal/spec → lệch sổ).
- **D. `/goal` của Claude Code làm lớp chính:** evaluator Haiku "không chạy lệnh, không đọc file" — đúng loại tín hiệu CLAUDE.md §4
  cấm; chỉ chạy ở Claude Code. Giữ làm **tuỳ chọn** thêm lớp.
- **E. Stop hook chạy `dev-task.sh gate` mỗi lượt** (pattern "deterministic Stop gate"): mỗi lượt tốn phút, trùng cổng commit, cap 8
  lượt của Claude Code — loại ở bậc 2; engine đọc `.claude/.gate-red-streak` thay vì chạy lại.

## Hệ quả

- Harness không hỗ trợ `!` trong file lệnh (Codex/Cursor/Hermes) → lệnh ghi rõ bước tay "chạy `scripts/loop-state.sh --enter`
  trước"; hook Stop chỉ có ở Claude Code (đã là giới hạn từ #287).
- Thiếu `gh` hoặc offline → `pr.available=false`, verdict không dựa vào PR (suy giảm có nói ra, không xanh giả).
- Engine đọc `docs/goals`, `COMPLETION-PLAN.md`, `release-readiness.md` theo **khuôn mẫu đang có** (bảng slice, ⬜/🔄/✅/➖, `- [ ]`);
  đổi khuôn mẫu phải đổi parser + test — khuôn mẫu nay là contract máy đọc.
- `standard-delivery.md:109` sửa "ba PR mở" → 5 cho khớp `pr-policy.yml`; ADR-0011 dòng 19 ghi "ba" là lỗi chép, **không sửa ADR cũ**
  — ghi nhận tại đây.
- Dự án đích nhận `loop-state.*` qua `copy-framework.manifest`; cổng 13b/15/16 cho đích vẫn ngoài scope (điều kiện xem lại ở báo cáo).
