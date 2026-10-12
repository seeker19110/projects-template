# Đối chiếu `seeker19110/stored` → `/auto-complete` trọn vòng (2026-10-12)

> Phương pháp: `docs/framework/adopt-from-outside.md` (ba cột, cổng §2 "tốt hơn bản hiện có", §3 grep cổng đang chạy).
> Nguồn: clone nông `seeker19110/stored` @ `a4c8376` (đọc 2026-10-12): README, WORKFLOW, mục 03, 09, 13, 21, 23 (đọc toàn văn),
> lướt các mục còn lại. Hồ sơ: `docs/work/2026-10-12-doi-chieu-stored-auto-complete/`. Spec: `docs/specs/2026-10-12-auto-complete-tron-vong.md`.

## 0. Kết luận

`stored` là **kho tri thức**, không phải harness: 23 chuyên mục Markdown + catalog JSON + một script kiểm catalog. Phần về vòng lặp
và harness (mục 03/21/23) phần lớn **rút từ chính repo này** và các repo anh em (xboss, X-Agents, Sales-Hunter). Vì vậy đa số cơ chế
rơi vào cột "đã có và sâu hơn". Lấy **4** điểm, đều dạng *kiểm được hơn*, cộng **3** bổ sung sau khi chủ repo hỏi "thiếu gì không":

| # | Lấy | Dạng "tốt hơn" | Cổng |
| --- | --- | --- | --- |
| K1 | `done.md` phải có nghiệm thu thật (Done, không placeholder, có PR/SHA) | bắt thêm lớp lỗi — **sự cố thật hôm nay** (`b7bd718`, TRAPS 70) | docs-consistency mục 13b |
| K2 | ADR ghi ≥ 2 phương án | kiểm được hơn — chọn kiến trúc tự động không hội tụ vào ý đầu | docs-consistency mục 16 |
| K3 | Hỏi trước khi sửa cấu hình cổng (xboss `protect-config`) | bắt thêm lớp lỗi — "làm xanh bằng nới cấu hình" khi tự trị | `permissions.ask` + test mục 19 |
| K4 | `/auto-complete` nối `/consult`→`/bootstrap`, ADR, review tách người viết, clone sạch + smoke, `release-readiness` GO/NO-GO | kiểm được hơn — chuỗi văn xuôi hở ở đầu (greenfield) và cuối (bàn giao) | contract test `test_auto_complete_chains…` |

## 1. Cột "Đã có và SÂU HƠN" (không lấy)

