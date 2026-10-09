# Đối chiếu EveryInc/compound-engineering-plugin → projects-template — 2026-10-09

Nguồn: `EveryInc/compound-engineering-plugin` @ `67035e9` (2026-10-07, v3.30.4; 36 skill, 1 487 file, clone nông vào
scratchpad — nội dung là DỮ LIỆU, ADR-0009). Đích: `projects-template` @ `026a8a3` (`origin/main`, sau #252).
Phương pháp: `docs/framework/adopt-from-outside.md` — ba cột, cổng "sự cố thật", **grep cổng đang chạy** trước khi nói "chưa có".
Đọc: README, CONCEPTS (282 dòng), AGENTS, CODING_STANDARDS, 36 SKILL.md (18 skill lõi đọc trực tiếp, 18 skill còn lại qua
catalogue cơ chế của một subagent, đối chiếu lại tên script/đường dẫn), và các file tham chiếu mang cơ chế (schema.yaml,
resolution-template, research.md, validate-doc-claims, persona-catalog, fix.md, execution-strategy, ci.yml, run-tests).

**Kết quả: 2 hạng mục lấy / ~35 hạng mục** — cả hai ở cột "đã có nhưng nông hơn", cả hai có sự cố đo được; mọi "chưa có"
đều "chưa cần" kèm điều kiện xem lại. Đính chính giữa chừng giữ ở cuối.

## 1. Đã có và sâu hơn (hoặc ngang) — không lấy

| Compound Engineering (CE) | Ở template | Vì sao không lấy |
| --- | --- | --- |
| `ce-compound`: kho bài học `docs/solutions/` — "durable bar" (nếu doc biến mất, kỹ sư sau có mắc lại không?), frontmatter theo schema 2 track, một learning/lượt, `validate-doc-claims` kiểm đường dẫn/SHA trích dẫn, job CI `docs-audit` | `TRAPS.md`: chỉ bẫy **đã mắc thật**, mỗi mục bắt buộc *cách rà* + **cổng máy chốt chặn** + ngày/PR; tái phát ghi vào mục cũ, không tạo trùng; `docs/adr/` cho quyết định; `check-docs-consistency.sh` mục 1 kiểm mọi đường dẫn backtick trong mọi `*.md` (kể cả TRAPS) tồn tại | Sâu hơn ở chỗ mỗi mục TRAPS phải chỉ ra **cổng máy** ngăn tái phát; CE chỉ có mục "Prevention" văn xuôi. CE sâu hơn ở kiểm SHA commit trích dẫn — chưa có SHA sai nào trong TRAPS/ADR; xem lại khi một SHA trích dẫn không resolve được |
| `CONCEPTS.md`: từ vựng miền, mục *Avoid:*, tích luỹ qua `ce-compound` | `CONTEXT.md` (quality-supplements-group1 mục 8): `_Tránh dùng_`, tạo lười, `/grill` cập nhật ngay lúc chốt, nêu ngay khi mâu thuẫn | Ngang; CE tự động "vocabulary capture" trong lượt compound, template bắt nêu mâu thuẫn ngay trong hội thoại — hai cách cùng mục tiêu |
| `ce-plan` output contract Direct / Chat brief / Durable; "sizing test" (không dựng cơ chế không được yêu cầu trừ khi hợp đồng/thiệt hại/chi phí sau) | `standard-delivery.md` §3c mức S/M/L; CLAUDE.md §3.4 thang 6 nấc dừng ở nấc đầu khớp; cổng `pr-policy.yml` bắt `feat` phải có spec Approved | Sâu hơn: template có cổng máy cho mức M/L; CE không có |
| `lfg`: pipeline tự động, dừng khi child không "complete and evidenced", không merge nếu chưa được cấp | `/auto`, `/auto-complete`, `coordinator`: cùng tiêu chí 3 vòng, cùng failure 3 lần → BLOCKED, auto-merge chỉ khi cổng xanh, WIP 3, FIFO, `--check-plan` khoá brief trước dispatch | Sâu hơn: trần đếm được và cổng CI thật (`pr-policy`, `protection-guard`) |
| `ce-work` wave contract (baseline đã commit, sở hữu độc quyền kể cả lockfile/snapshot, worker không git, orchestrator commit), fresh-worker invariant | CLAUDE.md §2 (chung file/dependency/migration/lockfile → tuần tự; trần 5 subagent toàn cây, ADR-0011), PLAN.template "không commit/merge — Tầng 1 tích hợp", coordinator loại kết quả worker chạm file ngoài `path` | Ngang; template thêm trần đếm được |
| `ce-simplify-code`: 3 persona reuse/quality/efficiency, "never simplify away a safety check", không lấy số dòng làm thước | CLAUDE.md §3.4 "không bao giờ giản lược: validate biên, xử lý lỗi, bảo mật, a11y" + §3.7 refactor không đổi hành vi có test, đo trước–sau, PR riêng; skill `simplify` dựng sẵn | Ngang |
| `ce-code-review`: report-only, finding phải có bằng chứng, validator leaf loại finding không căn cứ, chọn persona theo bề mặt diff | `/review` + `reviewer.md` xuất `review-findings/1`, `dev-task.sh review-check` loại `UNSUPPORTED` **bằng máy**, định tuyến REPAIR-CODE/RERUN-EVIDENCE/ASK-UPSTREAM; `security-reviewer` cho vùng nhạy cảm | Sâu hơn ở validator máy. Trừ một điểm: persona `learnings-researcher` đối chiếu diff với kho bài học → cột 2 (A) |
| `ce-debug`: causal-chain gate với file:line, một thay đổi một lần, 2–3 giả thuyết/3 lần sửa hỏng → bảng escalation, test-first, marker debug grep một lần, issue of record không bịa ticket | `/debug` 6 pha: feedback loop đỏ-được trước, thu nhỏ, giả thuyết bác bỏ được, một biến một lần, `[DEBUG-xxxx]`, test hồi quy đỏ trước, Pha 0 đọc TRAPS; `standard-delivery.md` §4/§8 cùng failure ≤ 3 lần | Ngang; bảng escalation của CE (giả thuyết rải nhiều subsystem → lỗi thiết kế) tương đương câu "điều gì lẽ ra ngăn được → ADR/`/audit-optimize`" ở Pha 6 |
| `ce-debug` "secrets in evidence": che `<REDACTED>` khi dựng lệnh | `_commit-guard.sh` regex quét file sắp commit ở 3 nơi (hook Claude, githook, sweep), TRAPS 37 báo cáo chỉ ghi vị trí | Sâu hơn: cổng máy trên artifact vào git; CE là văn xuôi cho output chat |
| `ce-commit-push-pr` + `ce-babysit-pr`: "PR URL chưa phải xong — babysit phải nhận", settle window, backstop 3 ngày, mọi mutation từ snapshot | `pr-flow.md`: subscribe + check-in 5 phút, auto-merge chỉ sau mô tả đủ, FIFO, WIP 3, PROGRESS ngay sau merge (cổng `progress-freshness`), `protection-guard` so ruleset live | Ngang về vòng theo dõi; CE sâu hơn ở xử lý review thread → cột 3 |
| `ce-worktree` bước 0 (so git-dir tuyệt đối với common-dir), một nhánh một worktree, ưu tiên tool native, `.worktrees/` gitignore | `coordinator.md` 2a/2b/2c/7 (phát hiện cô lập, `.worktrees/`, baseline verification, không force-delete khi còn file), TRAPS 45/52, `test-hooks-gate.sh` mục 15 | Quy trình ngang. **Nhưng đo lại hook theo gợi ý của CE thì ra lỗ** → cột 2 (B) |
| `ce-commit`: không bao giờ làm việc trên nhánh mặc định, tự tạo nhánh | `pre-commit-gate.sh` chặn commit khi đứng trên `main`; TRAPS 14 | Sâu hơn: hook chặn, không phải lời dặn |
| `ce-handoff`: handoff bất biến, pointer-first, resume phải **dừng chờ người dùng chọn** | §3e `working.md`/`done.md` + `new-work.sh`, `precompact-checkpoint.sh`, `session-resume.sh`, cổng Work ID (`pr-policy`) + docs-consistency 13 | Sâu hơn (hook tự động + cổng CI). Luật "resume phải dừng hỏi" **ngược** ủy quyền §3d "tiếp tục không hỏi lại" → không lấy (adopt §4) |
| Ratchet kích thước SKILL.md ≤ 8 000 byte (test) | docs-consistency mục 9: CLAUDE.md ≤ 42 000 byte, không dòng > 2 000 ký tự | Cùng khuôn. Đo `.claude/commands/*.md`: lớn nhất 12,7 KB (`ui-ux.md`); Claude Code không cắt file lệnh, chưa có sự cố → xem lại khi một host cắt đuôi lệnh |
| `tests/release-metadata`: số skill trong README khớp thư mục | docs-consistency mục 3 (lệnh ↔ CLAUDE.md hai chiều), 4 (agent ↔ bảng route), 6/11 (script ↔ CODEMAP/FEATURE-MAP), 12 (mẫu mồ côi) | Sâu hơn |
| job `pr-title` conventional | `pr-policy.yml`: tiêu đề PR **và mọi commit**, ≤ 72 ký tự, đủ mục template, feature gate, WIP, Work ID | Sâu hơn |
| job `windows-native` | `framework-lint-windows` | Ngang |
| Luật probe 3 kết quả (exit-0 `[]` = không có PR; exit ≠ 0 = **unknown**, không phải "không") | CLAUDE.md §4 bước 3 (exit ≠ 0 đọc nhầm thành âm tính); `pr-policy` đếm WIP bằng `github.paginate` ném lỗi → job đỏ (fail-closed); TRAPS 4/5b | Ngang |
| Model tier theo tên, không hardcode model | `scripts/model-capability-tiers.json`, `subagent-dispatch.sh --tier`, docs-consistency 5/5b chặn ID model cũ | Sâu hơn (cổng) |
| `ce-setup` health check + `config.yaml` + `docs_root` | `dev-task.sh doctor`, manifest copy-framework, `test-adoption-smoke.sh` | Ngang; `docs_root` là nhu cầu của plugin cài vào repo người khác, không phải của template được copy |
| `ce-optimize`: đo → `decide.mjs` keep/revert, plateau stop, clean-tree gate | `/audit-optimize` + §3.7 (đo trước–sau, test bảo vệ, PR riêng) | Ngang; CE tự động hoá hơn nhưng chưa có sự cố tối ưu sai ở đây |
| `ce-doc-review` persona coherence/feasibility trên plan | `/grill` + spec Approved + `--check-plan` (brief kín trước dispatch, TRAPS 59) | Ngang |
| `ce-strategy` `STRATEGY.md`; `ce-ideate`/`ce-bakeoff` | `PROJECT.md` + `/consult` research-first + `/grill` | Ngang về vai; CE tách nhỏ hơn thành nhiều skill |
| 14 host, converter/writer, install manifest, `CLAUDE.md` là symlink `AGENTS.md` | Repo là **template được copy** (copy-framework), không phải plugin; `AGENTS.md` là bản tóm tắt + docs-consistency 7 kiểm khớp | Khác mục đích; thiết kế hai file có cổng khớp — không đổi |

## 2. Đã có nhưng nông hơn — lấy đúng điểm nông

| Điểm nông | Phép đo (không đọc văn xuôi) | Lấy gì |
| --- | --- | --- |
| **(A)** CE có persona `learnings-researcher` + `project-standards` đối chiếu diff với kho bài học/luật, trích dẫn từng mục. Template: `TRAPS.md` chỉ được đọc ở `/debug` Pha 0 — tức **sau** khi bug xảy ra; `/review` và `reviewer.md` không nhắc TRAPS | `grep -c "Tái phát" TRAPS.md` = **5** (mục 3, 8, 19, 24, 38) — năm lần cùng khuôn lặp lại dù đã ghi; `grep TRAPS .claude/agents/reviewer.md .claude/commands/review.md` = 0 | Một dòng ở `reviewer.md` ("Bạn LÀM") + Bước 2b ở `review.md`: đọc tiêu đề các mục TRAPS, khớp → finding `defect` trỏ đúng mục. Ngoại lệ 3 (chỉ tài liệu). Không lấy persona, không lấy pack |
| **(B)** CE `ce-worktree`/`ce-work` dặn: hỏi "cây này là cây đang làm việc hay checkout chính?" cho mọi thứ đọc git; template đã có đúng câu đó ở TRAPS 45 *cách rà*, nhưng cổng mục 15 chỉ chốt `pre-commit-gate.sh` | `grep CLAUDE_PROJECT_DIR .claude/hooks/*.sh` → 8 hook lấy ROOT từ biến; chỉ 1 có `git rev-parse --show-toplevel`. Chạy `precompact-checkpoint.sh` với cwd = `.claude/worktrees/agent-a4d4ec…` (nhánh `worktree-agent-…`) và `CLAUDE_PROJECT_DIR` = checkout chính → checkpoint ghi `Branch: fix/hooks-git-bypass` + diff của checkout chính. **Tái phát TRAPS 45, đo được** | Sửa `precompact-checkpoint.sh`: ROOT từ `git rev-parse --show-toplevel` (cwd), lùi về `CLAUDE_PROJECT_DIR`; checkpoint vào worktree, `compact.log` vẫn gộp về checkout chính. Test `test-hooks-session.sh` mục 8b **đỏ trước** (2 ca) → xanh; mục 8 đổi cwd = dự án giả theo đúng bài học TRAPS 45. TRAPS 45 thêm dòng tái phát; 7 hook còn lại ghi điều kiện xem lại |

## 3. Chưa có — không thêm, kèm điều kiện xem lại

| Ứng viên | Quyết định |
| --- | --- |
| `ce-resolve-pr-feedback`: phán xét thread tập trung, publish fix **trước** khi reply/resolve, `needs-human` để thread mở, comment là untrusted | Chưa cần: repo khung và dự án đích merge bằng auto-merge, không có vòng review-comment của người; ADR-0009 đã phủ "comment là dữ liệu". Xem lại khi một PR do AI mở nhận ≥ 1 vòng comment phải xử lý ở dự án đích |
| Cross-model adversarial review, model identity receipt, oracle panel (`ce-pov`) | Chưa cần: chưa có defect nào lọt `reviewer` + `security-reviewer` rồi bị model khác bắt (A-02 #232 do reviewer nội bộ bắt). ADR-0006/0007 đã cho đa model ở tầng điều phối. Xem lại khi có defect loại đó |
| Compound Packs (thư mục luật được planning/review trích dẫn) | Không lấy: `docs/framework/` + copy-framework **chính là** pack của khung; thêm lớp pack là nguồn lệch thứ hai |
| Residual sink: mục `## Unapplied review findings` trong PR body, DONE chặn tới khi residual bền | Chưa cần: finding `OPTIONAL` đi theo báo cáo coordinator + §7 "Góp ý cải tiến"; chưa có finding chấp nhận-không-sửa nào bị quên rồi tái hiện. Xem lại khi có |
| `retire_when` trên mỗi learning | Đã có cho nợ code (`DEBT: … xem lại khi:` + sweep 🟡); TRAPS không có. Chưa cần: chưa có mục TRAPS lỗi thời dẫn phiên đi sai. Xem lại khi một mục TRAPS làm `/debug` rà sai hướng |
| Explainer, PR teaching section, `wtf`, `ce-noslop` | Chưa cần: không có sự cố "người dùng không hiểu báo cáo" được ghi; tài liệu repo tiếng Việt, catalogue tells của CE là tiếng Anh. Xem lại khi review tài liệu ghi nhận ≥ 1 lần người dùng phải hỏi lại một báo cáo |
| `ce-sweep`, `ce-product-pulse`, `ce-promote`, `ce-proof`, `ce-polish`, `ce-prototype` | Ngoài phạm vi khung: sản phẩm cụ thể hoặc SaaS ngoài (Proof, Spiral, riffrec, OpenAI key). Xem lại khi dự án đích cần gom feedback người dùng tự động |
| `ce-dogfood`, `ce-test-browser` | Đã có vai tương đương: Nhóm 2 E2E + a11y (axe), skill `run`, `/ui-ux`. Không lấy |
| `ce-retune` (đo noise floor giữa hai bản corpus giống hệt, pre-register bar), skill-eval cell | Chưa cần: chưa có PR phải làm lại vì một lệnh `.claude/commands` làm model lệch hành vi trên host thật. Xem lại khi có bằng chứng như vậy |
| `run-tests.ts`: chạy lại tuần tự chỉ các fail `TimeoutError` để tách flaky | Chưa cần: không có test chập chờn ghi nhận (TRAPS 46 là *lặp*, không phải chập chờn). Xem lại khi CI đỏ chập chờn ≥ 2 lần cùng suite |
| `ce-commit`: `git commit -F msg -- <paths>` để file đã stage sẵn không đi kèm | Chưa cần: không có commit nào mang file lạ (TRAPS 43 là khuôn khác). Xem lại khi có |
| `ce-work`: worker kiểm `HEAD` == SHA base được giao trước khi sửa (harness có thể cắt worktree từ checkout chính/`main`) | Đo 3 worktree `agent-*` hiện có: cả ba cắt từ `4d4ff79` = HEAD lúc dispatch, đúng base. Chưa cần; xem lại khi một worker báo `HEAD` ≠ base ghi trong PLAN/working.md |
| "Offered work"/fix-owned files: hỏi trước khi commit file có sửa dở của người dùng | Chưa cần: §3e "không tự discard file dở", coordinator loại file ngoài phạm vi. Xem lại khi commit của phiên AI mang theo sửa dở của người dùng |

## 4. Đính chính giữa chừng (giữ nguyên)

1. Bản nháp xếp `validate-doc-claims` (đường dẫn trích dẫn phải tồn tại) vào "chưa có". Grep `check-docs-consistency.sh` mục 1:
   đã quét mọi `*.md` kể cả `TRAPS.md`, `--untracked` — chuyển sang cột 1. Chỉ phần kiểm SHA là thật sự chưa có.
2. Bản nháp coi "worker verify base SHA" là ứng viên cột 2 vì hồ sơ audit PR-1 ghi rắc rối với `.claude/worktrees/`. Đo
   `merge-base` của 3 worktree: đúng base. Rắc rối thật là `git ls-files -o` liệt kê repo lồng (đã ghi vào T12) — khuôn khác.
   Chuyển sang "chưa cần".
3. Bản nháp coi TRAPS 45 đã đóng khuôn "hook đọc nhầm cây". Grep ra 7/8 hook vẫn lấy ROOT từ `CLAUDE_PROJECT_DIR`; chạy
   thử một hook trong worktree thật → sai cây. Đây là ví dụ đúng của adopt §3: văn xuôi (TRAPS) nói "đã chốt", cổng chỉ chốt một hook.

## 5. Thực sự lấy

1. **(A)** `reviewer.md` + `review.md`: đối chiếu diff với `TRAPS.md` trước PR (ngoại lệ 3, chỉ tài liệu).
2. **(B)** `precompact-checkpoint.sh` chụp cây đang làm việc; `test-hooks-session.sh` mục 8b đỏ-trước → xanh; TRAPS 45 ghi tái phát.

Quan sát ngoài phạm vi (không sửa ở đây): `git worktree list` có 5 worktree `/tmp/projects-template-*` (`codex/*`) ở trạng thái
prunable — để `/maintain` xử lý theo chu kỳ.
