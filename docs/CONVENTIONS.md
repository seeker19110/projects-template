# CONVENTIONS — Sổ quy ước của bộ khung

Mỗi pattern lặp lại có một nguồn chuẩn; thay đổi phải được đối chiếu với code/test
và Standard Delivery Contract. Repo này là bộ khung tài liệu/script/agent/CI,
không phải một app có stack mặc định. Sổ được đối chiếu lại ngày 2026-09-25.

## A. Shell, runtime và kiểm chứng

| Pattern | Quy ước | Nơi kiểm chứng |
| --- | --- | --- |
| Script cổng | Dừng và trả mã lỗi khi kiểm tra không đạt; `set -euo pipefail` khi phù hợp | `scripts/check-docs-consistency.sh` |
| Hook/utility cần xử lý lỗi có chủ đích | Có thể dùng `set -uo pipefail` với comment lý do; KHÔNG suy ra mọi hook phải exit 0. Formatter best-effort khác hook chặn commit | `.claude/hooks/auto-format.sh`, `.claude/hooks/pre-commit-gate.sh` |
| Gate dự án | Tiền kiểm contract rồi chạy fail-fast/pipefail; BLOCKED khác FAIL, READY khác PASS | `scripts/dev-task.sh`, `scripts/test-dev-task.sh` |
| N/A theo profile | Lý do có nội dung và được review; không vừa command vừa N/A, không N/A toàn bộ | `docs/framework/strict-gate-contract.md` |
| Không phụ thuộc stack | Hook gọi điểm vào chung; dự án khai command thật hoặc autodetect | `.claude/project-commands.example.sh` |
| Contract của repo khung | Cấu hình riêng trong `.claude/project-commands.sh`, không copy làm mặc định sang dự án khác | CI chạy doctor và gate đầy đủ |
| Header | Giải thích làm gì, vì sao tồn tại, cách chạy và mã lỗi có ý nghĩa | `scripts/maintain-cron.sh` |
| CLI nhận giá trị | Kiểm thiếu/rỗng/cờ kế tiếp trước shift; không để parser chạy mãi | `tests/test_runtime_safety.py` |
| Runtime data safety | Lease gắn expected SHA; giữ local commit; merge trên bản tạm; không ghi stamp thành công khi lỗi | `docs/reports/2026-09-25-runtime-safety.md` |
| Test mới | Có đối chứng vi phạm; test thật sự được CI chạy | `scripts/test-dev-task.sh`, `tests/test_runtime_safety.py` |
| Fixture phục hồi | Dùng scratch riêng/bản sao; không git restore/reset làm mất việc chưa commit của người dùng | `TRAPS.md` |
| Windows | Kiểm Git Bash/encoding/line endings ở Windows CI; copy PowerShell giữ UTF-8 BOM | `.github/workflows/ci.yml`, `copy-framework.ps1` |

Giới hạn cấp bảo vệ phải nói rõ: kiểm sau worker không thay thế sandbox. Atomic
merge theo từng file không phải transaction nguyên tử cho toàn cây. Command được
log nên không chứa secret. Lý do N/A là chính sách cần review, không phải chứng
thực phê duyệt của con người do máy tự tạo.

## B. Tài liệu và nguồn trạng thái

| Pattern | Quy ước |
| --- | --- |
| Tên file | Tiếng Anh, kebab-case; nội dung có thể dùng tiếng Việt |
| Điều hướng | `CLAUDE.md`/`AGENTS.md` và `docs/framework/standard-delivery.md` là điểm vào; tài liệu chuyên sâu không tạo vòng đời song song |
| Đường dẫn | Backtick, file tồn tại hoặc thuộc ngoại lệ tương lai có chủ đích; đối chiếu bằng docs-consistency |
| Trạng thái | PROJECT giữ phạm vi; PROGRESS tóm tắt; Goal giữ iteration; Spec giữ contract; GitHub/CI giữ bằng chứng thực thi |
| Nhật ký lịch sử | Snapshot giữ nguyên, ghi rõ không phải chính sách/trạng thái hiện tại; không sửa quá khứ để làm báo cáo hiện tại đẹp hơn |
| Bản mẫu | Dùng `docs/framework/templates/`; không nhân bản cùng trạng thái vào nhiều tài liệu |
| Tuyên bố chất lượng | Gắn đúng commit/phạm vi/toolchain; không suy ra sản phẩm production đạt chuẩn từ fixture hay điểm radar |

## C. Slash command và subagent

Frontmatter phải mô tả vai trò, routing và ranh giới, không ghim số lượng agent/lệnh
trong văn xuôi vì danh sách thay đổi. Slash command có TRIGGER tương ứng trong
CLAUDE; docs-consistency kiểm liên kết. Thân lệnh trỏ contract chuẩn thay vì chép
một quy trình mới. Worker không tự commit/merge hoặc đổi gate; phiên chính giữ
quyền quyết định và nghiệm thu. Các task độc lập có thể chạy song song theo phạm
vi file/worktree, nhưng tích hợp vẫn FIFO và kiểm lại trên base thực tế.

## D. Git và CI

Conventional Commits; mỗi PR một outcome; tích hợp qua PR, không push thẳng main.
Branch protection được đối chiếu bởi protection-guard với ruleset lưu trong repo;
FIFO là quy trình điều phối, không tự nhận rằng branch protection cưỡng chế FIFO.
Danh sách required checks ở `docs/ops/repository-settings.md`; `gate` tổng hợp chỉ
cho skip các job được khai rõ trong SKIP_ALLOWED.

Sửa bug cần test đỏ trước sửa rồi giữ test hồi quy. Feature có spec Approved trước
code; PR policy hiện kiểm metadata và tham chiếu, không được diễn giải thành bằng
chứng phê duyệt độc lập nếu chưa có kiểm chứng tương ứng. Không tắt test, nới
threshold hoặc sửa permissions/ruleset để vượt cổng.

## E. Điểm phân kỳ và giới hạn còn phải theo dõi

Bản Bash và PowerShell của installer phải khớp file phát; `REQUIRE_PWSH=1` trên CI
không cho thiếu PowerShell trở thành skip âm thầm. Riêng native `-Upgrade` ở bản
PowerShell chưa có engine merge: dùng Git Bash, không tuyên bố hai bản tương đương
ở tính năng này.

Các hook best-effort thiếu tool phải cảnh báo; gate chính trả BLOCKED. Hook thiếu
jq vẫn còn đường fail-open, không được gọi đó là đã được doctor thay thế hoàn toàn.
CI-policy của khung và các kiểm thử CI ở dự án đích cần được đối chiếu theo thực tế;
C01 (adoption trên sản phẩm thật) và C02 (đầy đủ toàn bộ drop-in) chưa được tự động
đóng bởi một fixture Node. Chi tiết ở `docs/framework/strict-gate-contract.md`.
