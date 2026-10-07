# Công việc: tích hợp sửa lỗi ghi evidence của gate

- Work ID: 2026-10-08-gate-evidence-write
- Yêu cầu / outcome: tạo PR và bật auto-merge cho bản sửa gate báo PASS khi không lưu được evidence.
- Trạng thái: Done — PR #214 MERGED vào main tại 2026-10-07T17:39:46Z; outcome đạt theo ủy quyền.
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
- Lượt 2026-10-08: main #213 đã reconcile; push thường thành công với head deefba8620e2385bc6fce3735576760405213542.
- PR https://github.com/seeker19110/projects-template/pull/214 đã tạo; autoMergeRequest SQUASH enabledAt 2026-10-07T17:31:08Z đã xác minh.
- Full gate và Git hook ở head trên exit 0; log /tmp/gate-evidence-main213-gate.log và /tmp/gate-evidence-main213-commit.log. Đối chiếu toàn bộ output, chỉ khác đường dẫn fixture/thời gian và dòng commit; coverage 96%, sàn 95%.
- CI 37659662280 SUCCESS trên head deefba8: Linux/Windows, docs/copy/protection và gate đều SUCCESS; metadata, gitleaks, dependency-review và CodeQL cũng SUCCESS. progress-freshness SKIPPED đúng điều kiện chỉ chạy trên push main.
- GET PR xác minh MERGED, merge SHA 93d1a3f8c2643a7d3ff280d83b87b3c51768ab22. Đã fetch và reconcile worktree riêng về origin/main tại SHA đó; checkout chính có staged của phiên khác nên giữ nguyên.

## Bàn giao / bước tiếp theo

Đơn vị này không còn việc source/PR phải làm. Hồ sơ done và PROGRESS sau merge là checkpoint cục bộ để đi cùng PR công việc kế tiếp; không mở PR chỉ để lặp cập nhật SHA.
Giới hạn: concurrent writer dùng cùng đường evidence và runtime macOS chưa được kiểm chứng trong đơn vị này.
