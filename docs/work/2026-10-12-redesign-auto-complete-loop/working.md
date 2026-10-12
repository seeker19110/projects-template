# Công việc: redesign-auto-complete-loop

- Work ID: 2026-10-12-redesign-auto-complete-loop
- Yêu cầu / outcome: chủ repo 2026-10-12 "thiết kế lại vòng lặp để tự động code hoàn thiện dự án, thiết kế cả workflow, tham khảo stored và các nguồn khác, bằng tất cả năng lực" → vòng lặp `/auto-complete` v2 có **trạng thái máy đọc được + bước kế tiếp do máy tính từ trạng thái thật**, và một tài liệu workflow tham chiếu đầu-cuối (idea → bàn giao).
- Trạng thái: Planned
- Chủ trì / writer: phiên chính (Fable 5.1 cho quyết định kiến trúc mức L)
- Mức rủi ro / số PR: **L** (đổi lệnh tự động cốt lõi + hook Stop + engine mới + nhiều PR); số PR chốt sau research (dự kiến 3–4, tuần tự vì harness chỉ push một nhánh)
- Scope / non-goal: trong — kiến trúc vòng lặp (trạng thái, chọn bước, cổng chuyển pha, dừng/bàn giao), workflow tham chiếu, cổng máy mới có test đỏ-trước; ngoài — runner không giám sát (X1, quyết 2026-10-10), đổi luật §3d/§8/§9, vendor plugin ngoài
- Spec / goal / issue: dự kiến tạo sau research (chưa tồn tại) — spec đầy đủ mức L docs/specs/2026-10-12-auto-complete-loop-v2.md + goal docs/goals/2026-10-12-auto-complete-loop-v2.md + ADR-0012; báo cáo đối chiếu docs/reports/2026-10-12-thiet-ke-lai-vong-lap.md
- Nhánh / base SHA / thời điểm reconcile: `claude/sharp-goldberg-4owppu` @ `dd9de33` · 2026-10-12T16:44:23Z

## Kế hoạch và phân công

Bước 1 — Research (4 agent read-only song song, ≤ 5 toàn cây): (a) kiểm kê cơ chế vòng lặp ĐANG CHẠY vs văn xuôi (grep cổng,
`adopt-from-outside.md` §3); (b) kiến trúc vòng lặp ở nguồn ngoài (Anthropic harness, ralph plugin, /goal, Codex Goals, OpenHands,
Beads, superpowers, BMAD, spec-kit…) theo trục *cấu trúc* — khác hai đối chiếu hôm nay (so từng cơ chế); (c) tầng workflow +
primitive Claude Code; (d) `stored` @ `71dbc26` (10 commit mới so với a4c8376; mục 03/21 không đổi).
Bước 2 — Báo cáo ba cột + spec L (≥ 2 phương án, Approved §3d) + goal + ADR-0012 + tài liệu workflow.
Bước 3 — Thực thi theo số PR trong spec, mỗi PR qua `/gate`, test đỏ-trước cho engine/hook mới; Bước 4 — đóng hồ sơ.

## Quyết định và bằng chứng

<Quyết định + lý do; lệnh/test, head/base và kết quả thật; PR/review/CI/merge SHA.
Không ghi test xanh từ lời khai hoặc dùng kết quả trước thay đổi.>

## Lần thử / blocker

<Failure, số lần cùng failure, giả thuyết đã bác bỏ, blocker và cách kiểm tiếp.>

## Bàn giao / bước tiếp theo

<Một hành động cụ thể, file/lệnh cần đọc/chạy; thay đổi chưa commit và nơi giữ;
điều kiện có thể tiếp tục. Cập nhật trước nén/chuyển phiên/giao việc.>

## Nghiệm thu cuối (chỉ điền khi đủ bằng chứng)

<DoD, mọi PR MERGED + merge SHA và main đã đối chiếu, giới hạn/rủi ro còn lại,
ngày và người nghiệm thu theo ủy quyền. Khi đủ điều kiện rename working.md → done.md
trong cùng thư mục; không overwrite lịch sử. Chưa có PR/merge thì giữ working.md.>
