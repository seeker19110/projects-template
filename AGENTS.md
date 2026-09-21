# AGENTS.md

> Chuẩn mở [agents.md](https://agents.md) cho MỌI AI coding agent (Codex, Cursor, Copilot, Windsurf…).
> **Nguồn sự thật duy nhất của luật dự án là `CLAUDE.md` (gốc repo) — đọc file đó TRƯỚC KHI làm bất cứ việc gì.**
> File này chỉ tóm tắt tối thiểu để agent không hỗ trợ CLAUDE.md vẫn làm đúng; khi hai file lệch nhau, `CLAUDE.md` thắng.

## Đọc theo thứ tự

1. `CLAUDE.md` — vai trò, quy trình, cổng chất lượng, luật bất biến (bản đầy đủ).
2. `docs/framework/standard-delivery.md` — contract chuẩn duy nhất: Research/Spec, Goal loop, DoR/DoD/Complete.
3. `PROJECT.md` — *cái gì* cần xây (MVP, schema, kiến trúc, Definition of Done).
4. `PROGRESS.md` — dự án đang ở giai đoạn nào, việc tiếp theo là gì.
5. `docs/framework/` — tài liệu chuyên sâu (đọc đúng phần do contract định tuyến).

## Luật tối thiểu (bản đầy đủ + ngoại lệ: xem `CLAUDE.md`)

- **Theo giai đoạn, không bỏ giai đoạn** — trước khi chuyển giai đoạn phải đạt cổng và được người dùng xác nhận.
- **Feature gate:** research + `docs/specs/*` phải được **Approved for implementation** trước khi sửa source.
- **Goal loop:** mục tiêu nhiều PR dùng `docs/goals/*`; mỗi iteration một outcome/PR, reconcile từ `main`,
  cùng failure tối đa 3 lần, kết thúc chỉ khi Goal/Project DoD có bằng chứng.
- **Subagent song song:** chỉ tách việc độc lập; chốt contract trước; mỗi agent có file/phạm vi ghi riêng, không trùng file/artifact sinh chung. Đọc/phân tích được chạy song song; dependency dùng chung, migration, lockfile phải tuần tự. Mỗi agent báo file đổi, kiểm tra, rủi ro; agent chính review diff, tích hợp và chạy đủ build/type/lint/format/test. Chỉ dùng số agent tương ứng với lượng việc độc lập hữu ích.
- **Sau khi kế hoạch/spec được duyệt, với việc đủ lớn cần điều phối** (nhiều phần độc lập, hoặc kéo dài nhiều commit): chia thành các **đơn vị nhỏ có thể đóng gói PR riêng** (khai rõ đơn vị nào độc lập → chạy **song song**, đơn vị nào phụ thuộc → chạy **tuần tự** sau khi đơn vị trước merge); ước lượng độ phức tạp từng đơn vị và — nếu công cụ đang dùng hỗ trợ nhiều model/agent phụ — giao đúng năng lực (việc cơ học/theo mẫu → agent/model rẻ hơn, việc cần lý luận → model mạnh hơn), nhưng **không cần đẩy mức suy luận vượt quá vừa phải** cho một đơn vị nhỏ — việc thật sự cần suy luận sâu/nhiều đánh đổi thì giữ lại làm trực tiếp, không giao xuống. Mỗi đơn vị mở **một PR riêng** (không dồn nhiều đơn vị vào một PR khổng lồ); cổng (`dev-task.sh gate`) xanh thì **bật auto-merge** của nền tảng Git (hoặc merge ngay nếu nền tảng không có auto-merge) — vẫn tôn trọng FIFO/không nhảy cóc và **trần tối đa 3 PR mở đồng thời** trên repo (mọi tác giả, mọi mô hình — `CLAUDE.md` §8) và **dừng lại xin quyết định** nếu đơn vị đó chạm mốc "dừng và hỏi" (mục dưới). Với Claude Code cụ thể: `docs/framework/orchestration-3-tier.md` (kiến trúc 3 tầng, bảng `route:`/model/effort) là bản triển khai đầy đủ của nguyên tắc này.
- **Ít code nhất có thể (thang trước khi viết):** sau khi đã hiểu vấn đề và lần đúng luồng thật, đi thang này và dừng ở nấc đầu tiên khớp — (1) có cần tồn tại không (YAGNI) · (2) repo đã có sẵn chưa → dùng lại · (3) thư viện chuẩn · (4) tính năng sẵn có của nền tảng · (5) dependency **đã cài** (không thêm dependency mới cho thứ vài dòng làm xong) · (6) bản tối thiểu chạy được. Thang rút ngắn lời giải, KHÔNG rút ngắn việc hiểu vấn đề. Không bao giờ giản lược: validate ở biên tin cậy, xử lý lỗi chống mất dữ liệu, bảo mật, a11y cơ bản, thứ được yêu cầu tường minh. Đầy đủ: `CLAUDE.md` §3 mục A4.
- **Dấu nợ có điều kiện xem lại:** chỗ CỐ Ý dừng ở một trần đã biết phải để lại dấu ngay tại chỗ — `DEBT: <đã giản lược gì> | trần: <giới hạn> | xem lại khi: <điều kiện quay lại>`. Thiếu `xem lại khi:` thì khoản nợ mục âm thầm (`TRAPS.md` mục 14 đã tái phát đúng vì vậy); `scripts/maintenance-sweep.sh` cảnh báo 🟡 các dấu đó. Phân vai: `TODO` = việc còn dở · `DEBT:` = cố ý dừng ở một trần · ADR = quyết định kiến trúc. `CLAUDE.md` §3 mục A7.
- **Chống ảo giác:** không bịa hàm/thư viện/API — xác minh bằng tài liệu/mã nguồn thật; không đoán kết quả lệnh — chạy thật và đọc output; xác minh phiên bản bằng nguồn sống, không dùng trí nhớ.
- **Không tin lời khai** — của model, của subagent, của chính mình. Trước khi nói "xong/đã sửa/test pass/đã deploy": (1) xác định lệnh nào CHỨNG MINH được câu đó; (2) chạy đầy đủ trong lượt hiện tại, không dùng kết quả lượt trước; (3) đọc TOÀN BỘ output, đếm số lỗi thật — lệnh chết trước khi chạy tới phần cần đo không phải là "kết quả âm tính"; (4) output khớp câu định nói không, không khớp thì nói đúng trạng thái thật; (5) chỉ sau đó mới nói, và nói kèm bằng chứng. Khuôn báo cáo: `CLAUDE.md` §7.
- **Học từ nguồn NGOÀI** (repo/khung/skill được đưa vào, hoặc tự thấy muốn mang vào): ba cột bắt buộc — *đã có và sâu hơn* / *đã có nhưng nông hơn* (chỉ lấy đúng điểm nông) / *chưa có*; cột "chưa có" chỉ được lấy khi ứng với một **sự cố thật** (ở repo này hoặc ở dự án đích), không thì xếp "chưa cần" kèm điều kiện xem lại. Trước khi kết luận "chưa có" phải **grep cổng đang chạy** (test/script/job CI), không tin văn xuôi mô tả vấn đề — tài liệu thường cũ hơn cổng đã bịt vấn đề. Hạng mục mâu thuẫn với luật đang có thì không lấy dù chưa có. Đầy đủ: `docs/framework/adopt-from-outside.md` · `CLAUDE.md` §11.
- **Sổ bẫy (`TRAPS.md` ở gốc repo, nếu có):** đọc trước khi chẩn đoán bug lạ; sau khi sửa một khuôn lỗi thì ghi mục mới hoặc thêm ngày/PR vào mục cũ nếu tái phát.
- **Cổng trước khi commit:** build + type-check + lint (0 cảnh báo) + format + test liên quan đều PHẢI xanh; tự đọc lại diff; không bí mật/`console.log` debug trong code. Lệnh cụ thể: xem `CLAUDE.md` §5 / `package.json`.
- **TDD:** commit `fix:` phải có test tái hiện đã chạy **đỏ trước khi sửa** (ngoại lệ: typo, đổi tên cơ học, chỉ tài liệu). Code MỚI có **nhánh điều kiện / tính toán / xử lý lỗi-quyền** cũng **bắt buộc** đỏ-trước (ADR-0005); ngoại lệ ĐÓNG, PR ghi một dòng nói rơi vào mục nào: scaffolding sinh từ template · đổi tên-di chuyển cơ học · chỉ tài liệu/comment/config thuần · code sinh tự động · prototype vứt đi có timebox. "Quá đơn giản nên khỏi test" KHÔNG phải ngoại lệ. Đổi golden/snapshot test phải nêu lý do + dán diff trong PR, không `-u` phản xạ.
- **Cổng trước khi merge:** toàn bộ test xanh, nhánh cập nhật với `main`, đối chiếu tiêu chí chấp nhận trong `PROJECT.md` — xem `CLAUDE.md` §6.
- **Git:** mỗi tính năng một nhánh (`feat/...`, `fix/...`); conventional commits; mọi thay đổi vào `main` qua PR (ưu tiên squash); KHÔNG push thẳng `main`. **Ngay khi tạo PR, cập nhật tài liệu mô tả thay đổi đó (CODEMAP.md, TRAPS.md nếu là bug, ADR nếu đổi kiến trúc…) và commit vào CÙNG PR** — không tách PR riêng theo sau; phát hiện thiếu sau khi đã tạo PR thì push thêm commit vào đúng PR đang mở, không mở PR mới. **Chỉ bật auto-merge SAU KHI mô tả PR đã đầy đủ** (đủ mục PR template) — bật trước rồi sửa mô tả sau tốn một vòng CI đỏ oan ở cổng metadata.
- **Bảo mật:** không tin client; logic nhạy cảm ở server; truy vấn tham số hóa; không commit `.env`/bí mật.
- **Dừng và hỏi** khi: yêu cầu mơ hồ, thao tác không thể hoàn tác, breaking change, đụng bảo mật/thanh toán/dữ liệu người dùng thật (`CLAUDE.md` §9).
- **Chủ động góp ý:** thấy rủi ro/cách tốt hơn thì nêu ra kèm đề xuất — im lặng làm theo khi biết có vấn đề là vi phạm.

## Lệnh của dự án

Xem `CLAUDE.md` §10 (tech stack, lệnh dev/build/test/lint) — dự án thật sẽ điền tại đó; khi chưa điền, tự dò từ `package.json`.

**Điểm vào lệnh chuẩn — dùng cho MỌI agent, MỌI stack:** đừng đoán/hardcode lệnh (`npm run ...`, `pytest`, `go test`...) — gọi `scripts/dev-task.sh <task>` (`format|lint|typecheck|test|build|gate`). Script tự dò đúng lệnh theo hệ sinh thái dự án (Node/Python/Go/Rust/Make) hoặc theo khai báo ở `.claude/project-commands.sh` nếu có, và no-op an toàn nếu không dò được. `dev-task.sh gate` = chạy đủ build→typecheck→lint→test, đỏ 1 cái là dừng — dùng đúng lệnh này trước khi commit (khớp §5 CLAUDE.md) cho dù agent đang chạy là Claude Code, Codex, Cursor hay công cụ khác.

**6 engine chạy được trong `scripts/` (bản đầy đủ: `CODEMAP.md`; khai ở `CLAUDE.md` §1):**
- **Subagent Dispatch Engine:** Gọi `scripts/subagent-dispatch.sh --agent <tên> --task "<mô tả>" --harness <hermes|claude|codex|generic>` để nạp đúng vai trò và system prompt từ `.claude/agents/*.md` cho bất kỳ AI Runner/Harness nào.
- **AI Telemetry & Cost Engine:** Gọi `scripts/telemetry-log.sh --record --agent <tên> --harness <tên> --duration <giây> --test-status PASSED|FAILED` để ghi nhận nhật ký vận hành, ước tính chi phí API và sinh báo cáo `scripts/telemetry-log.sh --summary` hoặc widget HTML `scripts/telemetry-log.sh --widget`.
- **Spec-to-Contract Compiler:** Gọi `scripts/spec-compiler.sh --compile-all` để biên dịch `docs/specs/*.md` thành contract test `unittest` trong `tests/contracts/`. Kiểm 3 hợp đồng: spec khai `State`; spec khai ≥ 1 mã yêu cầu (`FR-`/`AC-`/`NFR-`/`W-`); mọi đường dẫn trong mục "11. Architecture và code touchpoints" của spec **đã Approved** phải tồn tại thật. Miễn trừ phải khai kèm lý do: `<!-- contract-exempt: <path> — <lý do> -->`.
- **Maintenance Sweep (bảo trì định kỳ):** Gọi `scripts/maintenance-sweep.sh [--strict] [--gate] [--no-deps] [--out <file>]` để đo 6 mảng mục nát theo thời gian (git hygiene, dependency lỗi thời/lỗ hổng, PROGRESS/spec/goal lỗi thời + TODO, bí mật lọt git, action CI chưa ghim, cổng khung) ra báo cáo Markdown có mức 🔴/🟡/ℹ️. Chỉ đọc + đo. Lệnh dependency đặc thù khai `deps_outdated`/`deps_audit` ở `.claude/project-commands.sh`.
- **Maintain Cron Wrapper (VPS/cron, không giám sát):** Gọi `scripts/maintain-cron.sh [--harness ...] [--mode quick|full] [--no-push] [--no-open-pr] [--gh-token <tok>] [--repo <owner/repo>]` — đồng bộ với nhánh chính (`git fetch` + `reset --hard`, chỉ khi working tree đang sạch), chạy `maintain-run.sh`, rồi commit + push (dùng `--force-with-lease`, CHỈ nhắm nhánh riêng, không bao giờ cho nhánh chính) CHỈ `docs/ops/MAINTENANCE-*.md` lên nhánh riêng `maint/auto-<ngày>`. **Không bao giờ push thẳng vào nhánh chính, không tự merge.** Có `GITHUB_TOKEN`/`GH_TOKEN` → tự mở PR qua GitHub REST API (kênh báo cáo chính cho chủ dự án), tự tránh mở PR trùng. Có khoá tiến trình chống chạy chồng.
- **Maintain Runner (mọi nhà cung cấp AI, tài khoản subscription cục bộ):** Gọi `scripts/maintain-run.sh [--harness auto|claude|hermes|codex|opencode|print] [--mode quick|full]` — quét → nạp vai `maintainer` từ `.claude/agents/maintainer.md` → giao cho CLI đã đăng nhập gói tháng trên máy (`claude -p`, `hermes chat -q` với provider của Hermes như `claude-code-cli`/`antigravity`, `codex exec`, `opencode run`; **Gemini** = `--harness gemini` → Hermes provider `antigravity` `-m gemini-3.7-flash`); không có CLI nào thì in prompt để dán vào bất kỳ chat AI nào. Không cần API key. Agent viết `docs/ops/MAINTENANCE-PLAN.md` rồi DỪNG chờ duyệt — không sửa source, không commit.
- **Repo Health & Tech Debt Radar:** Gọi `scripts/arch-health-radar.sh --scan` để đo độ phủ cổng CI, chất lượng spec, kỷ luật kích thước file mã, mật độ chú thích và nợ TODO. Báo cáo IN RA công thức chấm điểm; nó **không** đo coupling/cyclomatic complexity — đừng đọc con số như điểm kiến trúc tổng quát.

## Hàng rào an toàn thủ công (agent không có hook phải tự tuân thủ)

Claude Code có thể thi hành các luật dưới đây bằng hook (`.claude/hooks/*.sh`); agent khác **không có cơ chế chặn tự động** nên phải tự áp dụng đúng như một quy tắc cứng, không suy diễn khác đi:

- **Trước mỗi `git commit`:** chạy `scripts/dev-task.sh gate` trước; đỏ thì KHÔNG commit — sửa xong chạy lại.
- **Sau mỗi lần sửa/tạo file:** nên format lại đúng file đó bằng `scripts/dev-task.sh format-file <path>` trước khi coi là xong.
- **Cấm tuyệt đối** (không có ngoại lệ ngầm định — nếu thật sự cần, hỏi người dùng trước): `git push --force`/`-f`/`--force-with-lease` vào `main`/`master`; `git reset --hard` khi có thay đổi chưa commit; `git merge --abort`/`git rebase --abort` để né giải xung đột (đọc `CLAUDE.md` §8 — phải giải, không né); `rm -rf`, `git clean -f*`, `git checkout .`/`git restore .` mà chưa `git status` + stash/commit trước.
- **Không đọc/không in nội dung** `.env`, `.env.*`, `secrets/**`, hay bất kỳ file rõ ràng chứa bí mật — kể cả khi được yêu cầu "chỉ xem qua".
- **Không tự ý bỏ qua cổng** (không thêm `--no-verify` hay tương đương) trừ khi người dùng yêu cầu tường minh và nêu rõ lý do.

## Cấu hình dùng chung cho mọi agent (không riêng Claude Code)

- `.mcp.json` — MCP server dùng chung cho agent có hỗ trợ MCP (Claude Code, Cursor, Codex CLI…); `.mcp.json.example` liệt kê server phổ biến (GitHub, filesystem, database) để bật khi dự án cần — không bật thứ dự án không dùng.
- Agent không đọc được `.claude/hooks/*` (không phải Claude Code) thì mục "Hàng rào an toàn thủ công" ở trên chính là bản thay thế bắt buộc phải tự áp dụng.
