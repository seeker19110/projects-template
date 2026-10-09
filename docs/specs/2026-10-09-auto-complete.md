# Feature spec: `/auto-complete` — làm tới xong, phiên chính tự quyết theo thứ tự ưu tiên

| Thuộc tính | Giá trị |
| --- | --- |
| Issue / Goal | Yêu cầu chủ repo 2026-10-09: "1 agent thay tôi quyết định tất cả khi ở chế độ /auto-complete, ưu tiên chất lượng cao, ít code, bảo mật"; "gộp cả 2 vào" (`/auto` + `/completion`). Hồ sơ `docs/work/2026-10-09-auto-complete/working.md` |
| Spec owner | Phiên chính |
| State | **Approved for implementation** |
| Approver / date | Phiên chính duyệt theo ủy quyền toàn cục (`standard-delivery.md` §3d); 2026-10-09 |
| Last updated | 2026-10-09 |

> Spec gọn (mức M): một PR, chỉ tài liệu/lệnh/test hợp đồng, không đổi script.

## 1. Problem, user và evidence

Chủ repo muốn một lượt chạy đầu-cuối không phải trả lời cổng nào, với thứ tự ưu tiên rõ. Hiện trạng: ủy quyền §3d
đã có nhưng (a) không xếp hạng khi các mục tiêu xung đột (ít code vs kiểm được vs nhanh), (b) `/auto` và `/completion`
là hai lượt riêng, mỗi lệnh còn một cổng "chốt/duyệt" viết như điểm dừng, (c) không có nơi bắt buộc ghi lại quyết định
đã tự duyệt để người dùng audit sau. Ràng buộc harness đã chứng minh (`docs/reports/2026-10-09-agent-acceptance.md`
đợt 3): subagent Claude Code không có tool `Agent`, không commit/merge → "agent quyết định" chỉ có thể là **phiên chính**.

| Đã có và sâu hơn | Đã có nhưng nông hơn | Chưa có / quyết định |
| --- | --- | --- |
| Ủy quyền §3d, §9, stop conditions §8, TDD/gate/feature gate: giữ nguyên | §3d chưa xếp hạng ưu tiên khi xung đột; hai lệnh chưa nối: thêm thang 4 bậc + lệnh mỏng nối hai playbook | Agent `decider` riêng: không làm — harness không cho subagent điều phối; thêm agent chỉ thêm một hop tốn token. Xem lại nếu harness cấp nested agent |

## 2. Outcome, baseline, target và guardrails

- Một lệnh `/auto-complete` chạy `/auto` → `/completion` liền, phiên chính tự duyệt hai cổng theo §3d, ghi từng
  quyết định một dòng vào `working.md`, chỉ dừng ở §9/§8.
- Thang ưu tiên cố định ở §3d: đúng+bảo mật+không mất dữ liệu › ít hơn › kiểm được › nhanh/rẻ; không đánh đổi bậc trên.
- Guardrails: không hạ cổng nào; danh sách "không bao giờ tự quyết" (dữ liệu thật, thanh toán, deploy, secret, ngoài
  scope, >3 lần cùng failure) giữ nguyên từ §3d/§8.

## 5. Scope / non-goals

Trong: `standard-delivery.md` §3d (thang + dòng ghi quyết định), `.claude/commands/auto-complete.md`, con trỏ ở
`CLAUDE.md` §1, `AGENTS.md`, `FEATURE-MAP` FT-66, `framework/README.md`, test hợp đồng. Ngoài: sửa `/auto`/`/completion`
(giữ nguyên, lệnh mới chỉ nối), agent mới, cổng máy đếm quyết định.

## 9. Acceptance criteria

- AC-1: §3d có 4 bậc ưu tiên đúng thứ tự, câu "không đánh đổi bậc trên lấy bậc dưới" và yêu cầu ghi vào `working.md`.
- AC-2: `auto-complete.md` trỏ `/auto`, `/completion`, §3d, §8, `--check-plan`, Definition of Complete và giữ các mốc không tự quyết.
- AC-3: `CLAUDE.md` và `AGENTS.md` nhắc `/auto-complete`; lệnh ↔ CLAUDE.md khớp hai chiều.

| AC | Bằng chứng |
| --- | --- |
| AC-1 | `tests/test_adaptive_process.py::test_contract_ranks_priorities_in_fixed_order` |
| AC-2 | `tests/test_adaptive_process.py::test_auto_complete_chains_existing_playbooks_under_3d` |
| AC-3 | `tests/test_adaptive_process.py::test_entry_docs_mention_auto_complete`, `scripts/check-docs-consistency.sh` |

## 11. Architecture và code touchpoints

Chỉ tài liệu + lệnh + test hợp đồng (ngoại lệ TDD số 3 của `CLAUDE.md` §3.6: không có nhánh logic chạy).

## Approval

Approved for implementation — phiên chính duyệt theo ủy quyền chủ repo ngày 2026-10-09; một PR, không hạ cổng.
