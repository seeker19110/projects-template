# Công việc: nghiên cứu lại quy trình khung và tối ưu (chất lượng · ít code · bảo mật · dễ vận hành)

- Work ID: 2026-10-08-process-optimization
- Yêu cầu / outcome: chủ repo yêu cầu "nghiên cứu lại quy trình, tối ưu lại tốt nhất, chất lượng tốt nhất, ít code nhất, bảo mật nhất, dễ vận hành nhất". Outcome: audit có bằng chứng trên chính bộ khung theo 4 lăng kính, kế hoạch ưu tiên, thực thi các hạng mục giá trị cao/rủi ro thấp không đổi hành vi, có test bảo vệ.
- Trạng thái: Done — PR #218 MERGED 2026-10-08; O-4b nối tiếp ở hồ sơ `docs/work/2026-10-08-process-optimization-o4b/done.md`.
- Chủ trì / writer: phiên chính; hai lượt audit chỉ-đọc giao subagent (code · tài liệu quy trình).
- Mức rủi ro / số PR: audit + refactor không đổi hành vi mức S/M; số PR chốt sau audit (mỗi hạng mục một PR nhỏ, FIFO, trần 3 PR mở).
- Scope / non-goal: scripts/, .claude/hooks, tests/, .github/workflows, tài liệu quy trình (CLAUDE/AGENTS/docs/framework/commands/agents). Non-goal: đổi luật nền (feature gate, TDD, WIP, trần token), hạ cổng, thêm dependency, thay stack, production.
- Spec / goal / issue: nối tiếp chu kỳ FC-2026-10-08 (đã đủ merge, reconcile trong PR này); phạm vi §1b CLAUDE.md chọn (a) `/audit-optimize` cho code + rà quy trình tài liệu; không feature mới nên không mở spec.
- Nhánh / base SHA / thời điểm reconcile: claude/relaxed-knuth-f1ejlq / 6643f4e52b0a0ca09e8ccee06ff4188ee4cda1a3 (= origin/main sau #217) / 2026-10-08.

## Kế hoạch và phân công

1. Reconcile W-02 (#217 MERGED) → đổi hồ sơ đơn vị thành done, cập nhật goal/report/PROGRESS/COMPLETION-PLAN.
2. Baseline đo thật: full gate --evidence, radar, maintenance --strict, CI main, quét workflow (quyền, pin SHA, injection), hook.
3. Hai audit chỉ-đọc song song: (A) trùng lặp/dead code/over-build trong code thực thi; (B) trùng lặp/mâu thuẫn/tham chiếu chết/chi phí vận hành trong tài liệu quy trình.
4. Phiên chính tổng hợp thành báo cáo `docs/reports/2026-10-08-process-optimization.md` (5 nhóm + ưu tiên), duyệt theo ủy quyền §3d, thực thi từng hạng mục qua /gate, đo trước–sau.

## Quyết định và bằng chứng

- Phạm vi chọn theo CLAUDE.md §1b: "tối ưu" + "quy trình" → audit tối ưu mã nguồn của chính khung (không đổi hành vi) + rà quy trình tài liệu; không chọn `/completion` vì chu kỳ hoàn thiện vừa đóng, không có lỗi mở.
- GitHub 2026-10-08: 0 PR mở; #217 MERGED 05:42:38Z, merge SHA 6643f4e; CI main run 37733742238 SUCCESS, CodeQL/Secret scan/Scorecard/Release SUCCESS.
- Radar 99/100 (kỷ luật kích thước 92.5: 5 file mã > 400 dòng). Maintenance --strict --no-deps: 🔴 0 · 🟡 0.
- Toolchain: host thiếu shellcheck/pwsh → cài vào venv/thư mục scratchpad (shellcheck-py 0.11.0, pwsh 7.5.4), không thêm dependency repo. Gate lần 1 BLOCKED đúng fail-closed vì thiếu pwsh (bằng chứng cổng không fail-open).
- Workflow: 9 workflow, mọi action ghim full SHA, quyền cấp workflow `contents: read`, không `pull_request_target`, không nội suy `github.event.*` trong `run:`. Ruleset: squash-only, strict checks `gate`+`metadata`, 0 bypass actor.

- Baseline sạch (worktree tại 6643f4e, không đặt CLAUDE_PROJECT_DIR): gate PASS exit 0, 186 s, 17 shell + 5 Python suite, coverage 96%; evidence baseline-gate.json trong scratchpad của phiên (ngoài repo).
- **P-A0 (Cao, mới):** gate lần 2 đặt `CLAUDE_PROJECT_DIR` như hook → đệ quy `test-adoption-smoke → dev-task gate → …` 10+ tầng sau 20 phút; đã dừng tiến trình, xác minh bằng `dev-task.sh:28` + `test-adoption-smoke.sh:32`. Sửa O-0 với test 7d đỏ-trước (log `o0-red.log`: 1 ca hỏng) → xanh (`o0-green.log`: 111 ✅); TRAPS 52.
- Hai audit chỉ-đọc hoàn tất; phiên chính xác minh từng claim đưa vào báo cáo bằng sed/grep (ghi trong report). Báo cáo + kế hoạch O-0..O-6, Approved theo §3d cho O-0..O-4.
- O-3 (docs) do worker làm trong `wt-o3`, diff 28 file apply vào nhánh; 5 chỗ sót sửa tay.
- Ràng buộc phiên: chỉ được push nhánh `claude/relaxed-knuth-f1ejlq` → các đơn vị đi thành commit tuần tự trên một PR (ghi trong report).

## Lần thử / blocker

Gate lần 1 exit 2 (thiếu pwsh — công cụ host, đã cài portable). Gate lần 2 treo đệ quy (P-A0) — dừng bằng tay, không phải cùng failure lặp.

- O-2 review + apply: 4 suite liên quan trên cây tích hợp 52/44/5/27 ✅; TRAPS của worker đánh lại số 53 (52 đã dùng cho P-A0). O-4a review + apply: 9 file +55/−101, test bảo vệ xanh.
- Commit qua hook pre-commit (full gate exit 0 mỗi lần): `7208f2c` fix (O-0+O-2), `8332b96` refactor (O-4a), `411d751` docs (O-1+O-3+report). Hai lần hook đỏ trước đó là do fixture `test-check-scripts` dựng từ `git ls-files` thiếu file chưa stage / tham chiếu file bị gitignore — sửa bằng stage trước và bỏ backtick, không hạ cổng.

## Bàn giao / bước tiếp theo

Push nhánh, mở PR đủ template, bật auto-merge sau khi mô tả đủ, theo dõi CI Linux/Windows của đúng head. Sau merge: reconcile PROGRESS (SHA mới), đổi hồ sơ này thành done, mở O-4b.

## Nghiệm thu cuối (chỉ điền khi đủ bằng chứng)

PR #218 MERGED (squash) lúc 2026-10-08T16:16:48Z, merge SHA 843581a000402955a3f28eb04306bd838522b4de,
head đã kiểm aa63553. Tại head: 13 check SUCCESS (gate, metadata, framework-lint Linux/Windows,
docs-consistency, copy-framework-smoke, protection-guard, CodeQL ×2, gitleaks, dependency-review;
progress-freshness skip hợp lệ), không review thread. Main 843581a: Release/Secret scan SUCCESS,
CI run 37807540551 ghi nhận ở hồ sơ O-4b khi hoàn tất. O-0..O-4a đạt DoD đã duyệt theo ủy quyền
2026-10-07, nghiệm thu 2026-10-08. Còn lại O-4b (đang làm), O-5/O-6 (kế hoạch có điều kiện xem lại).
