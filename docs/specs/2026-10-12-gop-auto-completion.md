# Feature spec: gộp `/auto` + `/completion` vào `/auto-complete`

| Thuộc tính | Giá trị |
| --- | --- |
| Issue / Goal | Yêu cầu chủ repo 2026-10-12: "bỏ /auto /complete, tích hợp hết vào /auto-complete". Hồ sơ `docs/work/2026-10-12-gop-auto-completion/working.md` |
| Spec owner | Phiên chính |
| State | **Approved for implementation** |
| Approver / date | Phiên chính duyệt theo ủy quyền toàn cục (`standard-delivery.md` §3d) trên yêu cầu tường minh của chủ repo; 2026-10-12 |
| Last updated | 2026-10-12 |

> Spec gọn (mức M): một PR, lệnh/tài liệu/hook marker + một mục cổng docs-consistency + test hợp đồng.

## 1. Problem, user và evidence

Ba lệnh chồng nhau: `/auto` (kế hoạch → thực thi), `/completion` (audit → hội tụ → DoC, dừng chờ duyệt) và
`/auto-complete` (nối hai lệnh kia "nguyên văn", tự duyệt). Người dùng phải chọn giữa ba điểm vào gần nghĩa; `/auto-complete`
phụ thuộc hai file khác nên đọc một lệnh phải mở ba file. Chủ repo chốt: chỉ giữ `/auto-complete`.

## 2. Outcome, baseline, target và guardrails

- Baseline: 17 lệnh; `/auto` + `/completion` được trỏ ở ~50 dòng trong ~25 file đang dùng (đo bằng mục 5c, chạy đỏ trước khi sửa).
- Target: 15 lệnh; `auto-complete.md` tự chứa (điểm vào A kế hoạch→thực thi / B hoàn thiện / C bàn giao, wind-down/resume);
  0 con trỏ cũ ngoài lịch sử (spec/báo cáo/ADR/hồ sơ/changelog/TRAPS/CHANGELOG/PROGRESS).
- Guardrails: không hạ cổng nào; `project-completion.md` giữ nguyên là playbook 5 pha; danh sách "không bao giờ tự quyết" giữ nguyên.
- Đánh đổi đã chấp nhận: biến thể "hoàn thiện nhưng dừng chờ người dùng duyệt kế hoạch" của `/completion` không còn lệnh riêng —
  người dùng muốn duyệt tay thì nói khi giao việc (ghi ở `project-completion.md`).

## 5. Scope / non-goals

Trong: xoá `.claude/commands/auto.md`, `completion.md`; viết lại `auto-complete.md`; con trỏ ở `CLAUDE.md`, `AGENTS.md`, README,
`CODEMAP.md`, `FEATURE-MAP`, playbook/ops, `copy-framework.sh`/`.ps1`, `session-guide.sh` (marker + gợi ý); mục 5c docs-consistency
+ ca âm; test hợp đồng. Ngoài: sửa ADR cũ (giữ nguyên văn; `.claude/commands/auto.md` vào `ALLOW_MISSING_PATH` cho ADR-0011),
đổi ID FEATURE-MAP (FT-03/FT-09 giữ ID, điểm vào thành `/auto-complete` A/B), tách `test-check-scripts.sh` (> 400 dòng có từ trước).

## 9. Acceptance criteria

- AC-1: `.claude/commands/auto.md` và `completion.md` không tồn tại; `auto-complete.md` chứa đủ chuỗi cũ + `project-completion.md`, Pha 0–4, `COMPLETION-PLAN.md`, `usage-guard`, §3c.
- AC-2: không tài liệu/hook/script đang dùng nào trỏ `/auto` hoặc `/completion` (mục 5c xanh trên repo thật, đỏ trên ca âm).
- AC-3: lệnh ↔ CLAUDE.md khớp hai chiều (mục 3) và `session-guide.sh` vẫn nhận ra dự án dùng khung.

| AC | Bằng chứng |
| --- | --- |
| AC-1 | `tests/test_adaptive_process.py::test_merged_commands_stay_merged`, `tests/test_adaptive_process.py::test_auto_complete_chains_existing_playbooks_under_3d` |
| AC-2 | `scripts/check-docs-consistency.sh` mục 5c; ca âm trong `scripts/test-check-scripts.sh` |
| AC-3 | `scripts/check-docs-consistency.sh` mục 3; `scripts/test-hooks-session.sh` |

## 11. Architecture và code touchpoints

Tài liệu + lệnh + một mục cổng (`forbid`, cùng khuôn 5/5b) + đổi đường dẫn marker trong hook. Mục 5c viết và chạy đỏ trước khi sửa
tài liệu (đỏ → sửa → xanh); đổi marker hook là thay đổi cơ học (ngoại lệ số 2, `CLAUDE.md` §3.6).

## Approval

Approved for implementation — phiên chính duyệt theo ủy quyền §3d trên yêu cầu tường minh của chủ repo ngày 2026-10-12; một PR, không hạ cổng.
