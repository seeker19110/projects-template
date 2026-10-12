# Công việc: Đổi cổng cột CHƯA CÓ của adopt-from-outside: tốt hơn bản hiện có là lấy

- Work ID: 2026-10-12-adopt-better-than-current
- Yêu cầu / outcome: chủ repo 2026-10-12: "cập nhật adopt*.md: không nhất thiết phải có lỗi mới tích hợp, chỉ cần tốt hơn bản hiện có là sẽ cập nhật" → đổi cổng cột CHƯA CÓ/NÔNG HƠN của `adopt-from-outside.md` §2 từ "phải ứng với sự cố thật" sang "tốt hơn bản hiện có, chứng minh được"; soát mọi chỗ chép luật này cho khớp.
- Trạng thái: Active (sửa xong, chờ PR)
- Chủ trì / writer: phiên chính (Fable 5.1)
- Mức rủi ro / số PR: S; 1 PR chỉ tài liệu (ngoại lệ 3 §3.6 — không có nhánh logic/cổng máy đổi)
- Scope / non-goal: Scope = `adopt-from-outside.md` §0/§1/§2/§5 + 4 chỗ chép luật (`CLAUDE.md` §1, `AGENTS.md`, `docs/framework/README.md`, `standard-delivery.md` §11). Non-goal = mở lại các báo cáo đối chiếu cũ (ralph, loop-engineering, compound-engineering, SDD) theo luật mới — đó là việc riêng khi chủ repo yêu cầu; không thêm cổng máy cho phương pháp (CODEMAP: review bằng mắt).
- Spec / goal / issue: không (mức S); nguồn luật là lời chủ repo trong phiên 2026-10-12.
- Nhánh / base SHA / thời điểm reconcile: `claude/trusting-cori-2i53gj` @ `aab9f88` · 2026-10-12T03:31:18Z

## Kế hoạch và phân công

Một PR docs trên `claude/trusting-cori-2i53gj`. AC: `grep -rn "sự cố thật"` ngoài reports/changelog/work/TRAPS không còn dòng nào nói cột "chưa có" cần sự cố; `check-docs-consistency.sh` + `check-progress-freshness.sh` xanh; CI xanh; squash merge.

## Quyết định và bằng chứng

- Định nghĩa "tốt hơn" theo 4 dạng (bắt thêm lớp lỗi / cùng kết quả ít hơn / kiểm được hơn / nhanh-rẻ hơn) và **tính ròng** (trừ thứ mang thêm) · loại: "tốt hơn" tự do không định nghĩa (mở lại cửa "hay quá, lấy luôn" mà §1 cấm) · bậc 1 §3d (giữ đúng ý chủ repo mà không phá luật chống lệch sổ §0).
- Sự cố thật hạ từ *bắt buộc* xuống *bằng chứng mạnh nhất* thay vì xoá hẳn · loại: xoá mọi nhắc tới sự cố · bậc 2 (giữ cầu nối tới `TRAPS.md` đang có, không thêm khái niệm mới).
- Cổng §2 áp cả cột NÔNG HƠN (trước chỉ CHƯA CÓ) · bậc 3 (một câu hỏi duy nhất cho cả hai cột, dễ kiểm hơn).
- §5 bỏ kỳ vọng "1–2/25 là bình thường" vì luật mới không còn suy ra con số đó; dấu hiệu bỏ phương pháp chuyển sang lý do từng dòng.
- Bằng chứng (HEAD `aab9f88` + working tree): `scripts/check-docs-consistency.sh` OK (14 mục); `scripts/check-progress-freshness.sh` OK (PF-1 cảnh báo trễ 1 commit, ngưỡng 7); `grep -rn "sự cố thật"` chỉ còn ở lịch sử (reports/changelog/work/TRAPS/spec cũ) và chú thích không liên quan.

## Lần thử / blocker

Không.

## Bàn giao / bước tiếp theo

Commit + push nhánh; mở PR (chủ repo yêu cầu) → auto-merge khi CI xanh → đổi file này thành `done.md` kèm merge SHA và cập nhật `PROGRESS.md` ở PR kế. Việc gốc trước khi bị ngắt (nghiên cứu sâu vòng lặp coding để nâng `/auto-complete`) chưa bắt đầu — làm theo luật §2 mới.

## Nghiệm thu cuối (chỉ điền khi đủ bằng chứng)

<DoD, mọi PR MERGED + merge SHA và main đã đối chiếu, giới hạn/rủi ro còn lại,
ngày và người nghiệm thu theo ủy quyền. Khi đủ điều kiện rename working.md → done.md
trong cùng thư mục; không overwrite lịch sử. Chưa có PR/merge thì giữ working.md.>
