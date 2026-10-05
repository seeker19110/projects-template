# Đề xuất hoàn thiện chính bộ khung — 2026-10-05

> Trạng thái: **người dùng duyệt triển khai toàn bộ ngày 2026-10-05**, kèm yêu cầu
> giao nhiều subagent. Đây là kế hoạch cho repo khung, chưa phải báo cáo nghiệm thu.
> Nguồn trạng thái thực thi là
> `docs/ops/COMPLETION-PLAN.md` và `docs/goals/2026-09-24-completion.md`.

## Snapshot đầu lượt (lịch sử, trước triển khai)

- `origin/main` là `f31c912` (PR #183 đã merge). Goal 2026-09-24 vẫn ghi W-05
  `IN_REVIEW` và base `8cba0e0`, trong khi PR #180 và #181 đã merge. CI trên
  `main` tại `f31c912` xanh: run 36298539716. Chưa thể gọi goal COMPLETE vì
  chưa đối chiếu từng F-01..11 với bằng chứng và quét lại giới hạn.
- `scripts/check-docs-consistency.sh` và `scripts/check-ci-policy.sh` xanh trong
  lượt 2026-10-05. `scripts/maintenance-sweep.sh --strict --no-deps` trả 0 đỏ,
  2 vàng về nhánh local; nó đã bỏ kiểm dependency. `scripts/dev-task.sh gate`
  trả `BLOCKED` (2) ngay ở tiền kiểm vì WSL không có executable `node` trong
  PATH. Vì vậy chưa có bằng chứng full gate **cục bộ của lượt này**.
- Ruleset `main — bảo vệ nhánh chính` đang active, bắt PR/squash, cấm xóa và
  force-push, yêu cầu `gate` + `metadata`, không có bypass actor. Tuy nhiên API
  trả `strict_required_status_checks_policy: false`, trong khi
  `.github/rulesets/main.json` và `docs/ops/repository-settings.md` khai `true`.
  `protection-guard` hiện xanh nhưng chưa phát hiện lệch tham số này.
- Có đúng 3 PR mở: #184 xanh, #185 và #186 đỏ ở CodeQL vì `init` và `analyze`
  chạy khác phiên bản 4.38.1/4.38.2. Log lỗi ghi rõ version mismatch. Trần
  WIP = 3 đã đầy; không mở PR hoàn thiện mới trước khi giải quyết hàng đợi.
- `docs/FEATURE-MAP.md` còn ghi 13 slash command, trong khi `.claude/commands/`
  có 16 file. FT-42 còn nói branch protection chưa bật thật; API ruleset cho
  thấy đã bật, nhưng cấu hình `strict` bị lệch. Các dòng này cần rà lại với code
  và trạng thái GitHub, không chỉ đổi số đếm.

## Definition of Complete đề xuất cho repo khung

1. Goal 2026-09-24 được đối chiếu F-01..11 tới PR, regression và CI trên
   `main`; chỉ đánh dấu COMPLETE nếu mọi tiêu chí trong goal có bằng chứng.
2. Audit lại 12 nhóm theo **năng lực khung** trong `docs/FEATURE-MAP.md`; nhóm
   không áp dụng cho repo không có app/UI/data phải có lý do. Không còn phát hiện
   Cao mở; phát hiện Trung/Thấp còn lại có quyết định và điều kiện xem lại.
3. Ruleset thực tế khớp contract đã chốt, gồm `strict=true`; kiểm tự động có
   negative test cho đúng tham số này. `gate` và `metadata` chặn được vi phạm.
4. CI `main` và từng PR nghiệm thu xanh trên Linux/Windows, copy smoke,
   docs/CI policy, security scan liên quan; gate local PASS trên toolchain đầy đủ
   hoặc báo rõ giới hạn nếu môi trường này vẫn BLOCKED.
5. Bản đồ tính năng, quy ước, CODEMAP, PROGRESS, completion plan và README/ADR
   liên quan khớp code và GitHub hiện tại. Không gắn nhãn đã kiểm chứng cho luồng
   chưa có bằng chứng; C01 (adoption trên sản phẩm thật) chỉ đóng khi người dùng
   chọn dự án đích và cho phép thử trên đó.
6. Một lượt re-audit cuối không phát sinh phát hiện Cao mới; mọi việc đã duyệt
   có PR và bằng chứng nghiệm thu, người dùng xác nhận đóng kế hoạch.

## Các đợt đề xuất

| ID | Việc và lý do | Tiêu chí nghiệm thu | Phụ thuộc | Cỡ |
| --- | --- | --- | --- | --- |
| W-01 | Đối chiếu goal cũ W-05/F-01..11 và cập nhật trạng thái từ `main`; không lẫn giới hạn C01/C02 với goal cũ | Bảng F→PR→test→CI đầy đủ; trạng thái Goal/PROGRESS có SHA thật và không tự nhận Project Complete | — | S |
| W-02 | Hoàn tất audit 12 nhóm của chính khung, cập nhật FEATURE-MAP và `COMPREHENSIVE-AUDIT-STATUS.md` theo hiện trạng | Mỗi nhóm có vị trí, mức độ, bằng chứng hoặc lý do N/A; mọi phát hiện mới có ID cố định | W-01 | M |
| W-03 | Giải quyết cụm CodeQL #184–186 theo FIFO và một phiên bản nhất quán cho các action cùng workflow | CodeQL `Analyze (python/actions)` cùng các required checks xanh trên SHA cuối; không vượt 3 PR mở | — | S |
| W-04 | Đóng lệch ruleset `strict=false` so với file và tài liệu; tăng kiểm live để chặn tái phát | Ruleset API trả `strict=true`; negative test sửa live/config giả thành `false` làm cổng đỏ; required checks vẫn `gate` + `metadata` | W-03; duyệt thay đổi setting bảo vệ repo | M |
| W-05 | Xử lý các phát hiện Cao/Trung từ W-02, mỗi outcome một PR có spec nếu là feature và test đỏ trước nếu đổi logic | Từng F có kết cục, test liên quan và full gate; không hạ coverage/complexity hay auth để xanh | W-02, W-03 | Chưa ước lượng trước audit |
| W-06 | Đối chiếu C02 theo một ma trận hữu hạn các stack mà khung tuyên bố hỗ trợ, gồm copy, gate thật và CI drop-in | Ma trận stack/cổng/CI có run và hạn chế rõ; các stack chưa thử không được ghi PASS | W-02, W-05 | L |
| W-07 | Re-audit hội tụ, smoke các luồng chính, nghiệm thu DoC và cập nhật tài liệu trạng thái | 0 Cao mở; Trung/Thấp có quyết định; CI/gate và báo cáo nghiệm thu gắn SHA `main` | W-04..06 | M |

W-01 và W-03 độc lập về phân tích. W-04 cần hàng đợi PR có chỗ và quyết định
thay đổi ruleset. W-05 được chia thành các PR nhỏ **sau khi** W-02 xác định
phát hiện; không đoán số lượng trước audit. W-06 kiểm C02 trên các stack đã
chốt trong audit, không suy diễn rằng một fixture Node chứng minh mọi stack.

## Điểm cần quyết định ở cổng duyệt

- Duyệt Definition of Complete và thứ tự đợt trên cho **repo khung**.
- Chấp thuận đưa `strict` của ruleset live về `true` sau khi W-04 đã có diff,
  negative test và phương án rollback để review. Đây là thay đổi setting bảo vệ
  nhánh chính nên cần quyết định riêng trước khi áp dụng.
- C01 cần một dự án thật do người dùng chỉ định và quyền kiểm chứng trên repo đó.
  Nếu phạm vi chỉ là repo khung, ghi C01 là giới hạn chưa kiểm chứng, không đánh
  dấu đã hoàn tất.

Các PR được chuẩn bị sau khi kế hoạch được duyệt. Trong lúc có 3 PR mở,
không mở PR mới; không merge PR có CodeQL đỏ để giải phóng slot.
