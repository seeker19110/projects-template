# Đối chiếu 8 nguồn ngoài — "Top 10 Hermes Skill Repos" (ảnh chụp tweet) — 2026-09-22

> Phương pháp: `docs/framework/adopt-from-outside.md` (§1 ba cột · §2 cổng "sự cố thật" · §3 grep cổng
> đang chạy · §4 kiểm mâu thuẫn luật). Không sửa `adopt-from-outside.md` (đó là tài liệu phương pháp,
> không phải sổ nhật ký — theo đúng §5 của chính nó, đầu ra là một bản đối chiếu riêng ở `docs/reports/`).

## 0. Nguồn và giới hạn phải nói rõ

Người dùng đưa ảnh chụp một tweet xếp hạng "Top 10 Hermes Skill Repos theo sao GitHub" (nguồn:
`skillleaderboard.com`, dữ liệu "through 20 September 2026"). Đã tra qua `WebFetch`/`WebSearch`, **không
đọc mã nguồn đầy đủ** (ngoài phạm vi repo được cấp quyền `add_repo`) — chỉ README/trang giới thiệu.

**Cảnh báo độ tin cậy số liệu (đã nêu ở lượt trả lời trước, giữ nguyên ở đây theo luật "không giấu đính
chính"):** số sao trong ảnh (289k, 143k, 120k…) **vượt xa kỷ lục thật của GitHub** (~400k cho các dự án lớn
nhất từng có, sau nhiều năm). Khi `WebFetch` đọc `DietrichGebert/ponytail`, chính công cụ tự flag trang đó
**"appears to be a fictional/demo GitHub page given the 2026 datestamp"**. Kết luận: bảng xếp hạng nhiều khả
năng là nội dung dựng/marketing, không phải số liệu thật. Việc đối chiếu dưới đây **chỉ dựa vào mô tả chức
năng** đọc được (README/trang giới thiệu), không dựa vào số sao hay uy tín tự xưng.

