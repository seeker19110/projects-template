# Lean delivery — bằng chứng nghiệm thu triển khai (2026-10-07)

## Phạm vi và trạng thái

Goal `docs/goals/2026-10-07-lean-delivery.md`, issue #198, spec Approved ngày
2026-10-07. LD-01..08 đã tích hợp qua #200, #203, #204, #205, #208, #209,
#207 và #210. Snapshot main khi quyết định nghiệm thu: `47b691fed67aa5aa24deb4259dd0a3f4672bf6ad` (sau #211).
Goal LD-01..08 được nghiệm thu kỹ thuật theo ủy quyền chủ repo ngày 2026-10-07.
Việc triển khai đã Complete; các kết quả sản phẩm/model ngoài scope vẫn chưa nghiệm thu.

Đây là nghiệm thu triển khai **repo khung**. Không phải nghiệm thu sản phẩm đích,
pilot thật, hosted CI dự án đích, hiệu quả model hay production.

## AC → hành vi và bằng chứng

| AC | Hành vi chứng minh | Cổng/test trên snapshot |
| --- | --- | --- |
| AC-1 | Giữ 17 suite Linux, mỗi suite một lời gọi; local gate đầy đủ | `tests/test_ci_suite_parity.py`, 4/4; Windows portability vẫn chạy |
| AC-2 | Quy trình S/M/L, spec gọn có approval, agent chính được code; quyền riêng | `tests/test_adaptive_process.py`, 8/8 |
| AC-3 | Reject evidence cũ/FAIL, no-op và zero-test; map gãy/thiếu AC chặn completion | `scripts/test-dev-task.sh`, `scripts/test-next-gen-engines.sh`, `tests/test_acceptance_trace.py` qua coverage suite |
| AC-4 | Review finding có vị trí/kịch bản/evidence; thiếu input/evidence không tự yêu cầu sửa code | `scripts/test-dev-task.sh` review_tests, gồm jq CRLF |
| AC-5 | Prepare-only; context thiếu/rỗng/hỏng/quá lớn bị từ chối, không thực thi agent | `tests/engine_characterization/test_dispatch.py` qua 42 characterization tests |
| AC-6 | C1–C10 đủ hành vi/UX-DX/dữ liệu/bảo mật/release và độ sâu S/M/L; ma trận gãy bị bắt | `tests/test_profile_quality_matrix.py`, 3/3 |
| AC-7 | Usage thiếu là unknown; attempt khác accepted work; cộng cả chi phí lần thất bại | `tests/test_telemetry_integrity.py`, 15/15; `scripts/test-hooks-session.sh` |
| AC-8 | Node/Python runtime thật, upgrade giữ config/ghi chú, evidence cũ/FAIL bị từ chối; giới hạn benchmark rõ | `tests/test_lean_adoption.py`, 2/2; `docs/reports/2026-10-07-lean-delivery-benchmark.md` |

`spec-compiler.sh --trace docs/specs/2026-10-07-lean-delivery.md`: AC-1..8 MAPPED,
TRACE COMPLETE. Đây là kiểm ánh xạ tồn tại; kết quả thực thi nằm ở gate/CI bên dưới.

## Validation và guardrails

Local head triển khai LD-08 `03458b6200fea3350c825d7b2c3552d988558ad2`:
full `dev-task.sh gate` exit 0, PASS 4 kiểm tra; hook pre-commit chạy lại và xanh.
Build/cú pháp, static complexity, ShellCheck và docs/CI consistency đạt. 17 shell
suite + runtime safety 10/10 + các test trực tiếp ở bảng trên đều xanh.
Coverage dòng 5 engine 96% (sàn 95%); CC Python/hàm shell ≤12, thân shell ≤45.
`format-file` không có formatter phù hợp và báo skip; `git diff --check` sạch.

Red-before LD-08: trên parent fb05bd5, 2 test chạy; fixture runtime xanh, protocol
thiếu gây 1 error. Sau thêm protocol/registration: 2/2. Full gate đầu tiên đỏ do
file mới chưa stage bị loại khỏi fixture tracked-file; stage đúng diff rồi chạy
lại toàn bộ, không đổi hay skip test. Không thêm code engine/runtime/dependency.

PR [#209](https://github.com/seeker19110/projects-template/pull/209) và
[#210](https://github.com/seeker19110/projects-template/pull/210): required checks
Linux/Windows và aggregate gate xanh trước merge, cùng metadata, secret scan,
dependency-review và CodeQL; không có review/comment chưa giải quyết tại lúc kiểm.
`progress-freshness` skip trên PR theo thiết kế (chạy trên main), không gọi là pass.
Ruleset main active, protection-guard xanh; không push trực tiếp main/bypass hook.

Maintenance `--strict --no-deps` trên head LD-08: exit 0, 0 đỏ, 1 vàng về hai nhánh
local cũ đã merge; giữ lại vì không ảnh hưởng triển khai. Dependency audit không
chạy trong lượt quét này. Không diễn giải radar thành đánh giá kiến trúc tổng quát.

## Số đo và giới hạn nghiệm thu

Baseline e2b70bf: 17 suite/34 lời gọi Linux; đối chứng c522839: 17/17.
Giảm 50% **lời gọi**, không chứng minh tiết kiệm thời gian/token. Protocol benchmark
khai cùng input/AC/toolchain/model/budget, run cô lập, ghi cả thất bại và usage thật.
Token/chi phí model/latency/retry/reject vẫn **unknown**. Không gọi API trả phí.

Pilot sản phẩm, hosted CI dự án đích và benchmark model nằm ngoài scope này;
xem lại khi chủ repo chọn repo đích và cấp quyền/ngân sách riêng. Không giảm sàn
coverage, complexity, security, branch protection hoặc quyền nghiệm thu/deploy.
Rollback: revert PR gây regression qua PR mới và full gate, không xóa dữ liệu đích.

## Quyết định nghiệm thu theo ủy quyền

Ngày 2026-10-07, sau khi nhận hồ sơ, chủ repo giao quyền: “chọn theo hướng tốt nhất cho chất lượng cho tôi từ giờ trở đi, không cần hỏi”.
AI quyết định nghiệm thu phạm vi triển khai LD-01..08 dựa trên AC/evidence ở trên,
CI xanh trên main `47b691f` (sau #211), và giữ mọi giới hạn chưa đo. Không ghi đây
là UAT sản phẩm do người dùng thực hiện. Quyền này áp repo hiện tại; không sửa
luật/cổng template dùng chung hoặc mở phạm vi production/model API.
