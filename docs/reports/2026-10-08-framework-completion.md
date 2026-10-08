# Hoàn thiện bộ khung — chu kỳ 2026-10-08

## Phạm vi và baseline

Yêu cầu: hoàn thiện toàn bộ dự án khung. Chủ thể là năng lực tài liệu/script/agent/
CI của template; PROJECT.md và CLAUDE.md §10 giữ mẫu dành cho dự án đích có chủ đích.
Base 6c3e3ce0fb7e236704d86fbf654b93046dbbffbb, PR #215 đã MERGED.
Không mở lại các chu kỳ/goal đã đóng; giữ checkpoint sau merge chưa commit.

Full scripts/dev-task.sh gate tại baseline trả 0: build, static analysis, lint và
test đủ; 17 shell suite, 5 Python suite trực tiếp; coverage engine 96% (sàn 95%).
Log cục bộ /tmp/framework-completion-20261008-baseline-gate.log đã đọc đầy đủ;
kết quả này chưa chứng minh các ca lỗi mới chưa có test. Main CI run 37703734395
đủ 7 job SUCCESS; CodeQL, Secret scan và Scorecard của đúng base SUCCESS.

## Đối chiếu 12 nhóm

| Nhóm | Phạm vi/kiểm chứng | Kết quả baseline |
| --- | --- | --- |
| 1 Kiến trúc | ADR/contract, installer hai lớp, shared resolver, engine prepare-only | Không thêm abstraction; F-C03 tại shared resolver |
| 2 Bảo mật | Đường dẫn qua shell, CLI input, handoff giới hạn/path escape, Git lease và secret scan | F-C01 Cao; hành vi filename có thể chạy shell |
| 3 Logic | Lựa chọn formatter/venv, trạng thái evidence, WIP, đường lỗi installer/cron | F-C02/F-C03 Trung |
| 4 Test | Full gate, negative tests, Python coverage | Xanh; bổ sung regression cho các phát hiện mới |
| 5 Hiệu năng | CLI hữu hạn/khóa/prepare-only, complexity gates | Không có UI/CWV; không đặt mục tiêu latency suy đoán |
| 6 A11y/UI | Không có app/UI; tài liệu/profile chứa cổng cho đích | N/A cho runtime khung, không giả axe/UAT |
| 7 Dependency | 5 gói môi trường CI; pip-audit strict PyPI, action SHA và dependency-review | Audit 0 lỗ hổng đã biết; không suy ra an toàn tuyệt đối |
| 8 CI/vận hành | Live ruleset active/no bypass, strict gate+metadata, CI Linux/Windows | Main xanh; F-C02 cổng WIP lệch luật |
| 9 Tài liệu | docs-consistency, FEATURE-MAP/CODEMAP/spec/work/progress | Cổng xanh; ghi chu kỳ mới thay vì sửa lịch sử |
| 10 Dữ liệu | Bảo toàn file đích/manifest, telemetry khóa+atomic replace, handoff bounded | Runtime safety baseline xanh; không có DB/migration production |
| 11 Cấu hình | Config tin cậy, ignore biến thể môi trường, không đọc file bí mật | Cổng xanh; giữ ranh giới command config khác filename |
| 12 Thống nhất | Bash/PowerShell copy, shared stack resolver, luật WIP và workflow thật | F-C02/F-C03; bản copy/gate Node/Python xanh |

## Phát hiện và kế hoạch trước source

| ID | Mức | Bằng chứng tái hiện | Việc / acceptance |
| --- | --- | --- | --- |
| F-C01 | Cao | format-file ghép filename vào bash -c; fixture npx nhận sai tên và sentinel từ command substitution được tạo dù exit 0 | W-01: path là một argv literal; mọi formatter/template hỗ trợ không thực thi ký tự shell; test đỏ trước sửa |
| F-C02 | Trung | JS thật của metadata với 3 draft khác + PR hiện tại (4 mở) sinh 0 failure; draft/bot hiện tại còn return trước WIP | W-02: tổng 3 xanh/4 đỏ, kể cả draft/bot; miễn trừ metadata vẫn đúng; test đỏ trước sửa |
| F-C03 | Trung | Root có khoảng trắng + .venv/bin/ruff; lint exit 127, tool không chạy do executable path không quote | W-01: shared py_tool trả command prefix shell-escaped; root có khoảng trắng/ký tự shell gọi đúng tool, không side effect |

