# PROGRESS.md — Trạng thái dự án

> Tóm tắt toàn dự án; cập nhật sau mỗi mốc. Goal nhiều PR theo dõi chi tiết ở `docs/goals/*`.
> Không sao chép iteration log vào đây. (Repo này LÀ bộ khung — file này là nhật ký của chính khung,
> không copy sang dự án đích; dự án đích nhận bản sạch từ `PROGRESS.template.md`.)

## Giai đoạn hiện tại

- Giai đoạn: GĐ 8. **Mốc (2026-09-23, PR #PRNUM, đang mở — nhánh `claude/ui-ux-skills-upgrade-f0d0ex`): nâng cấp
  `/ui-ux`.** Theo yêu cầu người dùng "nâng cấp kỹ năng thiết kế UI/UX". Đối chiếu ba cột với skill
  `ui-ux-design` v6 của repo Claude-Agents (`docs/reports/2026-09-23-doi-chieu-ui-ux-design-v6.md`): lấy 9 điểm
  cột 2, mỗi điểm siết một luật cứng đang có (§3.3/3.8/3.9/3.10/§4); cột 3 (danh mục "mặc định của AI", vân
  tay cấu trúc, tự chấm 6 trục) xếp "chưa cần" vì không có sự cố ghi nhận; breakpoint/type scale cố định
  không lấy vì mâu thuẫn `TRAPS.md` §9. Sửa câu "File thật: `styles/theme.css`" sai với ADR-0004.
- Giai đoạn trước đó: GĐ 8. **Mốc (2026-09-22, PR #163, đã merge — SHA `f2e4bbc`): đối chiếu 8 nguồn ngoài
  (bảng "Top 10 Hermes Skill Repos") + tinh chỉnh vòng đời worktree của `coordinator`.** Theo yêu cầu
  người dùng đối chiếu ba cột (`adopt-from-outside.md`) cho Graphify, Understand Anything, Caveman,
  last30days-skill, i-have-adhd, Agentic Awesome Skills, Scientific Agent Skills, Diagram Design (+
  bổ sung `obra/superpowers` đã đối chiếu sơ trước đó). Ghi `docs/reports/2026-09-22-doi-chieu-hermes-
  skill-leaderboard.md`: 1/8 qua cổng §2 (sự cố thật ở `TRAPS.md` — script cổng thiếu dòng CODEMAP.md)
  → đề xuất ý tưởng đồ thị codebase tự sinh, **chưa code, chờ Feature gate riêng**. Theo yêu cầu tiếp
  theo, đọc trực tiếp 3 `SKILL.md` thật của `superpowers` (using-git-worktrees, dispatching-parallel-
  agents, finishing-a-development-branch) → tìm 3 điểm nông ở `.claude/agents/coordinator.md` (thiếu
  phát hiện cô lập sẵn có, thiếu baseline verification, thiếu dọn worktree an toàn sau merge) → người
  dùng duyệt sửa trực tiếp: bước 2 tách 2a/2b/2c, thêm bước 7 dọn worktree (kiểm `git status
  --porcelain -uall` trước, không force-delete). Đồng bộ `docs/framework/orchestration-3-tier.md` trỏ
  về `coordinator.md` làm nguồn sự thật (xác nhận `scripts/subagent-dispatch.py` đọc chung một file
  cho mọi harness đa nhà cung cấp — không có bản coordinator riêng theo provider cần sửa thêm). PR tạo
  từ Claude Code UI; job `metadata` đỏ lần đầu vì mô tả PR thiếu 2 mục template (`Risk, rollout and
  rollback`, `Definition of Done`) — bổ sung qua `update_pull_request`, job tự kích lại và xanh. Chủ
  repo bật auto-merge (squash), CI xanh hết, đã merge.
- Giai đoạn trước đó: GĐ 8. **Mốc (2026-09-21, PR #161, đã merge — SHA `1ec4bed`): rà lại toàn bộ .md, vá
  1 chỗ sót.** Theo yêu cầu người dùng "kiểm tra lại toàn bộ file .md còn lỗi thời không" (nối tiếp
  PR #159). Grep lại toàn bộ phạm vi file luật bằng cùng tiêu chí đã chốt + thêm mẫu không kèm ngày
  tháng (trước đó là/đã ngừng/quy ước cũ...). Tìm thấy 1 chỗ sót: `docs/framework/quality-supplements.md`
  dòng dẫn ADR-0004 còn kèm ngày `(2026-09-12)` giống mẫu đã xử lý ở `FEATURE-MAP.md` nhưng bị bỏ sót
  lúc PR #159. Rút gọn thành "Theo ADR-0004: ..." — giữ nguyên ý luật. Các match còn lại xác nhận đều
  là luật hiện hành (mốc snapshot cần xác minh lại, ví dụ tên file chuẩn, phát biểu trạng thái hiện tại
  như "opusplan đã ngừng hỗ trợ") — không phải tường thuật lịch sử, không sửa.
- Giai đoạn trước đó: GĐ 8. **Mốc (2026-09-21, PR #159, đã merge — SHA `2ed9767`): xoá tường thuật lịch sử
  khỏi file quy định luật.** Theo yêu cầu người dùng "chỉ giữ những quy định luật lệ hiện hành, xoá
  hết lịch sử thay đổi khỏi mọi file *.md". Sau hai vòng `AskUserQuestion` để chốt phạm vi (loại trừ
  docs/adr/*.md và TRAPS.md — trái luật "không sửa ADR cũ"/mất giá trị sổ bẫy; loại trừ mọi file có
  chức năng nhật ký/đặc tả/báo cáo theo thời điểm: PROGRESS.md, CHANGELOG.md, docs/specs/*,
  docs/reports/*, docs/research/*, docs/ops/*), giao subagent dọn 10 file luật còn lại: `CODEMAP.md`,
  `docs/CONVENTIONS.md`, `docs/FEATURE-MAP.md`, và 7 file `docs/framework/*.md` (adopt-from-outside,
  industry-standards, models-and-automation, new-project-runbook-part-e-checklist,
  orchestration-3-tier, quality-gates-by-profile, quality-supplements-group2) — bỏ các đoạn "đã làm
  gì/ngày nào/PR nào/chốt ngày X thay quy ước cũ Y", giữ nguyên ý nghĩa luật hiện hành. Bỏ qua
  `docs/framework/case-study-greenfield-dry-run.md` vì toàn bài là tường thuật một lần chạy thử, không
  có luật độc lập. Soát diff, mở PR #159, CI xanh, đã merge.
- Giai đoạn trước đó: GĐ 8. **Mốc (2026-09-21, PR #157, đã merge — SHA `22829d2`): thêm trần WIP tối đa 3 PR
  mở đồng thời.** Theo yêu cầu người dùng (thay thế đề xuất FIFO tuyệt đối "chỉ tạo PR mới khi PR cũ
  đã merge hết" — bị nhận xét sẽ triệt tiêu song song hóa), chốt trần WIP = tối đa 3 PR mở đồng thời
  trên toàn repo, mọi tác giả/mọi mô hình AI, vẫn giữ FIFO cho thứ tự merge. Cập nhật `CLAUDE.md` §8
  và `AGENTS.md` (dòng tham chiếu điều phối) cho khớp. PR được tạo từ Claude Code UI (không phải do
  phiên tự mở), đăng ký theo dõi qua `subscribe_pr_activity`, CI xanh hết 10 check, không review
  comment nào, merge squash trực tiếp (đã clean, không cần auto-merge).
- Giai đoạn trước đó: GĐ 8. **Mốc (2026-09-21): `/maintain` quét định kỳ, kết quả sạch gần tuyệt đối.**
  Đồng bộ `main` (44 commit sau, fast-forward lên `2c62723`) rồi giao subagent `maintainer` chạy
  `maintenance-sweep.sh`: 🔴 0 · 🟡 1 (nhánh local `claude/brave-gates-tn5hak` đã merge còn sót) ·
  ℹ️ 5 (đều n-a/không phải nợ thật — xem `docs/ops/MAINTENANCE-LOG.md`). Duyệt M-01, xoá nhánh
  local (nhánh remote hoá ra đã không còn tồn tại từ trước, GitHub tự dọn sau merge PR #153).
  Quét lại `--strict` chỉ còn 🟡 1 là chính `MAINTENANCE-PLAN.md` vừa sinh (không phải phát hiện
  thật, như lượt 2026-09-15). Không có mục DỪNG & HỎI, không đổi source code. Đẩy PR #153-kế
  tiếp — chore/maint riêng cho M-01 + cập nhật `MAINTENANCE-PLAN.md`/`MAINTENANCE-LOG.md`/
  `PROGRESS.md` — mở PR #155, auto-merge, CI xanh, đã merge (SHA `58464d4`). **Xác nhận cuối:**
  đồng bộ lại `main` về `58464d4`, chạy `maintenance-sweep.sh --strict` lần nữa → **🔴 0 · 🟡 0**,
  sạch tuyệt đối (chỉ còn 5 mục ℹ️ thông tin, không phải nợ thật).
- Giai đoạn trước đó: GĐ 8. **Mốc (2026-09-21, PR #153, đã merge — SHA `3892c37`): mở rộng tập skill
  tự-trigger.** Người dùng yêu cầu thêm skill tự-trigger cho vibe-coding; sau khi hỏi phạm vi
  (`AskUserQuestion`), thêm 3 skill mới: `/review` (rà soát logic/thiết kế trước khi mở PR, bổ sung
  cho `/gate`), `/deps-upgrade` (nâng cấp dependency theo yêu cầu cụ thể/CVE, khác `/maintain` định
  kỳ), `/contract` (chốt schema DB/API trước khi code, nối vào feature gate CLAUDE.md §2). Đăng ký
  TRIGGER trong CLAUDE.md mục 1. Tiện thể đặt mặc định nhịp check-in PR babysit = 5 phút (CLAUDE.md
  §8 + §10, trước đó §8 ghi 3 phút — đã đồng bộ theo yêu cầu người dùng). PR ban đầu đặt tiêu đề
  `feat:` sai bản chất (đây là thay đổi tài liệu/skill khung, không phải feature source code) khiến
  cổng `metadata` đỏ do đòi `docs/specs/*` Approved; sửa lại `docs:` cho khớp Change type đã khai
  trong PR body, qua hết 10 check.
- Giai đoạn trước đó: GĐ 8. **Mốc (2026-09-19): `/maintain` quét toàn repo theo yêu cầu người dùng
  ("tối ưu file rồi context, cái nào không còn áp dụng thì xoá bỏ").** `maintenance-sweep.sh` sạch
  tuyệt đối (🔴 0 · 🟡 0). Rà tay thêm vùng máy không phủ (tham chiếu tên file trong YAML/shell, file
  mồ côi, ADR/spec/goal treo) tìm được đúng 1 mục thật: `ci.yml` job `metadata` vẫn kiểm JSON của tên
  file cũ `settings-shared-opusplan.json` (đã đổi tên sang `settings-shared-default.json` từ ADR-0007,
  2026-09-15) — guard `if [ -f ]` khiến cổng lặng lẽ bỏ qua, file cấu hình thật chưa từng được kiểm
  JSON hợp lệ. Sửa 1 dòng `ci.yml` (`docs/ops/MAINTENANCE-PLAN.md` mục M-01). Mọi nội dung khác
  (ADR, `docs/reports/`, spec đã Approved, changelog, TRAPS) là hồ sơ lịch sử bắt buộc giữ nguyên
  theo chính luật khung — không xoá.
- Giai đoạn trước đó: GĐ 8. **Mốc (2026-09-19): bản đồ 5 tầng SDLC (ADR-0008, đã duyệt).**
  Người dùng đề xuất mô hình 5 core AI (Product & UX · Design · Engineering · Verify & Operate ·
  Knowledge) + controller deterministic + worker động. Đối chiếu ba cột
  (`docs/reports/2026-09-19-doi-chieu-mo-hinh-5-tang-sdlc.md`): khung đã có và sâu hơn ở 10/13 hạng
  mục; lấy 2 điểm nông — bản đồ một trang `standard-delivery.md` §3b (tầng ↔ cổng ↔ lệnh/agent ↔
  artifact ↔ cổng máy ↔ fail quay về) + luật quy lỗi về tầng trước lần sửa thứ 2; **không** tạo 5 agent
  cố định (mâu thuẫn luật Tầng 1 giữ quyền hỏi). Người dùng đã duyệt ADR-0008 (2026-09-19).
- Giai đoạn trước đó: GĐ 8. **Mốc (2026-09-19): làm rõ CLAUDE.md §8 mục (5) — không bắt buộc PR
  riêng để sync `PROGRESS.md`.** Sau khi PR #146/#147 (đối chiếu `donghanh`) cần tới 2 PR liên tiếp
  chỉ để sync `PROGRESS.md`, người dùng yêu cầu gộp bước này vào PR việc kế tiếp thay vì tách riêng
  — thêm một câu làm rõ vào CLAUDE.md §8 mục (5): "ngay" nghĩa là trước khi mở/merge PR kế tiếp,
  không bắt buộc một PR riêng; chỉ tách khi việc kế tiếp còn xa. PR này áp dụng luôn quy tắc vừa
  thêm (gộp cập nhật `PROGRESS.md` vào cùng PR).
- Giai đoạn trước đó: GĐ 8. **Mốc (2026-09-19, PR #146 đã merge): 5 thực hành lấy từ đối chiếu dự án
  `seeker19110/donghanh`.** Theo yêu cầu người dùng "phân tích lấy những điểm mạnh về cho dự án"
  từ repo `donghanh` (dự án production từng dùng một bản khung này), chạy đúng phương pháp 3 cột
  của `adopt-from-outside.md`. Kết quả: 5 điểm ưu tiên nhất được đưa vào khung — (1) tách nhật ký
  đợt việc khỏi `PROGRESS.md` ra `docs/changelog/` (mục 9, `quality-supplements-group1.md`), (2)
  cảnh báo "máy xanh giả" (lockfile lệch/dist cũ/lệnh khác CI thật) thêm vào `.claude/commands/gate.md`
  Bước 1, (3) cảnh báo "oracle test tự trùng nguồn với input" thêm vào mục 6 `quality-supplements-group2.md`,
  (4) kill-switch runtime cho tính năng gọi LLM + eval bắt buộc khi đổi prompt/model (C7 mục 7-8,
  `quality-gates-by-profile.md`) kèm mẫu mới `docs/framework/templates/AI-EVAL.template.md`, (5)
  nguyên tắc đồng bộ trạng thái duyệt ngoài git về file trong repo (mục 10, group1). 5 điểm còn lại
  (contrast-audit tự động, quét tĩnh migration nguy hiểm, red-team AI feature, "biên độ còn lại"
  cho ngưỡng chất lượng, 2 điểm nông của AUDIT.md) xếp "chưa cần ngay" — để người dùng quyết sau.
  Kiểm: `check-docs-consistency.sh` xanh, `check-ci-policy.sh` xanh, CI PR #146 `success`.
- Giai đoạn trước đó: GĐ 8. **Mốc (2026-09-19, PR #145 đã merge): hook
  Stop `telemetry-record.sh` — đóng khoảng cách "kỷ luật §5 chỉ nằm trên giấy".** Theo yêu cầu
  người dùng "audit tối ưu quy trình và giảm token", rà `models-and-automation.md` §5 với thực tế:
  `telemetry-log.sh --record` được tài liệu hoá là "ghi mỗi tác vụ AI" nhưng **không hook nào gọi
  thật** — chỉ gọi tay theo `AGENTS.md` hoặc trong `maintain-run.sh` khi chạy agent `maintainer`.
  Hệ quả: chưa từng có dữ liệu thật để biết phiên có tuân theo "plan một lần/ngữ cảnh gọn" hay
  không (cùng khuôn C-01 "khung chưa từng dùng trọn vẹn cho dự án thật"). Thêm
  `.claude/hooks/telemetry-record.sh` (đọc thời lượng từ `transcript_path`, model từ
  `settings.json`, gọi `telemetry-log.sh --record`, best-effort không chặn phiên) + đăng ký vào
  `Stop` của CẢ `settings.json` VÀ `settings-shared-default.json` (CODEMAP.md yêu cầu khớp hai
  file) + cập nhật bảng/sơ đồ hook trong `models-and-automation.md` §6. `copy-framework.sh`/`.ps1`
  không cần sửa (copy cả thư mục `.claude/hooks`). Kiểm: `test-hooks-gate.sh` xanh (không đổi hành
  vi 2 hook cũ), `check-docs-consistency.sh` 8/8 mục xanh.
- Giai đoạn trước đó: GĐ 8. **Mốc (2026-09-19, PR #144 đã merge): đối chiếu 6 nguồn ngoài +
  khuôn severity cho review UI.** Theo yêu cầu người dùng "đánh giá tổng hợp cái hay" từ 6 nguồn
  (tasteskill.dev, `ianho7/ai-friendly-web-design-skill`, `bergside/awesome-design-skills`,
  `Octo-o-o-o/Image2Code`, `microsoft/playwright-cli`, `alibaba/open-code-review`), chạy đúng
  phương pháp `adopt-from-outside.md`. Kết quả: `docs/reports/2026-09-19-doi-chieu-6-nguon-ngoai.md`
  — 2 nguồn đã sâu hơn (không lấy), 1 điểm nông hơn lấy đúng điểm đó, 4 nguồn xếp "chưa cần" vì
  chưa qua cổng "sự cố thật" (mỗi mục có điều kiện xem lại), 1 nguồn mâu thuẫn luật (đa phong cách
  theme, không lấy dù chưa có). Việc thực lấy: thêm khuôn báo cáo severity 🔴/🟡/🟢 cho review UI
  có sẵn vào `.claude/commands/ui-ux.md`. Người dùng hỏi thêm về hạng mục `open-code-review`
  (rule-matching tất định + resume) — giữ nguyên "chưa cần", chưa có sự cố thật tương ứng.
  CI đỏ một lần ở job `metadata` (PR body thiếu mục `## Research / Spec` của template) — sửa body
  PR, chạy lại xanh, merge squash.
- Giai đoạn trước đó: GĐ 8. **Bảo trì định kỳ 2026-09-15 (`/maintain`, đợt sạch): 0 mục hành động.**
  `maintenance-sweep.sh` mặc định ra 🔴 0 · 🟡 0 · ℹ️ 5; Tầng 1 chạy lại `--strict` để kiểm chứng.
  Git sạch, 7 workflow ghim full SHA, không bí mật bị track, docs-consistency/ci-policy ✅,
  arch-health-radar 100/100. Dependency `n-a` do repo khung cố ý không có dependency manager.
  **Đính chính đáng giữ:** `--strict` ra 🟡 1 chứ không phải 0 — dòng đó là "1 file chưa commit",
  và file đó chính là `docs/ops/MAINTENANCE-PLAN.md` mà lượt quét vừa sinh ra. Lại một thể hiện nữa của
  khuôn "bộ dò tự khớp thứ nó đang soi" (xem mốc PR #141 ngay dưới) — không đếm chính xác là lần
  thứ mấy. Chưa có cổng nào chặn khuôn đó một cách tổng quát, mới chỉ xử lý từng ca.
  Nhật ký đợt: `docs/ops/MAINTENANCE-LOG.md` (file mới, một dòng/đợt, CÓ commit).

- Giai đoạn: GĐ 8. **Mốc gần nhất (2026-09-15, PR #141 đã merge): cổng chặn ký tự điều khiển vô
  hình trong `*.md` (mục 8 của `check-docs-consistency.sh`).** Gặp thật cùng ngày: một chuỗi Python
  thường chứa ký hiệu thoát `\` + `b` là BACKSPACE (0x08) chứ không phải hai ký tự literal, nên
  `PROGRESS.md` nhận một ký tự điều khiển vô hình giữa hai backtick — trình soạn thảo, trình xem
  Markdown và `git diff` đều không hiển thị, không cổng nào bắt; phát hiện chỉ vì tình cờ đọc lại
  bằng `cat -A`. Mục 8 quét mọi `*.md` do `git ls-files` liệt kê, **giữ TAB/LF/CR** (chặn chúng là
  chặn oan bảng Markdown và file checkout trên Windows) và **không soi NUL** (file có NUL đã là nhị
  phân). Mẫu dựng LÚC CHẠY bằng `printf`: bản đầu của chính commit đó viết ký tự thật vào source và
  tự khớp mình — lần thứ tư trong phiên của khuôn "bộ dò tự khớp văn bản của thứ nó đang soi".
  Negative test + đối chứng TAB/CR trong `test-check-scripts.sh`. **TRAPS mục 29.**
  **Cổng tự chứng minh ngay lần dùng đầu:** chính lượt viết mốc này lại sinh ra một backspace nữa
  (cùng nguyên nhân), và mục 8 chặn commit — sửa xong mới ghi được. Không có nó thì ký tự đó đã
  nằm trong `PROGRESS.md` như lần trước.
  **Giới hạn đã ghi:** cổng bắt HẬU QUẢ, không bắt NGUYÊN NHÂN (chuỗi không-raw trong script sinh
  tài liệu) — phần đó chỉ có TRAPS 29 + một dòng `CODEMAP.md`, không có cổng máy.
  **Bài học về ngưỡng dựng cổng:** tôi đề nghị chờ tái phát lần hai rồi mới làm; người dùng quyết
  làm luôn, và đúng — lúc viết trap mới thấy cùng khuôn đã xảy ra hai lần trong CÙNG phiên (ký hiệu thoát chữ `b`
  thành backspace, và một backreference `sed` thành 0x01 làm biểu thức thay bằng chuỗi rỗng mà
  không báo lỗi). Đếm theo "lỗi giống hệt" thì ngưỡng quá cao; phải đếm theo **cùng khuôn**.
- Giai đoạn trước đó: GĐ 8. **Mốc (2026-09-15, PR #139 đã merge): cổng
  `framework-lint-windows`.** Trước đó mọi job cổng chạy `ubuntu-latest`, nên cổng của khung chỉ
  chứng minh được điều gì đó TRÊN LINUX — trong khi khung nhắm tới người dùng Windows. Job mới chạy
  4 suite engine Python · `test-hooks-gate` · cổng CC shell + Python · `test-copy-framework`
  (`REQUIRE_PWSH=1`); cố ý không nhân đôi các kiểm thuần văn bản. Hai điểm dễ bị xoá nhầm về sau:
  KHÔNG đặt `core.autocrlf` (mặc định của runner chính là điều kiện đã làm hỏng `vendor/shellmetrics`)
  và bước bắt runner PHẢI có `jq` (thiếu `jq` thì `test-hooks-gate` báo BỎ QUA → cổng xanh giả).
  Theo ADR-0003 chỉ cần job mới + `needs:` của `gate` + bản kê `repository-settings.md`.
  **Bắt được 4 lỗi trong 4 lượt chạy đầu:** CP-4 so khớp `needs:` theo ranh giới từ nên `framework-lint`
  khớp bên trong `framework-lint-windows` (cổng để lọt) · AC-2 xanh oan vì đỏ sai lý do · **lỗi sản
  phẩm:** `os.path.relpath` ném `ValueError` khi hai đường dẫn khác ổ đĩa, làm `spec-compiler` chết
  trên runner (repo ở D:, tmp ở C:) · characterization test tự vỡ vì cũng gọi `relpath` để tính kỳ
  vọng. Chi tiết + cách rà: **TRAPS mục 28**, kèm bài học **một ca test đỏ mà không in được NGUYÊN
  NHÂN là một ca test chưa xong** (nuốt output bằng `>/dev/null 2>&1` đã làm đoán sai hai lượt liền).
- Giai đoạn trước đó: GĐ 8. **Mốc (2026-09-15, PR #136 + #137 đã merge): nới deny force-push
  + dọn nốt lỗi cp1252 ở Python nội tuyến.** Hai việc nối tiếp #134, cả hai đều do CHẠY THẬT
  trên máy Windows mới lộ.
  **(a) PR #136 — `permissions`:** `deny` cũ chặn MỌI force-push kể cả trên nhánh do chính phiên
  tạo, rộng hơn luật thật (`AGENTS.md`: cấm force-push **vào** `main`/`master`) — đã làm kẹt hai
  lần khi cần `--amend` một commit merge sai tiêu đề (#125 phải đóng + dựng lại nhánh; #134 phải
  nhờ người dùng gõ tay). Nay **ba lớp**: `deny` cho các cách viết nhắm thẳng `main`/`master`
  (chặn cứng, không phụ thuộc `jq`) · `ask` cho mọi force-push còn lại (hỏi từng lần) · hook
  `block-dangerous-git.sh` giữ nguyên làm lớp hiểu ngữ cảnh. **Giới hạn đã ghi trong
  `models-and-automation.md`:** mẫu `deny` so khớp chuỗi lệnh nên `git push --force` TRỐNG (đang
  đứng sẵn trên `main`) không khớp lớp 1 — rơi xuống lớp 2 và 3.
  **(b) PR #137 — cp1252 vòng hai:** khối `reconfigure` của #134 chỉ cứu file `.py`; **Python nội
  tuyến trong heredoc của `.sh`** không đi qua đó nên vẫn chết — 3 chỗ
  (`check-python-complexity.sh`, `test-engine-characterization.sh`, `usage-estimate.sh`), sửa bằng
  `PYTHONIOENCODING=utf-8`. Lỗi **bị che** suốt vì cổng CC Python thoát sớm hơn với "Thiếu radon".
  Bài học ghi vào bẫy 24: **một lỗi thoát sớm có thể đang giấu một lỗi khác ngay sau nó** — dọn
  xong điều kiện môi trường phải chạy LẠI (lần thứ hai trong cùng phiên: trước đó một
  `reset --hard` làm hỏng lại file vendor đã sửa). Biết thêm: `python` và `python3` có thể là HAI
  bản cài khác nhau trên cùng máy — `pip install` cho bản này không làm bản kia thấy.
  **Mốc môi trường:** người dùng đã cài `jq` 1.8.2 + `radon` 6.0.1 + `coverage` 7.16.0 — lần đầu
  máy dev Windows này chạy ĐỦ bộ cổng, `test-hooks-gate` đủ **21/21 ca** (không còn dòng BỎ QUA).
  Còn MỞ có chủ ý: chưa có cổng máy bắt heredoc Python MỚI phải có `PYTHONIOENCODING` — tái phát
  lần nữa thì làm cổng theo đúng lối CP-6.
- Giai đoạn trước đó: GĐ 8. **Mốc (2026-09-15, PR #134 đã merge): 4 lỗi chỉ nổ trên Windows,
  phát hiện khi người dùng hỏi "template này hoàn hảo chưa" và chạy toàn bộ self-test trên máy thật**
  (3/8 suite đỏ lúc đó). (1) 4 engine Python in tiếng Việt/emoji ra stdout → `UnicodeEncodeError`
  trên console cp1252; chỉ một ký tự `ạ` là đủ — ép UTF-8 cho `stdout`/`stderr` ở đầu cả 4 file
  (`TRAPS.md` bẫy 24). (2) `test-next-gen-engines.sh` + `test-telemetry-and-dispatch.sh` không job
  nào gọi nên 3 ca đỏ đó đi qua nhiều PR sạch — PR #113 đã nối tay, PR này thêm **CP-6** vào
  `check-ci-policy.sh` (mọi `scripts/test-*.sh` phải được `ci.yml` gọi) làm cổng máy chống tái phát,
  kèm negative test và khai ở bản dropins theo W-302 (bẫy 25). (3) `jq` chưa từng được khai là yêu
  cầu môi trường, mà hook cổng fail-open khi thiếu `jq` → máy không có `jq` **mất sạch hàng rào**
  (commit cổng đỏ, `push --force` lên `main`, `reset --hard` đều không bị chặn) mà không dấu hiệu gì
  — thêm mục "Yêu cầu môi trường" vào `README.md`, và `test-hooks-gate.sh` giờ báo **BỎ QUA kèm
  cảnh báo** thay vì kết luận sai bản chất "cổng chặn commit KHÔNG hoạt động" (§7) — bẫy 26.
  (4) Phát hiện thêm khi chạy lại cổng sau merge: `.gitattributes` ghim `eol=lf` theo ĐUÔI file nên
  `vendor/shellmetrics/shellmetrics` (**không có đuôi**) rơi vào `* text=auto` → CRLF trên Windows →
  SHA256 lệch → **cổng CC shell chết hoàn toàn trên mọi máy Windows** (CI chạy Linux nên không bao
  giờ lộ; xác nhận bằng worktree `main` sạch cũng đỏ y hệt) — thêm `vendor/** -text` + `*.py`/`*.ts`
  `eol=lf`, bẫy 27. **Lưu ý vận hành:** ai đã clone trước bản sửa phải chạy `git checkout -- vendor`
  một lần — `.gitattributes` chỉ áp lúc checkout, không tự chữa bản sao đã hỏng.
  **Lặp lại đúng vấn đề của PR #125** (xem mốc PR #128 dưới): commit merge giải xung đột có tiêu đề
  "Merge remote-tracking branch..." làm cổng `metadata` đỏ, sửa cần `git push --force-with-lease` —
  vẫn bị deny-list `Bash(git push --force*)` chặn. Lần này **không dựng lại nhánh**: `git commit --amend`
  đổi tiêu đề sang `chore:` (giữ nguyên hai cha, kiểm `%p` ra hai SHA; kiểm UTF-8 bằng `od -c` để
  tránh bẫy kèm của mục 22) rồi **người dùng tự chạy lệnh push** — rẻ hơn dựng lại nhánh và giữ được
  số PR. Kiểm chứng trước merge: 16/16 suite xanh trên Windows (`test-hooks-gate` đủ 21 ca khi có
  `jq`; `test-py-coverage` 96% ≥ sàn 95%; radon CC cao nhất 11 ≤ 12).
- Giai đoạn trước đó: GĐ 8. **Mốc (2026-09-15, PR #130 đã merge): ADR-0007 — bỏ `opusplan` làm
  mặc định.** Người dùng xác nhận `/model opusplan` đã ngừng được CLI
  hỗ trợ. ADR-0007 đảo ngược **một phần** ADR-0006 (mục 2 — "mặc định vẫn là `opusplan`"), không
  sửa ADR-0006: thay bằng chính sách hai pha làm **thủ công** — lập kế hoạch việc lớn chuyển tay
  `/model` sang model cao cấp nhất đang sẵn có, xong tự `/model claude-sonnet-5` quay lại thực thi;
  phân việc/PR cho subagent theo độ phức tạp qua `--tier` giữ nguyên không đổi (ADR-0006). Đổi:
  `.claude/settings.json` + `settings-shared-opusplan.json` (đổi tên → `settings-shared-default.json`)
  đặt `"model": "claude-sonnet-5"`; `session-guide.sh` bỏ so khớp `model_id` với `"opusplan"` (không
  còn ✅/⚠️ theo tên model, chỉ hiển thị + nhắc chính sách); viết lại `models-and-automation.md`
  (mục 1 đổi tên "opusplan là gì" → "hai pha lập kế hoạch/thực thi"); sửa mọi tham chiếu trong
  `orchestration-3-tier.md`, `new-project-runbook.md`, `case-study-greenfield-dry-run.md`,
  `CODEMAP.md`, `README.md`, `copy-framework.sh`/`.ps1`, `model-capability-tiers.json`, và các
  `.claude/commands/{adr,audit-full,auto,completion,consult,incident,maintain}.md` có dòng nhắc
  model/effort. `scripts/check-docs-consistency.sh` (7/7 mục) + `test-hooks-gate.sh` (10/10 ca)
  chạy lại xanh sau đổi — không có tham chiếu gãy tới file đã đổi tên. Không sửa nội dung lịch sử
  (log cũ trong chính file này, spec đã đóng, ADR-0006) — chỉ ADR mới ghi quyết định đảo ngược.
- Giai đoạn trước đó: GĐ 8. **Mốc (2026-09-15, PR #128 đã merge): ADR-0006 — điều phối 3 tầng đa
  model, đa nhà cung cấp.** Theo yêu cầu người dùng: trước tác vụ tự động/lập kế hoạch lớn phải
  chọn model cao cấp nhất sẵn có (không giới hạn Claude) theo độ phức tạp, rồi phân việc cho
  subagent đủ năng lực. Thêm `scripts/model-capability-tiers.json` (khuôn giống `model-rates.json`,
  có `_verified_on`/`_source`, model chưa xác minh đánh `verify_before_use`) +
  `scripts/subagent-dispatch.py --tier <planning|complex|spec|standard|mechanical>` (tra ứng viên
  đa nhà cung cấp, không dispatch) + ca test trong `test-telemetry-and-dispatch.sh` +
  `test-py-coverage.sh`. Cập nhật `CLAUDE.md` §2, `orchestration-3-tier.md` (mục "Chọn đa nhà cung
  cấp"), `models-and-automation.md` §2b, `CODEMAP.md`, `copy-framework.sh`/`.ps1`. Tận dụng hạ tầng
  đa-harness đã có sẵn (`subagent-dispatch.py --harness`, `maintain-run.sh`) — không viết engine
  mới. Spec: `docs/specs/2026-09-15-da-model-da-nha-cung-cap.md` (Approved for implementation).
  **PR #125 (nhánh `claude/hien-trang-b89ids`) bị đóng không merge**: một commit merge trên nhánh
  đó có tiêu đề không theo Conventional Commits ("Merge remote-tracking branch...") làm cổng
  `metadata` đỏ vĩnh viễn; sửa cần `git push --force-with-lease`, nhưng thao tác này bị deny-list
  tường minh trong `.claude/settings.json`/`.claude/settings-shared-opusplan.json`
  (`Bash(git push --force*)`) nên phiên không có quyền chạy dù trên nhánh tự tạo. Xử lý: dựng lại
  nhánh sạch `claude/da-model-da-nha-cung-cap` từ `main` (một commit, cùng nội dung), mở PR #128,
  merge bằng đó. Bài học: **không hard-code giả định "trên nhánh mình tạo thì amend/force-push
  luôn được phép"** — luôn kiểm `.claude/settings.json` (deny thắng allow) trước khi thử.
- Giai đoạn trước đó: GĐ 8. **Mốc (2026-09-15, PR #126 đã merge): CỔNG CC CHO SHELL** — nửa còn lại của cổng CC.
  `scripts/check-shell-complexity.sh` đo bằng `vendor/shellmetrics` (bản vendor có ghim SHA256,
  chạy offline), **hai trần**: hàm ≤ 12 như Python, thân script `<main>` ≤ 45 — trần thứ hai đặt
  ngay trên mức cao nhất đo được (41) làm **nắp chặn trượt**, vì ép thân một script cổng xuống 12
  chỉ đẩy nhánh vào hàm một-lần-gọi chứ không dễ đọc hơn (người dùng chốt phương án này). Hạ CC
  2 hàm vượt trần, hành vi giữ nguyên có đối chiếu fixture: `dev-task.sh::detected_cmd` 18 → tách
  5 hàm theo hệ sinh thái, `maintenance-sweep.sh::detect_deps_cmd` 13 → tách 4.
  Spec: `docs/specs/2026-09-15-cong-may-cc-shell.md`. Lượt CI đầu ĐỎ vì `func` là từ khoá của
  gawk (runner) chứ không phải mawk (máy dev) — sửa + `TRAPS.md` mục 23 + ca 6 của negative test
  chạy lại cổng dưới gawk.
- Giai đoạn trước đó: GĐ 8. **Mốc (2026-09-14, PR #123 đã merge): CỔNG MÁY
  cho ngưỡng CC 12** — trả lời trực tiếp phát hiện của mốc trước ("không có cổng máy nào cưỡng chế
  CC ≤ 12, ngưỡng chỉ nằm trong văn xuôi"). Thêm `scripts/check-python-complexity.sh` (radon, trần 12
  qua `PY_CC_MAX`, **không có miễn trừ theo hàm**) + `scripts/test-check-python-complexity.sh`
  (negative test: hàm CC 13 phải làm cổng ĐỎ · nâng trần trên đúng file đó phải làm nó XANH · thiếu
  `radon` phải ĐỎ chứ không skip) + bước mới trong job `framework-lint`. Dấu `DEBT:` duy nhất của repo
  **được trả đúng điều kiện xem lại của chính nó**: `format_markdown_report` 13 → 9 bằng cách tách
  `_optional_report_blocks` (báo cáo sinh ra không đổi cấu trúc — chỉ khác các con số đếm dòng của
  chính repo). Spec: `docs/specs/2026-09-14-cong-may-cc-12.md`. Repo còn 0 dấu `DEBT:`.
- Giai đoạn trước đó: GĐ 8. PR #69→#121 đã merge (#120 = phần còn lại của audit tối ưu; #121 = `TRAPS.md`
  mục 22 + đồng bộ `PROGRESS.md`).
  **Mốc nội dung gần nhất (2026-09-14, nhánh
  `claude/cool-gauss-4dk9ln`): phần CÒN LẠI của lượt `/audit-optimize`** mà PR #118 cố ý hoãn ở mục
  "Reviewer focus #2". Tách `_scripts_inventory` 15→5 và `subagent-dispatch::main` 12→4; hàm thứ ba
  `format_markdown_report` (13) **giữ nguyên có lý do đo được** + dấu `DEBT:` có trần và điều kiện
  xem lại — dấu `DEBT:` THẬT đầu tiên của repo, và cổng đếm ở `maintenance-sweep.sh` mảng 3 (PR #115)
  đã chứng minh giá trị ngay: nó bắt bản viết 3 dòng vì bộ dò đi theo dòng. Đính chính PR #118: nó ghi
  "bốn hàm vượt ngưỡng" nhưng đo thật chỉ có ba (`spec-compiler::main` là 11). Và **không có cổng máy
  nào cưỡng chế CC ≤ 12** trong repo — ngưỡng chỉ nằm trong văn xuôi, nên đây là phán đoán chứ không
  phải bịt cổng đỏ. `TRAPS.md` mục 20 + 21 (hai khuôn xanh-giả/đo-sai mắc thật trong phiên, mục 20 bắt
  được TRƯỚC khi commit). 14/14 cổng khung xanh, coverage 96%.
- **Mốc PR #118 (2026-09-14):**
  chạy `/audit-optimize` lên CHÍNH repo khung. GĐ 1 đo baseline: 0 dead code, 0 dependency thừa
  (4 engine Python chỉ stdlib), 15/15 GitHub Actions ghim SHA, jscpd 0,52% trùng lặp — repo đã
  tối ưu sẵn. GĐ 2 làm 3 việc: `scripts/_python-exec.sh` gộp boilerplate 4 wrapper (77→44 dòng) ·
  `scripts/_test-lib.sh` gộp `ok`/`bad`/`fails` của 8 script test · hạ complexity
  `scan_codebase_health` 18→1 và `parse_spec_markdown` 18→3 kèm 23 ca characterization
  (`scripts/test-engine-characterization.sh`, đã nối vào `ci.yml`).
- **Bài học PR #118 (quan trọng hơn chính bản refactor):** (a) ước tính "net −91 dòng" của báo cáo
  audit SAI — thực tế +366 dòng; với repo đã tối ưu sẵn, *giảm dòng là chỉ số sai* để duyệt kế hoạch
  tối ưu, giá trị thật nằm ở CC và ở test khoá hành vi. (b) Rút helper dùng chung làm đỏ MỌI nơi
  liệt kê file bằng tay — tái phát HAI lần trong cùng một PR (2 test sandbox, rồi
  `copy-framework.sh`/`.ps1` khiến dự án đích nhận script gãy); ghi thành `TRAPS.md` mục 19.
  (c) Nghiệm thu bằng "cổng LIÊN QUAN xanh" thay vì TOÀN BỘ test (`CLAUDE.md` §6) đã để lọt một
  hồi quy lên `origin` — xanh giả nguy hiểm hơn đỏ.
- **Mốc trước (2026-09-14, PR #115):** đối chiếu nguồn ngoài `ponytail` →
  ba luật: thang kiểm trước khi viết code `CLAUDE.md` §3 A4 · dấu nợ `DEBT:` có điều kiện xem lại
  §3 A7 **kèm cổng thật** ở `maintenance-sweep.sh` mảng 3 + negative/positive test · nhóm 5 "tự viết
  lại thứ đã có" cho `/audit-optimize`. Bản đối chiếu ba cột:
  `docs/reports/2026-09-14-doi-chieu-ponytail.md` — 3/~14 hạng mục được lấy; ba mâu thuẫn luật của
  nguồn được nêu ra và từ chối. Phát hiện tự đính chính giữ nguyên trong báo cáo: đọc README suýt
  làm lỡ đúng hạng mục có bằng chứng sự cố mạnh nhất.
- **Mốc PR #114: ADR-0005 — TDD mặc định bắt buộc cho code MỚI có logic** (nhánh điều kiện / tính
  toán / xử lý lỗi-quyền), kèm **danh sách ngoại lệ ĐÓNG** 5 mục (scaffolding từ template · đổi
  tên-di chuyển cơ học · chỉ tài liệu-comment-config thuần · code sinh tự động · prototype vứt đi có
  timebox); mỗi lần dùng ngoại lệ phải ghi một dòng trong PR. **Không** chép bản cứng tuyệt đối của
  `Claude-Agents` — nó mâu thuẫn với lý luận "nghi thức rỗng" đã có trong khung (lý luận đó đúng),
  khung phục vụ 10 hồ sơ chứ không phải một repo Python, và bản cứng đó đi kèm `fail_under = 100` mà
  chép nửa vời thì mất một nửa cơ chế. Điểm chạm quy trình: `CLAUDE.md` §5/§7 + `/gate` Bước 3 có
  mục `Đỏ-trước cho code mới có logic ✅/❌/ngoại lệ-N`. **Không có cổng máy** — "test này từng đỏ"
  không đọc được từ trạng thái cuối của repo; cưỡng chế bằng review (ADR §Hệ quả).
- Mốc trước (PR #113): **CP-5 — sổ job được
  phép skip.** Job `gate` tính mọi `skipped` là đạt (cần thế, vì `progress-freshness` cố ý chỉ chạy
  trên push vào nhánh chính), nên một job bị `if:` viết hỏng loại ra sẽ không chạy mà vẫn qua cổng —
  cổng xanh giả, cùng họ CP-4 nhưng vào cửa khác. Sửa hai lớp: `ci.yml` có sổ `SKIP_ALLOWED` tường
  minh (dùng `toJSON(needs)` vì `join(needs.*.result)` mất TÊN job), và `check-ci-policy.sh` CP-5 so
  sổ **bằng đúng** tập job có `if:`, hai chiều. Logic `gate` đã chạy thử ngoài CI trên 4 trạng thái
  trước khi push, vì chiều "để lọt" thì CI không nói hộ được.
- Mốc trước (PR #112): sửa hàng rào **Mốc gần nhất (2026-09-14, PR #112): sửa hàng rào
  `block-dangerous-git.sh` chặn oan vì DỮ LIỆU trong lệnh** — hook quét cả chuỗi lệnh nên commit
  message chứa chữ "main" (trong thân heredoc) làm nó tưởng đang force-push nhánh chính; thân
  `python3 - <<PY` chứa `git reset --hard` làm fixture cũng bị chặn. Bản vá đầu TỰ TẠO một lỗ hổng
  (nhận `<<` có khoảng trắng thành heredoc → nuốt mọi dòng sau → `git reset --hard` ở dòng kế KHÔNG
  bị chặn); vòng hai sửa bằng cách cấm khoảng trắng sau `<<`. `TRAPS.md` mục 18 (khuôn mới: bộ dò tự
  khớp văn bản của chính thứ nó soi) + mục 14 (tái phát: commit rơi nhầm vào nhánh chính, lần này do
  chính bug hook chặn mất lệnh ghép nên KHÔNG có output lỗi git nào để đọc). `test-hooks-gate` 15/15.
  Trước đó PR #109 (ba luật từ đợt đối chiếu Claude-Agents), #110 (sync PROGRESS).
- Giai đoạn (mốc cũ): PR #69→#109 đã merge. **Mốc gần nhất (2026-09-14, PR #109): ba luật rút từ đợt đối
  chiếu với `seeker19110/Claude-Agents`** — (1) `CLAUDE.md` §11 + `docs/framework/adopt-from-outside.md`:
  phương pháp ba cột khi học từ repo/khung/skill NGOÀI (*đã có và sâu hơn* / *đã có nhưng nông hơn* / *chưa
  có*), cổng "chưa có phải ứng với SỰ CỐ THẬT", và luật cốt lõi **grep CỔNG ĐANG CHẠY đừng đọc văn xuôi**;
  (2) `CLAUDE.md` §4 "không tin lời khai" — năm bước trước khi nói xong/pass (§7 đã có khuôn báo cáo nhưng
  chưa có luật sinh ra nó); (3) `quality-supplements-group2.md` — sổ trần cho bốn lối thoát khỏi cổng
  coverage, so **bằng đúng** (bớt cũng đỏ), kèm bẫy "bộ đếm tự khớp chính nó" + luật đo nhánh chứ không chỉ
  đo dòng. Nguồn sự cố cho (1) và (2) là chính phiên 2026-09-14: hai lần liên tiếp đề xuất "bổ sung" một
  thứ mà repo đích ĐÃ CÓ cổng thật đang chạy (Claude-Agents PR #295, #297), và một lần tính phép đo là "đã
  chứng minh" trong khi lệnh đã chết trước khi chạy tới phần cần đo. 8/8 cổng PR xanh.
- Trước đó: PR #108 (bỏ qua `__pycache__` trong `.gitignore`), PR #86 (làm rõ nhãn C1 "MẶC ĐỊNH" để
  không thiên lệch web cho dự án không phải web). Mốc PR #106: thêm **agent bảo trì
  toàn diện** — subagent `maintainer` + lệnh `/maintain` (quét → triage → `docs/ops/MAINTENANCE-PLAN.md`
  dừng chờ duyệt → PR nhỏ qua `/gate` → hội tụ), engine `scripts/maintenance-sweep.sh` (6 mảng mục
  nát theo thời gian: git/dependency/tài liệu/bí mật/CI/cổng khung), `scripts/maintain-run.sh` (chạy
  agent qua CLI subscription cục bộ mọi nhà cung cấp — Claude Code/Hermes/Gemini qua Antigravity/
  Codex/OpenCode, không API key), `scripts/maintain-cron.sh` (wrapper không giám sát cho VPS/cron,
  `--force-with-lease` chỉ cho nhánh riêng `maint/auto-<ngày>`, tự mở PR báo cáo qua GitHub REST API
  khi có `GITHUB_TOKEN`), workflow tuần `maintenance.yml`. Bốn self-test mới, nối vào `framework-lint`
  + smoke dự án đích. Xem `TRAPS.md` mục 16–17 (hai lỗi thật bắt được khi viết test cho
  `maintain-cron.sh`: push same-day rerun chỉ thành công nhờ trùng giây; biến gán trong hàm chạy qua
  subshell). 9/9 cổng PR xanh, radar 100/100.
- **Lưu ý khuôn lỗi (PR #82):** auto-merge (squash) có thể merge PR ngay khi CI của commit ĐẦU
  TIÊN xanh — một commit push SAU khi đã bật auto-merge (vd cập nhật PROGRESS.md cùng PR) có thể
  KHÔNG kịp vào trước khi merge xảy ra, dù mới push xong. Xác nhận lại bằng `git log origin/main`/
  `git show <sha> --stat` trước khi tin PROGRESS.md trong PR đã vào `main`; nếu thiếu, mở PR sync
  riêng — không coi im lặng là "đã vào". **Tái diễn ở PR #106:** PR #106 không kèm cập nhật
  `PROGRESS.md` trong cùng PR (bỏ sót bước 0 của CLAUDE.md §8) — sửa bằng PR sync này ngay sau khi
  merge, đúng theo chính lưu ý này. **Tái diễn lần thứ ba ở PR #109** — cùng một bỏ sót (PR không kèm
  `PROGRESS.md`), dù lưu ý này nằm ngay trong file bị bỏ sót. Ba lần liên tiếp nghĩa là nhắc bằng văn xuôi
  không đủ: job `progress-freshness` chỉ chạy trên push vào `main` (đúng thiết kế — kiểm lúc PR còn mở sẽ
  báo oan) nên nó KHÔNG chặn được PR quên bước 0, chỉ cảnh báo sau khi đã merge. Cân nhắc một cổng ở
  `pr-policy.yml` soi diff của PR thay đổi tài liệu khung mà không chạm `PROGRESS.md` — chưa làm, cần bàn
  vì dễ báo oan cho PR nhỏ.
- Default-branch SHA đã đối chiếu: `ba90090` (`origin/main`, PR #151)
- Nhánh đang làm: `main` (không có việc dở)
- Ngày cập nhật: 2026-09-19

## Goal đang active

| Goal | Outcome | State | Current gap | Next slice | Link |
| --- | --- | --- | --- | --- | --- |
| Gói A+B+C: TRAPS + CODEMAP + cổng CI | 4 PR merge; TRAPS/CODEMAP thật + cổng `check-ci-policy.sh` chạy trong CI | ✅ ĐÓNG (2026-09-12, PR #62) | — | Không còn goal mở | `docs/specs/2026-09-12-traps-codemap-ci-policy.md` |
| Siết hàng rào (audit 2026-09-12) | 0 phát hiện Cao mở; luật có cơ chế thi hành | ✅ ĐÓNG (2026-09-13) | — | W-308 xong: người dùng đã tự xoá toàn bộ nhánh đã merge qua GitHub UI (`list_branches` xác nhận chỉ còn `main`) | `docs/ops/COMPLETION-PLAN.md` |
| Golden test + kỷ luật TDD | 3 PR merge; TDD lên cấp CLAUDE.md/gate, golden có luật cập nhật | ✅ ĐÓNG (2026-09-12, PR #62) | — | Không còn goal mở | `docs/specs/2026-09-12-golden-tests-and-tdd.md` |
| Hoàn thiện khung theo COMPLETION-PLAN | 0 phát hiện Cao mở; Vừa/Thấp có kết cục ghi nhận; đạt Definition of Complete | ✅ ĐÓNG (2026-09-01) | — | Không còn goal mở | `docs/ops/COMPLETION-PLAN.md` |

## Đã xong (tóm tắt)

- Dựng trọn bộ khung: quy trình 9 giai đoạn + cổng, luật AI (CLAUDE.md/AGENTS.md), research-first,
  slash commands (`/consult` `/gate` `/bootstrap` `/auto` `/audit-full` `/audit-optimize` `/incident`
  `/completion` `/grill` `/debug` `/ui-ux` `/adr`), điều phối 3 tầng + opusplan, `copy-framework.sh`/
  `.ps1` + smoke test, OpenSpec (tùy chọn).
- **(2026-09-12, ADR-0004) Gỡ hẳn scaffold Web mặc định** — repo khung giờ chỉ còn Lớp 1 (phương
  pháp) + Lớp 2 (CI/quy ước GitHub tổng quát). Xem "Quyết định quan trọng" bên dưới.
- Hàng rào tự kiểm cho chính khung: CI `framework-lint` / `docs-consistency`
  (`scripts/check-docs-consistency.sh`) / `copy-framework-smoke`; case-study greenfield (lịch sử,
  chạy khi repo còn scaffold — xem `case-study-greenfield-dry-run.md`).
- Tái cấu trúc tên file sang tiếng Anh (nội dung tiếng Việt), bản đồ tên cũ→mới ở `docs/framework/README.md`.
- **(2026-09-12) PR #68 — tổng quát hoá harness cho mọi AI coding model/provider**: AGENTS.md
  thành entrypoint chung có hàng rào an toàn thủ công cho agent không có hook Claude Code;
  `.mcp.json.example` + `.claude/settings.local.json.example`; bridge file GEMINI.md/.clinerules/
  .windsurfrules/Cursor/Copilot trỏ về AGENTS.md; thêm subagent `tester` + `security-reviewer`.
- **(2026-09-12) PR #69 — cổng chống PROGRESS.md lỗi thời + chia đơn vị PR/trần effort medium/
  auto-merge**: `scripts/check-progress-freshness.sh` + job CI `progress-freshness`; quy trình mới
  sau bước duyệt kế hoạch cho việc đủ lớn cần điều phối 3 tầng — xem `TRAPS.md` mục 8.
- PR đã merge gần nhất: **#114** (ADR-0005 TDD), **#113** (CP-5 sổ job skip), **#112** (sửa hook chặn oan + TRAPS 18/14), **#111** (đóng, thay bằng #112), **#110** (sync PROGRESS), **#109** (ba luật từ đợt đối chiếu Claude-Agents), **#86** (nhãn C1), **#108** (`.gitignore` `__pycache__`), **#106** (agent bảo trì toàn diện — `maintainer`/`/maintain`/`maintenance-sweep`/`maintain-run`/`maintain-cron`), **#105→#104** (PROGRESS sync + fix telemetry/smoke, xem mục "Giai đoạn hiện tại" ở trên), **#69** (freshness gate + PR-splitting/effort/auto-merge), **#68** (tổng quát hoá harness), **#67** (ADR-0004 gỡ scaffold Web), **#66**
  (đóng Nhóm 11 audit), **#62** (TRAPS.md + CODEMAP.md + `check-ci-policy.sh` + golden test/TDD —
  2 spec `docs/specs/2026-09-12-*.md`, 7 PR gộp thành 1, rút từ lượt quét 15 repo dẫn xuất/lân cận),
  **#61** (verify-dropins ERESOLVE), **#52** (hoàn thiện khung theo COMPLETION-PLAN, 4 đợt/22 việc
  W-101→W-406, Pha 4 re-audit hội tụ + nghiệm thu Definition of Complete PASS), **#46** (parallel
  subagent workflow), **#45** (governance & supply-chain), **#44** (hợp nhất chuẩn —
  standard-delivery). Mốc cũ hơn (#19–#32…): xem lịch sử Git của file này + CHANGELOG.

## Đang làm / chờ

- **Không có việc dở.** PR #130 (ADR-0007 — bỏ opusplan mặc định) đã merge — xem mục "Giai đoạn
  hiện tại" ở trên.
- PR #106 (agent bảo trì toàn diện) đã merge — xem mục "Giai đoạn hiện tại"
  ở trên. Dùng thử: `/maintain` (Claude Code), `scripts/maintain-run.sh` (CLI khác), hoặc chờ
  workflow tuần `maintenance.yml` mở issue báo cáo.
- PR #93 (hậu kiểm audit 2026-09-13) đã merge: nối `test-next-gen-engines.sh`
  + `test-telemetry-and-dispatch.sh` vào job `framework-lint`, thêm mục 6 cho
  `check-docs-consistency.sh` (script ↔ `CODEMAP.md`) kèm negative-test hai chiều, tách bảng giá ra
  `scripts/model-rates.json`, đổi default harness về `claude`/`anthropic`. Xem `TRAPS.md` mục 11–12.
- Audit toàn diện 2026-09-12 (12/12 nhóm, G-001..G-004) đã đóng hết qua PR
  #71→#75. Nhánh remote đã dọn sạch (2026-09-13). Người dùng đã import `.github/rulesets/main.json`
  trên GitHub — `protection-guard` xanh thật, đã thêm vào `needs:` của `gate` (nhánh hiện tại), xoá
  khỏi `CP4_BOOTSTRAP_EXEMPT`. Vòng "mượn cơ chế branch-protection từ Claude-Agents" đã khép kín.

## Tiếp theo

- **Ngay lập tức:** không có việc dở. A-01→A-04 đã đóng; độ phủ cổng CI đạt **100%** (18/18
  script) và điểm radar **100/100** — cả hai đều có đối chứng động chứng minh là phép đo thật,
  không phải hằng số in ra.
- Cả 4 phát hiện Trung của audit toàn diện 2026-09-12 đã đóng: G-001 (PR #72), G-002 (dọn trong PR
  #73), G-003 + G-004 (PR #75).
- Có thể làm khi được yêu cầu: bắt đầu dự án đích mới bằng khung này (`/consult` hoặc `/auto`), tiếp
  tục quét thêm repo dẫn xuất khác (gói D–I của lượt quét 2026-09-12: script `check-*` của `xboss`,
  hook `block-dangerous-git.sh`, gitleaks pre-commit, gate-agent `sc-gate-*`, `eval-record.yml`),
  hoặc audit định kỳ khác (`/audit-full`).

## Quyết định quan trọng

- **(ĐẢO NGƯỢC MỘT PHẦN 2026-09-15, ADR-0007) `opusplan` không còn là mặc định** — CLI đã ngừng hỗ
  trợ `/model opusplan`. Chính sách cũ "opusplan là điểm ngọt" (ADR-0006 mục 2) thay bằng hai pha
  làm thủ công: `/model` sang model cao cấp nhất sẵn có để lập kế hoạch, tự `/model claude-sonnet-5`
  quay lại thực thi. Tối ưu token vẫn bằng CHIA VIỆC (subagent, cô lập ngữ cảnh) — không đổi. Chi
  tiết: `docs/framework/models-and-automation.md`, `docs/adr/0007-bo-opusplan-mac-dinh.md`.
- **(ĐẢO NGƯỢC 2026-09-12, ADR-0004) KHÔNG còn scaffold Web mặc định.** Quyết định cũ "giữ scaffold
  Web (Next.js+Supabase) làm hồ sơ mặc định" đã bị đảo ngược theo yêu cầu người dùng — gỡ hẳn khỏi
  repo khung để nhất quán với nguyên tắc "hỗ trợ mọi loại dự án, research-first" (không sửa ADR-0001
  — ghi ADR mới). Repo khung giờ chỉ còn Lớp 1 (phương pháp) + Lớp 2 (CI/quy ước GitHub tổng quát,
  không đặc thù stack).
- Copy-framework KHÔNG đè file có sẵn ở dự án đích (`copy_if_absent`); Lớp 2 (CI/GitHub) vào `_framework-dropins/`.
- ADR: `docs/adr/` (vd `0001-stack-selection.md`, `0004-remove-default-web-scaffold.md`).

## Rủi ro, blocker và nợ kỹ thuật

| Mục | Severity | Owner | Trigger/next action | Link |
| --- | --- | --- | --- | --- |
| ~~B-01 Feature gate né được qua tiêu đề COMMIT~~ | — | — | ✅ ĐÃ SỬA — `pr-policy.yml` nay soi CẢ tiêu đề PR LẪN tiêu đề từng commit; mọi commit phải conventional. Vẫn NÊN bật thêm Settings → 'Default to PR title for squash merge commits' (rẻ hơn, chặn ở tầng nền tảng). Cũ: `pr-policy.yml` kiểm `pr.title`, nhưng squash merge dùng tiêu đề **COMMIT** khi PR chỉ có **một** commit → `main` nhận được commit `feat:` chưa từng qua Feature gate. Xảy ra THẬT ở PR #99 (`76fc65e feat(test): ...` dù tiêu đề PR đã đổi thành `test:`). Sửa: bật "Default to PR title" cho squash trong Settings, HOẶC thêm cổng đối chiếu tiền tố tiêu đề commit ↔ tiêu đề PR | audit 2026-09-13 (lượt 2) |
| ~~B-02 `CLAUDE.md` ↔ `AGENTS.md` không có cổng đối chiếu~~ | — | — | ✅ ĐÃ SỬA — `AGENTS.md` kê đủ 4 engine + mục 7 mới trong `check-docs-consistency.sh` đối chiếu danh sách engine hai file, có negative-test hai chiều. Cũ: `CLAUDE.md` §1 khai 4 engine; `AGENTS.md` chỉ kê 2 (`subagent-dispatch`, `telemetry-log`) — thiếu `spec-compiler` và `arch-health-radar`. `CLAUDE.md` §1 bắt "sửa luật ở đây thì soát lại AGENTS.md" nhưng **không cổng máy nào kiểm**, nên lệch âm thầm | audit 2026-09-13 (lượt 2) |
| ~~B-03 CI chạy shellcheck mức `error`, luật ghi "0 cảnh báo"~~ | — | — | ✅ ĐÃ SỬA — CI nay chạy `shellcheck --severity=warning` đúng luật §5; sửa 1 ca SC2164 và khai directive KÈM LÝ DO cho 3 ca SC1090 + file `.example`. Cũ: `CLAUDE.md` §5 ghi "Lint 0 cảnh báo" nhưng `ci.yml` dùng `--severity=error`. Mức `warning` hiện có 6 phát hiện (4×SC1090 sourcing động — chấp nhận được; 2×SC2164 `cd` không `|| exit` ở `test-copy-framework.sh:10` và một chỗ nữa). Sửa: nâng CI lên `--severity=warning` + sửa 2 ca SC2164, HOẶC sửa luật §5 cho khớp thực tế | audit 2026-09-13 (lượt 2) |
| ~~A-01 `spec-compiler.py` sinh assertion RỖNG~~ | — | — | ✅ ĐÃ SỬA — sinh 3 hợp đồng kiểm được thật (C-1 State, C-2 mã yêu cầu, C-3 đường dẫn touchpoints tồn tại), có negative-test hai chiều. Cũ: 82/82 test sinh ra đều là `assertTrue(len([]) >= 0)` — hằng đúng, không thể đỏ; lại nằm trong `.gitignore` và không job CI nào chạy. Tệ hơn không có vì tạo cảm giác an toàn giả. Sửa: parse `**FR-n**`/`AC-n` thành assertion thật + đưa vào CI, HOẶC gỡ hẳn engine | audit 2026-09-13 |
| ~~A-02 `arch-health-radar.py` không đo kiến trúc~~ | — | — | ✅ ĐÃ SỬA — 5 tín hiệu có trọng số, in công thức, tách `.md` khỏi phép đếm code; điểm 100/100 đạt bằng việc thật. Cũ: Điểm chỉ gồm hai thành phần: trừ 5 cho mỗi file >400 dòng (tối đa 20), trừ 10 nếu tỷ lệ dòng mở đầu bằng dấu thăng < 5%. Không có coupling/complexity/coverage. Còn đếm văn xuôi Markdown là "code" → báo 84% code cho repo 67% là `.md`. Sửa: bỏ `.md` khỏi phép đếm code + đổi tên chỉ số cho đúng cái nó đo | audit 2026-09-13 |
| ~~A-03 `--harness claude` xuất lệnh không tồn tại~~ | — | — | ✅ ĐÃ SỬA — nêu đúng tool Task + `subagent_type`; test cũ vốn khoá chặt chính lỗi này cũng đã sửa. Cũ: Sinh ra `/subagent <tên> <task>`, nhưng `.claude/commands/` không có `subagent.md` — dán vào Claude Code sẽ không chạy. Docstring còn kê Cursor/Windsurf/Gemini trong khi `choices` chỉ có 4. Sửa hoặc bỏ lựa chọn đó | audit 2026-09-13 |
| ~~A-04 chưa có hướng dẫn `user.email` cho phiên AI~~ | — | — | ✅ ĐÃ SỬA — mục 4b `new-project-runbook.md` + `TRAPS.md` mục 13. Cũ: `require_extra_approval_for_unattributed_changes` trong ruleset chặn MỌI PR do AI tạo nếu commit không gắn được vào tài khoản GitHub (đã xảy ra ở PR #93). Sửa: ghi cách cấu hình author/committer vào `new-project-runbook.md` + mục `TRAPS.md` | `.github/rulesets/main.json` |
| F-011 `--theme-transition` dead token | Thấp | AI | **Chấp nhận rủi ro (xác nhận 2026-09-01)** — không sửa | `docs/ops/COMPLETION-PLAN.md` |
| F-014 usage-guard số thập phân | Thấp | AI | **Chấp nhận rủi ro (xác nhận 2026-09-01)** — không sửa | `docs/ops/COMPLETION-PLAN.md` |
| F-309 `dev-task.sh` fallback grep | Thấp | AI | **Chấp nhận rủi ro (xác nhận 2026-09-01)** — không sửa | `docs/ops/COMPLETION-PLAN.md` |
| ~~5 PR dependabot chưa merge~~ | — | — | ➖ Lỗi thời (G-002, audit 2026-09-12) — #53→#57 đã merge từ trước, `list_pull_requests(state=open)` xác nhận 0 PR đang mở | `docs/ops/COMPLETION-PLAN.md` W-101 |
| **C-01 Khung chưa từng dùng trọn vẹn cho một dự án thật** | **Cao** | Người dùng | ~100 PR tự hoàn thiện, chưa lần nào đi hết `/consult`→`/bootstrap`→ra sản phẩm. Bug #104 (telemetry chết ở mọi dự án đích, sống qua nhiều PR trong khi CI xanh 100%) tìm ra chỉ bằng cách copy khung vào thư mục trống rồi chạy thử — tỷ lệ phát hiện mà audit nội bộ không đạt được. Đề xuất: làm một dự án nhỏ có thật (CLI, hoặc API 3 endpoint) | đánh giá tổng thể 2026-09-14 |
| **C-02 Hàng rào lệch về phía repo khung** | Vừa | AI | 6/10 cổng CHỈ phục vụ repo khung; dự án đích chỉ nhận 3 self-test. `dev-task.sh`, `usage-estimate.sh`, `.claude/hooks/` được phát đi nhưng CHƯA từng chạy thật ở dự án đích — cùng loại rủi ro đã gây ra #104, chưa phủ | `TRAPS.md` mục 15 |
| **C-03 Bề mặt đã tới hạn** | Thấp | Người dùng | 12 lệnh · 10 subagent · 10 cổng · 4 engine · 98 file tài liệu (8.6k dòng) · 13 file `CLAUDE.md` §1 bảo phải đọc. Đề xuất ĐÓNG BĂNG: chỉ thêm khi có nhu cầu gặp thật ở C-01 | đánh giá tổng thể 2026-09-14 |
| Case-study Bước 6–8 (branch protection/Supabase/Vercel) chưa kiểm chứng | Thấp | Người dùng | Kiểm khi áp khung vào dự án thật có tài khoản | `docs/framework/case-study-greenfield-dry-run.md` |
| ~~31 nhánh đã merge còn tồn trên remote (F-014)~~ | — | — | ✅ Đã xoá 2026-09-13 (người dùng, qua GitHub UI) — `list_branches` xác nhận chỉ còn `main` | `docs/ops/COMPLETION-PLAN.md` W-308 |
| ~~Ruleset `.github/rulesets/main.json` chưa import trên GitHub~~ | — | — | ✅ Đã import (xác nhận lại 2026-09-15: log job `protection-guard` live trên PR #131 in "OK — main đang được bảo vệ, và mọi required status check khai trong file đều đã bắt buộc"). `protection-guard` đã nằm trong `needs:` của `gate`, `CP4_BOOTSTRAP_EXEMPT` rỗng — dòng này lẽ ra phải gạch từ mốc PR #75 (mục "Đang làm / chờ" ở trên) nhưng bị bỏ sót, nay sửa cho khớp | `docs/ops/repository-settings.md` |
| ~~G-003 (`orchestration-3-tier.md` dòng sơ đồ ASCII còn "Opus·high")~~ | — | — | ✅ Đã sửa — nhánh `fix/g003-g004-stale-effort-label` | `docs/ops/COMPREHENSIVE-AUDIT-STATUS.md` |
| ~~G-004 (effort/model lặp 6 file, không cổng đối chiếu)~~ | — | — | ✅ Đã sửa — mục 5 mới trong `check-docs-consistency.sh` (cấm "Opus · high" sống lại) + negative-test trong `test-check-scripts.sh` | `docs/ops/COMPREHENSIVE-AUDIT-STATUS.md` |
| ~~W-303 test RLS~~ | — | — | ➖ Hết hiệu lực (ADR-0004) — dropins Supabase đã gỡ, không còn gì để test | `docs/ops/COMPLETION-PLAN.md` W-303 |
| ~~PROGRESS.md lỗi thời (nhánh đã merge #67 nhưng vẫn ghi "chưa mở PR")~~ | Vừa | AI | ✅ Đã sửa 2026-09-12 — thêm `scripts/check-progress-freshness.sh` + job CI `progress-freshness` chặn merge nếu tái phạm; xem `TRAPS.md` | `CLAUDE.md` §8, `CODEMAP.md` |

## Bàn giao phiên

- Lần cập nhật: 2026-09-19
- State: DONE, không có việc dở. PR #144 (đối chiếu 6 nguồn ngoài + khuôn severity `ui-ux.md`) đã
  merge vào `main`.
- Việc đã xong và bằng chứng: `docs/reports/2026-09-19-doi-chieu-6-nguon-ngoai.md` (bản đối chiếu
  ba cột đầy đủ); `.claude/commands/ui-ux.md` (mục mới "Khuôn báo cáo khi REVIEW một UI có sẵn").
  CI đỏ một lần trên job `metadata` (PR body thiếu mục `## Research / Spec`) — sửa body PR qua
  `update_pull_request`, chạy lại xanh, merge squash; `subscribe_pr_activity` tự huỷ đăng ký khi
  PR đóng (đúng thiết kế).
- Việc CHƯA xong + lý do: không có.
- Bước tiếp theo: chờ yêu cầu người dùng. Hạng mục `open-code-review` (rule-matching tất định)
  vẫn "chưa cần" — điều kiện xem lại đã ghi trong báo cáo.
- Quyền/quyết định cần thêm: không có.
