# Feature spec: `/auto-complete` trọn vòng — bốn cổng máy học từ kho `seeker19110/stored`

| Thuộc tính | Giá trị |
| --- | --- |
| Issue / Goal | Yêu cầu chủ repo 2026-10-12: "nghiên cứu `seeker19110/stored`, lấy những điểm tốt tích hợp sâu vào dự án để hiện thực hoá: chỉ cần `/auto-complete` là tự động nghiên cứu, lập kế hoạch, chọn kiến trúc, lên kế hoạch → code → loop → fix → bàn giao sản phẩm". Hồ sơ `docs/work/2026-10-12-doi-chieu-stored-auto-complete/working.md` |
| Spec owner | Phiên chính |
| State | **Approved for implementation** |
| Approver / date | Phiên chính duyệt theo ủy quyền toàn cục (`standard-delivery.md` §3d); 2026-10-12 |
| Last updated | 2026-10-12 |

> Spec gọn (mức M): một PR, bốn đơn vị độc lập, không đổi schema/API/auth, không thêm dependency.
> Đối chiếu ba cột theo `adopt-from-outside.md` (báo cáo ở `docs/reports/`, tên `2026-10-12-doi-chieu-stored`).

## 1. Problem, user và evidence

`stored` là kho tri thức (23 chuyên mục) phần lớn rút từ chính các repo của chủ kho; cơ chế vòng lặp của nó đã có ở đây và
sâu hơn (ba cổng máy #287, Goal Loop §4/§8, streak cùng chữ ký). Bốn chỗ **tốt hơn bản hiện có** cho chuỗi `/auto-complete`
(nghiên cứu → kiến trúc → kế hoạch → code → loop → fix → bàn giao), đều dạng *kiểm được hơn* (văn xuôi → cổng máy):

| Đã có và sâu hơn | Đã có nhưng nông hơn | Chưa có / quyết định |
| --- | --- | --- |
| AI Delivery Loop (xboss) = `standard-delivery.md` §2/§4/§8; "3 repair" = streak chữ ký; status-freshness = PF-1..4; `verified_by` = evidence-check + contract C-4 + goal mục 15; subagent không lồng = ADR-0010/0011; negative control = test mục 11 | (K1) `done.md` là tín hiệu dừng của hook giữ vòng nhưng không cổng nào đọc nội dung — commit `b7bd718` hôm nay đưa `done.md` còn `Trạng thái: Active` + placeholder lên nhánh (`git mv` sau khi sửa giữ blob cũ) → mục 13b. (K2) ADR có mục "Các phương án" nhưng không cổng → mục 16 (≥ 2 phương án; 0003/0004 dùng tiêu đề "Phương án đã loại" — chấp nhận). (K3) `ask` che `.claude/**`, workflows, githooks nhưng **không** che script cổng/rulesets/config lint-test-coverage → nới cấu hình để xanh không bị hỏi (xboss `protect-config`). (K4) `/auto-complete` chưa nối `/bootstrap` (greenfield), review tách người viết (generator ≠ evaluator) và bước bàn giao (clone sạch + smoke, `release-readiness.md` GO/NO-GO, `done.md` nghiệm thu) | Timeout/hạn dùng cho vòng, FEATURE-MAP ✅ phải có test, `/hoc`, trường side-effect trong PLAN, outbox, gh-aw/Routines, evaluator trình duyệt: **chưa cần**, điều kiện xem lại ghi trong báo cáo |

## 2. Outcome, baseline, target và guardrails

- Baseline: 0 cổng cho nội dung `done.md`; 0 cổng cho phương án trong ADR; 20 entry `ask`, không entry nào cho cấu hình cổng;
  `/auto-complete` kết thúc ở Definition of Complete, không nêu bàn giao.
- Target: (a) docs-consistency đỏ khi `done.md` thiếu `Trạng thái: Done`, còn placeholder mẫu, hoặc không có PR/SHA ở "Nghiệm thu
  cuối"; (b) đỏ khi ADR (≠ `0000`) không có ≥ 2 phương án đã cân nhắc/loại; (c) sửa script cổng, rulesets, dependabot, config
  tsconfig/eslint/vitest/jest/playwright/lighthouse/coverage/ruff/pre-commit/markdownlint phải qua `ask` ở cả hai settings;
  (d) `/auto-complete` nêu đủ chuỗi: `/consult` → `/bootstrap` (cổng "Sẵn sàng phát triển") → ADR ≥ 2 phương án → `/auto`
  (review tách người viết trước mỗi PR) → `/completion` → bàn giao (chạy được từ clone sạch + smoke thật, `release-readiness.md`
  GO/NO-GO, `done.md`). Ba bước review/clone sạch/smoke bổ sung sau khi chủ repo hỏi "thiếu gì không" (2026-10-12): `/auto` và
  `/completion` không gọi `/review`; smoke chỉ có "cuối mỗi đợt" ở Pha 3; không playbook nào kiểm sản phẩm chạy được từ clone mới.
- Guardrails: không chặn oan 29 `done.md` và 11 ADR hiện có; `ask` không phải `deny` (người dùng vẫn duyệt được); không hạ cổng nào.

## 5. Scope / non-goals

Trong: `scripts/_docs-consistency-structure.sh` (mục 13b, 16), hai file settings + test mục 19, `.claude/commands/auto-complete.md`
+ contract test, TRAPS mục mới (git mv sau khi sửa), CODEMAP/FEATURE-MAP/CHANGELOG, báo cáo đối chiếu. Ngoài: hook PreToolUse kiểm
Bash ghi vào file cấu hình (`ask` chỉ che Edit/Write — ghi ở TRAPS làm giới hạn đã biết), các mục "chưa cần".

## 9. Acceptance criteria

- AC-1: `done.md` thiếu `- Trạng thái: Done` → docs-consistency đỏ, nêu mục 13b.
- AC-2: `done.md` còn placeholder `<DoD, mọi PR MERGED` hoặc "Nghiệm thu cuối" không có PR/SHA → đỏ; `done.md` đủ → không chặn.
- AC-3: ADR không có mục phương án hoặc < 2 phương án → đỏ (mục 16); ADR 2 phương án dạng bullet hoặc bảng → không chặn; `0000-template.md` bỏ qua.
- AC-4: Cả hai settings có entry `ask` cho script cổng, rulesets, dependabot và config lint/test/coverage của dự án đích.
- AC-5: `auto-complete.md` trỏ `/bootstrap`, "Sẵn sàng phát triển", `docs/adr/`, `/review` + `security-review` (review tách người viết trước mỗi PR), smoke từ clone sạch với `.env.example`, `release-readiness.md`, `done.md`.

| AC | Bằng chứng |
| --- | --- |
| AC-1 | `scripts/test-check-scripts.sh::bắt được done.md chưa Done (mục 13b)` |
| AC-2 | `scripts/test-check-scripts.sh::bắt được done.md còn placeholder (mục 13b)`, `scripts/test-check-scripts.sh::bắt được done.md không có PR/SHA (mục 13b)`, `scripts/test-check-scripts.sh::KHÔNG chặn oan done.md đủ nghiệm thu (mục 13b)` |
| AC-3 | `scripts/test-check-scripts.sh::bắt được ADR không có mục phương án (mục 16)`, `scripts/test-check-scripts.sh::bắt được ADR chỉ 1 phương án (mục 16)`, `scripts/test-check-scripts.sh::KHÔNG chặn oan ADR 2 phương án (mục 16)` |
| AC-4 | `scripts/test-hooks-gate-guard.sh::Edit(**/tsconfig*.json)`, `scripts/test-hooks-gate-guard.sh::Edit(.github/rulesets/**)` |
| AC-5 | `tests/test_adaptive_process.py::test_auto_complete_chains_existing_playbooks_under_3d` |

## 11. Architecture và code touchpoints

- `scripts/_docs-consistency-structure.sh`: `check_work_record` thêm nhánh done.md (13b); hàm mới `check_adr_alternatives` (mục 16)
  cho `docs/adr/*.md` trừ template; `scripts/check-docs-consistency.sh` comment phạm vi 12–16.
- `.claude/settings.json`, `.claude/settings-shared-default.json`: `permissions.ask` thêm entry cấu hình cổng (giống hệt nhau).
- `.claude/commands/auto-complete.md`: bước 1 nêu greenfield `/consult` → `/bootstrap`; kiến trúc → ADR; bước 3 bàn giao.
- Test: `scripts/test-check-scripts.sh` (7 ca mới), `scripts/test-hooks-gate-guard.sh` mục 19 (rules), `tests/test_adaptive_process.py`.
- Sổ: `TRAPS.md` (mục 70), `CODEMAP.md`, `docs/FEATURE-MAP.md`, `CHANGELOG.md`.

## Approval

Approved for implementation — phiên chính duyệt theo ủy quyền chủ repo ngày 2026-10-12; một PR, không hạ cổng, test đỏ-trước (ADR-0005).
