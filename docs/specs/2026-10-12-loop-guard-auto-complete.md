# Feature spec: ba cổng máy cho vòng lặp `/auto-complete` — giữ lượt, chuỗi đỏ cùng chữ ký, goal có bằng chứng

| Thuộc tính | Giá trị |
| --- | --- |
| Issue / Goal | Yêu cầu chủ repo 2026-10-12: "nghiên cứu sâu vòng lặp trong coding phát triển phần mềm để nâng cấp cho dự án tiến đến việc tự động hoàn thành khi có mục tiêu, yêu cầu và người dùng bật /auto-complete". Hồ sơ `docs/work/2026-10-12-loop-research-auto-complete/working.md`; bản đối chiếu `docs/reports/2026-10-12-doi-chieu-vong-lap-coding.md` |
| Spec owner | Phiên chính |
| State | **Approved for implementation** |
| Approver / date | Phiên chính duyệt theo ủy quyền toàn cục (`standard-delivery.md` §3d); 2026-10-12 |
| Last updated | 2026-10-12 |

> Spec gọn (mức M): một PR, ba đơn vị độc lập (hook mới, sửa hook có sẵn, một mục docs-consistency); không đổi
> schema/API công khai/auth, không thêm dependency ngoài `jq` đã dùng ở các hook khác.
>
> **Ghi chú trình tự:** research (bản đối chiếu) đi trước code đúng luật; spec này viết sau khi ba đơn vị đã có test
> đỏ-trước và cổng xanh, trước khi mở PR — lệch so với "Approved trước khi sửa source" của `CLAUDE.md` §2. Ghi ở
> mục "Deviation from spec" của PR; nội dung spec chốt từ kết quả đối chiếu, không viết lại cho khớp code.

## 1. Problem, user và evidence

`/auto-complete` nói "chỉ dừng ở §9/§8" nhưng mọi điều kiện dừng đều là **văn xuôi**: không gì ngăn lượt kết thúc khi
hồ sơ còn `Active`; "cùng một failure sửa tối đa 3 lần" (§8) không ai đếm; goal file có cột `State`/`Evidence` mà
không script nào đọc (đính chính B của bản đối chiếu ralph 2026-10-10). Bản đối chiếu 2026-10-12 so 41 cơ chế của
các vòng lặp ngoài (Anthropic harness/`/goal`/ralph-wiggum, OpenHands StuckDetector, Aider, SWE-agent, Codex Goals,
Cursor, Copilot) với cổng đang chạy ở đây (`grep` theo `adopt-from-outside.md` §3): 38 đã có và sâu hơn / nông hơn
không đáng lấy / chưa cần; **3 tốt hơn bản hiện có** theo dạng "kiểm được hơn" (văn xuôi → cổng máy).

| Đã có và sâu hơn | Đã có nhưng nông hơn | Chưa có / quyết định |
| --- | --- | --- |
| Hồ sơ `working.md` + trạng thái, §8 stop conditions, `usage-guard` wind-down, cổng commit chặn đỏ: giữ nguyên | (N2) dừng lượt chỉ bằng văn xuôi → hook Stop đọc **file trạng thái**; (N1) "3 lần cùng failure" không đếm → đếm theo chữ ký ở cổng commit; (N3) goal DONE không cần bằng chứng → mục 15 docs-consistency | Runner không giám sát (X1): không lấy — quyết định bảo mật 2026-10-10 còn hiệu lực. `/goal` làm lớp chính: không — đánh giá từ transcript là lời khai (`CLAUDE.md` §4); chỉ là lớp tuỳ chọn |

## 2. Outcome, baseline, target và guardrails

- Baseline: 0 cổng máy cho ba điều kiện trên; lượt `/auto-complete` có thể kết thúc với hồ sơ còn `Active`.
- Target: (a) marker bật → lượt chỉ kết thúc khi hồ sơ không còn `Active`, hoặc một điều kiện an toàn (trần lượt,
  lặp y hệt, wind-down, chuỗi đỏ) cho dừng; (b) cổng commit đỏ lần 2 cùng chữ ký nhắc tầng, lần 3 nhắc §8 BLOCKED,
  chữ ký khác không bị tính dồn; (c) goal DONE thiếu bằng chứng hoặc COMPLETE còn slice mở → docs-consistency đỏ.
- Guardrails: hook **fail-open có nói ra** khi thiếu `jq` (không khoá phiên vì môi trường); trần
  `AUTO_COMPLETE_MAX_CONTINUES` mặc định 20; marker gitignored, sống trong một phiên (`session-resume.sh` xoá khi
  phiên mới, giữ khi compact/resume); không hạ cổng nào; không đổi §3d/§8/§9.

## 5. Scope / non-goals

