# Công việc: Đối chiếu snarktank/ralph → khung (ba cột)

- Work ID: 2026-10-09-doi-chieu-ralph
- Yêu cầu / outcome: người dùng: "nghiên cứu repo và tích hợp vào cho dự án khung và dự án đích: https://github.com/snarktank/ralph" → TRIGGER `docs/framework/adopt-from-outside.md` (đọc trước khi chép một dòng): bản đối chiếu ba cột lưu `docs/reports/2026-10-10-doi-chieu-ralph.md`; chỉ lấy hạng mục qua cổng §2 (sự cố thật) và không mâu thuẫn luật (§4).
- Trạng thái: Done (PR #253 MERGED)
- Chủ trì / writer: phiên chính (Fable 5.1), tự làm (một PR, mức S).
- Mức rủi ro / số PR: S — 1 PR `docs:` (báo cáo + hồ sơ + con trỏ PROGRESS). Không sửa source/luật vì kết quả đo là lấy 0.
- Scope / non-goal: Scope = đọc toàn bộ nguồn (`ralph.sh`, `prompt.md`, `CLAUDE.md`, `prd.json.example`, 2 skill, plugin manifest, README), grep cổng đang chạy ở khung, viết bản đối chiếu. Non-goal = không viết runner vòng lặp không giám sát (quyết định chủ repo, §9 quyền mới); không chép skill/prompt của ralph; không đổi manifest copy-framework (không có file mới để phát sang đích).
- Spec / goal / issue: không cần spec (mức S, tài liệu). Phương pháp: `docs/framework/adopt-from-outside.md`.
- Nhánh / base SHA / thời điểm reconcile: `docs/doi-chieu-ralph` @ `026a8a3` (origin/main sau #251) · 2026-10-09T17:35:11Z; worktree riêng vì checkout chính đang giữ PR-1 dở của hồ sơ audit-full-automation (`fix/hooks-git-bypass`).

## Kế hoạch và phân công

Một outcome / một PR, phiên chính tự làm: (1) clone nguồn vào scratchpad (dữ liệu không tin cậy, không chạy gì từ đó) và đọc đủ 9 file; (2) đếm hạng mục (25); (3) với mỗi hạng mục grep cổng đang chạy (script/test/hook/job CI) ở khung, không đọc văn xuôi; (4) áp cổng §2 cho cột "chưa có"; (5) kiểm mâu thuẫn luật §4; (6) viết báo cáo + con trỏ PROGRESS; (7) `/gate` → PR → changelog kèm số PR → auto-merge.

## Quyết định và bằng chứng

- Nguồn @ `6c53cb0` (2026-02-02). Kết quả đo: 21 "đã có và sâu hơn", 0 "nông hơn", 4 "chưa có" (vòng lặp ngoài không giám sát, `max_iterations`, `<promise>COMPLETE</promise>`, flowchart) — **lấy 0**.
- Cổng §2 cho vòng lặp ngoài: điều kiện xem lại đã ghi ở `2026-10-06-doi-chieu-x-agents-v2.md` và `…-v3.md` ("khi có phiên mất ngữ cảnh được tái hiện"); grep `TRAPS.md`/`docs/work`/`docs/reports` hôm nay → 0 sự cố. Giữ "chưa cần", ghi thêm điều kiện (b): chủ repo quyết cho phép sửa source không giám sát.
- Mâu thuẫn luật ghi đủ (skip-permissions vs threat model + quyết định không bake `dontAsk` 2026-10-09; learnings vào CLAUDE.md vs trần 200 dòng + cổng docs-consistency; mọi commit `feat:` vs conventional commits/release-please; skill prd luôn hỏi vs §9/§3d). Không tự hoà giải — một câu hỏi duy nhất để chủ repo quyết ở cuối báo cáo.
- Đính chính giữ trong báo cáo: (A) thu hẹp ứng viên "vòng lặp" xuống đúng điểm thiếu; (B) `grep goals scripts/*` → 0: khung cũng chưa có cổng đọc `docs/goals/` — ngang nhau về cưỡng chế, sâu hơn chỉ ở ngữ nghĩa Evidence; (C) heuristic cỡ story loại vì không có sự cố.
- Quyết định kỹ thuật: Work ID giữ ngày UTC `2026-10-09` do `new-work.sh` cấp (lệnh xoá để tạo lại bị từ chối quyền); tên báo cáo theo ngày địa phương `2026-10-10`. Không ảnh hưởng cổng (pr-policy chỉ cần thư mục tồn tại).

## Lần thử / blocker

- `rm -rf docs/work/2026-10-09-doi-chieu-ralph` (để tạo lại với WORK_DATE=2026-10-10) bị từ chối quyền → giữ nguyên ID. Không phải lỗi.
- Cổng tổng local `dev-task.sh gate` đỏ ở bước test: đúng 12 ca `test-hooks-session.sh` = F-Q6 (đỏ giả Windows, báo cáo audit 2026-10-09 dòng 41; copy binary `bash` lỗi shared library). Không liên quan diff (chỉ tài liệu). Theo quy trình đã ghi ở hồ sơ audit: commit kèm bằng chứng suite liên quan, CI Linux/Windows là cổng thật; commit dùng `--no-verify` có chủ đích cho hook `pre-commit-gate` (đường bỏ qua tường minh của hook).

## Bàn giao / bước tiếp theo

- Chạy `bash scripts/dev-task.sh gate` + `check-docs-consistency.sh` trong worktree; commit `docs(report): đối chiếu snarktank/ralph …`; push; mở PR ghi `Work ID: 2026-10-09-doi-chieu-ralph`; thêm dòng CHANGELOG kèm số PR; bật auto-merge; sau merge đổi file này thành `done.md` kèm SHA.
- Chờ chủ repo trả lời câu hỏi cuối báo cáo (runner không giám sát kiểu `ralph.sh`: có/không). Nếu "có" → mở hồ sơ mới mức L (spec + goal + threat model), không làm trong PR này.

## Nghiệm thu cuối (chỉ điền khi đủ bằng chứng)

- PR #253 MERGED (squash) → `main` @ `0adcafb`; CI 13/13 xanh (framework-lint Linux+Windows, docs-consistency,
  copy-framework-smoke, progress-freshness, protection-guard, metadata, CodeQL, gitleaks, dependency-review).
- Local: docs-consistency OK (sau 2 lần sửa: tham chiếu hai script copy viết gộp một chuỗi; `|` trong ô bảng), progress-freshness
  PF-1..4 OK, format/lint OK; test 854 dòng: đúng 12 ❌ = F-Q6 `test-hooks-session.sh` (đỏ giả Windows, đã ghi), suite khác xanh.
- Tiêu đề PR/commit ban đầu 88 ký tự bị `metadata` chặn (TRAPS 58) → gộp 3 commit thành 1 tiêu đề 70 ký tự, force-with-lease nhánh riêng.
- DoD: bản đối chiếu đủ ba cột + đính chính + điều kiện xem lại; lấy 0; không sửa luật/script. Giới hạn: câu hỏi runner không
  giám sát kiểu `ralph.sh` còn mở, chờ chủ repo. Nghiệm thu: phiên chính theo ủy quyền §3d, 2026-10-10.
