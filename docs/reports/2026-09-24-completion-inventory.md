# Hồ sơ rà soát toàn diện bộ khung — Pha 0

- Ngày: 2026-09-24.
- Yêu cầu: pull, rà lỗi/cấu trúc/tài liệu và lập kế hoạch hoàn thiện.
- Trạng thái: đã lập hồ sơ và bản đồ phạm vi; chờ xác nhận Pha 0 trước audit.
- Chủ thể: chính bộ khung vận hành dự án, có mã Bash/PowerShell/Python và CI chạy thật.
  `PROJECT.md` là bản mẫu cho dự án đích; các ô trống không tự động là lỗi.
- Giai đoạn: GĐ 8 — bảo trì.

## Mốc Git đã kiểm tra

- Nhánh hiện tại: `feat/impeccable-production-integration`, HEAD `e991b14`.
- `git fetch origin`: exit 0.
- `git pull --ff-only`: exit 0, `Already up to date.`
- Working tree sạch trước khi tạo hồ sơ này.
- `origin/main`: `9087c1f`, PR #176.
- PR #177 vẫn OPEN, chưa merge. Phần Impeccable phải được phân biệt với nền main.
- `gh pr checks 177`: hai job `framework-lint` và `framework-lint-windows` fail;
  `metadata` fail; job tổng hợp `gate` fail. Chưa kết luận nguyên nhân từ tên job.
- Các check pass tại thời điểm đọc: copy-framework-smoke, docs-consistency,
  protection-guard, dependency-review, gitleaks, Analyze (actions/python), CodeQL.
- `progress-freshness`: skipping. Các trạng thái CI này không thay cho audit mới.

## Bản đồ phạm vi đề xuất

| Năng lực thực tế | Điểm vào / nguồn | Kiểm chứng cần dùng khi audit |
| --- | --- | --- |
| Copy và nâng bản khung, bảo toàn chỉnh sửa dự án đích | `copy-framework.sh`, `copy-framework.ps1` | `scripts/test-copy-framework.sh`; so hợp đồng hai nền tảng |
| Phân giải lệnh theo stack, cổng Git dùng chung | `scripts/dev-task.sh`, `scripts/_stack-detect.sh`, `scripts/githooks/pre-commit` | `scripts/test-dev-task.sh`; đối chiếu lệnh thực sự được gate chạy |
| Hook format, commit, Git, phiên làm việc và telemetry | `.claude/hooks/`, hai file settings dùng chung | `scripts/test-hooks-gate.sh`, `scripts/test-hooks-session.sh`; kiểm từng hook được khai và được test |
| Biên dịch spec thành contract | `scripts/spec-compiler.py` và wrapper | `scripts/test-next-gen-engines.sh`, `scripts/test-engine-characterization.sh` |
| Radar sức khỏe repo | `scripts/arch-health-radar.py` và wrapper | Các test engine; phân biệt phép đếm phủ cổng với coverage và chất lượng thực |
| Nạp vai agent, định tuyến năng lực | `scripts/subagent-dispatch.py`, `.claude/agents/` | `scripts/test-telemetry-and-dispatch.sh`; đối chiếu frontmatter và tài liệu |
| Ghi telemetry và ước tính quota | `scripts/telemetry-log.py`, `scripts/usage-estimate.sh` | Test telemetry, session và usage-estimate; kiểm sai số và xử lý lỗi ghi |
| Quét bảo trì, runner và cron | `scripts/maintenance-sweep.sh`, `scripts/maintain-run.sh`, `scripts/maintain-cron.sh` | Ba suite test tương ứng; chỉ dùng fixture, không gọi runner thật hoặc đẩy báo cáo tự động |
| CI, metadata, coverage, complexity và bảo vệ nhánh | `.github/workflows/`, `scripts/check-*.sh` | Log CI thực tế, negative test, Python coverage và complexity shell/Python |
| Quy trình, bản mẫu và trạng thái dự án | `CLAUDE.md`, `AGENTS.md`, `docs/framework/`, `PROGRESS.md`, bản đồ/quy ước | Kiểm đồng bộ máy và đối chiếu ngữ nghĩa thủ công |
| Adapter UI tùy chọn trong PR #177 | `.claude/hooks/ui-intelligence.sh`, `.claude/commands/ui-ux.md`, tài liệu provider | Rà opt-in, xử lý lỗi, test hành vi và khác biệt với main |

## Chênh lệch bản đồ cần kiểm tra trong lượt audit

- Đếm file thật hiện có: 16 command, 11 agent, 9 hook và 9 workflow.
- `docs/FEATURE-MAP.md` còn tiêu đề 13 command, 9 agent, 5 hook và mô tả 7 workflow.
  Bản đồ cũ cũng chưa phản ánh đầy đủ engine và nâng bản khung.
- `PROGRESS.md` phần đầu ghi PR #177 đang chờ nhưng phần đang làm/tiếp theo còn
  ghi không có việc dở, bàn giao phiên còn mốc 2026-09-19.
- Đây là điểm lệch đã thấy khi inventory; chưa phải kết luận audit toàn bộ.

## Đề xuất lượt audit tiếp theo

Quét mới trên mốc hiện tại, giữ lịch sử audit cũ (lượt 2026-09-12 đã đóng).
Rà các nhóm kiến trúc, bảo mật, logic, test, thời gian chạy CLI/cổng, chuỗi cung ứng,
CI/vận hành, tài liệu, tính toàn vẹn file/telemetry, cấu hình và thống nhất chéo.
UI app, Core Web Vitals và migration cơ sở dữ liệu không áp dụng; HTML widget và
adapter UI vẫn thuộc phạm vi nếu có mã tương ứng.

Đầu ra sau audit: phát hiện có vị trí và bằng chứng, kế hoạch PR nhỏ theo phụ thuộc,
tiêu chí nghiệm thu/DoC và rủi ro còn lại. Chưa sửa source, chưa commit/push/merge.

## Cổng cần xác nhận

`docs/framework/project-completion.md`, Pha 0 quy định:
“người dùng xác nhận Hồ sơ dự án + Bản đồ tính năng (đúng/đủ chưa) trước khi quét”.
Xác nhận cần thiết là phạm vi chính bộ khung theo bảng trên, bao gồm phần chưa merge
của PR #177 nhưng phân biệt với main; không phải xin lại quyền pull.
