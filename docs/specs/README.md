# docs/specs — Feature Spec (contract từng tính năng)

> Thư mục **bắt buộc tồn tại**: cổng `pr-policy.yml` yêu cầu mọi PR `feat` liên kết tới một file
> `docs/specs/<YYYY-MM-DD>-<slug>.md` đã ghi **Approved for implementation** (kèm người duyệt + ngày).
> Luật gốc: `docs/framework/standard-delivery.md` §2–§3 và `CLAUDE.md` mục 2.

## Cách dùng
1. Copy `docs/framework/templates/FEATURE-SPEC.template.md` thành `docs/specs/<ngày>-<slug>.md`.
2. Điền research + contract của tính năng; **chưa Approved thì chưa được sửa source code.**
3. Người duyệt ghi rõ `Approved for implementation` + tên + ngày, rồi mới mở PR `feat`.

Goal nhiều PR dùng `docs/goals/` (mẫu `docs/framework/templates/GOAL.template.md`).

## Ba vai của spec trong vòng đời (Spec-Driven Development) — khung thực thi ở đâu

Từ vựng chung của SDD (bản đối chiếu `docs/reports/2026-10-10-doi-chieu-sdd-ba-vai.md`) ánh xạ vào **cổng đang chạy**, không chỉ văn xuôi:

| Vai | Nghĩa | Cổng/engine của khung (chạy ở cả repo khung lẫn dự án đích) |
| --- | --- | --- |
| **Spec-First** | quyết định xây gì trước khi code | `pr-policy.yml`: PR/commit `feat` phải trỏ spec **Approved for implementation** (soi cả tiêu đề commit); mức S/M/L ở `standard-delivery.md` §3c; `/contract` chốt DDL/API trong spec trước khi code |
| **Spec-Anchored** | spec là mốc đối chiếu khi triển khai và sau đó | contract C-1..C-4 (`scripts/spec-compiler.sh --compile-all`): touchpoint §11 và bằng chứng AC (`path::ký hiệu`) phải còn tồn tại — chạy mỗi PR (job `framework-lint` ở khung; bước "Spec contracts" trong `ci.yml` phát cho đích); `--trace <spec>` phải TRACE COMPLETE trước khi `/gate` đánh ✅ tiêu chí chấp nhận |
| **Spec-as-Source** | spec sinh ra thứ dẫn dắt việc làm (plan, task, test) | AC → bảng bằng chứng → test đỏ-trước (ADR-0005), contract test sinh từ spec (`_spec_contract_gen.py`, chứng minh đỏ được), brief `PLAN.template.md` qua `subagent-dispatch.sh --check-plan`, hồ sơ `docs/work/<id>/` |

Khung **không** sinh test hành vi tự động từ spec (audit 2026-09-13: 82/82 assertion hằng đúng là tệ hơn không có test) và **không** bắt
mọi `fix`/`refactor` sau này quay lại sửa spec cũ: spec là hợp đồng theo thời điểm duyệt (không sửa lịch sử); bản đồ sống của code là
`CODEMAP.md`/`docs/FEATURE-MAP.md`, còn bằng chứng AC gắn vào test — đổi hành vi thì test đỏ, đổi tên test thì C-4 đỏ.
