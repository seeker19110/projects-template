# Feature spec: Lean delivery, chất lượng có bằng chứng

| Thuộc tính | Giá trị |
| --- | --- |
| Issue / Goal | #198; docs/goals/2026-10-07-lean-delivery.md |
| Spec owner | Chủ repo |
| State | Approved for implementation |
| Approver / date | Chủ repo, cuộc trò chuyện 2026-10-07 |
| Last updated | 2026-10-07 |

Phê duyệt gốc: “duyệt, triên khai tích hợp luôn cho tôi”, sau bản nghiên cứu hai repo.
Đây là phê duyệt triển khai, không phải bằng chứng kiểm thử hoặc quyền production.

## 1. Problem, user và evidence

Chủ repo phản ánh X-Agents tốn token, reject nhiều, chậm và hay lỗi. Template cần
học kỷ luật bằng chứng/phục hồi, không nhập runtime công ty AI. Baseline là
`e2b70bffd8f6adadd14b96b31d7b0ab62f63cc61` của projects-template.

## 2. Outcome, baseline, target và guardrails

Giảm thao tác và chuyển giao thừa; tăng nghiệm thu theo hành vi. Không hạ coverage,
complexity, security, branch protection hoặc quyền phê duyệt. Không hứa tỷ lệ tiết
kiệm trước benchmark. Ở baseline, 17 suite Linux vừa được gọi riêng vừa qua gate.

## 3. Research current state

Đã đọc standard-delivery, orchestration, dev-task, dispatcher, telemetry, compiler,
CI, negative tests và adapter handoff hiện hữu. X-Agents có execution/evidence/
retry nhưng không đưa bus, daemon, gateway hoặc scheduler vào template.

## 4. Alternatives và decision

Giữ nguyên: tiếp tục chi phí chuyển giao và kiểm thử trùng. Nhập X-Agents: tăng
độ phức tạp và vận hành. Chọn nâng những điểm chạm hiện có, agent chính trực tiếp,
worker theo nhu cầu, kiểm chứng bằng công cụ, integration X-Agents vẫn opt-in.

## 5. Scope / non-goals

LD-01 CI parity; LD-02 quy trình theo rủi ro; LD-03 AC/evidence; LD-04 review/repair;
LD-05 context/harness capability; LD-06 chất lượng sản phẩm; LD-07 telemetry;
LD-08 regression adoption và protocol benchmark. Không sửa repo sản phẩm, gọi API
trả phí, đổi provider mặc định hoặc triển khai production. Pilot ứng dụng thật
và benchmark model cần bằng chứng riêng, không được đóng bằng fixture.

## 6. User journeys và mọi state

Yêu cầu đã duyệt → thực hiện trực tiếp hoặc tách phần độc lập → kiểm tra → PR/CI.
Thiếu bằng chứng khác với lỗi code. Khi gián đoạn, đối chiếu Git/CI rồi tiếp tục
phần còn lại; khi vượt quyền hoặc ngân sách, giữ thay đổi và ghi blocker cụ thể.

## 7. Functional requirements

FR-1 Giữ mọi kiểm tra khi giảm chạy lặp. FR-2 Một nguồn quy trình, một agent chính.
FR-3 Gắn AC với bằng chứng đúng phiên bản; không tin lời PASS tự khai.
FR-4 Không đọc context thừa, không tuyên bố dispatcher thực thi quyền mà nó không có.
FR-5 Chi phí của công việc gồm cả lần thất bại; dữ liệu thiếu là unknown.

## 8. Non-functional requirements

Không thêm runtime service hoặc dependency thư viện mới cho các chức năng trên.
Giữ tương thích CLI khi có thể; thay đổi dữ liệu/luật có phiên bản và hướng nâng cấp.
Không đưa secrets/PII vào telemetry, prompt handoff hay artifact bàn giao.

## 9. Acceptance criteria

