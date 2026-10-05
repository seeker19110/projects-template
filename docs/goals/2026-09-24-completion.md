# Hoàn thiện bộ khung — 2026-09-24

## Contract và quyền thực thi

Người dùng duyệt inventory ngày 2026-09-24 và tiếp tục yêu cầu nâng cấp ưu tiên
chất lượng, ủy quyền quyết định ngày 2026-09-25. Phạm vi repo khung này; không tự
triển khai vào repo dẫn xuất hoặc dữ liệu production, không hạ cổng để xanh.

State: WAITING. Main nguồn đã đối chiếu: `6702994d90ad318142715aa172d79916c71e5b9d` (PR #196).
PR #196 đã merge sau CI trên head `8b97ee6`; F-K10 đóng. F-11/F-K08 và re-audit
được bàn giao trong PR tài liệu này, có hiệu lực khi bản này vào main và cổng PR đạt.
Mỗi outcome một PR, FIFO, tối đa 3 PR mở. Xác nhận đóng chu kỳ còn chờ người dùng.

## Công việc và bằng chứng

| ID | Outcome | State | Nghiệm thu |
| --- | --- | --- | --- |
| W-01 | Dependency #169 | DONE, merged | #169 → `b80e611`; required CI/CodeQL/dependency-review/secret/metadata checks SUCCESS |
| W-02 | Fixture/spec và adapter UI #177 | DONE, merged | #177 → `f3f29ef`; PF-2/spec regression và adapter opt-in; Linux/Windows, docs, copy smoke, gate, metadata/security checks SUCCESS |
| W-03 | Telemetry integrity/concurrency/duration #178 | DONE, merged | #178 → `23accce`; corruption/concurrent-write/duration regressions; CI Linux/Windows, copy smoke, gate, metadata/security checks SUCCESS |
| W-04 | CLI, lease, local work, upgrade safety #179 | DONE, merged | #179 → `8cba0e0`; 10 runtime tests (45 CLI subcases), lease/local-work/merge safety; CI Linux/Windows, copy smoke, gate, metadata/security checks SUCCESS |
| W-05 | Gate thực, trạng thái/quy ước, re-audit | DONE khi reconciliation này merge | #180 → `071faea`; strict gate/doctor, negative cases, real Node fixture, Linux/Windows CI SUCCESS. F-11/re-audit được bàn giao trong tài liệu này |
| W-06 | Bản đồ tính năng, coverage claims và F-11 | Bàn giao trong PR này | `FEATURE-MAP.md` đã được đối chiếu với file thật; coverage matrix phân biệt resolver fixtures, Node/Python runtime smoke và hosted CI chưa có. Cổng PR tài liệu xác minh bản bàn giao |
| W-07 | Re-audit 12 nhóm và nghiệm thu goal | WAITING | Re-audit ngày 2026-10-05 và bảng F-K01..10 đã ghi; F-K01..07/F-K09/F-K10 đóng trên main; F-K08/F-11 theo PR tài liệu này. Không tuyên bố Project Complete |

## Đối chiếu phát hiện với bằng chứng trên main

Snapshot lịch sử đầu lượt 2026-10-05: PR #180/#181/#183/#184/#185/#187 đều MERGED; main khi đó là
`9d2882a7a5bfe9f81500851623490db2a49a3473`. Kết quả CI dưới đây thuộc đúng các PR/head đã nêu,
không phải lần chạy local mới trong checkpoint này.

| Finding | Kết cục trên main | Regression / bằng chứng | Trạng thái |
| --- | --- | --- | --- |
| F-01 — fixture PF-2 sửa dòng tùy chọn không tồn tại | Sửa fixture trong #177 | `scripts/test-check-scripts.sh`; #177 Linux/Windows framework-lint, docs-consistency, copy smoke, metadata và các check bắt buộc SUCCESS | CLOSED |
| F-02 — spec thiếu mã yêu cầu | Bổ sung FR/AC metadata trong #177 | `scripts/test-next-gen-engines.sh` contract positive/negative; #177 checks như trên SUCCESS | CLOSED |
| F-03 — metadata / trạng thái spec không đáng tin | Kiểm State được chọn và fixture characterization trong #181 | `scripts/test-engine-characterization.sh`; 21 integrity tests tại #181; CI run 36250649109 SUCCESS (progress-freshness SKIPPED theo điều kiện main-only) | CLOSED |
| F-04 — JSON telemetry hỏng có thể mất dữ liệu cũ | Atomic write/error preservation trong #178 | `tests/test_telemetry_integrity.py`; PR report ghi các ca corruption/replace lỗi đỏ trước sửa; #178 Linux/Windows CI và required checks SUCCESS | CLOSED |
| F-05 — writer đồng thời làm mất cập nhật | Khóa transaction telemetry trong #178 | `tests/test_telemetry_integrity.py` concurrent writers; #178 CI SUCCESS | CLOSED |
| F-06 — thời lượng hook sai đơn vị | Truyền elapsed seconds đúng vào `duration_sec` trong #178 | `scripts/test-hooks-session.sh`, ca 12 phút = 720 giây; #178 CI SUCCESS | CLOSED |
| F-07 — retry/fetch làm mới lease và ghi đè báo cáo đồng thời | Expected SHA bất biến trong #179 | `tests/test_runtime_safety.py` concurrent remote report / stale lease; 10 bài, CI Linux/Windows SUCCESS | CLOSED |
| F-08 — thiếu giá trị CLI gây treo | Validate argv trước side effect trong #179 | `tests/test_runtime_safety.py`, 45 subcase CLI; timeout regression được nêu trong PR #179; CI SUCCESS | CLOSED |
| F-09 — fatal merge bị coi là thành công hoặc làm hỏng đích | Merge trên bản tạm, giữ file/stamp khi lỗi trong #179 | `tests/test_runtime_safety.py` fatal exit 255, conflict và giữ bytes; CI SUCCESS | CLOSED |
| F-10 — local gate no-op vẫn xanh | Fail-closed preflight, doctor READY khác PASS trong #180 | `scripts/test-dev-task.sh` negative contract + real Node fixture đỏ/xanh; CI run 36086495638: Linux/Windows, copy smoke, docs, protection, gate, metadata/security SUCCESS | CLOSED |
| F-11 — bản đồ tính năng và tiến độ lỗi thời | Reconciliation trong PR tài liệu này | Đếm file thật: 16 command, 11 agent, 9 hook, 9 workflow; 13 Markdown template + 1 CI. Đã rà giới hạn runtime/fixture và evidence ledger; CI của PR này xác minh diff | CLOSED khi bản này vào main |

Không đóng phát hiện chưa có bằng chứng hoặc lẫn với phạm vi mở rộng.

## Re-audit 2026-10-05 và phạm vi nghiệm thu

Re-audit 12 nhóm và phát hiện F-K01..10 được ghi trong
`docs/reports/2026-10-05-framework-audit.md`. F-K01..07 và F-K09 đã có kết cục trên main;
F-K08/F-11 trong bản bàn giao này; F-K10 đã đóng ở PR #196. Ma trận W-06 ghi rõ coverage resolver, Node/Python fixture
runtime và CI hosted của dự án đích chưa có bằng chứng. Residual C01 (adoption trên
sản phẩm thật), hosted CI/coverage cho stack ngoài fixture, và thực thi PLAN ba tầng
đầu-cuối còn mở với điều kiện quay lại trong báo cáo audit.

## Definition of Complete

Mỗi F-01..11 có kết cục và regression phù hợp; gate local chạy kiểm thực;
CI Linux/Windows, copy smoke, metadata và required checks xanh; code/docs khớp;
re-audit giới hạn/phát hiện còn lại được ghi; main chứa các PR nghiệm thu. Trạng thái
hiện tại là WAITING: nguồn đã merge và bản đồ/re-audit
được bàn giao ở PR này; cần người dùng xác nhận đóng theo Pha 4 của contract.
Không suy ra toàn sản phẩm hay mọi repo dẫn xuất hoàn thiện từ goal giới hạn này.

## Checkpoint

W-04 đã merge, không còn chờ CI/merge. Báo cáo:
`docs/reports/2026-09-25-runtime-safety.md`.
W-05 spec: `docs/specs/2026-09-25-strict-gate-contract.md`.
Trên bản gốc, test mới có 21 assertion failures (bao gồm kiểm trạng thái mới);
sau sửa, các ca resolver cũ và ca contract mới xanh cục bộ. Doctor chặn đúng
môi trường thiếu ShellCheck. Root contract đầy đủ phải nghiệm thu trên CI,
không được ghi PASS chỉ vì tool chẩn đoán trả READY.

W-05 #180 merged ngày 2026-09-25 (`071faea`); #181 (`f42bb5f`) và #183 (`f31c912`)
cập nhật handoff/progress; #184 (`a8dbd44`) cập nhật CodeQL upload-sarif; #185
(`8f4a181`) đồng bộ hai bước CodeQL và nhóm Dependabot. CI #184 run
36474637374 xanh trên Linux/Windows, docs, copy smoke, protection, gate, CodeQL,
dependency-review, secret scan và metadata; progress-freshness SKIPPED theo điều kiện.
PR #188 (`bec5795`) đóng F-K06; #189 (`4b51643`) đóng F-K09; #190 (`54425a2`)
đóng F-K01; #191 (`0ddb4e8`) đóng F-K04; #192 (`b368f7e`) đóng F-K02;
#193 (`6bfbb3a`) đóng F-K05; #194 (`4bf9504`) đóng F-K03; #195 (`430b4b9`)
đưa CI drop-in runnable, nhưng không nghiệm thu hosted CI trên dự án đích.
F-K07 đã đóng ở #185 (`8f4a181`). PR #196 đã merge (`6702994`); head `8b97ee6` đạt CI run 37323540706
trên Linux/Windows, docs/copy/protection/gate và các check security/metadata.
Reconciliation docs/F-11 nằm trong PR tài liệu này. Progress-freshness là main-only, nên kết quả
SKIPPED trên PR không được tính như PASS.

## Phạm vi mở rộng chưa tự động đóng

C01 adoption đầu-cuối trên sản phẩm thật và C02 đầy đủ mọi CI drop-in vẫn mở.
Hook fail-open khi thiếu jq, native PowerShell upgrade, chứng thực phê duyệt spec,
evidence schema theo AC và UX thực tế không được coi là hoàn tất bởi PR #180.
Xem `docs/framework/strict-gate-contract.md` và `PROGRESS.md`.
