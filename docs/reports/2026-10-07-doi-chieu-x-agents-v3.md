# Đối chiếu X-Agents lần 3 → projects-template — 2026-10-07

Nguồn: `seeker19110/X-Agents` @ `2dd4750` — **cùng commit với lần 2** (`2026-10-06-doi-chieu-x-agents-v2.md`), nên không có
thay đổi mới ở nguồn. Lần này đọc phần lần 2 chưa đụng: `.claude/agents/ecc-*`, `/no-ky-thuat`, mục "Compact
Instructions" của `CLAUDE.md`, luật 11 của `AGENTS.md`. Đích: `projects-template` @ `3ab7a7b`.
Kết quả: **không có hạng mục nào qua cổng §2 → không lấy gì.** Đây là kết quả, không phải thiếu sót.

## Ba cột

### Đã có và sâu hơn
| X-Agents | Ở template |
| --- | --- |
| `/no-ky-thuat` (thu marker `no-ky-thuat:`, cờ thiếu điều kiện quay lại) | Marker `DEBT: … \| xem lại khi:` (CLAUDE.md §3.7) + `maintenance-sweep.sh` cảnh báo 🟡 tự động trong quét định kỳ và CI, có test; X-Agents chỉ có lệnh chạy tay. |
| Cổng 1 lệnh, hook chặn git nguy hiểm, TDD, `TRAPS.md` | Đã đối chiếu ở lần 2 (giữ nguyên). |
| Chụp trạng thái trước khi nén ngữ cảnh | `precompact-checkpoint.sh` + `session-resume.sh` chạy bằng hook; X-Agents dựa vào văn bản "Compact Instructions" + auto-compact 300k. |

### Đã có nhưng nông hơn
Không có điểm nào đo được. Ghi nhận: template không có đoạn "Compact Instructions" trong CLAUDE.md (danh sách thứ giữ
lại khi nén, "không biến lời khai thành bằng chứng"); hook checkpoint đã giữ nhánh/diff/PROGRESS, và §4 CLAUDE.md đã cấm
tin lời khai — chưa có phiên mất ngữ cảnh nào tái hiện được → không thêm.

### Chưa có — không thêm, kèm điều kiện xem lại
| Ứng viên | Quyết định |
| --- | --- |
| Luật "tìm PR/issue trùng (cả đã đóng) trước khi mở PR" (AGENTS.md #11 của X-Agents) | Chưa cần. Ứng viên sự cố là PR #186 — kiểm bằng API: đó là PR dependabot bị #185 thay thế, **không phải** PR người/AI mở trùng. Không đủ bằng chứng. Xem lại khi có PR do phiên AI mở mà trùng một PR đã đóng/đang mở cùng vấn đề. |
| Agent `ecc-silent-failure-hunter`, `ecc-type-design-analyzer`, `ecc-comment-analyzer`, `ecc-pr-test-analyzer` | Chưa cần: `reviewer` + `/review` (skill `code-review`) và CLAUDE.md §3.3/§3.6 phủ cùng vùng; sự cố "nuốt lỗi" duy nhất ở template (TRAPS: `2>/dev/null` trong script) là lỗi shell đã có cổng riêng, không phải lỗi ứng dụng mà agent này săn. Xem lại khi một PR dự án đích lọt `catch {}`/fallback nuốt lỗi qua `/review`. |
| Vendor ECC (23 mục, ghim sha256) | Ngoài phạm vi: trái ranh giới "template không vendor plugin" (đã ghi ở lần 2). |
| Quy trình worktree/`/gate-review`/`/thi-hanh`/`sc-*` | Ngoài phạm vi: là runtime công ty của X-Agents (orchestrator, chữ ký reviewer); template có `coordinator` + `/auto` cho vai tương đương. |

## Đính chính giữa chừng
Ban đầu coi #186 là bằng chứng "PR trùng" (PROGRESS.md ghi "#186 trùng đã đóng"). Đọc PR thật: bot dependabot, thay bởi
#185 — loại ứng viên. Chữ "trùng" trong PROGRESS.md chỉ đúng nghĩa dependabot, không phải sự cố quy trình.

## Thực sự lấy
Không có.