Đã đối chiếu riêng `DietrichGebert/ponytail` (hạng 2) ở báo cáo trước:
`docs/reports/2026-09-14-doi-chieu-ponytail.md` — **không lặp lại ở đây**, chỉ dẫn chiếu khi liên quan.
`obra/superpowers` (hạng 1) mới chỉ đọc README ở lượt trả lời trước (chưa ghi báo cáo) — bổ sung sâu hơn ở
mục 1 dưới, theo đúng bài học đã ghi ở báo cáo ponytail §6 ("đọc văn xuôi/README cũng có thể làm lỡ hoặc làm
tưởng nhầm — phải đối chiếu với cổng thật, không dừng ở ấn tượng đầu").

## 1. Cổng §2 đã chạy trước khi xếp cột "CHƯA CÓ"

```
grep -rli "worktree" --exclude-dir=.git .                    → PROGRESS.md, models-and-automation.md,
                                                                 FEATURE-MAP.md, .claude/agents/coordinator.md
grep -n -i "worktree" .claude/agents/coordinator.md          → coordinator.md dòng 28: đã bắt buộc
                                                                 "nhánh/worktree riêng" cho đơn vị PR độc lập
grep -n -i "CODEMAP" TRAPS.md                                → mục ~10 (dòng 182-199): SỰ CỐ THẬT — một
                                                                 script cổng mới thêm vào ci.yml mà KHÔNG
                                                                 thêm dòng vào CODEMAP.md/CLAUDE.md §1 →
                                                                 "cổng chết trên thực tế", phiên AI mới đọc
                                                                 CLAUDE.md/CODEMAP.md không hề biết cổng đó
                                                                 tồn tại. Đã chốt bằng quy ước tay + cổng
                                                                 check-docs-consistency.sh mục 6.
grep -rli "diagnostic\|chẩn đoán phiên" docs/ .claude/        → 0 kết quả
grep -rli "nén token\|compress.*token\|token.*proxy" .        → 0 kết quả
```

## 2. Cột "ĐÃ CÓ và SÂU HƠN" — không lấy gì

| Hạng mục nguồn | Ở đây đã có | Mạnh hơn ở chỗ nào |
|---|---|---|
| **superpowers** — TDD RED-GREEN-REFACTOR bắt buộc trong workflow | CLAUDE.md §3.6 + ADR-0005 | Có **danh sách ngoại lệ ĐÓNG** (5 mục, phải khai trong PR mục nào), không phải "khuyến nghị dùng TDD" chung chung |
| **superpowers** — bước "git-worktrees" tách môi trường cho việc song song | `.claude/agents/coordinator.md` dòng 28/46 + `docs/framework/orchestration-3-tier.md` | Đã là **luật bắt buộc** ("nhánh/worktree riêng" cho mọi đơn vị PR độc lập chạy song song, chờ tích hợp mới bắt đầu đơn vị phụ thuộc) gắn với kiến trúc 3 tầng cụ thể, không phải một bước rời trong danh sách 7 skill |
| **superpowers** — "code review" là một bước riêng trong workflow | `/review` + skill `code-review`/`security-review` + subagent `reviewer`/`security-reviewer` | Tách thành **tầng hậu kiểm độc lập** trong kiến trúc 3 tầng, có cổng bảo mật riêng khi đụng vùng nhạy cảm, không chỉ một bước trong chuỗi tuần tự |
| **superpowers** — đa nền tảng agent (17+ harness: Cursor, Copilot, Gemini…) | `AGENTS.md` (chuẩn mở agents.md) + `scripts/subagent-dispatch.sh --tier` (bảng đa nhà cung cấp `model-capability-tiers.json`) | Đã phủ **cả hai chiều**: luật dùng chung qua chuẩn mở, VÀ định tuyến model đa hãng theo cấp năng lực — không chỉ "cài được trên nhiều harness" |
| **i-have-adhd** — trả lời đi thẳng vào hành động, không mở đầu dài dòng | CLAUDE.md §4 ("không tin lời khai", 5 bước trước khi nói "xong") + §7 (khuôn Báo cáo xác thực) | Ở đây **đối lập có chủ đích**: khung yêu cầu báo cáo có bằng chứng đầy đủ (Build/Type/Lint/Test/rủi ro), không phải cụt gọn — "đi thẳng vào hành động tiếp theo" chỉ đúng ở phần đầu câu trả lời, không đúng ở việc bỏ hết bằng chứng. Xem thêm mục 4 (mâu thuẫn luật) |
| **diagram-design** — sinh sơ đồ chuyên nghiệp cho AI coding agent, xuất HTML/SVG tự chứa | skill `artifact-diagramming` (đã có trong danh sách skill khả dụng) | Cùng mục đích (sơ đồ chất lượng cho agent); phần **nông hơn cụ thể** nằm ở mục 3 dưới — không lấy cả hạng mục |

## 3. Cột "ĐÃ CÓ nhưng NÔNG HƠN" — lấy đúng điểm

### N-1. `diagram-design` — tự động quét brand từ website để đồng bộ màu/phong cách sơ đồ

- **Nông ở đâu:** `artifact-diagramming` xử lý cơ chế vẽ (SVG inline, mực legible ở cả hai theme) nhưng
  không có bước "quét trang web/design token của dự án rồi tự áp vào sơ đồ trong 60 giây" như nguồn mô tả.
- **Sự cố thật (cổng §2):** **không có** — chưa ghi nhận trường hợp sơ đồ do khung tạo ra bị lệch thương
  hiệu/token màu của dự án đích.
- **Quyết định:** **chưa cần**, không lấy ngay. **Điều kiện xem lại:** khi một dự án đích yêu cầu sơ đồ
  kiến trúc phải khớp đúng bảng màu thương hiệu và việc chỉnh tay lặp lại ≥ 2 lần trong audit/review.

### N-2. `superpowers` — "session diagnostic tools" khi agent lỗi giữa phiên

- **Nông ở đâu:** khung có `/debug` (5 pha, dựng feedback loop đỏ-được trước) cho **bug trong sản phẩm**,
  nhưng không có công cụ chẩn đoán khi chính **phiên agent** (Claude Code) bị treo/lỗi giữa chừng (khác
  phạm vi — `/debug` chẩn đoán code, không chẩn đoán trạng thái phiên).
- **Sự cố thật (cổng §2):** **không có** ghi nhận cụ thể ở `TRAPS.md` về phiên agent tự lỗi cần công cụ
  chẩn đoán riêng (khác với việc phiên hết quota — đã có `session-guide.sh` nhắc dừng ở §5.3).
- **Quyết định:** **chưa cần**. **Điều kiện xem lại:** khi có ≥ 1 lần ghi nhận thật một phiên `/auto` hỏng
  giữa chừng mà không rõ nguyên nhân và không có công cụ nào trong khung giúp chẩn đoán lại.

## 4. Cột "CHƯA CÓ" — đối chiếu cổng §2

| Hạng mục | Chưa có gì tương đương (đã grep) | Sự cố thật tương ứng? | Kết luận |
|---|---|---|---|
| **Graphify** / **Understand Anything** (chọn 1 nếu lấy — hai repo giải cùng một nhu cầu: đồ thị kiến thức codebase tự động, tree-sitter/hybrid LLM, cập nhật tăng dần khi file đổi) | `CODEMAP.md` là bảng tra **viết tay**, không tự cập nhật, không phải đồ thị truy vấn được | **CÓ** — `TRAPS.md` (~dòng 182-199): một script cổng mới không được thêm vào `CODEMAP.md`, phiên AI sau đọc tài liệu không biết cổng đó tồn tại ("cổng chết trên thực tế"). Đây đúng khuôn sự cố mà một công cụ **tự sinh** bản đồ từ mã nguồn thật (không phụ thuộc con người nhớ ghi) sẽ ngăn được tận gốc | **Đủ điều kiện cân nhắc** — xem mục 5 (mức độ lấy: bổ trợ, không thay thế) |
| **Agentic Awesome Skills** — catalog 2.445+ skill, agent tự chọn ID từ catalog ngoài, sinh `aas-stack.json` | Khung tự viết mọi skill/subagent riêng (`.claude/commands/*.md`, `.claude/agents/*.md`), không lắp ráp từ catalog ngoài | Không áp dụng — đây là **mâu thuẫn luật**, không phải thiếu sót (xem mục 5 phương pháp: §4) | **Không lấy — mâu thuẫn luật.** Lắp skill hàng loạt từ catalog chưa kiểm chứng ngược với §4 CLAUDE.md ("không bịa hàm/API — xác nhận tồn tại trước khi dùng") và với luật ba cột chính tài liệu này (mỗi hạng mục phải tự chứng minh, không "lấy theo danh mục") |
| **Caveman** — proxy nén token cục bộ (nén log/JSON/diff trước khi gửi provider, giảm ~33% input token) | `models-and-automation.md` §5 là **kỷ luật hành vi** (plan một lần, ngữ cảnh gọn), không phải một proxy/middleware nén dữ liệu tự động | Không đủ — đây là công cụ hạ tầng vận hành LLM, **ngoài phạm vi §0b** của khung (khung quản lý *quy trình phát triển phần mềm*, không phải xây *middleware tối ưu chi phí API*) | **Không lấy — ngoài phạm vi.** Ghi nhận là ý tưởng đúng hướng cho ai muốn tối ưu chi phí vận hành agent, nhưng không phải việc của CLAUDE.md/khung này |
| **last30days-skill** — nghiên cứu đa nguồn (Reddit/X/YouTube/HN/Polymarket) | Không có gì tương đương — không cần | Không áp dụng — **ngoài phạm vi §0b** (không phải quản lý dự án phần mềm) | **Không lấy — ngoài phạm vi** |
| **scientific-agent-skills** — 166 skill khoa học (bioinformatics, cheminformatics…) | Không có | Không áp dụng — **ngoài phạm vi**, trừ khi dự án đích thuộc hồ sơ data/ML khoa học cụ thể (không phải trường hợp chung của khung) | **Không lấy — ngoài phạm vi cho khung chung.** Ghi chú: nếu một dự án đích cụ thể thuộc hồ sơ khoa học/dược, đây là nguồn tham khảo skill tốt — quyết định ở cấp dự án đích, không ở cấp khung |

## 5. Kết luận — thực sự lấy (rất ngắn, đúng kỳ vọng phương pháp)

**1 / 8 hạng mục qua được cổng §2**, và ngay cả hạng mục đó cũng lấy ở mức **hẹp nhất có thể chứng minh
được**, không lấy nguyên khối:

1. **Ý tưởng lõi của Graphify/Understand Anything — đồ thị/bản đồ codebase SINH TỰ ĐỘNG, không dựa trí nhớ
   con người** — đúng đúng lỗ hổng mà `TRAPS.md` đã ghi nhận thật (script không vào `CODEMAP.md`). **Cách
   lấy phù hợp nhất với luật hiện có:** không thay `CODEMAP.md` (nó có giá trị vì viết tay, có *lý do vì
   sao* mỗi dòng tồn tại, thứ một đồ thị tự sinh không tự có) — mà bổ sung một **phép đo tự động phát hiện
   lệch giữa mã nguồn thật và `CODEMAP.md`** (kiểu: liệt kê mọi `scripts/*.sh` mới không xuất hiện trong
   `CODEMAP.md`), cùng hướng với cổng đã có ở `check-docs-consistency.sh` mục 6 nhưng **đo từ phía mã nguồn
   thay vì chỉ đối chiếu tài liệu ↔ tài liệu**.
   - **Đây là một đề xuất, chưa phải quyết định** — theo đúng Feature gate (CLAUDE.md §2): cần một
     `docs/specs/<ngày>-<slug>.md` mô tả cụ thể thuật toán quét + tiêu chí "lệch" là gì, và người dùng duyệt
     "Approved for implementation" trước khi đụng `scripts/check-docs-consistency.sh`.

Không lấy 7/8 còn lại — lý do tóm tắt: 5 đã sâu hơn hoặc đối lập có chủ đích (cột 1), 1 mâu thuẫn luật
(Agentic Awesome Skills), 2 ngoài phạm vi khung (Caveman token-proxy, last30days/scientific khi tính gộp).

## 6. Đính chính giữa chừng (giữ nguyên, không xoá)

- Lượt trả lời đầu tiên (trước khi có báo cáo này) đã xếp cả 10 repo vào kết luận nhanh "không repo nào đủ
  điều kiện lấy ngay". Sau khi grep kỹ `TRAPS.md` cho từ khoá "CODEMAP" (bước bắt buộc của §3 phương pháp,
  bị làm tắt ở lượt đầu vì chỉ dựa ấn tượng đọc README), phát hiện **có** một sự cố thật đủ điều kiện cho
  Graphify/Understand Anything — kết luận ban đầu "0/10" phải sửa thành "1/8" (loại ponytail đã xử lý riêng
  và superpowers đã đối chiếu bổ sung ở đây, không tính lại). Đúng bài học đã ghi ở
  `2026-09-14-doi-chieu-ponytail.md` §6: **loại một ứng viên sau khi NGHĨ (đọc README) thay vì sau khi ĐO
  (grep TRAPS.md) là bẫy đã mắc, và ở đây bẫy suýt lặp lại theo chiều "loại nhầm" thay vì "lấy nhầm".**
- Mục "Caveman" ban đầu định xếp vào cột "chưa có → chưa cần, xem lại khi chi phí API tăng" (giống mẫu
  N trong báo cáo ponytail), nhưng xét lại thấy đây không phải vấn đề *mức độ ưu tiên thấp* mà là *ngoài
  phạm vi thật sự* của khung (§0b nói rõ khung phục vụ quản lý dự án phần mềm, không phải xây hạ tầng
  LLM-ops) — xếp lại đúng cột "ngoài phạm vi" thay vì "chưa cần trong phạm vi".
