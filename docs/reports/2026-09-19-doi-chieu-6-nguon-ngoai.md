# Đối chiếu 6 nguồn ngoài — 2026-09-19

> Phương pháp: `docs/framework/adopt-from-outside.md` (ba cột + cổng "sự cố thật" + grep cổng đang chạy).
> Nguồn xác nhận với người dùng (tên gần đúng → repo cụ thể qua tìm kiếm, người dùng chốt):

| Tên người dùng đưa | Repo xác nhận |
|---|---|
| taste skill | `tasteskill.dev` (skill "Taste-Skill", nhiều fork trên GitHub) + kho chính thức `anthropics/skills` |
| web design guideline | `ianho7/ai-friendly-web-design-skill` |
| awesome design | `bergside/awesome-design-skills` |
| image2code | `Octo-o-o-o/Image2Code` |
| playwright cli | `microsoft/playwright-cli` |
| (bổ sung giữa chừng) | `alibaba/open-code-review` |

**Giới hạn phải nói rõ:** không có quyền `gh`/duyệt file trực tiếp các repo trên (ngoài phạm vi
repo được cấp) — đối chiếu dựa trên README/SKILL.md đọc qua WebFetch/WebSearch, không đọc được toàn
bộ mã nguồn. Với hạng mục nào cần chắc hơn trước khi lấy thật, phải tự tải SKILL.md về đọc trực tiếp.

## Cổng §2 đã chạy trước khi xếp cột "CHƯA CÓ"

Tra `TRAPS.md` (repo khung) — không có mục nào liên quan: giao diện AI-sinh trông chung chung, quy
trình screenshot→code, hay công cụ review diff tự động thiếu sót. `grep` các cổng đang chạy
(`docs/framework/`, `.claude/`) cho từng khái niệm bên dưới, kết quả nêu trong cột 3.

---

## Cột 1 — Đã có và SÂU HƠN

| Hạng mục | Vì sao ở đây sâu hơn |
|---|---|
| **awesome-design-skills** — mỗi style có token hệ thống + WCAG AA | Khung đã có `ui-ux.md` + `quality-supplements-theme.md`: token hoá **bắt buộc** (không hard-code màu), AA ở **cả Dark+Light** (không chỉ một theme), no-flash khi tải, 4 trạng thái, ≥44px, `prefers-reduced-motion` — là luật cứng gắn với `/gate`, không phải một trong nhiều "phong cách" tự chọn. Cái awesome-design-skills cho là *thực đơn phong cách*; cái khung có là *hệ ràng buộc chất lượng bắt buộc* — khác mục đích, không thay nhau. |
| **ai-friendly-web-design-skill** — semantic HTML, locator ổn định (`getByRole`/`getByLabel`) | `ui-ux.md` mục 4 đã nêu đúng các locator này + HTML ngữ nghĩa + ARIA đúng ngữ cảnh; `quality-supplements` đã có E2E+a11y+axe trong cổng CI. Điểm nông hơn duy nhất: định dạng báo cáo review theo mức 🔴🟡🟢 — xem cột 2. |

## Cột 2 — Đã có nhưng NÔNG HƠN (chỉ lấy đúng điểm)

| Hạng mục | Điểm nông cụ thể | Việc nên làm (nếu người dùng chốt) |
|---|---|---|
| **ai-friendly-web-design-skill** — khuôn báo cáo review theo severity 🔴 (chặn) / 🟡 (usability/ổn định) / 🟢 (tinh chỉnh) | `ui-ux.md` không có khuôn xuất báo cáo review UI theo mức độ; `code-review`/`security-review` (skill toàn cục) có khuôn severity riêng nhưng không chuyên cho UI/a11y | Thêm một mục nhỏ vào `ui-ux.md` "khuôn báo cáo khi review UI có sẵn" dùng đúng 3 mức đó — **việc rất nhỏ, không phải import cả skill** |
| **Taste-Skill** — bước "audit-first" trước khi redesign (đọc UI hiện có, không vẽ lại từ đầu) | `ui-ux.md` đã nói "bám đúng hệ thống thiết kế của khung, không vẽ tách rời rồi code lại" nhưng không có bước audit tường minh trước khi đề xuất redesign một màn đã tồn tại | Có thể thêm một dòng vào quy trình tư vấn (mục "Làm rõ") — nhưng **chưa có sự cố thật nào đòi hỏi việc này** ở repo khung hay được người dùng kể ra, nên xếp "chưa cần" thay vì làm ngay (xem cột 3) |

## Cột 3 — CHƯA CÓ (chưa qua được cổng §2 — không lấy ngay)

