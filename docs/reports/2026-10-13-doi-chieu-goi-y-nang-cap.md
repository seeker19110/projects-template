# Đối chiếu đề xuất nâng cấp 2026-10-13 (báo cáo #299 + `stored` mục 23 §7b, 12 §3, 16 §2c–§2d)

> Phương pháp: `docs/framework/adopt-from-outside.md` (ba cột, §2 "tốt hơn bản hiện có", §3 grep cổng đang chạy).
> Nguồn: `docs/reports/2026-10-13-goi-y-nang-cap.md` (#299, phiên chủ repo); clone nông `seeker19110/stored` @ `f98ccdb`
> (đọc 2026-10-13): mục 23 §7–§8.1, mục 12 §3–§3e, mục 16 §2c–§2d. Chủ repo yêu cầu "xem thêm đề xuất nâng cấp" (2026-10-13).
> Hồ sơ: `docs/work/2026-10-12-hoan-thien-khung-sau-loop-v2/` (W-410, W-411). Mọi lệnh grep dưới đây chạy trên `5aabe93`.

## 0. Kết luận

Ba đề xuất của #299 và các gợi ý của `stored` §7b được xét cùng nhau. Phần lớn đã có ở đây (thường sâu hơn) hoặc cần
quyền/quyết định của chủ repo. **Lấy 1**:

| # | Lấy | Dạng "tốt hơn" | Cổng |
| --- | --- | --- | --- |
| L1 | Khoá hash `scripts/requirements-ci.txt` (stored 12 §3 "hash-locked installs") | bắt thêm lớp lỗi: phụ thuộc bắc cầu của radon (`mando`, `colorama`, `six`) trước đây **không ghim**, gói bị thay ở PyPI/proxy đi lọt | chính pip ở chế độ hash, job `framework-lint` và `framework-lint-windows` |

Trong lúc rà còn lộ thêm một lỗi của chính khung, nặng hơn mọi đề xuất: **F-013**. Bí mật ở đầu một diff staged lớn
lọt qua cả hai hook pre-commit (SIGPIPE, TRAPS 71). Bản sửa ở #303, chờ chủ repo duyệt.

## 1. Cột "Đã có và SÂU HƠN" (không lấy)

| Hạng mục | Ở đây (cổng đang chạy) | Vì sao không lấy |
| --- | --- | --- |
| Ghim action theo SHA (bài học Trivy CVE-2026-33634) | `check-ci-policy.sh` (mọi `uses:` phải `@<sha40>`, có negative test); `ci-target.yml` 0 action chưa ghim | đã là cổng máy, chính stored lấy repo này làm chuẩn tham chiếu (25/25) |
| Hook chặn sửa cấu hình (`protect-config`) | `permissions.ask` cho file cổng + `test-hooks-gate-guard.sh` mục 19 | đã có từ #289 |
| Template threat model / RoE (AI Red Teaming Guide, stored 12 §3f) | `docs/framework/templates/THREAT-MODEL.template.md`, `docs/ops/threat-model-maintain-cron.md` | RoE là cho buổi red-team có hợp đồng, ngoài hồ sơ của khung; nguồn chưa có LICENSE (không chép được) |
| Workflow `issue_comment` + `contents: write` không kiểm `author_association` (lỗi Claude-Red, stored 8.1) | `grep -l 'issue_comment\|pull_request_target' .github/workflows/*.yml docs/framework/templates/*.yml` → **0 file** | khung không có bề mặt này; xem "chưa cần" C4 cho cổng phòng ngừa |
| Dependabot `github-actions` + `pip` + `npm`, Scorecard, dependency-review | `.github/dependabot.yml`, `scorecard.yml`, `dependency-review.yml` | stored 8.1 đo 25/25, mọi workflow có `permissions:` |

## 2. Cột "Đã có nhưng NÔNG HƠN" (chỉ lấy đúng điểm nông)

| Hạng mục | Ở đây | Điểm nông | Kết cục |
| --- | --- | --- | --- |
| Hash-locked installs (stored 12 §3) | `requirements-ci.txt` ghim `coverage==7.16.2`, `radon==6.0.1` theo phiên bản | không hash; phụ thuộc bắc cầu trôi tự do | **Lấy (L1).** 129 sha256 lấy từ PyPI JSON (mọi file của từng bản); đo: `pip install --dry-run -r` ở chế độ hash → OK; đổi `six==1.16.0` (hash không khớp) → pip từ chối |
| Lan chuẩn khung sang repo con (#299 đề xuất 1) | `maintenance-sweep.sh` `sweep_framework_age`: dự án đích tự cảnh báo 🟡 khi bản khung đã copy > 90 ngày | chỉ đo tuổi, và chỉ ở repo **đã** copy khung. Repo đứng ngoài khung (X-Agents 0/42, ai-gateway 0/6, reveser 0/92 action ghim SHA) không bao giờ chạy nó | **BLOCKED, cần chủ repo** (xem §4 Q1): job quét chéo cần token đọc 19 repo + quyền mở issue ở repo khác (hành động ra ngoài) |

## 3. Cột "CHƯA CÓ"

| Hạng mục | Tốt hơn bản hiện có? | Kết cục |
| --- | --- | --- |
| C1. `claude-sonnet-5` → `claude-sonnet-5-5` trong `.claude/settings.json` + `STALE_MODEL_RE` (#299 đề xuất 2) | Có: cùng giá 2/10 USD/1M (pricing đã xác minh ở #302), đời mới hơn. Nhưng đây là **đổi model mặc định** của mọi phiên (ADR-0006/0007, CLAUDE.md §2) và `settings.json` thuộc `permissions.ask`. Thêm `claude-sonnet-5([^-0-9]\|$)` vào `STALE_MODEL_RE` sẽ đỏ ngay ở ADR-0007 (ADR cũ không được sửa) nên cần miễn trừ | **Chờ chủ repo** (§4 Q2), kèm đề xuất gộp: 4 subagent khai `model: haiku` (`lookup`, `version-check`, `mechanical-worker`, `tester`) — mô tả ghi "Haiku 4.5"; ghim/ghi rõ Haiku 5.5 (1/5 → 0.10/0.50, rẻ hơn 10 lần) |
| C2. Quét skill/MCP mới bằng `snyk/agent-scan` / NVIDIA SkillSpector / cisco skill-scanner (#299 đề xuất 3; stored 12 §3d–§3e) | Chưa chứng minh được. `ls .claude/skills` → thư mục không tồn tại, không có skill bên thứ ba nào được vendor; `adopt-from-outside.md` đã buộc đọc từng hook/installer. Cả ba tool tự nhận "best-effort"; agent-scan có thể **chạy** MCP stdio khi quét (cần sandbox); SkillSpector gửi nội dung file cho LLM. Tốt hơn ròng = 0 khi không có gì để quét, còn cộng thêm một dependency và một bề mặt chạy code | **Chưa cần.** Xem lại khi khung vendor skill/MCP bên thứ ba đầu tiên, hoặc dự án đích có `.claude/skills/**` từ nguồn ngoài |
| C3. Code knowledge graph cho agent (Graphify / codegraph, stored 16 §2d; CodeFlow §2c) | Chưa chứng minh được cho khung: repo là bash + Markdown, đã có `CODEMAP.md` (docs-consistency mục 6 bắt script không có dòng) + `arch-health-radar.sh`. Benchmark của tool là tự công bố "(chưa xác minh độc lập)"; codegraph bật telemetry mặc định, cài bằng `curl \| sh` | **Chưa cần.** Xem lại khi một dự án đích brownfield vượt ~1.000 file mã (xboss 2.002 file) và có ca đo được agent grep lại tốn token; khi đó chọn một tool (Graphify, Apache-2.0) và ghi ADR |
| C4. Cổng `check-ci-policy`: workflow `issue_comment`/`pull_request_target` có quyền ghi phải kiểm `author_association` | Bắt một lớp lỗi có thật ở repo của chủ sở hữu (Claude-Red `skill-optimize-apply.yml`), nhưng khung và `ci-target.yml` có 0 workflow như vậy: cổng sẽ không bắt gì hôm nay | **Chưa cần.** Xem lại khi khung phát workflow chạy theo comment (vd `claude-code-action`, đang BLOCKED cần chủ repo) |
| C5. dependency-cruiser / import-linter làm cổng CI (stored 16 §2c) | `quality-gates-by-profile.md:137` có luật bằng lời cho monorepo, chưa có cổng máy trong `ci-target.yml`; khung không có mã JS/TS/Python ứng dụng để chặn | **Chưa cần** ở khung. Xem lại khi `ci-target.yml` có hồ sơ monorepo được dự án đích thật dùng (cổng phải cấu hình theo từng dự án) |
| C6. Mutation testing (stored 12 §3, xboss `mutation-check.mjs`) | Spec `docs/specs/2026-09-12-golden-tests-and-tdd.md` đã để ngỏ, chưa có quyết định mới | **Giữ quyết định cũ** (để mở, không chặn) |

## 4. Câu hỏi cho chủ repo (vượt ủy quyền §3d)

- **Q1 (lan chuẩn sang repo con).** Đề xuất thiết kế: workflow định kỳ ở **repo `stored`** (nơi đã giữ ma trận 8.1), không ở khung.
  Nó dùng một PAT fine-grained chỉ đọc nội dung + `issues: write` trên các repo được liệt kê, đo đúng các cột của ma trận
  (ghim SHA, `permissions:`, Dependabot actions, `auto-complete-guard.sh` trong Stop, không `opusplan`), rồi mở hoặc cập nhật
  **một** issue có nhãn cố định ở repo lệch (khoá theo tiêu đề để chạy lại không trùng). Cần anh/chị: tạo token + chọn danh sách repo.
- **Q2 (model mặc định).** Đổi `claude-sonnet-5` → `claude-sonnet-5-5` (cùng giá) và Haiku 4.5 → 5.5 cho 4 subagent `model: haiku`?
  Nếu đồng ý: một ADR mới (không sửa ADR-0007), sửa `settings.json` + `settings-shared-default.json` + `model-capability-tiers.json`
  + `STALE_MODEL_RE` (miễn trừ `docs/adr/`), qua một PR không auto-merge.
- **Q3.** Duyệt #303 (F-013 bí mật lọt + F-011) và patch W-406 (lint bỏ `./.claude/worktrees/*`).

## 5. Đính chính giữa chừng

- Ban đầu định ghi C2 là "nông hơn" vì `adopt-from-outside.md` có luật đọc trước khi cài. `grep -rniE 'agent-scan|skillspector|skill-scanner'`
  trên cổng chạy → 0, và `.claude/skills` không tồn tại → đúng là "chưa có", và chưa có gì để quét.
- Định lấy C4 vì có sự cố thật ở Claude-Red; grep ra 0 workflow có trigger đó ở khung → hôm nay cổng không bắt được gì, nên chuyển sang "chưa cần".
- `haiku` trần trong `model-rates.json` vẫn mang giá Haiku 4.5. Nếu alias `haiku` của Claude Code đã trỏ Haiku 5.5 thì ước tính
  chi phí của 4 agent khai `model: haiku` bị thổi 10 lần (và mô tả "Haiku 4.5" trong agent đã cũ). **Chưa xác minh** alias trỏ bản nào; ghi lại, không sửa đoán.
