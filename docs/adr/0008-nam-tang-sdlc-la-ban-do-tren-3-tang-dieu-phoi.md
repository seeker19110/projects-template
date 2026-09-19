# ADR-0008: 5 tầng SDLC là lớp từ vựng/bản đồ trên 9 cổng + 3 tầng điều phối — không tạo 5 agent cố định

- **Trạng thái:** Đề xuất (chờ người dùng duyệt)
- **Ngày:** 2026-09-19

## Bối cảnh

Người dùng đề xuất tổ chức AI theo 5 tầng vòng đời phần mềm — ① Product & UX (what/why) → ② Design
(experience) → ③ Engineering (build) → ④ Verify & Operate (prove + run) → ⑤ Knowledge (memory) → quay
lại ① — với 5 "core AI", một workflow controller deterministic, và worker động (FE/BE/DB/Security/
Architect/Test…) spawn khi cần rồi kết thúc. Yêu cầu: tối ưu đề xuất đó và áp vào khung này.

Khung hiện có: 9 cổng Frame→Reconcile (`standard-delivery.md` §3), kiến trúc điều phối 3 tầng
(`orchestration-3-tier.md`, ADR-0006/0007) với `route:` là cấp năng lực, 11 subagent, cổng máy
(`pr-policy.yml`, `ci.yml`, hook). Bản đối chiếu ba cột:
`docs/reports/2026-09-19-doi-chieu-mo-hinh-5-tang-sdlc.md`.

## Quyết định

1. **Nhận 5 tầng làm từ vựng vòng đời chính thức** của khung: mỗi tầng trả lời một câu hỏi
   (Xây gì/tại sao? · Hoạt động/trông thế nào? · Xây bằng cách nào? · Đúng, an toàn, chạy tốt không? ·
   Hệ thống biết gì/đã đổi gì?). Bản đồ đặt ở `standard-delivery.md` §3b, nối mỗi tầng với cổng, lệnh/agent,
   artifact và cổng máy **đang có** — không tạo cơ chế mới.
2. **Không tạo 5 agent cố định.** Tầng ①②⑤ là **vai của phiên chính** (Tầng 1) qua lệnh
   `/consult`·`/grill`·`/ui-ux`·`/adr`·PLAN.md, vì đó là nơi cần ngữ cảnh người dùng và quyền hỏi
   (`AskUserQuestion`) — subagent không có cả hai. Tầng ③ là Tầng 3 (worker theo `route:`), tầng ④ là
   `tester`/`reviewer`/`security-reviewer` + `/gate` + CI + `/incident`/`/maintain`. Đúng tinh thần
   "worker động, không agent thường trực" của đề xuất.
3. **Giữ tên agent và nhãn `route:` hiện có** (cấp năng lực — ADR-0006). Tên tầng ("Verify & Operate",
   "Knowledge") chỉ xuất hiện trong bản đồ, không đổi tên file agent.
4. **Thêm luật quy lỗi về tầng:** khi Verify fail, trước lần sửa **thứ 2** cùng một failure phải nêu rõ
   tầng gây lỗi (spec sai → ①, thiếu state/luồng → ②, code → ③, cổng/hạ tầng → ④) và quay về tầng đó;
   không mặc định sửa code. Bổ sung cho trần "3 lần → BLOCKED" của AI Goal Loop, không thay nó.
5. **Không thay `coordinator` bằng state machine** ở thời điểm này — "chưa cần", điều kiện xem lại ghi
   trong bản đối chiếu (đo bằng `scripts/telemetry-log.sh`).

## Lý do

- Khung đã có mọi cơ chế đề xuất mô tả, và ở hầu hết chỗ sâu hơn (cổng máy thay checklist lời). Cái thiếu
  là **bản đồ một trang** — thêm bản đồ giải quyết đúng nhu cầu "bao phủ toàn vòng đời" mà không nhân đôi
  luật (nguy cơ lệch hai sổ, `adopt-from-outside.md` §0).
- Đặt Product/Knowledge vào subagent là **bước lùi**: mất ngữ cảnh qua bàn giao, mất quyền hỏi, tốn token
  (kỷ luật §5 `models-and-automation.md`), trái luật cứng Tầng 1 "thiếu đặc tả → hỏi người dùng".
- Luật quy lỗi rẻ (một câu) nhưng chặn khuôn "sửa code khi lỗi ở spec" — khuôn này chưa có trong
  `TRAPS.md`, nên lấy theo quyết định người dùng và ghi rõ để bác lại được.

## Các phương án đã cân nhắc

- **Tạo 5 file `.claude/agents/{product,design,engineering,verify,knowledge}.md` + xoá 11 agent hiện có:**
  bị loại — mâu thuẫn luật Tầng 1 (cột 4 bản đối chiếu), mất định tuyến 2 trục và đa nhà cung cấp đã có
  test hồi quy.
- **Đổi tên agent/skill theo tầng** (`tester`→`verify-operate`…): bị loại — `route:` là cấp năng lực,
  đổi tên phá tương thích `subagent-dispatch.sh`/CODEMAP/telemetry mà không thêm năng lực.
- **Viết state machine điều phối (JSON/YAML + script) thay coordinator:** hoãn — chưa có số đo chi phí,
  phần deterministic đã là hook/CI/script (thang tối giản CLAUDE.md §3.4).

## Hệ quả

- Tích cực: một trang trả lời "đang ở tầng nào, dùng lệnh gì, artifact gì, cổng nào kiểm, fail quay về đâu";
  đề xuất của người dùng được phản ánh đầy đủ mà không thêm agent.
- Đánh đổi: từ vựng có hai lớp (5 tầng vòng đời ↔ 3 tầng điều phối) — bản đồ §3b phải nói rõ "tầng" nào
  đang được nhắc; `docs-consistency` không kiểm được ngữ nghĩa, review bằng mắt.
- Việc tiếp theo: người dùng duyệt ADR → đổi trạng thái "Đã chấp nhận"; nếu bác, gỡ §3b và đóng ADR
  "Đã thay thế". Xem lại mục 5 khi có số đo telemetry như điều kiện đã ghi.