**Approved for implementation — phiên chính duyệt theo ủy quyền của chủ repo
ngày 2026-10-07; ngày duyệt thực tế 2026-10-08.** Hai PR sửa lỗi S, không feature
mới; goal FC-2026-10-08 nối hai outcome. W-01 giao format_safety, W-02 giao
wip_policy sau W-01 merge vì chung test/tài liệu. Phiên chính review, chạy gate và
CI, nghiệm thu; không giả test của worker thành bằng chứng đã tích hợp.

## Definition of Complete của chu kỳ

1. F-C01/F-C02/F-C03 được sửa với test đỏ-trước/xanh-sau ở lại trong CI.
2. Required CI của từng PR và full gate trên default branch xanh; không bypass,
   không nới ngưỡng, không push main.
3. Re-audit 12 nhóm: không có Cao/Trung mở; mọi khoản còn lại có quyết định/phạm vi.
4. Docs, ownership, rollout/rollback và hồ sơ work khớp Git/PR/merge thật.

## Giới hạn được ghi nhận

- Radar baseline 99/100 là điểm kỷ luật, không chứng nhận kiến trúc/bảo mật. Bốn
  file mã >400 dòng vẫn có complexity gates và test; chưa tách khi chưa có bằng
  chứng giảm lỗi/chi phí. Xem lại khi thay đổi cần ranh giới module rõ hơn.
- Maintenance --strict --no-deps: 0 đỏ, 2 vàng (việc chưa commit và nhánh local đã
  merge). Không xoá nhánh/checkout của phiên khác để làm đẹp báo cáo. Dependency
  được kiểm riêng bằng pip-audit, không lấy --no-deps làm bằng chứng sạch.
- Pilot sản phẩm thật, hosted CI repo đích/toàn bộ stack, benchmark model và cưỡng
  chế ngữ cảnh runtime mọi provider vẫn unknown; cần repo/quyền/ngân sách riêng.
  Native PowerShell upgrade chưa hỗ trợ, dùng Bash theo contract hiện có.
- Config formatter vẫn là shell tin cậy của dự án; bản sửa không sandbox config.
  WIP check chặn integration khi vượt trần, không thể chặn tạo PR bằng GitHub UI.

## Thực thi và nghiệm thu

W-01 giữ filename ngoài shell source qua positional parameter; py_tool shell-escape
executable venv bằng printf %q. Không thêm dependency/abstraction; trusted command
config vẫn thực thi, missing tool/formatter failure vẫn best-effort. Template hỗ
trợ placeholder độc lập {}, "{}", '{}'; leading dash được chuyển thành ./filename.

TDD: format regression trên source cũ có 25 failure trong 5 phương thức; venv
regression exit 1 do lint 127. Sau sửa, phiên chính chạy lại
python3 tests/test_runtime_safety.py: 16/16 xanh, không error/skip; log
/tmp/framework-completion-W01-parent-runtime.log. Log đỏ:
/tmp/framework-completion-W01-format-red.log và /tmp/framework-completion-W01-venv-red.log.
Code diff đã đọc; test kiểm argv/sentinel thật, không chỉ exit 0.

W-01 full gate --evidence exit 0, evidence-check VERIFIED trước cập nhật bản ghi:
17 shell suite/5 Python suite trực tiếp, runtime 16/16, coverage 96%, lint 0 cảnh báo.
Log /tmp/framework-completion-W01-gate.log; output đối chiếu đầy đủ với baseline,
chỉ khác các ca mới, tỷ lệ tài liệu, fingerprint và dữ liệu động của fixture/thời gian.
Hook Git và CI sẽ kiểm lại bản tích hợp sau cập nhật tài liệu.

