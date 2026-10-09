# PROGRESS.md — Trạng thái dự án

> Goal giữ phạm vi; Issue/PR/CI giữ kết quả thực thi theo commit. Không suy ra
> đã merge, đã nghiệm thu hoặc đã deploy từ trạng thái trong tài liệu.

## Giai đoạn hiện tại

- Giai đoạn: GĐ 4–5 (Build/Verify). Tối ưu quy trình phân chia việc 2026-10-09 COMPLETE (#239): cổng `subagent-dispatch.sh --check-plan` + mẫu `PLAN.template.md` khoá brief trước khi dispatch (TRAPS 59; `docs/work/2026-10-09-plan-check-gate/done.md`). `/auto-complete` 2026-10-09: lệnh nối `/auto` → `/completion`, phiên chính tự quyết theo thang ưu tiên §3d (hồ sơ `docs/work/2026-10-09-auto-complete/working.md`). Dọn radar 2026-10-09: tách `test-dev-task.sh` (430 dòng) → `test-dev-task.sh` + `test-dev-task-evidence.sh` + `_dev-task-test-lib.sh`, 119 ca giữ nguyên, radar hết "Việc cần làm". Vòng hoàn thiện trên dự án đích thật 2026-10-09 COMPLETE (#235): T-01/T-02 (Pha 0→4 `/completion` trên fixture Node/vitest, 2 Cao sửa TDD, re-audit Cao/Trung 0), F-T01/S-05 #234 (lỗi khung lộ ra), T-03 closeout (Luồng chính 5 + FT-01 → ✅ có giới hạn; TRAPS 58 cổng độ dài tiêu đề commit). Đợt nghiệm thu agent 2026-10-09 COMPLETE: A-01 #231 (trần subagent 3→5, ADR-0011), A-02 #232 (F-309b từ phát hiện của reviewer/security-reviewer thật), A-03 closeout (FEATURE-MAP cột Test FT-13..20 có kết cục; phát hiện subagent Claude Code không tạo agent lồng → Tầng 2 = phiên chính). Đợt finishing 2026-10-09 COMPLETE: R-01 #227 (tách engine Python ra helper), R-02 #228 (tách hai suite test; radar 100/100, 0 file > 400 dòng), R-03 #229 (F-309 sửa có test đỏ-trước, cột Trạng thái FEATURE-MAP hết ⚠️, benchmark dời `docs/reports/`). Chu kỳ hoàn thiện phần còn lại 2026-10-09 COMPLETE: W-01 #224 (khối required checks phát cho đích khớp `ci-target.yml`; vitest drop-in xanh trên fixture đích), W-02 #225 (docs-consistency mục 12 mẫu mồ côi; test hook session-guide/auto-format). Chu kỳ tối ưu quy trình 2026-10-08 COMPLETE: O-0..O-4a #218, O-4b #219, O-5 #221 (dời dò stack sang `_stack-detect.sh`, tài liệu lặp → con trỏ, CLAUDE.md −6,9 KB), O-6 #222 (một manifest cho hai script copy; P-B11/P-C12 quyết không làm kèm điều kiện xem lại). Chu kỳ hoàn thiện (W-01 #216, W-02 #217) COMPLETE, goal `docs/goals/2026-10-08-framework-completion.md` đã đóng.
- Giai đoạn trước đó: snapshot trước PR #179 được giữ nguyên trong `docs/changelog/0002-2026-09-25-progress-before-runtime-safety.md` (chỉ là lịch sử).
- Default-branch SHA đã đối chiếu: `9561889` (`origin/main`, sau PR #239).
- Ngày cập nhật: 2026-10-09

## Goal đã nghiệm thu

`docs/goals/2026-10-07-lean-delivery.md`, spec đã được chủ repo duyệt ngày
2026-10-07; LD-01..08 đã Complete theo ủy quyền quyết định của chủ repo trong cuộc trò chuyện
ngày 2026-10-07. Issue #198 và hồ sơ nghiệm thu giữ các PR/CI cùng giới hạn chưa kiểm chứng.

## Đang làm / chờ

**Đang mở:** `docs/work/2026-10-09-auto-complete/working.md` — `/auto-complete` + thang ưu tiên §3d (spec `docs/specs/2026-10-09-auto-complete.md`, mức M, 1 PR; nhánh `claude/kind-cori-k7x4p6`). Đã đóng cùng ngày: `docs/work/2026-10-09-plan-check-gate/done.md` (#239).

Vòng hoàn thiện trên dự án đích thật 2026-10-09 COMPLETE: `docs/work/2026-10-09-target-completion/done.md`
(T-01/T-02 sandbox đích, F-T01/S-05 #234, T-03 closeout); báo cáo `docs/reports/2026-10-09-target-completion.md`. Đợt nghiệm thu agent 2026-10-09 COMPLETE: `docs/work/2026-10-09-agent-acceptance/done.md` (A-01 #231,
A-02 #232, A-03 closeout); báo cáo `docs/reports/2026-10-09-agent-acceptance.md`. Đợt finishing 2026-10-09 COMPLETE: `docs/work/2026-10-09-finishing/done.md` (R-01 #227, R-02 #228,
R-03 #229); báo cáo `docs/reports/2026-10-09-finishing.md`. Chu kỳ hoàn thiện 2026-10-09 COMPLETE: `docs/work/2026-10-09-completion-remaining/done.md`
(W-01 #224, W-02 #225); báo cáo `docs/reports/2026-10-09-completion-remaining.md`; kế hoạch/DoC ở `docs/ops/COMPLETION-PLAN.md`.

Chu kỳ tối ưu quy trình 2026-10-08 COMPLETE: O-0..O-4a
`docs/work/2026-10-08-process-optimization/done.md` (#218), O-4b `docs/work/2026-10-08-process-optimization-o4b/done.md`
(#219), O-5 `docs/work/2026-10-08-process-optimization-o5/done.md` (#221), O-6
`docs/work/2026-10-08-process-optimization-o6/done.md` (#222); báo cáo `docs/reports/2026-10-08-process-optimization.md`.

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
`docs/reports/2026-10-07-lean-delivery-benchmark.md` đo baseline 17 suite/34 lời gọi so với 17/17 ở c522839;
đây là giảm lời gọi, không phải số đo tiết kiệm token/thời gian. AC-1..8 đã có ánh xạ evidence;
map đầy đủ không thay thế kết quả CI của đúng commit. Required checks Linux/Windows của #210
đã xanh trước merge; pilot/hosted CI dự án đích/model benchmark chưa chạy, ngoài scope hiện tại.
Kế hoạch hoàn thiện khung trước đó đã có hồ sơ ở PR #197; phần nghiệm thu cũ
không được tự thay đổi bởi việc bắt đầu goal mới.

Đã merge #199: đối chiếu X-Agents lần 2 và chu kỳ hoàn thiện 2026-10-06
(radar, FEATURE-MAP↔scripts, specs, concurrency). Báo cáo `docs/reports/2026-10-06-framework-audit.md`; F-N05: chủ repo chọn giữ lại 3 nhánh remote (2026-10-07), rồi tự xoá 7 nhánh tồn đọng 2026-10-09 — remote chỉ còn `main`, ĐÓNG.

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

Đợt nghiệm thu agent 2026-10-09 đã đóng: FT-13..20 cột Test có kết cục (nghiệm thu phiên thật, không test tự động; xem lại khi sửa `.claude/agents/*.md`); FT-13 ⚠️ vì coordinator-như-subagent không chạy được trong Claude Code (Tầng 2 = phiên chính). Đợt finishing 2026-10-09 đã đóng: radar 100/100 (0 file mã > 400 dòng), cột Trạng thái FEATURE-MAP hết ⚠️/❌ (cột Test còn ❌ ở FT-41 cần tài khoản thật), P-C12 xong (benchmark ở
`docs/reports/2026-10-07-lean-delivery-benchmark.md`). Repo không còn mục nào tự đánh dấu "phải làm" kiểm được ở đây. Việc còn lại
KHÔNG làm được ở phiên này (cần repo đích/tài khoản/harness thật): hosted CI của một repo đích, pilot sản phẩm, benchmark model,
phiên thật Codex/Gemini/OpenCode/Cursor/Copilot — mở khi chủ repo cấp môi trường. P-B11 giữ không làm (lý do kỹ thuật).
Chu kỳ tối ưu quy trình 2026-10-08 đã đóng hoàn toàn (O-0..O-6). Các hạng mục không làm (P-B11: gộp parser transcript /
cổng CP-6 / fixture adoption; P-C12: không copy tài liệu nội bộ) có điều kiện xem lại ghi trong report (parser thứ ba,
gate > 15 phút, file nội bộ thứ hai) — không mở chu kỳ mới nếu chưa chạm hoặc chủ repo chưa yêu cầu.
Goal LD-01..08 và FC-2026-10-08 giữ nguyên Complete. Pilot/hosted CI dự án đích/model
benchmark thuộc phạm vi riêng và vẫn chưa được kiểm chứng.
