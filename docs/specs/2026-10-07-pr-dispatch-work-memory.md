# Feature spec: phân chia theo PR và hồ sơ công việc nối phiên

| Thuộc tính | Giá trị |
| --- | --- |
| Issue / Goal | Yêu cầu chủ repo trong cuộc trò chuyện 2026-10-07; hồ sơ `docs/work/2026-10-07-pr-dispatch-work-memory/working.md` |
| Spec owner | Phiên chính |
| State | **Approved for implementation** |
| Approver / date | Phiên chính duyệt theo ủy quyền toàn cục của chủ repo; 2026-10-07 |
| Last updated | 2026-10-07 |

## 1. Problem, user và evidence

Chủ repo yêu cầu phân công theo số PR và ghi working.md/done.md trước/sau từng việc.
Hook SessionStart hiện chỉ nạp PROGRESS và Git, không chỉ ra hồ sơ công việc đang làm.
PROGRESS có lịch sử phình từng làm ngữ cảnh đầu phiên quá lớn; cổng PF-4 và test hook
đã xử lý giới hạn nạp. Không xây lại một hệ quản lý task hoặc chép trạng thái goal/spec.

Research ngày 2026-10-07: [Anthropic long-running harnesses](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents),
[parallel agents](https://www.anthropic.com/engineering/building-c-compiler),
[persistent checkpoints](https://docs.langchain.com/oss/python/langgraph/persistence).
Các nguồn ủng hộ cập nhật tiến độ bền vững, đọc lại đầu phiên và kiểm chứng bằng Git/test;
không chứng minh model không bao giờ quên.

| Đã có và sâu hơn | Đã có nhưng nông hơn | Chưa có / quyết định |
| --- | --- | --- |
| Feature gate, TDD, DoD và PR/CI làm bằng chứng: giữ cổng đang chạy | SessionStart đọc PROGRESS/Git nhưng chưa chỉ ra working.md: bổ sung danh sách hồ sơ active trước phần PROGRESS | working.md → done.md theo từng work ID là yêu cầu trực tiếp của chủ repo; dùng file/Git, không thêm DB hoặc framework |
| Contract tách writer, worktree, dependency và WIP: giữ nguyên | Điều phối chỉ khuyến nghị subagent cho đơn vị độc lập: áp quy tắc ≥ 2 PR, kể cả chạy tuần tự | LangGraph/checkpoint DB/task locks mới: chưa cần; xem lại nếu có nhiều phiên chính cùng ghi hoặc mất cập nhật được đo thật |

## 2. Outcome, baseline, target và guardrails

- Mỗi yêu cầu có phân loại rủi ro, số PR dự kiến và kế hoạch phù hợp.
- Một PR: phiên chính có thể tự làm. Từ hai PR: giao đơn vị cho subagent đủ năng lực;
  tối đa ba subagent đang chạy trong toàn cây, song song khi độc lập và tuần tự khi phụ thuộc.
- Hồ sơ active có ID, chủ trì, scope, PR/dependency, bằng chứng và bước nối tiếp;
  chỉ rename sang done.md khi DoD đạt và tất cả PR thực tế đã merge.
- SessionStart chỉ nạp đường dẫn working.md; không nạp lịch sử done hay nội dung task.
  Giữ trần byte hiện có, chỉ dẫn đọc hồ sơ bị cắt và cơ chế fail-open của hook.

## 5. Scope / non-goals

Luật chung, template hồ sơ, PROGRESS trỏ hồ sơ, hook resume hiện có và test của hook.
Không thêm scheduler, DB, CLI task manager, file trạng thái thứ hai hay script tự merge/rename.
Không đổi quyền merge/deploy. Các thay đổi từ yêu cầu trước chưa commit được giữ nguyên.
Một PR có thể chứa trọn thay đổi này; không chia PR giả tạo để kích hoạt subagent.

## 9. Acceptance criteria

- AC-1: Phân chia theo số PR, năng lực, dependency, writer và trần ba subagent được đồng bộ ở luật/lệnh điều phối.
- AC-2: SessionStart chỉ ra nhiều working.md, kể cả khi PROGRESS thiếu hoặc dài; không nạp done.md hay nội dung hồ sơ.
- AC-3: Hook vẫn giữ bounded context, báo khi cắt, đọc PROGRESS/Git và không thay đổi hồ sơ công việc.
- AC-4: Hồ sơ có lifecycle, quy tắc checkpoint/reconcile và rename sau merge; không ghi done chỉ vì agent báo xong.

| AC | Bằng chứng |
| --- | --- |
| AC-1 | `tests/test_adaptive_process.py`; thủ công: đối chiếu CLAUDE, AGENTS, contract và auto/coordinator với số PR/trần toàn cây |
| AC-2 | `scripts/test-hooks-session.sh` |
| AC-3 | `scripts/test-hooks-session.sh` |
| AC-4 | thủ công: đọc working.md hiện tại, template/lifecycle; xác minh vẫn working khi chưa có PR merge, không giả kiểm chứng runtime rename |

## 11. Architecture và code touchpoints

- `.claude/hooks/session-resume.sh`: thêm danh sách đường dẫn active trước PROGRESS,
  nhắc đối chiếu Git/PR/CI và đọc full file; không thực thi nội dung hồ sơ.
- `scripts/test-hooks-session.sh`: regression nhiều hồ sơ, done exclusion, không PROGRESS,
  PROGRESS dài, không sửa hồ sơ; chạy đỏ trước thay đổi hook.
- `tests/test_adaptive_process.py`: giữ test mức rủi ro/quyền, kiểm lại mô tả điều phối.
- `CLAUDE.md`, `AGENTS.md`, `docs/framework/standard-delivery.md`: luật nguồn và contract.

## Approval

Approved for implementation — phiên chính duyệt theo ủy quyền chủ repo ngày 2026-10-07;
phạm vi một PR như trên, không hạ cổng chất lượng hoặc giả người dùng đã duyệt tay.
