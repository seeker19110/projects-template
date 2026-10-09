---
description: Chạy tự động — lên kế hoạch TOÀN BỘ (plan mode; đổi model khi độ khó thật đòi hỏi) rồi thực thi tự động (Sonnet code + Haiku việc phụ), qua các cổng của khung. Dùng khi mô tả dự án MỚI hoặc bắt đầu làm trên dự án CÓ SẴN.
---

Bạn vận hành ở chế độ **"lên kế hoạch toàn bộ — chạy tự động"**. Áp dụng khi: người dùng **mô tả một dự án/tính năng mới**, hoặc bắt đầu **làm việc trên một repo có sẵn**.

> Nền model: repo đặt mặc định `.claude/settings.json` = **Sonnet 5**. `/model opusplan` đã ngừng CLI hỗ trợ (ADR-0007). **Đổi model khi độ khó thật đòi hỏi** (vd quyết định kiến trúc mức L), không phải nghi thức đầu mỗi việc (CLAUDE.md §2, ADR-0010 §4); đổi xong quay lại mặc định khi thực thi. Việc tra cứu/xác minh phiên bản giao **subagent Haiku** (`lookup`, `version-check`).

> 💡 Model/effort: theo `docs/framework/models-and-automation.md` §3–§4 và ADR-0010 §4. Đổi model khi độ khó thật đòi hỏi (vd quyết định kiến trúc mức L), không phải nghi thức đầu mỗi việc; phân loại và chia việc theo `docs/framework/standard-delivery.md` §3c.

## Bước 1 — LẬP KẾ HOẠCH TOÀN BỘ bằng Opus (trong Plan Mode)
Vào **plan mode** (Opus). Trước khi lập kế hoạch, **nghiên cứu thật** (không bịa):
- **Dự án MỚI (greenfield):** theo `/consult` + KHUNG-3 — phân loại loại dự án → chọn hồ sơ → **xác minh phiên bản bằng nguồn sống** (giao subagent `version-check`) → đề xuất stack. Bám 9 giai đoạn KHUNG-1.
- **Dự án CÓ SẴN (brownfield):** theo `existing-project-adoption.md` — **đọc repo để biết stack thật** (giao subagent `lookup`), KHÔNG áp stack mặc định; đề xuất nâng cấp tăng dần.

Kế hoạch phải bao trùm: mục tiêu & phạm vi (DoR), các giai đoạn/cột mốc, việc chia nhỏ kiểm tra được, rủi ro + cách giảm, tiêu chí chấp nhận + DoD, điểm cần "dừng và hỏi" (CLAUDE.md §9), và **các cổng** giữa giai đoạn. Độ dài kế hoạch tỉ lệ với mức rủi ro (§3c): mức S/M vài dòng là đủ, mức L mới cần cột mốc và đơn vị PR.

## Bước 2 — CHỐT KẾ HOẠCH (một cổng phê duyệt)
Áp dụng `docs/framework/standard-delivery.md` §3d: phiên chính tự review và chốt kế hoạch trong phạm vi đã được ủy quyền, ghi căn cứ và trạng thái duyệt; không hỏi lại người dùng. Nếu runner đang ở Plan Mode bắt buộc người dùng xác nhận thật qua ExitPlanMode thì tôn trọng cổng đó và báo giới hạn; không tuyên bố đã có xác nhận. Chưa đủ research/spec/bằng chứng hoặc vượt quyền → chưa thực thi phần phụ thuộc.

