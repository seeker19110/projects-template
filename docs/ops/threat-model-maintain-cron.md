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
**chỉ** nhánh `maint/auto-<ngày>` → mở PR qua REST (header `Authorization` ghi vào file tạm `mktemp` (0600) trong thư mục
khoá 0700, `curl -H @file`, xoá ở `trap EXIT` — token không nằm trong argv của `curl`). Token giữ trong biến không
export; `maintain-run.sh`/CLI AI chạy với `GITHUB_TOKEN`/`GH_TOKEN` đã unset; owner/repo tách từ origin đã bỏ userinfo và
phải khớp `owner/repo`.

## Threats

| ID | Threat/abuse case | Asset/boundary | Likelihood | Impact | Control/test | Residual risk | Owner |
| --- | --- | --- | --- | --- | --- | --- | --- |
| T1 | Prompt injection: file/issue chứa "xoá nhánh main", "chạy `curl … \| sh`" → agent làm theo | repo, VPS | Trung | Cao | ADR-0009 (luật); `maintain-cron` chỉ push `maint/*`, không merge (`test-maintain-cron.sh`); hook chặn git nguy hiểm (Claude Code) | Harness ngoài Claude Code không có hook → chỉ còn luật | chủ dự án |
| T2 | Command injection qua tên file khi sweep quét (`$(…)` trong tên) | VPS | Thấp (đã vá) | Cao | `maintenance-sweep.sh` đọc tên file bằng `read -d ''`, không `sh -c` (negative test mục 3b) | mẫu tương tự ở script khác của dự án đích | khung |
| T3 | Token GitHub lộ qua `ps`/log/env tiến trình con/URL origin/`bash -x` | token | Trung | Cao | `curl` nhận header qua file tạm 0600 trong thư mục khoá (`-H @file`, xoá ở trap) — argv không chứa `Authorization`/token (`test-maintain-cron.sh` 7f); token ở biến không export, `maintain-run.sh`/CLI AI chạy với `GITHUB_TOKEN`/`GH_TOKEN` đã unset (10a) — agent đọc nội dung không tin cậy không lấy được token qua `env`; origin dạng `https://user:token@github.com/…` → bỏ userinfo trước khi tách owner/repo, owner/repo phải khớp `^[A-Za-z0-9._-]+/[A-Za-z0-9._-]+$` (11); xtrace tắt quanh mọi chỗ chạm token (12); `--gh-token-file` cảnh báo khi quyền khác 600/400; `curl -sS` không in header | `--gh-token` (argv của chính `maintain-cron.sh`) vẫn lộ qua `ps` — chỉ giữ để tương thích, script cảnh báo; `git fetch/push` của chính script vẫn thấy env (cố ý, cho credential helper); token trong URL origin vẫn nằm ở `.git/config` | khung |
| T4 | Agent nâng dependency/đổi lockfile tự ý theo "đề nghị" trong changelog của gói | repo | Thấp | Trung | `maintainer.md` cấm sửa source khi kế hoạch chưa duyệt; `maintain-cron` chỉ `git add` 3 file report | agent bỏ luật → diff vẫn nằm trên nhánh `maint/*`, chờ người duyệt | khung |
| T5 | DoS/chi phí: cron chạy chồng, prompt phình theo report; symlink cài sẵn ở chỗ đặt khoá để ghi đè file | VPS, quota AI, file của người chạy | Thấp | Thấp | khoá tiến trình (`flock`/fallback `set -C`) đặt trong `.git/maintain-cron` (`umask 077`), từ chối thư mục/file khoá là symlink, không thuộc người chạy, hoặc thư mục cho group/other ghi (`test-maintain-cron.sh` 8, 13); con không giữ fd khoá (10b); `--no-deps` khi offline, timeout `DEPS_TIMEOUT` | fallback không flock còn đua khi hai lượt cùng dọn khoá mồ côi (dấu `DEBT:` tại chỗ); NTFS không đo được mode nên kiểm group/other-ghi không có tác dụng trên Windows | chủ dự án |
| T6 | Report/PR tự mở chứa bí mật đọc được từ repo | token/bí mật | Thấp | Cao | sweep chỉ in 160 ký tự đầu mỗi dòng nghi bí mật; secret-scan chạy trên PR | vẫn có thể lộ tiền tố khoá | khung |

## Security acceptance

- [x] Negative test: tên file độc không thực thi (`test-maintenance-sweep.sh` 3b).
- [x] `maintain-cron.sh` không đụng `main`, không merge, chỉ 3 file (`test-maintain-cron.sh`).
- [x] Token không ra stdout/log và không vào argv `curl` (`test-maintain-cron.sh` 7f; `curl -sS -H @file`).
- [x] Token không vào env của `maintain-run.sh`/CLI AI và không lộ qua userinfo của origin (`test-maintain-cron.sh` 10a, 11).
- [ ] Bỏ `--gh-token` argv (Đợt 7).
- [ ] Hook `PostToolUse` gắn nhãn untrusted cho output WebFetch/GitHub (Đợt 5, chỉ Claude Code).
- [x] Luật ADR-0009 ở CLAUDE.md/AGENTS.md/3 agent.

**Approver/date/review trigger:** người dùng duyệt kế hoạch 7 đợt 2026-09-23; xem lại khi thêm harness mới vào
`maintain-run.sh`, khi cron nhận thêm quyền (merge/deploy), hoặc sau bất kỳ sự cố nào ở T1–T6.
