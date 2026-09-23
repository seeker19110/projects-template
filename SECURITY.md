# Chính sách bảo mật

Bảo mật là một trụ cột của bộ khung này (CLAUDE.md mục 3). Tài liệu này nói **cách báo cáo lỗ hổng**
và **các hàng rào bảo mật tự động** đang chạy.

## Báo cáo lỗ hổng

**Đừng** mở issue công khai cho lỗ hổng bảo mật. Thay vào đó:

- Dùng **GitHub Security Advisories**: tab **Security → Report a vulnerability** (private disclosure), hoặc
- Repo này không công bố email riêng cho bảo mật — dùng kênh Security Advisories ở trên (dự án đích: điền email/kênh thật của mình vào đây).

Vui lòng kèm: mô tả, bước tái hiện, ảnh hưởng dự kiến, và phiên bản/commit liên quan.
Mục tiêu phản hồi: xác nhận trong vòng **72 giờ**; thống nhất mốc vá trước khi công bố.

## Hàng rào bảo mật tự động trong repo

| Lớp | Công cụ | Bắt gì |
|-----|---------|--------|
| Bí mật | gitleaks (`.github/workflows/secret-scan.yml`) — mỗi PR/push + quét toàn lịch sử hằng tuần | API key/token/mật khẩu lỡ commit |
| Bí mật (trước khi vào git) | hook `.claude/hooks/pre-commit-gate.sh` | chuỗi giống khoá / file > 1 MB trong diff staged (Claude Code) |
| Phụ thuộc | Dependabot (`.github/dependabot.yml`: actions, pip, npm) + `dependency-review.yml` (fail ở mức high) | bản có lỗ hổng đã biết; dependency mới có CVE trong PR |
| SAST | CodeQL (`.github/workflows/codeql.yml`: python + actions) | lỗ hổng trong 4 engine Python và workflow |
| Chuỗi cung ứng | OpenSSF Scorecard (`.github/workflows/scorecard.yml`); cổng `scripts/check-ci-policy.sh` CP-2 (mọi action ghim full SHA); ShellCheck | action chưa ghim, quyền token rộng, workflow nguy hiểm |
| Nhánh chính | ruleset `.github/rulesets/main.json` + job `protection-guard` | push thẳng/force-push `main`, PR không qua cổng |
| Agent | ADR-0009 (nội dung ngoài là dữ liệu) + `docs/ops/threat-model-maintain-cron.md` | prompt injection qua PR/issue/file vào agent, kể cả khi chạy không giám sát |

Mã chạy thật của khung là `scripts/*.py` + `scripts/*.sh` + `.claude/hooks/*.sh` (không phải app web) — CodeQL và
ShellCheck quét đúng phần đó. Ở **dự án đích** (đã chọn stack qua `/consult`), bổ sung tương ứng: SAST (vd CodeQL cho JS/TS, hoặc
công cụ tương đương ngôn ngữ khác), `npm audit`/công cụ quét phụ thuộc của stack đã chọn, validate
biến môi trường lúc khởi động (vd Zod cho Node), và kiểm soát truy cập dữ liệu (RLS/ACL) nếu có CSDL —
xem `CLAUDE.md` §3 mục 1–2 + `docs/framework/03-tech-selection-and-proactive-advice.md`.

## Nguyên tắc bất biến (không bao giờ phá)

- **Bí mật không bao giờ vào Git** — dùng biến môi trường (`.env*` đã bị `.gitignore` chặn).
- **Không tin client** — logic nhạy cảm (kiểm tra quyền, tính toán quan trọng) luôn ở server.
- Truy vấn **tham số hóa** (chống SQL injection); **escape** dữ liệu ra HTML (chống XSS).
- **RLS bật và đã test** trước khi mở cho người ngoài.
- Mọi đầu vào (người dùng/API/CSDL) **validate lúc chạy** trước khi dùng.
