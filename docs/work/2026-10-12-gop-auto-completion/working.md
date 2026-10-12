# Công việc: Gộp /auto và /completion vào /auto-complete

- Work ID: 2026-10-12-gop-auto-completion
- Yêu cầu / outcome: chủ repo 2026-10-12 "bỏ /auto /complete, tích hợp hết vào /auto-complete" → một lệnh tự động duy nhất, tự chứa; 0 con trỏ cũ ngoài lịch sử.
- Trạng thái: Active
- Chủ trì / writer: phiên chính
- Mức rủi ro / số PR: M, 1 PR (đổi bề mặt lệnh — breaking cho người dùng; chỉ lệnh/tài liệu/marker hook + một mục cổng)
- Scope / non-goal: theo spec mục 5; không sửa ADR cũ, không tách `test-check-scripts.sh` (> 400 dòng có từ trước)
- Spec / goal / issue: `docs/specs/2026-10-12-gop-auto-completion.md` (Approved, phiên chính §3d)
- Nhánh / base SHA / thời điểm reconcile: `claude/sharp-goldberg-4owppu` @ `59bd1d1` · 2026-10-12T13:35:20Z

## Kế hoạch và phân công

Một PR, phiên chính tự làm (§3c: một PR). Thứ tự: mục 5c docs-consistency (đỏ trước) → viết lại `auto-complete.md`, xoá hai lệnh →
sửa con trỏ → test hợp đồng + ca âm → cổng tổng → PR.

## Quyết định và bằng chứng

- "/complete" hiểu là `/completion` (không có lệnh `/complete`) · bậc (1) đúng.
- Gộp nội dung vào `auto-complete.md` thành điểm vào A/B/C thay vì giữ file con · loại "giữ auto.md làm file nội bộ" (vẫn là lệnh slash) · bậc (2) ít hơn.
- Thêm "điểm vào B" (chỉ hoàn thiện, bỏ A) để không mất ca dùng của `/completion` trên dự án đã phát triển · bậc (1) đúng.
- Cổng docs-consistency mục 5c chặn `/auto`, `/completion` ngoài lịch sử · loại "chỉ sửa tay" (~50 dòng, dễ sót) · bậc (3) kiểm được.
  Đỏ trước: 50 lỗi ở 25 file; sau sửa: `check-docs-consistency.sh` rc=0.
- ADR-0011 trỏ `.claude/commands/auto.md` (ADR không sửa) → thêm vào `ALLOW_MISSING_PATH`; 5c vẫn chặn đường dẫn đó ở tài liệu đang dùng · bậc (2) ít hơn.
- Cổng tổng lần 1 (sau khi cài `pwsh` 7.4.6 + `requirements-ci.txt`): đỏ ở smoke `test-telemetry-and-dispatch.sh` trong đích
  copy (ca `model_hint`); `test-copy-framework.sh` chạy riêng trên `main` gốc và trên nhánh này đều rc=0 → chập chờn, không do PR.
  Lần 2: đỏ thật ở `test-next-gen-engines.sh` — spec cũ Approved (2026-09-12 traps, 2026-10-09 plan-check) hứa đường dẫn hai lệnh
  đã xoá (C-3), và bảng bằng chứng spec mới sai khuôn (C-4). Sửa: `contract-exempt` kèm lý do (tiền lệ ADR-0004) + khuôn
  `path::symbol`; `test-next-gen-engines.sh` rc=0. Trace rc=1 của spec 2026-09-12 có từ trước (spec trước mốc bản đồ AC).
- Ca âm 5c đặt trong `test-check-scripts.sh` (đã 410 dòng > 400 từ trước) · loại "tách suite ngay" (ngoài scope) · bậc (2).

## Lần thử / blocker

<Failure, số lần cùng failure, giả thuyết đã bác bỏ, blocker và cách kiểm tiếp.>

## Bàn giao / bước tiếp theo

Chạy cổng tổng (`bash scripts/dev-task.sh gate`), commit, push `claude/sharp-goldberg-4owppu`, mở PR (Work ID trên).

## Nghiệm thu cuối (chỉ điền khi đủ bằng chứng)

<DoD, mọi PR MERGED + merge SHA và main đã đối chiếu, giới hạn/rủi ro còn lại,
ngày và người nghiệm thu theo ủy quyền. Khi đủ điều kiện rename working.md → done.md
trong cùng thư mục; không overwrite lịch sử. Chưa có PR/merge thì giữ working.md.>
