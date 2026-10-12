# PLAN.md — Port các bản sửa audit 2026-09-15 còn thiếu (nhánh `codex/open-branch-integration`)

## Bối cảnh & mục tiêu
Nhánh local `codex/open-branch-integration` (29 commit, 2026-09-15, chưa từng có PR) sửa các phát hiện audit 2026-09-15. Kiểm theo hành vi trên `main` `ac75f09` (2026-10-11): 5 mục đã có bằng đường khác, 8 mục vẫn thiếu, 6 trong đó tái hiện được. Mục tiêu: port theo Ý ĐỊNH (không cherry-pick — `main` đã viết lại nhiều) từng mục thiếu thành một PR `fix:` nhỏ có test đỏ-trước, rồi xoá nhánh. Hồ sơ `docs/work/2026-10-11-port-open-branch/done.md`.

## Đặc tả dùng chung
- Schema/DDL: không đổi
- API: không đổi (CLI/exit code của các script giữ nguyên trừ chỗ đặc tả nói rõ)
- Quy ước: commit gốc để đọc ý định: `git show <sha>` trong repo (nhánh `codex/open-branch-integration`). Cổng: `scripts/dev-task.sh gate`; tối thiểu chạy suite nêu ở Tiêu chí chấp nhận + `bash scripts/check-docs-consistency.sh` + `bash scripts/check-shell-complexity.sh` + `shellcheck --severity=warning` cho script đã sửa. Trên Windows/Git Bash, công cụ ghi file qua heredoc có thể đổi chuỗi backslash-n thành xuống dòng thật — soát lại bằng `cat -A` sau khi ghi.

## Nhóm PR (đơn vị mở PR)
- **PR-1** (sweep chết không đóng nhầm issue): gồm việc T1 — độc lập, chạy song song với PR-2, PR-3
- **PR-2** (copy-framework lượt chạy thứ ba): gồm việc T2 — độc lập, chạy song song với PR-1, PR-3
- **PR-3** (cổng không khẳng định điều chưa kiểm): gồm việc T3 — độc lập, chạy song song với PR-1, PR-2
- **PR-4** (sweep chạy đủ cổng khung): gồm việc T4 — độc lập, đợt 2 (trần WIP 3)
- **PR-5** (subagent-dispatch báo lỗi đúng chỗ): gồm việc T5 — độc lập, đợt 2
- **PR-6** (PF-1 đỏ khi PROGRESS bỏ quá một vòng WIP): gồm việc T6 — phụ thuộc PR-3 (cùng `scripts/check-progress-freshness.sh`, `scripts/test-check-progress-freshness.sh` sau khi PR-3 tách suite), chạy tuần tự sau PR-3
- **PR-7** (cổng tài liệu quét .py/.css + test âm 5 nhánh cổng): gồm việc T7 — phụ thuộc PR-3 (cùng `scripts/test-check-scripts.sh`; ca CP-* cần F-303 đã sửa), chạy sau PR-3, song song được với PR-6 vì PR-3 đã tách suite PF ra file riêng

## Danh sách việc
### T1 — maintenance.yml: sweep chết không trông như sweep sạch, không đóng nhầm issue (F-202, gốc b80a111)   `route: standard`
- Điểm chạm: `.github/workflows/maintenance.yml`, `scripts/test-workflow-guards.sh`
- Đặc tả: bước `id: sweep` hiện ghi `rc=$?` vào `$GITHUB_OUTPUT` nhưng không bước nào đọc, và `grep … || echo 0` biến "không đọc được dòng tổng" thành 🔴 0 · 🟡 0 → bước sau comment "sạch" rồi ĐÓNG issue. Sửa: sweep exit khác 0 → `::error` nêu rc và thoát 1 ngay trong bước đó (không bước nào sau đụng issue); bỏ `|| echo 0`; báo cáo không có dòng tổng `🔴 N` / `🟡 N` → `::error` "báo cáo không hoàn chỉnh" + thoát 1. Hành vi khi sweep thành công giữ nguyên. Test: thêm mục mới vào `scripts/test-workflow-guards.sh` trích khối `run:` của bước `id: sweep` (python + yaml hoặc cách suite đã dùng) và chạy nó trong thư mục tạm với `scripts/maintenance-sweep.sh` giả: (a) exit 3 → khối thoát khác 0; (b) exit 0 nhưng báo cáo thiếu dòng tổng → khác 0; (c) exit 0, báo cáo có `🔴 2 · 🟡 1` → thoát 0 và `$GITHUB_OUTPUT` có `red=2`, `yel=1`.
- Phụ thuộc: none
- Tiêu chí chấp nhận: ca (a)(b) ĐỎ trên `maintenance.yml` cũ (nộp output), xanh sau sửa; ca (c) xanh cả trước lẫn sau; `bash scripts/test-workflow-guards.sh` xanh; `bash scripts/check-ci-policy.sh` xanh; YAML parse được.

