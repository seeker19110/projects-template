# Đối chiếu skill `ui-ux-design` v6 (Claude-Agents) với `/ui-ux` của khung — 2026-09-23

> Phương pháp: `docs/framework/adopt-from-outside.md` (§1 ba cột · §2 cổng "sự cố thật" · §3 grep cổng
> đang chạy · §4 kiểm mâu thuẫn luật). Yêu cầu người dùng: "nâng cấp kỹ năng thiết kế UI/UX".

## 0. Nguồn

Repo `seeker19110/Claude-Agents`, skill [ui-ux-design v6](https://github.com/seeker19110/Claude-Agents/blob/main/companies/software-company/skills/ui-ux-design.md) (98 dòng), cùng
[báo cáo nhập Hallmark](https://github.com/seeker19110/Claude-Agents/blob/main/companies/software-company/docs/reports/2026-09-05-hallmark-vao-ui-ux.md) của repo đó.
Skill này tự ghi nguồn gốc: `ui-ux-pro-max-skill`, `impeccable`, `hallmark` (đều MIT) — diễn đạt lại, không
chép nguyên văn; bản đối chiếu này cũng làm như vậy.

Bên nhận: `.claude/commands/ui-ux.md` (50 dòng) + phần nó dẫn chiếu: `quality-supplements-group2.md`
mục 1/3/5, `quality-supplements-theme.md`.

## 1. Cổng §3 đã chạy trước khi xếp cột

```
grep -rli "<khái niệm>" --exclude-dir=.git --include=*.{md,sh,yml,css,ts} . | grep -v reports/
  "8 trạng thái|focus-visible"        → chỉ ui-ux.md (nhắc focus-visible ở mức bàn phím, không có tầng component)
  "overflow-x"                        → 0 file
  "transition: all|transform/opacity" → 0 file
  "primary CTA|một CTA|hành động chính" → 0 file
  "bịa số|lời chứng thực|testimonial" → 2 file, cả hai nói về bịa số liệu MODEL/benchmark, không phải UI
  "Inter|gradient"                    → 2 file, đều dương tính giả (Interface/linter)
  "border-width|outline-offset"       → 0 file
  "on-primary|nền tối|lật nền"        → 1 file, dương tính giả (aria-label "Chuyển sang nền tối")
ls .github/workflows → ci, dependency-review, maintenance, pr-policy, release, secret-scan, stale-pr-alert
  (không job nào của repo khung chạy axe/Lighthouse — đó là cổng của dự án đích hồ sơ C1)
```

Kết luận đo: các "chưa có" dưới đây là dữ kiện từ grep, không phải ấn tượng đọc văn xuôi.

**Phát hiện phụ (§3 — tài liệu nói sai):** `ui-ux.md` ghi *"File thật: `styles/theme.css`,
`components/theme-toggle.tsx`"*, nhưng theo ADR-0004 repo khung không còn kèm scaffold Web — hai file đó
không tồn tại ở đây (`ls styles components` → không có). Câu này sẽ dẫn AI đi tìm file không có, hoặc tệ
hơn, tự tạo chúng ở dự án không phải web. Sửa trong cùng PR.

## 2. Cột 1 — ĐÃ CÓ và SÂU HƠN (không lấy)

| Hạng mục v6 | Vì sao bản khung mạnh hơn |
|---|---|
| Token nguồn duy nhất, không hard-code; đọc token hiện có trước khi đề xuất | Khung có y hệt, cộng thêm nối vào cổng: AA **cả Dark + Light**, no-flash, axe trong E2E. |
| Dark mode là bộ token riêng, đo contrast lại | Khung bắt AA ở **cả hai** chế độ là luật cứng (CLAUDE.md §3.10), không chỉ khuyến nghị. |
| 5 trạng thái màn hình | Khung có 4 trạng thái + phản hồi form ở mục riêng — tương đương; v6 gộp "validation" thành trạng thái thứ 5, không thêm nội dung. |
| Tap target 24×24 CSS px (web) | Khung bắt **≥ 44×44px** — chặt hơn mức tối thiểu WCAG 2.2. |
| Undo hơn "chắc chưa?", submit disable + loading, giữ dữ liệu khi lỗi, > 400ms có chỉ báo | Khung đã có đủ (group2 mục 5). |
| Research-first cho thư viện UI mới | Khung có, kèm xác minh bằng nguồn sống + `/adr`. |
| Checklist cho người chấm | Khung có khuôn review 🔴/🟡/🟢 (PR #144) — mạnh hơn checklist phẳng vì phân cấp chặn/không chặn. |

## 3. Cột 2 — ĐÃ CÓ nhưng NÔNG HƠN (chỉ lấy đúng điểm nông)

Mỗi dòng neo vào **một luật cứng đang có** của khung — đây là "sự cố" theo nghĩa §2: luật đã tồn tại vì lỗi
thật, và điểm nông là lỗ để lỗi đó lọt qua.

| Điểm lấy | Luật/cổng đang có mà nó siết | Điểm nông cụ thể |
|---|---|---|
| **Trạng thái tầng component**: mặc định, hover, `:focus-visible`, active, disabled, loading, error, success | CLAUDE.md §3.8 (bàn phím, focus thấy rõ), §3.3 (mọi thao tác có nhánh lỗi) | Khung chỉ bắt 4 trạng thái **màn hình**; một nút thiếu `focus-visible` hay `disabled` vẫn qua được checklist. |
| **Contrast theo từng bề mặt**: nền lật màu thì chữ lật theo cùng rule; nền nhấn đi kèm token chữ (`on-primary`); chữ nút ≈ nền nút là lỗi chặn | §3.10 AA cả hai theme | Khung đo AA ở mức **theme**, không nói tới khối nền tối trong theme sáng / nút màu nhấn — chỗ báo cáo Hallmark ghi là "lỗi ship thật". axe chỉ bắt khi màn đó có trong E2E. |
| **Không nhảy layout ở form & ảnh**: không đổi `border-width` giữa các trạng thái input; focus bằng `outline` + `outline-offset`; chừa sẵn dòng helper/lỗi; đặt sẵn kích thước ảnh/khối async | §3.9 CLS ≤ 0.1 (Lighthouse CI là cổng) | Khung nói "không nhảy layout" chỉ cho trạng thái **tải**; lỗi validation hiện ra đẩy form là nguồn CLS phổ biến không được nhắc. |
| **Chuyển động chỉ `transform`/`opacity`**, không `transition: all`, không animate thuộc tính bố cục, focus ring hiện ngay (không fade) | §3.9 (CWV: CLS, INP) + §3.8 | Khung chỉ nói `prefers-reduced-motion`. |
| **Công thức chống cuộn ngang**: `overflow-x: clip` ở `html` và `body`; track lưới `minmax(0, 1fr)`; `overflow-wrap: anywhere` cho tiêu đề lớn; chữ bấm được không xuống hai dòng | group2 mục 1 checkbox "không có thanh cuộn ngang ở bất kỳ breakpoint nào" | Khung **đòi** nhưng không nói **cách** — AI tự vá bằng `overflow: hidden` (làm hỏng `position: sticky`). |
| **Thông báo lỗi = nguyên nhân + việc làm tiếp** (không chỉ lỗi validation) | §3.3 xử lý lỗi | Khung chỉ nói "nói *cách sửa*" cho lỗi form. |
| **Một primary CTA mỗi màn**; hành động phá hủy tách khỏi CTA chính | Quy trình bước 2 "một màn — một mục tiêu" | Khung hỏi "hành động quan trọng nhất là gì" ở bước làm rõ nhưng đầu ra không bắt thể hiện nó. |
| **Không bịa số liệu, logo khách, lời chứng thực, Lorem ipsum** — thiếu dữ liệu thì để ô có nhãn "chờ số liệu"; dữ liệu mẫu lấy từ miền của dự án | CLAUDE.md §4 chống ảo giác | §4 áp cho code/lệnh; chưa nói rõ áp cho **nội dung trong thiết kế** — chỗ AI hay lấp bố cục bằng số đẹp. |
| **A11y chi tiết còn thiếu**: label hiển thị (placeholder không thay label); disabled báo ba kênh (mờ + con trỏ + `disabled`/`aria-disabled`); nội dung tự xoay dừng khi hover **và** focus (WCAG 2.2.2); không emoji làm icon, SVG trang trí `aria-hidden` | §3.8 WCAG AA | Khung liệt "nhãn cho input" nhưng không cấm placeholder-thay-label; WCAG 2.2.2 là mức A mà khung chưa nhắc. |

## 4. Cột 3 — CHƯA CÓ → xếp "chưa cần" (không qua cổng §2)

grep ở §1 xác nhận các mục này thật sự chưa có. Nhưng không tìm thấy sự cố ghi nhận nào ở repo khung, ở
`TRAPS.md`, hay ở repo Claude-Agents (đã grep `TRAPS.md`, `docs/sessions/`, `CHANGELOG.md` của nó — mục UI
duy nhất là nhập Hallmark, một quyết định chủ động chứ không phải sự cố). "Repo kia có" không đủ.

| Hạng mục | Điều kiện xem lại |
|---|---|
| Danh mục "mặc định của AI" (font Inter/Roboto mặc định, gradient tím→xanh, hero + 3 cột feature, card lồng card, bounce, heading nghiêng, khung trình duyệt/điện thoại giả, eyebrow cạnh tiêu đề) | Khi một review UI ở dự án đích ghi nhận "trông như AI sinh" ≥ 1 lần → ghi `TRAPS.md` rồi mở lại. |
| Vân tay cấu trúc 6 trục + cấm lặp cấu trúc giữa các màn | Khi hai màn khác mục đích của cùng dự án bị chê trùng khuôn. |
| Tự chấm 6 trục 1–5 trước khi giao | Cùng điều kiện với dòng đầu; nếu mở lại, gộp vào khuôn review 🔴/🟡/🟢 thay vì thêm thang điểm thứ hai. |
| Chọn phong cách theo ngành; quy tắc biểu đồ; trễ tooltip 800–1000ms; mật độ theo ngữ cảnh | Khi một dự án đích có dashboard/biểu đồ thật. |
| Bước "audit trước khi redesign" | Giữ nguyên "chưa cần" như báo cáo 2026-09-19 — không có sự cố mới. |

## 5. Không lấy vì MÂU THUẪN luật đang có (§4)

| Hạng mục | Mâu thuẫn với |
|---|---|
| Breakpoint cố định 375 / 768 / 1024 / 1440; type scale cố định 12/14/16/18/24/32; spacing 4/8 bắt buộc | Khung **không áp stack/giá trị mặc định** (CLAUDE.md §0b, `TRAPS.md` §9 nhãn "C1 — MẶC ĐỊNH"): token là của dự án đích, đọc từ file token của nó. Áp số cố định là tái phát đúng bẫy đó. |
| Ghi token có version vào namespace `design` | Cơ chế riêng của software-company (blackboard); khung dùng `docs/specs/` + ADR. |

## 6. Thực sự lấy

9 điểm ở cột 2 + sửa câu "File thật" sai (§1). Không lấy hạng mục nào ở cột 3. Tỷ lệ 9/~25 cao hơn mức
"1–2/25" §5 gợi ý là bình thường — lý do: nguồn là **skill cùng chủ, cùng mục đích** (không phải một khung
ngoài khác mục đích), và mỗi điểm lấy đều là siết một luật cứng đã có, không đẻ luật mới. Nếu người duyệt
thấy tỷ lệ này là dấu hiệu §3 bị bỏ, đây là chỗ để bác: xem bảng §1.

Phần CSS cụ thể (`overflow-x: clip`, `minmax`, `outline`) chỉ áp cho hồ sơ có UI web; `ui-ux.md` ghi rõ hồ sơ
native dùng cơ chế tương đương của nền tảng — không kéo khung về web mặc định.