AC-1 CI Linux gọi đủ mọi shell suite đúng một lần; local gate vẫn đủ; Windows giữ.
AC-2 Spec gọn vẫn có approval/AC; agent chính được code; quyền merge/deploy riêng.
AC-3 Không gọi report cũ, thiếu AC hoặc zero-test là nghiệm thu hành vi thành công.
AC-4 Finding có bằng chứng; thiếu input không mặc định yêu cầu viết lại code.
AC-5 Dispatcher nói rõ prepare-only, context thiếu/quá giới hạn không bị bỏ im lặng.
AC-6 Profile sản phẩm nêu cách chứng minh hành vi, UX, dữ liệu, bảo mật, release.
AC-7 Không biến usage thiếu thành 0; phân biệt lần thử với công việc được nghiệm thu.
AC-8 Test adoption/benchmark nói rõ fixture, hosted CI và sản phẩm thật khác nhau.

## 10. Design và UX

Giữ lệnh hiện có; tài liệu cốt lõi làm bản đồ, đọc chi tiết khi cần. Báo cáo kết quả
nêu đạt/chưa đạt/bằng chứng/việc tiếp theo, không buộc người dùng vận hành nhiều agent.

## 11. Architecture và code touchpoints

`.github/workflows/ci.yml`, `.claude/project-commands.sh`, `tests/test_ci_suite_parity.py`,
`CLAUDE.md`, `AGENTS.md`, `docs/framework/standard-delivery.md`,
`docs/framework/orchestration-3-tier.md`, `scripts/dev-task.sh`,
`scripts/subagent-dispatch.py`, `scripts/telemetry-log.py`, `scripts/spec-compiler.py`,
`docs/framework/quality-gates-by-profile.md`, `copy-framework.sh`, `copy-framework.ps1`.
Các helper/test mới sẽ được khai trong slice triển khai tương ứng, không hứa sẵn có.

## 12. Test và evidence

Bản đồ dưới khai **cái gì chứng minh** từng AC (`spec-compiler.sh --trace`, C-4); kết quả chạy
của đúng commit nằm ở CI và `dev-task.sh evidence-check`, không chép vào spec. "chưa có" là trạng thái
thật: AC đó chưa được gọi là đạt.

| AC | Bằng chứng | Ghi chú |
| --- | --- | --- |
| AC-1 | `tests/test_ci_suite_parity.py::test_every_linux_suite_runs_exactly_once` | LD-01, #200; full local gate và CI |
| AC-2 | chưa có — LD-02 (#203 mang test hợp đồng quy trình) | cập nhật khi #203 vào main |
| AC-3 | `scripts/test-dev-task.sh::evidence_tests`, `scripts/test-dev-task.sh::noop_tests`, `scripts/test-next-gen-engines.sh::c4_case`, `tests/test_acceptance_trace.py::test_every_gap_is_reported_and_blocks_completion` | LD-03; đỏ trước, xanh sau |
| AC-4 | `scripts/test-dev-task.sh::review_tests` | LD-04; `dev-task.sh review-check`: finding không căn cứ bị loại, thiếu evidence/input không sinh REPAIR-CODE |
| AC-5 | chưa có — LD-05 | |
| AC-6 | chưa có — LD-06 | |
| AC-7 | chưa có — LD-07 | |
| AC-8 | chưa có — LD-08 | |

Issue #198 giữ các link PR/CI và phần chưa kiểm; không nhân bản kết quả CI trong spec.

## 13. Rollout và rollback

Nhánh → PR nhỏ → required checks xanh → squash merge. Không bypass ruleset.
Revert PR cụ thể khi có regression; không xóa thay đổi của dự án đích để quay lui.

## 14. Budget, ownership và completion

Giới hạn model thật: không gọi trong triển khai khung. Không dùng số test hoặc LOC
làm thước đo năng suất. Goal chỉ Complete khi đủ AC và bằng chứng; pilot/benchmark
chưa chạy phải ghi rõ chứ không suy ra từ unit test.
