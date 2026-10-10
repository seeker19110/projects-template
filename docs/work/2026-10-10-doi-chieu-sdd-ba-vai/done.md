# Công việc: Đối chiếu SDD ba vai (Spec-First / Spec-Anchored / Spec-as-Source) → khung + đích

- Work ID: 2026-10-10-doi-chieu-sdd-ba-vai
- Yêu cầu / outcome: người dùng gửi ảnh reel "Spec-Driven Development — 3 roles of specification in SDLC" và hỏi "dự án đã áp dụng chưa? tích hợp sâu vào dự án khung và dự án đích" → TRIGGER `docs/framework/adopt-from-outside.md` (đọc trước khi chép một dòng): bản đối chiếu ba cột `docs/reports/2026-10-10-doi-chieu-sdd-ba-vai.md`; chỉ lấy hạng mục qua cổng §2 (sự cố thật) và không mâu thuẫn luật (§4).
- Trạng thái: Done (PR #261 MERGED)
- Chủ trì / writer: phiên chính (Fable 5.1), tự làm (một PR, mức S theo §3c: `fix`/`ci`/`docs`, không đổi schema/API/auth).
- Mức rủi ro / số PR: S; 1 PR. Lý do một PR: cổng CI đích + test + sửa engine + báo cáo mô tả cùng một thay đổi (CLAUDE.md §8 bước 0: tài liệu đi cùng PR).
- Scope / non-goal: Scope = đo 12 hạng mục của sơ đồ với cổng đang chạy; lấy đúng điểm nông (CI đích không chạy contract spec); sửa lỗi lộ ra (pyc cũ). Non-goal = không thêm cổng "mọi PR phải nêu spec cũ" (chưa có sự cố, mâu thuẫn luật spec-theo-thời-điểm → câu hỏi cho chủ repo); không sinh PLAN từ AC; không sửa `dev-task.sh` (399 dòng, sát trần).
- Spec / goal / issue: không cần spec (mức S). Phương pháp: `docs/framework/adopt-from-outside.md`.
- Nhánh / base SHA / thời điểm reconcile: `docs/doi-chieu-sdd` @ `2ac2a37` · 2026-10-10T02:26:45Z; worktree riêng ở scratchpad (TRAPS 63: mỗi phiên một worktree).

## Kế hoạch và phân công

Một outcome / một PR, phiên chính tự làm: (1) đọc `adopt-from-outside.md`; (2) grep cổng đang chạy (pr-policy, ci.yml, ci-target.yml, spec-compiler C-1..C-4/--trace, radar `_spec_quality`, sweep, `_plan_check`, manifest); (3) đo trôi touchpoint/bằng chứng bằng git log; (4) ba cột + cổng §2 + §4; (5) test đỏ-trước cho bước CI đích → thêm bước → xanh; (6) báo cáo, README specs, FEATURE-MAP, TRAPS, CHANGELOG, PROGRESS; (7) cổng local → PR → số PR vào CHANGELOG/TRAPS → auto-merge.

## Quyết định và bằng chứng

- Kết quả đo: 8 "đã có và sâu hơn", 1 "nông hơn" (Spec-Anchored ở đích: engine phát nhưng `ci-target.yml` không gọi — `grep spec` → 0), 3 "chưa có" (2 chưa cần kèm điều kiện, 1 bản đồ từ vựng 3 dòng). Lấy 2 + 1 lỗi lộ ra.
- Sự cố thật cho điểm nông: TRAPS 11 (chính 4 engine này từng không nối CI ở khung — audit 2026-09-13 CAO-1), 25, 3/15.
- Đỏ-trước: `bash scripts/test-adoption-smoke.sh` trước khi thêm bước → `❌ node/python: CI drop-in không chạy spec-compiler` (2 ca, rc=1). Sau khi thêm bước: ca 1–2 xanh, ca 3 đỏ với thông báo của ca 2 → lỗi pyc cũ (xem dưới). Sau sửa `spec-compiler.py`: 6/6 ca xanh, `OK —`.
- Lỗi lộ ra (TRAPS 64): Python dùng lại `.pyc` khi nguồn sinh lại cùng mtime-giây + cùng kích thước; tái hiện cô lập có-thật → không-có → có-thật in `OK/OK/OK` (ca giữa xanh oan). Sửa: `shutil.rmtree(<out-dir>/__pycache__)` trước khi sinh. Test tái hiện = ca 3 của `spec_contract_expect`.
- §4 mâu thuẫn luật: cổng "mọi PR chạm touchpoint spec cũ phải nêu spec" ngược với spec-theo-thời-điểm (TRAPS 60 ghi chú, `contract-exempt` lịch sử) và sẽ đỏ gần mọi PR (139/201 touchpoint đã đổi sau spec) → không tự hoà giải; câu hỏi ở cuối báo cáo.
- Bước CI đặt ở `ci-target.yml` sau `gate` thay vì trong `dev-task.sh gate` (399 dòng, trần radar 400) — ghi `xem lại khi` trong báo cáo.

## Lần thử / blocker

- Máy này thiếu `shellcheck`/`radon`/`coverage`/`pwsh`: cài `shellcheck-py`, `radon`, `coverage` qua pip; `pwsh` không có → `dev-task.sh doctor` BLOCKED ở `gate_tools`; chạy từng cổng tay + CI Linux/Windows là cổng thật (cùng cách các hồ sơ 2026-10-09/10).

## Bàn giao / bước tiếp theo

- Đã làm: cổng tay xanh; commit `c4d623c`; PR #261 (`subscribe_pr_activity` bật); commit 2 ghi số PR vào CHANGELOG/TRAPS 64. Còn: bật auto-merge; sau merge đổi file này thành `done.md` kèm SHA, cập nhật PROGRESS.
- Chờ chủ repo trả lời câu hỏi cuối báo cáo (cổng hẹp "PR sửa file bằng chứng phải nêu spec": mở ngay / giữ chưa cần).

## Nghiệm thu cuối (chỉ điền khi đủ bằng chứng)

- PR #261 MERGED (squash) → `main` @ `cb73c1f`; 12/12 check xanh trên head `4b359de` (framework-lint Linux+Windows, docs-consistency,
  copy-framework-smoke, progress-freshness, protection-guard, metadata, CodeQL ×3, gitleaks, dependency-review). Check `gate` đỏ ở
  commit đầu `c4d623c` là do concurrency huỷ job khi push commit 2 (aggregate đếm cancelled là thất bại), không phải lỗi mã.
- Local: 20/20 suite shell, 6/6 test Python, shellcheck/docs-consistency/ci-policy/progress-freshness/CC xanh; hook pre-commit bỏ qua
  có chủ đích (thiếu `pwsh`), CI là cổng thật.
- DoD: bản đối chiếu ba cột đủ + đính chính (A)(B)(C) + điều kiện xem lại; lấy 2 + TRAPS 64; test đỏ-trước có output. Giới hạn: câu hỏi
  cổng hẹp "PR sửa file bằng chứng phải nêu spec" còn mở, chờ chủ repo (đề xuất giữ "chưa cần"). Nghiệm thu: phiên chính theo ủy quyền
  §3d, 2026-10-10.
