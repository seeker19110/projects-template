# Goal: Lean delivery, ít điều phối và chất lượng có bằng chứng

| Thuộc tính | Giá trị |
| --- | --- |
| Goal ID | LD-2026-10 |
| Owner | Chủ repo |
| State | ACTIVE |
| Default-branch SHA đã reconcile | e2b70bffd8f6adadd14b96b31d7b0ab62f63cc61 |
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
phạm vi/phụ thuộc, không sao chép trạng thái từng run. Hiện đang triển khai; chưa
có benchmark model thật hoặc pilot sản phẩm. Phê duyệt triển khai không phải UAT.

## Risk register

Tối giản nhầm thành giảm cổng: giữ test âm tính, required checks và các ngưỡng.
Trạng thái cũ: đọc Git/CI, không tin checkpoint một mình. Thêm công cụ quá mức:
dùng lại điểm vào và cơ chế hiện có; mọi helper phải giải quyết lỗi đo được.
