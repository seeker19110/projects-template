# PROGRESS.md — Trạng thái dự án

> Goal giữ phạm vi; Issue/PR/CI giữ kết quả thực thi theo commit. Không suy ra
> đã merge, đã nghiệm thu hoặc đã deploy từ trạng thái trong tài liệu.

## Giai đoạn hiện tại

- Giai đoạn: GĐ 4–5 (Build/Verify). Chu kỳ tối ưu quy trình 2026-10-08: O-0..O-4a đã merge ở #218 (sửa đệ quy gate, hook cứng hơn, gỡ trùng lặp, căn tài liệu); O-4b đã merge ở #219 (một nguồn guard bí mật/1 MB, `finish`/`declared_cmd` dùng chung, test telemetry trên bản tạm) — chu kỳ đóng; O-5/O-6 giữ kế hoạch kèm điều kiện xem lại. Chu kỳ hoàn thiện (W-01 #216, W-02 #217) COMPLETE, goal `docs/goals/2026-10-08-framework-completion.md` đã đóng.
- Giai đoạn trước đó: snapshot trước PR #179 được giữ nguyên trong `docs/changelog/0002-2026-09-25-progress-before-runtime-safety.md` (chỉ là lịch sử).
- Default-branch SHA đã đối chiếu: `0eeede6` (`origin/main`, sau PR #219).
- Ngày cập nhật: 2026-10-08

## Goal đã nghiệm thu

`docs/goals/2026-10-07-lean-delivery.md`, spec đã được chủ repo duyệt ngày
2026-10-07; LD-01..08 đã Complete theo ủy quyền quyết định của chủ repo trong cuộc trò chuyện
ngày 2026-10-07. Issue #198 và hồ sơ nghiệm thu giữ các PR/CI cùng giới hạn chưa kiểm chứng.

## Đang làm / chờ

**Không có hồ sơ đang mở.** Chu kỳ tối ưu quy trình 2026-10-08 COMPLETE: O-0..O-4a
`docs/work/2026-10-08-process-optimization/done.md` (#218), O-4b
`docs/work/2026-10-08-process-optimization-o4b/done.md` (#219); báo cáo
`docs/reports/2026-10-08-process-optimization.md` (O-5/O-6 chưa làm, có điều kiện xem lại).

Chu kỳ FC-2026-10-08 COMPLETE: `docs/work/2026-10-08-framework-completion/done.md`
(W-01 `…-format/done.md` #216, W-02 `…-wip/done.md` #217); báo cáo
`docs/reports/2026-10-08-framework-completion.md`.

Hồ sơ cũ: `docs/work/2026-10-07-pr-dispatch-work-memory/done.md` (#213),
`docs/work/2026-10-08-gate-evidence-write/done.md` (#214) và
`docs/work/2026-10-08-completion-closeout/done.md` (#215). Các PR đã MERGED và CI xanh;
checkpoint sau merge #215 được tích hợp cùng PR của chu kỳ mới theo contract §3e.

**Ngữ cảnh chung (2026-10-07):** chủ repo yêu cầu trần 500.000 token cho mọi phiên,
mọi nhà cung cấp và subagent; checkpoint/nén trước 450.000 hoặc thấp hơn theo cửa sổ model.
Luật ở `CLAUDE.md` §2 / `AGENTS.md`; Claude Code và Codex đã có cấu hình repo.
JSON/TOML và cổng docs đã kiểm; chưa kiểm chứng phiên Claude/Hermes/Gemini/OpenCode/Cursor/Copilot
thật trên máy này. Runner chưa có cổng tự động tuân thủ checkpoint/chuyển phiên;
chi tiết ở `docs/framework/models-and-automation.md` §5.2.1.

**Ủy quyền toàn cục (2026-10-07):** chủ repo yêu cầu phiên chính luôn tự chọn phương án
tối giản nhất vẫn đạt chất lượng cao nhất có thể: ít code, bảo mật, khoa học, logic,
ít bảo trì, TDD. Đã nâng thành luật chung của template ở `CLAUDE.md` §2 / `AGENTS.md`
và `docs/framework/standard-delivery.md` §3d, áp mọi phiên/nhà cung cấp/agent.
Phiên chính tự quyết và nghiệm thu trong phạm vi đã giao, ghi căn cứ; không hỏi lại
quyết định đã được ủy quyền. Mọi cổng chất lượng và scope/budget vẫn được giữ.

LD-01 (CI parity, mỗi suite Linux chạy đúng một lần) đã merge ở #200.
LD-03 (evidence gắn HEAD/config/working tree, `evidence-check`, chặn no-op/0 ca test,
C-4 + `--trace` nối AC tới bằng chứng) đã merge ở #204.
LD-02 (mức quy trình S/M/L theo rủi ro — `standard-delivery.md` §3c, spec gọn mức M,
agent chính tự làm, 3 tầng tùy chọn cho mức L, ADR-0010) đã merge ở #203; AC-2 nối tới
`tests/test_adaptive_process.py`. TRAPS mục 48 (commit do công cụ sinh làm đỏ `metadata`)
đi PR riêng vì đẩy sau khi #203 đã merge.
LD-04 (`dev-task.sh review-check`, `review-findings/1`: finding không căn cứ bị loại, thiếu
evidence/input không sinh yêu cầu sửa code; ca jq CRLF của Windows) đã merge ở #205.
LD-07 (telemetry `telemetry-record/2`: token thiếu = unknown, lần thử ≠ công việc nghiệm thu,
chi phí gồm cả lần thất bại) đã merge ở #207.
LD-05 (`subagent-dispatch` prepare-only, context thiếu/rỗng/không UTF-8/quá lớn → exit 2) đã merge ở #208.
LD-06 (#209) đã merge ở `fb05bd5`: ma trận bằng chứng hồ sơ C1–C10 × hành vi/UX-DX/
dữ liệu/bảo mật/release và độ sâu S/M/L; `tests/test_profile_quality_matrix.py`, CI Linux/Windows xanh.
Blocker tạo PR GitHub đã được xử lý sau khi chủ repo cho phép thử lại; không hạ cổng.
LD-08 (#210) đã merge ở `2b927e6`, bổ sung `tests/test_lean_adoption.py`: Node/Python runtime thật, copy → evidence → upgrade
bảo toàn config/ghi chú → từ chối evidence cũ và FAIL. Test đăng ký ở gate cục bộ và CI Linux.
`docs/framework/lean-delivery-benchmark.md` đo baseline 17 suite/34 lời gọi so với 17/17 ở c522839;
đây là giảm lời gọi, không phải số đo tiết kiệm token/thời gian. AC-1..8 đã có ánh xạ evidence;
map đầy đủ không thay thế kết quả CI của đúng commit. Required checks Linux/Windows của #210
đã xanh trước merge; pilot/hosted CI dự án đích/model benchmark chưa chạy, ngoài scope hiện tại.
Kế hoạch hoàn thiện khung trước đó đã có hồ sơ ở PR #197; phần nghiệm thu cũ
không được tự thay đổi bởi việc bắt đầu goal mới.

Đã merge #199: đối chiếu X-Agents lần 2 và chu kỳ hoàn thiện 2026-10-06
(radar, FEATURE-MAP↔scripts, specs, concurrency). Báo cáo `docs/reports/2026-10-06-framework-audit.md`; F-N05: chủ repo chọn giữ lại 3 nhánh remote (ghi nhận).

PR #180 đã merge (`071faea`), bổ sung gate fail-closed, doctor và test Node thật.
Các PR #188–195 đã sửa ruleset strict, môi trường Git của hook, báo cáo secret,
ignore môi trường, nhận diện manifest lồng, probe coverage, quét đa stack và
CI mẫu cho dự án đích. #185 đồng bộ CodeQL/grouping; #186 trùng đã đóng.
F-01..10 và F-K01..07/F-K09/F-K10 có regression và CI trên main.
#196 sửa lint nuốt lỗi; sau sửa fixture Windows, head `8b97ee6` đạt các cổng
bắt buộc trên Linux/Windows. Bản đồ F-11/F-K08, re-audit và ma trận bằng chứng
được bàn giao trong PR tài liệu này. Không phát hiện Cao/Trung mới trong phạm vi
code/cổng đã rà; đây không phải chứng nhận không có lỗi trên mọi dự án dẫn xuất.

## Tiếp theo

Chu kỳ tối ưu quy trình đã đóng. Mở chu kỳ mới (O-5: dời dò stack, rút tài liệu; O-6: copy manifest,
gộp parser) chỉ khi chạm điều kiện xem lại trong report (thêm/bớt file khung, gate > 15 phút) hoặc chủ repo yêu cầu.
Goal LD-01..08 và FC-2026-10-08 giữ nguyên Complete. Pilot/hosted CI dự án đích/model
benchmark thuộc phạm vi riêng và vẫn chưa được kiểm chứng.
