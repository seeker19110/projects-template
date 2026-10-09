# Lượt `/auto-complete` đầu tiên — chạy trên chính repo khung (2026-10-09)

> Hồ sơ: `docs/work/2026-10-09-auto-complete-run/`. Lệnh `/auto-complete` (#240) chạy lần đầu, không kèm mô tả việc;
> phiên chính là người quyết định theo thang ưu tiên `standard-delivery.md` §3d. Đây vừa là lượt hoàn thiện, vừa là
> nghiệm thu thật của chính lệnh.

## Bước 1 — `/auto` (brownfield, đọc trạng thái thật)

| Thước (base `a208b4f`) | Kết quả |
|---|---|
| `arch-health-radar.sh` | 100/100 nhưng "Việc cần làm" 1 mục: `scripts/subagent-dispatch.py` 404 dòng > 400 (hệ quả của #239) |
| `maintenance-sweep.sh --strict --no-deps` | 🔴 0 · 🟡 0 · TODO 10 (đều là ví dụ trong tài liệu) · DEBT 1 đủ điều kiện xem lại |
| `check-docs-consistency.sh` / `check-ci-policy.sh` | ✅ / ✅ |
| FEATURE-MAP | FT-13 ⚠️ (giới hạn harness, có chủ ý), FT-41 🚧 (cần tài khoản thật) |

Kế hoạch: 1 PR mức S → phiên chính tự làm (§3c). Cổng "chốt kế hoạch" tự duyệt theo §3d, ghi ở working.md.

## Bước 2 — `/completion` Pha 0–4

- Pha 0: FEATURE-MAP/CODEMAP/CONVENTIONS đã có từ các chu kỳ trước, rà lại khớp.
- Pha 1: bảng trên; không phát hiện Cao/Trung.
- Pha 2: kế hoạch AC-01..03 ở `docs/ops/COMPLETION-PLAN.md`; cổng "DỪNG trình kế hoạch + DoC" tự duyệt theo §3d.
- Pha 3: AC-01 — tách luật `--check-plan` sang helper thuần `scripts/_plan_check.py` (khuôn `_telemetry_report.py`, R-01),
  `subagent-dispatch.py` import muộn để sandbox test chỉ copy engine vẫn chạy; thêm 1 ca test helper thuần; manifest copy + CODEMAP.
- Pha 4: radar 100/100, "Việc cần làm" rỗng, 46/46 script có cổng; characterization 51/51; coverage engine 96 %;
  docs-consistency, check-scripts, copy-framework (Bash+PowerShell), adoption-smoke đều OK; `dev-task.sh gate` PASS.

## Quyết định tự duyệt (đủ dòng ở working.md)

5 quyết định: outcome từ ngữ cảnh · tách helper thay vì nới trần · FT-41 BLOCKED thay vì giả lập · FT-13 chấp nhận có điều kiện ·
closeout cùng PR (luật §8 mục 0).

## Giới hạn trung thực

- Lượt chạy trên repo khung (mã = script + tài liệu), chưa phải dự án đích có runtime; `/completion` Pha 1 dùng engine của khung thay
  cho 12 nhóm audit đầy đủ — hợp lệ vì các chu kỳ trước đã đóng 12 nhóm và không có thay đổi hành vi mới ngoài #239/#240.
- FT-41 vẫn BLOCKED: bước 6–8 case-study cần tài khoản/secret thật, nằm trong danh sách "không bao giờ tự quyết".
