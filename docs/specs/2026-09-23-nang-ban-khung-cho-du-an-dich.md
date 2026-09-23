# Feature spec: Nâng bản khung cho dự án đích (`copy-framework.sh --upgrade`, phiên bản + manifest)

| Thuộc tính | Giá trị |
| --- | --- |
| Issue / Goal | `docs/reports/2026-09-23-de-xuat-nang-cap-khung-toan-dien.md` — Đợt 4 (C2, A3) |
| Spec owner | Phiên Claude Code (Tầng 1) |
| State | **Approved for implementation** |
| Approver / date | Người dùng (chủ repo) duyệt kế hoạch 7 đợt qua chat, 2026-09-23 |
| Last updated | 2026-09-23 |

> Không code khi chưa **Approved for implementation**.

## 1. Problem, user và evidence

Dự án đích chỉ có một dấu `commit-nguon` (short SHA) trong `docs/framework/FRAMEWORK-VERSION`; cách "nâng bản" duy nhất
là chạy lại `copy-framework.sh`, và lệnh đó **ghi đè toàn bộ Lớp 1** (`docs/framework/`, `docs/ops/*.md` hướng dẫn,
`.claude/commands/`) — mọi chỉnh sửa cục bộ của dự án đích (thêm lệnh riêng, sửa runbook theo stack) mất sạch. Repo
khung không có phiên bản (0 tag; `release.yml` gate `package.json` nên không bao giờ chạy). `grep merge-file|diff3` = 0.

## 2. Outcome, baseline, target và guardrails

| Đo | Baseline | Target |
| --- | --- | --- |
| Chạy lại copy trên đích đã sửa file Lớp 1 | mất chỉnh sửa | `--upgrade`: giữ chỉnh sửa (3-way merge hoặc để bản mới cạnh bên) |
| Biết file nào đích đã sửa tay | không | manifest `git hash-object` từng file Lớp 1 trong `FRAMEWORK-VERSION` |
| Phiên bản khung máy đọc | không | `VERSION` (SemVer) + dòng `version:` trong `FRAMEWORK-VERSION` |
| Cảnh báo khung cũ | không | `maintenance-sweep.sh` 🟡 khi `ngay-copy` > 90 ngày (`MAINT_FRAMEWORK_STALE_DAYS`) |

Guardrails: **không bao giờ mất nội dung của đích** — khi không merge được thì để `.framework-new` cạnh bên; chế độ mặc
định (không `--upgrade`) giữ nguyên hành vi cũ để không bất ngờ với script/CI đang gọi.

## 3. Research current state

`copy-framework.sh` (`copy_into` = `cp -R`), `.ps1` cùng danh sách; `git merge-file` có sẵn ở mọi git (POSIX diff3);
`git hash-object` thay `sha256sum` (macOS không có — T16). release-please `simple` cần cấu hình manifest riêng và sẽ viết
lại `CHANGELOG.md` theo định dạng của nó — **không bật trong đợt này** (quyết định ở §4).

## 4. Alternatives và decision

| Option | Benefits | Cost/risk | Decision |
| --- | --- | --- | --- |
| Do nothing | 0 | dự án đích không nâng bản được, càng lâu càng lệch | ✗ |
| A. `--upgrade` 3-way bằng `git merge-file` + manifest hash (chọn) | không dependency; giữ chỉnh sửa; phát hiện file đã sửa cả khi thiếu lịch sử git | `.ps1` chưa có (DEBT, xem lại khi có người dùng Windows cần) | ✓ |
| B. Đóng gói plugin Claude Code | nâng bản = bump version | chỉ Claude Code; đổi kiến trúc phân phối — cần ADR + người dùng chốt | để sau (câu hỏi §5 báo cáo) |
| C. Bật release-please `simple` cho repo khung | tag tự động | viết lại CHANGELOG, cần bootstrap; quyết định vận hành của chủ repo | hỏi người dùng; đợt này chỉ thêm `VERSION` |

## 5. Scope / non-goals

Trong: `VERSION`, `FRAMEWORK-VERSION` (version + manifest), `copy-framework.sh --upgrade`, sweep 🟡 khung cũ, test.
Ngoài: plugin; release-please; `.ps1 --upgrade` (in hướng dẫn dùng Git Bash).

