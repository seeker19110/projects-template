# Công việc: Hoàn thiện phần còn lại của repo khung (chu kỳ 2026-10-09)

- Work ID: 2026-10-09-completion-remaining
- Yêu cầu / outcome: chủ repo 2026-10-09: "hoàn thiện tiếp những phần còn lại đi" → chạy `/completion`
  trên chính repo khung: rà mọi khoảng trống đã ghi (FEATURE-MAP "hạn chế", PROGRESS "Tiếp theo", radar,
  sweep), đưa từng mục tới kết cục có bằng chứng: sửa được ở đây thì sửa, không thì ghi rõ vì sao + điều kiện.
- Trạng thái: Active
- Chủ trì / writer: phiên chính (Fable); worker `standard-worker` cho đơn vị độc lập trong worktree riêng
- Mức rủi ro / số PR: S; 3 PR tuần tự trên nhánh `claude/relaxed-knuth-f1ejlq` (W-01 fix copy, W-02 test/cổng, W-03 closeout)
- Scope / non-goal: không mở lại P-B11/P-C12 (điều kiện xem lại chưa chạm); không chạy hosted CI/pilot/harness
  ngoài Claude Code (không có tài khoản/máy ở phiên này); không đổi ADR-0003 (bản kê hai chiều giữ nguyên).
- Spec / goal / issue: kế hoạch + DoC ở `docs/ops/COMPLETION-PLAN.md` (chu kỳ 2026-10-09); báo cáo
  `docs/reports/2026-10-09-completion-remaining.md`
- Nhánh / base SHA / thời điểm reconcile: `claude/relaxed-knuth-f1ejlq` = `origin/main` `580fc91` (2026-10-09, sau #223)

## Kế hoạch và phân công

Pha 0 (dò hiện trạng, đã đo 2026-10-09): radar 100/100 (3 file mã > 400 dòng); sweep `--strict --no-deps`
🔴 0 🟡 0; docs-consistency 11/11; FEATURE-MAP còn ❌ ở FT-43/FT-44, "chưa có test chạy hook" ở FT-23/FT-51.
Pha 1 (audit đích danh, chỉ đọc + đo):
- F-R01 Trung — `docs/ops/repository-settings.md` phát sang đích nguyên văn, khối fenced đầu khai 7 job
  `ci.yml` của RIÊNG repo khung; `ci-target.yml` phát cho đích chỉ có job `gate` → vitest drop-in
  `ci-workflow-policy.test.ts` ĐỎ ngay trên fixture copy sạch: 2 failed / 36 passed ("Job đã khai nhưng không
  còn tồn tại trong ci.yml": framework-lint, framework-lint-windows, docs-consistency, copy-framework-smoke,
  progress-freshness, protection-guard). Trên cây khung: 25/25 pass. (vitest 3.2.4, node 22.22.0, fixture scratchpad.)
- F-R02 Thấp — 3 template mồ côi: `DATA-GOVERNANCE`, `GOVERNANCE`, `SUPPORT` không được tài liệu hướng dẫn
  nào (ngoài templates/, work/, reports/, changelog/) nhắc tới theo tên file; chỉ comment trong manifest. FT-43 ❌.
- F-R03 Thấp — `session-guide.sh`, `auto-format.sh` chưa có test chạy hook với payload thật (FT-23/FT-51).
- F-R04 Thông tin — tài liệu trạng thái lệch: FEATURE-MAP FT-23/43/44/51, COMPREHENSIVE-AUDIT-STATUS header còn
  "đang sửa"; radar liệt kê 3 file > 400 dòng; P-B11/P-C12 giữ; hosted CI/pilot/harness ngoài chưa kiểm được ở đây.
Pha 2 (kế hoạch): W-01 fix F-R01 (copy-time lọc khối theo job của `ci-target.yml`, test đỏ-trước trong
`test-copy-framework.sh`, cả bash + pwsh) · W-02 F-R02+F-R03 (docs-consistency mục 12 + negative test; con trỏ
template; ca 11–12 `test-hooks-session.sh`) · W-03 closeout (F-R04, plan/report/PROGRESS/audit-status).
W-01 ∥ W-02 (worker, worktree riêng, file không chung) → phiên chính review, `git apply --index`, PR tuần tự.

## Quyết định và bằng chứng

- Approved for implementation — phiên chính duyệt theo ủy quyền của chủ repo ngày 2026-10-07; ngày duyệt
  2026-10-09; phạm vi: W-01..W-03 như trên; căn cứ: F-R01 tái hiện bằng vitest trên fixture (log scratchpad),
  F-R02 đo bằng `git grep -l -F <tên template>` (3 tên không có kết quả), F-R03 đo bằng grep tên hook trong
  `scripts/test-*.sh`/`tests/*.py` (không có ca chạy hook).
- Không đổi ADR-0003: bản kê hai chiều của repo khung giữ nguyên; chỉ bản PHÁT cho đích được lọc theo job thật
  của workflow phát kèm.

## Lần thử / blocker

(chưa có)

## Bàn giao / bước tiếp theo

Viết brief cho 2 worker (W-01, W-02); sau khi nhận patch: review, áp, chạy `scripts/dev-task.sh gate`, PR.
