# CONVENTIONS — Sổ quy ước (bộ khung project-template)

> Mỗi pattern lặp lại có MỘT cách đúng duy nhất. Tính năng mới & mọi lần sửa phải đối chiếu.
> Lệch quy ước = phát hiện Nhóm 12 khi audit. Đổi quy ước lớn → ghi ADR.
>
> **Chủ thể:** repo này LÀ bộ khung — "pattern" ở đây là pattern **viết tài liệu, script, lệnh,
> subagent, cổng CI** của chính khung, không phải pattern app (validate/API/UI — những cái đó là
> nội dung khung *dạy dự án đích*, nằm ở `CLAUDE.md` §3 và `quality-supplements.md`).
> Lập bằng cách đọc file thật trong repo.

## A. Quy ước shell script

| Pattern | Cách đúng duy nhất | File ví dụ chuẩn | Ghi chú |
|---------|--------------------|------------------|---------|
| Chế độ nghiêm — script **cổng** (được phép fail cả lượt) | `set -euo pipefail` | `scripts/check-docs-consistency.sh` | Đỏ là phải dừng ngay, đó là mục đích tồn tại |
| Chế độ nghiêm — **hook** + script tiện ích (không được cản phiên) | `set -uo pipefail` (**cố ý không `-e`**) + luôn `exit 0` | `.claude/hooks/auto-format.sh` | ⚠️ quy ước này **đang ngầm** — xem mục "cần hợp nhất" |
| Header script | Khối `#` mở đầu: *script làm gì* → **VÌ SAO TỒN TẠI** → cách chạy | `scripts/check-ci-policy.sh` (dòng 2–20) | Rất mạnh: mọi script cổng đều giải thích lỗ hổng nó chặn |
| Không phụ thuộc stack | Mọi lệnh stack đi qua `scripts/dev-task.sh` | `.claude/hooks/pre-commit-gate.sh` | Vì khung hỗ trợ mọi loại dự án (§0b) |
| Bản Windows | Mỗi script người dùng chạy có cặp `.sh` + `.ps1`; `.ps1` dùng `$ErrorActionPreference='Stop'` | `copy-framework.sh` / `.ps1` | Chỉ áp cho `copy-framework`; script cổng nội bộ không cần |
| Kiểm CẤU TRÚC, không kiểm nội dung | Script cổng chỉ đối chiếu *có khớp danh sách/tồn tại không*, không ép nội dung từng bước | `scripts/check-ci-policy.sh` dòng 12–14 | Tránh biến cổng thành vật cản mỗi lần thêm bước mới |
| Mọi assertion mới có **negative test** | Thêm một kiểm mới → chứng minh nó **bắt được** vi phạm (cố tình làm sai, thấy đỏ) | `scripts/test-copy-framework.sh` | Ghi bằng chứng ở PR |
| Phục hồi file trong negative test | `cp` từ bản sao ở scratchpad — **KHÔNG** `git checkout/restore <file>` (xoá luôn sửa chưa commit, xem `TRAPS.md` mục 6b) | — | Bẫy đã mắc thật — xem `TRAPS.md` |

## B. Quy ước tài liệu

| Pattern | Cách đúng duy nhất | File ví dụ chuẩn | Ghi chú |
|---------|--------------------|------------------|---------|
| Tên file | **tiếng Anh, kebab-case**; nội dung **tiếng Việt** | `docs/framework/*.md` | Bản đồ tên cũ→mới ở `docs/framework/README.md` |
| Đường dẫn trong tài liệu | luôn trong backtick, phải **tồn tại thật** | mọi file | Cưỡng chế bằng `check-docs-consistency.sh` §1 |
| Mục lục tài liệu | Một nguồn duy nhất: `CLAUDE.md` §1 | `CLAUDE.md` | Mỗi file `docs/framework/` phải được §1 trỏ tới |
| Khai báo kích hoạt lệnh | Mỗi lệnh có dòng **`TRIGGER:`** trong `CLAUDE.md` §1 | `CLAUDE.md` §1 | Cưỡng chế 2 chiều bằng `check-docs-consistency.sh` §3 |
| Giới hạn độ dài | `CLAUDE.md` < 200 dòng; chi tiết đẩy xuống `docs/framework/` | `CLAUDE.md` dòng 5 | |
| Nguồn sự thật trạng thái | `PROGRESS.md` (giai đoạn), `COMPLETION-PLAN.md` (kế hoạch), `COMPREHENSIVE-AUDIT-STATUS.md` (quét) — **không chép lẫn nhau** | `CLAUDE.md` §10 | Chống lệch giữa 2 chỗ |
| Bản mẫu | Không chép tay từ tài liệu — copy file trong `docs/framework/templates/` | `project-completion.md` mục cuối | |

