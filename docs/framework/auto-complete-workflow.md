# Workflow tham chiếu `/auto-complete` — từ ý tưởng tới bàn giao, vòng lặp có trạng thái máy tính

> Tài liệu **tham chiếu một trang** cho lệnh tự động duy nhất của khung. Luật gốc không đổi và không chép lại ở đây:
> `standard-delivery.md` (§3 cổng, §3b tầng, §3c mức, §3d ủy quyền, §3e hồ sơ, §4 Goal Loop, §8 dừng), `project-completion.md`
> (Pha 0–4), `pr-flow.md`, `orchestration-3-tier.md`. File này trả lời đúng ba câu: **trạng thái nằm ở đâu, ai tính bước kế tiếp,
> dừng theo kiểu gì.** Thiết kế: ADR-0012; đối chiếu nguồn ngoài: `docs/reports/2026-10-12-thiet-ke-lai-vong-lap.md`.

## 1. Nguyên tắc kiến trúc (3 dòng)

1. **Trạng thái là artifact trong repo** (`docs/work/<id>/working.md`, `docs/goals/<id>.md`, `docs/ops/COMPLETION-PLAN.md`,
   `docs/ops/release-readiness.md`, git/PR/CI) — không phải lời model, không phải bộ nhớ phiên.
2. **Máy đo trước, model quyết sau:** đầu mỗi vòng `scripts/loop-state.sh` đọc artifact → một khối trạng thái + verdict có kiểu +
   bước kế tiếp; model chọn *cách làm* trong phạm vi bước đó (§3d), không tự suy "đang ở đâu".
3. **Dừng theo file trạng thái + vân tay artifact**, không theo chuỗi "đã xong": hook Stop chỉ cho kết lượt khi `Blocked`/`Waiting`/
   `done.md`, trần lượt, wind-down, chuỗi đỏ ≥ 3, hoặc **2 lượt liên tiếp không artifact nào đổi**.

## 2. Sơ đồ pha (ánh xạ 9 cổng §3 ↔ Giai đoạn A/B/C của lệnh)

```
Ý tưởng ──► A1 Research ──► A2 Kế hoạch ──► A3 Duyệt §3d ──► A4 Thực thi (vòng lặp, mỗi vòng = 1 PR)
             /consult        PLAN.md          spec Approved      ┌──────────────────────────────────────┐
             /bootstrap      --check-plan     ADR ≥ 2 phương án  │ loop-state → next → làm → /gate →    │
             version-check   goal slices                         │ /review → PR → auto-merge → reconcile│
                                                                 └──────────────┬───────────────────────┘
                                                                     mọi PR merge thật (SHA trên main)
B0 Dò hiện trạng ──► B1 Audit 12 nhóm ──► B2 COMPLETION-PLAN + DoC ──► B3 Thực thi đợt ──► B4 Re-audit hội tụ
  FEATURE-MAP          F-xxx                 W-xxx ⬜/🔄/✅/➖           mỗi W một PR          0 Cao mở
                                                                     │
C Bàn giao: clone sạch + smoke ──► release-readiness GO/NO-GO ──► done.md (13b) ──► rm marker ──► báo cáo
```

| Pha | Cổng vào (máy kiểm) | Artifact ra | Ai quyết chuyển |
| --- | --- | --- | --- |
| A1 | hồ sơ `working.md` tồn tại (`new-work.sh`) | hồ sơ + ADR/stack | phiên chính (§3d) |
| A2 | — | `PLAN.md` qua `subagent-dispatch.sh --check-plan` (exit 0) | máy khoá brief, phiên chính duyệt |
| A3 | spec `Approved` (`pr-policy.yml` cho PR `feat`); ADR ≥ 2 phương án (docs-consistency 16) | spec, ADR, goal slices | phiên chính |
| A4 | `loop-state` verdict `continue` + slice `ready` | PR nhỏ, test cùng code | máy: cổng commit/CI; phiên chính: review tích hợp |
| B0–B4 | mọi PR A merge thật; `COMPLETION-PLAN.md` đếm được | 4 file trạng thái `project-completion.md` | phiên chính tự duyệt kế hoạch (§3d) |
| C | `completion.open=0` ∧ `handoff=GO` ∧ goal không slice mở | `done.md` có PR/SHA (13b) | phiên chính nghiệm thu |

## 3. Một vòng lặp (iteration contract)

```
loop-state.sh --enter      # máy: git, PR/CI, hồ sơ, goal ready/blocked, kế hoạch, GO/NO-GO, streak → verdict + next
  ├─ continue      → làm đúng `next` (một outcome): sửa CI PR · commit qua cổng · reconcile base · chọn slice ready · W-xxx kế · ghi Bàn giao
  ├─ refine-spec   → quay về tầng ①/② (sửa spec/design) trước khi chạm code (§3b, streak lần 2)
  ├─ refine-code   → sửa code có test đỏ-trước (streak lần 2, tầng ③/④)
  ├─ waiting       → ghi `- Trạng thái: Waiting — chờ CI/merge PR #n`, kết lượt (hook cho dừng)
  ├─ request-input → ghi `- Trạng thái: Blocked — <lý do §8/§9>` + lựa chọn + đề xuất, kết lượt
  └─ stop          → hồ sơ đã `done.md`: rm marker, báo cáo cuối
