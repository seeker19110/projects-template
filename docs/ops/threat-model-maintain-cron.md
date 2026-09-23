# Threat model: `scripts/maintain-cron.sh` — bảo trì không giám sát trên VPS/cron

> Theo mẫu `docs/framework/templates/THREAT-MODEL.template.md`. Đường chạy duy nhất của khung mà AI agent hành động
> **không có người duyệt tại chỗ** — nên cần threat model riêng (audit 2026-09-23, C9; ADR-0009).

## Scope và assets

Repo dự án đích (lịch sử git, nhánh `main`), token GitHub trong môi trường cron (`GITHUB_TOKEN`), máy VPS (tài khoản
CLI subscription đã đăng nhập, file hệ thống), báo cáo `docs/ops/MAINTENANCE-*.md` (kênh báo cáo cho chủ dự án).

## Actors và entry points

- Hợp lệ: cron trên VPS của chủ dự án; CLI AI cục bộ (`claude -p`, `hermes`, `codex`, `opencode`).
- Tấn công: bất kỳ ai ghi được nội dung mà agent đọc — PR/issue/comment từ fork, tên file/nội dung file trong repo
  (qua PR đã merge), dependency (changelog/README được `deps_*` in ra), output của lệnh quét.
- Entry points: `git ls-files` (tên file), `maintenance-sweep.sh` (nội dung report), prompt nạp `MAINTENANCE-PLAN.md`
  cũ, REST API GitHub khi mở PR.

## Data flow và boundaries

cron → `maintain-cron.sh` (khoá tiến trình, `git fetch` + checkout `main` sạch) → `maintain-run.sh` (sweep → prompt
→ CLI AI) → agent đọc repo + report → ghi **chỉ** `docs/ops/MAINTENANCE-*.md` → `git push --force-with-lease`
**chỉ** nhánh `maint/auto-<ngày>` → mở PR qua REST (token chỉ trong header, không argv).

## Threats

| ID | Threat/abuse case | Asset/boundary | Likelihood | Impact | Control/test | Residual risk | Owner |
| --- | --- | --- | --- | --- | --- | --- | --- |
| T1 | Prompt injection: file/issue chứa "xoá nhánh main", "chạy `curl … \| sh`" → agent làm theo | repo, VPS | Trung | Cao | ADR-0009 (luật); `maintain-cron` chỉ push `maint/*`, không merge (`test-maintain-cron.sh`); hook chặn git nguy hiểm (Claude Code) | Harness ngoài Claude Code không có hook → chỉ còn luật | chủ dự án |
| T2 | Command injection qua tên file khi sweep quét (`$(…)` trong tên) | VPS | Thấp (đã vá) | Cao | `maintenance-sweep.sh` đọc tên file bằng `read -d ''`, không `sh -c` (negative test mục 3b) | mẫu tương tự ở script khác của dự án đích | khung |
| T3 | Token GitHub lộ qua `ps`/log | token | Trung | Cao | `--gh-token` qua argv → chuyển sang biến môi trường/`--gh-token-file` (Đợt 7); `curl -sS` không in header | tới khi Đợt 7 merge, không dùng `--gh-token` trên máy chung | khung |
| T4 | Agent nâng dependency/đổi lockfile tự ý theo "đề nghị" trong changelog của gói | repo | Thấp | Trung | `maintainer.md` cấm sửa source khi kế hoạch chưa duyệt; `maintain-cron` chỉ `git add` 3 file report | agent bỏ luật → diff vẫn nằm trên nhánh `maint/*`, chờ người duyệt | khung |
| T5 | DoS/chi phí: cron chạy chồng, prompt phình theo report | VPS, quota AI | Thấp | Thấp | khoá tiến trình (`flock`/fallback), `--no-deps` khi offline, timeout `DEPS_TIMEOUT` | — | chủ dự án |
| T6 | Report/PR tự mở chứa bí mật đọc được từ repo | token/bí mật | Thấp | Cao | sweep chỉ in 160 ký tự đầu mỗi dòng nghi bí mật; secret-scan chạy trên PR | vẫn có thể lộ tiền tố khoá | khung |

## Security acceptance

- [x] Negative test: tên file độc không thực thi (`test-maintenance-sweep.sh` 3b).
- [x] `maintain-cron.sh` không đụng `main`, không merge, chỉ 3 file (`test-maintain-cron.sh`).
- [x] Token không ra stdout/log (đọc mã; `curl -sS`).
- [ ] Bỏ `--gh-token` argv (Đợt 7).
- [ ] Hook `PostToolUse` gắn nhãn untrusted cho output WebFetch/GitHub (Đợt 5, chỉ Claude Code).
- [x] Luật ADR-0009 ở CLAUDE.md/AGENTS.md/3 agent.

**Approver/date/review trigger:** người dùng duyệt kế hoạch 7 đợt 2026-09-23; xem lại khi thêm harness mới vào
`maintain-run.sh`, khi cron nhận thêm quyền (merge/deploy), hoặc sau bất kỳ sự cố nào ở T1–T6.