W-01 đã MERGED qua [PR #216](https://github.com/seeker19110/projects-template/pull/216)
lúc 2026-10-08T05:07:05Z, SHA d7aca5d37ddd55df7672cbe66470a086d7101794. Head
0fca909 đã có CI 37730273965: Linux/Windows/gate/docs/copy/protection SUCCESS,
progress-freshness SKIPPED theo main-only; metadata/security đều SUCCESS. Không có
review thread; tree head/main trùng nhau. Hồ sơ đơn vị:
`docs/work/2026-10-08-framework-completion-format/done.md`.

F-C01/F-C03 đóng trên default branch; còn F-C02 (Trung) đang thực thi W-02.
Main CI d7aca5d run 37730770082 đã SUCCESS đủ 7 job, gồm progress-freshness.
Đã đọc log bước Runtime safety Windows thật của #216: 16/16, không skip/error.

W-02 giữ trần ba, chuyển đếm mọi PR khác trước return draft/bot; không đếm lại PR
hiện tại. Test dùng Node thực thi JS thật của workflow với API/core fixture offline,
không viết lại luật đếm trong test. TDD: 18 subcase, 13 failure trước source; sau
sửa phiên chính chạy runtime 17/17 xanh, không skip/error. Log đỏ
/tmp/framework-completion-W02-wip-red.log; log recheck của phiên chính
/tmp/framework-completion-W02-parent-runtime.log. Title/body/feature metadata và
miễn trừ dưới trần có ca bảo vệ riêng.

Re-audit candidate 12 nhóm: F-C01/F-C03 đã đóng trên main, F-C02 sửa trên nhánh
W-02 nhưng còn chờ tích hợp; chưa có Cao/Trung mới trong phần đã rà. Radar vẫn
99/100, 39/39 script có cổng và 22/22 spec đạt tín hiệu đo. File runtime test mới
vượt 400 dòng (năm file mã vượt mốc heuristic); giữ chung suite đang có để giảm
wiring/fixture trùng, có DEBT ngay header. Xem lại khi thêm nhóm hành vi mới hoặc
fixture bắt đầu phân kỳ; đây là giới hạn bảo trì được ghi nhận, không nới cổng.

W-02 full gate --evidence exit 0 và evidence-check VERIFIED trước cập nhật bản ghi:
17 shell suite/5 Python suite trực tiếp, runtime 17/17, coverage 96%, lint 0 cảnh báo.
Maintenance --strict --no-deps sau gate: 0 đỏ/2 vàng về Git (đang sửa 12 file và hai
nhánh local cũ); hai DEBT đều có điều kiện xem lại, docs/CI-policy/action pin sạch.
Dependency được audit riêng ở baseline và không đổi trong hai PR. Hook Git kiểm
lại sau cập nhật tài liệu; W-02 chờ CI/merge và nghiệm thu default branch cuối.
W-02 đã MERGED qua [PR #217](https://github.com/seeker19110/projects-template/pull/217)
lúc 2026-10-08T05:42:38Z, SHA 6643f4e52b0a0ca09e8ccee06ff4188ee4cda1a3 (head f9eb2f8).
Main 6643f4e: CI run 37733742238 SUCCESS; CodeQL, Secret scan, Scorecard, Release SUCCESS;
0 PR mở, không review thread. Hồ sơ đơn vị: `docs/work/2026-10-08-framework-completion-wip/done.md`.

Re-audit cuối 2026-10-08 trên 6643f4e: F-C01/F-C02/F-C03 đóng trên default branch;
radar 99/100 (5 file mã > 400 dòng, không đổi); maintenance --strict --no-deps 🔴 0 · 🟡 0.
Không có Cao/Trung mở. **Chu kỳ COMPLETE** theo DoC 1–4; giới hạn ở mục trên giữ nguyên.
Chu kỳ kế tiếp (tối ưu quy trình, không đổi hành vi):
`docs/reports/2026-10-08-process-optimization.md`.
