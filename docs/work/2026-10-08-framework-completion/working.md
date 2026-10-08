# Công việc: kiểm chứng và hoàn thiện toàn bộ bộ khung

- Work ID: 2026-10-08-framework-completion
- Yêu cầu / outcome: hoàn thiện toàn bộ dự án khung; rà năng lực thật, sửa thiếu sót có bằng chứng, hội tụ qua cổng và CI.
- Trạng thái: Active.
- Chủ trì / writer: phiên chính.
- Mức rủi ro / số PR: mục tiêu nhiều PR (L), hai đơn vị sửa lỗi S; không thêm tính năng nên không mở feature spec mới.
- Scope: installer, engine, hook, quality gate, CI, tài liệu và hồ sơ của chính khung.
- Non-goal: sản phẩm giả, production, API/model trả phí, xoá các nhánh chủ repo đã chọn giữ, thay stack hoặc hạ cổng.
- Spec / goal: docs/goals/2026-10-08-framework-completion.md; kế thừa các contract đã Approved, không mở lại goal LD đã Complete. Feature mới nếu cần phải có spec Approved trước source.
- Nhánh / base: codex/framework-completion-2026-10-08 / 6c3e3ce0fb7e236704d86fbf654b93046dbbffbb; reconcile 2026-10-08.

## Kế hoạch và phân công

1. Đối chiếu 12 nhóm theo năng lực khung, cổng đang chạy, các hồ sơ done và GitHub hiện tại.
2. Chạy full gate, maintenance/radar, kiểm smoke và live CI/ruleset; đọc code ở biên tin cậy và đường lỗi.
3. Ghi phát hiện và kế hoạch vào báo cáo chu kỳ mới; phiên chính review/duyệt theo contract §3d. Bug phải test đỏ trước sửa.
4. Sửa tối thiểu, cập nhật tài liệu cùng PR; review diff, format, full gate, PR đủ template và CI. Chỉ nghiệm thu sau bằng chứng thực tế.

Hai outcome/PR, thực thi tuần tự vì cùng sửa test runtime và tài liệu:

- W-01: subagent format_safety, sửa truyền đường dẫn vào shell ở format-file và shared Python venv resolver; phạm vi source/test/CODEMAP/TRAPS và hồ sơ đơn vị format. Phiên chính giữ report/goal/PROGRESS.
- W-02: subagent wip_policy, chỉ thực thi sau W-01 merge và reconcile main; sửa WIP của metadata để đếm mọi PR mở, kể cả draft/bot. Phạm vi workflow/test/CODEMAP/TRAPS và hồ sơ đơn vị wip.
- Subagent dùng model của phiên được runtime cung cấp, không đổi provider/model hoặc gọi CLI/API khác; không giả chạy model Claude ghi trong frontmatter của vai tham chiếu. Phiên chính review/tích hợp và chạy full gate. Tối đa hai worker đã được giao, không giao agent lồng.

## Quyết định và bằng chứng

- Đã đọc CLAUDE, Standard Delivery Contract, PROJECT (mẫu có chủ đích), PROGRESS, các hồ sơ done #213/#214/#215, goal LD và kế hoạch/audit cũ.
- GitHub: 0 PR mở, 0 issue mở; default branch đúng base. CI, CodeQL, Secret scan, Scorecard của base SUCCESS (CI run 37703734395).
- Giữ nguyên checkpoint staged từ #215 (PROGRESS và rename done); không discard, không push main.
- Scope là năng lực của bộ khung, không audit UI/API/DB chưa tồn tại. Quyết định kỹ thuật và kế hoạch trong scope duyệt theo ủy quyền 2026-10-07.
- python3 -m venv không tạo được pip vì host thiếu ensurepip; chuyển sang uv venv /tmp/framework-completion-20261008-ci và uv pip install đúng dependency CI đã ghim. Không thêm dependency repo.
- Baseline full gate trên cây checkpoint tại base: exit 0, build/static/lint/test đủ; 17 shell suite, 5 Python suite trực tiếp; coverage engine 96%, sàn 95%. Log /tmp/framework-completion-20261008-baseline-gate.log đã đọc đầy đủ.
- pip-audit strict qua PyPI trên 5 gói của môi trường CI (gồm transitive): exit 0, không có lỗ hổng đã biết; JSON /tmp/framework-completion-20261008-dependency-audit.json.
- Ruleset live 23113200 active, không bypass, yêu cầu gate/metadata và nhánh cập nhật; main CI đủ 7 job SUCCESS. PR #215 MERGED và SHA khớp checkpoint cũ.
- Ba phát hiện đã tái hiện từ source thật: format filename thực thi touch ngoài ý muốn (F-C01); WIP không đếm draft/bypass draft-bot (F-C02); venv trong root có khoảng trắng không chạy được (F-C03). Kế hoạch và DoC: docs/reports/2026-10-08-framework-completion.md, phiên chính duyệt theo ủy quyền trước sửa source.
- W-01: đã đọc diff source/test, log đỏ đầy đủ (25 failure format, một failure venv/lint 127). Phiên chính chạy lại runtime safety sau sửa: 16/16 xanh, không skip/error; log /tmp/framework-completion-W01-parent-runtime.log. Shared helper chỉ ảnh hưởng lựa chọn venv của dev-task; maintenance-sweep hiện không gọi py_tool.
- W-01 full gate --evidence exit 0; evidence-check VERIFIED trên cây staged tại base. Log /tmp/framework-completion-W01-gate.log, JSON /tmp/framework-completion-W01-gate.json. Đối chiếu toàn bộ output với baseline (chỉ chuẩn hoá thư mục fixture/thời gian): thêm ca Windows venv, 6 runtime method, tỷ lệ tài liệu và fingerprint; không failure mới. 17 shell suite/5 Python suite đủ, coverage 96%. Bản ghi này cập nhật sau phép đo nên evidence cũ không đại diện cho tài liệu mới; hook Git sẽ chạy lại cổng trước commit, CI kiểm đúng head.

## Lần thử / blocker

Hai đơn vị sửa ba phát hiện trên; baseline cổng xanh không chứng minh các ca chưa có test. Pilot thật, hosted CI repo đích và runtime mọi provider vẫn chưa được kiểm chứng; không dùng fixture để đóng chúng.

## Bàn giao / bước tiếp theo

W-01 test đỏ trước sửa, review diff của worker và full gate; mở PR đủ template, auto-merge theo quyền/quy tắc repo. W-02 chờ W-01 tích hợp.

## Nghiệm thu cuối

Chưa nghiệm thu; giữ working.md đến khi DoD và merge thật đạt.
