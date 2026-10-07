# Goal: Lean delivery, ít điều phối và chất lượng có bằng chứng

| Thuộc tính | Giá trị |
| --- | --- |
| Goal ID | LD-2026-10 |
| Owner | Chủ repo |
| State | WAITING |
| Default-branch SHA đã reconcile | 2b927e6c1ae36452739eb966ce49e8a23a8e7d8d |
| Bắt đầu / review | 2026-10-07 |
| Quyền AI | branch / PR / kiểm thử / merge khi cổng xanh; không production |
| Budget | Không gọi model/API trả phí; không đổi provider mặc định |

## Outcome và Goal DoD

Một mục tiêu được giao một lần; quy trình và context gọn, bằng chứng hành vi rõ,
không giảm sàn chất lượng. AC-1..AC-8 trong spec phải có bằng chứng phù hợp. Không
claim toàn bộ goal hoàn tất từ một PR hoặc fixture. So sánh hiệu quả cần baseline.

## Scope / non-goals

Nâng projects-template theo spec `docs/specs/2026-10-07-lean-delivery.md`.
Không nhập X-Agents runtime, không thêm scheduler, không rollout repo sản phẩm.

## Milestones và slices

| ID | Outcome | Phụ thuộc |
| --- | --- | --- |
| LD-01 | CI parity, không chạy suite Linux hai lần | baseline |
| LD-02 | Quy trình thích ứng và agent chính trực tiếp | LD-01 |
| LD-03 | Nghiệm thu AC/evidence, bằng chứng đúng phiên bản | LD-02 |
| LD-04 | Review có căn cứ, repair đúng nguyên nhân | LD-02 |
| LD-05 | Context gọn, capability harness không bị nói quá | LD-02 |
| LD-06 | Chất lượng sản phẩm theo profile và rủi ro | LD-02 |
| LD-07 | Telemetry task/attempt/outcome, usage unknown | LD-03 |
| LD-08 | Adoption regression và protocol benchmark | các slice trên |

## Current truth

Issue #198 là sổ liên kết PR, kết quả CI và khoản chưa thực hiện. Goal này giữ
phạm vi/phụ thuộc, không sao chép trạng thái từng run. LD-01..08 đã merge; bằng chứng ở
`docs/reports/2026-10-07-lean-delivery-acceptance.md`. Chờ chủ repo nghiệm thu; chưa
có benchmark model thật hoặc pilot sản phẩm. Phê duyệt triển khai không phải UAT.

## Risk register

Tối giản nhầm thành giảm cổng: giữ test âm tính, required checks và các ngưỡng.
Trạng thái cũ: đọc Git/CI, không tin checkpoint một mình. Thêm công cụ quá mức:
dùng lại điểm vào và cơ chế hiện có; mọi helper phải giải quyết lỗi đo được.

## Checkpoint 2026-10-07 — LD-08 verification và nghiệm thu

Đã reconcile main `2b927e6`: LD-01..08 đã merge (#210 là slice cuối); LD-06 ở #209 có required checks
Linux/Windows xanh. Blocker tạo PR (3 lỗi dịch vụ) đã được chủ repo cho phép thử
lại khi GitHub hoạt động; REST tạo #209 thành công, không bypass hook/ruleset.

LD-08 có regression Node/Python runtime thật và protocol ở
`docs/framework/lean-delivery-benchmark.md`. AC-1..8 nối tới test hiện hữu trong spec;
trace đầy đủ là ánh xạ, không tự chứng minh hành vi. Required checks Linux/Windows
và gate của #210 đã xanh trước merge. Hồ sơ
`docs/reports/2026-10-07-lean-delivery-acceptance.md` ghi AC/evidence và giới hạn;
chờ chủ repo xác nhận nghiệm thu. Không gọi goal Complete trước quyết định đó.

Protocol đo 17 suite/34 lời gọi baseline so với 17/17 ở c522839. Không suy ra token
hay latency từ lời gọi suite. Pilot sản phẩm, hosted CI dự án đích, benchmark model
và usage thật chưa chạy; ngoài scope triển khai hiện tại, giữ unknown đến khi có
repo đích/quyền/ngân sách riêng. Không gọi API trả phí hoặc tự triển khai production.
