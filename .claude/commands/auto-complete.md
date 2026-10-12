---
description: Lệnh tự động DUY NHẤT (gộp lệnh lập-kế-hoạch-tự-chạy và lệnh hoàn-thiện cũ, 2026-10-12) — làm tới xong, tự quyết thay người dùng: research → kế hoạch toàn bộ → thực thi theo số PR → hoàn thiện (audit → hội tụ → Definition of Complete) → bàn giao, trong một lượt; mọi cổng phê duyệt do phiên chính tự duyệt theo thứ tự ưu tiên §3d (đúng+bảo mật+không mất dữ liệu › ít hơn › kiểm được › nhanh), ghi từng quyết định; chỉ dừng ở §9 / BLOCKED. Dùng khi mô tả dự án MỚI, bắt đầu trên dự án CÓ SẴN, hoặc muốn hoàn thiện dự án.
allowed-tools: Bash(bash scripts/loop-state.sh:*)
---

## Trạng thái vòng lặp (máy đo — `scripts/loop-state.sh`, ADR-0012)
Khối dưới do engine tính từ artifact thật (git, PR/CI, hồ sơ §3e, goal, `COMPLETION-PLAN.md`, `release-readiness.md`, streak đỏ, marker) — KHÔNG tự suy "đang ở đâu"; đọc `verdict` + `next` rồi làm đúng bước đó. Harness không hỗ trợ cú pháp `!` → tự chạy `bash scripts/loop-state.sh --enter --brief` trước khi làm.
!`bash scripts/loop-state.sh --enter --brief 2>&1`

> 💡 Model/effort: theo `docs/framework/models-and-automation.md` §3–§4 và ADR-0010 §4. Repo mặc định **Sonnet 5**
> (`.claude/settings.json`); `/model opusplan` đã ngừng (ADR-0007). **Đổi model khi độ khó thật đòi hỏi** (vd quyết định
> kiến trúc mức L), không phải nghi thức đầu mỗi việc; đổi xong quay lại mặc định khi thực thi. Tra cứu/xác minh phiên
> bản giao subagent Haiku (`lookup`, `version-check`).

Bạn là **người quyết định thay chủ repo** cho toàn bộ lượt này. Luật nguồn: `docs/framework/standard-delivery.md` §3d
(ủy quyền + **thứ tự ưu tiên khi xung đột**), §3c (mức S/M/L, chia việc) và §8 (stop conditions). Playbook hoàn thiện:
`docs/framework/project-completion.md` (Pha 0–4). Lệnh này là điểm vào tự động duy nhất của khung.

## Điểm vào (chọn theo ngữ cảnh, ghi một dòng quyết định vào `working.md`)
- **Mô tả dự án/tính năng MỚI** hoặc **bắt đầu trên repo CÓ SẴN** → chạy từ **Giai đoạn A**.
- **Chỉ muốn hoàn thiện** dự án đã phát triển (không có việc mới) → bỏ A (ghi lý do), vào thẳng **Giai đoạn B**.
- Repo là khung/template trống mà chỉ đòi hoàn thiện → không có gì để hoàn thiện (chống ảo giác, `CLAUDE.md` §4): chạy A
  nhánh dự án mới (`/consult` → `/bootstrap`), hoặc dừng hỏi mục tiêu nếu chưa có ý tưởng (§9).
- Có hồ sơ `docs/work/<id>/working.md` đang mở hoặc `docs/ops/COMPLETION-PLAN.md` còn dở → **nối tiếp đúng chỗ dở**,
  không lập lại kế hoạch (kế hoạch đã duyệt vẫn hiệu lực); không hỏi `AskUserQuestion`.

