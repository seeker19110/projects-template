# TRAPS.md — bẫy đã mắc trong repo này

> Sổ bẫy ĐÃ MẮC THẬT của chính bộ khung này, không phải danh sách "nên tránh" chung chung. Mỗi mục
> có ngày + PR/commit + cách rà + test/cổng chốt chặn. Khác `docs/adr/` (ghi **quyết định**): file
> này ghi **lỗi đã xảy ra**. Mẫu rỗng cho dự án đích: `docs/framework/templates/TRAPS.template.md`.
>
> Cách dùng: gặp lỗi lạ → tìm khuôn khớp ở đây trước khi đọc code từ đầu (`/debug` Pha 1 đọc file
> này trước khi ra giả thuyết). Sửa xong → thêm mục mới nếu là khuôn mới, hoặc thêm ngày/PR vào mục
> cũ nếu là **tái phát**.

## 1. Dropins chưa từng biên dịch thì không "chắc chạy được"

Repo khung cố ý không có `package.json` (nó là drop-in cho `create-next-app`) — nên `app/*.tsx`,
`lib/env.ts`, `components/*.tsx`, `eslint.config.mjs`, `vitest.config.ts` **chưa từng được lint hay
biên dịch lần nào** trước khi phát cho dự án đích. Chạy `verify-dropins.sh` lần đầu (dựng dự án
Next.js sạch, copy khung vào, `lint`/`type-check`/`build`/`test` thật) bắt ngay 2 lỗi có sẵn:
`components/theme-toggle.tsx` vi phạm `react-hooks/set-state-in-effect` (rule React Compiler của
`eslint-config-next` bản mới), và `app/sw.ts` không type-check (`TS2552` thiếu lib `webworker`).
*Cách rà*: bất kỳ file dropins mới nào — hỏi "đã có lượt `verify-dropins.sh` nào biên dịch nó chưa,
hay mới chỉ được đọc bằng mắt?". *Chốt chặn*: `scripts/verify-dropins.sh` + `verify-dropins.yml`
(chạy khi PR đụng dropins, hằng đêm, và theo yêu cầu — lịch hằng đêm cũng là cảm biến version drift
vì dùng `create-next-app@latest`). (2026-08-08, PR #43)

## 2. `copy-framework.ps1` cần BOM cho PowerShell 5.1, dù `.sh` không cần

Windows PowerShell 5.1 mặc định đọc script theo ANSI; file UTF-8 **không BOM** làm hỏng ký tự tiếng
Việt và gây lỗi parse (`Missing closing '}'`, chuỗi bị cắt sớm ở ký tự em-dash). PowerShell 7 đọc
UTF-8 không BOM nên **không lộ lỗi khi test bằng PowerShell 7** — bẫy ẩn đúng ở chỗ máy dev hiện đại
không thấy gì sai. *Cách rà*: mọi thay đổi `.ps1` phải test bằng PowerShell **5.1** thật (không chỉ
pwsh 7), và kiểm byte đầu file là `EF BB BF`. *Chốt chặn*: ghi chú "PHẢI lưu UTF-8 có BOM" ở đầu file
+ `.gitattributes` giữ nguyên BOM (`*.ps1 text eol=lf`) + `[Console]::OutputEncoding = UTF8`
(try/catch) để chữ tiếng Việt in đúng. (2026-07-01, PR #18, commit `59a280f`)

## 3. `copy-framework.sh` thiếu file → hàng rào ở dự án đích no-op ÂM THẦM

`copy-framework.sh`/`.ps1` từng **không copy** `scripts/dev-task.sh` + `usage-estimate.sh` sang dự án
đích. Hệ quả không phải lỗi ồn ào: hook auto-format, cổng chặn commit đỏ, và nhắc quota ở dự án đích
đều **lặng lẽ thành no-op** — dự án đích tưởng mình có hàng rào nhưng không có gì chạy. Cùng PR, bản
`.sh` còn có lỗi `cp -R` gây **lồng thư mục** khi chạy script lần hai (`docs/framework/framework`,
`hooks/hooks`) — bản `.ps1` đã làm đúng, `.sh` thì chưa. *Cách rà*: sau bất kỳ thay đổi cấu trúc
`docs/framework/`, `.claude/`, `scripts/` — chạy `copy-framework.sh` **hai lần liên tiếp** vào cùng
một thư mục scratch, đếm số file, kiểm không lồng. *Chốt chặn*: `scripts/test-copy-framework.sh`
(chạy cả `.sh` và `.ps1`, chạy lại lần hai để bắt đúng lỗi lồng thư mục này). (2026-07-02, PR #27, commit `6a4ac40`)

**Tái phát 2026-10-05 (CI drop-in):** hai bản copy phát nguyên `ci.yml` nội bộ của repo khung,
nhưng CI đó gọi `scripts/test-check-scripts.sh` và các suite khác không được copy sang đích.
Smoke Node/Python với ca đỏ-trước bắt cả hai đích thất bại. *Chốt chặn*: CI đích có template
riêng `docs/framework/templates/ci-target.yml`; `scripts/test-adoption-smoke.sh` xác nhận mọi
script được CI gọi tồn tại sau copy và bản Bash/PowerShell phát cùng nội dung.
Config `.claude/project-commands.sh` còn bị ignore mặc định: smoke clone sạch
kiểm `doctor` BLOCKED trước khi track, rồi READY/gate PASS sau khi review và force-add.

## 4. Job CI mới thiếu `permissions:` tường minh → 403 im lặng đến khi chạy PR thật

`gitleaks-action` liệt kê commit của PR qua GitHub API; `GITHUB_TOKEN` mặc định (workflow-level
`contents: read`) thiếu quyền `pull-requests: read` nên action trả `403 Resource not accessible by
integration`. Lỗi này **không xuất hiện khi đọc YAML hay chạy `bash -n`** — chỉ lộ ra khi job thật
chạy trên một PR. *Cách rà*: thêm job CI mới gọi GitHub API (không chỉ chạy shell nội bộ) → tự hỏi
"job này cần quyền gì trên `GITHUB_TOKEN` ngoài `contents: read` mặc định?" trước khi mở PR đầu tiên
dùng job đó. *Chốt chặn*: khai `permissions:` tường minh ở cấp job (không dựa vào mặc định của repo/
tổ chức) — nguyên tắc này đã lan ra mọi workflow của khung (`ci.yml`, `lighthouse-ci.yml`,
`codeql.yml`…). (2026-06-30, commit `366aeec`)

## 5. ShellCheck bắt lỗi ở file `.example.sh` không có shebang (SC2148)

Ngay lần chạy đầu của job `framework-lint` mới thêm (bash -n + ShellCheck mức error), CI đỏ vì
`project-commands.example.sh` và `usage-budget.example.sh` không có `#!/usr/bin/env bash` —
ShellCheck không xác định được target shell. Cả hai file được `source` bằng bash
(`dev-task.sh: . "$DECL"`), nên shebang không chỉ để né lint mà đúng là thiếu sót thật.
*Cách rà*: mọi file `.sh`/`.example.sh` mới phải có shebang **trước khi** commit, không chờ CI báo.
*Chốt chặn*: job `framework-lint` (`bash -n` mọi `*.sh` + `shellcheck --severity=error`) — chạy cả
khi repo khung chưa có `package.json`. (2026-07-02, PR #27, commit con trong `6a4ac40`)

## 6. `verify-dropins.sh` đỏ vì ERESOLVE — thiếu bump cùng lượt của một transitive dependency

Thêm `vitest` vào lệnh cài của `verify-dropins.sh` mà không nâng `@types/node` cùng lượt → `npm ci`
báo `ERESOLVE` (xung đột phiên bản peer dependency), làm job `verify-dropins` đỏ từ 2026-09-04 mà
không ai để ý ngay vì workflow đó chỉ chạy khi PR đụng dropins, hằng đêm, hoặc theo yêu cầu — không
chạy trên mọi PR như `ci.yml`. *Cách rà*: thêm/nâng một dependency cài trong `verify-dropins.sh` →
chạy `npm ci` thật ở bước đó (không chỉ `npm install` cục bộ có cache cũ) trước khi tin cổng xanh.
*Chốt chặn*: `verify-dropins.yml` chạy hằng đêm (không chỉ khi có PR đụng dropins) — nhưng bài học
thật là: **cổng chạy không thường xuyên (hằng đêm/theo yêu cầu) cần được xem lại log định kỳ**, không
chỉ dựa vào nó tự báo đỏ trên PR đang mở. (2026-09-06, PR #61, commit `d0baf40`)

## 5b. Cổng đòi thứ bot không thể có → PR bảo mật kẹt vĩnh viễn, nhìn như "PR chưa đạt chuẩn"

**Ngày/PR:** 2026-09-12, audit toàn diện (F-001) — bẫy đã âm thầm hoạt động từ 2026-08-24.

**Khuôn lỗi:** required check `pr-policy.yml: metadata` yêu cầu PR body chứa 6 mục của PR template.
Dependabot không điền được → check **không bao giờ xanh** → 5 PR nâng cấp (3 trong đó là công cụ
bảo mật: gitleaks, dependency-review, codeql) kẹt 19 ngày. Nhìn từ ngoài giống "PR chưa đạt chuẩn,
chờ người bổ sung", nên không ai lần ra rằng nó **không thể** đạt chuẩn.

Tổng quát: **cổng áp cho tác nhân không có khả năng thoả mãn nó** biến thành deadlock im lặng.
Nguy hiểm hơn cổng thiếu, vì nó trông như đang làm việc.

**Cách rà:**
- Với mỗi required check, hỏi: *ai/cái gì tạo PR loại này, và họ CÓ THỂ làm nó xanh không?*
  (dependabot, renovate, github-actions, release-please…)
- Có PR nào mở > 7 ngày với cùng một check đỏ? → `list_pull_requests` + xem `conclusion` của
  workflow run theo nhánh. PR bot cũ đọng lại là dấu hiệu, không phải sự lười.

**Cổng chốt chặn:** `pr-policy.yml` miễn trừ `BOT_ACTORS` khỏi yêu cầu mục template (vẫn giữ kiểm
tiêu đề conventional). Chưa tự động hoá được phần "phát hiện PR đọng" — xem W-105.

## 6b. `git checkout <file>` xoá sạch thay đổi chưa commit — không cần `reset --hard`

**Ngày/PR:** 2026-09-12, trong lúc chạy `/completion` Pha 3.

**Khuôn lỗi:** chạy negative test bằng cách xoá `docs/FEATURE-MAP.md` rồi `git checkout` để phục
hồi — lệnh này lấy lại **bản đã commit**, nên mọi sửa chưa commit trong file đó (một sửa tham
chiếu backtick) biến mất không cảnh báo. `block-dangerous-git.sh` chặn `reset --hard` nhưng
**không** chặn `checkout <file>` / `restore <file>` vì hai lệnh này dùng hợp lệ hàng ngày.

**Cách rà:** trước khi `git checkout/restore <file>`, chạy `git diff -- <file>` — có output nghĩa
là đang sắp mất phần đó. Với negative test, nên copy file ra scratchpad rồi copy trả lại, **không**
dùng `git checkout`.

**Cổng chốt chặn:** không có cổng máy (chặn `checkout` sẽ gây khó chịu hơn lợi). Chốt bằng quy ước
trong `docs/CONVENTIONS.md` §A: negative test phải phục hồi bằng `cp` từ bản sao, không bằng Git.

## 7. PR dependabot chỉ sửa file TỒN TẠI LÚC NÓ ĐƯỢC TẠO — file mới mang lại phiên bản cũ

**Ngày/PR:** 2026-09-12, ngay sau khi merge #64 rồi #53–#57 (W-101).

**Khuôn lỗi:** PR #53 (tạo 24/08) nâng `actions/github-script` 7.0.1 → 9.0.0 trong 2 file có mặt
lúc đó. Một giờ trước khi merge nó, PR #64 thêm `.github/workflows/stale-pr-alert.yml` — và tôi
copy dòng `uses:` từ một workflow cũ, tức **ghim lại v7.0.1 (node20)**. Merge cả 5 PR dependabot
xong, `main` **vẫn còn** một action node20: chính file tôi vừa thêm. Thay đổi của tôi mang ngược
vào đúng vấn đề mà PR đó đang sửa.

Tổng quát: PR dependabot là **ảnh chụp danh sách file tại thời điểm tạo**. Thêm file mới trong lúc
PR dependabot đang treo → file mới không nằm trong phạm vi nó. Dependabot sẽ mở PR mới ở lượt quét
sau (hệ thống tự lành), nhưng khoảng giữa thì `main` sai mà mọi check đều xanh.

**Cách rà:** sau khi merge một loạt PP dependabot, **đo lại trên `main`** thay vì tin số PR đã merge:

```
grep -rhoE "uses: [^ ]+@[0-9a-f]{40}" .github/workflows/*.yml | sed 's/uses: //' | sort -u \
| while read ref; do repo="${ref%@*}"; sha="${ref#*@}"; \
    curl -sS "https://raw.githubusercontent.com/$repo/$sha/action.yml" | grep -oE "node[0-9]+" | head -1; done
```

Khi copy một dòng `uses:` từ workflow khác: kiểm xem có PR dependabot đang treo cho action đó không.

**Cổng chốt chặn:** `check-ci-policy.sh` CP-2 chỉ kiểm *đã ghim SHA*, **không** kiểm runtime — kiểm
runtime cần gọi mạng, mà cổng phải chạy offline. Chốt bằng quy ước: lệnh đo ở trên chạy tay sau mỗi
lượt merge dependabot (đã ghi vào `docs/CONVENTIONS.md` §D).

## 8. `PROGRESS.md` lỗi thời sau khi PR merge — mô tả nhánh "đang làm" đã thực ra đã merge

**Ngày/PR:** 2026-09-12, phát hiện khi người dùng yêu cầu quét kỹ lại sau `/audit-full`.

**Khuôn lỗi:** `PROGRESS.md` ghi "Nhánh đang làm: `claude/remove-web-scaffold-layer2`... đang hoàn
thiện trên nhánh riêng trước khi mở PR", nhưng thực ra PR #67 (nhánh đó) **đã merge từ trước**, và
PR #68 sau đó cũng đã merge — không phiên nào quay lại cập nhật file. Vì `PROGRESS.md` là văn xuôi
tự do, không có gì đối chiếu nó với git thật, nên lệch **hoàn toàn im lặng**: phiên sau đọc phải
trạng thái cũ, dễ tưởng còn việc dở (mở PR cho nhánh đã không còn tồn tại) hoặc bỏ sót việc mới
(PR #68) đã xong.

Tổng quát: **bất kỳ tài liệu trạng thái nào mô tả một mốc git (nhánh/SHA/PR) đều có thể lỗi thời
ngay khi mốc đó thay đổi mà không ai quay lại sửa** — không có cổng máy đối chiếu là lỗi chắc chắn sẽ
xảy ra, chỉ là chưa biết lúc nào.

**Cách rà:** trước khi tin `PROGRESS.md`, đối chiếu nhanh: `git branch -r` xem nhánh nêu tên còn
tồn tại không; `git log origin/main` xem SHA "đã đối chiếu" có phải HEAD hiện tại không.

**Cổng chốt chặn:** `scripts/check-progress-freshness.sh` (PF-1: SHA đã đối chiếu là tổ tiên của
HEAD; PF-2: nhánh nêu trong "Nhánh đang làm" còn tồn tại trên remote) + job CI `progress-freshness`
(chỉ chạy khi push vào `main`, `needs:` của `gate`) + `CLAUDE.md` §8 bắt buộc cập nhật `PROGRESS.md`
ngay sau khi quay về `main`.

## 9. Nhãn "C1 — MẶC ĐỊNH" gây thiên lệch web cho dự án không phải web

**Ngày/nguồn:** 2026-09-13, phát hiện qua phân tích ngoài phiên.

**Khuôn lỗi:** `docs/framework/03-tech-selection-and-proactive-advice.md` đặt nhãn `C1 — Hồ sơ Web app (MẶC ĐỊNH)` và `PROJECT.md` ghi "mặc định theo hồ sơ Web app" — trong khi `README`, `CLAUDE.md` và `existing-project-adoption.md` đều khẳng định khung **không có stack mặc định**. Với agent thiếu cẩn thận, hai chữ "MẶC ĐỊNH" có thể dẫn đến thiên lệch chọn Next.js/React/TS + cổng Lighthouse/a11y/CWV cho dự án backend thuần, CLI, plugin Revit/AutoCAD hay bất kỳ loại nào không phải web. Trong các phiên brownfield lặp lại hoặc khi context bị nén, agent có thể không đọc đủ chú thích và áp hồ sơ C1 như mặc định thật sự.

*Cách rà*: trước khi đề xuất stack/cổng, kiểm tra `PROJECT.md` mục 0 (Loại dự án & Hồ sơ) đã được điền chưa. Nếu chưa điền, chạy PHẦN A0 của KHUNG-3 để phân loại — không giả định C1 vì "đây là mặc định". Nhãn "MẶC ĐỊNH" trong C1 chỉ có nghĩa file cấu hình **drop-in** của khung giả định hồ sơ này, không có nghĩa mọi dự án nên dùng C1.

*Cổng chốt chặn*: làm rõ nhãn C1 trong `03-tech-selection-and-proactive-advice.md` và chú thích nguồn gốc trong `PROJECT.md` để agent luôn thấy ngữ cảnh giải thích khi đọc hai chữ "MẶC ĐỊNH". (2026-09-13)

## 11. Thêm code chạy được mà không nối cổng CI → code chết, không ai biết nó tồn tại

*Ngày: 2026-09-13 · PR #89, #91 (mắc) → PR sửa: audit 2026-09-13.*

PR #89 và #91 thêm 4 engine Python (`spec-compiler.py`, `arch-health-radar.py`,
`subagent-dispatch.py`, `telemetry-log.py`, ~650 dòng) **kèm cả self-test** —
`test-next-gen-engines.sh` và `test-telemetry-and-dispatch.sh` — nhưng **không nối self-test nào
vào `ci.yml`**, và không thêm dòng nào vào `CODEMAP.md` hay `CLAUDE.md` §1.

Hai hậu quả, cái thứ hai nặng hơn: (a) code không có cổng bảo vệ, sửa gãy không ai bắt; (b) **code
chết trên thực tế** — một phiên AI mới chỉ đọc `CLAUDE.md`/`CODEMAP.md` nên không bao giờ biết 4
engine đó tồn tại, dù chúng chạy hoàn hảo. Viết self-test rồi không cắm vào CI tạo cảm giác an toàn
giả: `ls scripts/` thấy có test, nhưng không lần chạy nào là bắt buộc.

Lỗ hổng lọt vì cổng cũ chỉ kiểm hai chiều **lệnh ↔ `CLAUDE.md`** (mục 3 của
`check-docs-consistency.sh`), không kiểm **script ↔ `CODEMAP.md`**. Khi thêm cổng mới, nó bắt luôn
2 script cũ cũng chưa khai (`usage-estimate.sh`, `ci-workflow-policy.test.ts`) — tức khuôn này đã
âm thầm lặp lại nhiều lần trước đó.

**Cách rà:** với mọi PR thêm file vào `scripts/`, hỏi đúng 3 câu — (1) có job/step CI nào *bắt buộc*
chạy nó không? (2) có dòng trong `CODEMAP.md` không? (3) một phiên AI mới, chỉ đọc `CLAUDE.md`, có
biết nó tồn tại không? Không đủ 3 thì chưa xong, dù test có xanh.

**Cổng chốt chặn:** `scripts/check-docs-consistency.sh` **mục 6** (mọi `scripts/*.{sh,py,json,ts}`
phải được `CODEMAP.md` khai; miễn trừ phải ghi lý do ở `CODEMAP_EXEMPT`) + 2 step mới trong job CI
`framework-lint` chạy `test-next-gen-engines.sh` và `test-telemetry-and-dispatch.sh` + negative-test
của chính mục 6 trong `scripts/test-check-scripts.sh` (cả chiều đỏ lẫn chiều xanh).

## 12. `test-check-scripts.sh` chỉ kiểm được cổng ĐÃ COMMIT — sửa cổng mà chưa commit thì test mới xanh giả

*Ngày: 2026-09-13 · phát hiện khi thêm mục 6 ở trên.*

`setup_repo()` dựng sandbox bằng `git archive HEAD` — **chỉ lấy file đã commit**. Nên khi vừa thêm
mục kiểm mới vào `check-docs-consistency.sh` (chưa commit) rồi chạy `test-check-scripts.sh` ngay,
sandbox vẫn chạy **bản cũ** của cổng: ca negative (`rc` phải = 1) đỏ vì cổng cũ không có mục đó, còn
ca đối chứng (`rc` phải = 0) **xanh giả** — xanh vì cổng không kiểm gì, không phải vì nó kiểm đúng.

Nguy hiểm ở chỗ nếu chỉ viết ca đối chứng (không viết ca negative), bộ test sẽ báo xanh toàn bộ và
người viết tin rằng cổng mới đã hoạt động. Đây là lý do mỗi mục kiểm **phải có cả ca đỏ lẫn ca xanh**
(nguyên tắc F-002/G-001 áp cho chính mình).

**Cách rà:** sửa bất kỳ `check-*.sh` nào → **commit trước** rồi mới chạy `test-check-scripts.sh`;
nếu một ca negative mới báo `rc=0`, nghi ngờ "chưa commit" *trước* khi nghi ngờ logic cổng.

**Cổng chốt chặn:** không có cổng máy (bản chất là thứ tự thao tác) — chốt bằng chính mục này +
ghi chú trong đầu `scripts/test-check-scripts.sh`.

## 13. Commit của phiên AI không gắn được tài khoản GitHub → auto-merge kẹt, triệu chứng không nói ra nguyên nhân

*Ngày: 2026-09-13 · PR #93.*

Ruleset `.github/rulesets/main.json` bật `require_extra_approval_for_unattributed_changes`.
Phiên AI commit bằng một email **chưa liên kết** tài khoản GitHub → GitHub coi đó là thay đổi
"unattributed" và **chặn auto-merge**, dù `required_approving_review_count` = 0 và **toàn bộ
required check đều xanh**.

Triệu chứng đánh lạc hướng: PR ở trạng thái `blocked` nhưng mọi cổng đều ✅, không thông báo nào
nói lý do. Rất dễ đi tìm nhầm trong CI. Dấu hiệu nhận ra: gọi API commit thấy **thiếu** trường
`author.login` (commit đã gắn được sẽ có), và trên giao diện GitHub avatar tác giả không hiện.

Điểm dễ mắc thứ hai: sửa bằng `--reset-author` sẽ đặt **cả** author lẫn committer, làm mất danh
tính harness (và mất chữ ký Verified). Git tách hai trường này nên **không phải đánh đổi**:
author quyết định attribution, committer quyết định chữ ký.

**Cách rà:** trước khi mở PR từ phiên AI — `git log -1 --format='%an <%ae> | %cn <%ce>'`; email
author phải nằm trong `Settings → Emails` của tài khoản GitHub.

**Cổng chốt chặn:** không có cổng máy trong repo (thuộc cấu hình môi trường chạy, không phải nội
dung repo) — chốt bằng mục **4b** trong `docs/framework/new-project-runbook.md` + mục này.

## 14. `git checkout -b` thất bại vì nhánh đã tồn tại → commit rơi nhầm vào `main`

*Ngày: 2026-09-13 · mắc ngay trong phiên xử lý audit 2026-09-13.*

`git checkout -b <nhánh>` báo `fatal: a branch named '<nhánh>' already exists` và **giữ nguyên
nhánh đang đứng**. Nếu lệnh đó nằm trong một chuỗi `&&`/nhiều lệnh và output không được đọc kỹ,
các lệnh sau vẫn chạy — nhưng trên **nhánh cũ**. Hậu quả trong phiên này: commit đồng bộ
`PROGRESS.md` rơi vào `main` cục bộ, rồi `git push origin <nhánh>` lại đẩy **nhánh cũ** (nội dung
đã merge từ trước) lên, tạo PR #94 sai nội dung mà vẫn bật auto-merge.

May mắn PR đó squash ra **commit rỗng** nên `main` không thụt lùi — nhưng đó là may, không phải
do cổng nào chặn.

**Cách rà:** sau mỗi lần chuyển nhánh, xác nhận bằng `git branch --show-current` **trước khi**
commit; đừng tin lệnh checkout đã thành công chỉ vì các lệnh sau nó không lỗi. Dùng
`git switch -c <nhánh> || git switch <nhánh>` để ý định "tạo hoặc chuyển sang" là tường minh.
Trước khi push, đối chiếu `git log --oneline -1 <nhánh>` với commit vừa tạo.

**TÁI PHÁT 2026-09-14 (PR #111), qua một đường khác và tệ hơn:** lần này `git checkout -B <nhánh>`
không *thất bại* — nó **không hề chạy**. Lệnh đó nằm chung một dòng `&&` với một heredoc `python3`,
và cả dòng bị chính `block-dangerous-git.sh` chặn ở `PreToolUse` (bug chặn oan ở mục 18). Lệnh bị
chặn trước khi thực thi ⇒ không có output lỗi nào của git để mà đọc — dấu hiệu sớm ở mục này
("đừng tin checkout đã thành công chỉ vì lệnh sau không lỗi") **không áp dụng được**, vì không có
lệnh sau nào chạy cả. Ba commit sửa hook rơi vào `main` cục bộ; `git push -q -u origin <nhánh>` đẩy
**nhánh cũ** (đã merge) lên, tạo PR #111 sai nội dung.

Hai thứ làm nó sống lâu thêm:
- `git push -q` nuốt output, và tôi **không đối chiếu remote sau khi push** — tin vào dòng "Create a
  pull request for ..." mà dòng đó xuất hiện cả khi ref được tạo từ một nhánh khác.
- Hàng rào này chính là thứ đang được sửa trong PR đó: một hook chặn oan không chỉ phiền, nó **làm
  hỏng lệnh ghép theo cách không để lại dấu vết**.

**Cách rà (bổ sung, đây là phần đắt nhất):** sau **mỗi** `git push`, đối chiếu hai SHA trước khi nói
bất kỳ câu nào về kết quả — `git fetch origin && git rev-parse HEAD` so với
`git rev-parse origin/<nhánh>`. Bằng nhau mới là đã vào. Đây đúng `CLAUDE.md` §4 bước 1–3 (xác định
lệnh CHỨNG MINH được câu mình định nói, chạy đủ, đọc hết output) áp cho thao tác git. Và: **không
ghép `git checkout` vào cùng một dòng với lệnh khác** — chạy riêng, đọc `git branch --show-current`.

**Cổng chốt chặn:** từ 2026-09-23 có cổng máy — `.claude/hooks/pre-commit-gate.sh` chặn `git commit` khi
`git branch --show-current` là `main`/`master` (exit 2; bỏ qua tường minh `ALLOW_COMMIT_ON_MAIN=1`), ca ở
`scripts/test-hooks-gate.sh` mục 11. Chỉ có hiệu lực trong Claude Code (harness khác: `AGENTS.md` hàng rào thủ
công). Dấu hiệu sớm ngoài hook: `stop-hook-git-check` báo "unpushed commit(s) on branch 'main'".

## 15. "Đã copy đủ file" không có nghĩa là "dùng được ở dự án đích"

*Ngày: 2026-09-14 · gây ra ở PR #93, phát hiện khi đánh giá tổng thể.*

PR #93 bắt `telemetry-log.py` đọc `scripts/model-rates.json` và **thoát mã 1** nếu thiếu (cố ý:
thà không có báo cáo còn hơn báo cáo chi phí bằng số bịa). Nhưng `copy-framework.sh`/`.ps1`
**không phát** file dữ liệu đó, trong khi vẫn phát `telemetry-log.py`. Hậu quả:
`telemetry-log.sh --record` **chết trên MỌI dự án đích**, suốt nhiều PR, mà không cổng nào kêu.

Vì sao lọt: `test-copy-framework.sh` kiểm **đúng file có được copy không** — cấu trúc, không phải
hành vi. Self-test đi kèm (`test-telemetry-and-dispatch.sh`) bắt được ngay, nhưng **chưa ai chạy
nó BÊN TRONG dự án đích**. Khung tự kiểm chính mình rất kỹ, còn thứ nó **phát đi** thì không.

Cùng lượt smoke đầu tiên còn lộ thêm 2 ca nữa, đều cùng gốc "chạy ở repo khung thì xanh, ở dự án
đích thì không": `spec-compiler --compile-all` im lặng không in gì khi chưa có `docs/specs/`
(dự án mới thì đương nhiên chưa có), và ca AHR-3 assert "độ phủ phải TỤT" trong khi dự án đích
chưa có `ci.yml` nên độ phủ đã là 0 — không có gì để tụt.

**Cách rà:** mỗi khi thêm/sửa thứ được `copy-framework` phát đi, hỏi hai câu — (1) nó có phụ thuộc
file/thư mục nào mà dự án đích CHƯA có không? (2) đã chạy thật nó trong một dự án đích trống chưa?
Trạng thái "trống" (chưa có spec, chưa có CI, chưa có budget) là HỢP LỆ, phải xử lý tử tế chứ
không được coi là lỗi.

**Cổng chốt chặn:** `scripts/test-copy-framework.sh` mục "Smoke" — dựng dự án đích thật rồi CHẠY
các self-test được phát kèm ngay trong đó; đỏ là chặn. Chạy trong job CI `copy-framework-smoke`.

## 16. Push lại cùng nhánh cùng ngày chỉ "thành công" nhờ trùng giây — không thật sự an toàn

*Ngày: 2026-09-14 · phát hiện khi viết test cho `scripts/maintain-cron.sh` (agent bảo trì chạy
không giám sát trên VPS/cron).*

`maintain-cron.sh` thiết kế: nhánh `maint/auto-<ngày>` chạy lại cùng ngày thì `git reset --hard`
về nhánh nền rồi commit lại từ đầu (không cộng dồn). Bản đầu push bằng `git push -u origin
<nhánh>` (không force). Test tay chạy hai lượt LIÊN TIẾP RẤT NHANH (cùng giây đồng hồ) thấy xanh —
kết luận sai là "ổn". Viết thêm ca test 5 lượt (7a→7e, có xử lý tốn vài giây giữa các lượt) mới lộ
ra: commit thứ hai có nội dung/parent giống hệt commit thứ nhất nhưng **khác giây** → khác SHA →
không phải hậu duệ của commit cũ trên remote → git từ chối `non-fast-forward`. Lượt test nhanh
trước đó "xanh" thuần tuý vì hai commit **trùng giây tuyệt đối** nên trùng SHA, push thành no-op.

**Bài học tổng quát:** một test tay chạy đủ NHANH để né race condition không chứng minh gì — thời
gian trôi qua giữa hai bước là một BIẾN, không phải hằng số; test tự động phải cố tình để đủ thời
gian trôi qua (nhiều bước xen giữa, hoặc gọi mạng/subprocess thật) chứ không chỉ lặp lại lệnh liền
kề nhau.

**Sửa:** `git fetch origin <nhánh>` trước, rồi `git push --force-with-lease=<nhánh>` — CHỈ áp cho
nhánh do chính wrapper sở hữu (`maint/auto-*`), không bao giờ cho nhánh chính; `--force-with-lease`
(khác `--force` thường) bị remote từ chối nếu ai đó đã đẩy lên đúng nhánh đó sau lượt fetch.

**Cổng chốt chặn:** `scripts/test-maintain-cron.sh` mục 4 — hai lượt chạy cách nhau qua nhiều bước
xử lý thật (không phải `sleep` giả), xác nhận push thành công và không cộng dồn commit.

## 17. Biến gán trong hàm gọi qua `$(...)` không bao giờ thấy được ở ngoài — kể cả có khai `local`

*Ngày: 2026-09-14 · cùng lượt viết `maintain-cron.sh` (bước tự mở PR qua GitHub REST API).*

Một hàm `http_call()` ghi đường dẫn file tạm vào biến `http_body_file` (khai `local` ở hàm CHA gọi
nó), rồi hàm cha đọc lại biến đó ngay sau khi gọi. Chạy `bash -n`/shellcheck đều sạch. Lỗi chỉ lộ
lúc CHẠY THẬT: `set -u` báo `http_body_file: unbound variable`. Nguyên nhân: mọi lệnh gọi hàm đều
qua `code="$(http_call ...)"` — cú pháp `$(...)` luôn chạy trong **subshell**; một biến được gán
BÊN TRONG subshell đó biến mất khi subshell kết thúc, bất kể biến được khai `local` ở scope nào.

**Bài học tổng quát:** không bao giờ dùng một biến "kênh phụ" (side-channel) để hàm A truyền dữ
liệu ra ngoài trong khi lệnh gọi hàm A lại đi qua command substitution để lấy giá trị IN RA
stdout — hai kênh giao tiếp (biến + stdout) không cùng sống sót qua ranh giới subshell. Dữ liệu
"ra ngoài" thứ hai phải đi qua tham số truyền vào (caller tạo sẵn, truyền path/tên vào) hoặc gộp
chung vào output có cấu trúc, không bao giờ qua biến toàn cục/`local` chia sẻ ngầm.

**Sửa:** đổi `http_call()` nhận đường dẫn file tạm làm THAM SỐ tường minh (`http_call METHOD URL
BODYFILE [DATA]`), caller tự `mktemp` trước khi gọi — không còn kênh phụ nào.

**Cổng chốt chặn:** `scripts/test-maintain-cron.sh` mục 7 — chạy thật hàm `open_pr()` qua `curl`
giả (không mock ở mức hàm bash, chạy nguyên vẹn dưới `set -u`) mới bắt được; test tĩnh không đủ.

## 18. Hook an toàn quét CẢ chuỗi lệnh → chặn oan vì DỮ LIỆU trong lệnh (heredoc/nháy)

**Ngày/PR:** 2026-09-14, khi đồng bộ `PROGRESS.md` sau PR #109. Mắc **hai lần trong cùng một lượt**.

`.claude/hooks/block-dangerous-git.sh` nhận nguyên văn chuỗi lệnh rồi `grep` bốn khuôn nguy hiểm
trên **toàn bộ chuỗi đó**. Nhưng một lệnh shell chứa cả *lệnh* lẫn *dữ liệu*, và dữ liệu nhiều từ
thường nằm trong thân heredoc:

1. `git commit -F - <<EOF … EOF && git push -u origin claude/<nhánh> --force-with-lease` bị quy tắc
   1 ("force-push vào nhánh chính") chặn, vì **commit message** có chữ `main` đứng riêng ("quay về
   main"). Nhánh đích là nhánh riêng.
2. Ngay sau đó, một lệnh `python3 - <<PY … PY` bị quy tắc 2 chặn, vì thân script có chuỗi
   `git reset --hard` làm **dữ liệu fixture** cho test.

Phần trong dấu nháy đã được bỏ từ audit 2026-09-12 — nhưng heredoc thì chưa, và heredoc mới là chỗ
văn bản dài sống.

**Vì sao nghiêm trọng hơn là "phiền":** hàng rào báo oan dạy người ta gõ `ALLOW_DANGEROUS_GIT=1`
thành phản xạ, và lúc đó nó không còn chặn được ca thật. Một cổng bị vô hiệu hoá vì mất lòng tin
nguy hiểm hơn một cổng không tồn tại, vì tài liệu vẫn khai là có.

**Khuôn tổng quát:** *bộ dò tự khớp văn bản của chính thứ nó đang soi*. Cùng họ với bẫy bộ đếm miễn
trừ tự đếm chính mình (`docs/framework/quality-supplements-group2.md` §"Sổ trần cho LỐI THOÁT khỏi
cổng coverage"). Trước khi viết bất kỳ bộ dò dạng grep-trên-văn-bản nào, hỏi: *văn bản mình đang
soi có thể chứa chính mẫu mình đang tìm, dưới dạng dữ liệu, không?*

**Cách rà:** cho bộ dò chạy trên một đầu vào **chứa mẫu dưới dạng dữ liệu** (chuỗi, comment, thân
heredoc, fixture test) và xác nhận nó KHÔNG báo động — đồng thời giữ ca chiều ngược (mẫu thật vẫn
bị bắt). Thiếu một trong hai chiều thì test vô nghĩa.

**Sửa:** bỏ thân heredoc khỏi chuỗi trước khi so khớp (`strip_heredoc_bodies`), cùng lý do đã bỏ
phần trong dấu nháy. Giới hạn còn lại được ghi thẳng trong comment của hook: dữ liệu không nháy,
không heredoc (`… && echo main`) vẫn bị quét — sửa hẳn cần tách lệnh theo `&&`/`;`/`|` rồi chỉ soi
segment bắt đầu bằng `git`, chưa làm vì chưa có sự cố thật.

**Bẫy TRONG chính bản sửa — bản vá đầu tiên NỚI LỎNG hàng rào:** bản đầu nhận heredoc bằng
`<<-?[[:space:]]*DELIM`, nên `echo "a << b"` khớp thành heredoc với delimiter `b`, và **mọi dòng sau
đó bị nuốt** — `git reset --hard` ở dòng kế KHÔNG còn bị chặn. Đo được bằng một lần chạy hook thật,
không phải suy đoán; phát hiện vì tự kiểm lại một ca xấu đã nêu ra miệng mà chưa test (`CLAUDE.md`
§4 bước 1: xác định lệnh nào CHỨNG MINH được câu mình định nói). Sửa: cấm khoảng trắng giữa `<<` và
delimiter.

**Bài học riêng của ca này:** khi bản vá là "bỏ bớt đầu vào khỏi phép quét", hai chiều hỏng KHÔNG
đối xứng — bỏ thiếu thì chặn oan (thấy ngay, có người kêu), bỏ thừa thì **để lọt** (không ai biết).
Mọi bản vá dạng này phải có ít nhất một ca chặn-bắt-buộc đi kèm, không chỉ ca không-chặn-oan.

**Cổng chốt chặn:** `scripts/test-hooks-gate.sh` — mục 8 hai ca không-chặn-oan (`force-push nhánh
RIÊNG, chữ 'main' chỉ nằm trong thân heredoc`; `nhánh riêng có chuỗi 'main' trong TÊN nhánh`) và
mục 7 một ca chặn-bắt-buộc mới (`lệnh nguy hiểm SAU một chuỗi chứa '<<' không phải heredoc`), cùng
5 ca chặn thật có sẵn làm chiều ngược. 15/15.

---

## 19. Rút helper dùng chung làm đỏ test COPY một danh sách file cố định

**Ngày/PR:** 2026-09-14, nhánh `claude/confident-brown-6vb0f7` (commit `4f9e740` gây, vá ở commit kế).

**Khuôn lỗi:** một refactor "gộp boilerplate" tạo file mới (`scripts/_python-exec.sh`) và biến nó
thành **phụ thuộc lúc chạy** của script cũ (`subagent-dispatch.sh`). Mọi test dựng sandbox bằng cách
`cp` một **danh sách file viết tay** vào thư mục tạm đều đỏ ngay — vì danh sách đó không biết về file
mới. Ở đây là `test-maintain-cron.sh:24` và `test-maintain-run.sh:31`.

**Vì sao lọt:** refactor được nghiệm thu bằng đúng hai test *trực tiếp* của bốn wrapper
(`test-next-gen-engines.sh`, `test-telemetry-and-dispatch.sh`) — cả hai chạy trong cây repo thật nên
file mới luôn có mặt. Hai test đỏ nằm ở **script khác, tên không liên quan**, không ai nghĩ tới.
Sai lầm quy trình: "cổng liên quan xanh" bị đọc thành "không đổi hành vi", trong khi `CLAUDE.md` §6
đòi chạy **TOÀN BỘ** test trước khi merge. Xanh giả kiểu này còn nguy hiểm hơn đỏ.

**Cách rà:** sau khi thêm bất kỳ file nào bị `source`/`exec` bởi script khác, grep danh sách copy:
`grep -rn 'cp .*scripts/{' scripts/` — mọi danh sách có chứa script tiêu thụ thì phải có thêm file mới.
Tổng quát hơn: `grep -rn "$(basename FILE_MOI)" scripts/` phải khớp **cả nơi dùng lẫn nơi copy**.

**Cổng chốt chặn:** `scripts/test-maintain-cron.sh` + `scripts/test-maintain-run.sh` (job CI
`framework-lint`) — đã xanh trở lại sau khi thêm `_python-exec.sh` vào hai danh sách `cp`. Đo thật:
exit 0/0 ở `HEAD~1`, exit 9/22 sau refactor, exit 0/0 sau bản vá.

**Tái phát 2026-10-09** (tách `telemetry-log.py` → `_telemetry_report.py`): `scripts/test-hooks-session.sh` chép tay
`telemetry-log.sh/.py` + `model-rates.json` + `_python-exec.sh` vào fixture → hook telemetry-record chết
`ModuleNotFoundError` ở cổng commit, dù `test-telemetry-and-dispatch.sh` và `test-copy-framework.sh` đều xanh
(manifest đã có helper; chỉ danh sách `cp` viết tay là không biết). Bắt bởi hook pre-commit-gate; vá: thêm
helper vào dòng `cp` đó. Cách rà ở trên đúng — chỉ là chưa chạy nó trước khi commit.

## 20. Test xanh nhưng nhánh cần đo KHÔNG bị chạm — `chmod 000` vô hiệu dưới uid 0

**Ngày/PR:** 2026-09-14, nhánh `claude/cool-gauss-4dk9ln` (bắt được TRƯỚC khi commit, khi tự kiểm).

**Khuôn lỗi:** viết characterization test cho nhánh `except OSError: continue` của
`arch-health-radar.py::_scripts_inventory` bằng cách `os.chmod(file, 0o000)` rồi assert kết quả.
Test **xanh** — nhưng xanh vì đi đường BÌNH THƯỜNG: phiên chạy dưới `uid 0` (container/CI hay gặp),
và root đọc được cả file `0o000`, nên `open()` không hề ném `OSError`. Nhánh định khoá vẫn trần trụi.

**Vì sao nguy hiểm:** đây là xanh giả *ngược chiều* với mục 19. Mục 19 là "cổng liên quan xanh bị đọc
thành không đổi hành vi"; mục này là **chính test được viết ra để khoá một nhánh lại không chạm tới
nhánh đó** — nó sẽ vẫn xanh sau khi ai đó xoá mất `try/except`, đúng thứ nó có mặt để ngăn. Cùng họ
với mục 18 (bộ dò tự khớp văn bản của chính nó): cái sai nằm ở *tiền đề của phép đo*, không ở kết quả.

**Cách rà:** mọi test dựng điều kiện lỗi bằng **quyền truy cập** (`chmod`, chủ sở hữu file, thư mục
chỉ-đọc) đều đáng ngờ — `id -u` bằng 0 thì phần lớn vô hiệu. Kiểm tiền đề trước bằng một dòng:
`python3 -c "open(F).read()"` trên chính file đã `chmod` — đọc được nghĩa là test đang giả.
Bắt buộc hơn: với MỌI test khoá một nhánh, chạy **negative test** — cố ý phá nhánh đó và xác nhận
test chuyển đỏ. Test không đỏ khi phá thì không phải test.

**Cổng chốt chặn:** `scripts/test-engine-characterization.sh` — nay kích lỗi bằng **thư mục trùng
tên** (`IsADirectoryError`, một `OSError`), độc lập hoàn toàn với quyền của người chạy. Đo thật ở
4 negative test trước khi commit: phá `_ci_gate_tests` → 5 failures · phá luật wrapper `.sh`→`.py`
→ 4 failures · phá nối `--context-file` → 1 failure · phá nhánh render `hermes` → 1 error ·
đối chứng khôi phục → OK.

## 21. So bản CŨ với bản MỚI bằng cách chạy file cũ ở thư mục khác → nó quét nhầm cây

**Ngày/PR:** 2026-09-14, nhánh `claude/cool-gauss-4dk9ln` (mắc HAI lần liên tiếp trong cùng một phiên).

**Khuôn lỗi:** để chứng minh refactor không đổi hành vi, chép bản cũ ra thư mục tạm
(`git show HEAD:scripts/x.py > /tmp/.../x.py`) rồi chạy hai bản và `diff` đầu ra. Cả bốn engine của
khung đều tính `ROOT_DIR = dirname(dirname(abspath(__file__)))`, nên bản cũ ở thư mục tạm quét
**thư mục tạm**, không phải repo. Kết quả `diff` khác nhau toé loe và *trông như* refactor đã phá
hành vi — trong khi thật ra phép đo sai. Lần hai y hệt với `AGENTS_DIR` của `subagent-dispatch.py`.

**Vì sao lọt:** phép so sánh có vẻ hiển nhiên đúng nên không ai kiểm tiền đề của nó. Nguy hiểm cả hai
chiều: lần này nó báo động giả, nhưng cùng cơ chế đó có thể cho hai bản cùng quét một cây RỖNG rồi
trả về "IDENTICAL" — một chứng minh vô nghĩa được đọc thành bằng chứng mạnh.

**Cách rà:** đừng so bằng cách chạy file ở vị trí khác. Nạp **cả hai** bản làm module
(`importlib.util.spec_from_file_location`), **ghi đè `ROOT_DIR`/`AGENTS_DIR` của cả hai vào CÙNG một
cây cố định** (dựng bằng `git archive HEAD | tar -x -C <thư mục>`), rồi gọi thẳng hàm và so giá trị
trả về. Luôn in kèm một con số nhận dạng của cây đó (số file, điểm sức khoẻ) để thấy ngay nếu nó rỗng.

**Cổng chốt chặn:** không có cổng máy — đây là kỷ luật của người chứng minh, thuộc `CLAUDE.md` §4
bước (4) "output có khớp đúng câu định nói không". Ghi lại ở đây vì khuôn này sẽ quay lại ở mọi lần
refactor engine sau.

## 22. Commit merge đặt tiêu đề `merge:` → đỏ cổng Conventional Commits

**Ngày/PR:** 2026-09-14, PR #120 (đỏ ở job `metadata`, sửa bằng `--amend` ngay trên nhánh của mình).

**Khuôn lỗi:** giải xong xung đột, commit merge với tiêu đề mô tả đúng việc đang làm — `merge: đưa
main vào nhánh, giải xung đột X`. `merge` **không** nằm trong danh sách type hợp lệ của
`.github/workflows/pr-policy.yml` (`feat|fix|refactor|docs|test|chore|style|perf|build|ci|revert`),
nên cổng `metadata` đỏ. Dùng `chore:` — nội dung mô tả giữ nguyên, chỉ đổi type.

**Vì sao lọt:** commit merge *cảm giác* như một thao tác git chứ không phải một commit "nội dung", nên
quy ước tiêu đề không được nghĩ tới. Nhưng cổng soi **mọi** tiêu đề commit chứ không chỉ tiêu đề PR —
đúng như comment trong `pr-policy.yml` giải thích: squash lấy tiêu đề COMMIT khi PR chỉ có một commit
(sự cố thật ở PR #99). Mọi chuỗi CÓ THỂ thành tiêu đề trên `main` đều bị soi, commit merge không ngoại lệ.

**Cách rà:** trước khi push một nhánh có commit merge, chạy đúng regex của cổng lên toàn bộ tiêu đề:
`git log --format=%s origin/main..HEAD` rồi đối chiếu với regex ở `pr-policy.yml:21`. Sửa bằng
`git commit --amend` trên chính commit merge — `--amend` GIỮ NGUYÊN cả hai cha (kiểm: `git log -1
--format=%p` phải in hai SHA), nên không phải viết lại lịch sử; chỉ hợp lệ trên nhánh do mình tạo.

**Cổng chốt chặn:** job `metadata` (`.github/workflows/pr-policy.yml`) — đã đỏ thật ở PR #120 commit
`eb2ea98` với thông điệp nêu đích danh tiêu đề vi phạm, xanh lại sau khi đổi `merge:` → `chore:`.

**Bẫy kèm theo — sửa tiêu đề trên PowerShell làm HỎNG tiếng Việt trong thân commit.** Bản sửa ở PR
#120 được thực hiện trên Windows bằng
`$msg = (git log -1 --format=%B | Out-String) -replace '^merge:', 'chore:'`. Lệnh chạy, cổng xanh,
nhưng tiêu đề trên remote thành `chore: ─æ╞░a main …`: `git log` xuất UTF-8, PowerShell giải mã theo
**code page của console** (CP437/850) rồi mã hoá lại thành UTF-8 — hỏng kép. Nhìn bằng mắt trên
terminal Windows rất khó thấy vì console cũng hiển thị sai theo chiều ngược lại.

*Cách rà:* so **byte**, đừng so hình. `git log -1 --format=%s <sha> | od -c` — chữ `đ` đúng là
`304 221` (U+0111); thấy `342 224 200` (ký tự kẻ khung U+2500) là đã hỏng. Đối chiếu với một commit
sạch kề bên để có mốc.

*Cách tránh:* đặt `$OutputEncoding = [Console]::OutputEncoding = [Text.UTF8Encoding]::new()` TRƯỚC khi
đọc output của git, hoặc đừng đọc-ghi lại thân commit — gõ thẳng `git commit --amend -m "..."`, hoặc
sửa trong `git commit --amend` bằng editor. Ghi file thì dùng
`[System.IO.File]::WriteAllText($p, $msg, (New-Object System.Text.UTF8Encoding($false)))` để không
chèn BOM — nhưng **ghi đúng không cứu được chuỗi đã đọc sai**: hỏng xảy ra ở bước ĐỌC, không phải ghi.

*Không có cổng máy:* cổng `metadata` chỉ soi tiền tố Conventional Commits nên tiêu đề hỏng vẫn qua.
Đây là kỷ luật của người sửa. Hệ quả ở PR #120 được CHẤP NHẬN có ý thức thay vì force-push thêm một
lượt nữa: chi phí sửa (một vòng force-push nữa) lớn hơn thiệt hại (một dòng hỏng trong thân commit
squash, tiêu đề trên `main` lấy từ tiêu đề PR nên vẫn sạch).

## 23. `awk` ở máy dev (mawk) nhận cú pháp mà `awk` ở CI (gawk) từ chối

*Ngày/PR:* 2026-09-15, PR #126 (cổng CC shell) — đỏ ngay lượt CI đầu tiên.

**Khuôn lỗi.** Script cổng viết một chương trình `awk` dùng biến tên `func`. Máy dev có
`/usr/bin/awk → mawk` (Debian mặc định) nhận bình thường; runner `ubuntu-latest` có `awk → gawk`,
mà `func` là **từ khoá của gawk** (viết tắt của `function`) → `syntax error`, cổng chết TRƯỚC khi đo
được gì. Mọi lượt chạy tay ở máy đều xanh, CI đỏ 100%.

Đây là một thể hiện khác của khuôn "cổng chết trước khi chạy tới phần cần đo" (`CLAUDE.md` §4, bẫy
cuối): exit code khác 0 rất dễ bị đọc nhầm thành "đã đo, không có vi phạm".

*Cách rà:* `ls -l /usr/bin/awk` — thấy trỏ vào `mawk` là máy đang chạy dialect KHÁC CI. Chạy lại cổng
với `PATH` chèn một thư mục có `awk → gawk` (`ln -sf /usr/bin/gawk $d/awk`) để tái hiện đúng môi
trường runner trước khi push. Từ khoá chỉ có ở gawk hay quên: `func`, `include`, `switch`, `case`,
`delete` (dạng mảng), `BEGINFILE`, `ENDFILE`.

*Cổng chốt chặn:* ca 6 của `scripts/test-check-shell-complexity.sh` — khi máy CÓ `gawk`, chạy lại
chính cổng đó dưới gawk và bắt buộc phải xanh. Máy không có gawk thì ca này in ghi chú "bỏ qua" chứ
không giả vờ xanh; CI luôn có gawk nên nơi đó không bao giờ bỏ qua.

## 24. Script Python in tiếng Việt/emoji → chết trên console Windows (cp1252)

**Ngày/PR:** 2026-09-15, phát hiện khi người dùng hỏi "template này hoàn hảo chưa" và chạy thử toàn
bộ self-test trên máy Windows thật. **Tái phát 2026-09-23 (PR #166), biến thể ĐỌC:** test mới gọi
`python3 -c "json.load(open(...))"` không có `encoding='utf-8'` — trên runner Windows, `open()` mặc định
cp1252 chết vì `_comment` tiếng Việt trong `model-rates.json`, và `2>/dev/null` nuốt lỗi nên ca test đọc
thành chuỗi rỗng → đỏ ở `framework-lint-windows`, xanh ở Linux. Luật rút ra: mọi `open()` trong Python
inline của script test cũng phải có `encoding='utf-8'`, không chỉ file `.py`.

**Khuôn lỗi:** 4 engine Python (`spec-compiler`, `arch-health-radar`, `telemetry-log`,
`subagent-dispatch`) in báo cáo tiếng Việt + emoji ra stdout. Trên Windows, `sys.stdout` mặc định
dùng codec ANSI của hệ (cp1252 với locale Việt/Âu) → `UnicodeEncodeError` ngay dòng `print()` đầu
tiên có dấu. Chỉ một ký tự `ạ` (`ạ`) là đủ chết; không cần emoji. Trên Linux CI (locale UTF-8)
**không bao giờ lộ** — đúng kiểu bẫy chỉ nổ ở máy người dùng.

Tổng quát: **stdout của Python không phải lúc nào cũng UTF-8** — mọi script CLI viết bằng tiếng
Việt đều mang sẵn lỗi này, chỉ chưa chạy trên máy Windows nào.

**Cách rà:** thêm/sửa một script Python có chữ tiếng Việt trong `print()` → chạy nó bằng Git Bash
trên Windows thật (không chỉ WSL/Linux), hoặc ép thử: `PYTHONIOENCODING=cp1252 python scripts/x.py`.

**TÁI PHÁT (2026-09-15, cùng ngày, PR riêng):** khối `reconfigure` chỉ cứu được file `.py` —
**Python nội tuyến trong heredoc của script `.sh` thì không**, vì nó không đi qua file nào có khối đó.
Ba chỗ: `check-python-complexity.sh`, `test-engine-characterization.sh`, `usage-estimate.sh`. Lỗi
**bị che** suốt vì cổng CC Python thoát sớm hơn với "Thiếu radon" — chỉ lộ ra sau khi cài radon
đúng interpreter mà script chọn. Bài học: **một lỗi thoát sớm có thể đang giấu một lỗi khác ngay sau
nó** — sửa xong điều kiện môi trường phải chạy LẠI, đừng cho là xong. Cách sửa cho heredoc:
đặt `PYTHONIOENCODING=utf-8` ngay trước lệnh gọi interpreter.

**Bẫy kèm — nhiều bản Python trên cùng máy:** `python` và `python3` có thể là HAI bản cài khác nhau
(ví dụ `C:\Python314` và `...\pythoncore-3.14-64`). `pip install radon` cho bản này không làm bản kia
thấy — cổng báo "Thiếu radon" dù vừa cài xong. *Cách rà:* `command -v python python3` rồi
`python3 -m radon --version` đúng cái mà script sẽ chọn (script ưu tiên `python3`).

**Cổng chốt chặn:** khối `_stream.reconfigure(encoding="utf-8")` ở đầu cả 4 file `.py`,
`PYTHONIOENCODING=utf-8` ở 3 chỗ heredoc nói trên, +
`scripts/test-next-gen-engines.sh` và `scripts/test-telemetry-and-dispatch.sh` chạy trong `ci.yml` — xem bẫy 25.

## 25. Test có trong repo nhưng KHÔNG job nào gọi → đỏ nằm im qua nhiều PR "sạch"

**Ngày/PR:** 2026-09-15, cùng lượt phát hiện bẫy 24.

**Khuôn lỗi:** `scripts/test-next-gen-engines.sh` và `scripts/test-telemetry-and-dispatch.sh` được
thêm cùng các engine mới (PR #89, #91) nhưng **không job nào trong `ci.yml` gọi chúng**. Repo nhìn
như có test bao phủ; thực tế 3 ca đỏ (bẫy 24) đi qua nhiều PR merge sạch mà không ai thấy. Đây đúng
khuôn hỏng-im-lặng của F-002 (hook tồn tại nhưng chưa ai chứng minh nó chặn), chỉ khác tầng.

Tổng quát: **một test không có cổng nào chạy thì về thực chất là không tồn tại** — nó còn tệ hơn
không có test, vì tạo cảm giác an toàn giả.

**Cách rà:** thêm bất kỳ `scripts/test-*.sh` nào → `grep "$(basename "$t")" .github/workflows/ci.yml`.

**Cổng chốt chặn:** CP-6 trong `scripts/check-ci-policy.sh` (mọi `scripts/test-*.sh` phải được
`ci.yml` gọi) + negative test cho CP-6 trong `scripts/test-check-scripts.sh`. (PR #113 đã nối tay 2 suite vào `ci.yml` sau khi audit 2026-09-13 phát hiện — CP-6 là cổng máy chống tái phát, thay vì trông vào việc ai đó nhớ.)

## 26. Hàng rào hook phụ thuộc `jq` nhưng `jq` chưa từng được khai là yêu cầu môi trường

**Ngày/PR:** 2026-09-15, cùng lượt phát hiện bẫy 24.

**Khuôn lỗi:** `pre-commit-gate.sh` và `block-dangerous-git.sh` đọc lệnh từ payload JSON bằng `jq`,
và **cố ý fail-open** khi thiếu `jq` (fail-closed sẽ chặn oan vì không đọc nổi lệnh). Nhưng không
tài liệu nào khai `jq` là yêu cầu — nên trên máy không có `jq`, toàn bộ hàng rào (chặn commit đỏ,
chặn `push --force` lên `main`, chặn `reset --hard`) **im lặng biến mất** dù mọi file vẫn đúng chỗ.
Tệ hơn: `test-hooks-gate.sh` không phát hiện thiếu `jq` mà kết luận thẳng "cổng chặn commit KHÔNG
hoạt động như tài liệu mô tả" — báo cáo sai bản chất, đúng thứ `CLAUDE.md` §7 cấm.

Tổng quát: **fail-open là lựa chọn đúng nhưng chỉ an toàn khi điều kiện kích hoạt được khai báo và
kiểm được** — nếu không, nó là "không có hàng rào" đội lốt "có hàng rào".

**Cách rà:** `command -v jq` trên máy đang dùng; hoặc chạy `bash scripts/test-hooks-gate.sh` và đọc
dòng đầu.

**Cổng chốt chặn:** mục "Yêu cầu môi trường" trong `README.md` (nêu rõ thiếu `jq` = mất hàng rào) +
`test-hooks-gate.sh` giờ báo **BỎ QUA kèm cảnh báo** thay vì xanh giả/đỏ sai, và xây PATH không-jq
theo cách chạy được cả trên Windows (không dựa vào `ln -s`).

## 27. File vendor KHÔNG có đuôi rơi vào `* text=auto` → CRLF trên Windows làm chết cổng CC shell

**Ngày/PR:** 2026-09-15, phát hiện khi chạy lại toàn bộ cổng trên máy Windows sau khi merge `main`.

**Khuôn lỗi:** `.gitattributes` ghim `eol=lf` theo **đuôi file** (`*.sh`, `*.md`, `*.yml`, `*.json`,
`*.ps1`). `vendor/shellmetrics/shellmetrics` **không có đuôi** nên rơi vào luật chung `* text=auto`
→ Git đổi sang CRLF khi checkout trên Windows → SHA256 lệch `SHA256SUMS` → `check-shell-complexity.sh`
từ chối chạy ("không đo bằng một công cụ không rõ nội dung"). Cổng tự bảo vệ đúng như thiết kế,
nhưng hệ quả là **cổng CC shell chết hoàn toàn trên mọi máy Windows** — và vì CI chạy Linux nên
không bao giờ lộ. `scripts/test-check-shell-complexity.sh` cũng đỏ theo, 7 ca.

Tổng quát: **luật line-ending viết theo đuôi file luôn bỏ sót file không đuôi** — mà file không đuôi
gần như luôn là binary/vendor, đúng loại tuyệt đối không được Git đụng vào.

**Cách rà:** `git check-attr -a <file>` thấy `text: auto` trên thứ đáng lẽ bất khả xâm phạm;
hoặc `file <path>` báo "with CRLF line terminators" trên file vendor.

**LƯU Ý khi cập nhật:** sửa `.gitattributes` KHÔNG tự chữa bản sao đã CRLF-hoá trong cây làm
việc sẵn có — luật mới chỉ áp lúc checkout. Sau khi kéo bản sửa về phải chạy `git checkout -- vendor`
một lần (clone mới thì không cần). Cùng lý do, mọi `git reset --hard` về một commit TRƯỚC bản sửa
sẽ làm hỏng lại file vendor — đã gặp thật ngay trong chính lượt sửa này.

**Cổng chốt chặn:** `vendor/**  -text` trong `.gitattributes` (kèm `*.py`/`*.ts` `eol=lf` cùng lý do
với `*.sh`). Ca 4-5 của `scripts/test-check-shell-complexity.sh` (sửa/khôi phục bản vendor) đã sẵn
bắt được lệch checksum — thiếu mỗi việc file không bị Git làm lệch ngay từ lúc checkout.

## 28. `os.path.relpath` ném ValueError khi hai đường dẫn khác Ổ ĐĨA (chỉ trên Windows)

**Ngày/PR:** 2026-09-15, do chính job `framework-lint-windows` bắt được trong lượt chạy thứ hai của
nó (PR thêm cổng Windows).

**Khuôn lỗi:** `os.path.relpath(a, b)` trên Windows **ném `ValueError`** nếu `a` và `b` nằm trên hai
ổ đĩa khác nhau: `path is on mount 'C:', start on mount 'D:'`. Runner `windows-latest` checkout repo
ở ổ **D:** còn `mktemp -d` trả về thư mục ở ổ **C:** — nên `spec-compiler.py --spec <đường dẫn ở ổ
C:>` chết ngay ở dòng tính `spec_file`, KHÔNG sinh ra test nào. Trên Linux không bao giờ xảy ra vì
không có khái niệm ổ đĩa.

Tổng quát: **`relpath` là hàm CÓ THỂ NÉM, không chỉ trả về chuỗi** — và nó chỉ ném trên Windows, nên
CI Linux không bao giờ bắt được. Dùng nó cho một NHÃN HIỂN THỊ mà không bắt lỗi là để một chuỗi
trang trí làm chết cả chương trình.

**Hai lớp che khiến nó tồn tại lâu:** (1) lỗi chỉ nổ khi đường dẫn đầu vào ở ổ đĩa khác — hiếm trên
máy dev, luôn xảy ra trên runner; (2) trong `test-next-gen-engines.sh` cả lệnh compile lẫn lệnh
unittest đều bị nuốt bằng `>/dev/null 2>&1`, nên triệu chứng chỉ là "AC-3 đỏ oan" — đoán sai hai
lượt liên tiếp trước khi thêm chẩn đoán. **Bài học: một ca test đỏ mà không in được NGUYÊN NHÂN là
một ca test chưa xong.**

**Cách rà:** `grep -n relpath scripts/*.py` — mỗi chỗ dùng cho nhãn hiển thị phải có `try/except
ValueError`.

**Cổng chốt chặn:** `_display_path()` trong `spec-compiler.py` (fallback về đường dẫn tuyệt đối) +
`try/except` tương tự trong `arch-health-radar.py` + **ca SC-1** trong `test-next-gen-engines.sh`,
ép `ValueError` bằng monkeypatch nên có nghĩa trên CẢ Linux lẫn Windows (chỉ truyền đường dẫn
`"D:/..."` thì trên Linux ca đó xanh vô nghĩa) + job `framework-lint-windows` chạy thật trên ổ D:.
Đã chứng minh SC-1 ĐỎ khi gỡ bản sửa và XANH khi có bản sửa.

## 29. `\b` trong chuỗi Python thường là BACKSPACE — ký tự điều khiển lọt vào tài liệu

**Ngày/PR:** 2026-09-15, gặp thật khi rút gọn một mục trong `PROGRESS.md` bằng script Python.

**Khuôn lỗi:** viết `"...grep \b$jid\b..."` trong một chuỗi Python **thường** (không phải raw
string): `\b` KHÔNG phải hai ký tự literal mà là **BACKSPACE (0x08)**. Script chạy trót lọt, file
ghi ra trót lọt, `PROGRESS.md` nhận một ký tự điều khiển vô hình giữa hai backtick. Trình soạn thảo
không hiển thị, trình xem Markdown không hiển thị, `git diff` cũng không nêu — phát hiện được chỉ vì
tình cờ đọc lại output qua `cat -A`. Cùng họ này còn `\a` (bell), `\f`, `\v`, và `\1` (đã mắc riêng
một lần trong cùng phiên: một backreference `\1` của `sed` biến thành ký tự 0x01, làm biểu thức
`sed` thay bằng chuỗi RỖNG mà không báo lỗi).

Tổng quát: **ký tự điều khiển trong tài liệu là hỏng IM LẶNG** — không công cụ hiển thị nào cho
thấy nó, nên nó sống vô thời hạn và được sao chép sang mọi bản dẫn xuất. Cùng họ với mục 27 (CRLF):
thứ mà Git và trình soạn thảo đều coi là "văn bản" vẫn có thể mang byte con người không thấy.

**Cách rà:** sinh tài liệu bằng Python thì dùng **raw string** (`r"..."`) cho mọi chuỗi có dấu
`\`, hoặc tránh viết ký hiệu regex vào văn xuôi (diễn đạt bằng chữ: "theo ranh giới từ"). Kiểm
nhanh một file: `LC_ALL=C grep -n "$(printf '[\001-\010\013\014\016-\037\177]')" file.md | cat -A`.

**Cổng chốt chặn:** **mục 8** của `scripts/check-docs-consistency.sh` — quét mọi `*.md` do
`git ls-files` liệt kê, giữ lại TAB/LF/CR vì đó là ký tự văn bản hợp lệ, KHÔNG soi NUL (file có NUL
đã là nhị phân chứ không phải lỗi tài liệu). Mẫu được dựng lúc chạy bằng `printf` chứ không viết ký
tự điều khiển thật vào source — nếu không, chính script sẽ tự khớp mình (khuôn "bộ dò tự khớp văn
bản của thứ nó đang soi", xem `block-dangerous-git.sh`). Có **negative test** (chèn 0x08 → phải đỏ)
và **đối chứng** (TAB/CR → phải xanh) trong `scripts/test-check-scripts.sh`.

## 30. Copy "tài liệu khung" bằng `cp -R` cả thư mục → chạy lại để nâng bản ĐÈ MẤT nhật ký của dự án đích

**Ngày/PR:** 2026-09-23, phát hiện ở audit toàn diện repo khung (`docs/reports/2026-09-23-de-xuat-nang-cap-khung-toan-dien.md` C1), tái hiện thật.

**Khuôn lỗi:** `copy_into "docs/ops"` copy NGUYÊN thư mục vì "docs/ops chỉ là tài liệu tham khảo".
Nhưng thư mục đó dần chứa cả **file trạng thái** của chính repo khung (`MAINTENANCE-LOG.md`,
`MAINTENANCE-PLAN.md`, `COMPLETION-PLAN.md`, `COMPREHENSIVE-AUDIT-STATUS.md`) — được thêm SAU khi
viết lệnh copy, không ai quay lại soát danh sách. Hệ quả hai tầng: (1) dự án đích nhận nhật ký bảo
trì của repo khung làm nhiễu; (2) dự án đích chạy lại `copy-framework.sh` để nâng bản → `cp -R`
ghi đè, **xoá sạch nhật ký `/maintain`/`/completion` thật của họ**. Test chỉ kiểm "chạy lần 2 không
lỗi" — mất dữ liệu không phải lỗi thoát nên xanh. Cùng họ mục 19 (danh sách file viết tay lệch
thực tế) và mục 10 (test không đo đúng thứ cần bảo vệ).

**Cách rà:** với mọi lệnh copy cả thư mục sang dự án đích, hỏi: *thư mục này có file nào là
TRẠNG THÁI (log/plan/status) thay vì TÀI LIỆU không?* `ls docs/ops | grep -E -- '-(PLAN|LOG|STATUS)\.md$'`.
Mọi file sinh ra bởi một lệnh/agent (chứ không do người viết tay một lần) đều là trạng thái.

**Cổng chốt chặn:** `scripts/test-copy-framework.sh` — (a) `check_structure` khẳng định 4 file trạng
thái KHÔNG có ở đích trống; (b) ca "chạy lại lần 2" ghi sentinel vào `docs/ops/MAINTENANCE-LOG.md`
của đích trước, chạy lại, sentinel phải còn nguyên (cả bash lẫn pwsh). `copy-framework.sh`/`.ps1`
lọc theo hậu tố `-PLAN/-LOG/-STATUS.md` thay vì liệt kê tên (file trạng thái mới cùng khuôn tên
tự được loại).

## 31. Fixture sửa dòng tùy chọn không có thật → negative test xanh giả

*Ngày/PR:* 2026-09-24, PR #177. Job `framework-lint` đỏ ở ca PF-2.

**Khuôn lỗi:** `test-check-scripts.sh` dựng sandbox bằng `git archive HEAD` rồi dùng `sed`
thay dòng `Nhánh đang làm`. Dòng này là tùy chọn và đã không còn ở `PROGRESS.md` hiện tại,
nên `sed` thoát 0 nhưng không thay byte nào. Ca "nhánh đã xoá" không tạo tiền đề; cổng
kiểm đúng khi trả 0, nhưng test kết luận cổng đã hỏng. Fixture còn chạy bản commit cũ
thay vì bản đang sửa, khiến pre-commit test không kiểm đúng nội dung sắp commit.

*Cách rà:* khi negative test dùng `sed`, kiểm tiền đề/đối chứng thật trong sandbox, đọc
output cổng nếu assertion sai. Không suy ra fixture đã đổi chỉ từ exit code của `sed`.

*Cổng chốt chặn:* `setup_repo` dựng tường minh cả hai dòng fixture, lấy bản working tree
đã track và fail khi dựng sandbox lỗi. PF-2 có ca nhánh mất và nhánh còn thật trên bare
remote; suite in output cổng khi thất bại. Chạy `scripts/test-check-scripts.sh` trước
commit để kiểm đúng bản đang ghi.

## 32. Telemetry nuốt JSON lỗi rồi ghi đè lịch sử

*Ngày:* 2026-09-24, audit hoàn thiện. `telemetry-log.py` cũ bắt mọi exception
khi đọc `telemetry.json` và trả danh sách rỗng. Một file JSON bị cắt hoặc lỗi đọc
được coi như log mới; lượt ghi sau mở `w` và xoá toàn bộ lịch sử. Hai Stop hook
ghi cùng lúc còn đọc chung một trạng thái rồi lượt sau ghi đè lượt trước. Test cũ
chỉ đo lối đi bình thường, nên không phát hiện mất dữ liệu.

*Cách rà:* làm hỏng JSON trong một thư mục thử, ghi entry và so bytes trước/sau;
chạy nhiều process ghi cùng file và đếm đủ task. `os.replace` riêng lẻ chống file
ghi dở nhưng không chống mất cập nhật của đọc–sửa–ghi.

*Cổng chốt chặn:* `tests/test_telemetry_integrity.py` kiểm JSON lỗi, sai root type,
lỗi replace, sáu process ghi đồng thời và chờ khoá. Hai suite telemetry và coverage
chạy bộ test; copy framework đưa test kèm engine.

## 33. Hook telemetry truyền giờ vào trường giây

*Ngày:* 2026-09-24, audit hoàn thiện. `telemetry-record.sh` chia thời lượng
transcript cho 3600 rồi truyền vào `--duration`, nhưng engine lưu trường
`duration_sec` và báo cáo in `s`. Transcript 12 phút bị ghi thành `0.2s`.
Test cũ khẳng định `0.2`, tức bảo vệ chính lỗi sai đơn vị.

*Cách rà:* lấy hai timestamp cách nhau 12 phút, đo entry và summary. Giá trị
`duration_sec` phải là 720, phần tiếp theo 18 phút phải là 1080.

*Cổng chốt chặn:* `scripts/test-hooks-session.sh` khẳng định 720/1080 giây.
Không nhân toàn bộ log lịch sử: CLI cũng ghi cùng schema nên không xác định an
toàn entry cũ nào thực sự dùng giờ.

## 34. Dependabot tách các bước CodeQL thành PR riêng làm CI đỏ vì lệch phiên bản

*Ngày/PR:* 2026-10-05, PR #185/#186. Cả hai job `Analyze (python)` và
`Analyze (actions)` lỗi `Loaded a configuration file for version '4.38.1',
but running version '4.38.2'` khi chỉ một trong `init`/`analyze` được nâng.

**Khuôn lỗi:** Dependabot tạo PR riêng cho từng `github/codeql-action/*` trong
cùng workflow. Mỗi PR riêng làm CodeQL `init` và `analyze` khác version; required
`gate` của khung vẫn xanh nhưng CodeQL đỏ, nên không đủ cổng trước merge.

**Cách rà:** khi nâng một sub-action CodeQL, đối chiếu toàn bộ `uses:` của
`github/codeql-action/*` trong cùng workflow và các check CodeQL trên PR.

**Cổng chốt chặn:** `.github/dependabot.yml` gom `github/codeql-action/*` vào
một nhóm update; PR #185 cập nhật `init` và `analyze` cùng SHA v4.38.2, sau đó
phải có `Analyze (python)` và `Analyze (actions)` xanh trên đúng head. Việc nhóm
PR chỉ áp dụng cho các lượt Dependabot tương lai, không tự sửa PR #186 đã mở.

## 35. Ruleset live có thể yếu hơn file dù protection-guard vẫn xanh

*Ngày/PR:* 2026-10-05, PR #188. `.github/rulesets/main.json` khai
`strict_required_status_checks_policy: true`, nhưng API ruleset đang áp
trả `false`. `protection-guard` trước đó chỉ kiểm loại rule và tên required
check nên vẫn xanh; PR không cần cập nhật với `main` mới để merge.

**Khuôn lỗi:** kiểm sự hiện diện của rule nhưng bỏ qua tham số quyết định
chính sách. File khai và GitHub Settings có thể trôi lệch mà CI không báo.

**Cổng chốt chặn:** `scripts/test-check-scripts.sh` chạy chính thân step
`protection-guard` với phản hồi API giả: `strict=true` xanh,
`strict=false` đỏ. Ruleset live đã được cập nhật và đọc lại qua API
ngày 2026-10-05; CI của PR #188 đã xác nhận trên head cuối.

## 36. Git pre-commit truyền biến repo nội bộ vào gate làm hỏng test repo tạm

*Ngày/PR:* 2026-10-05, PR #189. Khi chạy `git commit` với
`core.hooksPath=scripts/githooks`, hook gọi `dev-task.sh gate` khi còn
`GIT_DIR`/`GIT_INDEX_FILE` do Git truyền vào. Các test tạo repo tạm dùng nhầm
repo gốc: `test-check-scripts.sh` đỏ oan và `core.bare` trong config chung
từng bị đổi thành `true`. Đã khôi phục `false` trước khi tiếp tục.

**Khuôn lỗi:** chạy test có lệnh `git init`/`git -C` từ hook nhưng giữ biến
Git nội bộ của repo gọi hook. Mọi worktree chia sẻ config nên tác động lan
qua nhiều nhánh.

**Cổng chốt chặn:** `scripts/test-hooks-gate.sh` truyền giả
`GIT_DIR`/`GIT_WORK_TREE`/`GIT_INDEX_FILE` vào hook, yêu cầu gate không
nhận các biến đó. Test đã đỏ trước sửa và xanh sau khi hook chỉ dọn biến Git
trong subshell chạy gate; kiểm staged diff vẫn dùng môi trường hook ban đầu.

## 37. Báo cáo bảo trì phát tán giá trị secret đã phát hiện

*Ngày:* 2026-10-05, audit năng lực framework. `maintenance-sweep.sh` lấy các dòng
khớp mẫu secret từ file được Git theo dõi rồi ghi nguyên nội dung vào báo cáo.
Workflow bảo trì đưa báo cáo vào job summary và issue GitHub, khiến credential bị
lặp lại ở thêm nơi lưu trữ/nhóm người đọc sau khi đã lọt vào repo.

*Cách rà:* tạo secret giả trong repo fixture, chạy maintenance sweep, xác nhận báo
cáo không chứa giá trị giả nhưng còn đường dẫn, số dòng và nhãn loại phát hiện.

*Cổng chốt chặn:* `scripts/test-maintenance-sweep.sh` khẳng định giá trị giả không
xuất hiện và vị trí được giữ với nhãn `[credential-like match — redacted]`;
`scripts/maintenance-sweep.sh` trích riêng số dòng trước khi ghi báo cáo.

## 38. Dependency review chỉ tìm manifest ở gốc → monorepo bị skip im lặng

*Ngày:* 2026-10-05, audit hoàn thiện W-06.

*Khuôn lỗi:* `dependency-review.yml` duyệt danh sách tên manifest bằng `[ -f "$file" ]`
tại gốc repo. Chính bộ khung có `scripts/requirements-ci.txt` nhưng không có manifest ở gốc,
nên bước phát hiện ghi `exists=false` và bỏ qua action. Dự án monorepo chỉ có manifest trong
`packages/` hoặc `services/` cũng bị bỏ qua, dù PR thay đổi dependency.

*Cách rà:* chạy thân step phát hiện với repo thử chỉ có một manifest được Git theo dõi trong
thư mục con; kiểm `GITHUB_OUTPUT` ghi `exists=true`. Đối chứng repo không có manifest phải
ghi `false`.

*Cổng chốt chặn:* `scripts/test-check-scripts.sh` chạy đúng thân step với fixture
scripts/requirements-ci.txt, packages/api/package.json, services/backend/go.mod và
repo trống; lệnh `git ls-files` lỗi phải đỏ thay vì skip. Bước phát hiện quét
file Git theo dõi ở mọi độ sâu. Cổng này xác nhận action được
kích hoạt, còn độ phủ phân tích thật phụ thuộc Dependency graph của GitHub.

**Tái phát trên PR #192:** action chạy thật nhưng đỏ vì Dependency graph/alerts của
repo chưa bật (`Dependency review is not supported on this repository`). API
vulnerability-alerts trả 404 trước, 204 sau khi bật; rerun job xanh. Cổng local
chỉ chứng minh bước phát hiện manifest, nên khi áp khung phải đọc cài đặt live.

## 39. Coverage đạt sàn nhưng probe thành công đã lỗi

*Ngày:* 2026-10-05, audit hoàn thiện F-K05.

*Khuôn lỗi:* helper `run()` của `test-py-coverage.sh` thêm `|| true` cho mọi CLI.
Một probe radar cố ý truyền cờ sai vẫn làm suite thoát 0 và báo độ phủ 96%, vì
probe khác chạm đủ dòng. Sàn coverage đo phần code được chạy, không xác nhận
những luồng thành công đã chạy đúng.

*Cách rà:* thay một lời gọi thành công bằng cờ CLI không hợp lệ nhưng giữ các
lời gọi khác; suite phải đỏ ngay tại probe đó, kể cả khi coverage vẫn ≥ 95%.

*Cổng chốt chặn:* `scripts/test-py-coverage-exit.sh` thực thi bản sao của suite
với probe thành công bị làm lỗi và kiểm exit 1. Test còn gây lỗi giữa lúc có
fixture tạm và sau khi bảng giá bị ghi hỏng để xác nhận trap dọn/khôi phục.
Helper `run_expected_failure()` chỉ dùng cho các lời gọi được xác minh trả exit
khác 0; spec không tồn tại của spec-compiler trả 0 theo contract hiện tại.

## 40. Maintenance sweep chỉ quét dependency của stack đầu tiên ở root

*Ngày:* 2026-10-05, F-K03 audit. `detect_deps_cmd` dừng ở hệ sinh thái root đầu tiên
có mặt; monorepo đa stack không chạy kiểm tra những stack còn lại và không phát hiện
manifest dependency trong `apps/*` hoặc `packages/*`.

*Cách rà:* fixture có Go ở root, Node trong `apps/site` và Rust trong
`packages/rust-core`; xác nhận lệnh outdated/audit chạy với working directory từng
thành phần, đồng thời tên thành phần xuất hiện trong báo cáo.

*Cổng chốt chặn:* `scripts/test-maintenance-sweep.sh` kiểm tra log lời gọi công cụ
trong cả ba thư mục và nội dung báo cáo. Tự dò giới hạn ở root cùng một cấp trực tiếp
`apps/*`/`packages/*`; manifest sâu hơn phải khai báo `deps_outdated`/`deps_audit`
trong `.claude/project-commands.sh` cho đến khi có yêu cầu quét sâu hơn.

## 41. Lint ghép bằng dấu chấm phẩy báo xanh dù ShellCheck lỗi

*Ngày:* 2026-10-05, audit hoàn thiện F-K10. `lint` của repo khung nối ShellCheck,
kiểm tài liệu và kiểm CI bằng `;`, nên mã thoát của bước cuối che lỗi bước đầu.
Gọi ShellCheck một lần cho cả danh sách file còn che cảnh báo SC2154 có thể thấy
khi kiểm riêng `scripts/test-hooks-gate.sh`.

*Cách rà:* chạy ShellCheck riêng từng file và cố ý cài một file `.sh` có biến chưa
khai báo vào fixture. Khi ShellCheck đỏ, lint phải đỏ và hai kiểm tiếp theo không
được chạy; khi file sạch, cả ba bước phải chạy và lint xanh.

*Cổng chốt chặn:* `.claude/project-commands.sh` dùng `xargs -n1` và `&&` giữa
ba bước; `scripts/test-dev-task.sh` kiểm cả đường lỗi và đường sạch của chuỗi
lint thật. Cảnh báo SC2154 ở test hook được sửa trong cùng đợt trước khi gate xanh.
CI Windows không cài ShellCheck: lần đầu test đỏ với exit 127 ở đường sạch,
vì fixture gọi binary thật. Test dùng ShellCheck giả chỉ trong fixture để kiểm
đường gọi từng file và mã thoát; cổng Linux vẫn chạy ShellCheck thật trên source.

## 42. Hook không có bit thực thi chết im lặng ngoài Windows

*Ngày:* 2026-10-06, đối chiếu X-Agents (họ H6 ở TRAPS của nó). `settings.json` gọi thẳng đường dẫn hook;
`ui-intelligence.sh` được commit mode `100644` (từ Windows) nên `sh` trả 126 "Permission denied" — Claude Code coi
là lỗi không chặn, hook không bao giờ chạy. Test mục 9 chạy hook qua `bash <file>` nên xanh giả.

*Cách rà:* với mọi lệnh trong `settings*.json`, hỏi "chạy đúng như harness gọi (không qua `bash`) có được không?"
và xét mode trong git index (`git ls-files -s`), không xét mode trên đĩa Windows.

*Cổng chốt chặn:* `scripts/test-hooks-gate.sh` mục 14 (có negative test hạ về 100644).

## 43. Hook chạy trước lệnh nên không thấy thứ lệnh sắp stage

*Ngày:* 2026-10-06 (X-Agents #368). `pre-commit-gate.sh` chỉ đọc `git diff --cached`; `git add X && git commit` hay
`commit -a` stage X *sau* khi hook đã chạy → bí mật và file >1 MB lọt (đo: 3 ca exit 0). Phụ: trong hook có
`set -o pipefail`, một nhóm `{ …; [ cond ] && cmd; } | grep` trả 1 làm cả pipeline "lỗi" và bỏ lọt ca thật.

*Cách rà:* mọi hook PreToolUse đọc trạng thái repo — hỏi "lệnh này có tự đổi trạng thái đó trước khi commit không?".
Không dùng `[ ] && cmd` làm lệnh cuối của nhóm đưa vào pipeline; bọc hàm và `return 0`.

*Cổng chốt chặn:* `scripts/test-hooks-gate.sh` mục 11 (5 ca: 3 chặn, 2 không chặn oan).

## 44. Bảng Markdown thừa ô mất chữ im lặng

*Ngày:* 2026-10-06 (X-Agents `test_bang_markdown_khong_hang_nao_thua_o`). GitHub bỏ ô thừa; `|` trong backtick vẫn tách ô.
Đo: 2 hàng thật (`Analyze (python|actions)`, `|| true`) mất chữ mà mọi cổng cũ xanh.

*Cách rà:* `|` trong ô bảng luôn viết `\|`. *Cổng chốt chặn:* `check-docs-consistency.sh` mục 10.

## 45. Hook cổng đọc CLAUDE_PROJECT_DIR thay vì cây đang commit (worktree)

*Ngày:* 2026-10-07 (X-Agents `pt.10`, TRAPS §3 của nó; đo lại ở repo này). `pre-commit-gate.sh` lấy nhánh, index và cổng
từ `CLAUDE_PROJECT_DIR` = checkout chính. Phiên chạy trong `git worktree` thì `git commit` chạy ở worktree: hook chặn oan
commit hợp lệ ("đang đứng trên main") và buông bí mật staged lẫn cổng đỏ của worktree (đọc index rỗng của checkout chính).
Đo: 3 ca đỏ (exit 2/0/0, kỳ vọng 0/2/2).

*Cách rà:* mọi hook/script đọc trạng thái git — hỏi "đường dẫn này là cây ĐANG làm việc hay checkout chính?". Gốc cây lấy từ
`git rev-parse --show-toplevel` ở cwd của hook; `CLAUDE_PROJECT_DIR` chỉ là chỗ lùi về. Test hook phải chạy với cwd = thư mục
dự án giả, không phải cwd của test.

*Cổng chốt chặn:* `scripts/test-hooks-gate.sh` mục 15 (3 ca worktree) + `run_hook` đặt cwd = dự án.

## 46. Chạy từng suite rồi chạy full gate làm kiểm thử Linux lặp toàn bộ

*Ngày:* 2026-10-07, issue #198. CI gọi các suite bằng step riêng, sau đó gọi
full local gate có vòng lặp lại mọi shell suite. Cả 17 suite bị gọi hai lần trên
Linux; các lượt Windows là đối chứng nền tảng riêng, không phải phần cần xóa.

*Cách sửa:* giữ step kiểm tra và doctor, bỏ lần gọi full gate lặp trong CI.
Giữ ShellCheck từng file (bẫy 41) và Python syntax trên cả scripts/tests để không
mất kiểm tra vốn có trong full gate. Local gate vẫn chạy đủ mọi suite.

*Cổng:* `tests/test_ci_suite_parity.py` đếm lệnh chạy, không đếm tên step/comment;
thiếu hoặc trùng một suite phải đỏ. Không dùng kết quả này để suy ra mức giảm thời
lượng hoặc token: đó cần số đo thực tế riêng.

## 47. Test nâng bản lấy base từ HEAD nhưng nguồn là working tree

*Ngày:* 2026-10-07, LD-03 (#198). `scripts/test-copy-framework.sh` dựng ca "đích viết lại toàn bộ
`standard-delivery.md`" rồi chạy `--upgrade`. `copy-framework.sh` lấy base ba chiều từ commit HEAD của
repo khung còn bản mới từ working tree; khi chính file đó đang sửa dở (mọi PR chạm `standard-delivery.md`,
gồm LD-02/LD-03), base ≠ nguồn nên xung đột là THẬT và suite đỏ ở full gate cục bộ/hook pre-commit —
trong khi CI trên cây sạch vẫn xanh. Tái hiện: cùng commit, `git stash` riêng file đó → rc 0; bỏ stash → rc 1.

*Cách sửa:* ca viết lại chọn một file khung CHƯA sửa so với HEAD trong danh sách ứng viên; tất cả đều đang
sửa → FAIL nói rõ, không âm thầm bỏ ca. Không đổi hành vi của `copy-framework.sh`.

*Khuôn:* test dùng repo khung làm nguồn phải độc lập với trạng thái working tree của chính repo đó; kiểm bằng
cách chạy suite khi một file nó dùng đang sửa dở.

## 48. Commit do công cụ sinh không theo Conventional Commits làm đỏ `metadata`

*Ngày:* 2026-10-07, LD-02 (#203), tái phát 2 lần trong cùng PR. Job `metadata` (`pr-policy.yml`) kiểm
**mọi** tiêu đề commit của PR, không chỉ tiêu đề PR. Lần 1: nút autofix CodeQL trên GitHub tạo commit
"Potential fix for pull request finding …". Lần 2: `git merge origin/main` để giải xung đột tạo
"Merge origin/main …". Cả hai đều đúng nội dung nhưng đỏ CI; squash merge không cứu được vì cổng chạy trước.

*Cách sửa:* đổi tiêu đề commit đó (`git commit --amend` / `-m` khi merge), giữ nguyên nội dung và parent,
rồi `git push --force-with-lease=<nhánh>:<sha-cũ>` lên nhánh PR (không bao giờ lên `main`).

*Khuôn:* commit không do mình gõ tiêu đề (autofix, suggestion, merge, revert của nền tảng) vẫn phải theo
`<type>(<scope>): …`. Phòng trước: merge base bằng `git merge -m "chore(merge): đồng bộ main (…)"`;
autofix/suggestion thì sửa tiêu đề ngay ở hộp commit. Cổng chốt chặn: job `metadata`.

## 49. Gate báo PASS dù không lưu được evidence đã yêu cầu

*Ngày:* 2026-10-07, rà sau LD-08. Các kiểm tra xanh nhưng thư mục evidence bị xóa
trong lúc chạy: `evidence_finish` chỉ ghi log lỗi rồi trả 0, gate vẫn báo PASS.
Đích trở thành thư mục còn làm `mv` chuyển file JSON tạm vào thư mục đó và trả 0.
Test đỏ trước sửa: hai ca gate exit 0; ca thư mục còn để lại file tạm.

*Cách sửa:* truyền lỗi tạo/ghi evidence thành BLOCKED (exit 2); từ chối đích là
thư mục trước `mv -f`, dọn file tạm khi thất bại. Giữ lệnh tương thích BSD/GNU;
không thêm cờ `mv -T` chỉ có trên GNU. Không thay kết quả kiểm tra bằng lời tự khai.

*Cổng chốt chặn:* `scripts/test-dev-task.sh` mục 7b: thư mục cha mất, đích thành
thư mục và kiểm tra thất bại kèm lỗi ghi evidence đều phải exit 2, không báo PASS
và không để lại file tạm; đường ghi PASS/FAIL/BLOCKED thành công vẫn có regression.

## 50. Filename và executable path được ghép vào shell source

*Ngày:* 2026-10-08, audit hoàn thiện F-C01/F-C03 (W-01).

*Khuôn lỗi:* `format-file` ghép filename vào chuỗi rồi chạy `bash -c`; bọc dấu
nháy kép vẫn thực thi `$()`/backtick, còn filename chứa dấu nháy làm hỏng lệnh.
`py_tool` trả executable path venv không quote nên root có khoảng trắng trả 127;
ký tự shell trong root có thể thực thi lệnh ngoài tool. Config command là shell
tin cậy nhưng các đường dẫn filesystem vẫn là dữ liệu.

*Cách rà:* dùng formatter giả ghi NUL-separated argv và sentinel cục bộ; truyền
filename có khoảng trắng, dấu nháy, dollar, backtick, dấu chấm phẩy và newline.
Chạy executable venv giả trong fixture root có khoảng trắng/ký tự shell. Test phải kiểm
đúng argv và không có sentinel, không chỉ dựa trên exit 0 của formatter best-effort.

*Cổng chốt chặn:* `tests/test_runtime_safety.py` kiểm cả năm formatter fallback,
template với {}, "{}", '{}', leading dash, missing tool/error và venv root;
`scripts/test-dev-task.sh` kiểm resolver cả `.venv/bin` và `.venv/Scripts`.
Sửa bằng Bash positional parameter cho filename và printf %q cho executable path;
không đưa filename vào shell source. Template dùng placeholder như đối số độc lập,
không nhúng trong shell lồng. Config vẫn cần được review như shell tin cậy.

## 51. Miễn trừ metadata bằng return bỏ qua trần WIP toàn repo

*Ngày:* 2026-10-08, audit hoàn thiện F-C02 (W-02).

*Khuôn lỗi:* workflow trả về sớm với PR draft/bot trước phép đếm WIP; phép đếm
còn lọc bỏ draft khác. Luật ghi mọi PR mở nhưng cổng cho qua PR thứ tư khi ba PR
khác là draft. Miễn trừ thông tin mà một tác nhân không cung cấp được vô tình
miễn cả giới hạn tài nguyên áp cho mọi tác nhân.

*Cách rà:* thực thi JavaScript thật trong workflow với GitHub/core stub offline,
không viết lại luật trong test. Test total ba/bốn PR, draft khác, PR draft/bot
hiện tại, title sai và metadata thường. Trả cả PR hiện tại trong danh sách để
chứng minh không đếm trùng; kiểm miễn trừ body/feature vẫn áp dưới trần.

*Cổng chốt chặn:* `tests/test_runtime_safety.py` chạy Node trên script workflow
với 18 subcase trong gate và CI Linux/Windows. Đếm mọi PR khác đang mở trước
return miễn trừ, chỉ loại PR hiện tại; giới hạn vẫn là ba. Không tự đóng PR.

## 52. Gate của dự án đích kế thừa `CLAUDE_PROJECT_DIR` của repo khung → gate khung gọi lại chính nó

*Ngày:* 2026-10-08, audit tối ưu quy trình (P-A0).

*Khuôn lỗi:* `dev-task.sh` ưu tiên `CLAUDE_PROJECT_DIR` để tính ROOT (cần cho worktree —
mục 48/hook). `test-adoption-smoke.sh` chạy gate/doctor của dự án đích giả bằng
`cd "$dir" && bash scripts/dev-task.sh gate` mà không đặt lại biến đó. Khi biến đã trỏ về
repo khung (hook `pre-commit-gate` đặt nó cho mọi `git commit` từ Claude Code), ROOT của gate
"dự án đích" quay về khung → gate khung chạy lại trong gate khung → đệ quy vô hạn, treo
không thông báo. CI không thấy vì CI không đặt biến; các phiên trước commit bằng Git hook
chuẩn (không đặt biến) nên không gặp.

*Cách rà:* mọi chỗ gọi `dev-task.sh` cho MỘT CÂY KHÁC (fixture, dự án đích, clone) phải đặt
`CLAUDE_PROJECT_DIR` trỏ đúng cây đó (grep `dev-task.sh (gate|doctor)` trong `scripts/test-*.sh`);
`ps` thấy chuỗi `test-adoption-smoke.sh → dev-task.sh gate → test-adoption-smoke.sh` lặp là
đúng khuôn này.

*Cổng chốt chặn:* `dev-task.sh gate` BLOCKED khi `DEV_TASK_GATE_ROOT` (export ở lượt ngoài) trùng
ROOT — fail-closed có lý do thay vì treo; `scripts/test-dev-task.sh` mục 7d (fixture tự gọi gate
cùng ROOT, giới hạn 3 tầng, đỏ-trước trên bản cũ). `test-adoption-smoke.sh` đặt
`CLAUDE_PROJECT_DIR="$dir"` cho mọi gate/doctor của đích.

## 53. Bản sao hook lệch nhau — bộ lọc dữ liệu sửa ở một hook không sang hook kia

*Ngày:* 2026-10-08, O-2 P-A1 (PR: điền khi mở). Lần sửa 2026-09-14 thêm `strip_heredoc_bodies` vào
`block-dangerous-git.sh` nhưng `pre-commit-gate.sh` giữ BẢN SAO riêng của bộ lọc (chỉ bỏ nháy). Hệ quả:
`python3 - <<PY … git commit … PY` (lệnh không phải commit) chạy cổng và bị chặn oan khi cổng đỏ; commit có
message heredoc nhắc `git add` bị coi là lệnh tự stage → soi cả file chưa theo dõi và chặn oan. Đo: 2 ca đỏ
(exit 2, kỳ vọng 0). Gặp thật ngay trong phiên sửa: lệnh vá test có thân heredoc chứa `git commit` bị chặn.

*Cách rà:* sửa một bộ lọc/regex/parse ở một hook → `grep` cùng khuôn (`.tool_input.command`, `strip_`, `<<`)
trong mọi `.claude/hooks/*.sh` và `scripts/githooks/*`. Logic dùng chung đặt một chỗ (`.claude/hooks/_lib.sh`),
không chép; hook nào còn bản sao riêng là ứng viên lệch.

*Cổng chốt chặn:* `scripts/test-hooks-gate.sh` mục 16 (thân heredoc chứa `git commit`/`git add` không kích hoạt
cổng/tự-stage; `git commit` THẬT sau heredoc vẫn qua cổng) + mục 7–8 cho `block-dangerous-git` — cả hai hook
`source` cùng `_lib.sh` nên một lần sửa áp cho cả hai.

## 54. Tài liệu phát sang đích mang bản kê của repo khung — test drop-in đỏ ngày đầu

*Ngày:* 2026-10-09, F-R01 chu kỳ hoàn thiện (PR: điền khi mở). `docs/ops/repository-settings.md` được
`copy-framework.sh`/`.ps1` phát nguyên văn sang đích, nhưng khối fenced đầu của nó là bản kê job của RIÊNG repo
khung (7 job `ci.yml` + `pr-policy.yml: metadata`) trong khi đích nhận `ci-target.yml` (chỉ có `gate`). Vitest
drop-in `scripts/ci-workflow-policy.test.ts` đọc đúng khối đó và đối chiếu hai chiều → đỏ ngay trên dự án đích
copy sạch ("Job đã khai nhưng không còn tồn tại trong ci.yml", 6 job). Chưa từng chạy vitest trên fixture đích
nên không ai thấy.

*Cách rà:* bất kỳ file tài liệu nào được một cổng MÁY đọc (shell lẫn drop-in) mà phát nguyên văn sang đích →
hỏi "cổng ở đích đọc được gì từ file này?" và chạy cổng ở đích ít nhất một lần trên fixture copy sạch.

*Cổng chốt chặn:* `scripts/test-copy-framework.sh` `check_structure` (hai chiều khối required checks đầu ↔ job
thật của workflow phát kèm) + `scripts/test-check-scripts.sh` ca marker (xoá marker → `check-ci-policy.sh` đỏ).

## 55. Dò khoá JSON bằng grep trên cả file — khoá cùng tên ở mục khác thành dương tính giả

*Ngày:* 2026-09-01 ghi nhận (F-309, "chấp nhận rủi ro"); sửa 2026-10-09 (đợt finishing, PR closeout). `node_has_script`
trong `scripts/_stack-detect.sh` khi không có jq dùng `grep -Eq "\"$1\"[[:space:]]*:" package.json` → một dự án có
`dependencies.test` nhưng không có `scripts.test` vẫn được dev-task in `npm run test` (tái hiện bằng PATH tối thiểu không jq).
Rủi ro "thấp" nằm im 5 tuần vì môi trường dev/CI luôn có jq nên nhánh fallback không bao giờ chạy trong test.

*Cách rà:* mọi `grep` trên file có cấu trúc (JSON/YAML/TOML) để trả lời câu hỏi về MỘT khoá ở MỘT vị trí → hỏi "khoá cùng
tên ở chỗ khác thì sao?"; nhánh fallback của công cụ nào cũng cần một ca test dựng đúng môi trường thiếu công cụ đó
(wrapper bash tới binary thật trong PATH tối thiểu — không symlink để Git Bash Windows chạy được).

*Cổng chốt chặn:* `scripts/test-dev-task.sh` mục 1 — ca "không jq" (khoá `test` ở dependencies → rỗng; `build` thật → `npm run build`).

## 56. Tham số đặt ngay sau `node -e '…'` (không có `--`) là CỜ của interpreter, và `obj[k]` thấy cả khoá kế thừa

*Ngày:* 2026-10-09 (F-309b; lộ ra khi nghiệm thu agent `reviewer` + `security-reviewer` trên chính diff #229 — sửa F-309 mang
theo hai lỗi mới). `node -e '…' "$1"` với `$1 = --version` in phiên bản và trả 0 (dương tính giả); `--require=x.js` CHẠY MÃ.
Caller hiện chỉ truyền 5 tên cố định nên chưa khai thác được, nhưng hàm nhận tham số thì bất biến "tham số là dữ liệu" phải
nằm ở hàm, không ở caller. Cùng dòng: `p.scripts[k]` với `k = toString` → "có script" vì tra cả `Object.prototype`.
Thêm F1 của reviewer: không jq lẫn node (Bun/Deno thuần) → `node` exit 127 bị `2>/dev/null` nuốt → false âm thầm (khuôn T4).

*Cách rà:* mọi chỗ interpreter nhận `-e/-c` rồi tham số động → phải có `--` (node, python `-c` không cần nhưng `-` đầu vẫn
nguy hiểm với argparse) hoặc đưa qua biến môi trường; mọi tra khoá động trên object JS → `Object.hasOwn`; mọi nhánh fallback
`else` gọi công cụ thứ hai → thêm `elif command -v` và nhánh cuối báo ra stderr. Nghiệm thu agent bằng diff THẬT vừa merge
là cách rẻ để bắt lỗi do chính mình vừa gây ra.

*Cổng chốt chặn:* `scripts/test-dev-task.sh` mục 1 — ba ca F-309b (`--version` → rc≠0 & stdout rỗng; `toString` → không có;
không jq+node → stderr "jq lẫn node") + ca BOM (reviewer F2) + ca khoá `config` khi có jq.

## 57. Drop-in test của khung nằm trong `_framework-dropins/` vẫn bị test runner của ĐÍCH gom → `npm test` đỏ ngay sau copy

*Ngày:* 2026-10-09 (lộ ra khi chạy `/completion` trên một dự án đích Node thật — xem `docs/reports/2026-10-09-target-completion.md`).
`copy-framework.sh` để `ci-workflow-policy.test.ts` ở `_framework-dropins/scripts/` cho người dùng tự merge; nhưng vitest mặc định gom
`**/*.test.ts` toàn repo, và `.github/workflows/` chưa có → ca "tìm thấy ít nhất một workflow" đỏ. Cổng `dev-task.sh gate` của đích
FAIL ngay bước đầu tiên dù code đích không lỗi — ấn tượng đầu tiên về khung là "nó làm hỏng test của tôi". Cùng lượt: `ci-target.yml`
không có bước cài dependency nên cổng trên runner sạch cũng đỏ (S-05).

*Cách rà:* mọi file khung PHÁT SANG đích mà một công cụ của đích có thể tự tìm thấy theo mẫu tên (test runner, linter, formatter,
pre-commit) → hỏi "công cụ đích sẽ làm gì với file này KHI NÓ CÒN NẰM Ở CHỖ TẠM?"; đọc output `npm test`/gate của đích NGAY SAU copy,
không chỉ sau khi đã merge drop-in bằng tay. Mọi workflow mẫu → đọc từng bước và hỏi "runner sạch có cái gì để chạy bước này?".

*Cổng chốt chặn:* drop-in tự `describe.skipIf(STAGED)` khi đường dẫn còn chứa `_framework-dropins`; `scripts/test-copy-framework.sh`
grep hàng rào đó trong bản phát; `ci-target.yml` có bước `npm ci`/`pip install` có điều kiện theo lockfile/requirements.

## 58. Cổng đo độ dài chỉ soi TIÊU ĐỀ PR — PR một commit được squash bằng tiêu đề COMMIT, lọt 90 ký tự lên `main`

*Ngày:* 2026-10-09 (#234: tiêu đề PR rút còn 66 ký tự để qua cổng `metadata`, nhưng commit duy nhất giữ tiêu đề 90 ký tự → squash
lấy tiêu đề commit → `main` nhận `db9bda6` với subject 90 ký tự). Cùng khuôn với B-01 (audit 2026-09-13): mọi chuỗi CÓ THỂ thành
tiêu đề commit trên `main` đều phải qua cùng một bộ kiểm — cổng Conventional Commits đã soi commit subject từ B-01, cổng độ dài thì chưa.

*Cách rà:* với mỗi điều kiện kiểm tiêu đề PR trong `pr-policy.yml`, hỏi "có áp cho `commitSubjects` chưa?"; GitHub squash dùng tiêu
đề commit khi PR có đúng một commit và dùng tiêu đề PR khi nhiều commit.

*Cổng chốt chặn:* `pr-policy.yml` job `metadata` fail khi bất kỳ commit subject nào > 72 ký tự (PR closeout 2026-10-09).

## 59. Brief cho worker tự nhận "0 quyết định để ngỏ" nhưng mâu thuẫn với chính khuôn nó đưa — worker dừng đúng, Tầng 1 mất một vòng

*Ngày:* 2026-10-09 (nghiệm thu agent đợt 3, `docs/reports/2026-10-09-agent-acceptance.md`): PLAN.md giao `mechanical-worker` nối
một khối README "kể cả dòng trống đầu" nhưng khối trong fence không có dòng trống đầu → worker chọn khối đúng từng ký tự theo fence,
báo mơ hồ và xin quyết định; kết quả lệch đúng như worker cảnh báo. Cùng đợt: worker không chạy cổng vì brief không đòi; reviewer không
xác minh được đỏ-trước vì worker không nộp output; worker thử `git reset --hard` (hook chặn). Bốn lỗi đều của **brief**, không của worker.

*Cách rà:* trước khi dispatch hỏi "nếu worker làm đúng từng chữ brief này thì có ra đúng kết quả mình muốn không?" — với `mechanical`
tự chạy `od -c`/`cat -A` lên khuôn trong fence; với mọi route: brief có đòi cổng + output đỏ/xanh + cấm hoàn tác lịch sử chưa.

*Cổng chốt chặn:* `scripts/subagent-dispatch.sh --check-plan PLAN.md` (thoát 1 khi thiếu trường/placeholder/route lạ/phụ thuộc
sai-vòng/việc không thuộc đúng một PR/mechanical không có fence hoặc điểm chạm glob); mẫu `docs/framework/templates/PLAN.template.md`
có sẵn khối "Luật chung" (cổng, output đỏ/xanh, cấm hoàn tác) để dán vào brief. Cổng kiểm hình thức kín, không kiểm khuôn đúng —
phần đó vẫn là việc của Tầng 1 (PR 2026-10-09).