## Bước 3 — THỰC THI TỰ ĐỘNG (Sonnet + Haiku)
Sau khi duyệt, chạy **tự động** theo kế hoạch, không hỏi lại từng bước:
- **Sonnet 5** viết code theo từng phần nhỏ, hoàn chỉnh, kiểm tra được.
- Giao **subagent Haiku** các việc cơ học: tìm file/định vị (`lookup`), xác minh phiên bản (`version-check`).
- **Phân tích và phân chia** (`docs/framework/standard-delivery.md` §3c): phiên chính chọn S/M/L và số PR; một PR có thể tự làm, từ hai PR giao subagent đủ năng lực theo contract, độc lập thì song song/phụ thuộc thì tuần tự. Tối đa **5 subagent đang chạy toàn cây**, gồm coordinator/reviewer/tester/agent lồng; ba tầng tùy chọn. Phiên chính giữ kế hoạch/quyết định khó, review, tích hợp và chạy đủ cổng; mỗi đơn vị một PR, FIFO/WIP/auto-merge theo §8. Brief cho worker viết theo `docs/framework/templates/PLAN.template.md` và qua `scripts/subagent-dispatch.sh --check-plan` (thoát 0) trước khi giao.
- **Tự động chất lượng đã bật:** auto-format khi sửa file, **cổng chặn `git commit` khi đỏ** (`.claude/hooks/`), qua `scripts/dev-task.sh`. Điền `.claude/project-commands.sh` (copy từ `.example.sh`) nếu dự án có lệnh riêng.
- Trước việc đọc/tạo `docs/work/<id>/working.md`, checkpoint mỗi mốc/trước nén; `PROGRESS.md` trỏ hồ sơ. Chỉ rename sang done.md sau DoD + mọi PR merge thật (contract §3e); commit theo conventional commits.

## WIND-DOWN ở ~70% giới hạn 5h + RESUME phiên sau
> **Sự thật kỹ thuật (đã xác minh):** Claude Code **KHÔNG** cấp % giới hạn 5h cho hook/agent (không env var, không field). Nên **không có cổng máy móc** đọc đúng "70% của 5h". Thực thi bằng **hành vi wind-down + hạ tầng resume** dưới đây.

**Tín hiệu tự động:** nếu đã khai báo `.claude/usage-budget.sh`, **Stop hook** (`usage-guard.sh`) sau mỗi lượt tự ước tính % quota 5h (token thật từ transcript ÷ budget của bạn) và **tự nhắc wind-down khi ≥ ngưỡng** (mặc định 70%). Chưa khai báo budget → tín hiệu tắt, dùng phán đoán tay.

**Khi ước lượng đã dùng ~70% cửa sổ 5h** (theo tín hiệu tự động ở trên, hoặc cảnh báo `/usage` của CLI, hoặc phán đoán theo khối lượng):
1. **KHÔNG bắt đầu** đơn vị công việc mới cần commit/merge; **hoàn tất gọn** đơn vị đang dở.
2. **Commit** phần đã xong (qua cổng — không commit code đỏ). Đây là "dừng commit/merge" hiểu đúng: **ngừng khởi động chu kỳ mới**, không phải chặn lệnh commit (near-limit thì càng phải commit để không mất việc).
3. **Cập nhật `PROGRESS.md`** — nhất là mục **"Bàn giao phiên"**: việc vừa xong, việc DỞ ở đâu, **bước kế tiếp cụ thể**.
4. **Dừng phiên sạch sẽ**, báo người dùng: "đã wind-down, phiên sau nhắn *tiếp tục*".

**Phiên sau — người dùng chỉ cần nhắn "tiếp tục":**
- SessionStart hook (`.claude/hooks/session-resume.sh`) đã **tự nạp** PROGRESS.md + git state vào ngữ cảnh.
- Đọc mục **"Đang làm" / "Tiếp theo" / "Bàn giao phiên"** → **nối tiếp đúng chỗ dở**, không lập lại kế hoạch từ đầu (kế hoạch tổng đã duyệt vẫn hiệu lực).

## Ranh giới tự động (BẮT BUỘC — không vượt)
Chạy tự động **KHÔNG** có nghĩa bỏ cổng. **Vẫn dừng và hỏi chỉ theo CLAUDE.md §9 (thiếu mục tiêu/dữ kiện không tự xác minh · không có phương án đạt chất lượng trong scope/budget · cần quyền chưa cấp) và `docs/framework/standard-delivery.md` §3d**. Chuyển giai đoạn kế: phiên chính nghiệm thu cổng giai đoạn và ghi căn cứ (CLAUDE.md §2), không chờ xác nhận riêng. Ngoài các mốc đó → chạy liền mạch.

> Tóm tắt: **1 kế hoạch tổng (Opus) → 1 lần duyệt → thực thi tự động (Sonnet+Haiku) với auto-format + gate**, chỉ dừng ở các cổng/§9. Đây là mức "tự động" cao nhất vẫn an toàn theo khung.
