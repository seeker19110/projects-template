# Báo cáo: đưa mọi mục repo còn tự đánh dấu "phải làm" tới kết cục thật (2026-10-09)

> Hồ sơ: `docs/work/2026-10-09-finishing/working.md`. Báo cáo này được điền dần theo từng PR; phần "Kết quả" và
> "Giới hạn" chốt ở PR closeout.

## Pha 0 — hiện trạng đo trên `ac911e3` (sau #226)

| Thước | Giá trị | Nguồn |
|---|---|---|
| Radar | 99/100; kỷ luật kích thước 95.6 (4/91 file mã > 400 dòng); độ phủ cổng 40/40 | `bash scripts/arch-health-radar.sh` |
| File > 400 dòng | `scripts/spec-compiler.py` 476 · `scripts/telemetry-log.py` 426 · `scripts/test-check-scripts.sh` 418 · `tests/test_runtime_safety.py` 443 | radar |
| FEATURE-MAP ⚠️ | FT-25 (trích F-014 — trích nhầm, F-014 là dọn nhánh đã đóng) · FT-50 (F-309 fallback grep) | `docs/FEATURE-MAP.md` |
| Tài liệu nội bộ phát sang đích | `docs/framework/lean-delivery-benchmark.md` (P-C12, report O-6) | `copy-framework.sh` copy cả `docs/framework/` |

## Kết quả theo đơn vị

- R-01 — engine Python: điền sau merge.
- R-02 — suite test: điền sau merge.
- R-03 — F-309, FT-25/FT-50, P-C12, closeout: điền sau merge.

## Giới hạn

- Điền ở PR closeout.
