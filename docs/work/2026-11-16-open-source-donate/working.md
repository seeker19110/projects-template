# Công việc: Mục ủng hộ, hỗ trợ triển khai và NOTICE

- Work ID: 2026-11-16-open-source-donate
- Yêu cầu / outcome: chủ repo đã quyết mở mã mọi repo, thêm mục ủng hộ (donate) và dịch vụ hỗ trợ triển khai; repo đã có MIT nên giữ nguyên giấy phép
- Trạng thái: Ready
- Chủ trì / writer: phiên chính
- Mức rủi ro / số PR: S — 1 PR, chỉ tài liệu và ảnh, không đổi hành vi
- Scope / non-goal: README thêm mục "Ủng hộ và liên hệ"; `docs/assets/donate-vietqr-techcombank.png`; `.github/FUNDING.yml`; `NOTICE`; dòng CHANGELOG. KHÔNG đổi giấy phép, KHÔNG đổi `copy-framework.manifest` (các tệp mới không chép sang dự án đích)
- Spec / goal / issue: n-a (mức S, không spec); quyết định của chủ repo
- Nhánh / base SHA / thời điểm reconcile: `docs/open-source-donate` @ `bac75d3` · 2026-11-16T03:04:03Z

## Kế hoạch và phân công

Một PR, phiên chính tự làm. AC: cổng CI của repo xanh; dự án đích chạy `copy-framework.sh` không nhận tệp ủng hộ.

## Quyết định và bằng chứng

- Quét bí mật toàn lịch sử: `gitleaks git --redact` → 0 phát hiện. `.mcp.json` đã commit chỉ có URL công khai của Context7, không có khoá.
- Rà bản quyền: thành phần bên thứ ba duy nhất trong cây là `vendor/shellmetrics` (MIT, có LICENSE, ghim SHA256) — ghi ở `NOTICE`.
- `copy-framework.manifest` và `copy-framework.sh` không chép `README.md`, `LICENSE`, `NOTICE`, `.github/FUNDING.yml`, `docs/assets/`.

## Lần thử / blocker

Không có.

## Bàn giao / bước tiếp theo

Chờ CI và review của PR; merge do chủ repo.

## Nghiệm thu cuối (chỉ điền khi đủ bằng chứng)

Chưa — giữ `working.md` tới khi PR merge.
