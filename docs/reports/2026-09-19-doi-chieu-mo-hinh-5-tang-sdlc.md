# Đối chiếu mô hình "5 AI theo 5 tầng SDLC" với khung hiện có — 2026-09-19

> Phương pháp: `docs/framework/adopt-from-outside.md` (ba cột + cổng "sự cố thật" + grep cổng đang chạy).
> Nguồn: đề xuất của người dùng — 5 core AI (Product & UX · Design · Engineering · Verify & Operate ·
> Knowledge) + workflow controller deterministic + worker động; đổi tên "QA & DevOps" → "Verify &
> Operate", "Documentation" → "Knowledge"; không tạo Security AI / Architect AI / Orchestrator AI riêng.
> Yêu cầu kèm theo: *"tối ưu và thay thế cho dự án này tốt hơn"*.

## Kết luận trước (để bác lại được)

Mô hình 5 tầng **không mâu thuẫn** với khung — nó là **một cách nhìn theo vòng đời** trên cùng những
cơ chế đã chạy: 9 cổng `standard-delivery.md` §3, 3 tầng điều phối, lệnh `/consult` `/grill` `/ui-ux`
`/gate` `/incident` `/maintain`, và cổng máy (`pr-policy.yml`, `ci.yml`, hook). Điểm khung **đang thiếu**
là **một bản đồ một trang** nối 5 câu hỏi vòng đời với *lệnh/agent/artifact/cổng máy* tương ứng, và
**luật quy lỗi về tầng** khi Verify fail. Hai thứ đó được lấy. **Không** tạo 5 file agent cố định mới —
lý do ở cột 4 (mâu thuẫn luật). Kết quả: **2/13 hạng mục lấy** (đúng tỷ lệ bình thường của phương pháp).

## Cổng §2 đã chạy trước khi xếp cột "CHƯA CÓ"

- `TRAPS.md`: không có mục nào về "AI không biết mình đang ở tầng nào của vòng đời" hay "fail trả nhầm
  tầng". Sự cố gần nhất liên quan: `PROGRESS.md` lỗi thời hai PR liên tiếp (#146/#147) → đã có cổng
  `progress-freshness` bịt.
- grep cổng đang chạy: `pr-policy.yml` (Feature gate "Approved for implementation"), `ci.yml` 7 job,
  hook `pre-commit-gate.sh`/`auto-format.sh`/`usage-guard.sh`/`telemetry-record.sh`,
  `scripts/subagent-dispatch.sh --tier`, `scripts/dev-task.sh gate`, `scripts/maintenance-sweep.sh`.

---

## Cột 1 — Đã có và SÂU HƠN

