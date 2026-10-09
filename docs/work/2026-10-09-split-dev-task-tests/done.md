# Công việc: Tách `scripts/test-dev-task.sh` vượt 400 dòng (2026-10-09)

- Work ID: 2026-10-09-split-dev-task-tests
- Yêu cầu / outcome: chủ repo "tiếp tục cho đến khi xong đi" sau #235 → mục duy nhất repo còn tự đánh dấu và kiểm được:
  radar "Việc cần làm": `scripts/test-dev-task.sh` 430 dòng (> 400). Outcome: hai suite + lib chung, số ca test giữ nguyên.
- Trạng thái: Done
- Chủ trì / writer: phiên chính
- Mức rủi ro / số PR: S, 1 PR; refactor cơ học không đổi hành vi (ngoại lệ TDD số 2)
- Nhánh / base SHA: `claude/relaxed-knuth-f1ejlq` = `origin/main` `9c30df0`

## Quyết định và bằng chứng

- Cắt theo đúng ranh giới mục đã có (7b/7c → suite evidence; 1–7, 7d, 8 ở lại); helper `fx`/`gate_case`/`gate_fixture`/
  `assert_no_marker` + thư mục tạm → `scripts/_dev-task-test-lib.sh` (cùng khuôn `scripts/_test-lib.sh`).
- Bằng chứng không đổi hành vi: bản cũ 119 ✅ / 0 ❌; bản mới 66 (`scripts/test-dev-task.sh`) + 53
  (`scripts/test-dev-task-evidence.sh`) = 119 ✅ / 0 ❌.
- Đăng ký: `.github/workflows/ci.yml` Linux + Windows gọi suite mới (CP-6); FEATURE-MAP FT-50; CODEMAP (lib mới, 14 suite dùng `_test-lib.sh`).
- Cổng commit bắt được bản đồ bằng chứng cũ: spec Approved `docs/specs/2026-10-07-lean-delivery.md` AC-3/AC-4 trỏ `test-dev-task.sh::evidence_tests|noop_tests|review_tests` → đổi sang suite mới và sinh lại `tests/contracts/test_contract_2026_10_07_lean_delivery.py` bằng `spec-compiler.sh` (không sửa tay file sinh).

## Nghiệm thu cuối

- `check-ci-policy.sh`, `check-docs-consistency.sh`, `check-progress-freshness.sh`, `test-check-scripts.sh` xanh; radar không còn "Việc cần làm"; PR qua cổng CI.
- Merge: #236 → `72afea6`; checkpoint PROGRESS/COMPREHENSIVE-AUDIT-STATUS đi PR tài liệu ngay sau (§8 bước 5).
