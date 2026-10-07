# Đối chiếu X-Agents lần 2 → projects-template — 2026-10-06

Nguồn: `seeker19110/X-Agents` @ `2dd4750` (clone nông, đọc `CLAUDE.md`, `TRAPS.md`, `CHANGELOG.md`, `.claude/`,
`platform/console/tests/test_cong_khung.py`, `test_cong_tai_lieu.py`). Lần trước đọc `b50a29d`
(`2026-09-26-bidirectional-delivery-handoff.md`). Đích: `projects-template` @ `e2b70bf`.
Phạm vi trung thực: khảo sát hàng rào/cổng khung, **không** kiểm định runtime công ty/keeper/gateway của X-Agents.

## Ba cột

### Đã có và sâu hơn — giữ nguyên
| Cơ chế X-Agents | Ở template |
| --- | --- |
| Chặn `--abort`, `reset --hard`, `+main`/`:main`/`--delete main` | `block-dangerous-git.sh` mục 1–5, `test-hooks-gate.sh` mục 12 |
| Mỗi lỗi một test đỏ trước, sổ bẫy `TRAPS.md` | CLAUDE.md §3.6, ADR-0005, `TRAPS.md` (42 mục) |
| Cổng tài liệu: link gãy, `python -m`/`cd` trỏ thật, CODEMAP gọi tên mọi module | `check-docs-consistency.sh` mục 1–7 |
| Một lệnh cổng duy nhất khớp CI | `scripts/dev-task.sh gate` |
| Vendor có ghim + sha256 (ECC) | `docs/framework/adopt-from-outside.md` (ba cột) — template cố ý không vendor plugin |

### Đã có nhưng nông hơn — lấy đúng điểm thiếu (mỗi điểm có sự cố đo được tại repo này)
| Điểm | Bằng chứng đo ở template | Thay đổi |
| --- | --- | --- |
| Hook không có bit thực thi chết im lặng (X-Agents họ H6) | `ui-intelligence.sh` mode 100644, `echo '{}' \| .claude/hooks/ui-intelligence.sh` → exit 126; test mục 9 chạy qua `bash` nên không thấy | Sửa 100755; `test-hooks-gate.sh` mục 14 canh mode **trong index** của mọi hook nối ở `settings*.json` + negative test |
| Hook commit chạy TRƯỚC lệnh nên `git add … && git commit`/`commit -a` lọt (X-Agents #368) | 3 ca đỏ: file >1 MB, bí mật chưa stage, `commit -am` đều exit 0 | `pre-commit-gate.sh` xét thêm thay đổi chưa stage (và file chưa theo dõi khi có `git add`); commit thường vẫn chỉ xét index; 5 ca mới ở mục 11 |
| Bảng Markdown thừa ô: GitHub bỏ ô, `\|` trong backtick vẫn tách ô | 2 hàng thật mất chữ: `docs/ops/repository-settings.md:98`, `2026-10-05-framework-audit.md:52` | Sửa hai hàng; `check-docs-consistency.sh` mục 10 (bỏ qua code fence) + 2 ca ở `test-check-scripts.sh` |

### Chưa có — không thêm, kèm điều kiện xem lại
| Ứng viên | Quyết định |
| --- | --- |
| Chặn mọi `git push` ghi `main` (kể cả không force) trong hook | Chưa cần: template để ruleset chặn và test mục 12 ghi rõ lựa chọn đó; xem lại khi có lần push thẳng `main` thật lọt qua ruleset. |
| `pr_dod_check.py`/keeper `changelog_drift` (mỗi PR một dòng CHANGELOG) | Chưa cần: `docs/changelog/` + `pr-policy.yml` đang giữ; xem lại khi CHANGELOG lệch PR đã merge ≥ 2 lần. |
| Sandbox container/egress, reviewer có chữ ký, lease `flock`, lọc `<PREFIX>_LLM_*` | Ngoài phạm vi: là runtime công ty, trái ranh giới "template không kéo orchestrator/provider". |
| `auto-compact 300k` ở `settings.json` | Chưa cần: template đã có `precompact-checkpoint.sh`; xem lại khi có phiên mất ngữ cảnh được tái hiện. |

Đính chính: ban đầu nghi template thiếu chặn push `HEAD:refs/heads/main`; đọc `test-hooks-gate.sh` mục 12 cho thấy
đó là quyết định có chủ ý (ruleset), nên xếp "chưa cần" thay vì thêm.

## Kiểm chứng
Mỗi thay đổi có test đỏ trước (mode hook: 1 ca đỏ; tự stage: 3 ca đỏ; bảng: 1 ca đỏ), sau sửa xanh; gỡ
hai hàng đã sửa thì cổng mới đỏ đúng hai dòng đó. Chạy: `scripts/test-hooks-gate.sh`, `scripts/test-check-scripts.sh`,
`scripts/check-docs-consistency.sh` (kết quả đầy đủ trong PR). Chưa chạy: CI hosted Windows/macOS, ShellCheck (máy này không có).
