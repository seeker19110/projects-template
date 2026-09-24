# Đối chiếu `pbakaus/impeccable` với project-template — 2026-09-24

Nguồn: [`pbakaus/impeccable`](https://github.com/pbakaus/impeccable), clone/đọc trực tiếp 2026-09-24
(~70.7k GitHub stars khi xác minh). Phạm vi: template đa stack, không phải một frontend cụ thể.

## Kiến trúc nguồn

Impeccable là skill + Rust engine/CLI đa harness: 24 commands theo concern, `PRODUCT.md` lưu product truth,
`DESIGN.md`/surface brief lưu visual truth, live browser iteration và 61 detector rules. Plugin/hook chỉ là
lớp phân phối; engine/browser extension không cần thiết cho template.

## Dữ kiện cổng đã kiểm

- `/ui-ux` và provider contract đã bắt precedence, a11y, responsive, source-of-truth/fallback; `dev-task.sh gate` là cổng delivery.
- Report năm tầng SDLC đã quyết: design context nằm trong feature spec, không tách artifact riêng vì drift.
- Template không có UI runtime/fixture; detector external không thể là required gate.

## Mapping ba cột

| Impeccable | Đối chiếu template | Quyết định |
| --- | --- | --- |
| Plugin, installer, multi-harness manifests | AGENTS/`.claude`/copy framework đã là lớp phân phối generic | Đã có và sâu hơn — không copy. |
| `PRODUCT.md`/`DESIGN.md` context | `PROJECT.md` + approved spec + tokens/components + ADR có precedence | Đã có và sâu hơn — không tạo sổ song song. |
| `audit`/`polish` technical quality | `/ui-ux`, profile gates, `dev-task.sh gate` | Đã có và sâu hơn — không thay gate bằng score. |
| `shape`/`critique`/`audit`/`polish` theo concern | Provider contract chưa có adapter Impeccable | Nông hơn — map thành evidence tùy chọn, chọn command nhỏ nhất. |
| Detector findings | Chưa có triage contract cụ thể cho Impeccable | Nông hơn — finding phải kiểm DOM/code/token, không auto-fix. |
| Live variants, 61 required detectors, 24 aliases, Rust engine/submodule | Không có incident/baseline/owner; tăng dependency/trust/drift | Chưa cần; xem lại tại dự án đích khi có UI regression + fixture + triage owner. |
| PostToolUse/Stop external hook | Mâu thuẫn profile-specific gate và non-UI genericity | Không lấy; chỉ dự án đích bật sau review/baseline/rollback. |

## Kết quả thực sự tích hợp

Adapter documentation-only trong provider contract và routing `/ui-ux`; không dependency, runtime, hook,
config, skill copy hoặc artifact source-of-truth. Đây là bề mặt nhỏ nhất cho trường hợp dự án đích đã cài
Impeccable nhưng vẫn cần giữ kiến trúc template.
