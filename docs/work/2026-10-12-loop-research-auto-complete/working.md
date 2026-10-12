# Công việc: Nghiên cứu vòng lặp coding để nâng /auto-complete tới tự hoàn thành

- Work ID: 2026-10-12-loop-research-auto-complete
- Yêu cầu / outcome: chủ repo 2026-10-12: "nghiên cứu sâu vòng lặp trong coding phát triển phần mềm để nâng cấp cho dự án tiến đến việc tự động hoàn thành khi có mục tiêu, yêu cầu và người dùng bật /auto-complete — bằng tất cả khả năng, tìm kiếm, học hỏi". Outcome: báo cáo đối chiếu ba cột theo `adopt-from-outside.md` (luật §2 mới 2026-10-12: tốt hơn bản hiện có là lấy) giữa vòng lặp hiện có (`standard-delivery.md` §4/§8, `/auto-complete`, hook, cổng) và nguồn ngoài (Anthropic, runner mã mở, sản phẩm thương mại, nghiên cứu) → thực hiện những hạng mục qua cổng §2.
- Trạng thái: Active (research)
- Chủ trì / writer: phiên chính (Fable 5.1); 4 agent read-only nghiên cứu web song song (Anthropic / mã mở / thương mại / học thuật).
- Mức rủi ro / số PR: chưa biết — quyết sau khi có danh sách lấy (dự kiến M nếu có cổng máy mới; báo cáo đi PR riêng).
- Scope / non-goal: Scope = cơ chế vòng lặp (lặp tới goal, verify, phát hiện kẹt/giậm chân, ngân sách, dừng, trạng thái qua phiên, cổng người). Non-goal = runner sửa source không giám sát (quyết 2026-10-10 "chưa", cần threat model riêng — chỉ nêu lại nếu nguồn ngoài cho bằng chứng mới); đổi luật merge/ủy quyền (C1/C2 báo cáo loop-engineering).
- Spec / goal / issue: báo cáo đối chiếu sẽ tạo ở `docs/reports/` (tên `2026-10-12-doi-chieu-vong-lap-coding`); bốn báo cáo đối chiếu trước là nền: ralph (2026-10-10), loop-engineering (2026-10-11), compound-engineering (2026-10-09), SDD ba vai (2026-10-10).
- Nhánh / base SHA / thời điểm reconcile: `claude/trusting-cori-2i53gj` @ `770af27` · 2026-10-12T03:40:35Z

## Kế hoạch và phân công

1. Research ngoài: 4 agent song song (chỉ đọc web, không chạy code ngoài). 2. Đo nội bộ (§3 phương pháp): grep cổng đang chạy cho từng cơ chế ứng viên; đếm sự cố lặp thật trong TRAPS/work/CHANGELOG. 3. Tái đánh giá các mục "chưa cần" của 4 báo cáo trước theo luật §2 mới (ứng viên đầu tiên: N1 bộ đếm 3 lần, goal file chưa có cổng (đính chính B ralph), N3 thoát sớm, N7 ngân sách). 4. Báo cáo ba cột + danh sách lấy. 5. Thực hiện mục lấy: mỗi mục một PR qua `/gate`, TDD đỏ-trước cho cổng máy mới.

## Quyết định và bằng chứng

<Quyết định + lý do; lệnh/test, head/base và kết quả thật; PR/review/CI/merge SHA.
Không ghi test xanh từ lời khai hoặc dùng kết quả trước thay đổi.>

## Lần thử / blocker

Lượt đầu bị chủ repo ngắt để đổi luật §2 trước (hồ sơ `2026-10-12-adopt-better-than-current`, commit 770af27); tiếp tục theo luật mới.

## Bàn giao / bước tiếp theo

<Một hành động cụ thể, file/lệnh cần đọc/chạy; thay đổi chưa commit và nơi giữ;
điều kiện có thể tiếp tục. Cập nhật trước nén/chuyển phiên/giao việc.>

## Nghiệm thu cuối (chỉ điền khi đủ bằng chứng)

<DoD, mọi PR MERGED + merge SHA và main đã đối chiếu, giới hạn/rủi ro còn lại,
ngày và người nghiệm thu theo ủy quyền. Khi đủ điều kiện rename working.md → done.md
trong cùng thư mục; không overwrite lịch sử. Chưa có PR/merge thì giữ working.md.>
