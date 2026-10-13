# Gợi ý nâng cấp — rà soát 2026-10-13

> Lấy từ đợt rà soát chéo 19 repo của chủ sở hữu (ma trận vệ sinh ở [seeker19110/stored, mục 23 §8.1](https://github.com/seeker19110/stored/blob/main/23-own-repos-lessons/README.md); gợi ý tích hợp ở §7b của cùng file). Số liệu đo bằng lệnh trên HEAD (đếm `uses:` ghim SHA 40 ký tự, khối `permissions:`, `dependabot.yml`, `.claude/settings.json`), không suy ra từ văn xuôi. Đây là **đề xuất**, chưa sửa code. Mỗi mục kèm bằng chứng để kiểm lại trước khi làm; mục nào đã xử lý thì đánh dấu hoặc xoá.

## Hiện trạng đo được

| HEAD đọc | Action ghim SHA | Workflow thiếu `permissions:` cấp đầu | Dependabot | LICENSE · SECURITY | File test |
|---|---|---|---|---|---|
| `9f6b6f9` (2026-10-12) | 25/25 | – | npm, github-actions, pip | có · có | 16 |

## Đề xuất (🔴 cao · 🟠 trung bình · 🟢 nhẹ)

| # | Mức | Đề xuất | Bằng chứng | Kiểm xong khi |
|---|---|---|---|---|
| 1 | 🟠 | Thêm vào khung một cổng **lan chuẩn sang repo con**: job định kỳ (cạnh `maintenance.yml`) quét các repo đã áp khung theo đúng ma trận vệ sinh (ghim SHA, `permissions:`, Dependabot `github-actions`, có `auto-complete-guard.sh` trong Stop, không còn `opusplan`) rồi mở issue ở repo lệch | Rà soát chéo cho thấy chuẩn của khung không tự lan tới các repo con: X-Agents 0/42, Xgold 0/19, xboss-manager 0/20 action ghim SHA; dhcb, Xgold, xboss-manager còn `opusplan` (trái ADR-0007); X-Scanner, case-study-ft41, dhcb thiếu `auto-complete-guard.sh` trong Stop | Mỗi repo con lệch chuẩn có một issue tự sinh; chạy lại thì không có issue trùng |
| 2 | 🟢 | Đổi model trong `.claude/settings.json` từ `claude-sonnet-5` sang `claude-sonnet-5-5`, đồng thời thêm `claude-sonnet-5([^-0-9]\|$)` vào `STALE_MODEL_RE` của `scripts/check-docs-consistency.sh` | `.claude/settings.json:3` ghi `"model": "claude-sonnet-5"`, còn xboss đã dùng `claude-sonnet-5-5`. `STALE_MODEL_RE` (dòng 212) hiện chỉ bắt `claude-opus-4-x`, `claude-fable-5` và `Opus 4.8` | `bash scripts/check-docs-consistency.sh` xanh và bắt được ID cũ khi cố tình chèn vào |
| 3 | 🟢 | Đưa **agent-scan / SkillSpector** vào bước adopt-from-outside: quét mỗi skill, hook hay MCP mới trước khi vendor | `docs/framework/adopt-from-outside.md` đã có quy tắc "đọc trước khi cài" nhưng chưa có máy quét; xem stored mục 12 §3d–§3e | Có một lệnh quét trong checklist adopt và được gọi trong CI khi `.claude/skills/**` đổi |

## Giữ nguyên (điểm mạnh)

- Ghim SHA 25/25, mọi workflow đều có `permissions:` cấp đầu, Dependabot npm + github-actions + pip, Scorecard và dependency-review: đây là **chuẩn tham chiếu** cho các repo khác.
- Ba cổng máy cho `/auto-complete` (#287) và bộ hook có test.

## Gợi ý tích hợp từ catalog `stored`

- Code knowledge graph (Graphify hoặc codegraph) để agent đọc bản đồ trước khi sửa (stored mục 16 §2d). Với codegraph thì đặt `DO_NOT_TRACK=1`.
- Template RoE / threat-model của AI Red Teaming Guide (stored mục 12 §3f). Nguồn chưa có LICENSE, nên viết lại thay vì chép nguyên văn.

## Ghi chú chung

- Ghim action theo SHA bằng [pinact](https://github.com/suzuki-shunsuke/pinact) hoặc [ratchet](https://github.com/sethvargo/ratchet), giữ comment tag (`# v7.0.1`), rồi để Dependabot `github-actions` tự nâng SHA. Đây là cách projects-template, xboss và Sales-Hunter đang làm.
- Chuẩn tham chiếu là `seeker19110/projects-template`: 25/25 action ghim SHA, mọi workflow có `permissions:` cấp đầu, Dependabot cho npm, github-actions và pip.
