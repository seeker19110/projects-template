# Feature spec: script tạo hồ sơ công việc tự động

| Thuộc tính | Giá trị |
| --- | --- |
| Issue / Goal | Yêu cầu chủ repo 2026-10-09: "thêm script tạo hồ sơ công việc tự động"; hồ sơ `docs/work/2026-10-09-new-work-script/working.md` |
| Spec owner | Phiên chính |
| State | **Approved for implementation** |
| Approver / date | Phiên chính duyệt theo ủy quyền toàn cục (`standard-delivery.md` §3d); 2026-10-09 |
| Last updated | 2026-10-09 |

> Spec gọn (mức M): một PR, không đổi schema/API công khai/auth.

## 1. Problem, user và evidence

Từ #244, mọi PR phải ghi `Work ID:` trỏ tới `docs/work/<id>/` có thật, và `check-docs-consistency.sh` mục 13 đòi
thư mục đúng khuôn `YYYY-MM-DD-slug` với đúng một file trạng thái. Hồ sơ vẫn phải tạo tay: chép
`WORK.template.md`, tự đặt ngày, tự điền nhánh/SHA. Lỗi khuôn tên, quên điền ID hoặc dùng lại ID (TRAPS 60) chỉ
lộ ra ở CI — muộn hơn lúc cần.

## 2. Outcome, baseline, target và guardrails

- Baseline: 0 lệnh tạo hồ sơ; mọi trường điền tay.
- Target: `bash scripts/new-work.sh <slug> ["tên công việc"]` sinh hồ sơ hợp lệ với cổng mục 13 trong một lệnh.
- Guardrails: không ghi đè hồ sơ có sẵn; không thêm dependency; chạy được trên Linux và Git Bash (Windows);
  CC hàm ≤ 12 và thân script ≤ 45 như mọi script.

## 5. Scope / non-goals

Trong: `scripts/new-work.sh`, `scripts/test-new-work.sh`, đăng ký CI + manifest copy sang đích, con trỏ ở
`standard-delivery.md` §3e, `CLAUDE.md` §2, `AGENTS.md`, CODEMAP, FEATURE-MAP. Ngoài: đóng hồ sơ (rename
`done.md` cần bằng chứng merge thật — giữ thủ công); sinh hồ sơ đơn vị của subagent (dùng cùng lệnh với slug riêng).

## 9. Acceptance criteria

- AC-1: Slug hợp lệ → thoát 0, tạo `docs/work/<ngày UTC>-<slug>/working.md` từ mẫu với tiêu đề, `Work ID`,
  `Trạng thái: Planned`, nhánh và SHA hiện tại; in đường dẫn.
- AC-2: Work ID đã tồn tại → thoát 1, hồ sơ cũ không đổi.
- AC-3: Slug sai khuôn (chữ hoa, `/`, `..`, rỗng), `WORK_DATE` sai khuôn hoặc tên có xuống dòng → thoát 2, không tạo gì.
- AC-4: Thiếu mẫu hoặc mẫu không còn dòng `Work ID:` → thoát 2, không để lại thư mục.
- AC-5: Tên công việc chứa ký tự đặc biệt (`&`, `\`, `/`) được giữ nguyên văn.

| AC | Bằng chứng |
| --- | --- |
| AC-1 | `scripts/test-new-work.sh` ca "slug hợp lệ" |
| AC-2 | `scripts/test-new-work.sh` ca "Work ID đã tồn tại" |
| AC-3 | `scripts/test-new-work.sh` ca "slug sai", "WORK_DATE sai", "tên nhiều dòng" |
| AC-4 | `scripts/test-new-work.sh` ca "thiếu mẫu", "mẫu lệch" |
| AC-5 | `scripts/test-new-work.sh` ca "ký tự đặc biệt" |

## 11. Architecture và code touchpoints

- `scripts/new-work.sh` (mới): kiểm đầu vào → dựng ID → từ chối nếu tồn tại → `awk` thay 4 dòng đầu mẫu (đọc giá
  trị qua `ENVIRON`, không qua `-v`, để `\` không bị diễn giải) → kiểm lại dòng `Work ID` rồi mới giữ file.
- `scripts/test-new-work.sh` (mới): fixture git tạm, không chạm repo thật.
- `.github/workflows/ci.yml` (step trong `framework-lint`), `copy-framework.manifest` `[scripts]`, `CODEMAP.md`,
  `docs/FEATURE-MAP.md` (FT-73), `docs/framework/standard-delivery.md` §3e, `CLAUDE.md` §2, `AGENTS.md`.

## Approval

Approved for implementation — phiên chính duyệt theo ủy quyền chủ repo ngày 2026-10-09; một PR, không hạ cổng.
