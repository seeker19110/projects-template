# Công việc: Chạy progress-freshness cả ở PR

- Work ID: 2026-10-09-progress-freshness-on-pr
- Yêu cầu / outcome: người dùng "cho progress-freshness chạy cả ở PR" — PROGRESS.md lỗi thời phải đỏ ngay ở PR, không lọt vào `main` (TRAPS 8, #245).
- Trạng thái: Done
- Chủ trì / writer: phiên chính
- Mức rủi ro / số PR: S, 1 PR (đổi dây CI + test, không đổi logic script)
- Scope / non-goal: bỏ `if:` chỉ-main của job `progress-freshness`, sổ `SKIP_ALLOWED` rỗng, test khoá nối dây + đối chứng merge ref, sửa tài liệu nói "chỉ trên main". Non-goal: đổi PF-1..4.
- Spec / goal / issue: mức S — không spec (standard-delivery §3c).
- Nhánh / base SHA / thời điểm reconcile: `claude/laughing-clarke-3uzhft` @ `1e9f962` · 2026-10-09T15:24:53Z

## Kế hoạch và phân công

Một PR, phiên chính tự làm: `ci.yml`, `scripts/test-check-scripts.sh` (ca nối dây + đối chứng merge ref; CP-5 (b)
đổi sang kê thừa `protection-guard`), comment `check-progress-freshness.sh`/`check-ci-policy.sh`, `pr-flow.md`,
TRAPS 8, FEATURE-MAP FT-67, CODEMAP.

## Quyết định và bằng chứng

- Lý do lo "báo oan" cũ không đứng: ở PR, CI checkout merge ref (chứa lịch sử `main` → PF-1 đúng), nhánh PR còn
  mở nên tồn tại (PF-2), PF-3/PF-4 là nhất quán nội bộ file. Nếu `main` đã lỗi thời thì PR đỏ — đúng ý (buộc sửa).
- Đỏ-trước: `bash scripts/test-check-scripts.sh` exit=1, đúng 1 ❌ "job progress-freshness vẫn bị 'if:' loại khỏi PR";
  ca đối chứng merge ref đã xanh từ trước (script không đổi logic).
- Phát hiện khi chạy cục bộ: `check-progress-freshness.sh` exit=1 trên `main` `1e9f962` — PF-3: SHA trỏ #247 nhưng
  dòng "Giai đoạn" chỉ nêu tới #246 (#248 sửa SHA mà sót dòng này, đúng TRAPS 8). Sửa trong PR này (SHA → `1e9f962`,
  "Giai đoạn" nêu #248); sau sửa exit=0. Đây đúng loại lỗi mà job chạy ở PR sẽ chặn trước merge.

## Lần thử / blocker

Chưa có.

## Bàn giao / bước tiếp theo

Không còn — đã đóng.

## Nghiệm thu cuối (chỉ điền khi đủ bằng chứng)

- PR #250 MERGED → `98a64be` trên `main` (squash). Trước merge có xung đột `PROGRESS.md` với #249, đã giải bằng
  merge commit `3fde248`, giữ nội dung của cả hai phía.
- CI head `3fde248`: 13/13 check xanh, trong đó `progress-freshness` chạy thật trên PR (lần đầu) và xanh; head trước
  `bfa0689` cũng xanh toàn bộ.
- DoD: job chạy ở PR, test khoá nối dây + đối chứng merge ref, CP-5 khớp sổ rỗng, tài liệu không còn nói "chỉ trên main".
- Giới hạn: `main` lỗi thời sẽ làm đỏ mọi PR tới khi sửa (cố ý).
- Nghiệm thu: phiên chính theo ủy quyền §3d, 2026-10-09.
