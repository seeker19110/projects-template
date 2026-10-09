# Feature spec: cổng khoá brief PLAN.md trước khi dispatch subagent

| Thuộc tính | Giá trị |
| --- | --- |
| Issue / Goal | Yêu cầu chủ repo 2026-10-09: "tối ưu quy trình [phân chia việc phiên chính ↔ subagent] lên mức hoàn hảo nhất, chất lượng cao nhất mà hoàn thành nhanh nhất"; hồ sơ `docs/work/2026-10-09-plan-check-gate/working.md` |
| Spec owner | Phiên chính |
| State | **Approved for implementation** |
| Approver / date | Phiên chính duyệt theo ủy quyền toàn cục (`standard-delivery.md` §3d); 2026-10-09 |
| Last updated | 2026-10-09 |

> Spec gọn (mức M): một PR, không đổi schema/API công khai/auth.

## 1. Problem, user và evidence

Quy trình phân chia việc đã đủ luật (`standard-delivery.md` §3c, `orchestration-3-tier.md`, 11 agent) nhưng
nghiệm thu bằng phiên thật 2026-10-09 (`docs/reports/2026-10-09-agent-acceptance.md`, đợt 2–3) lộ bốn tổn thất
**đều ở brief của Tầng 1**, không ở worker: (1) brief `route:mechanical` tự nhận "0 quyết định để ngỏ" nhưng mâu
thuẫn với fence → worker dừng đúng, mất một vòng; (2) worker không chạy cổng vì brief không đòi → Tầng 1 phải chạy
lại; (3) reviewer không xác minh được đỏ-trước vì worker không nộp output → phải tin lời khai hoặc chạy lại;
(4) worker thử `git reset --hard` (hook chặn) — brief không cấm, tốn lượt. Định dạng PLAN.md chỉ là văn xuôi trong
`orchestration-3-tier.md`, không có mẫu copy được và không có cổng máy nào đọc nó.

| Đã có và sâu hơn | Đã có nhưng nông hơn | Chưa có / quyết định |
| --- | --- | --- |
| Luật S/M/L, số PR, trần 5 agent, route 2 trục có tiêu chí đếm được, hook chặn git nguy hiểm: giữ nguyên | Định dạng PLAN.md trong văn xuôi, không mẫu, không cổng: nâng thành mẫu + `--check-plan` | Kiểm nội dung khuôn có đúng ý Tầng 1 hay không: không làm được bằng máy, giữ ở người (TRAPS 59 cách rà) |

## 2. Outcome, baseline, target và guardrails

- Baseline: 1/2 việc đợt 3 mất một vòng vì brief; 0 cổng máy cho PLAN.md.
- Target: mọi brief qua `scripts/subagent-dispatch.sh --check-plan` thoát 0 trước khi dispatch; mẫu có sẵn khối
  "Luật chung" (cổng, output đỏ/xanh, cấm hoàn tác, dừng khi mơ hồ) để không phải viết lại mỗi lần.
- Guardrails: không thêm dependency; không đổi luật §3c/ADR-0010/0011; cổng chỉ kiểm hình thức kín, không tự sửa
  PLAN; coverage engine ≥ 95 %, radon CC ≤ 12 giữ nguyên.

## 5. Scope / non-goals

Trong: `subagent-dispatch.py --check-plan`, `PLAN.template.md`, con trỏ ở orchestration/coordinator/auto/CODEMAP/
FEATURE-MAP, TRAPS 59, probe coverage. Ngoài: cổng đếm slot subagent (harness không cấp số), kiểm nội dung khuôn,
sửa prompt 11 agent (điều kiện xem lại: khi nghiệm thu phiên thật lần sau vẫn lộ lỗi dù brief đã qua cổng).

## 9. Acceptance criteria

- AC-1: PLAN hợp lệ theo mẫu → thoát 0, báo số việc.
- AC-2: Thiếu một trong 4 trường / còn placeholder `<…>` / route lạ hoặc thiếu → thoát 1, lỗi nêu tên việc và lý do.
- AC-3: Phụ thuộc tới việc không tồn tại hoặc tạo vòng → thoát 1.
- AC-4: Việc không thuộc đơn vị PR nào hoặc thuộc hai → thoát 1.
- AC-5: `route:mechanical` không có fence hoặc điểm chạm có glob → thoát 1.
- AC-6: File PLAN thiếu/rỗng/không UTF-8 → thoát 2 (cùng khuôn `--context-file`).
- AC-7: Tài liệu điều phối trỏ tới mẫu và cổng; mẫu không mồ côi.

| AC | Bằng chứng |
| --- | --- |
| AC-1 | `tests/engine_characterization/test_dispatch.py::test_plan_hop_le_thoat_0_va_dem_viec` |
| AC-2 | `tests/engine_characterization/test_dispatch.py::test_thieu_truong_bat_buoc_neu_ten_viec_va_truong`, `tests/engine_characterization/test_dispatch.py::test_placeholder_con_sot_la_loi`, `tests/engine_characterization/test_dispatch.py::test_route_la_hoac_thieu_la_loi` |
| AC-3 | `tests/engine_characterization/test_dispatch.py::test_phu_thuoc_khong_ton_tai_hoac_vong_la_loi` |
| AC-4 | `tests/engine_characterization/test_dispatch.py::test_nhom_pr_phai_phu_moi_viec_dung_mot_lan` |
| AC-5 | `tests/engine_characterization/test_dispatch.py::test_mechanical_phai_co_fence_va_diem_cham_tuong_minh` |
| AC-6 | `tests/engine_characterization/test_dispatch.py::test_file_plan_khong_ton_tai_thoat_2` |
| AC-7 | `scripts/check-docs-consistency.sh` (mục 12 mẫu mồ côi + link) |

## 11. Architecture và code touchpoints

- `scripts/subagent-dispatch.py`: `check_plan(content)` + 5 helper nhỏ (CC ≤ 10), nhánh `--check-plan` trong `main`.
- `tests/engine_characterization/test_dispatch.py`: lớp `TestCheckPlan` (8 ca, đỏ trước khi thêm nhánh).
- `scripts/test-py-coverage.sh`: 3 probe (ok / bad / thiếu file) để giữ sàn 95 %.
- `docs/framework/templates/PLAN.template.md` (mới); `docs/framework/orchestration-3-tier.md` (khối định dạng → con
  trỏ + cổng); `.claude/agents/coordinator.md` bước 1; `.claude/commands/auto.md`; `CODEMAP.md`; `docs/FEATURE-MAP.md`
  FT-65; `TRAPS.md` mục 59.

## Approval

Approved for implementation — phiên chính duyệt theo ủy quyền chủ repo ngày 2026-10-09; một PR, không hạ cổng.
