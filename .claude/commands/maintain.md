---
description: Bảo trì toàn diện theo chu kỳ — quét (git/dependency/tài liệu/bí mật/CI/cổng) → triage → kế hoạch chờ duyệt → thực thi từng PR nhỏ qua /gate → quét lại hội tụ
---

Bạn đang chạy **`/maintain`** — vòng bảo trì toàn diện, dùng được cho **chính repo khung** và
**mọi dự án đích** (engine tự dò stack, không cần khai gì trước). Tham số:
`/maintain` (mặc định, có kiểm dependency) · `/maintain quick` (bỏ dependency, chỉ mất vài giây) ·
`/maintain full` (thêm `--gate`: build/type/lint/test) · `/maintain continue` (tiếp kế hoạch đã duyệt).

> 💡 Model/effort: theo `docs/framework/models-and-automation.md` §3–§4 và ADR-0010 §4.

Ràng buộc bắt buộc (bám `CLAUDE.md` §2 chia nhỏ + §5–§8 cổng/PR + §9 dừng-và-hỏi):

- **Khác gì các lệnh gần nghĩa:** `/audit-full` rà **chất lượng nội tại** một lần (12 nhóm, cần dự án
  đã phát triển); `/completion` đi đến "không còn lỗi đã biết"; `/audit-optimize` tối ưu mã.
  `/maintain` là **vệ sinh định kỳ**: thứ **mục nát theo thời gian** dù code không đổi —
  dependency lỗi thời/lỗ hổng, nhánh chết, `PROGRESS.md` lỗi thời, spec/goal treo, action CI chưa
  ghim, bí mật lọt git, cổng khung bắt đầu đỏ. Chạy được trên repo khung trống lẫn dự án thật.

- **PHA 0 — tiền kiểm (không bỏ qua):** đang ở `main` sạch và đã `git fetch origin main`? Nếu
  không → đưa về `main` trước (TRAPS.md mục 14: commit rơi nhầm nhánh). Đọc `PROGRESS.md` mục
  "Giai đoạn hiện tại" + `TRAPS.md`. Có `docs/ops/MAINTENANCE-PLAN.md` trạng thái ĐÃ DUYỆT còn mục
  TODO → đó là `continue`: nhảy PHA 3, không quét lại từ đầu (trừ khi người dùng bảo).

- **PHA 1 — quét (chỉ đọc):** giao subagent **`maintainer`** chạy
  `bash scripts/maintenance-sweep.sh --out docs/ops/MAINTENANCE-REPORT.md`
  (`quick` → thêm `--no-deps`; `full` → thêm `--gate`). Thiếu script (dự án chưa copy khung đủ) →
  báo người dùng chạy lại `copy-framework.sh`, rồi mới tiếp; **không** tự bịa kết quả quét.

- **PHA 2 — triage + kế hoạch, rồi DỪNG CHỜ DUYỆT:** `maintainer` viết
  `docs/ops/MAINTENANCE-PLAN.md` (mẫu trong `.claude/agents/maintainer.md`): 🔴 trước, mỗi mục =
  **một PR nhỏ** có tiêu chí xong đo được + nhãn `route:` + cổng kiểm; mục đụng §9 (thiếu dữ kiện không tự xác minh, không có phương án đạt chất lượng trong scope, cần quyền chưa cấp; vd bảo mật, dữ liệu
  thật, breaking, major bump) ghi **DỪNG & HỎI**. Trình bày kế hoạch cho người dùng bằng
  `AskUserQuestion` (duyệt toàn bộ / duyệt một phần / sửa) — **chưa duyệt thì không sửa source** (theo ủy quyền contract §3d (phiên chính tự duyệt và ghi căn cứ khi quyết định đã được ủy quyền)).

- **PHA 3 — thực thi từng mục đã duyệt:** mỗi mục một nhánh `chore/maint-<id>-<slug>` (hoặc
  `fix/…` khi là bug — khi đó **phải có test tái hiện đỏ trước** theo §3.6), giao worker theo
  `route:` (trần effort medium), sửa xong chạy **cổng kiểm của mục** + `/gate`, mở PR riêng
  (mô tả đủ PR template, kèm dòng "Nguồn: MAINTENANCE-PLAN M-xx"), cập nhật tài liệu **trong
  cùng PR** (CODEMAP/TRAPS/CHANGELOG nếu chạm), bật auto-merge khi mô tả đã đủ, **FIFO** (§8).
  Lockfile/migration → **tuần tự**, không song song. Ghi mỗi mục xong vào `docs/ops/MAINTENANCE-LOG.md`
  (ngày · mục · PR · bằng chứng) và đổi trạng thái trong kế hoạch.