| Hạng mục | Chưa có gì tương đương (đã grep) | Sự cố thật tương ứng? | Kết luận |
|---|---|---|---|
| **Taste-Skill** — dial VARIANCE/MOTION/DENSITY chống "AI slop" thị giác | Không có cơ chế tinh chỉnh độ biến thiên thiết kế nào trong khung | **Không** — chưa có mục nào trong `TRAPS.md` hay báo cáo audit nói giao diện do AI sinh "trông giống AI" | **Chưa cần.** Xem lại khi: người dùng/khách hàng thật sự phàn nàn UI do khung sinh ra "nhìn generic" ≥ 1 lần |
| **Image2Code** — quy trình screenshot/mockup → `docs/image2code/` (manifest, ui-spec.md, design-model.yaml, before/after screenshot verify) | `grep -rn "screenshot"` trong `quality-supplements-theme.md`/`group2.md` ra 0 kết quả — khung không có quy trình chính thức đi từ ảnh thiết kế sang implementation pack có audit trail | **Không** — chưa dự án đích nào (theo thông tin có) cần bàn giao từ ảnh mockup | **Chưa cần.** Xem lại khi: một dự án đích nhận yêu cầu "code lại y hệt ảnh Figma/mockup" và không có quy trình ghi vết — lúc đó ý tưởng `design-model.yaml` (tách "ảnh là mục tiêu thị giác, YAML/markdown mới là nguồn sự thật") đáng cân nhắc thật |
| **playwright-cli** — CLI token-hiệu-quả bọc Playwright cho agent (thay MCP tốn schema) | Khung hiện dùng Playwright qua test framework thường (`playwright.dev` docs, E2E trong CI) — không có tầng CLI riêng cho agent điều khiển trình duyệt tương tác | **Không rõ** — khung không chạy agent điều khiển trình duyệt trực tiếp (không phải MCP browser-use); Playwright hiện dùng để *viết và chạy test*, không phải để agent *thao tác trực tiếp* trên trình duyệt | **Chưa cần** cho mục đích hiện tại của khung. Xem lại khi: khung/dự án đích cần agent tự thao tác trình duyệt trong vòng lặp (không chỉ chạy test cố định) |
| **open-code-review** — CLI hybrid (deterministic rule-match + agent) review diff, rulesets sẵn (NPE/XSS/SQLi…), resume session | Khung có `/gate` (build/type/lint/test) + skill toàn cục `code-review`/`security-review` chạy trực tiếp bằng model, không có tầng "rule matching qua template engine" độc lập với model, không có cơ chế resume review bị ngắt giữa chừng | **Không** — chưa ghi nhận sự cố review bị ngắt giữa chừng hay lọt lỗi mà rule cố định (không dựa model) đáng lẽ bắt được | **Chưa cần.** Xem lại khi: có PR nào đó lọt qua `/gate` + `code-review` skill mà một rule tất định (regex/AST) lẽ ra bắt được ngay — lúc đó formalize "built-in ruleset" là hợp lý |
| **awesome-design-skills** — 67 gói phong cách sẵn (glassmorphism, brutalism, material, thương hiệu game…) | Khung chỉ có 1 theme chính thức (Dark blue + Light) — không có catalog nhiều phong cách | **Không** — khung cố ý CHỈ một hệ theme (mục 10 CLAUDE.md), catalog nhiều phong cách **mâu thuẫn** với luật đó, không phải thiếu sót | **Không lấy — mâu thuẫn luật** (mục 4 phương pháp), không phải "chưa có". Chỉ đáng xem nếu người dùng chủ động muốn khung hỗ trợ đa phong cách theme — quyết định của người dùng, không tự ý đổi |

---

## Thứ THỰC SỰ nên lấy ngay (rất ngắn, đúng kỳ vọng của phương pháp)

1. **Khuôn severity 🔴/🟡/🟢 cho review UI** trong `ui-ux.md` (từ `ai-friendly-web-design-skill`) —
   việc nhỏ, không mâu thuẫn luật nào, không cần chờ sự cố vì nó chỉ là **định dạng trình bày** của
   một cổng đã bắt buộc (a11y review), không phải luật mới.

Mọi hạng mục khác: **chưa cần**, có điều kiện xem lại ghi rõ ở cột 3 — đúng tinh thần "chưa cần không
phải không bao giờ".

## Đính chính giữa chừng
- Câu hỏi đầu tiên nêu 5 nguồn quá chung chung để xác định repo chính xác — đã dừng hỏi người dùng
  (`AskUserQuestion`) thay vì tự đoán URL, đúng luật "không bịa URL". Người dùng chọn gợi ý cho 4/5
  nguồn, riêng "taste skill" chọn "cả 2" (tasteskill.dev + anthropics/skills), và bổ sung thêm
  `alibaba/open-code-review` giữa chừng.
- `tasteskill.dev` bị egress proxy chặn khi `WebFetch` trực tiếp — thông tin về nguồn này chỉ dựa vào
  đoạn trích trong kết quả `WebSearch`, nông hơn các nguồn còn lại. Nếu cần quyết định chắc hơn về
  Taste-Skill, nên đọc trực tiếp SKILL.md (qua `npx skills add` hoặc bản GitHub fork) trước khi kết luận.
