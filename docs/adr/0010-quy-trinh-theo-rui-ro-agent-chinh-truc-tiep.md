# ADR-0010: Quy trình theo mức rủi ro, agent chính tự làm, 3 tầng là tùy chọn

- **Trạng thái:** Đã chấp nhận (chủ repo duyệt spec `docs/specs/2026-10-07-lean-delivery.md`, 2026-10-07)
- **Ngày:** 2026-10-07

## Bối cảnh

Goal LD-2026-10 (slice LD-02, FR-2/AC-2): mọi thay đổi đang đi cùng một bộ thủ tục — đổi model trước
khi lập kế hoạch, spec đủ 19 mục, PLAN.md, chuyển giao `coordinator` → worker. Với thay đổi nhỏ, chi
phí bàn giao (mất ngữ cảnh, token, vòng review) lớn hơn lợi ích; chủ repo đã quan sát đúng khuôn này
ở X-Agents (tốn token, reject nhiều, chậm). Các cổng máy (TDD đỏ-trước, `dev-task.sh gate`, required
checks, `pr-policy.yml`) mới là thứ giữ chất lượng, không phải số bước giấy tờ.

## Quyết định

1. Thêm ba mức S/M/L ở `standard-delivery.md` §3c: thủ tục tỉ lệ với rủi ro, chọn theo yếu tố rủi
   ro cao nhất, nghi ngờ thì chọn mức cao hơn. Sàn chất lượng giống nhau ở mọi mức.
2. Mức M dùng **spec gọn** (mục 1, 2, 5, 9, 11 + Approval của mẫu hiện có) — không thêm mẫu thứ hai.
3. **Agent chính tự làm** là mặc định. Điều phối 3 tầng (`orchestration-3-tier.md`) chuyển thành
   tùy chọn cho mức L có ≥ 2 đơn vị PR độc lập; Tầng 1 tự làm phần lõi thay vì "không tự code".
4. Đổi model là theo độ khó thật, không phải nghi thức đầu mỗi việc (bổ sung ADR-0007, không thay).
5. Quyền code ≠ quyền merge ≠ quyền deploy được viết thành luật ở §3c.

Không đổi agent, nhãn `route:`, bản đồ 5 tầng (ADR-0008) hay bất kỳ cổng máy nào.

## Lý do

Giảm bàn giao và giấy tờ ở nơi rủi ro thấp mà không chạm cơ chế đo chất lượng. Một nguồn quy trình
(§3c) thay cho các đoạn hướng dẫn điều phối chép ở CLAUDE.md, AGENTS.md và `/auto`.

## Các phương án đã cân nhắc

- **Giữ nguyên:** tiếp tục chi phí chuyển giao cho mọi thay đổi — bị loại theo spec §4.
- **Gỡ hẳn coordinator/worker:** mất khả năng song song cho việc lớn thật, phá tương thích
  `subagent-dispatch.sh`/telemetry — bị loại; giữ làm tùy chọn.
- **Mẫu spec gọn riêng:** thêm một file phải đồng bộ với mẫu đầy đủ — bị loại; dùng tập con.

## Hệ quả

- Tích cực: thay đổi S/M đi thẳng từ yêu cầu tới PR; tài liệu điểm vào ngắn hơn.
- Đánh đổi: chọn mức là phán đoán; chống chọn thấp bằng luật "nghi ngờ thì mức cao hơn", mốc §9 và
  `pr-policy.yml` vẫn đòi spec Approved cho mọi PR `feat`.
- Kiểm chứng: `tests/test_adaptive_process.py` (chạy trong gate cục bộ và CI Linux).