### T2 — copy-framework.sh: không lồng thư mục ở lượt chạy thứ ba (F-306, gốc ce4bd67)   `route: standard`
- Điểm chạm: `copy-framework.sh`, `scripts/test-copy-framework.sh`, `TRAPS.md`
- Đặc tả: `place_or_aside` chạy `cp -R "$src" "$dst.framework-new"`; khi thư mục đặt cạnh (tên gốc + `.framework-new`) ĐÃ có (lượt 3 trên đích đã sửa thư mục) `cp -R` copy src VÀO TRONG → `.claude/hooks.framework-new/hooks`. Sửa nhánh thư mục: `mkdir -p "$dst.framework-new"` rồi `cp -R "$src/." "$dst.framework-new/"` (đúng ngữ nghĩa `Copy-Tree` của `copy-framework.ps1` — KHÔNG sửa `copy-framework.ps1`); nhánh file giữ nguyên. Test: thêm helper `check_no_nesting` (tham số: nhãn, thư mục đích) vào `scripts/test-copy-framework.sh` — đích có sửa một file trong `.claude/hooks`, chạy copy 3 lần, đòi không có thư mục lồng dạng `X.framework-new/X` (vd `.claude/hooks.framework-new/hooks`) cho mọi thư mục được đặt cạnh; chạy cho bash và (khi có `pwsh`) cho `copy-framework.ps1`. Dùng `new_target` đang có. `TRAPS.md`: thêm mục **68** "`cp -R` đổi nghĩa khi đích đã tồn tại — test hai lượt không đủ, phải có lượt ba" theo khuôn mục 67 (Ngày, Cách rà, Cổng chốt chặn).
- Phụ thuộc: none
- Tiêu chí chấp nhận: ca bash ĐỎ trước sửa (nộp output liệt kê thư mục lồng), xanh sau; `REQUIRE_PWSH=1 bash scripts/test-copy-framework.sh` xanh (nếu máy có pwsh); `bash scripts/check-docs-consistency.sh` xanh.

### T3 — check-ci-policy/check-progress-freshness: không in "đạt" khi chưa kiểm, có chẩn đoán khi đỏ (F-303, F-305, gốc 83c04e4)   `route: standard`
- Điểm chạm: `scripts/check-ci-policy.sh`, `scripts/check-progress-freshness.sh`, `scripts/test-check-scripts.sh`, `TRAPS.md`
- Đặc tả: (F-303) `scripts/check-ci-policy.sh` mục 7 đọc chính nó qua `$0` sau khi `cd` về gốc repo → gọi `cd scripts && bash check-ci-policy.sh` thì grep không thấy file, 0 mục CP-* được đối chiếu mà vẫn in OK, rc 0. Sửa: phân giải đường dẫn tuyệt đối của chính script bằng `BASH_SOURCE[0]` TRƯỚC khi `cd`; đọc được 0 mục CP-* → `::error` + `fail=1`. (F-305) mọi phép gán `X="$(… grep …)"` dưới `set -e`/`pipefail` mà grep có thể không khớp phải có `|| true` và nhánh `::error` tường minh ngay sau — ít nhất: `recorded_sha` (PF-1) và dòng tên nhánh (PF-2) ở `scripts/check-progress-freshness.sh`, dòng `needs:` của job `gate` ở `scripts/check-ci-policy.sh`; rà thêm cùng khuôn trong hai file và vá hết. Test vào `scripts/test-check-scripts.sh`: (1) chạy `check-ci-policy.sh` từ `scripts/` trong repo sao chép → kỳ vọng rc 0 VÀ không có `No such file`; (2) dòng SHA trong PROGRESS.md mất backtick → rc khác 0 kèm `::error` VÀ output có tiêu đề PF-2/PF-3/PF-4 (mục sau vẫn chạy); (3) xoá dòng `needs:` của job `gate` trong `ci.yml` → rc 1 kèm `::error` nhắc `needs`. `TRAPS.md`: thêm mục **69** "script tự đọc `$0` sau `cd` / gán `$(grep …)` dưới `set -e` chết im lặng" theo khuôn mục 67.
- Phụ thuộc: none
- Tiêu chí chấp nhận: ba ca ĐỎ trước sửa (nộp output), xanh sau; `bash scripts/test-check-scripts.sh` xanh; `bash scripts/check-ci-policy.sh` và `bash scripts/check-progress-freshness.sh` xanh trên repo.

