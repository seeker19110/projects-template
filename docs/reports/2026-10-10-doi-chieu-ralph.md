# Đối chiếu snarktank/ralph → projects-template — 2026-10-10

Nguồn: `snarktank/ralph` @ `6c53cb0` (2026-02-02; `ralph.sh` 113 dòng, `prompt.md`/`CLAUDE.md` mẫu prompt, `prd.json.example`,
hai skill `prd`/`ralph`, plugin manifest, flowchart React). Đích: `projects-template` @ `026a8a3` (`origin/main`, sau PR #251).
Phương pháp: `docs/framework/adopt-from-outside.md` (ba cột, cổng sự cố thật, **grep cổng đang chạy**).

**Kết quả: 25 hạng mục → lấy 0.** Ralph là tập con của khung ở mọi hạng mục đo được; phần duy nhất khung chưa có
(vòng lặp ngoài không giám sát, mỗi lượt một tiến trình CLI mới) mắc đúng điều kiện xem lại đã ghi ở hai lần đối chiếu
trước và **vẫn chưa xảy ra**, đồng thời đụng threat model của khung — đưa người dùng quyết (cuối file).

## Ralph là gì (một đoạn, để bác lại được)

Một vòng `for i in 1..N` gọi `claude --dangerously-skip-permissions --print < CLAUDE.md` (hoặc `amp`), mỗi lượt một tiến
trình mới, ngữ cảnh trống. Prompt bảo agent: đọc `prd.json` (user story có `passes: false/true`), đọc `progress.txt`, chọn
story ưu tiên cao nhất chưa pass, làm, chạy typecheck/test, commit `feat: [ID] - [title]`, đặt `passes: true`, append
learnings vào `progress.txt` và `CLAUDE.md`/`AGENTS.md` cạnh file đã sửa. Hết story thì in `<promise>COMPLETE</promise>`
và vòng lặp thoát. Không PR, không review, không cổng máy — mọi "cổng" là câu trong prompt.

## Phép đo đã chạy (không đọc văn xuôi)

```bash
grep -rn -i "claude -p|--print|dangerously-skip|phiên mới|max.iter" scripts .claude docs/framework  # vòng lặp/headless
grep -n "một outcome|3 lần|BLOCKED|stop condition" docs/framework/standard-delivery.md             # goal loop
grep -n "goals" scripts/*.sh scripts/*.py                                                           # cổng cho docs/goals → 0 kết quả
grep -n "def _check_" scripts/_plan_check.py                                                        # cổng brief/phụ thuộc
grep -n "^## " TRAPS.md | grep -i "ngữ cảnh|nén|quên|lặp|phiên"                                     # sự cố ngữ cảnh → 0
grep -rn -i "mất ngữ cảnh|tràn ngữ cảnh|lặp vô hạn|phải tách.*PR" TRAPS.md docs/work docs/reports   # → 0 sự cố
ls .claude/hooks; grep -n "flock|working tree|maint/auto" scripts/maintain-cron.sh                   # hàng rào runner
```

## Ba cột

### Đã có và SÂU HƠN (21)

| Ralph | Ở khung | Sâu hơn ở chỗ nào |
| --- | --- | --- |
| Vòng lặp "chọn một story → làm → kiểm → commit → lặp" | Goal Loop `standard-delivery.md` §4 + `/auto-complete` | Mỗi vòng **reconcile lại từ `main` + CI thật**, một outcome = một PR, cùng failure tối đa 3 lần → BLOCKED (§8); ralph không reconcile, không trần sửa lỗi. |
| `prd.json` với `passes: true/false` | `docs/goals/<id>.md` bảng slice có cột State **và Evidence**; `spec-compiler.sh --trace` nối AC → test | `passes` là **lời tự khai** của model; khung đòi bằng chứng gắn HEAD (`dev-task.sh gate --evidence` + `evidence-check`, LD-03). Xem đính chính (B) bên dưới. |
| Điều kiện dừng `<promise>COMPLETE</promise>` | Definition of Complete §7 có bằng chứng trên default branch; `/auto-complete` chỉ kết khi DoC có bằng chứng | Chuỗi hứa hẹn do model in ra là đúng thứ CLAUDE.md §4 cấm tin ("không tin lời khai"); khung dừng theo **trạng thái đo được**. |
| "Chạy typecheck/test trước khi commit" (câu trong prompt) | Hook `pre-commit-gate.sh` **chặn cứng** `git commit` đỏ qua `dev-task.sh gate`; CI required checks | Ralph không có gì ngăn agent commit khi test đỏ ngoài lời hứa; khung chặn bằng máy, có test hook (`test-hooks-gate.sh`). |
| `progress.txt` append learnings + mục "Codebase Patterns" | `TRAPS.md` (khuôn → cách rà → **cổng chốt chặn** → tái phát), `CONTEXT.md`, `CODEMAP.md`, `docs/work/<id>/working.md` | Learnings ở khung có cấu trúc, có cổng (`maintenance-sweep.sh`, `check-docs-consistency.sh`) và đánh dấu tái phát; `progress.txt` là văn xuôi tự do không ai kiểm. |
| Bộ nhớ giữa lượt = git + progress.txt + prd.json | `working.md` + `PROGRESS.md` + hook `session-resume.sh` (SessionStart nạp trạng thái) + `precompact-checkpoint.sh` + cổng CI `progress-freshness` (PF-1..4) | Khung có **cổng đo PROGRESS lỗi thời so với git** (sự cố thật 2026-09-12); ralph không có gì bắt `progress.txt` lệch thực tế. |
| AC phải kiểm được; luôn thêm "Typecheck passes" | `FEATURE-SPEC.template.md` AC Given/When/Then + bảng AC → bằng chứng; `_spec_contract_gen.py` sinh contract test từ spec | Khung máy-đọc AC thành test; ralph chỉ có hướng dẫn viết câu. |
| Skill `prd` (9 mục) | `PROJECT.md` + `FEATURE-SPEC.template.md` (20 mục: non-goal, threat, a11y, rollout/rollback, telemetry…) + cổng `pr-policy.yml` đòi spec Approved cho `feat` | Spec ở khung là **cổng** trước khi sửa source; PRD của ralph không ràng buộc gì. |
| Hỏi 3–5 câu làm rõ, lựa chọn A/B/C | `/grill` hỏi theo **đợt**, mỗi câu kèm đề xuất, **tự tra sự kiện** thay vì hỏi người dùng | Định dạng "1A, 2C" là tiện nghi hiển thị; không có sự cố nào về cách trả lời. Không lấy. |
| Thứ tự story theo phụ thuộc (schema → backend → UI) | `PLAN.template.md` trường `Phụ thuộc` + `_plan_check.py::_check_dependency_cycle` (cổng `subagent-dispatch.sh --check-plan`) | Khung phát hiện **chu trình** phụ thuộc bằng máy; ralph là lời khuyên. |
| Lưu trữ lượt cũ `archive/<ngày>-<feature>/` | `docs/work/<id>/done.md` (rename, không overwrite) + `docs/changelog/`; cổng docs-consistency mục 13 (đúng một trong working/done) | Có cổng; ralph copy file bằng tay trong script. |
| Nhánh `ralph/<feature>` từ `branchName` | §8 `feat/`/`fix/` + hook `block-dangerous-git.sh` + `pr-policy.yml` (WIP ≤ 3, Work ID) | Ralph **không mở PR**; khung bắt mọi merge qua PR + squash + auto-merge khi xanh. |
| Commit luôn `feat: [ID] - [title]` | Conventional commits đủ type + `_commit-guard.sh` + TRAPS 58 (độ dài tiêu đề) + release-please | Gắn `feat:` cho mọi thứ làm CHANGELOG tự sinh sai; khung phân type theo bản chất thay đổi. |
| "Verify in browser" cho story UI (model tự kiểm) | `quality-gates-by-profile.md` C1: E2E Playwright + axe + Lighthouse CI **trên CI** | Kiểm tra là job CI lặp lại được, không phải model tự nhìn rồi khai. |
| Cập nhật `CLAUDE.md`/`AGENTS.md` cạnh file đã sửa mỗi lượt | `CLAUDE.md` < 200 dòng là **luật**; learnings đi `TRAPS.md`/`CONTEXT.md`/`CODEMAP.md`; `AGENTS.md` phải khớp `CLAUDE.md` (cổng docs-consistency) | Mâu thuẫn luật — xem §Mâu thuẫn. |
| `--tool amp\|claude` | `maintain-run.sh --harness auto\|claude\|hermes\|gemini\|codex\|opencode\|print`; `subagent-dispatch.sh` nạp vai cho mọi harness | 6 harness, cú pháp đã xác minh, có test (`test-maintain-run.sh`). |
| Amp auto-handoff ở 90% ngữ cảnh | §5.2.1: trần 500k, `CLAUDE_CODE_AUTO_COMPACT_WINDOW`/`PCT_OVERRIDE=90` trong settings, bảng cấu hình cho 6 runner, hook precompact | Ralph chỉ có một dòng settings Amp. |
| Story "vừa một cửa sổ ngữ cảnh", mô tả được trong 2–3 câu | §3c S/M/L, "một iteration = một outcome + một PR", radar chặn file > 400 dòng | Khung chưa có **cổng** đo cỡ slice, ralph cũng không — ngang nhau về cưỡng chế; không có sự cố "PR quá to phải tách" trong TRAPS/work → không lấy heuristic. |
| Plugin manifest / marketplace | `copy-framework.manifest` + `copy-framework.sh`/`copy-framework.ps1` + `test-copy-framework.sh` (job `copy-framework-smoke`) | Ranh giới đã ghi (đối chiếu X-Agents v2): template **không vendor plugin**; lệnh phát sang đích qua manifest có test idempotent. |
| Khoá tiến trình/hàng rào cho chạy không giám sát | `maintain-cron.sh`: flock, working tree sạch, chỉ push `maint/auto-*`, `--force-with-lease`, chỉ `git add` 3 file, threat model riêng + `test-maintain-cron.sh` | `ralph.sh` không có khoá, không kiểm working tree, `set -e` nhưng `\|\| true` sau lệnh agent. |
| Lệnh debug `jq '.userStories[] \| {id,passes}'` | `docs/work/*/working.md`, `arch-health-radar.sh`, `maintenance-sweep.sh` | Tầm thường; không có gì để lấy. |

### Đã có nhưng NÔNG HƠN (0 đo được)

Không có điểm nào đo được. Ghi nhận hai ứng viên bị loại sau khi đo (xem Đính chính (A), (B)).

### CHƯA CÓ (4) — không lấy, kèm điều kiện xem lại

| Ứng viên | Quyết định |
| --- | --- |
| **Vòng lặp ngoài không giám sát: mỗi lượt một tiến trình CLI mới (ngữ cảnh trống), N lượt, dừng khi xong** (`ralph.sh`) | **Chưa cần.** Điều kiện xem lại đã ghi 2 lần (`2026-10-06-doi-chieu-x-agents-v2.md`, `…-v3.md`): "khi có phiên mất ngữ cảnh được tái hiện" — grep `TRAPS.md`/`docs/work`/`docs/reports` hôm nay: **0 sự cố**. Khung đã có luật hành vi tương đương ("mở phiên mới sau mỗi mảng", `models-and-automation.md` §5 dòng 206; wind-down + resume trong `/auto`). Ngoài ra còn đụng threat model (xem §Mâu thuẫn). **Xem lại khi:** (a) một phiên/subagent đo được > 450k token hoặc tái hiện được mất ngữ cảnh, HOẶC (b) chủ repo quyết định cho phép **sửa source không giám sát** (hiện `maintain-cron.sh` chỉ được ghi `docs/ops/MAINTENANCE-*.md`). |
| Trần số lượt `max_iterations` | Chưa cần: chỉ có nghĩa khi có vòng lặp ngoài; khung dừng theo §8 (3 lần cùng failure, budget trong `GOAL.template.md`). Xem lại cùng mục trên. |
| `<promise>COMPLETE</promise>` làm tín hiệu thoát cho script | **Không lấy dù có vòng lặp**: mâu thuẫn CLAUDE.md §4 (lời khai ≠ bằng chứng). Nếu một ngày có vòng lặp ngoài, tín hiệu dừng phải đọc từ trạng thái đo được (goal file State + PR merged + evidence), không từ chuỗi model in ra. |
| Flowchart React, ảnh minh hoạ | Ngoài phạm vi (tài liệu trình bày của ralph, không phải thực hành). |

## Mâu thuẫn luật (§4 của phương pháp) — không tự hoà giải

| Ralph | Luật đang có ở khung | Hệ quả nếu chép |
| --- | --- | --- |
| `claude --dangerously-skip-permissions` chạy không giám sát, commit thẳng nhánh, không PR | `docs/ops/threat-model-maintain-cron.md` + ADR-0009: đường chạy không giám sát duy nhất chỉ được ghi file báo cáo, không sửa source, không merge; quyết định 2026-10-09 (hồ sơ audit-full-automation): **không** bake `dontAsk` vào settings dùng chung | Cấy một đường ghi source không có người duyệt tại chỗ — đúng thứ threat model loại trừ. Là quyết định của chủ repo (§9: quyền mới), không phải của phiên này. |
| Mỗi lượt cập nhật `CLAUDE.md`/`AGENTS.md` với learnings | `CLAUDE.md` < 200 dòng; `AGENTS.md` là bản tóm tắt phải khớp `CLAUDE.md` (cổng docs-consistency); learnings đi `TRAPS.md`/`CONTEXT.md` | Hai sổ luật phình và lệch nhau; cổng docs-consistency đỏ. |
| Mọi commit là `feat:` | Conventional commits đúng type (§8), release-please sinh CHANGELOG từ type | CHANGELOG sai; cổng `fix:` cần test đỏ-trước (§3.6) bị né bằng nhãn. |
| Skill `prd` **luôn** hỏi 3–5 câu trước | `/grill` chỉ hỏi phần không tự tra được; CLAUDE.md §9 dừng-hỏi chỉ 3 trường hợp; §3d không hỏi lại việc đã ủy quyền | Đúng ví dụ mâu thuẫn ghi sẵn ở `adopt-from-outside.md` §4. |

## Đính chính giữa chừng (giữ nguyên dấu vết)

- **(A)** Lúc đọc README, xếp "vòng lặp ngoài" vào *chưa có* hoàn toàn. Sau khi grep: Goal Loop §4, `/auto-complete`,
  `maintain-run.sh` (6 harness, `claude -p`), hook resume/precompact, §5.2.1 phủ **mọi thành phần** trừ đúng một thứ —
  tiến trình mới mỗi lượt khi không có người. Thu hẹp ứng viên xuống đúng điểm đó rồi mới áp cổng §2.
- **(B)** Định xếp `prd.json`/`passes` vào *nông hơn* vì "máy đọc được bằng `jq`". Đo: `grep -n goals scripts/*` → **0** —
  khung cũng **không có script nào đọc `docs/goals/`**; cột State của goal file hiện chỉ là văn bản. Vậy về cưỡng chế
  hai bên ngang nhau; khung chỉ sâu hơn ở **ngữ nghĩa** (Evidence thay vì lời khai). Không lấy `passes`
  (lời khai), nhưng ghi nhận: *goal file chưa có cổng* — xem lại khi một goal ghi COMPLETE mà audit phát hiện slice
  chưa có bằng chứng/PR chưa merge (chưa xảy ra: goal `2026-10-08-framework-completion` đóng có PR #216/#217).
- **(C)** Ứng viên "heuristic cỡ story 2–3 câu" bị loại vì không tìm được sự cố PR quá to phải tách
  (`grep -i "phải tách|PR quá" TRAPS.md docs/work docs/reports` → 0). TRAPS 59 là về brief chưa kín, không phải cỡ.

## Bản đồ từ vựng ralph → khung (cho người quen ralph dùng khung, kể cả ở dự án đích)

| Muốn làm như ralph | Ở khung dùng |
| --- | --- |
| Viết PRD rồi chuyển thành danh sách story | `/grill` → `docs/specs/<ngày>-<slug>.md` (FEATURE-SPEC) → `docs/goals/<id>.md` bảng slice (`GOAL.template.md`) |
| Chạy vòng lặp "tới khi xong" | `/auto-complete` (một phiên, tự duyệt theo §3d, dừng ở §9/BLOCKED) |
| Ngữ cảnh mới cho mỗi mảng | Hết một mảng: `/gate` → commit → cập nhật `PROGRESS.md`/`working.md` → mở phiên mới, nhắn "tiếp tục" (`session-resume.sh` nạp lại) |
| `progress.txt` | `docs/work/<id>/working.md` (checkpoint) + `TRAPS.md` (khuôn lỗi) + `CONTEXT.md` (thuật ngữ) |
| `passes: true` | Hàng slice State = DONE **kèm** cột Evidence (PR merged + `spec-compiler.sh --trace`) |
| Chạy bằng Amp/Codex/Hermes thay Claude | `scripts/subagent-dispatch.sh --harness generic`; runner không giám sát: chỉ `maintain-run.sh`/`maintain-cron.sh` |

Dự án đích nhận toàn bộ bảng trên qua `copy-framework` (docs/framework, `.claude/commands`, scripts) — **không cần file mới**.

## Danh sách thực sự lấy

Không có. Thay đổi của PR này chỉ là bản đối chiếu này + hồ sơ công việc + con trỏ ở `PROGRESS.md`.

## Quyết định cần chủ repo (không tự quyết — §9 "quyền mới")

Có muốn khung cung cấp một **runner xây dựng không giám sát** kiểu `ralph.sh` (mỗi lượt một tiến trình CLI mới, được
sửa source + commit lên nhánh riêng, mở PR, không merge) hay không? Đề xuất của phiên này: **chưa** — vì (1) chưa có sự cố
ngữ cảnh nào tái hiện được sau ba lần đối chiếu, (2) phải viết threat model mới trước (§9 standard-delivery: automation →
threat model trước implementation), (3) `dontAsk`/skip-permissions đã bị từ chối cho settings dùng chung ngày 2026-10-09.
Nếu chủ repo quyết **có**, việc đó là mức L: spec + goal + threat model, tái dùng hàng rào của `maintain-cron.sh`
(khoá, working tree sạch, chỉ nhánh riêng, không merge), tín hiệu dừng đọc từ goal file/PR chứ không từ chuỗi model in.

**Kết luận 2026-10-10:** chủ repo trả lời "chọn phương án tốt nhất" (ủy quyền §3d). Phiên chính chọn **chưa làm** runner
không giám sát — đúng bậc 1 của thang ưu tiên §3d (bảo mật: không mở đường ghi source không có người duyệt khi chưa có
threat model) và đúng cổng §2 của phương pháp (không có sự cố). Điều kiện xem lại giữ nguyên: (a) một phiên/subagent đo
được > 450k token hoặc tái hiện được mất ngữ cảnh, hoặc (b) chủ repo cần sửa source không giám sát — khi đó mở hồ sơ mức L
(spec + goal + threat model) chứ không chép `ralph.sh`. Phương án bị loại: (b) chép `ralph.sh` nguyên trạng (mâu thuẫn 4 luật);
(c) runner "có giám sát một nửa" (vẫn là đường ghi source không người duyệt → cần threat model như (b), không rẻ hơn).
