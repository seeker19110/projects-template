# Báo cáo: vòng hoàn thiện (`/completion`) trên một dự án đích Node thật (2026-10-09)

> Hồ sơ: `docs/work/2026-10-09-target-completion/done.md`. Mục tiêu: FEATURE-MAP "Luồng chính" mục 5 (vòng hoàn thiện/audit
> "chưa chạy trên dự án đích thật") và FT-01 cột Test (`/consult` chỉ kiểm tồn tại). **Giới hạn nói trước:** dự án đích
> `invoice-calc` (Node 22 ESM, vitest 5, 4 module, 4 test ban đầu) do phiên chính viết làm "mã kế thừa" — không phải sản phẩm
> production của chủ repo; mọi bước còn lại (copy khung, audit, kế hoạch, sửa, re-audit) chạy bằng công cụ và agent thật.

## Pha 0 — áp khung (brownfield)

| Bước | Kết quả | Phát hiện về KHUNG |
|---|---|---|
| `copy-framework.sh <đích>` | Lớp 1 + tài liệu vào thẳng; CI/`.gitignore`/vitest drop-in vào `_framework-dropins/` | chạy lại lần 2 không `--upgrade` → sinh 59 file `*.framework-new` cạnh file đã có (đúng thiết kế brownfield, nhưng cần dọn tay) |
| `dev-task.sh doctor` | BLOCKED "chưa cấu hình build" → khai `.claude/project-commands.sh` (lint/test thật, N/A build+typecheck có lý do) → READY | thông điệp đúng; không cho `true` né cổng |
| `dev-task.sh gate` lần đầu | **FAIL** ở `test`: vitest gom _framework-dropins/scripts/ci-workflow-policy.test.ts (ở đích) → đỏ "tìm thấy ít nhất một workflow" dù code đích không lỗi | **F-T01 (Cao cho trải nghiệm áp khung)** → sửa ở khung PR #234: `describe.skipIf(STAGED)`; sau sửa `2 passed \| 1 skipped` |
| Bước 0 adoption (`standard-worker`) | `docs/FEATURE-MAP.md` 8 hàm (4 ✅/4 ⚠️ có tái hiện), `docs/CONVENTIONS.md` (5 mục "cần hợp nhất"), `CODEMAP.md`, `PROJECT.md` điền ngược, `CLAUDE.md` §5/§10, `PROGRESS.md` | `check-docs-consistency.sh` không phát sang đích (đúng: cổng của riêng khung) |

## Pha 1 — audit bằng 4 agent read-only song song (nhóm 2+11, 3+12, 4+9, 7)

Tổng 11 (L) + 11 (T) + 7 (S) phát hiện, trùng nhau có chủ ý (độc lập xác nhận). Hợp nhất: **Cao 2** — L-01/T-01 bậc chiết khấu
dùng `>` thay `>=` (qty 100 được 10 % thay vì 15 %; test cũ chọn 101 nên không bắt), L-02/T-03 `dueDate` trộn giờ local với UTC
(lệch 1 ngày quanh DST, tái hiện `TZ=America/New_York`); **Trung 9** — tiền float (`format(1.005)` → `$1.00`), `format` im lặng với
mã tiền lạ/âm/NaN, `invoice` không validate (qty âm → hoá đơn âm, `'abc'` → `$NaN`), luôn NET 30, `.gitignore` đích thiếu `.env`,
CI drop-in chưa cài, **`ci-target.yml` không cài dependency (S-05)**; **Thấp 6** (gồm T-09/L-10 chính là F-T01). Nhóm 7: 0 gói lỗi
thời, 0 lỗ hổng, 3/3 action ghim SHA.

## Pha 2 — kế hoạch (tự duyệt theo ủy quyền §3d)

`docs/ops/COMPLETION-PLAN.md` ở đích: DoC 4 mục; W-1 (biên bậc + UTC + validate), W-2 (tiền đơn vị nhỏ nhất + `invoice` validate +
`netDays`), W-3 (README/API, `.gitignore`, CI drop-in); T-11 coverage provider → KHÔNG thêm dependency; S-04 CODEOWNERS → ghi nhận.
Hai mục sửa ở KHUNG (F-T01, S-05) → PR #234.

## Pha 3 — thực thi (worktree riêng, song song W-1 ∥ W-2, TDD đỏ-trước)

| Đơn vị | Agent | Đỏ-trước | Xanh sau | Commit |
|---|---|---|---|---|
| W-1 | `standard-worker` | 28 fail (UTC) / 29 fail (New_York — ca DST) | 46 pass cả 2 TZ | `f1acb22` |
| W-2 | `complex-implementer` | 17/24 ca mới fail | 28 pass; total = subtotal + tax chính xác | `1c3d676` |
| CI drop-in + `.gitignore` | phiên chính | — | `.github/workflows/ci.yml` (bản có `npm ci`), `.gitignore` khung | `1111282` |
| W-3 | `standard-worker` | n-a (chỉ tài liệu, ngoại lệ 3) | README API 8 hàm, mọi ví dụ chạy thật bằng `node -e`; FEATURE-MAP 8/8 ✅; CONVENTIONS/PROGRESS/COMPLETION-PLAN đích | `860d561` |
| Merge + cổng | phiên chính | — | vitest **76 passed \| 8 skipped** ở TZ=UTC và TZ=America/New_York; `dev-task.sh gate` PASS, evidence VERIFIED | `26dd280` → `9bb2127` (sau W-3 + ghi backlog Pha 4; 76 pass 2 TZ, gate PASS, evidence VERIFIED `tgt-final.json`) |