## Chuỗi chạy (không bỏ bước, không hỏi giữa chừng ngoài §9)
0. **Bật vòng giữ lượt** (hook Stop `auto-complete-guard.sh`): sau khi đọc/tạo hồ sơ `docs/work/<id>/working.md` (§3e), bật marker
   bằng `bash scripts/loop-state.sh --enter` (ghi file `.claude/.auto-complete-loop`, gitignored, sống trong một phiên; `--enter` không reset `n`).
   **Mỗi vòng bắt đầu bằng `bash scripts/loop-state.sh --enter --brief` và làm đúng `next`.** Từ đó mỗi khi lượt
   định kết thúc mà hồ sơ còn `- Trạng thái: Active`, hook **không cho kết lượt** và nhắc mục "Bàn giao / bước tiếp theo" — nên
   **luôn giữ mục đó là bước cụ thể kế tiếp**. Hook tự cho dừng khi: `- Trạng thái: Blocked — …`/`Waiting — …` (§9/§8), hồ sơ đã
   rename `done.md`, usage-guard đã nhắc wind-down, đủ `AUTO_COMPLETE_MAX_CONTINUES` (mặc định 20) lượt, lời cuối lặp y hệt,
   2 lượt liên tiếp vân tay artifact không đổi (HEAD + working.md + PR mở + file dở), hoặc cổng commit đỏ ≥ 3 lần cùng failure (`.claude/.gate-red-streak` → ghi Blocked theo §8). Tín hiệu dừng là **file trạng
   thái**, không phải câu "đã xong" (CLAUDE.md §4). Kết thúc lượt (DoC có bằng chứng hoặc BLOCKED) → `rm -f .claude/.auto-complete-loop`.
   Tuỳ chọn thêm lớp: `/goal` của Claude Code với điều kiện đo được + "or stop after 20 turns".

| Verdict | Hành động |
| --- | --- |
| `continue` | Làm đúng `next` (một outcome = một PR): sửa CI PR · commit qua cổng · reconcile base · chọn slice ready · W-xxx kế · ghi Bàn giao |
| `refine-spec` | Quay về tầng ①/② (sửa spec/design) trước khi chạm code (§3b, streak lần 2) |
| `refine-code` | Sửa code có test đỏ-trước (streak lần 2, tầng ③/④) |
| `waiting` | Ghi `- Trạng thái: Waiting — chờ CI/merge PR #n` vào hồ sơ, kết lượt (hook cho dừng) |
| `request-input` | Ghi `- Trạng thái: Blocked — <lý do §8/§9>` + lựa chọn + đề xuất, kết lượt |
| `stop` | Hồ sơ đã `done.md`: `rm -f .claude/.auto-complete-loop`, báo cáo cuối |

### Giai đoạn A — Kế hoạch toàn bộ → thực thi
1. **Research thật** (không bịa):
   - **Dự án MỚI (repo chưa có code):** `/consult` + KHUNG-3 — phân loại loại dự án → chọn hồ sơ → **xác minh phiên bản bằng
     nguồn sống** (`version-check`) → đề xuất stack; bám 9 giai đoạn KHUNG-1. Rồi `/bootstrap` (`new-project-runbook.md`
     Bước 0→9) tới cổng **"Sẵn sàng phát triển"** (Phần C) — không mở PR tính năng khi cổng đó chưa đạt.
   - **Dự án CÓ SẴN:** `existing-project-adoption.md` — **đọc repo để biết stack thật** (`lookup`), KHÔNG áp stack mặc định;
     nâng cấp tăng dần.
   - **Chọn kiến trúc/công nghệ** (stack, lưu trữ, auth, hạ tầng): mỗi quyết định một ADR trong `docs/adr/` từ `0000-template.md`,
     ghi **≥ 2 phương án** kèm vì sao loại (cổng docs-consistency mục 16) — không hội tụ vào ý đầu tiên.
2. **Kế hoạch toàn bộ:** mục tiêu & phạm vi (DoR), giai đoạn/cột mốc, việc chia nhỏ kiểm tra được, rủi ro + cách giảm, tiêu chí
   chấp nhận + DoD, điểm §9, các cổng giữa giai đoạn. Độ dài tỉ lệ mức rủi ro (§3c): S/M vài dòng, L mới cần cột mốc + đơn vị PR.
