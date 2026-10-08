# PROJECT.md — [Tên dự án]

> Đặc tả dự án — nguồn sự thật về *cái gì cần xây*. Điền đầy đủ trước khi code.
> Mẫu lấy từ docs/framework/KHUNG-2 (Phần B). Nhờ AI phản biện trước khi chốt.
> **Mẫu này không có hồ sơ mặc định** (ADR-0004; hồ sơ do AI chọn từ ý tưởng — xem README).
> Các mục đặc thù web (Lighthouse/CWV, RLS, theme, endpoint) **chỉ điền nếu
> đúng hồ sơ**; hồ sơ khác thay bằng tiêu chí tương đương (xem KHUNG-3 PHẦN C).

## 0. Loại dự án & Hồ sơ
- Loại dự án (web / mobile / desktop / backend-API / site tĩnh / CLI-thư viện / data-ML / game / blockchain / monorepo / khác):
- Hồ sơ áp dụng (KHUNG-3 C1–C10): ___ — nếu nhiều thành phần, liệt kê hồ sơ cho từng phần.
- Cổng chất lượng đặc thù của hồ sơ (thay/bổ sung cho cổng web):

## 1. Vấn đề & Người dùng
- Vấn đề (1–2 câu):
- Người dùng mục tiêu (cụ thể):
- Bằng chứng nhu cầu:
- Đối thủ & điểm khác biệt:

## 2. Phạm vi MVP (MoSCoW)
- Must have: (mỗi mục kèm tiêu chí chấp nhận)
- Should have:
- Could have:
- Won't have (lúc này):

## 3. Yêu cầu phi chức năng
- Tốc độ mục tiêu (Lighthouse ≥ ...; CWV: LCP ≤ 2.5s, INP ≤ 200ms, CLS ≤ 0.1):
- Bảo mật (vd RLS, xác thực):
- Accessibility (vd WCAG AA):
- Mobile-first & thiết bị/trình duyệt hỗ trợ:
- Theme: nền **Dark blue mặc định** + chế độ **Light** (mặc định trừ khi nêu khác):

## 4. Tech stack
> Điền theo KHUNG 3 (research-first). Mỗi lựa chọn ghi **phiên bản + ngày đã xác minh** và 1 câu lý do
> (cân bằng độ phổ biến ↔ năng lực). Quyết định lớn → có ADR trong `docs/adr/`.
- Frontend / Backend / CSDL / Hosting / Khác:
- Phiên bản chính (đã xác minh ngày ____): Node ___ · framework ___ · CSDL/client ___ · ...

## 5. Thiết kế dữ liệu
- Bảng + cột + ràng buộc + quan hệ + index:
- Chính sách RLS:

## 6. Kiến trúc & API
- Sơ đồ luồng (client ↔ server ↔ CSDL):
- Danh sách endpoint (đầu vào / đầu ra / mã lỗi):
- Logic nào ở server (nhạy cảm):

## 7. Luồng người dùng chính
- (từng bước từ vào app đến đạt mục tiêu)

## 8. Definition of Done (DoD)
- (sao chép từ KHUNG-1, điều chỉnh nếu cần)

## 9. Lộ trình & Mốc thời gian
- (chia theo đợt/sprint, mỗi đợt một mục tiêu rõ)

## 10. Rủi ro & Giả định
- (sổ rủi ro: giả định nguy hiểm nhất + cách kiểm chứng)