## 6. User journeys và mọi state

- Đích chưa có khung → như cũ. Đích có khung, chạy không cờ → như cũ (ghi đè Lớp 1; in nhắc dùng `--upgrade`).
- `--upgrade`: file đích chưa sửa (hash = manifest) → ghi đè; đã sửa + có base trong lịch sử `SRC` → `git merge-file`
  (báo số xung đột, marker trong file); đã sửa + không có base/manifest → giữ đích, để `<file>.framework-new`.

## 7. Functional requirements

FR-1 `VERSION` ở gốc repo khung (SemVer); `FRAMEWORK-VERSION` có `version:`, `commit-nguon:`, `ngay-copy:`, và
`manifest: <hash> <path>` cho mọi file Lớp 1 đã copy.
FR-2 `copy-framework.sh <đích> --upgrade` (cờ ở bất kỳ vị trí) áp luật §6; mặc định không cờ giữ hành vi cũ.
FR-3 Không có `FRAMEWORK-VERSION` cũ ở đích → `--upgrade` chạy như copy thường (không có gì để bảo vệ), in cảnh báo.
FR-4 `maintenance-sweep.sh`: 🟡 "khung lệch" khi `ngay-copy` > `MAINT_FRAMEWORK_STALE_DAYS` (90).
FR-5 `.ps1 -Upgrade` → in hướng dẫn dùng bản `.sh` qua Git Bash, thoát 2 (không im lặng ghi đè).

## 8. Non-functional requirements

Bash ≥ 4 không bắt buộc (không dùng mảng kết hợp); CC ≤ 12/hàm; không dependency mới; ShellCheck 0 cảnh báo.

## 9. Acceptance criteria

AC-1 `test-copy-framework.sh`: `FRAMEWORK-VERSION` có `version:` khớp `VERSION` và ≥ 1 dòng `manifest:`.
AC-2 Đích sửa `docs/framework/quickstart.md` (thêm dòng) → `--upgrade` giữ dòng đó (merge hoặc `.framework-new`);
file không sửa (`standard-delivery.md`) bằng bản `SRC`.
AC-3 Đích có `FRAMEWORK-VERSION` cũ không manifest và `commit-nguon` không giải được → `--upgrade` không mất sửa đổi.
AC-4 `test-maintenance-sweep.sh`: `FRAMEWORK-VERSION` `ngay-copy: 2020-01-01` → 🟡; repo sạch không 🟡.
AC-5 Chạy không cờ trên đích có khung → hành vi cũ (sentinel ops-log vẫn còn — ca đã có).

## 10. UX/content/accessibility

Thông điệp mỗi file: `= giữ nguyên` / `+ cập nhật` / `~ merge (N xung đột)` / `~ để cạnh .framework-new`.

## 11. Architecture và code touchpoints

`VERSION`, `copy-framework.sh` (`parse args`, `upgrade_file`, `copy_into`, `write_version_stamp`), `copy-framework.ps1`
(`-Upgrade` thông báo), `scripts/maintenance-sweep.sh` (`sweep_docs`), `scripts/test-copy-framework.sh`,
`scripts/test-maintenance-sweep.sh`, `docs/framework/README.md`, `SUPPORT.md`, `CODEMAP.md`, `CHANGELOG.md`.

## 12. API/event contract

CLI: `bash copy-framework.sh <đích> [--upgrade]`. Exit 0 kể cả khi có xung đột (đã báo từng file); exit 1 lỗi tham số.

## 13. Data contract/migration

`FRAMEWORK-VERSION` thêm dòng — bản cũ (chỉ `commit-nguon`) vẫn đọc được (FR-3, AC-3). `.framework-new` đã là quy ước.

## 14. Security/privacy/abuse cases

Đường dẫn file lấy từ `find` trong `SRC` (repo khung), không từ input ngoài; `git merge-file` không thực thi nội dung.

## 15. Rollout, observability, rollback

Có hiệu lực khi merge; đích cũ dùng được ngay (`--upgrade` với FR-3). Rollback: revert PR. Quan sát: dòng tóm tắt
"N cập nhật · M merge · K để cạnh" cuối lệnh.