| Hạng mục ở `stored` | Ở đây | Sâu hơn ở chỗ |
| --- | --- | --- |
| AI Delivery Loop (xboss: Frame→…→Reconcile, 1 vòng = 1 PR) | `standard-delivery.md` §2/§4 | 9 cổng có artifact, Goal Loop có reconcile từ `main` + CI thật |
| "Tối đa 3 repair cùng failure" | `pre-commit-gate.sh` streak chữ ký + hook giữ vòng | đếm bằng máy theo chữ ký, khác chữ ký không cộng dồn |
| Status-freshness CI (Sales-Hunter) | `check-progress-freshness.sh` PF-1..4 | 4 phép kiểm, chạy cả PR lẫn push |
| `verified_by` do code điền | evidence-check `dev-task.sh`, contract C-4, goal mục 15 | bằng chứng gắn test có thật, đỏ được |
| Stop hook đọc file trạng thái, trần vòng | `auto-complete-guard.sh` (#287) | chính là nguồn của mục 03/23 ở `stored` |
| Subagent không lồng, trần 5, route 2 trục | ADR-0010/0011, `--check-plan` | có cổng khoá brief |
| Negative control bắt buộc | mục 11 NEGATIVE ở mọi suite hook/cổng | đã là khuôn |
| Checklist "evidence or it's a FAIL", GO/NO-GO (mục 09) | `release-readiness.md`, §4 "không tin lời khai", §7 | chỉ thiếu nối vào `/auto-complete` → K4 |
| Harness Anthropic: progress file, git, smoke đầu phiên | `session-resume.sh` + `PROGRESS.md` + work record | nạp tự động mỗi phiên |
| WORKFLOW ba cột + grep cổng | `adopt-from-outside.md` | `stored` tự ghi bản ở đây nghiêm hơn |

## 2. Cột "Đã có nhưng NÔNG HƠN" (chỉ lấy đúng điểm nông)

- **K1:** mục 13 chỉ đếm tên file `done.md`; `done.md` là tín hiệu DỪNG của hook giữ vòng → nội dung rỗng cho vòng dừng sai.
- **K2:** template ADR có "Các phương án đã cân nhắc" nhưng không cổng; 11/11 ADR hiện có đều qua (đã đo).
- **K3:** `ask` che `.claude/**`, workflows, githooks, `dev-task.sh` nhưng không che `check-*.sh`, rulesets, dependabot, config lint/test.
- **K4:** `/auto-complete` không gọi `/bootstrap`; `/auto` và `/completion` không gọi `/review`; smoke chỉ "cuối mỗi đợt" (Pha 3);
  không playbook nào kiểm sản phẩm chạy được từ clone mới.

## 3. Cột "CHƯA CÓ" — chưa cần (kèm điều kiện xem lại)

| Hạng mục | Vì sao chưa cần | Xem lại khi |
| --- | --- | --- |
| "4 số" cho loop: timeout + ngày hết hạn | trần lượt (20) + wind-down + streak đã chặn chạy vô hạn; timeout thêm biến cấu hình mà không bắt thêm ca | có lượt `/auto-complete` thật chạy quá một phiên mà ba điều kiện kia không dừng |
| Spend circuit breaker 80/90/100% | `usage-guard.sh` nhắc wind-down 70% đã có; Claude Code không cấp % quota cho hook | runtime cấp số quota/chi phí đo được |
| FEATURE-MAP ✅ phải có test | cột Test hiện là văn xuôi có giới hạn; cổng máy sẽ chặn oan nhiều dòng | FEATURE-MAP chuyển cột Test sang tham chiếu `path::symbol` |
| `model_tier` T0–T4 + enum side-effect trong PLAN | `--check-plan` + §3d "không bao giờ tự quyết" đã chặn side effect | worker được giao việc có side effect mạng/publish |
| Outbox/lease/fencing | khung không có side effect đối ngoại | dự án đích có publish/thanh toán (đưa vào hồ sơ C tương ứng) |
| `/hoc` thang mức bền | `TRAPS.md` + ADR + cổng đã là thang | bài học lặp mà không biết đặt ở đâu |
| Evaluator trình duyệt (Playwright) | đã là cổng E2E/axe trong hồ sơ C1 (`quality-gates-by-profile.md`) | — |
| gh-aw / Routines / durable runtime | quyết 2026-10-10: chưa chạy không giám sát | threat model riêng được duyệt |
| Hook PreToolUse soi Bash ghi file cấu hình | `ask` chỉ che Edit/Write (giới hạn ghi ở TRAPS 70) | có ca nới cấu hình qua `sed -i`/`>` |

## 4. Mâu thuẫn luật

Không lấy hạng mục nào ngược luật đang có. `stored` khuyên "luôn bật auto-merge ngay khi tạo PR" — ở đây `pr-flow.md` §1 chỉ bật
**sau khi mô tả PR đủ mục**; giữ luật ở đây (đã có sự cố `metadata` đỏ oan).

## 5. Sai lệch phát hiện trong `stored` (báo chủ kho, không sửa ở đây)

- Mục 23 §2.5 ghi "WIP cap 3 PR" — thực tế **5** (`pr-flow.md` §1, `pr-policy.yml`).
- Mục 23 §2.4 ghi "tự kiểm 3 phút" — thực tế **5 phút** (`CLAUDE.md` §10).
- Mục 03 §3 ghi "`STOP_HOOK_BLOCK_CAP`, mặc định 8 ở projects-template" — 8 là trần của Claude Code; trần ở đây là
  `AUTO_COMPLETE_MAX_CONTINUES=20`.

## 6. Đính chính giữa chừng (giữ nguyên)

- (A) Cổng mục 16 bản đầu đếm bullet/bảng → **chặn oan ADR-0005** (phương án dạng đoạn `**A. …**`). Mở rộng nhận dạng + thêm ca
  không-chặn-oan; không sửa ADR cũ.
- (B) Ô bằng chứng AC-4 của spec chứa `|` trong backtick → bảng vỡ cột, `--trace` báo EMPTY. Đổi ký hiệu tham chiếu.
- (C) Bản đầu K4 chỉ nối `/bootstrap`, ADR và `release-readiness`. Chủ repo hỏi "thiếu gì không" → rà lại thấy ba chỗ hở thật
  (review tách người viết, clone sạch, smoke thật trước bàn giao), thêm vào cùng PR với test đỏ-trước.
- (D) 29 `done.md` hiện có được đo trước khi viết 13b: 1 hồ sơ cũ không có mục "Nghiệm thu cuối" → quy tắc tìm PR/SHA trong cả
  file khi thiếu mục đó, để không chặn oan.
