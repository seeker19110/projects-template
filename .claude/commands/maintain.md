---
description: Bảo trì toàn diện theo chu kỳ — quét (git/dependency/tài liệu/bí mật/CI/cổng) → triage → kế hoạch chờ duyệt → thực thi từng PR nhỏ qua /gate → quét lại hội tụ
---

Bạn đang chạy **`/maintain`** — vòng bảo trì cho **chính repo khung** và **mọi dự án đích** (engine tự dò stack). Quét/triage/kế hoạch/mẫu `MAINTENANCE-PLAN.md`/chạy ngoài Claude Code và cron: nguồn sự thật là `.claude/agents/maintainer.md` (subagent `maintainer`) — lệnh này chỉ gọi nó và thêm phần dưới.

Tham số: `/maintain` (mặc định, có kiểm dependency) · `/maintain quick` (thêm `--no-deps`) · `/maintain full` (thêm `--gate`: build/type/lint/test) · `/maintain continue` (tiếp kế hoạch đã duyệt).

> 💡 Model/effort: theo `docs/framework/models-and-automation.md` §3–§4 và ADR-0010 §4.

Bám `CLAUDE.md` §2 chia nhỏ + §5–§8 cổng/PR + §9 dừng-và-hỏi.

- **Khác lệnh gần nghĩa:** `/audit-full` rà chất lượng nội tại một lần; `/completion` đi đến "không còn lỗi đã biết"; `/audit-optimize` tối ưu mã. `/maintain` là **vệ sinh định kỳ** cho thứ mục nát theo thời gian dù code không đổi (dependency, nhánh chết, `PROGRESS.md`/spec/goal treo, action CI chưa ghim, bí mật lọt git, cổng khung đỏ); chạy được trên repo khung trống lẫn dự án thật.
- **PHA 0 — tiền kiểm:** phải ở `main` sạch và đã `git fetch origin main` (không thì đưa về `main` trước — TRAPS.md mục 14). Đọc `PROGRESS.md` "Giai đoạn hiện tại" + `TRAPS.md`. Có `docs/ops/MAINTENANCE-PLAN.md` ĐÃ DUYỆT còn mục TODO → coi như `continue`: nhảy PHA 3.
- **PHA 1–2:** giao `maintainer` quét (`quick`/`full` ánh xạ thành cờ ở trên) và viết kế hoạch. Thiếu `scripts/maintenance-sweep.sh` → báo người dùng chạy lại `copy-framework.sh`; không bịa kết quả quét. Kế hoạch xong thì **DỪNG CHỜ DUYỆT** qua `AskUserQuestion` (duyệt toàn bộ / một phần / sửa; theo ủy quyền contract §3d) — chưa duyệt thì không sửa source. Mục đụng §9 ghi **DỪNG & HỎI**.
- **PHA 3 — thực thi từng mục đã duyệt:** mỗi mục một nhánh `chore/maint-<id>-<slug>` (bug → `fix/…`, có test tái hiện đỏ trước, §3.6); giao worker theo `route:` (trần effort medium); chạy **cổng kiểm của mục** + `/gate`; PR riêng (mô tả đủ template, dòng "Nguồn: MAINTENANCE-PLAN M-xx"); cập nhật tài liệu trong cùng PR; bật auto-merge khi mô tả đủ; **FIFO** (§8). Lockfile/migration → tuần tự. Ghi mỗi mục xong vào `docs/ops/MAINTENANCE-LOG.md` và đổi trạng thái trong kế hoạch.
- **PHA 4 — hội tụ:** về `main`, chạy lại `maintenance-sweep.sh --strict`; còn 🔴 → lặp PHA 2–3 (cùng một mục thất bại tối đa 3 lần rồi BLOCKED và hỏi — Goal loop). 🔴 = 0 và mọi mục xong → cập nhật `PROGRESS.md` (mốc "bảo trì <ngày>", nợ còn lại), đóng kế hoạch, xuất Báo cáo xác thực §7 cho PR cuối.
- **Định kỳ & kênh giao tiếp:** `.github/workflows/maintenance.yml` (thứ Hai) đăng **một** issue tổng hợp — tín hiệu để gõ `/maintain` (dependency ở CI do `dependabot.yml` + `dependency-review.yml` lo; dự án đích chưa có → copy từ `_framework-dropins/`). Giao tiếp luôn là văn bản ở repo: chat khi gõ lệnh; `MAINTENANCE-REPORT.md` (không commit) · `MAINTENANCE-PLAN.md` (commit, "hộp thư" hai chiều: sửa trực tiếp rồi gõ `/maintain continue`) · `MAINTENANCE-LOG.md` (commit); khi không ai online thì issue/PR. Khung không có kênh email/Slack riêng.
- **Chạy ngoài Claude Code / không giám sát:** `scripts/maintain-run.sh` (harness khác, tài khoản subscription cục bộ) và `scripts/maintain-cron.sh` (cron/VPS, đẩy lên nhánh `maint/auto-<ngày>` + tự mở PR) — mô tả đầy đủ ở `.claude/agents/maintainer.md`, xem `--help` của script.
- **Không bao giờ:** tắt/skip test, nới ngưỡng, thêm miễn trừ để cổng xanh; nâng major hàng loạt; xoá nhánh remote/dữ liệu khi chưa được duyệt rõ; gộp nhiều mục vào một PR khổng lồ.

Bắt đầu **PHA 0** ngay.
