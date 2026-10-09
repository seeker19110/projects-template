# Công việc: O-5 — dời khối dò stack, rút tài liệu trùng (chu kỳ tối ưu quy trình, phần kế hoạch có điều kiện)

- Work ID: 2026-10-08-process-optimization-o5
- Yêu cầu / outcome: chủ repo nhắn "tiếp các việc khác cho đến khi xong" (2026-10-08) → chạm điều kiện xem lại
  "chủ repo yêu cầu" của O-5/O-6 trong `docs/reports/2026-10-08-process-optimization.md`. O-5 = P-B7 (dời `_cmd_*`
  sang `scripts/_stack-detect.sh`, sửa usage) + P-C8..P-C11 (rút tài liệu lặp về con trỏ, một chỉ mục đủ). Không đổi
  luật, không hạ cổng, không dependency; đo radar/byte trước–sau.
- Trạng thái: Done (2026-10-08).
- Chủ trì / writer: phiên chính; ba worker trong worktree riêng (A: P-B7 · B: P-C8 + P-C11 · C: P-C9), phiên chính tự
  làm P-C10 (CLAUDE.md §1/§11, AGENTS.md, pr-flow.md:9) vì đụng file luật.
- Mức rủi ro / số PR: M refactor/docs không đổi hành vi; một PR (ràng buộc nhánh của phiên), nhiều commit theo đơn vị.
- Scope / non-goal: `scripts/dev-task.sh`, `scripts/_stack-detect.sh`, `.claude/commands`, `.claude/agents`,
  `docs/framework/*`, `CLAUDE.md`, `AGENTS.md`, `PROJECT.md`, CODEMAP. Non-goal: O-6 (P-B10/B11/C12 — PR sau), đổi luật.
- Spec / goal / issue: kế hoạch + Approved §3d trong report (O-5/O-6 duyệt bổ sung 2026-10-08 theo ủy quyền, điều kiện
  "chủ repo yêu cầu" đã chạm); hồ sơ trước: `docs/work/2026-10-08-process-optimization-o4b/done.md` (#219).
- Nhánh / base SHA / thời điểm reconcile: claude/relaxed-knuth-f1ejlq (reset từ origin/main) / 82c2af5 / 2026-10-08T23:40Z.

## Baseline (đo thật trên 82c2af5)

- Radar 99/100; kỷ luật kích thước 95.6 (4 file mã > 400 dòng, trong đó `scripts/dev-task.sh` 585).
- `CLAUDE.md` 41 182 byte / 157 dòng (trần 42 000); `AGENTS.md` 17 329 byte; `pr-flow.md:9` 3 576 ký tự.
- `02-ai-rules-and-project-template.md` 179 dòng; `docs/framework/README.md` thiếu 5 file (`industry-standards`,
  `lean-delivery-benchmark`, `pr-flow`, `quality-gates-by-profile`, `strict-gate-contract`); `quality-supplements.md`
  có hai bảng mục lục cùng nội dung.

## Kế hoạch và phân công

- Worker A (standard): P-B7 — dời `node_has_script`, `_node_aliases`, 13 `_cmd_*`, `detected_cmd` sang
  `_stack-detect.sh`; sửa usage `dev-task.sh` (hai chỗ kê task lệch nhau, thiếu `format-file`); CODEMAP; TDD ngoại lệ 2.
- Worker B (standard): P-C8 — `02-ai-rules…` rút còn PHẦN C + con trỏ (PHẦN A → CLAUDE §4–§7/§9, PHẦN B → `PROJECT.md`
  gốc), sửa tham chiếu; P-C11 — `docs/framework/README.md` là chỉ mục đủ, `quality-supplements.md` một bảng, DoR/handoff
  trỏ `standard-delivery.md`.
- Worker C (standard): P-C9 — lệnh `audit-full`/`completion`/`audit-optimize`/`incident`/`bootstrap`/`maintain` thành
  con trỏ mỏng + delta vào playbook; `coordinator.md` bỏ bảng route chép (orchestration là nguồn; dòng 44-47 là dữ liệu
  của cổng docs-consistency mục 4c — không đụng); `bootstrap.md` bỏ bất biến web hard-code (trái §0b).
- Phiên chính: P-C10, review diff từng worker, `git apply --index`, full gate qua hook, commit theo đơn vị, PR, PROGRESS.

## Quyết định và bằng chứng

- Ba worker xong (A: 4 file +170/−166; B: 8 file +31/−162; C: 7 file +39/−199), mỗi worker chạy docs-consistency + suite
  liên quan OK trong worktree. Phiên chính review toàn bộ diff, `git apply --index`, rồi dời thêm `declared_format_file`/
  `resolve_format_file` (30 dòng) để `dev-task.sh` xuống 399 dòng (dưới trần 400 của radar) — cùng khuôn dời cơ học.
- Quyết định §3d: (a) `maintain-run/cron` tả một nơi ở `maintainer.md` (file được `maintain-run.sh` nạp làm prompt);
  (b) lệnh thiếu playbook ở dự án đích → báo người dùng chạy `copy-framework.sh`, không tự suy quy trình (thu hẹp cố ý,
  tóm tắt đã xoá); (c) CLAUDE.md §11 gộp vào dòng `adopt-from-outside.md` ở §1, AGENTS.md trỏ theo; (d) không thêm
  TRAPS mới — không phải bug, là trùng lặp tài liệu đã biết (khuôn 19 chỉ về danh sách copy).
- Số đo: radar 99 → 100 (kích thước 95.6 → 96.7); `CLAUDE.md` 41 182 → 34 292 byte, 157 → 142 dòng; `dev-task.sh`
  585 → 399; `02-ai-rules` 179 → 65; 6 lệnh 244 → 89 dòng; `pr-flow.md:9` 3 576 ký tự → 8 gạch đầu dòng.
- Commit 1 `4d6be23` (refactor P-B7) và commit 2 `e0a1419` (tài liệu P-C8..P-C11) đều qua full gate của hook.

## Lần thử / blocker

- Gate đỏ hai lần trước commit 1, đều ở docs-consistency mục 1: report trỏ `done.md` chưa tồn tại (sửa → `working.md`,
  đổi lại khi đóng), và fixture `test-check-scripts.sh` copy theo `git ls-files` nên `working.md` chưa stage bị coi là
  thiếu → `git add -N`. Không đụng cổng.

## Bàn giao / bước tiếp theo

- O-6 (P-B10) đi PR kế tiếp, hồ sơ `docs/work/2026-10-08-process-optimization-o6/done.md`.

## Nghiệm thu cuối (chỉ điền khi đủ bằng chứng)

- PR #221 MERGED (squash) 2026-10-08T23:58Z → `origin/main` = `7ab88e6`. CI head e0a1419: 12 check xanh
  (framework-lint Linux + Windows, copy-framework-smoke, docs-consistency, protection-guard, metadata, dependency-review,
  gitleaks, CodeQL ×3; progress-freshness skipped hợp lệ), không lần đỏ nào, không review thread.
- DoD: không đổi hành vi (`--print` byte-identical, 111 ✅ test-dev-task; mọi luật giữ bằng con trỏ, docs-consistency
  11 mục OK, test chuỗi 11 OK); số đo trước–sau ghi ở mục trên; tài liệu (report, CODEMAP, hồ sơ) đi cùng PR.
