# Công việc: Audit toàn diện — nâng tự động hóa cho dự án đích lên tối đa, giữ chất lượng tối đa

- Work ID: 2026-10-09-audit-full-automation
- Yêu cầu / outcome: người dùng: "audit toàn diện, nâng auto ở repo đích lên tối đa, giữ chất lượng tối đa" → chạy `/audit-full` (CLAUDE.md §1b(c)) GIAI ĐOẠN 1 trên chính repo khung theo năng lực khung, trọng tâm bề mặt tự động hóa phát sang đích (settings/hooks/agents/commands/CI drop-ins/copy-framework); xuất báo cáo 12 nhóm có ID cố định; GIAI ĐOẠN 2 từng PR nhỏ qua `/gate` sau khi phiên chính duyệt theo §3d.
- Trạng thái: Active (GIAI ĐOẠN 1 xong 2026-10-09; GIAI ĐOẠN 2 đang chạy theo PLAN.md)
- Chủ trì / writer: phiên chính (Fable 5.1); 5 auditor read-only song song (claude-code-guide xác minh tài liệu Claude Code; 4 general-purpose: Nhóm 8+tự động hóa · Nhóm 1/9/12 · Nhóm 2/7/11 · Nhóm 3/4).
- Mức rủi ro / số PR: L; **9 PR** theo `docs/work/2026-10-09-audit-full-automation/PLAN.md` (check-plan OK, 13 việc), 4 đợt, WIP ≤ 3, từ 2 PR giao subagent (worktree riêng), phiên chính tích hợp.
- Scope / non-goal: Scope = repo khung + những gì nó phát cho đích. Non-goal = không sửa gì ở GIAI ĐOẠN 1; không bật thứ cần secret/chi phí mới (API key, PAT) mà không có quyết định của chủ repo (§3d: secret/quyền mới → BLOCKED).
- Spec / goal / issue: `docs/ops/comprehensive-audit-prompt.md` (quy trình); trạng thái `docs/ops/COMPREHENSIVE-AUDIT-STATUS.md`.
- Nhánh / base SHA / thời điểm reconcile: `main` @ `2e80d2f` (origin/main, sau #245), reconcile 2026-10-09 đầu phiên (pull --ff-only từ 9d589c0).

## Kế hoạch và phân công

GIAI ĐOẠN 1 (chỉ đọc + đo): phiên chính đọc bề mặt tự động hóa + chạy engine (radar, sweep, docs-consistency, ci-policy, doctor); 5 auditor song song, mỗi auditor một brief read-only, trả về phát hiện có file:dòng. Phiên chính đối chiếu, loại phát hiện không căn cứ, gán ID F-xxx, xếp ưu tiên toàn cục, ghi STATUS + báo cáo `docs/reports/2026-10-09-audit-full-automation.md`, rồi duyệt kế hoạch GIAI ĐOẠN 2 theo §3d.

## Quyết định và bằng chứng

- Bước -1: repo khung ≠ template trống — code thật = scripts/hooks/CI; tiền lệ nhiều chu kỳ audit khung (STATUS). Chọn: tiếp tục audit · loại: dừng theo Bước -1 · bậc 1 (đúng: audit đối tượng có code thật).
- Bước 0: STATUS đã có, mọi chu kỳ đều ĐÓNG, base đổi (2e80d2f) và trọng tâm mới → chọn (a) quét lại từ đầu · loại (b) tiếp tục · bậc 3 (kiểm được: kết quả cũ không gắn base hiện tại).
- GIAI ĐOẠN 1 xong: báo cáo `docs/reports/2026-10-09-audit-full-automation.md` (Cao 7 · Trung 19 · Thấp 14), STATUS reset 12 nhóm (5/6/10 ➖). Ba phát hiện Cao đo được đã tự tái hiện (hook lọt 7/8 ca; copy lần 2 → 60 `.framework-new`, self-test đích đỏ 2 ca).
- **Duyệt kế hoạch GIAI ĐOẠN 2 — "Approved for implementation — phiên chính duyệt theo ủy quyền của chủ repo ngày 2026-10-07", ngày duyệt 2026-10-09, phạm vi: 13 việc/9 PR trong PLAN.md; bằng chứng: báo cáo + tái hiện ở trên.** Thứ tự: hàng rào trước tự động hóa (bậc 1 §3d) → copy/CI đích không đỏ → bot/release tự merge → allow list → tài liệu.
- Quyết định: PR-5/PR-7 dùng type `ci:` (thay đổi hạ tầng CI drop-in, không phải tính năng sản phẩm; tiền lệ #244) · loại: `feat:` + spec L + goal · bậc 2 (ít nghi thức, cổng chất lượng không đổi).
- Quyết định: KHÔNG bake `defaultMode: dontAsk` vào settings dùng chung (từ chối mọi thứ ngoài allow cho mọi phiên tương tác) · chọn: mở rộng allow có chủ đích + ghi `dontAsk` là opt-in ở `settings.local.json.example` · bậc 1 (đúng cho cả phiên tương tác).
- Quyết định: thu hẹp an toàn bằng `deny` đích danh lệnh publish/mất dữ liệu thay vì cắt allow build/test (F-S07) · bậc 2 (ít đổi, giữ tự động).
- Quyết định: `Edit/Write(.claude/**, .github/workflows/**, 3 script cổng)` chuyển `ask` (F-S02) dù làm phiên chính phải xác nhận khi sửa hàng rào · loại: giữ allow · bậc 1 (bảo mật).
- Engine 2026-10-09 @2e80d2f: radar 100/100 (46/46 script có cổng, 24/24 spec), sweep 🔴 0 🟡 2 (đứng sau origin 1 commit — đã pull; 4 nhánh local đã merge còn sót), docs-consistency OK, ci-policy CP-1..6 OK, `dev-task.sh doctor` BLOCKED trên máy này vì thiếu `shellcheck` (giới hạn máy, không phải lỗi khung).

## Lần thử / blocker

- Máy Windows thiếu `shellcheck` → `dev-task.sh doctor` BLOCKED; đã cài `koalaman.shellcheck` qua winget (user-scope) 2026-10-09 để cổng local chạy được.
- `test-hooks-session.sh` đỏ giả 12 ca trên Windows (F-Q6) → cổng tổng local đỏ cho tới khi PR-3 merge; commit trong thời gian đó nộp output các suite liên quan + CI Linux/Windows là cổng thật (ghi ở báo cáo §7 từng PR).
- BLOCKED cần chủ repo (secret/chi phí): `RELEASE_PLEASE_TOKEN`; `claude-code-action`; bật Allow auto-merge/auto-delete ở đích.

## Bàn giao / bước tiếp theo

- Đợt 1 (PR-1 hooks, PR-2 copy-framework, PR-3 test-hooks-session) đang chạy bằng 3 worker worktree; sau khi worker trả: phiên chính đọc diff, chạy lại cổng, commit, mở PR (Work ID này), auto-merge; rồi đợt 2.

## Nghiệm thu cuối (chỉ điền khi đủ bằng chứng)

- (chưa)

- 2026-10-09 (tích hợp PR-1): #248 merge sau rebase (xung đột PROGRESS.md với #246/#247, giữ cả hai phía). Khi commit PR-1
  ở checkout chính, `pre-commit-gate.sh` → `dev-task.sh gate` BLOCKED "không đọc được working tree": `git ls-files -o` liệt kê
  `.claude/worktrees/agent-*/` (repo lồng) → `hash-object --stdin-paths` "Unable to hash (NULL)"; hook dòng 103 `wc -c <dir`
  in "0
0" → `[: integer expected`. Quyết: thêm `.claude/worktrees/` vào `.gitignore` ngay trong PR-1 (ngoại lệ 3, config
  thuần; T12 bỏ mục này). Nợ ghi vào T12: `untracked_listing` (dev-task) và vòng `wc` của hook phải bỏ qua đường dẫn thư mục
  (`/$`) kèm test tái hiện — không sửa trong PR-1 để giữ PR nhỏ. Cổng tổng T1/T3 chạy nền trong worktree (log `$TMP/gate/`).
- 2026-10-09 (PR-1, lần commit 2): cổng commit đỏ oan ở `check-shell-complexity.sh` — `find .` quét vào `.claude/worktrees/`
  và bắt probe tạm `zz-probe-shcc-*.sh` của suite đang chạy ở worktree khác (CC 47 > 45). Sửa trong PR-1: loại
  `./.claude/worktrees/*` khỏi phép đo + ca 4b `test-check-shell-complexity.sh` (đỏ trước: rc=1). Ghi T12: `arch-health-radar.py`
  `EXCLUDE_DIRS` chưa loại `.claude/worktrees` (chỉ lệch số đếm báo cáo, không chặn) → thêm kèm ca test khi làm T12.
- 2026-10-10 (đợt 2, PR-4 = T4→T5, phiên chính tự làm trong worktree `chore/settings-automation` từ `main` @ abc3058; PR-2/PR-3
  vẫn staged trong worktree worker của phiên khác — không đụng). T4: mục 19 `test-hooks-gate.sh` viết trước, chạy ĐỎ 2 ca
  (thiếu `enabledMcpjsonServers`, thiếu deny `git push -f*`) → sửa settings (allow 77 · ask 17 · deny 50, hai file giống hệt,
  mục ask `git push -f *` xoá vì deny `-f*` thắng) → xanh. T5: hai negative test ở `test-check-scripts.sh` chạy ĐỎ trước
  (suite báo "FAIL — 2 ca hỏng" khi chưa có mục 14) → thêm mục 14 `check-docs-consistency.sh` (hai chiều settings ↔ bảng Hook)
  → mục 14 xanh, bảng Hook 9/9, shellcheck + CC xanh. Phát sinh: thư mục rác tên là output `git status` xuất hiện trong
  worktree khi máy quá tải (EAGAIN, 1229 tiến trình) — đã xoá; chưa rõ suite nào tạo, ghi T12 rà `mkdir -p "$(…)"`.
- 2026-10-10 (đợt 1, PR-2 = T2 tích hợp): worker trả xong trong worktree `agent-af90…` (branch `fix/copy-framework-idempotent`, staged,
  im lặng ~3 giờ); phiên chính xuất patch staged → worktree riêng `fix/copy-framework-idempotent-pr` từ `main` @ c7ca562 (sau #260),
  không đụng cây worker (TRAPS 63). Cổng: shellcheck/CC/docs/test-hooks-gate OK; `test-copy-framework.sh` (pwsh) **lộ lỗi của PR-4**:
  mục 19 so `settings.json` với `settings-shared-default.json` nhưng đích chỉ nhận `settings.json` → smoke đích đỏ. Sửa trong PR-2
  (bỏ qua phép so khi không có bản shared-default; đỏ-trước = chính smoke) → smoke đích xanh. Ghi T12: mọi ca test-hooks-gate mới
  phải tự hỏi "ở đích file này có không?".

- 2026-10-10 (đợt 2, PR-5 = T6): #264 merge xong mới làm (phụ thuộc T2, cùng sửa `test-copy-framework.sh`). Đỏ-trước:
  `check_ci_target_stacks` chạy trên template cũ → 17 FAIL × 2 ca (bash/pwsh: thiếu 15 `hashFiles`, thiếu `protection-guard`,
  thiếu `gate` `if: always()`); thay `ci-target.yml` (3 job `checks`/`protection-guard`/`gate`, 18 `uses:` ghim SHA) → smoke
  REQUIRE_PWSH=1 rc=0, adoption-smoke OK, check-ci-policy CP-1..6 OK, pyyaml parse OK. **Lệch spec có chủ đích:** (1) khối
  fenced đầu của `repository-settings.md` phải liệt kê cả `checks` + `protection-guard` — CP-1 (vitest drop-in + `check_structure`)
  so HAI CHIỀU tập job thật ↔ khối, không phải "required checks"; ruleset vẫn chỉ khoá `gate`+`metadata`, đã ghi rõ ở đoạn dẫn.
  (2) `allow_auto_merge`/`delete_branch_on_merge` trả `null` với `GITHUB_TOKEN` thiếu quyền → `::warning` + exit 0, không đỏ oan.
  (3) Đếm lại: 17 stack (npm + pip + 15 khác), spec viết "15" là số stack *khác* — TRAPS 57 ghi đúng 15 khác.
- 2026-10-10 (đợt 2, PR-6 = T7, route: standard → worker trong worktree riêng, phiên chính rebase lên `main` sau #265 và chạy lại
  mọi cổng): đỏ-trước 3 suite (test-copy-framework: hooksPath "chưa đặt" + dropin CODEOWNERS còn `@seeker19110`, bash+pwsh;
  test-maintenance-sweep 2 ca 🟡; test-dev-task ca doctor cảnh báo) → sửa `copy-framework.sh/.ps1` (`--no-hooks`/`-NoHooks`,
  `enable_hooks_path`/`Enable-HooksPath`, CODEOWNERS stage → `@OWNER-CHANGE-ME`), `dev-task.sh` `hooks_path_warning`,
  `maintenance-sweep.sh` 2 🟡 mảng Cổng → xanh. Phát sinh: bật hooksPath ở đích làm `test-adoption-smoke.sh` đỏ 6 ca (fixture
  commit trên `master` bị chính `pre-commit` của khung chặn) → fixture copy với `--no-hooks` (đúng mục đích của cờ). Quyết định cục
  bộ của worker giữ: đích không `.git` → in hướng dẫn, không lỗi; hooksPath đã đặt giá trị khác → giữ + cảnh báo. PROGRESS checkpoint
  sau #264/#265 gộp vào PR này (§3e). Để lại T12: ca test cho `--no-hooks` và "hooksPath đã đặt giá trị khác".