cuối lượt: hook Stop → loop-state --fingerprint → đổi ⇒ block + trạng thái mới · không đổi 2 lượt ⇒ cho dừng
```

Bất biến mỗi vòng: một outcome = một PR (Work ID trong mô tả, `pr-policy.yml`); cổng commit chặn đỏ (`pre-commit-gate.sh`); review
tách người viết trước PR (`reviewer`/`security-reviewer`); auto-merge chỉ bật sau khi mô tả đủ mục (`pr-flow.md` §1); `PROGRESS.md`
trỏ hồ sơ (PF-1..4).

## 4. Verdict có kiểu và nguồn dữ liệu

| Verdict | Điều kiện máy (thứ tự ưu tiên) | Dữ liệu |
| --- | --- | --- |
| `stop` | hồ sơ là `done.md` | `docs/work/<id>/` |
| `request-input` | `Trạng thái: Blocked`; streak đỏ ≥ 3; slice mở mà không slice nào ready | hồ sơ, `.claude/.gate-red-streak`, goal |
| `waiting` | `Trạng thái: Waiting`; PR mở CI xanh/pending và không file dở | hồ sơ, `gh pr list` |
| `refine-spec` / `refine-code` | streak = 2 — tầng ghi ở dòng cuối "Lần thử / blocker" (①② → spec, ③④ → code) | hồ sơ |
| `continue` | PR CI đỏ · file dở · tụt `origin/main` · DONE thiếu Evidence · có slice ready · W ⬜/🔄 · NO-GO · Bàn giao | git, PR, goal, plan, release-readiness |

Thiếu `gh`/offline → `pr.available=false` và verdict không dựa vào PR (nói rõ, không xanh giả). Thiếu `python3` → hook về cách đo cũ
(cksum lời cuối) và nói ra.

## 5. Kiểu dừng (stop kind) và cách nối lại

| Dừng | Tín hiệu | Nối lại |
| --- | --- | --- |
| Blocked | `- Trạng thái: Blocked — …` | người dùng quyết → sửa trạng thái `Active` → `/auto-complete` |
| Waiting | `- Trạng thái: Waiting — …` | sự kiện PR/CI (subscribe) hoặc check-in 5 phút → `Active` |
| Không tiến triển | vân tay artifact không đổi 2 lượt | đọc lý do ở stderr hook; thường là thiếu `next` cụ thể → ghi Bàn giao |
| Trần lượt | `n ≥ AUTO_COMPLETE_MAX_CONTINUES` (20) | gõ `/auto-complete` (marker giữ `n`, `--enter` không reset) |
| Wind-down | `usage-guard.sh` (cần `.claude/usage-budget.sh`) | phiên sau "tiếp tục" |
| Chuỗi đỏ | `.gate-red-streak n ≥ 3` | ghi Blocked + tầng lỗi; không sửa mù |
| Done | `done.md` (13b) | — |

## 6. Phân công người–máy–model

| Việc | Máy (script/hook/CI) | Model (phiên chính/worker) | Người |
| --- | --- | --- | --- |
| Biết đang ở đâu | `loop-state.sh`, PF-1..4, `session-resume.sh` | đọc, không tự suy | — |
| Chọn việc kế | tập `ready` + `next` | chọn trong tập, theo value/risk (§4) | — |
| Làm | — | code + test đỏ-trước | — |
| Kiểm | `dev-task.sh gate`, CI, contract C-1..4, 13b/15/16 | `/review` tách người viết | — |
| Chuyển pha | cổng máy đỏ thì không chuyển | tự duyệt §3d, ghi một dòng | chỉ §9 (dữ liệu thật, chi phí, deploy, quyền) |
| Dừng | hook Stop + vân tay | ghi trạng thái dừng có kiểu | trả lời Blocked |

## 7. Ở dự án đích

`copy-framework.sh` phát `scripts/loop-state.*`, `.claude/commands/auto-complete.md`, hook Stop; hồ sơ/goal/plan theo mẫu
`docs/framework/templates/`. Cổng 13b/15/16 và PF-1..4 hiện **chỉ chạy ở repo khung** — giới hạn đã biết (báo cáo §2.3), đích dựa vào
`loop-state` đếm + `pr-policy.yml`. Harness ngoài Claude Code: chạy tay `bash scripts/loop-state.sh --enter` đầu mỗi vòng; không có
hook Stop thì luật "Bàn giao trước khi kết lượt" là văn xuôi (AGENTS.md).
