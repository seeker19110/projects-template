# Feature spec: Hàng rào commit (main / bí mật / file lớn), khuôn push xoá main, ngữ cảnh phiên gọn

| Thuộc tính | Giá trị |
| --- | --- |
| Issue / Goal | `docs/reports/2026-09-23-de-xuat-nang-cap-khung-toan-dien.md` — Đợt 2 (C5, C10, T5, T17) |
| Spec owner | Phiên Claude Code (Tầng 1) |
| State | **Approved for implementation** |
| Approver / date | Người dùng (chủ repo) duyệt kế hoạch 7 đợt qua chat, 2026-09-23 ("triển khai nâng cấp đi") |
| Last updated | 2026-09-23 |

> Không code khi chưa **Approved for implementation**.

## 1. Problem, user và evidence

- **Luật có, cổng không.** `CLAUDE.md` §8 cấm commit/push thẳng nhánh chính; `TRAPS.md` mục 14 ghi sự cố thật
  (`checkout -b` hỏng → commit rơi vào `main`) và tự ghi "không có cổng máy". Hook hiện chỉ chặn force-push/reset.
- **Bí mật vào lịch sử trước khi ai kịp quét.** `maintenance-sweep.sh` quét bí mật định kỳ — lúc đó khoá đã nằm
  trong git; không hàng rào nào chặn ở thời điểm `git commit`.
