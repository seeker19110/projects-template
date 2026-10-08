# Tối ưu quy trình khung — audit 2026-10-08

## Phạm vi và cách chọn

Yêu cầu chủ repo: "nghiên cứu lại quy trình, tối ưu lại tốt nhất, chất lượng tốt nhất,
ít code nhất, bảo mật nhất, dễ vận hành nhất". Theo CLAUDE.md §1b, cụm "tối ưu" + "quy trình"
được đọc là **audit tối ưu không đổi hành vi trên chính bộ khung** (code thực thi + tài liệu
quy trình), không phải `/completion` (chu kỳ FC-2026-10-08 vừa đóng, không còn lỗi Cao/Trung mở).
Nguyên tắc: không đổi luật nền, không hạ cổng, không thêm dependency; mỗi hạng mục một PR nhỏ,
có test bảo vệ, đo trước–sau; bug (`fix:`) có test đỏ trước.

Base: `6643f4e` (origin/main sau #217). Hồ sơ: `docs/work/2026-10-08-process-optimization/done.md`.
Hai lượt audit chỉ-đọc (code · tài liệu) do subagent thực hiện; phiên chính xác minh từng claim
đưa vào kế hoạch bằng `grep`/`sed` trên source thật trước khi ghi dưới đây.

## Baseline (đo thật, 2026-10-08, base 6643f4e)

| Thước | Kết quả |
| --- | --- |
| CI main | run 37733742238 SUCCESS (7 job); CodeQL · Secret scan · Scorecard · Release SUCCESS; 0 PR mở |
| Full gate cục bộ (worktree sạch) | `dev-task.sh gate --evidence` **PASS** exit 0, 186 s (build 0 s · typecheck 1 s · lint 10 s · test 175 s); 17 suite shell + 5 suite Python trực tiếp; coverage engine 96% (sàn 95%); context `6643f4e:85996f0:4f614d5`. Lần chạy đầu với `CLAUDE_PROJECT_DIR` đặt như hook → treo đệ quy (→ P-A0) |
| Radar | 99/100 — kỷ luật kích thước 92.5 (5 file mã > 400 dòng); 39/39 script có cổng; 22/22 spec |
| Maintenance `--strict --no-deps` | 🔴 0 · 🟡 0; 10 TODO đều là ví dụ trong tài liệu; 2 `DEBT:` đủ điều kiện xem lại |
| Quy mô | 275 file / 30 016 dòng; mã 8 599 + chú thích 1 426; tài liệu 16 416 (54,7%) |
| Code thực thi | `scripts/*.sh` + `*.py` 7 572 dòng; `tests/` 1 579; hook 633; workflow 905 |
| Tài liệu quy trình | `docs/framework` 4 978; commands 708; agents 467; CLAUDE.md 41 182/42 000 byte (còn 818) |
| Bảo mật workflow | 9 workflow, mọi `uses:` ghim full SHA, `permissions: contents: read` cấp workflow, không `pull_request_target`, không nội suy `github.event.*` trong `run:`; ruleset squash-only, strict checks `gate`+`metadata`, 0 bypass |
| Vận hành | Gate của chính repo khung cần `shellcheck`+`pwsh`+`jq`+python `coverage`/`radon`; host thiếu `pwsh` → `BLOCKED` đúng fail-closed (lần chạy 1) |

## Phát hiện

Mức: **Cao** = hàng rào có thể bị vô hiệu/im lặng; **Trung** = sai/lệch có thể gây việc sai;
**Thấp** = chỉ tốn code/bảo trì. Mọi dòng dưới đã xác minh trên source tại base.

### A. Bảo mật & hàng rào (hook/cổng)

| ID | Mức | Vị trí | Phát hiện | Đề xuất |
| --- | --- | --- | --- | --- |
| P-A0 | **Cao** | `scripts/dev-task.sh:28` + `scripts/test-adoption-smoke.sh:32,71,87,98` + `.claude/hooks/pre-commit-gate.sh:109` | Phát hiện khi đo baseline (không nằm trong hai audit): gate/doctor của dự án đích giả chạy mà **kế thừa `CLAUDE_PROJECT_DIR` của repo khung** → ROOT quay về khung → gate khung gọi lại chính nó → đệ quy vô hạn, treo không thông báo. Hook `pre-commit-gate` đặt biến này cho mọi `git commit` từ Claude Code nên **mọi commit repo khung từ Claude Code sẽ treo**; CI không đặt biến nên xanh; các PR gần đây commit từ Codex (Git hook chuẩn) nên không lộ. Tái hiện thật: `ps` thấy chuỗi `test-adoption-smoke.sh → dev-task.sh gate → test-adoption-smoke.sh` 10+ tầng sau 20 phút | Hai lớp: (1) `dev-task.sh gate` BLOCKED có lý do khi `DEV_TASK_GATE_ROOT` trùng ROOT (fail-closed thay vì treo, áp cho mọi dự án đích); (2) smoke test đặt `CLAUDE_PROJECT_DIR="$dir"` cho đích. TRAPS mục 52 |
| P-A1 | Trung | `.claude/hooks/pre-commit-gate.sh:34` vs `block-dangerous-git.sh:64-78` | Hai hook cùng làm sạch lệnh trước khi so khớp nhưng chỉ `block-dangerous-git` bỏ thân heredoc (sửa 2026-09-14); `pre-commit-gate` chỉ bỏ nháy → thân heredoc chứa `git commit`/`git add` kích gate/`self_stage` sai | Dùng chung một thư viện hook thư viện hook chung .claude/hooks/_lib.sh (tạo ở O-2) (đọc payload jq + strip heredoc + strip nháy); test đỏ trước |
| P-A2 | Trung | `session-guide.sh:16`, `usage-guard.sh:8`, `telemetry-record.sh:19-21,94` | Thoát 0 **im lặng** khi thiếu `jq`/`python3` hoặc khi `telemetry-log` lỗi (`>/dev/null 2>&1 \|\| exit 0`) — trái luật F-007 "bỏ qua thì phải nói"; `telemetry.json` hỏng sẽ fail mỗi lượt không ai biết | In một dòng cảnh báo stderr; nhận cả `python` như `_python-exec.sh` |
| P-A3 | Trung | `scripts/usage-estimate.sh:56` | `open(path)` không encoding (khác `telemetry-record.sh:54`); transcript non-ASCII trên console cp1252 → UnicodeDecodeError → `usage-guard.sh:15` tắt cảnh báo quota không báo | `encoding="utf-8", errors="replace"`; test với fixture non-ASCII |
| P-A4 | Trung | `pre-commit-gate.sh:60`, `scripts/githooks/pre-commit:17`, `maintenance-sweep.sh:283` | `secret_re` chép nguyên văn 3 nơi, kiểm > 1 MB 3 nơi, kiểm commit-trên-main 2 nơi; không test nào kiểm chúng còn đồng bộ (TRAPS mục 19 ghi đúng khuôn lệch bản sao) | một nguồn scripts/_commit-guard.sh (tạo ở O-4), hai hook + sweep source; thêm vào cả hai copy script |
| P-A5 | Thấp | `block-dangerous-git.sh` | Chạy jq+awk+sed+5 grep trên **mọi** lệnh Bash, regex `git … push` tính 3 lần; `pre-commit-gate` gọi `git rev-parse` trước khi biết có phải commit | Thoát sớm khi lệnh không chứa `git`; tính push-match một lần |
| P-A6 | Thấp | 3 hook + 2 githook | Cả hàng rào Claude Code fail-open khi thiếu `jq` (có cảnh báo); agent ngoài Claude Code chỉ có luật văn xuôi + githook opt-in | Ghi nhận; `python3` fallback đọc JSON là lựa chọn nếu có sự cố thật (chưa có) — xem lại khi TRAPS ghi ca hook bị bỏ qua vì thiếu jq |

### B. Trùng lặp / dead code / over-build trong code thực thi

| ID | Mức | Vị trí | Phát hiện | Đề xuất (net dòng) |
| --- | --- | --- | --- | --- |
| P-B1 | Trung | `scripts/test-telemetry-and-dispatch.sh:165` | Hard-code `'^Ran 15 tests'` của file khác → thêm test thứ 16 là suite đỏ | Kiểm exit 0 + `^OK` (0) |
| P-B2 | Thấp | 12 `scripts/test-*.sh` + `test-adoption-smoke.sh:9-12` | Khối kết thúc "fails=0 → OK/exit 0 else FAIL/exit 1" viết tay 12 lần; adoption-smoke định nghĩa lại `fails/ok/bad` giống `_test-lib.sh` | `finish` trong `_test-lib.sh` (≈ −41) |
| P-B3 | Thấp | `subagent-dispatch.py:41-48` · `check-ci-policy.sh:153-160,174` · `check-docs-consistency.sh:25-28,42-55` | `AGENT_TIER` 0 tham chiếu; `CP4_BOOTSTRAP_EXEMPT=()` rỗng "để dành"; exclusion chết cho `test-engine-characterization.sh` (fixture đã dời sang `tests/engine_characterization/`); 4 entry `ALLOW_MISSING_PATH` cho file đã tồn tại/không còn ai nhắc (`settings-sonnet.json`) — chính comment ở dòng 40-41 bảo gỡ | Xoá (≈ −21) |
| P-B4 | Thấp | `test-check-scripts.sh:171-175` · `test-telemetry-and-dispatch.sh:62-70,151-160` · `test-next-gen-engines.sh:196-218` · `test-maintenance-sweep.sh:25-26` | Ca test trùng ca khác hoặc trùng `tests/test_*.py` đang chạy cùng gate; dòng 25 nhận rc 0/1 rồi dòng 26 bác rc≠0 | Xoá bản trùng (≈ −32) |
| P-B5 | Thấp | `maintenance-sweep.sh:201-205` · `check-docs-consistency.sh:186-209` · `test-check-scripts.sh:326-367` · `maintain-cron.sh:251-263` · 3 file `require_cli_value` | Nhánh if/else in cùng chuỗi; §5/§5b cùng vòng lặp; awk trích `run:` chép 2 lần; 4 header curl chép GET/POST; pre-`case` chỉ để gọi `require_cli_value` | Gộp hàm (≈ −33) |
| P-B6 | Thấp | `dev-task.sh:39-44,220-224` · `maintenance-sweep.sh:81-85` · `maintain-run.sh:78` | 3 cách đọc biến từ `project-commands.sh`, hai chỗ dùng `eval` thay `${!name}` | `declared_cmd` vào `_stack-detect.sh` (đã source + đã copy), bỏ `eval` (≈ −9) |
| P-B7 | Thấp | `dev-task.sh` 584 dòng | 13 `_cmd_*` + alias (≈ 157 dòng) là phần dò stack, hợp `_stack-detect.sh`; usage text dòng 34 kê 7 task, dòng 583 kê 9, `format-file` không có ở đâu | Dời khối dò stack, sửa usage (dev-task ≈ 430 dòng, radar 92.5 → 95) |
| P-B8 | Thấp | `subagent-dispatch.py:117-228` · `telemetry-log.py:281-324` · `spec-compiler.py:242` · `arch-health-radar.py:68-95` | 4 nhánh payload lặp key chung; 44 dòng CSS widget; tham số `start` không ai truyền; 2 bản try/open/read | Gộp dict, nén CSS, gỡ tham số (≈ −67) |
| P-B9 | Trung | `maintain-run.sh:102` · `test-next-gen-engines.sh:276-279` · `test-py-coverage.sh:110-126` · `test-telemetry-and-dispatch.sh:100,137,153` | Tác dụng phụ: file prompt tạm không xoá (rò mỗi lần cron); probe ghi vào `scripts/` thật không trap; test append vào .ai-telemetry/telemetry.json thật (phình vô hạn, `test-next-gen-engines.sh:254-256` ghi nhận đỏ giả do đó); `model-rates.json` bị ghi đè chỉ hồi phục nhờ trap EXIT | trap EXIT; test telemetry chạy trên bản copy tạm như `test-hooks-session.sh` (+3) |
| P-B10 | Thấp | `copy-framework.sh:254-289` vs `copy-framework.ps1:204-241` | Hai danh sách ≈ 36 file bảo trì tay (TRAPS mục 19) | Một manifest cả hai đọc (≈ −35, +1 file) — mức M, xem lại khi thêm/bớt file khung lần tới |
| P-B11 | Thấp | `telemetry-record.sh:36-84` vs `usage-estimate.sh:32-93` · `check-ci-policy.sh` CP-6 vs `test_ci_suite_parity.py` vs radar · `test-adoption-smoke.sh:116-150` vs `test_lean_adoption.py` | Hai parser transcript Python chạy mỗi Stop; ba cổng cùng kiểm "test-*.sh có trong ci.yml"; cùng fixture Node/Python copy→FAIL→PASS chạy 4 lần copy-framework | Hợp nhất (≈ −57) — mức M, cần đo thời gian gate trước–sau |
| P-B12 | — | Wrapper `scripts/*.sh` 4-5 dòng; ROOT/cygpath/mktemp+trap/UTF-8 reconfigure lặp 1-3 dòng | Có người gọi thật (hook, maintain-run, sweep, 20+ tài liệu, cổng §7); không đáng tách | **Giữ nguyên** |

### C. Tài liệu quy trình — trùng lặp, mâu thuẫn, tham chiếu chết

| ID | Mức | Vị trí | Phát hiện | Quyết định phiên chính (căn cứ: căn theo nguồn sự thật đã khai, không đổi luật) |
| --- | --- | --- | --- | --- |
| P-C1 | Trung | ≈ 20 vị trí: `auto.md:45`, `completion.md`, `contract.md:29`, `deps-upgrade.md:14`, `orchestration-3-tier.md:83`, `review.md`, `standard-worker.md:32`, `complex-implementer.md:30`, `security-reviewer.md:29`, `maintainer.md:56`, `comprehensive-audit-prompt.md`, `models-and-automation.md`, `quality-gates-by-profile.md:29`, `02-ai-rules…md:14,51-57`, `new-project-runbook.md:175` | Vẫn trích danh sách 6 mục **cũ** của CLAUDE §9 (mơ hồ/không hoàn tác/mâu thuẫn/breaking/nhiều đánh đổi/bảo mật) sau khi #213 đã thu §9 về "thiếu mục tiêu/dữ kiện · không có phương án đạt chất lượng · cần quyền chưa cấp"; `auto.md:45` còn bắt "xin xác nhận khi chuyển giai đoạn" trái CLAUDE §2 | Thay mọi trích dẫn bằng con trỏ "dừng/hỏi: CLAUDE §9 → `standard-delivery.md` §3d"; không viết lại nội dung §9 |
| P-C2 | Trung | `coordinator.md:19` vs frontmatter `model: sonnet` (:14) và `orchestration-3-tier.md:28` | Thân vai nói "chạy Opus ở effort thấp" | Sửa thân về Sonnet · low theo frontmatter (nguồn khai ở orchestration:78) |
| P-C3 | Trung | `auto.md:2,7,9` · `orchestration-3-tier.md:21` | "Luôn `/model` sang Opus trước Plan Mode" trái CLAUDE §2 và ADR-0010 quyết định 4 ("đổi model theo độ khó thật, không phải nghi thức") | Sửa thành "đổi model khi độ khó thật đòi hỏi (ADR-0010 §4)"; 7 callout "💡 Model/effort" rút về một dòng trỏ `models-and-automation.md` |
| P-C4 | Trung | `coordinator.md:54` | "đỏ lần hai → BLOCKED" (2 lần) trong khi contract §4/§8 và CLAUDE §2 là 3 lần | Sửa về 3 |
| P-C5 | Trung | `gate.md` bước 4 vs dòng 20 | "Không có `package.json` → dừng" trái "`dev-task.sh` là nguồn, đa stack" | Bỏ điều kiện `package.json`; `dev-task.sh doctor` quyết |
| P-C6 | Trung | `CLAUDE.md:130`, `pr-flow.md:9` vs `ci.yml:261-262` | Nói `progress-freshness` "chặn merge PR kế tiếp"; thực tế job chỉ chạy khi push main, PR skip hợp lệ, required checks chỉ `gate`+`metadata` → nó làm đỏ `main` sau merge, không chặn PR kế | Sửa văn đúng hành vi thật ("làm đỏ main sau merge; sửa trong PR kế") |
| P-C7 | Thấp | `CODEMAP.md:12-13` · `standard-delivery.md:69,296-297` · `pr-flow.md:9` · `README.md:10,28` · `PROJECT.md:5-6` · `copy-framework.sh:176` | Tham chiếu chết: TRAPS "bẫy 10" không tồn tại, "bẫy 9" (UTF-8) thực là §24, CP-5 → đúng là CP-6; "PF-1..3" → PF-1..4; "§8 bước 0/5" là của CLAUDE; "xem §10" là CLAUDE §10; `KHUNG-1/2/3` tên cũ; "4 engine" (có 5 `.py`); PROJECT.md "mặc định Web app" trái ADR-0004; comment kê 13/16 lệnh; dòng `project-completion.md` lặp | Sửa từng điểm |
| P-C8 | Thấp | `02-ai-rules-and-project-template.md` (181 dòng) | PHẦN A lặp CLAUDE §4-§7/§9 bản cũ (mẫu báo cáo không có dòng TDD/golden); PHẦN B là bản PROJECT.md đã lệch 45 dòng diff | Rút còn PHẦN C + con trỏ (≈ −130) |
| P-C9 | Thấp | `audit-full.md`/`completion.md`/`audit-optimize.md`/`incident.md`/`bootstrap.md` vs playbook tương ứng; `maintain.md` vs `maintainer.md` (+ 3 chỗ khác tả maintain-run/cron); `coordinator.md` vs `orchestration-3-tier.md` (bảng route) | Lệnh chép lại pha/bước của playbook rồi lệch; `bootstrap.md:21-22` hard-code bất biến web (TS strict/Zod/Dark blue) trái §0b; maintain-run/cron tả 5 lần; bảng route chép 3 nơi | Lệnh = con trỏ mỏng + delta; mô tả cron 1 nơi; route = frontmatter + orchestration (≈ −145) |
| P-C10 | Thấp | `CLAUDE.md` §1 (16 KB = 39% file), §11 lặp :38; `pr-flow.md:9` một dòng 3 496 ký tự | CLAUDE sát trần 42 000 byte; §11 chép adopt-from-outside §1-3; dòng khổng lồ trong pr-flow đúng khuôn mà cổng mục 9 sinh ra để chặn (chỉ đo CLAUDE.md) | Rút §1 thành TRIGGER một dòng; gộp §11 vào :38; tách pr-flow:9 thành danh sách (≈ −10 KB CLAUDE) |
| P-C11 | Thấp | 5 chỉ mục tài liệu (CLAUDE §1, framework/README, sd §11, README, FEATURE-MAP); `quality-supplements.md` chỉ là index 4 file; framework/README thiếu 7 file; DoR ở sd §5 (9 mục) vs group1 §7 (5 mục); handoff ở `PROGRESS.template.md:40` vs `working.md` | Nhiều nguồn một phần, lệch nhau | framework/README là index duy nhất đủ; DoR/handoff trỏ về `standard-delivery.md` (nguồn khai) |
| P-C12 | Thấp | `lean-delivery-benchmark.md`, `case-study-greenfield-dry-run.md`, `strict-gate-contract.md` | Tài liệu nội bộ repo khung vẫn copy sang mọi dự án đích (`copy-framework.sh:164`) | Chưa làm — đổi copy script là mức M, xem lại cùng P-B10 |

### D. Cổng máy: luật nào thật sự được cưỡng chế (đối chiếu, không phải phát hiện lỗi)

Thật: WIP 3 (metadata), conventional/≤72/template (metadata), không push main/squash/strict (ruleset + protection-guard), gate trước commit (hook + githook opt-in), docs-consistency 11 mục, CP-1..6, PF-1..4 (chỉ sau merge).
Yếu: Feature gate chỉ grep chuỗi "Approved for implementation" + đường dẫn spec trong body PR, không mở spec (ghi nhận; xem lại khi có PR `feat` lọt với spec chưa Approved thật).
Văn xuôi: TDD đỏ-trước (ADR-0005 cố ý), FIFO, 3 lần cùng failure, trần 500k (chỉ config, không test), ADR-0009, hồ sơ working→done.
Test phụ thuộc chữ: `test_adaptive_process.py` (chuỗi trong §3c/orchestration/CLAUDE/AGENTS/auto), `test_profile_quality_matrix.py` (số mục CLAUDE §3), `check-docs-consistency.sh` mục 4(c) chỉ đọc 4 dòng mũi tên `route:x → agent` ở orchestration:44-47 — **không được xoá/đổi khuôn** khi gọn hoá.

## Kế hoạch (mỗi đơn vị một commit/PR nhỏ; `fix:` có test đỏ trước; refactor có test bảo vệ + đo trước–sau)

> Phiên này bị ràng buộc **chỉ được push một nhánh** (`claude/relaxed-knuth-f1ejlq`), nên O-0..O-4
> đi thành các commit tuần tự trên **một PR**, mỗi commit một đơn vị, thay vì nhiều PR FIFO; đây là
> đánh đổi do môi trường phiên, không phải thay đổi luật §8. O-5/O-6 là chu kỳ sau.

| PR | Loại | Nội dung | Phụ thuộc | Người làm |
| --- | --- | --- | --- | --- |
| O-0 | fix S | P-A0: chốt chặn gate lồng nhau cùng ROOT + smoke test đặt đúng `CLAUDE_PROJECT_DIR`; test 7d đỏ-trước; TRAPS 52 | — | phiên chính |
| O-1 | docs S | Reconcile FC-2026-10-08 + báo cáo này + hồ sơ work | — | phiên chính (PR hiện tại) |
| O-2 | fix S | P-A1, P-A2, P-A3, P-A5 + P-B1: hook dùng `_lib.sh` chung, cảnh báo thay vì im lặng, encoding, thoát sớm; TRAPS mục mới; test đỏ trước ở `test-hooks-gate.sh`/`test-hooks-session.sh`/`test-usage-estimate.sh` | O-1 (FIFO) | subagent (complex: có nhánh logic + test) |
| O-3 | docs S | P-C1..P-C7 (mâu thuẫn + tham chiếu chết), không đổi luật | độc lập O-2 (không chung file) | subagent (standard) |
| O-4 | refactor S | P-A4 `_commit-guard.sh` + P-B2..P-B6, P-B9 dọn trùng/dead/tác dụng phụ | O-2 merge (chung hook/test) | subagent |
| O-5 | refactor/docs M | P-B7 (dời dò stack), P-C8..P-C11 (rút tài liệu) | O-3, O-4 merge | chu kỳ sau, đo radar/byte trước–sau |
| O-6 | refactor M | P-B10, P-B11, P-C12 | O-5 | **chưa làm** — xem lại khi thêm/bớt file khung hoặc thời gian gate > 15 phút |

**Approved for implementation — phiên chính duyệt theo ủy quyền của chủ repo ngày
2026-10-07; ngày duyệt thực tế 2026-10-08.** Phạm vi duyệt: O-0..O-4 (S, không đổi hành vi
luật, không hạ cổng, không dependency). O-5/O-6 giữ ở mức kế hoạch có điều kiện xem lại.
Mâu thuẫn tài liệu được giải bằng cách **căn theo nguồn sự thật đã khai trong chính tài liệu**
(CLAUDE §9/§3d, frontmatter agent, contract §4/§8, hành vi `ci.yml` thật), không chọn luật mới.

## Thực thi và nghiệm thu

**O-0 (fix, P-A0).** Test đỏ-trước `scripts/test-dev-task.sh` mục 7d trên dev-task cũ: suite exit 1,
đúng 1 ca hỏng "nested: expected exit 1 / lồng nhau trên cùng ROOT, got 1" (bản cũ đệ quy tới tầng 3
rồi hỏng không thông báo); log `o0-red.log`. Sửa `dev-task.sh` (chốt `DEV_TASK_GATE_ROOT`, 7 dòng) +
`test-adoption-smoke.sh` (4 lời gọi đặt `CLAUDE_PROJECT_DIR` đúng đích). Xanh-sau: suite exit 0,
111 ✅, ca 7d "gate → exit 1, lồng nhau trên cùng ROOT"; shellcheck 0 cảnh báo; complexity OK
(CC cao nhất 43/45, không đổi). TRAPS mục 52.

**O-3 (docs, P-C1..P-C7).** Worker sửa 28 file (+59/−74) trong worktree riêng, phiên chính
`git apply` vào nhánh; 5 chỗ sót (`grill.md`, `incident.md`, `bootstrap.md`, `project-completion.md:83`,
`spec-driven-openspec.md:92`) phiên chính sửa tay cùng khuôn. Worker đã chạy docs-consistency
(11 mục OK), `test_adaptive_process` 8 OK, `test_profile_quality_matrix` 3 OK trong worktree;
phiên chính chạy lại trên cây tích hợp (xem dưới). TDD: ngoại lệ 3 (chỉ tài liệu).

**O-2 (fix, P-A1/A2/A3/A5 + P-B1).** Worker complex trong worktree riêng; phiên chính review diff
từng hook (mọi khuôn chặn vẫn cần chữ `git`, không regex nào đổi) rồi `git apply`. Đỏ-trước trên
source cũ: `test-hooks-gate.sh` mục 16 — 2 ❌ (thân heredoc chứa `git commit`/`git add` làm hook exit 2);
`test-hooks-session.sh` mục 10 — 6 ❌ (thiếu jq/python, chỉ có `python`, engine lỗi → im lặng);
`test-usage-estimate.sh` UE-5 — `UnicodeDecodeError` thật với `LC_ALL=C PYTHONUTF8=0`. Xanh-sau trên
cây tích hợp (phiên chính chạy lại): hooks-gate 52 ✅, hooks-session 44 ✅, usage-estimate 5 ✅,
telemetry-and-dispatch 27 ✅, 0 ❌. `_lib.sh` đi theo copy nguyên thư mục `.claude/hooks`
(worker đã copy thử sang đích và hook ở đích vẫn chặn force-push main). TRAPS mục 53. Để lại có
chủ đích: `telemetry-record.sh` vẫn im lặng khi *thiếu engine* (dự án đích gỡ telemetry không nên bị
nhắc mỗi lượt); `usage-guard.sh:15` im lặng khi `usage-estimate.sh` lỗi → O-4b.
Commit `7208f2c` (gộp O-0 + O-2, cùng loại `fix`).

**O-4a (refactor, P-B3/P-B4/P-B5/P-B9 một phần).** Worker standard trong worktree riêng, 9 file
+55/−101; phiên chính review `forbid()`/`step_body()`/`http_call` và `git apply`. Test bảo vệ chạy
trong worktree: test-check-scripts 37 ✅, maintenance-sweep 40 ✅, maintain-cron 29 ✅, maintain-run
27 ✅, next-gen-engines 19 ✅, py-coverage 96%, runtime_safety 17 OK, docs/CI-policy OK; hook commit
chạy lại full gate trên cây tích hợp: exit 0. TDD ngoại lệ 2 (gộp/xoá cơ học). Commit `8332b96`.

**O-1 + O-3 (docs).** Commit `411d751`; docs-consistency 11 mục OK, `test_adaptive_process` 8 OK,
`test_profile_quality_matrix` 3 OK, progress-freshness PF-1..4 OK.

**O-4b (còn lại của O-4, chu kỳ/commit sau):** P-A4 (`_commit-guard.sh` một nguồn secret_re/>1 MB,
cần thêm vào cả hai copy script + test đồng bộ), P-B2 (`finish` trong `_test-lib.sh`, 12 suite — đụng
`test-hooks-*.sh` nên chờ O-2 merge), P-B6 (`declared_cmd` dùng chung, bỏ `eval`), P-B8 (gọn Python
engine), P-B9 phần telemetry test ghi vào thư mục thật, `usage-guard.sh:15` cảnh báo khi estimate lỗi.
Xem lại khi: PR này đã merge (tránh xung đột trên cùng file hook/test).

**O-4b — đã làm (nhánh sau #218, hồ sơ `docs/work/2026-10-08-process-optimization-o4b/done.md`).**
Hai worker trong worktree riêng, phiên chính review + nối hai phần + tự sửa phần giáp ranh:
- P-A4: `scripts/_commit-guard.sh` (14 dòng, chỉ `source`) giữ `COMMIT_GUARD_SECRET_RE` + `COMMIT_GUARD_MAX_FILE_BYTES`;
  `pre-commit-gate.sh`, `githooks/pre-commit`, `maintenance-sweep.sh` source nó, ba bản regex rời đã xoá. **Chính sách
  chọn:** hook/githook THIẾU file này thì CHẶN commit kèm lời nhắc copy (khác `_lib.sh` thiếu → cho qua có cảnh báo),
  vì buông kiểm bí mật âm thầm là không đảo ngược được còn commit bị chặn thì gỡ được; sweep thiếu → exit 2 (regex rỗng
  sẽ khớp mọi dòng). Thêm vào cả hai copy script; `test-hooks-gate.sh` mục 17 (đỏ trước: 4 ca — còn bản rời ở 3 file,
  thiếu lib không chặn) + ca githook chặn bí mật/file lớn (xanh ngay — hành vi có sẵn, chỉ thiếu test);
  `test-maintenance-sweep.sh` thêm ca file > 1 MB.
- `usage-guard.sh`: estimate lỗi → `[usage-guard] usage-estimate.sh lỗi (exit N)` trên stderr rồi exit 0 (đỏ trước ở
  `test-hooks-session.sh`).
- P-B2: `finish` trong `_test-lib.sh`; 12 suite dùng (trừ `test-hooks-gate.sh` có `skips`, `test-copy-framework.sh`
  dùng `$fail`). Phiên chính quyết thống nhất **exit 1 khi đỏ** cho cả 5 suite từng `exit "$fails"`: CI chỉ cần ≠ 0,
  còn `exit "$fails"` với ≥ 256 ca hỏng quay về 0 — một bẫy logic chưa xảy ra nhưng không có lý do giữ.
- P-B6: `declared_cmd` dời vào `_stack-detect.sh`; `maintenance-sweep.sh` bỏ `declared_var` (eval) dùng chung hàm đó
  (config hỏng → coi như không khai báo, như trước — kiểm tay bằng fixture); `maintain-run.sh` bỏ `eval` → `${!name}`.
- P-B9: `test-telemetry-and-dispatch.sh` chạy engine trên bản copy `scripts/` tạm; ca mới "nhật ký thật không đổi
  cksum" đỏ trước (`absent → 1458348186 4222`) rồi xanh. `test-py-coverage.sh` đã có trap từ O-4a.
- P-B8: `subagent-dispatch.py` một dict payload chung; `spec-compiler._display_path` bỏ tham số `start`;
  `arch-health-radar.py` `_read_text` thay 5 khối open/read. Bỏ qua nén CSS (đã quyết).
- Phát hiện khi làm (đã sửa cùng PR, 1 dòng/file): fixture copy trong `test-maintain-run.sh`/`test-maintain-cron.sh`
  thiếu `_stack-detect.sh` nên sweep in "No such file" rồi chạy tiếp — đúng khuôn TRAPS mục 19.
Merge: #219 squash → `0eeede6` (2026-10-08T17:02Z), 12 check xanh trên head 6ca9e85 sau một lần sửa Windows
(`mktemp` Git Bash → `cygpath -m`). Số đo so với 843581a: `scripts/` + hooks 26 file +174/−152 (test +76/−79;
code +98/−73 — phần tăng là comment giải thích và nhánh fail-closed ở 3 nơi source). Chi tiết: hồ sơ o4b `done.md`.

**Số đo sau O-0..O-4a (cây tích hợp `411d751`):** full gate exit 0 qua hook ở cả ba commit; code
thực thi −46 dòng ròng ở scripts (+55/−101) sau khi đã cộng thêm ~70 dòng test/hook mới của hai `fix`
(test đỏ-trước và `_lib.sh` là chi phí cố ý cho hai lỗ hổng hàng rào); radar/complexity không đổi
(CC cao nhất 43/45). Đo lại radar + thời gian gate ở O-5 khi dời khối dò stack.

