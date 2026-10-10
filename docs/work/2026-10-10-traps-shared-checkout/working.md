# Công việc: TRAPS 63: hai phiên chung một checkout

- Work ID: 2026-10-10-traps-shared-checkout
- Yêu cầu / outcome: người dùng: "ghi mục TRAPS mới" cho sự cố hai phiên chung checkout (#257/#258) → TRAPS 63 + CHANGELOG + PROGRESS, một PR docs-only (#259), ngoại lệ 3.
- Trạng thái: Active (chờ PR #259 merge rồi đổi done ở checkpoint kế)
- Chủ trì / writer: phiên chính (Fable 5.1), worktree riêng `scratchpad/wt-traps`.
- Mức rủi ro / số PR: S; 1 PR (chỉ tài liệu).
- Scope / non-goal: Scope = TRAPS 63 + nhật ký. Non-goal = không thêm hook phát hiện (ghi DEBT kèm điều kiện xem lại).
- Spec / goal / issue: n/a (mức S).
- Nhánh / base SHA / thời điểm reconcile: `docs/traps-shared-checkout` @ `c8b24a8` · 2026-10-10T00:53:16Z

## Kế hoạch và phân công

<Một outcome/PR; owner/cấp năng lực, input/output, file được ghi, dependency,
test/AC và nhánh/worktree. Từ 2 PR giao subagent; tối đa 5 subagent chạy toàn cây.
Song song nếu độc lập, tuần tự nếu phụ thuộc hoặc ghi chung.>

## Quyết định và bằng chứng

<Quyết định + lý do; lệnh/test, head/base và kết quả thật; PR/review/CI/merge SHA.
Không ghi test xanh từ lời khai hoặc dùng kết quả trước thay đổi.>

## Lần thử / blocker

<Failure, số lần cùng failure, giả thuyết đã bác bỏ, blocker và cách kiểm tiếp.>

## Bàn giao / bước tiếp theo

<Một hành động cụ thể, file/lệnh cần đọc/chạy; thay đổi chưa commit và nơi giữ;
điều kiện có thể tiếp tục. Cập nhật trước nén/chuyển phiên/giao việc.>

## Nghiệm thu cuối (chỉ điền khi đủ bằng chứng)

<DoD, mọi PR MERGED + merge SHA và main đã đối chiếu, giới hạn/rủi ro còn lại,
ngày và người nghiệm thu theo ủy quyền. Khi đủ điều kiện rename working.md → done.md
trong cùng thư mục; không overwrite lịch sử. Chưa có PR/merge thì giữ working.md.>