**Phát hiện về harness (không phải khung):** hook `pre-commit-gate.sh` của PHIÊN KHUNG chạy cổng của repo khung
(`CLAUDE_PROJECT_DIR`) ngay cả khi worker commit trong worktree của dự án đích → 3 worker bị chặn bởi cổng không thuộc diff của
họ, và hai lần cổng đỏ giả do suite của khung chạy đồng thời (file probe tạm `scripts/zz-probe-*.sh`, "working tree đổi trong khi
kiểm tra"). Cả 3 worker **không** dùng `--no-verify` (auto-mode cũng chặn `[CI Bypass]`), dừng và báo lên — đúng hợp đồng. Phiên chính
commit thay sau khi xác nhận cổng đích xanh. Khi dùng khung đúng cách (phiên Claude Code MỞ TRONG dự án đích) thì hook gate đúng repo.

## Pha 4 — re-audit (agent `reviewer`, read-only, nhóm 3/4/12) trên `main` sau W-1/W-2

**Cao 0 · Trung 0 · Thấp 4** (`review-findings/1`). Hai phát hiện Cao cũ đã đóng và được xác nhận độc lập: bậc 10/50/100
inclusive, `dueDate('2026-03-01', 30)` → `2026-03-31` ở cả hai TZ; 20 000 hoá đơn ngẫu nhiên có `subtotal + tax = total` lệch 0.
Còn lại: R-01 `dueDate` vượt năm 9999 trả chuỗi `+010000-01` thay vì ném lỗi; R-02 `netDays` ~1e9 ném `RangeError` không nêu tên
tham số; R-03 `lineTotal` public trả float thô (invoice không ảnh hưởng vì `toMinor` làm tròn lại); R-04 thiếu test ca tràn range
và ca sai kiểu ở `invoice`. Quyết định (ủy quyền §3d): **không sửa trong chu kỳ này** — cả 4 nằm ngoài DoC đã duyệt (Cao/Trung = 0),
R-01/R-02 là biên phi thực tế với hoá đơn, R-03/R-04 ghi vào `docs/ops/COMPLETION-PLAN.md` của đích làm backlog có điều kiện xem lại
("khi có caller ngoài dùng `lineTotal`" / "khi mở rộng validate").

## `/consult` brownfield — research-first có xác minh nguồn sống (agent `version-check`, registry.npmjs.org, 2026-10-09)

| Gói | Đích đang dùng | Latest | Kết luận |
|---|---|---|---|
| vitest | 5.0.3 | 5.0.3 | giữ nguyên |
| @vitest/coverage-v8 | — | 5.0.3 (peer vitest 5.0.3) | **không thêm** (T-11): đích chưa có ngưỡng coverage; thêm dependency cho thứ chưa đo là trái §3.4 nấc 5 |
| typescript | — | 7.0.2 | **không chuyển TS** trong chu kỳ này; nếu muốn kiểu tĩnh: JSDoc + `tsc --checkJs --noEmit` (0 dependency runtime) khi codebase > ~5 module |
| eslint | — | 10.12.0 | chưa thêm; `node --check` + vitest đủ cho 4 module; xem lại khi có ≥ 2 người đóng góp |

Khung đã làm đúng vai brownfield: không áp hồ sơ mặc định, chỉ nâng cấp tăng dần trên stack thật (Node ESM + vitest).

## Kết luận

- **Luồng chính 5 (FT-08/FT-09): ✅ có giới hạn.** Vòng `/completion` (Pha 0→4) chạy trọn trên một dự án đích Node thật bằng công cụ
  và agent thật; hai phát hiện Cao của đích được sửa theo TDD và re-audit xác nhận Cao/Trung = 0. Giới hạn: đích là fixture do
  phiên chính viết, không phải sản phẩm production; CI drop-in chưa chạy trên hosted runner.
- **FT-01 (`/consult`): ✅ có giới hạn.** Research-first brownfield chạy thật với xác minh phiên bản nguồn sống (4 gói); kết luận là
  "giữ stack, không thêm dependency" — đúng luật §3.4, nhưng chưa phải một lượt tư vấn greenfield chọn stack mới.
- **Khung:** hai lỗi thật lộ ra (F-T01, S-05) đã sửa ở #234 (`db9bda6`); squash #234 đưa lên `main` một tiêu đề commit 90 ký tự vì
  cổng `metadata` chỉ đo độ dài TIÊU ĐỀ PR, không đo tiêu đề commit (PR một commit → squash lấy tiêu đề commit) → sửa trong PR closeout
  này (TRAPS mục 58).
- **Còn lại, ngoài tầm phiên này:** hosted CI trên repo đích thật, pilot với người dùng thật, model benchmark, phiên harness khác
  (Hermes/Gemini/Cursor…), FT-41 bước 6–8.