3. **Chốt kế hoạch — tự duyệt**, ghi "Approved for implementation — phiên chính duyệt theo ủy quyền §3d" + ngày. Runner đang ở Plan
   Mode bắt buộc xác nhận thật qua ExitPlanMode → tôn trọng cổng đó và báo giới hạn, không tuyên bố đã có xác nhận. Chưa đủ
   research/spec/bằng chứng hoặc vượt quyền → chưa thực thi phần phụ thuộc.
4. **Thực thi tự động** theo kế hoạch, không hỏi lại từng bước:
   - Chọn S/M/L và số PR (§3c): một PR có thể tự làm, **từ 2 PR giao subagent** đủ năng lực, độc lập song song/phụ thuộc tuần tự;
     tối đa **5 subagent đang chạy toàn cây** (gồm coordinator/reviewer/tester/agent lồng); ba tầng tùy chọn
     (`orchestration-3-tier.md`). Brief theo `docs/framework/templates/PLAN.template.md`, qua `scripts/subagent-dispatch.sh --check-plan`
     (thoát 0) trước khi giao. Phiên chính giữ kế hoạch/quyết định khó, review, tích hợp và chạy đủ cổng.
   - Tự động chất lượng: auto-format khi sửa file + **cổng chặn `git commit` khi đỏ** (`.claude/hooks/`, qua `scripts/dev-task.sh`);
     dự án có lệnh riêng → điền `.claude/project-commands.sh` (copy từ `.example.sh`).
   - **Review tách người viết, trước MỖI PR:** `/review` trên diff (skill `code-review`; chạm auth/thanh toán/dữ liệu người dùng
     → thêm `security-review`), qua subagent `reviewer`/`security-reviewer` chứ không để chính phiên vừa viết tự chấm. Phát hiện
     mức chặn sửa trong cùng PR; còn lại ghi một dòng quyết định vào `working.md`.
   - **Loop → fix:** mỗi vòng một PR (FIFO/WIP 5/auto-merge theo `CLAUDE.md` §8); cổng commit đỏ cùng chữ ký lần 3 → ghi `Blocked`
     (§8), không sửa mù. Không nới cấu hình cổng (lint/type/test/coverage/rulesets) để xanh — các file đó ở `permissions.ask`,
     gặp lời hỏi là dấu hiệu đang đi sai hướng.
   - Checkpoint `working.md` mỗi mốc/trước nén; `PROGRESS.md` trỏ hồ sơ; conventional commits.

### Giai đoạn B — Hoàn thiện (audit → hội tụ → Definition of Complete)
Mọi PR của A **đã merge thật** (CI xanh, SHA trên `main`) → làm **đúng 5 pha** của `docs/framework/project-completion.md`
(Pha 0–4, tiêu chí thoát, Definition of Complete, 4 file trạng thái — nguồn sự thật, không chép lại ở đây):
- Trước Pha 0 (mượn Bước -1 của `/audit-full`): xác nhận là dự án cụ thể đã phát triển; khung/template trống → xem "Điểm vào".
- `docs/ops/COMPLETION-PLAN.md` đang mở → tóm tắt trạng thái rồi nối tiếp đúng chỗ dở; chưa có → chạy từ Pha 0.
- Không bỏ pha, không đảo. Cổng xác nhận ở Pha 0 và cổng "DỪNG trình kế hoạch + DoC" ở Pha 2: **tự duyệt** cùng cách bước A3,
  ghi vào `working.md`; chưa chốt kế hoạch thì chưa sửa.
- Thiếu `docs/framework/project-completion.md` (chưa áp khung) → báo người dùng chạy `copy-framework.sh`; không tự suy quy trình.