## C. Quy ước slash command & subagent

| Pattern | Cách đúng duy nhất | File ví dụ chuẩn | Ghi chú |
|---------|--------------------|------------------|---------|
| Frontmatter lệnh | `---` + chỉ `description:` (một dòng, tiếng Việt) | `.claude/commands/gate.md` | 12/12 lệnh đều có |
| Frontmatter subagent | `name:` + `description:` dạng `>-`, nêu **TẦNG**, model, GIAO khi nào, **KHÔNG làm gì** | `.claude/agents/lookup.md` | 8/8 agent đều có |
| Thân lệnh | Trỏ sang tài liệu chi tiết, **không nhân bản** nội dung tài liệu | `.claude/commands/gate.md` | Một nguồn sự thật |
| Ranh giới quyền | Worker không commit/merge; coordinator không code; chỉ phiên chính quyết kiến trúc | `.claude/agents/coordinator.md` | Kiến trúc 3 tầng |

## D. Quy ước Git & cổng

| Pattern | Cách đúng duy nhất | File ví dụ chuẩn | Ghi chú |
|---------|--------------------|------------------|---------|
| Commit | conventional commits; một thay đổi logic/commit | `CLAUDE.md` §8 | `commitlint.config.cjs` ở dropins |
| Merge | squash, qua PR, không push thẳng `main`, FIFO theo thứ tự tạo PR | `CLAUDE.md` §8 | ⚠️ chưa có hàng rào thi hành (chỉ là luật) |
| Sửa bug | test tái hiện **đỏ trước** khi sửa, test ở lại làm hồi quy | `CLAUDE.md` §3.6 | |
| Tính năng | spec `docs/specs/<ngày>-<slug>.md` ghi "Approved for implementation" trước khi sửa source | `docs/specs/2026-09-12-*.md` | Cưỡng chế bằng `pr-policy.yml` |
| Required checks | Danh sách tên job **duy nhất** ở `docs/ops/repository-settings.md` | như trên | Cưỡng chế 2 chiều bằng `check-ci-policy.sh` |

## Đang có NHIỀU KIỂU / quy ước NGẦM — cần hợp nhất (đầu vào cho kế hoạch hoàn thiện)

1. **`set -euo` vs `set -uo` phải có chủ đích, không "chuẩn hoá" ngầm.** Script cổng dùng `-euo`; script
   tiện ích + hook dùng `-uo` (hook không được làm chết phiên) — comment `# cố ý KHÔNG -e` phải có ở mọi
   file dùng `set -uo pipefail`, để người/AI sau không vô tình thêm `-e` và biến một formatter thiếu
   thành cổng chặn phiên.
2. **Hai bản kiểm CI song song** (`scripts/check-ci-policy.sh` shell cho repo khung ·
   `scripts/ci-workflow-policy.test.ts` vitest cho dropins) — **cố ý không gộp** (repo khung không có
   `package.json`), đã ghi rõ trong header script. Không phải nợ, nhưng là điểm phân kỳ cần canh:
   sửa một bên phải soát bên kia. Chưa có cổng nào ràng hai bên với nhau.
3. **`copy-framework.sh` ↔ `.ps1` phải khớp danh sách file.** Bỏ qua `.ps1` khi thiếu `pwsh` phải in
   cảnh báo nổi bật; CI chạy với `REQUIRE_PWSH=1` nên runner mất `pwsh` làm job đỏ thay vì bỏ qua âm thầm.

4. **Fail-open phải NÓI RA.** Mọi hook/cổng khi bỏ qua vì thiếu công cụ (`jq`, `gitleaks`, `pwsh`,
   `dev-task.sh`) đều phải in cảnh báo ra stderr. Đã áp cho `auto-format.sh`,
   `pre-commit-gate.sh`, `block-dangerous-git.sh`, `.husky/pre-commit`, `test-copy-framework.sh`.
