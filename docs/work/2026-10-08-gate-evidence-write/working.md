# Công việc: tích hợp sửa lỗi ghi evidence của gate

- Work ID: 2026-10-08-gate-evidence-write
- Yêu cầu / outcome: tạo PR và bật auto-merge cho bản sửa gate báo PASS khi không lưu được evidence.
- Trạng thái: Active — đang reconcile main và thử lại tích hợp theo ủy quyền; chưa PR/merge.
- Chủ trì / writer: phiên chính.
- Mức rủi ro / số PR: S, một PR sửa bug; phiên chính tự làm.
- Scope: xử lý lỗi ghi evidence, regression, contract/CODEMAP/TRAPS và hồ sơ tích hợp.
- Non-goal: mở rộng feature, đổi cấu hình runner hay benchmark sản phẩm/model.
- Spec / goal / issue: bug nhỏ theo contract §3c; liên quan goal lean-delivery đã đóng (#198).
- Nhánh: codex/gate-evidence-write; base mới dfb1855a215dd5545c2752322cc9bf53cd8f5712 (#213), đối chiếu 2026-10-08.

## Kế hoạch và phân công

1. Giữ checkpoint cũ; merge main mới và giữ ý định của cả hai phần tiến độ.
2. Chạy gate/review trên bản tích hợp; commit theo chuẩn và push nhánh riêng.
3. Tạo một PR đầy đủ template, kiểm head/CI, bật auto-merge; chỉ Done sau MERGED.

## Quyết định và bằng chứng

- Bản sửa đã có remote commit ff1e07636fb82ce47a222d65c315b4273955f166;
  tree e22cb6a10906404c217e7d98fd652dac03c9c5ad trùng bản cục bộ.
- Lượt 2026-10-07: test đỏ trước sửa (hai ca exit 0 sai, một file tạm còn sót),
  sau sửa ba kịch bản/6 assertion xanh; full gate và Git hook xanh trên bản ff1e076.
  Đây là bằng chứng lịch sử, không thay kiểm tra bản sau merge main.
- Log lịch sử: /tmp/gate-evidence-red.log, /tmp/gate-evidence-reviewed.log, /tmp/gate-evidence-commit.log.
- Đã đọc hồ sơ work-memory của #213 và đối chiếu PR/main; phần bàn giao của phiên khác giữ riêng.

## Lần thử / blocker

- Lượt trước Git push lỗi 500 ba lần; Git Data API tạo được đúng commit/nhánh.
- Tạo PR lỗi ba lần; GET xác minh chưa có PR. Chủ repo đã cấp quyền thử lại khi GitHub hoạt động.
- Lượt 2026-10-08: GET vẫn chưa có PR; main đã tiến lên #213 nên reconcile trước retry.

## Bàn giao / bước tiếp theo

Merge main mới vào nhánh hiện tại, giải PROGRESS theo cả hai ý định, chạy lại full gate.
Nội dung PR dự thảo: /tmp/gate-evidence-pr.md. Không đổi hồ sơ thành done trước khi xác minh merge.