| Hạng mục đề xuất | Cơ chế đang có | Vì sao ở đây sâu hơn |
|---|---|---|
| ① Product & UX AI — WHAT/WHY → `FEATURE_SPEC` | `/consult` (research-first KHUNG-3), `/grill`, cổng Frame/Research/Approve, `docs/specs/<ngày>-<slug>.md` theo `FEATURE-SPEC.template.md` (19 mục: journeys mọi state, acceptance, security, observability, slice plan) | Có **cổng máy** `pr-policy.yml` chặn PR `feat` chưa "Approved for implementation" — đề xuất chỉ nêu điều kiện chuyển tầng bằng lời |
| ② Design AI → `DESIGN_SPEC` riêng | `/ui-ux` + `quality-supplements` Nhóm 2 (mobile-first, a11y, 4 trạng thái, theme tokens) + FEATURE-SPEC §6 (journeys/mọi state), §10 (UX/content/a11y), §11 (architecture touchpoints) | Design nằm **trong cùng spec** đã được duyệt — không tách thành artifact thứ hai phải giữ khớp tay. Phần "không GUI → CLI/API/DX" đã ở hồ sơ C4 (backend/API) và C5 (CLI/SDK) `quality-gates-by-profile.md` |
| ③ Engineering AI — kiến trúc trước, FE/BE/DB là worker tạm | Tầng 1 viết PLAN.md (schema/API/điểm chạm) → Tầng 3 worker theo 2 trục `route:complex/spec/standard/mechanical`, trần effort medium, đa nhà cung cấp (ADR-0006/0007) | Định tuyến **2 trục** (độ phức tạp × độ kín spec) + ánh xạ năng lực đa hãng có file dữ liệu và test hồi quy; đề xuất chỉ chia theo *miền* (FE/BE/DB) |
| ③ Architect chỉ spawn khi cực lớn | Kiến trúc là việc Tầng 1 giữ lại, không route xuống (`orchestration-3-tier.md` "Luật cứng Tầng 1") | Cùng ý, nhưng ở đây có ràng buộc "worker không quyết kiến trúc" ghi trong frontmatter từng agent |
| ④ Verify — review/test/security/build | `/gate` §5–§7 (báo cáo xác thực có bằng chứng), `tester`, `reviewer`, `security-reviewer`, `ci.yml` job `gate`, TDD đỏ-trước (ADR-0005), hook chặn commit đỏ | Cổng **đo được, chạy máy**, không phải checklist lời |
| ④ Operate — deploy/monitor/incident/rollback | `docs/ops/release-readiness.md`, `/incident`, post-mortem, `/maintain` + `maintenance.yml` cron, `maintain-cron.sh` | Có agent bảo trì chạy không giám sát và mở PR báo cáo — đề xuất chưa nói tới mục nát theo thời gian |
| ⑤ Knowledge — ADR/runbook/changelog/debt/state | `docs/adr/` (`/adr`), `TRAPS.md`, `CONTEXT.md`, `CODEMAP.md`, `docs/changelog/`, `FEATURE-MAP`, `CONVENTIONS`, dấu `DEBT:` có `xem lại khi:`, `PROGRESS.md` + cổng `progress-freshness`, hook `session-resume.sh` | Có **cổng máy** giữ trạng thái mới (PF-1..PF-3) và sweep 🟡 nợ mục âm thầm; đề xuất chỉ liệt kê loại tri thức |
| ⑤ Vòng kín production feedback → Product | Cổng Observe → Reconcile + AI Goal Loop (`standard-delivery.md` §3–§4, `docs/goals/*`) | Vòng lặp có **stop condition** và trần sửa 3 lần; đề xuất chỉ vẽ mũi tên quay lại |
| Security là cross-cutting, không agent riêng | `security-reviewer` **ngoài bảng route**, gọi theo điều kiện §9; ASVS ở `industry-standards.md` | Trùng ý và đã hiện thực đúng như vậy |
| Không Orchestrator AI — dùng state machine | Phần deterministic **đã** là máy: hook, `pr-policy`, auto-merge, FIFO, `subagent-dispatch.sh`, `dev-task.sh gate`, `maintain-cron.sh` | Xem thêm cột 3 cho phần còn là LLM (`coordinator`) |

## Cột 2 — Đã có nhưng NÔNG HƠN (chỉ lấy đúng điểm nông)

| Hạng mục | Điểm nông cụ thể | Lấy gì | Sự cố/căn cứ |
|---|---|---|---|
| Sơ đồ 5 tầng "một trang, một câu hỏi mỗi tầng" | Bảng cổng ở `standard-delivery.md` §3 có *điều kiện vào/ra* nhưng **không có cột "ai làm bằng lệnh/agent nào, artifact gì, cổng máy nào kiểm"** — người đọc phải ghép từ 6 file | Thêm §3b "Bản đồ 5 tầng SDLC" vào `standard-delivery.md`: 5 tầng ↔ cổng ↔ lệnh/agent ↔ artifact ↔ cổng máy ↔ fail quay về đâu | `standard-delivery.md` được tạo chính vì "không rõ tài liệu nào chi phối bước hiện tại"; yêu cầu tái cấu trúc agent lần này là lần thứ hai người dùng phải hỏi lại "AI nào làm gì" |
| "Nếu fail → trả đúng tầng gây lỗi" | Có "worker vướng spec → báo lên Tầng 1" và "cùng failure sửa tối đa 3 lần → BLOCKED", nhưng **không có bảng quy lỗi**: test fail do spec sai, do design thiếu state, hay do code? Hiện AI mặc định sửa code | Cột "Fail ở đây → quay về tầng" trong bản đồ §3b, kèm 1 luật: trước lần sửa thứ 2 cùng failure phải nêu tầng gây lỗi | Chưa có mục `TRAPS.md` tương ứng — **lấy theo quyết định của người dùng** (đề xuất tường minh), ghi rõ để bác lại được |