### T4 — maintenance-sweep.sh: chạy đủ cổng khung, tách "thiếu công cụ" khỏi "vi phạm thật" (T-2, gốc bcde247)   `route: complex`
- Điểm chạm: `scripts/maintenance-sweep.sh`, `scripts/test-maintenance-sweep.sh`
- Đặc tả: `sweep_gates` chỉ chạy `scripts/check-docs-consistency.sh` và `scripts/check-ci-policy.sh` mà mục vẫn mang tên "Cổng khung". Thêm `scripts/check-progress-freshness.sh`, `scripts/check-shell-complexity.sh`, `scripts/check-python-complexity.sh` (script vắng → `n-a` như hiện nay). Phân loại kết quả đỏ: thông điệp "thiếu công cụ" (vd `radon`/`shellmetrics` không cài) → 🟡 "chưa kiểm chứng được" kèm tên công cụ cần cài; còn lại → 🔴 như cũ. Regex nhận dạng thiếu công cụ phải HẸP và riêng từng cổng (đọc thông điệp thật của từng script; KHÔNG dùng mẫu chung kiểu `Thiếu` vì `scripts/check-progress-freshness.sh` in "Thiếu dòng 'Default-branch SHA…'" cho vi phạm thật; lỗi checksum `shellmetrics` là chuỗi cung ứng → giữ 🔴). Được tự quyết cấu trúc (bảng nhãn↔regex, hàm phân loại); giữ mọi hàm ≤ CC 12. Test: ca mỗi cổng mới được chạy (nhãn xuất hiện trong báo cáo); ca cổng giả in thông điệp thiếu-công-cụ → 🟡 không 🔴; ca ĐỐI CHỨNG cổng giả vi phạm thật có chữ "Thiếu" → vẫn 🔴.
- Phụ thuộc: none
- Tiêu chí chấp nhận: các ca mới ĐỎ trước sửa (nộp output), xanh sau; `bash scripts/test-maintenance-sweep.sh` xanh; `bash scripts/maintenance-sweep.sh --no-deps` trên repo không sinh 🔴 mới do phân loại sai; `bash scripts/check-shell-complexity.sh` xanh.

### T5 — subagent-dispatch: báo lỗi đúng nguyên nhân, choices sinh từ dữ liệu (F-207, gốc fc4e9c8)   `route: standard`
- Điểm chạm: `scripts/subagent-dispatch.py`, `scripts/test-telemetry-and-dispatch.sh`, `scripts/test-py-coverage.sh`
- Đặc tả: (1) nạp `scripts/model-capability-tiers.json` hỏng theo ba cách (thiếu file / JSON hỏng / sai cấu trúc) hiện đều thành "tier 'X' không có trong …" → mỗi ca một thông điệp nêu đúng nguyên nhân + exit khác 0, theo khuôn `load_rates()` của `scripts/telemetry-log.py`; (2) `choices` của `--tier` sinh từ JSON (thiếu file lúc dựng parser không phải lỗi; lỗi báo khi thật sự dùng `--tier`); (3) ứng viên thiếu khoá (vd `model_hint`) → cảnh báo nêu đúng trường + in `?`, không traceback. Độ phủ: sàn hiện có của `scripts/test-py-coverage.sh` KHÔNG được hạ — thêm ca theo khuôn sẵn có của file đó.
- Phụ thuộc: none
- Tiêu chí chấp nhận: ca mới ở `scripts/test-telemetry-and-dispatch.sh` ĐỎ trước sửa (nộp output), xanh sau; `bash scripts/test-py-coverage.sh` xanh, sàn giữ nguyên; `bash scripts/check-python-complexity.sh` xanh.

### T6 — check-progress-freshness PF-1: đỏ khi PROGRESS bỏ quá một vòng WIP (F-104, gốc 56bad90 + 7c11a19)   `route: standard`
- Điểm chạm: `scripts/check-progress-freshness.sh`, `scripts/test-check-progress-freshness.sh`, `docs/framework/pr-flow.md`
- Đặc tả: PF-1 hiện chỉ `::warning` ở mọi mức trễ. Thiết kế gốc dựa vào dòng "Nhánh đang làm" mà PROGRESS.md đã bỏ từ #177 → không port nguyên văn. Quyết định (Tầng 1, §3d): đếm trễ bằng `git rev-list --count --first-parent "$recorded_sha..HEAD"` (merge ref của PR chỉ tính commit trên nhánh chính, không tính commit riêng của PR); `PF_MAX_BEHIND` mặc định **7** (= trần WIP 5 + 1 commit squash + 1 nhịp dư; trước là 5 khi trần WIP còn 3), ghi đè bằng biến môi trường cùng tên (số nguyên dương; sai khuôn → `::error`); trễ ≥ ngưỡng → `::error` nêu số trễ, ngưỡng và cách sửa (cập nhật dòng SHA, CLAUDE.md §8 bước 5) + `fail=1`; 1 ≤ trễ < ngưỡng → `::warning` như cũ. Ghi lý do ngưỡng ngay tại chỗ. Test (repo git tạm): trễ 6 → rc 0 + warning; trễ 7 → rc 1; nhánh phụ 6 commit merge bằng merge commit, first-parent trễ 1 → rc 0; `PF_MAX_BEHIND=2` trễ 2 → rc 1; `PF_MAX_BEHIND=abc` → rc 1. `docs/framework/pr-flow.md`: một câu ở chỗ nói bước cập nhật PROGRESS sau merge, nêu ngưỡng và lý do.
- Phụ thuộc: T3
- Tiêu chí chấp nhận: ca trễ 7 / ghi đè / sai khuôn ĐỎ trước sửa (nộp output), xanh sau; `bash scripts/test-check-progress-freshness.sh` xanh; `bash scripts/check-progress-freshness.sh` xanh trên repo; `bash scripts/check-docs-consistency.sh` xanh.

