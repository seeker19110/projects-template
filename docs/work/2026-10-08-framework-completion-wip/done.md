# Công việc: W-02 — trần WIP áp cho mọi PR mở

- Work ID: 2026-10-08-framework-completion-wip
- Yêu cầu / outcome: khớp cổng PR với trần tối đa ba PR mở toàn repo, kể cả draft và bot.
- Trạng thái: Done — PR #217 MERGED, nghiệm thu 2026-10-08 theo ủy quyền.
- Chủ trì / writer: worker W-02; phiên chính review, tích hợp và nghiệm thu.
- Mức rủi ro / số PR: S; một PR sửa lỗi có hồi quy đỏ-trước.
- Scope: `.github/workflows/pr-policy.yml`, `tests/test_runtime_safety.py`, `CODEMAP.md`, `TRAPS.md` và hồ sơ đơn vị này.
- Non-goal: đổi trần WIP, bỏ miễn trừ metadata draft/bot, thêm dependency/suite CI, commit/push/merge bởi worker.
- Goal: `docs/goals/2026-10-08-framework-completion.md`; W-02 phụ thuộc W-01 vì chung test và tài liệu.
- Nhánh / base: codex/framework-wip-completion-2026-10-08 / d7aca5d37ddd55df7672cbe66470a086d7101794; reconcile 2026-10-08.

## Kế hoạch và phân công

1. Test offline thực thi JavaScript thật trong workflow bằng Node và GitHub/core stub; xác nhận đỏ trên source cũ.
2. Di chuyển đếm WIP trước nhánh return draft/bot và bỏ bộ lọc draft; giữ nguyên kiểm title và miễn trừ metadata.
3. Test tổng ba/bốn PR, draft khác, draft/bot hiện tại, không đếm trùng và metadata; cập nhật CODEMAP/TRAPS cùng PR.
4. Chạy runtime suite và cổng docs/static; bàn giao diff để phiên chính chạy full gate sau khi tài liệu tổng ổn định.

## Quyết định và bằng chứng

- Đã đọc CLAUDE, contract, orchestration, vai standard-worker, PROJECT, PROGRESS và hồ sơ liên quan.
- Phiên chính cho phép sửa sau W-01 merge #216; Git tại đầu lượt xác nhận đúng base/nhánh trên. Giữ nguyên staged checkpoint của phiên chính.
- `pr-flow.md` tính mọi PR chưa đóng/merge; source cũ return trước WIP cho draft/bot và lọc `!p.draft` cho PR khác.
- Tận dụng runtime suite đã chạy trong gate và CI Linux/Windows; fixture không mạng và không gọi AI/API.
- RED trước sửa source: `python3 -m unittest discover -s tests -p test_runtime_safety.py -k pr_policy -v` exit 1; một method/18 subcase, 13 fail. Log `/tmp/framework-completion-W02-wip-red.log` đã đọc đầy đủ: PR thứ tư gồm draft khác không bị chặn; draft/bot return trước phép đếm, kể cả dưới trần và khi title sai. Các ca metadata thường và total ba/bốn PR thường đúng như trước.
- Sửa tối thiểu: chuyển nguyên phép đếm WIP trước hai return miễn trừ; chỉ loại PR hiện tại khỏi danh sách open. Conventional title, giới hạn title, body/feature metadata và các miễn trừ hiện có giữ nguyên.
- GREEN sau source: cùng focused command exit 0, 1/1 method và 18 subcase; log `/tmp/framework-completion-W02-wip-green.log` đã đọc đủ. `python3 tests/test_runtime_safety.py` exit 0, 17/17 method; log `/tmp/framework-completion-W02-runtime-green.log` đã đọc đủ.
- `scripts/dev-task.sh build` exit 0 (Bash syntax/Python compile), log `/tmp/framework-completion-W02-build.log`; `scripts/dev-task.sh typecheck` exit 0, 78 khối Python và 274 khối shell đạt trần, log `/tmp/framework-completion-W02-typecheck.log`. Hai lệnh dùng PATH=/tmp/framework-completion-20261008-ci/bin:$PATH.
- `scripts/dev-task.sh lint` cùng PATH exit 0, ShellCheck mức warning không cảnh báo; docs-consistency đủ 11 nhóm và CI-policy CP-1..6 xanh. Log `/tmp/framework-completion-W02-lint.log` đã đọc đầy đủ.
- Đã tự đọc diff source/test/CODEMAP/TRAPS; `git diff --check` exit 0. Không thêm dependency, không đổi snapshot/golden, không debug/secret và không thay wiring suite CI.
- Đã gọi `scripts/dev-task.sh format-file` cho cả năm file; resolver skip vì repo không có formatter theo file cho các loại này. Không gọi skip là formatter thật đã chạy.
- Bằng chứng trên cây sửa chưa commit tại base nêu trên; chưa chạy full gate, Git hook, PR/CI Linux/Windows hoặc merge. Windows fixture dùng Node sẵn có của CI; kết quả thật chờ CI.

## Lần thử / blocker

Expected RED xác nhận defect, không tính như lần sửa thất bại. Lần sửa source đầu GREEN; không có blocker kỹ thuật đã biết.

## Bàn giao / bước tiếp theo

Phiên chính đã review diff/log, chạy full gate --evidence exit 0 và evidence-check
VERIFIED trước cập nhật bản ghi; log /tmp/framework-completion-W02-gate.log:
17 shell suite/5 Python suite trực tiếp, runtime 17/17, coverage 96%. Output đối chiếu
đầy đủ với W-01, chỉ khác ca WIP/số runtime/context và dữ liệu động. Tiếp theo hook
Git kiểm lại rồi tích hợp PR W-02 và kiểm CI của đúng head. Worker đã ngừng ghi; mọi thay đổi
thuộc scope còn trong checkout chung, chưa commit. Giới hạn: fixture kiểm logic script
workflow offline, chưa chứng minh mọi thay đổi trạng thái PR trên GitHub đều tự re-run
metadata; khi số PR thay đổi workflow vẫn yêu cầu re-run như thông báo hiện có.

## Nghiệm thu cuối

PR #217 MERGED lúc 2026-10-08T05:42:38Z (squash), merge SHA
6643f4e52b0a0ca09e8ccee06ff4188ee4cda1a3; head đã kiểm f9eb2f8df47b71be1e1ef62a31baca6e34faecd9,
base d7aca5d. CI của main 6643f4e: run 37733742238 (CI) SUCCESS; CodeQL 37733742317,
Secret scan 37733742216, Scorecard 37733742338, Release 37733742326 đều SUCCESS. GitHub
2026-10-08: 0 PR mở, không review thread chờ. `git fetch origin main` → nhánh làm việc
trùng origin/main (0/0 ahead-behind). F-C02 đóng trên default branch với regression
18 subcase trong `tests/test_runtime_safety.py`. Nghiệm thu theo ủy quyền chủ repo
2026-10-07, ngày 2026-10-08; đổi tên done sau các phép đối chiếu trên, ghi trong PR
của chu kỳ kế tiếp theo contract §3e. Giới hạn giữ nguyên: cổng WIP chặn ở check
metadata, không ngăn tạo PR thứ tư trên GitHub UI.
