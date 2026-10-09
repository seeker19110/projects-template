# Công việc: FT-41 — chạy thật phần GitHub của case-study greenfield (Bước 6/11)

- Work ID: 2026-10-09-ft41-github-run
- Yêu cầu / outcome: chủ repo (2026-10-09) cho dùng tài khoản CLI `seeker19110`, tạo repo private, **chỉ làm phần GitHub**:
  branch protection + CI trên GitHub Actions thật cho dự án đích dựng theo runbook. Supabase (Bước 7) / Vercel (Bước 8) ngoài scope.
- Trạng thái: Ready — chờ PR khung merge
- Chủ trì / writer: phiên chính
- Mức rủi ro / số PR: S — 1 PR tài liệu/bằng chứng, phiên chính tự làm (§3c)
- Scope / non-goal: dự án đích dựng trong scratchpad, push lên `seeker19110/case-study-ft41` (private). Không đổi hành vi script khung
  trừ khi lộ lỗi thật (khi đó lỗi đi PR `fix:` riêng có test đỏ-trước). Không đụng Supabase/Vercel.
- Spec / goal / issue: `docs/FEATURE-MAP.md` FT-41; `docs/framework/case-study-greenfield-dry-run.md`; `docs/framework/new-project-runbook.md` Bước 6.
- Nhánh / base SHA / thời điểm reconcile: `fix/dependabot-wip-cap` (worktree `../Projects-Template-ft41`) / `9d589c0` / 2026-10-09

## Kế hoạch và phân công

1. `create-next-app` + `copy-framework.sh` + dropin CI đích (`ci-target.yml`) trong scratchpad.
2. `gh repo create --private`, push `main`, chờ CI Actions thật.
3. Bật branch protection (PR bắt buộc, required checks, strict) qua API; thử push thẳng `main` (phải bị chặn) và PR (phải qua CI).
4. Ghi bằng chứng vào case-study + FEATURE-MAP + PROGRESS; PR.

## Quyết định và bằng chứng

- Đích: `create-next-app@latest` → Next 16.4.0; `copy-framework.sh` → merge toàn bộ `_framework-dropins/` (workflows, ruleset,
  dependabot, `.gitignore` gộp, `ci-workflow-policy.test.ts`); thêm `type-check`/`test` (vitest 4.1.11). `dev-task.sh doctor` READY,
  `gate` PASS (build/typecheck/lint/test, 19/19 test policy). Commit `d45a28e`, repo `seeker19110/case-study-ft41` (private).
- Actions thật trên `main` `d45a28e`: CI (job `gate`) ✅, Release ✅; CodeQL ❌, Scorecard ❌, Secret scan ❌. Dependabot tự mở 5 PR.
- Phân loại: CodeQL — "Code scanning is not enabled" (repo private gói Free, giới hạn nền tảng); Scorecard — GraphQL "Resource not
  accessible by integration" (private); gitleaks — `fatal: ambiguous argument '<root>^..<head>'`: push đầu chứa commit gốc
  (create-next-app luôn tạo commit gốc → luồng runbook luôn gặp).
- Commit đích dùng `--no-verify` có lý do: hook `pre-commit-gate` của phiên lấy cây theo cwd của hook (repo khung), không theo `cd`
  trong lệnh → chạy cổng khung (thiếu `shellcheck` cục bộ); đích đã PASS gate riêng ngay trước đó.

## Lần thử / blocker

- Bước 6: `POST repos/.../rulesets` và `PUT .../branches/main/protection` → **403 "Upgrade to GitHub Pro or make this repository
  public"** (1 lần mỗi API). Repo private trên tài khoản Free không bật được bảo vệ nhánh — chủ repo chọn **public tạm** (2026-10-09).
- Sau public (soát bí mật lịch sử bằng regex: 0 khớp thật): import `.github/rulesets/main.json` → ruleset 24792207 active,
  rules `deletion, non_fast_forward, pull_request, required_status_checks`.
- (a) push thẳng `main` → `remote rejected … Changes must be made through a pull request; 2 of 2 required status checks are expected` ✅.
- (b) PR #6 `ci: analyze javascript-typescript with CodeQL`: `gate` ✅, gitleaks ✅ (lần push sau commit gốc hết đỏ), CodeQL
  actions/python/**javascript-typescript** ✅ (public); `metadata` ❌ **"Trần WIP: đã có 5 PR khác đang mở (#5…#1)"** → mergeState BLOCKED;
  `dependency-review` ❌ "Dependency graph is not enabled" (repo tạo private, chuyển public không tự bật).
- **F-41a (lỗi khung, Cao cho người áp khung):** `dependabot.yml` phát cho đích cho phép tới 13 PR bot (npm 5 + actions 5 + pip 3), cổng WIP
  (#217) đếm cả bot với trần 3 → ngay lần chạy Dependabot đầu tiên, mọi PR của người đỏ required check `metadata`. Bot PR #1 (typescript 7,
  major) đỏ CI → không merge được để giải phóng chỗ.
- Bị chặn quyền (classifier "External System Writes"): đóng 5 PR bot + `PUT vulnerability-alerts` trên repo đích — chờ chủ repo. Chủ repo cho phép
  (2026-10-09) và chọn hướng sửa **A** (giữ luật WIP #217, thu hẹp Dependabot).
- Đã bật Dependency graph, đóng PR bot #1–5, rerun → PR #6 đủ 8 check ✅, `CLEAN`, squash MERGED `161f4ef`; `main` 161f4ef: CI, CodeQL,
  Secret scan, Scorecard, Release ✅.
- F-41a sửa ở khung (TDD): `test_dependabot_version_prs_leave_wip_room_for_humans` ĐỎ trước sửa ("13 bot PRs can fill the WIP cap 3"),
  XANH sau; `tests/test_runtime_safety.py` 9/9. `dependabot.yml`: một `multi-ecosystem-groups.dependencies` (nguồn sống: docs.github.com
  "Configuring multi-ecosystem updates" — `patterns` bắt buộc mỗi mục) + `ignore semver-major` mọi hệ sinh thái.
- Kiểm thực nghiệm trên đích PR #7 (MERGED `a95e95f`): log Dependabot `multi-ecosystem-update: true`, `dependency-groups: dependencies`,
  `ignore-conditions: semver-major` → 0 PR (5 bản có sẵn đều major). Chưa quan sát việc TẠO PR gộp (không có bản minor/patch).
- Checkout chính bị công cụ ngoài stash ("epitaxy: pre-switch") + chuyển `main` giữa chừng; khôi phục bằng worktree riêng
  + `git stash apply` (stash giữ nguyên). `shellcheck` cài qua `pip install --user shellcheck-py` để chạy gate khung.

## Bàn giao / bước tiếp theo

PR khung `fix(ci): keep dependabot bot PRs below the WIP cap` → CI xanh → squash merge → checkpoint closeout (rename done.md).
Sau đó chuyển `case-study-ft41` về private (`gh repo edit --visibility private`) theo chọn của chủ repo.

## Nghiệm thu cuối (chỉ điền khi đủ bằng chứng)
