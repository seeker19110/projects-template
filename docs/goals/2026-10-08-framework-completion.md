# Goal: hoàn thiện toàn bộ năng lực của bộ khung

| Thuộc tính | Giá trị |
| --- | --- |
| Goal ID | FC-2026-10-08 |
| Owner | Chủ repo; phiên chính nghiệm thu theo ủy quyền |
| State | ACTIVE |
| Default-branch SHA đã reconcile | 6c3e3ce0fb7e236704d86fbf654b93046dbbffbb |
| Bắt đầu / review | 2026-10-08 |
| Quyền AI | research, branch, PR, kiểm thử; merge khi cổng xanh theo luật repo; không production |
| Budget | Không gọi model/API trả phí, không đổi provider, không thêm dependency runtime |

## Outcome và Goal DoD

Rà lại 12 nhóm theo năng lực khung; mọi lỗi Cao/Trung phát hiện trong chu kỳ phải
được sửa và có regression. Full gate cùng CI trên default branch xanh, tài liệu
khớp hành vi, mọi giới hạn còn lại có điều kiện xem lại. Nghiệm thu theo ủy quyền
chủ repo ngày 2026-10-07, không giả người dùng duyệt tay hoặc pilot sản phẩm.

## Scope / non-goals

Installer/upgrade, engine, hook, gate, CI và tài liệu của chính template. Không mở
lại goal LD hoặc chu kỳ đã đóng; không dựng app mẫu để giả UAT, không phát hành
release/production, không xoá nhánh hoặc cấu hình bí mật của chủ repo.

## Milestones và slices

| ID | Outcome | Dependency | Mức | State | Evidence |
| --- | --- | --- | --- | --- | --- |
| W-01 | Đường dẫn filename/venv là dữ liệu khi thực thi shell | baseline | S fix | VERIFY | F-C01/F-C03 có đỏ-trước/xanh-sau và 16 test runtime xanh |
| W-02 | WIP đếm mọi PR mở trước miễn trừ draft/bot | W-01 merge | S fix | READY | F-C02 trong báo cáo |

Không feature mới: ngoại lệ spec cho sửa lỗi S theo contract §3c. Hai worker được
giao tuần tự, hồ sơ tổng docs/work/2026-10-08-framework-completion/working.md;
bảng phát hiện và acceptance ở docs/reports/2026-10-08-framework-completion.md.

## Current truth

W-01 đã sửa F-C01/F-C03 và có regression; chờ full gate/PR/CI/merge.
W-02 chờ merge/reconcile. Chưa có quyền production hoặc
bằng chứng hosted CI/pilot dự án đích. Không hạ cổng để vượt các giới hạn đó.

## Risk register

Command config là shell tin cậy; filename và executable path phải được quote
đúng khi qua biên shell. WIP chỉ cưỡng chế ở check metadata, không thể ngăn GitHub
tạo PR thứ tư trước check. Rollback bằng revert qua PR; regression không được xoá.

## Final audit

NOT COMPLETE: chờ hai PR MERGED, full gate/CI trên default branch và nghiệm thu.