- **Chạy KHÔNG GIÁM SÁT trên VPS/cron (không ai mở phiên chat):** `scripts/maintain-cron.sh` gói
  PHA 0–2 thành một lệnh an toàn để đặt cron — đồng bộ nhánh chính, chạy `maintain-run.sh`, rồi
  commit + push **CHỈ** `docs/ops/MAINTENANCE-*.md` lên nhánh riêng `maint/auto-<ngày>` (KHÔNG bao
  giờ đụng nhánh chính, KHÔNG tự merge). Có `GITHUB_TOKEN`/`GH_TOKEN` trong môi trường → **tự mở
  PR** qua GitHub REST API (kênh báo cáo chính cho chủ dự án — bạn nhận thông báo PR mới y hệt mọi
  PR khác); không có token → chỉ log, bạn tự mở PR tay. `--no-open-pr` tắt hẳn bước này dù có
  token. Có khoá tiến trình + kiểm working tree sạch trước khi chạy — xem `--help` của script.

- **PHA 4 — hội tụ + đóng:** quay về `main`, chạy lại `maintenance-sweep.sh --strict`: còn 🔴 →
  lặp PHA 2–3 cho phần còn lại (cùng một mục thất bại **tối đa 3 lần** rồi checkpoint BLOCKED và hỏi —
  luật Goal loop). 🔴 = 0 và mọi mục đã duyệt xong → cập nhật `PROGRESS.md` (mốc "bảo trì <ngày>",
  nợ kỹ thuật còn lại), xoá/ghi ĐÓNG kế hoạch, xuất Báo cáo xác thực §7 cho PR cuối.

- **Định kỳ tự động:** workflow `.github/workflows/maintenance.yml` (thứ Hai hằng tuần) chạy
  `maintenance-sweep.sh --no-deps` và mở/cập nhật **một** issue tổng hợp — issue đó là tín hiệu để
  người dùng gõ `/maintain`; dependency ở CI đã có `dependabot.yml` + `dependency-review.yml` lo.
  Không có workflow đó ở dự án đích → nhắc copy từ `_framework-dropins/`.

- **Ngoài Claude Code (Hermes/Codex/OpenCode hoặc dán tay vào chat bất kỳ), tài khoản subscription
  cục bộ, không API key:** `bash scripts/maintain-run.sh [--harness auto|claude|hermes|gemini|codex|opencode|print] [--mode quick|full]`
  (`gemini` = Hermes provider `antigravity`) làm trọn PHA 1–2 (quét → nạp vai `maintainer` → CLI cục bộ viết kế hoạch chờ duyệt). PHA 3–4 vẫn
  là người + `/gate` của harness đang dùng (`scripts/dev-task.sh gate` ở harness không có hook).

- **Giao tiếp với người vận hành ("nhân viên bảo trì" = `maintainer` + engine) — TRONG lúc code và
  SAU khi deploy dùng cùng một kênh, không phải hai hệ thống khác nhau:**
  - **Trong lúc phát triển (chủ động, bạn gõ lệnh):** `/maintain` in trực tiếp vào phiên chat —
    đây là kênh chính. Trạng thái bền giữa các lần gõ nằm ở 3 file (đọc được bằng mắt, diff được
    trong PR): `docs/ops/MAINTENANCE-REPORT.md` (ảnh chụp lần quét gần nhất — KHÔNG commit, xem
    `.gitignore`), `docs/ops/MAINTENANCE-PLAN.md` (kế hoạch + trạng thái từng mục — CÓ commit, đây
    là "hộp thư" hai chiều: bạn duyệt/sửa trực tiếp trong file này rồi gõ `/maintain continue`),
    `docs/ops/MAINTENANCE-LOG.md` (nhật ký đã làm — CÓ commit, đối chiếu khi audit).
  - **Sau khi deploy / giữa các đợt code (bị động, không ai đang mở phiên chat):**
    `.github/workflows/maintenance.yml` chạy theo lịch, kết quả đăng vào **một issue GitHub tổng
    hợp** (mở/cập nhật/tự đóng) — đây là kênh duy nhất không cần ai đang online. Cấu hình thông
    báo issue mới theo watch/notification của chính GitHub (không phải cơ chế riêng của khung); PR
    do `/maintain` mở cũng theo đúng luồng thông báo PR thường (CLAUDE.md §8) — không có kênh
    email/Slack riêng trong khung, gắn thêm là việc của dự án đích nếu cần.
  - **Không có CLI/chat nào đang mở (chạy qua `maintain-run.sh` từ cron/CI của người dùng, không
    phải workflow GitHub):** kết quả in ra stdout/stderr của tiến trình đó + ghi
    `docs/ops/MAINTENANCE-REPORT.md`/`MAINTENANCE-PLAN.md` như trên — người dùng tự nối ống dẫn
    (log file, cron mail, webhook) theo hạ tầng của họ; khung không giả định có kênh chat.
  - **Điểm chung:** `maintainer` không bao giờ tự hành động ngoài phạm vi đã duyệt — "giao tiếp"
    LUÔN là văn bản ở repo (issue/PR/3 file trên), không phải tin nhắn tạm thời biến mất; đây là lý
    do kế hoạch phải nằm trong git thay vì chỉ in ra màn hình.

- **Không bao giờ:** tắt/skip test, nới ngưỡng, thêm miễn trừ để cổng xanh; nâng major hàng loạt;
  xoá nhánh remote/dữ liệu mà không được duyệt rõ ràng; gộp nhiều mục vào một PR khổng lồ.

Bắt đầu **PHA 0** ngay.