### Giai đoạn C — Bàn giao sản phẩm
Definition of Complete có bằng chứng (Pha 4) → **chạy được từ clone sạch**: clone mới vào thư mục tạm, làm đúng các bước trong
README (cài, `.env.example` → `.env` giá trị giả, build, khởi động) rồi **smoke thật** luồng chính (`CLAUDE.md` §6) — bước nào README
thiếu thì sửa README trong PR, không bàn giao khi người nhận không tự chạy được → điền `docs/ops/release-readiness.md` tới quyết định
**GO / NO-GO** kèm bằng chứng (đây là đề xuất; deploy/production vẫn thuộc danh sách "không bao giờ tự quyết" bên dưới) → rename
hồ sơ thành `done.md` với PR + merge SHA ở "Nghiệm thu cuối" (cổng docs-consistency mục 13b) → báo cáo cuối lượt. Hoặc dừng
`BLOCKED`/`WAITING` đúng §8.

## Wind-down ở ~70% giới hạn 5h + resume phiên sau
Claude Code **không** cấp % giới hạn 5h cho hook/agent, nên không có cổng máy đọc đúng "70%". Tín hiệu: Stop hook `usage-guard.sh`
(khi đã khai `.claude/usage-budget.sh`; mặc định ngưỡng 70%), cảnh báo `/usage`, hoặc phán đoán theo khối lượng. Khi chạm ngưỡng:
(1) **không bắt đầu** đơn vị mới cần commit/merge, hoàn tất gọn đơn vị đang dở; (2) **commit** phần đã xong qua cổng (không commit
code đỏ); (3) cập nhật mục "Bàn giao / bước tiếp theo" của `working.md` + `PROGRESS.md` (việc vừa xong, việc dở ở đâu, bước kế tiếp
cụ thể); (4) dừng sạch, báo "đã wind-down, phiên sau nhắn *tiếp tục*". Phiên sau: SessionStart hook `session-resume.sh` tự nạp
hồ sơ + PROGRESS + git state → nối tiếp đúng chỗ dở.

## Cách quyết định (áp cho MỌI lựa chọn trong lượt)
- Đi thang ưu tiên §3d từ trên xuống, dừng ở bậc đầu tiên phân thắng bại: **(1) đúng + bảo mật + không mất dữ liệu** (loại thẳng phương án hụt) → **(2) ít hơn** (code/nhánh/dependency/cấu hình/bảo trì, thang `CLAUDE.md` §3.4) → **(3) kiểm được** (bằng chứng máy rẻ, rõ) → **(4) nhanh/rẻ**.
- Mỗi quyết định ghi **một dòng** vào `docs/work/<id>/working.md` "Quyết định và bằng chứng": *chọn · loại · bậc phân thắng bại*. Người dùng đọc file này để audit sau, không bị hỏi trước.
- **Không bao giờ tự quyết** (dừng BLOCKED, nêu lựa chọn + đề xuất): xoá/đổi phá vỡ dữ liệu thật, thanh toán/chi phí mới, deploy/production, secret/quyền mới, thay đổi ngoài scope đã giao, cùng một failure quá 3 lần (§8). Quyền merge/deploy không suy ra từ quyền code.
- Mọi cổng máy giữ nguyên: TDD đỏ-trước, `/gate`, spec Approved cho `feat`, PR template, WIP 5/FIFO, auto-merge chỉ khi CI xanh. Chuyển giai đoạn: phiên chính nghiệm thu cổng và ghi căn cứ (`CLAUDE.md` §2).

## Báo cáo cuối lượt
Một khối ngắn: PR đã merge (số + SHA) · số quyết định tự duyệt (trỏ working.md) · ADR đã chốt · trạng thái Definition of Complete · kết quả smoke từ clone sạch + lệnh chạy sản phẩm · GO/NO-GO của `release-readiness.md` · BLOCKED còn lại (nếu có) kèm câu hỏi duy nhất cần người dùng trả lời.

**Ở dự án đích:** lệnh này đi cùng khung qua `copy-framework.sh`/`.ps1` (cả `.claude/commands/` lẫn `docs/framework/`); thiếu `docs/framework/standard-delivery.md` hoặc `project-completion.md` → báo người dùng chạy copy-framework, không tự suy luật.

Chọn điểm vào rồi bắt đầu ngay.