- **Ngữ cảnh khởi đầu 60 KB.** Hook `session-resume.sh` `cat` nguyên `PROGRESS.md` (58 KB, 21 khối "Giai đoạn trước
  đó") mỗi phiên — trái `quality-supplements-group1.md` §9 và `models-and-automation.md` §5; `docs/changelog/` là luật
  nhưng thư mục không tồn tại.
- **Khuôn push xoá main lọt.** `git push origin +main`, `:main`, `--delete main` không có chữ `--force` nên khuôn 1
  của `block-dangerous-git.sh` không bắt.

## 2. Outcome, baseline, target và guardrails

| Đo | Baseline (2026-09-23) | Target |
| --- | --- | --- |
| `session-resume.sh` output (repo khung) | 60 058 byte | ≤ 8 000 byte, có 4 mục cần cho "tiếp tục" |
| Khối "Giai đoạn trước đó" trong `PROGRESS.md` | 21 | ≤ 1 (PF-4 chặn) |
| Commit trên `main` qua Claude Code | không chặn | exit 2, bỏ qua tường minh `ALLOW_COMMIT_ON_MAIN=1` |
| Bí mật / file > 1 MB trong diff staged | không chặn | exit 2 |
| `push +main` / `:main` / `--delete main` | lọt | exit 2 (khuôn 5) |

Guardrails: mọi hook vẫn **fail-open có cảnh báo** khi thiếu `jq`; không chặn oan diff sạch trên nhánh riêng, refspec
`+feat/x`, `--delete feat/x`, `push origin main` thường (ruleset đã chặn).

## 3. Research current state

Đọc thật: `.claude/hooks/{pre-commit-gate,block-dangerous-git,session-resume}.sh`, `scripts/test-hooks-gate.sh`,
`scripts/check-progress-freshness.sh` (PF-1..3), `PROGRESS.md`, `quality-supplements-group1.md` §9,
`standard-delivery.md` tầng ⑤. Claude Code hooks: PreToolUse exit 2 = chặn, SessionStart `additionalContext`
(code.claude.com/docs/en/hooks, 2026-09-23).

## 4. Alternatives và decision

| Option | Benefits | Cost/risk | Decision |
| --- | --- | --- | --- |
| Do nothing | 0 | lặp TRAPS 14; 15k token/phiên đốt vào lịch sử | ✗ |
| A. Hook Claude Code (chọn) | dùng lại 2 hook + test đã có; chặn trước khi vào lịch sử | chỉ Claude Code (harness khác: Đợt 6 `.githooks`) | ✓ |
| B. Chỉ luật + ruleset | ruleset đã chặn push main | không chặn commit cục bộ/bí mật; không giảm ngữ cảnh | ✗ |

## 5. Scope / non-goals

Trong phạm vi: 3 hook, PF-4, tách lịch sử `PROGRESS.md` → `docs/changelog/0001-2026-09-23-lich-su-giai-doan-den-2026-09-23.md`, test. **Ngoài:** `.githooks`
harness-agnostic (Đợt 6), hook `SubagentStop`/`PreCompact` (Đợt 5), gitleaks đầy đủ (dùng regex sẵn có của sweep).

## 6. User journeys và mọi state

- Commit trên nhánh riêng, diff sạch → qua (như cũ). Trên `main` → chặn kèm hướng dẫn `git switch -c`. Cố ý →
  `ALLOW_COMMIT_ON_MAIN=1`. Thiếu `jq` → fail-open có cảnh báo. Không có `dev-task.sh` → chỉ các kiểm mới chạy.
- Mở phiên: ngữ cảnh ≤ 8 KB; `PROGRESS.md` quá dài → cắt ở trần và nói rõ "ĐÃ CẮT".

## 7. Functional requirements

FR-1 `pre-commit-gate.sh` chặn `git commit` khi `branch --show-current` ∈ {main, master} trừ `ALLOW_COMMIT_ON_MAIN=1`.
FR-2 Chặn khi `git diff --cached -U0` có dòng thêm khớp regex bí mật (cùng mẫu sweep) hoặc file staged > 1 MB.
FR-3 `block-dangerous-git.sh` khuôn 5: token `+…:?main|master`, `:main|master`, hoặc `--delete|-d` + `main|master`.
FR-4 `session-resume.sh` chỉ nạp 4 section, bỏ khối "Giai đoạn trước đó", trần `SESSION_RESUME_MAX_BYTES` (8000).
FR-5 `check-progress-freshness.sh` PF-4: > 1 khối "Giai đoạn trước đó" → đỏ.
FR-6 `maintain-run.sh`: harness nhận prompt qua argv chạy với stdin đóng (stub/CLI chờ stdin treo vô hạn khi gọi từ nền).

## 8. Non-functional requirements

Fail-open có cảnh báo; không thêm dependency; CC ≤ 12/hàm; ShellCheck 0 cảnh báo; chạy được Git Bash Windows.

## 9. Acceptance criteria

AC-1 `test-hooks-gate.sh` mục 11: commit trên main → 2; `ALLOW_COMMIT_ON_MAIN=1` → 0; khoá AWS staged → 2; file 1.1 MB → 2; diff sạch → 0.
AC-2 `test-hooks-gate.sh` mục 12: 5 khuôn push xoá/ghi đè main → 2; 3 ca nhánh riêng/push thường → 0.
AC-3 `test-hooks-session.sh` mục 6: có 4 mục + dòng SHA, không có lịch sử/goal/quyết định; 100 KB → ≤ 9 000 byte + "ĐÃ CẮT"; trần tuỳ chỉnh có hiệu lực.
AC-4 `test-check-scripts.sh`: PROGRESS.md thêm 2 khối "trước đó" → PF-4 đỏ; baseline xanh.
AC-5 `test-maintain-run.sh` xanh cả khi stdin của tiến trình gọi không đóng.

## 10. UX/content/accessibility

Thông điệp chặn nêu luật + cách làm đúng + cách bỏ qua tường minh (một khuôn với các hook hiện có).

## 11. Architecture và code touchpoints

`.claude/hooks/pre-commit-gate.sh`, `.claude/hooks/block-dangerous-git.sh`, `.claude/hooks/session-resume.sh`,
`scripts/maintain-run.sh`, `scripts/check-progress-freshness.sh`, `scripts/test-hooks-gate.sh`,
`scripts/test-hooks-session.sh`, `scripts/test-check-scripts.sh`, `PROGRESS.md`, `docs/changelog/0001-2026-09-23-lich-su-giai-doan-den-2026-09-23.md`,
`TRAPS.md` mục 14 (cập nhật "cổng chốt chặn"), `CODEMAP.md`, `CHANGELOG.md`.

## 12. API/event contract

n-a (hook stdin JSON của Claude Code; không đổi contract).

## 13. Data contract/migration

`PROGRESS.md`: khối lịch sử chuyển nguyên văn sang `docs/changelog/0001-2026-09-23-lich-su-giai-doan-den-2026-09-23.md`;
không mất nội dung (diff đối chiếu). Không có DB.

## 14. Security/privacy/abuse cases

Regex bí mật chỉ chạy trên diff staged cục bộ, không gửi đi đâu. Bỏ qua bằng biến môi trường tường minh, không bằng cờ ẩn.

## 15. Rollout, observability, rollback

Có hiệu lực ngay khi merge (hook copy sang dự án đích qua `copy-framework`). Rollback: revert PR. Quan sát: số lần chặn
hiện trên stderr của Claude Code.
