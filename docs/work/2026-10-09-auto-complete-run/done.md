# Công việc: lượt `/auto-complete` trên chính repo khung (2026-10-09)

- Work ID: 2026-10-09-auto-complete-run
- Yêu cầu / outcome: chủ repo gõ `/auto-complete` không kèm mô tả → phiên chính chốt outcome từ ngữ cảnh: đưa repo khung (brownfield) tới Definition of Complete theo trạng thái đo thật hôm nay.
- Trạng thái: Done
- Chủ trì / writer: phiên chính
- Mức rủi ro / số PR: S; 1 PR (refactor không đổi hành vi + closeout tài liệu cùng PR)
- Scope / non-goal: chỉ phát hiện đo được bằng engine thật; không mở tính năng mới; FT-41 (cần tài khoản thật) và FT-13 (giới hạn harness) ghi BLOCKED/chấp nhận có điều kiện, không tự bịa bằng chứng.
- Spec / goal / issue: không (mức S)
- Nhánh / base SHA / thời điểm reconcile: `claude/kind-cori-k7x4p6` từ `origin/main` a208b4f, 2026-10-09

## Kế hoạch và phân công

Bước 1 `/auto` (brownfield): đo hiện trạng → 1 PR → phiên chính tự làm (§3c). Bước 2 `/completion` Pha 0–4 trên cùng lượt.

## Quyết định và bằng chứng

- Chọn: outcome = DoC của repo khung · Loại: dừng hỏi "làm gì" · Bậc: §3d "chốt outcome từ ngữ cảnh đã có" — ngữ cảnh phiên là hoàn thiện khung; hỏi lại là vi phạm ủy quyền.
- Đo 2026-10-09 (base a208b4f): radar 100/100 nhưng "Việc cần làm" 1 mục — `scripts/subagent-dispatch.py` 404 dòng (> 400, do #239 thêm `--check-plan`); sweep `--strict --no-deps` 🔴 0 🟡 0; docs-consistency ✅; ci-policy ✅; FEATURE-MAP: FT-13 ⚠️ (harness, có chủ ý), FT-41 🚧 (cần tài khoản thật).
- Chọn: tách `check_plan` sang helper `scripts/_plan_check.py` (khuôn `_telemetry_report.py`, R-01) · Loại: nới trần 400 / xoá comment cho đủ dòng · Bậc: (1) nới trần là tự bịt mắt (radar ghi rõ), (2) helper thuần ít coupling hơn.
- Chọn: FT-41 giữ 🚧, ghi BLOCKED §8 (cần tài khoản/secret thật) · Loại: giả lập bước 6–8 · Bậc: (1) không bịa bằng chứng (§4).
- Chọn: closeout (COMPLETION-PLAN, AUDIT-STATUS, báo cáo, PROGRESS) đi cùng PR refactor · Loại: PR dọn dẹp sau · Bậc: luật §8 mục 0 (không tách PR dọn dẹp).
- Bằng chứng Pha 4 (cây đã stage, base a208b4f): radar 100/100 + "Việc cần làm" rỗng + 46/46 script có cổng; characterization 51/51; coverage 96 %; docs-consistency OK; progress-freshness OK; test-check-scripts OK; test-copy-framework OK; test-adoption-smoke OK; `dev-task.sh gate` PASS 4/4.
- Chọn: FT-13 chấp nhận có điều kiện (xem lại khi harness cấp nested agent) · Loại: xoá coordinator · Bậc: (2) xoá là mất playbook phiên chính đang dùng làm Tầng 2.

## Lần thử / blocker

(chưa có)

## Bàn giao / bước tiếp theo

Đã xong: PR #242.

## Nghiệm thu cuối (chỉ điền khi đủ bằng chứng)

DoD/DoC đạt: PR #242 MERGED (squash) 2026-10-09 → `main` 8517a16; required checks xanh trên head `94185ae`; radar 100/100 "Việc cần làm" rỗng. Nợ có chủ đích: FT-41 BLOCKED (cần tài khoản thật). Nghiệm thu: phiên chính theo ủy quyền §3d, 2026-10-09.
