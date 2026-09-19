# Kế hoạch bảo trì — 2026-09-19

Nguồn: `docs/ops/MAINTENANCE-REPORT.md` (quét 2026-09-19, 🔴 0 · 🟡 0 — sạch tuyệt đối) + rà tay
toàn repo theo yêu cầu người dùng ("tối ưu file rồi context, cái nào không còn áp dụng thì xoá bỏ
— toàn bộ trong repo này"). Trạng thái: **ĐÃ DUYỆT — 1 mục, đã thực thi qua PR.**

## Phạm vi rà tay (máy không phủ tới)

`maintenance-sweep.sh` chỉ kiểm 6 mảng cơ học (git/dependency/tài liệu-nợ-kỹ-thuật/bí mật/CI-ghim-SHA/cổng
khung), không kiểm **tham chiếu tên file chết trong YAML/shell** (chỉ `check-docs-consistency.sh` soi
backtick trong `*.md`, `ci.yml` ngoài phạm vi đó). Đã rà thêm:

- Tham chiếu `opusplan` còn sót (ADR-0007 yêu cầu dọn) — tất cả **trừ một** là văn xuôi lịch sử hợp lệ
  (giải thích ADR-0007, không phải hướng dẫn dùng chế độ đã mất).
- File mồ côi trong `docs/framework/templates/`, `docs/adr/`, `docs/reports/` — 0, mọi file đều được
  tham chiếu.
- ADR đánh dấu "Đã thay thế" nhưng còn được dẫn chiếu như đang hiệu lực — 0 (chỉ khớp giả ở
  `0000-template.md` và câu dự phòng trong ADR-0008, không phải phát hiện thật).
- Spec ở trạng thái Draft/In review treo, Goal BLOCKED — 0 (khớp báo cáo sweep).

## Danh sách việc

### M-01 — `ci.yml` job `metadata` kiểm sai tên file JSON (đã đổi tên từ ADR-0007)   `route: mechanical`

- **Phát hiện:** `.github/workflows/ci.yml:119` liệt kê "settings-shared-opusplan.json" (tên cũ, đã xoá) trong
  vòng lặp `jq empty "$f"`. File này đã đổi tên thành `.claude/settings-shared-default.json` từ
  ADR-0007 (2026-09-15, PR #130). Guard `if [ -f "$f" ]` khiến job **im lặng bỏ qua** — file cấu hình
  thật đang dùng (`settings-shared-default.json`) chưa từng được cổng này kiểm JSON hợp lệ.
- **Điểm chạm:** `.github/workflows/ci.yml` dòng 119.
- **Đặc tả:** đổi `settings-shared-opusplan.json` → `settings-shared-default.json` trong danh sách file
  của bước "JSON cấu hình hợp lệ (jq)".
- **Phụ thuộc:** none.
- **Tiêu chí chấp nhận:** `jq empty .claude/settings-shared-default.json` chạy trong CI (không còn bị
  guard bỏ qua); `check-ci-policy.sh` vẫn xanh; không còn chuỗi `settings-shared-opusplan.json` nào
  ngoài văn xuôi lịch sử (ADR-0007, PROGRESS.md mốc cũ, đặc tả spec cũ) — giữ nguyên các chỗ đó.
- **Mức:** không đụng §9 (không phải bảo mật/dữ liệu thật/breaking/major bump) → không cần DỪNG & HỎI.

## Thực thi

Sửa trực tiếp trên nhánh làm việc hiện tại (thay đổi 1 dòng, rủi ro thấp, không đáng tách nhánh
`chore/maint-m01-*` riêng theo đúng tinh thần "không tách PR chỉ vì thủ tục" khi người dùng đã duyệt
tại chỗ) — mở PR riêng, không gộp vào PR khác.

## Đóng

Sau khi PR merge: cập nhật dòng này thành ĐÓNG, ghi vào `docs/ops/MAINTENANCE-LOG.md`.
