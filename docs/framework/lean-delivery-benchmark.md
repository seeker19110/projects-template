# Lean delivery — adoption regression và protocol benchmark (LD-08)

## Phạm vi bằng chứng

`tests/test_lean_adoption.py` chạy hai **fixture** Node/Python: copy khung → cấu hình
cổng đã review → chạy test runtime thật → ghi/kiểm evidence → `--upgrade` → giữ
config và ghi chú địa phương → chạy lại → đổi source → từ chối evidence cũ →
kiểm thử đỏ và từ chối evidence FAIL. Mỗi lượt xanh phải đếm được đúng một test.
`scripts/test-copy-framework.sh` bổ sung Bash/PowerShell, upgrade có/không manifest,
xung đột và bảo toàn file; `tests/test_runtime_safety.py` kiểm lỗi merge/lease.

Đây là kiểm thử local và CI của **repo khung**. Kiểm cấu trúc CI drop-in offline
khác với **hosted CI** trên repo đích; fixture khác với **pilot** sản phẩm thật.
Không dùng số ca test để tuyên bố chất lượng hay tốc độ của mọi dự án dẫn xuất.

## Số đo protocol hữu hạn

Baseline đã chốt: `e2b70bffd8f6adadd14b96b31d7b0ab62f63cc61` (e2b70bf).
Đối chứng: main sau LD-05 (#208), `c5228390c79e549a34ee19e6925c6ca4209fbc2e`.
Dùng `suite_counts` của `tests/test_ci_suite_parity.py` trên workflow ở từng SHA,
với danh sách 17 `scripts/test-*.sh` hiện có tại cả hai SHA. Hàm đếm lệnh Linux
và mở rộng lời gọi full gate; không đếm tên step, comment hoặc lượt Windows.

| Metric | Baseline | Đối chứng | Ý nghĩa |
| --- | --- | --- | --- |
| Suite shell Linux khác nhau | 17 | 17 | Tập suite được giữ |
| Tổng lời gọi suite Linux | 34 | 17 | Loại 17 lời gọi lặp; giảm 50% **lời gọi**, không suy ra thời gian |
| Lời gọi mỗi suite Linux | 2 | 1 | `test_every_linux_suite_runs_exactly_once` chặn thiếu/trùng |
| token / chi phí model | unknown | unknown | Không gọi model/API trả phí; byte context không phải token |
| latency đầu-cuối / retry / reject | unknown | unknown | Cần chạy benchmark cùng nhiệm vụ và điều kiện |

Đo lại bằng Python: lấy workflow bằng `git show <SHA>:.github/workflows/ci.yml`,
liệt kê suite theo `git ls-tree -r --name-only <SHA>` rồi truyền hai dữ liệu cho
`suite_counts`. Nếu tập suite khác nhau thì báo riêng phần chung và phần thêm/bớt,
không áp tỷ lệ 50% này cho snapshot mới một cách máy móc. Parser dành riêng cho
workflow phẳng của repo, không phải bộ phân tích YAML tổng quát.

## Bộ nhiệm vụ đại diện S/M/L

Cùng input, acceptance criteria, toolchain, model/version, ngân sách và quyền cho
baseline/đối chứng; mỗi run ở checkout cô lập. Lưu SHA khung **và** SHA dự án đích.
Không cho worker sửa artifact chung; không đánh đổi coverage hoặc required checks.

| Mức | Nhiệm vụ | Oracle nghiệm thu |
| --- | --- | --- |
| S | Bug tính toán có ca biên trong CLI | Test đỏ trước, sửa đúng, gate/CI đúng head |
| M | Feature API validation và lỗi | Spec Approved, ca hợp lệ/không hợp lệ, AC map evidence |
| M | Luồng UI tải/rỗng/lỗi và bàn phím | E2E + a11y theo profile, xác nhận UX riêng |
| L | Nâng định dạng dữ liệu có rollback | Fixture bản cũ, migration lặp, rollback và reconciliation |
| L | Thay prompt/model trong hệ AI | Golden eval cố định và so baseline; chỉ chạy khi có quyền API |

Chạy ít nhất 3 lượt độc lập cho mỗi nhiệm vụ/biến thể, đổi thứ tự baseline/đối chứng
để giảm ảnh hưởng cache; ghi cả run thất bại, bỏ dở và BLOCKED. Ba lượt chỉ là mức
khởi đầu mô tả, không đủ tự nhận ý nghĩa thống kê. Reviewer dùng cùng oracle cho
cả hai biến thể và phân loại reject: defect có căn cứ / thiếu evidence / thiếu input.

## Bản ghi mỗi run và tiêu chí công bố

Ghi task ID, attempt ID, biến thể, SHA, model/version, config/toolchain, trạng thái
PASS/FAIL/BLOCKED, AC đạt/chưa đạt, link evidence/CI, latency, số bàn giao, retry,
reject và nguyên nhân. `telemetry-record/2` tách attempt khỏi accepted work; chi phí
cộng cả lần thất bại. token input/output lấy từ usage thật; thiếu thì **unknown**,
không gán 0 và không đổi byte/LOC thành token. Giá ước tính tách khỏi hóa đơn.

So median/range latency và tổng usage của **công việc được nghiệm thu**, đồng thời
báo tỷ lệ hoàn tất và mọi failure; không chỉ chọn run xanh. Chỉ công bố tiết kiệm
model khi có usage đầy đủ và cùng AC đạt, kèm cỡ mẫu/giới hạn. Nếu quyền, toolchain
hoặc input không tương đương, ghi không so được thay vì gộp số.

Pilot sản phẩm thật, hosted CI dự án đích và benchmark model thật **chưa chạy**.
Chúng cần repo đích được chủ repo chọn và quyền riêng; không thuộc quyền production
của goal hiện tại. Xem lại khi có repo đích/usage và ngân sách được duyệt. Goal này
nghiệm thu khả năng kiểm thử và protocol; không nghiệm thu các kết quả chưa đo.