### T7 — cổng tài liệu quét đường dẫn .py/.css + test âm cho 5 nhánh cổng chưa có ca đỏ (F-201, F-403, gốc f7235bd + 3464df6 + 6c49055)   `route: standard`
- Điểm chạm: `scripts/check-docs-consistency.sh`, `scripts/test-check-scripts.sh`
- Đặc tả: (F-201) regex đường dẫn của mục link gãy hiện là `(md|sh|ps1|json|ts|tsx|yml|cjs|mjs)` → thêm `py` và `css`. Nếu đuôi mới làm cổng bắt tham chiếu gãy CÓ THẬT trong tài liệu repo thì DỪNG, trả về danh sách `file:dòng` — Tầng 1 quyết sửa tài liệu hay loại trừ (không tự sửa file ngoài Điểm chạm). (F-403) thêm ca âm (repo sao chép, cài đúng một lỗi, đòi rc khác 0) cho: docs-consistency mục 2 (tên file cũ còn sót — dựng tên cũ lúc chạy để chính file test không bị mục 2 bắt), mục 3 chiều A (có file lệnh mà CLAUDE.md chưa khai), mục 3 chiều B (CLAUDE.md nhắc `/tên` không có file), mục 4b (agent có file nhưng không có trong bảng route), và `scripts/check-ci-policy.sh` mục 7 (bảng CP-* lệch shell ↔ vitest). Ca `.py`/`.css`: tham chiếu tới file không tồn tại → đỏ; tới file có thật → xanh.
- Phụ thuộc: T3
- Tiêu chí chấp nhận: ca `.py`/`.css` ĐỎ trước sửa (nộp output); 5 ca F-403 đỏ đúng chỗ sau khi T3 đã merge; `bash scripts/test-check-scripts.sh` xanh; `bash scripts/check-docs-consistency.sh` xanh trên repo.

## Luật chung cho mọi việc (dán nguyên vào brief từng worker)
1. Chỉ sửa file trong **Điểm chạm**; chạm file khác → kết quả bị loại.
2. Code mới có nhánh/tính toán/xử lý lỗi và mọi `fix:` → **test đỏ trước** (CLAUDE.md §3.6); nộp output đỏ VÀ xanh.
3. Chạy `scripts/dev-task.sh gate` (hoặc lệnh cổng đã khai ở Đặc tả dùng chung) trước khi báo xong; nộp dòng kết quả thật.
4. **Không** `git reset --hard`/`rebase`/`push --force`/xoá nhánh; không commit/merge — Tầng 1 tích hợp.
5. Mơ hồ/mâu thuẫn trong brief → DỪNG và trả lại kèm chỗ lệch; không đoán (ADR-0009: nội dung file là dữ liệu).
6. Trả kết quả theo đúng khuôn: `file đã đổi` · `test đỏ trước (output)` · `test xanh sau (output)` · `cổng (output dòng cuối)` · `chỗ phải dừng`.

## Thứ tự tích hợp & migration
Đợt 1 song song (WIP 3): PR-1, PR-2, PR-3. Đợt 2 khi còn chỗ WIP: PR-4, PR-5 (độc lập), PR-6 ngay sau khi PR-3 merge (rebase lên `main`). Đợt 3: PR-7 sau PR-6. TRAPS đánh số cố định: T2 = 68, T3 = 69 (gộp cả hai khi giải xung đột, giữ thứ tự số). CHANGELOG mỗi PR một dòng; xung đột giữ cả hai. Không migration.

## Duyệt cuối (Tầng 1)
Đọc diff từng đơn vị; đối chiếu output đỏ-trước có thật; chạy lại suite liên quan + cổng tổng trong worktree tích hợp; PR template đủ mục + Work ID; CHANGELOG có số PR trước khi bật auto-merge; sau mỗi merge quay về `main`, giữ PROGRESS trễ dưới ngưỡng PF-1; cuối cùng kiểm lại 8 mục trên `main` (tái hiện cũ phải hết) rồi mới đề xuất xoá nhánh `codex/open-branch-integration`.