## Cột 3 — CHƯA CÓ → xếp "chưa cần", có điều kiện xem lại

| Hạng mục | Vì sao chưa cần | Xem lại khi |
|---|---|---|
| Workflow controller deterministic thay `coordinator` (LLM Opus·low) | Phần lặp lại đã là script/hook/CI; phần còn lại của coordinator (đọc PLAN.md, tạo nhánh, nghiệm thu tiêu chí, gọi reviewer) chưa đo được là tốn đáng kể; viết state machine riêng là engine mới (thang tối giản §3.4) | `scripts/telemetry-log.sh` cho thấy chi phí phiên `coordinator` > 20% tổng chi phí một PLAN, hoặc một PLAN > 5 đơn vị PR chạy thường xuyên |
| `DESIGN_SPEC` là artifact riêng | Đã nằm trong FEATURE-SPEC §6/§10/§11 (cột 1); tách ra tạo hai sổ phải khớp tay | Có dự án đích với đội design riêng bàn giao file thiết kế độc lập với spec |
| `VERIFIED_RELEASE` / `PROJECT_KNOWLEDGE` là artifact có tên | Bằng chứng release đã là báo cáo §7 + CI xanh + `release-readiness.md`; tri thức đã phân tán đúng chỗ đọc (ADR/TRAPS/CONTEXT/CODEMAP) | Có yêu cầu audit/khách hàng cần một file "release evidence" duy nhất (`industry-standards.md` mức SOC2) |

## Cột 4 — Mâu thuẫn luật (không lấy dù có thể "chưa có")

| Hạng mục | Luật đang có nói ngược | Cách xử lý |
|---|---|---|
| 5 **AI cố định** (5 file agent) mà Product/Design/Knowledge là subagent | Tầng 1 = phiên chính giữ ngữ cảnh người dùng và quyền hỏi (`AskUserQuestion`); subagent **không được hỏi người dùng** và mất ngữ cảnh khi kết thúc. Product & UX/Knowledge là chỗ *cần hỏi nhiều nhất* (`/grill`). Đưa xuống subagent = thêm một lần bàn giao mất chi tiết + tốn token (§5 kỷ luật ngữ cảnh) | **Tối ưu lại đề xuất:** 5 tầng là **5 vai (mũ)** phiên chính đội qua lệnh `/consult`·`/grill`·`/ui-ux`·PLAN.md·`/gate`·`/adr`; chỉ Engineering (Tầng 3) và Verify (`tester`/`reviewer`/`security-reviewer`) mới là subagent thật — đúng như đề xuất "worker động, spawn rồi terminate" |
| Đổi tên agent theo tầng ("Verify & Operate AI") | `route:` là **cấp năng lực**, không phải vai trò (ADR-0006); tên agent hiện nêu năng lực + ranh giới | Giữ tên agent; tên tầng chỉ dùng trong bản đồ §3b làm từ vựng |

## Danh sách thực sự lấy

1. `docs/framework/standard-delivery.md` §3b — bản đồ 5 tầng SDLC ↔ cổng ↔ lệnh/agent ↔ artifact ↔ cổng máy ↔ fail quay về đâu (+ luật quy lỗi trước lần sửa thứ 2).
2. `docs/adr/0008-*.md` — chốt "5 tầng là lớp từ vựng/bản đồ trên 9 cổng + 3 tầng điều phối; không tạo 5 agent cố định" — **trạng thái Đề xuất, chờ người dùng duyệt**.

## Đính chính giữa chừng (giữ nguyên)

- Ban đầu định xếp "Design AI → DESIGN_SPEC" vào cột 2 (nông hơn vì không có mẫu design spec). Đọc lại
  `FEATURE-SPEC.template.md` thấy §6/§10/§11 đã bao phủ → chuyển sang cột 1 + cột 3 "chưa cần".
- Ban đầu định xếp "workflow controller deterministic" vào cột 2. grep hook/CI/script cho thấy phần
  deterministic đã là máy; phần chưa là máy chưa có số đo chi phí → chuyển cột 3 với điều kiện đo được.