Trong: `.claude/hooks/auto-complete-guard.sh` (mới) + nối ở hai settings; `.claude/hooks/pre-commit-gate.sh` (đếm
chuỗi đỏ); `.claude/hooks/session-resume.sh` (vòng đời marker); `scripts/_docs-consistency-structure.sh` mục 15;
`.claude/commands/auto-complete.md` bước 0; suite test + CI + tài liệu bản đồ. Ngoài: runner không giám sát, agent
"decider", cổng đọc transcript, sửa `/auto`/`/completion` (điều kiện xem lại: khi có lượt `/auto-complete` thật dừng
sớm mà ba cổng này không bắt được — ghi vào `TRAPS.md`).

## 9. Acceptance criteria

- AC-1: Không có marker → hook Stop không can thiệp (exit 0, không JSON).
- AC-2: Marker + hồ sơ `Active` → `{"decision":"block"}`, reason mang mục "Bàn giao", đếm lượt.
- AC-3: Hồ sơ `Blocked`/`Waiting`, đã rename `done.md`, đủ trần lượt, lời cuối lặp y hệt, usage-guard đã nhắc → cho dừng.
- AC-4: Chuỗi đỏ cổng commit ≥ 3 → nhắc §8 BLOCKED đúng một lần rồi cho dừng; thiếu `jq` → cho dừng kèm cảnh báo stderr.
- AC-5: `session-resume.sh` xoá marker ở phiên mới (startup/clear), giữ ở compact/resume.
- AC-6: Cổng commit: cùng chữ ký lần 2 nhắc tầng, lần 3 nhắc §8; chữ ký khác về 1; xanh xoá bộ đếm; đỏ không in chữ ký vẫn đếm.
- AC-7: docs-consistency mục 15: slice DONE ô bằng chứng rỗng → đỏ; goal COMPLETE còn slice mở → đỏ; đủ bằng chứng → không chặn oan.

| AC | Bằng chứng |
| --- | --- |
| AC-1 | `scripts/test-hooks-loop.sh::== 1. Không có marker` |
| AC-2 | `scripts/test-hooks-loop.sh::== 2. Marker + hồ sơ Active`, `scripts/test-hooks-loop.sh::== 11. NEGATIVE` |
| AC-3 | `scripts/test-hooks-loop.sh::== 3. Hồ sơ Blocked / Waiting`, `scripts/test-hooks-loop.sh::== 4. working.md đã rename done.md`, `scripts/test-hooks-loop.sh::== 5. Trần lượt`, `scripts/test-hooks-loop.sh::== 6. Lời cuối lặp y hệt`, `scripts/test-hooks-loop.sh::== 8. usage-guard đã nhắc wind-down` |
| AC-4 | `scripts/test-hooks-loop.sh::== 7. Chuỗi đỏ cổng commit`, `scripts/test-hooks-loop.sh::== 9. Thiếu jq` |
| AC-5 | `scripts/test-hooks-loop.sh::== 10. session-resume` |
| AC-6 | `scripts/test-hooks-gate-guard.sh::== 20. pre-commit-gate: chuỗi đỏ CÙNG chữ ký` |
| AC-7 | `scripts/test-check-scripts.sh::bắt được slice DONE không có Evidence (mục 15)`, `scripts/test-check-scripts.sh::bắt được goal COMPLETE còn slice BUILD (mục 15)`, `scripts/test-check-scripts.sh::KHÔNG chặn oan goal COMPLETE đủ bằng chứng` |

## 11. Architecture và code touchpoints

- `.claude/hooks/auto-complete-guard.sh` (mới, hook Stop): đọc marker .claude/.auto-complete-loop (Work ID, `n=`,
  `last=`, `nudged=`), hồ sơ docs/work/<id>/working.md, .claude/.gate-red-streak, .claude/.winddown-nudged;
  nối ở `.claude/settings.json` và `.claude/settings-shared-default.json`.
- `.claude/hooks/pre-commit-gate.sh`: chữ ký = dòng `FAIL:`/`BLOCKED:` đầu tiên của `scripts/dev-task.sh gate`
  (không có → `gate-exit-<rc>`), bộ đếm .claude/.gate-red-streak.
- `.claude/hooks/session-resume.sh`: xoá marker theo `source` của SessionStart.
- `scripts/_docs-consistency-structure.sh`: `check_goal_file` (mục 15) cho `docs/goals/*.md` trừ README.
- `.claude/commands/auto-complete.md` bước 0; test: `scripts/test-hooks-loop.sh` (mới, 11 mục, nối `.github/workflows/ci.yml`),
  `scripts/test-hooks-gate-guard.sh` mục 20, `scripts/test-check-scripts.sh` mục 15; bản đồ: `CODEMAP.md`,
  `docs/FEATURE-MAP.md` FT-74, `docs/framework/models-and-automation.md` bảng Hook; `.gitignore` hai file trạng thái.

## Approval

Approved for implementation — phiên chính duyệt theo ủy quyền chủ repo ngày 2026-10-12; một PR, không hạ cổng,
ba đơn vị đều có test đỏ-trước (ADR-0005).
