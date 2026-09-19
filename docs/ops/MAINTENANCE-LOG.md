# Nhật ký bảo trì

> Mỗi dòng = một đợt `/maintain` đã đóng. Kế hoạch chi tiết của đợt: `docs/ops/MAINTENANCE-PLAN.md`
> (ghi đè mỗi đợt). Ảnh chụp quét thô `docs/ops/MAINTENANCE-REPORT.md` KHÔNG commit (`.gitignore`).

| Ngày | Phạm vi quét | Kết quả | Mục đã làm | PR | Bằng chứng |
| --- | --- | --- | --- | --- | --- |
| 2026-09-15 | `maintenance-sweep.sh` (mặc định, có deps) + kiểm chứng lại bằng `--strict` | 🔴 0 · 🟡 0 · ℹ️ 5 | không có mục M-xx | #143 | exit 0 cả hai lượt; git sạch, nhánh khớp `origin/main`; 7 workflow ghim full SHA; không `.env`/bí mật bị track; docs-consistency ✅, ci-policy ✅, arch-health-radar 100/100. `--strict` ra 🟡 1 = chính file `MAINTENANCE-PLAN.md` vừa sinh (bộ dò tự khớp sản phẩm của nó), không phải phát hiện thật. Không chạy `--gate` (repo khung không có bộ lệnh dev app thật). |
| 2026-09-19 | `maintenance-sweep.sh` (mặc định, có deps) + rà tay toàn repo (tham chiếu file chết ngoài `*.md`, file mồ côi, ADR/spec/goal treo) theo yêu cầu người dùng | 🔴 0 · 🟡 0 (máy) · 1 phát hiện tay | M-01: `ci.yml` job `metadata` kiểm sai tên file JSON đã đổi từ ADR-0007 | #151 | `jq empty .claude/settings-shared-default.json` chạy được trong CI (không còn bị guard `if [ -f ]` bỏ qua); docs-consistency ✅, ci-policy ✅, progress-freshness ✅. Rà thêm `opusplan` còn sót (12 file, 11/12 là văn xuôi lịch sử hợp lệ), file mồ côi trong `docs/framework/templates/`+`docs/adr/`+`docs/reports/` (0), ADR "Đã thay thế" còn dẫn như hiệu lực (0, chỉ khớp giả) — không có mục nào khác đủ điều kiện xoá (đều là hồ sơ lịch sử bắt buộc giữ theo `adopt-from-outside.md` §5 và quy ước ADR không sửa lại). |
