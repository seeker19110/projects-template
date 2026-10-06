# Trạng thái audit hiện hành của repo khung — 2026-10-05

> Người dùng chọn hoàn thiện chính bộ khung. Audit 12 nhóm theo năng lực khung,
> các phát hiện F-K01..10 và căn cứ kiểm chứng nằm trong
> `docs/reports/2026-10-05-framework-audit.md`. Bản 2026-09-12 bên dưới là
> snapshot lịch sử của một lượt khác; không dùng để tuyên bố Project Complete.

## Re-audit 2026-10-06 (chu kỳ mới, Pha 1 xong — chờ duyệt kế hoạch)

Base `e2b70bf`. 12 nhóm quét lại: Cao 0 · Trung 1 (F-N01 FEATURE-MAP thiếu engine, không có cổng đối chiếu) ·
Thấp 6 · Thông tin 2. Chi tiết, bằng chứng đo và kế hoạch W-01..W-09 ở `docs/ops/COMPLETION-PLAN.md`.

## Re-audit — 2026-10-05 (chu kỳ đã đóng 2026-10-06)

Main nguồn đã đối chiếu: `6702994d90ad318142715aa172d79916c71e5b9d` (#196).
12 nhóm đã quét lại; không phát hiện Cao/Trung mới trong phần code/cổng đã rà.
F-K01..07/F-K09/F-K10 đóng trên main; F-K08/F-11 bàn giao trong PR tài liệu này.
Chu kỳ WAITING, còn cổng PR tài liệu và xác nhận đóng của người dùng.
W-06 chứng minh copy/gate runtime Node/Python tối thiểu; các resolver fixture
khác không chứng minh runtime toàn stack, Go/Make chưa có ca resolver độc lập,
CI hosted của repo đích chưa kiểm. C01 ngoài phạm vi repo khung đã chọn.
Revisit triggers và bảng 12 nhóm/F-K nằm trong
`docs/reports/2026-10-05-framework-audit.md`; không dùng snapshot cũ để nghiệm thu.

---

# COMPREHENSIVE-AUDIT-STATUS — trạng thái quét audit toàn diện

> Chủ thể: **chính bộ khung** `project-template` (không phải app web) — xem `docs/FEATURE-MAP.md`.
> Lượt quét: **RESET 2026-09-12** (lượt trước chạy TRƯỚC ADR-0004, đã lỗi thời — Nhóm 5/6/10/11
> tham chiếu `app/`, `lib/env.ts`, Supabase đã bị gỡ khỏi repo khung, không còn ý nghĩa).
> Base: `709cc86` (`origin/main`, sau PR #69 + #70). Chạy qua `/audit-full`, GIAI ĐOẠN 1 (chỉ quét,
> chưa sửa gì).
> Trạng thái: ✅ Xong · 🔄 Đang dở · ⬜ Chưa quét · ➖ Không áp dụng.

| Nhóm | Tên | Trạng thái | Phát hiện | Ngày |
| --- | --- | --- | --- | --- |
| 1 | Kiến trúc & thiết kế | ✅ Xong | 0 mới — ranh giới Lớp 1 (phương pháp)/Lớp 2 (CI/GitHub tổng quát) rõ, ADR-0001 cố ý giữ nguyên (đã superseded bằng văn xuôi ở ADR-0004, không sửa ADR cũ — đúng luật) | 2026-09-12 |
| 2 | Bảo mật | ✅ Xong | 0 mới — không có secret commit thật (`.mcp.json` chỉ chứa URL công khai; `.mcp.json.example` dùng biến môi trường); `.gitignore` chặn đúng `.env*`/`.mcp.local.json`/`settings.local.json`; `gitleaks.toml` + job `gitleaks` + `secret-scan.yml` có thật; hook `block-dangerous-git.sh` chặn đọc `.env`/bí mật (test qua `test-hooks-gate.sh`) | 2026-09-12 |
| 3 | Chất lượng mã & chống lỗi logic | ✅ Xong | 0 mới trong `check-progress-freshness.sh` (mới thêm PR #69) — đã tự rà edge case: thiếu remote, PROGRESS.md không tồn tại, thiếu dòng SHA, SHA không phải ancestor — đều có nhánh xử lý rõ, không im lặng | 2026-09-12 |
| 4 | Kiểm thử & coverage | ✅ Xong | ~~1 Trung (G-001)~~ **✅ Đã sửa 2026-09-12** — thêm `scripts/test-check-scripts.sh` (12 ca: baseline xanh + negative-test cho từng nhánh phát hiện của cả 3 script + 1 đối chứng không chặn oan), wire vào job `framework-lint` của `ci.yml` | 2026-09-12 |
| 5 | Hiệu năng | ➖ Không áp dụng | Repo khung không còn runtime (ADR-0004 đã gỡ scaffold Web/Next.js) — không có gì để đo Core Web Vitals/bundle | 2026-09-12 |
| 6 | Accessibility & UI/UX | ➖ Không áp dụng | Không còn UI trong repo khung (ADR-0004) | 2026-09-12 |
| 7 | Dependency & chuỗi cung ứng | ✅ Xong | **1 Thấp (G-002, tái xác nhận)** — `PROGRESS.md` risk table vẫn ghi "5 PR dependabot chưa merge (Cao)" nhưng `list_pull_requests(state=open)` xác nhận **0 PR đang mở** — #53→#57 đã merge từ trước (thấy trong git log). Mục risk lỗi thời, hạ xuống đã đóng. Mọi `uses:` trong workflow đã ghim SHA đầy đủ (`grep` xác nhận 0 vi phạm) | 2026-09-12 |
| 8 | CI/CD & vận hành | ✅ Xong | 8 job CI đều xanh (`framework-lint`, `docs-consistency`, `copy-framework-smoke`, `progress-freshness`, `metadata`, `gitleaks`, `dependency-review`, `gate`); branch protection **vẫn chưa gộp về 2 tên** (`gate`+`metadata`, ADR-0003) — đã biết, chờ chủ repo (không mới); 31 nhánh merged còn tồn trên remote — đã biết, chờ chủ repo (không mới) | 2026-09-12 |
| 9 | Tài liệu & đồng bộ code thật | ✅ Xong | ~~1 Trung (G-003)~~ **✅ Đã sửa 2026-09-12** — sửa dòng sơ đồ ASCII thành `Opus · medium` (khớp bảng định tuyến); riêng dòng dependabot lỗi thời của `PROGRESS.md` đã dọn ở PR #73 | 2026-09-12 |
| 10 | Dữ liệu & migration | ➖ Không áp dụng | Không còn migration nào trong repo khung (Supabase đã gỡ, ADR-0004) | 2026-09-12 |
| 11 | Cấu hình môi trường & bí mật | ✅ Xong | 0 mới — không có `.env.example` nữa (đúng, vì không còn app cần biến môi trường); `.mcp.json.example` toàn placeholder biến môi trường, không secret thật | 2026-09-12 |
| 12 | Thống nhất chéo tính năng | ✅ Xong | ~~1 Trung (G-004)~~ **✅ Đã sửa 2026-09-12** — thêm mục 5 vào `check-docs-consistency.sh`: cấm chuỗi cụ thể "Opus · high" (đã biết là sai) sống lại ở bất kỳ *.md/*.sh/*.ps1 nào, trừ nhật ký lịch sử. Cố ý KHÔNG xây trình đối chiếu ngữ nghĩa tổng quát giữa 6 file (prose mỗi nơi viết khác kiểu, dễ báo oan) — chốt hẹp đúng chuỗi đã biết là bẫy | 2026-09-12 |

## Tổng hợp mức độ

- **Cao: 0**
- **Trung: 4, đã sửa cả 4** — G-001 (PR #72), G-002 (PR #73), G-003 + G-004 (nhánh `fix/g003-g004-stale-effort-label`)
- **Thấp: 0 mới** (branch protection 7→2 tên và 31 nhánh tồn đọng đã biết từ trước, không tính lại)

## Đối chiếu với lượt trước (đã lỗi thời, tham khảo lịch sử)

Lượt quét 2026-09-12 (base `772c949`, trước ADR-0004) từng ghi nhận F-001..F-017 trên scaffold Web
đã bị xoá — không còn kiểm chứng được và không còn liên quan. Xem lịch sử Git của file này nếu cần
tra lại nội dung cũ; không mang sang lượt reset này.

**Chưa sửa gì ở lượt quét này (GIAI ĐOẠN 1 — chỉ quét).** Chờ người dùng duyệt kế hoạch xử lý ở
GIAI ĐOẠN 2.
