# Bộ khung phát triển dự án (drop-in)

## Phạm vi: hỗ trợ MỌI loại dự án lập trình (trừ dự án "cấm")

Khung này hỗ trợ **phát triển mọi loại dự án phần mềm từ ý tưởng đến ra mắt** — không chỉ web app:
**web, mobile native, desktop, backend/API/dịch vụ, site nội dung tĩnh, CLI/thư viện/SDK, data/ML/AI, game,
blockchain, monorepo** (và loại chưa liệt kê). Cách hoạt động:

- **Phương pháp là phổ quát:** quy trình 9 giai đoạn + cổng, research-first, đề xuất chủ động mọi mặt, ADR,
  chống ảo giác, báo cáo xác thực — áp cho **mọi loại dự án, mọi ngôn ngữ/stack** (`docs/framework/KHUNG-1/2/3`).
- **Công nghệ chọn theo "hồ sơ loại dự án":** từ ý tưởng, AI **phân loại → chọn hồ sơ → chọn stack** (research-first,
  phiên bản đã xác minh). Bảng hồ sơ C1–C10 + cổng tương đương: `KHUNG-3 PHẦN A0 + PHẦN C`.
- **Không có scaffold/stack mặc định đóng gói sẵn.** Repo này chỉ chứa tài liệu + quy trình + script tự kiểm
  của chính khung — không kèm code app của bất kỳ stack nào. Từ ý tưởng, AI **research-first** (KHUNG-3) rồi
  đề xuất công nghệ hợp lý nhất cho đúng dự án của bạn, không có "hồ sơ mặc định" áp sẵn (xem `docs/adr/0004-remove-default-web-scaffold.md`).
- **Dự án có sẵn (brownfield):** khung **chỉ tư vấn & nâng cấp** trên stack hiện có, **không áp đặt** stack mặc định
  (`docs/framework/existing-project-adoption.md`).
- **Ngoại lệ — dự án "cấm" (không hỗ trợ):** mã độc, phá hoại, DoS, nhắm mục tiêu hàng loạt, tấn công chuỗi cung ứng,
  né tránh phát hiện vì mục đích xấu, hay việc phạm pháp/xâm phạm quyền riêng tư. Bảo mật **phòng thủ** / kiểm thử
  **có ủy quyền** / CTF / nghiên cứu thì hỗ trợ (xem `CLAUDE.md` §0b).

## Yêu cầu môi trường

| Công cụ | Bắt buộc cho | Thiếu thì sao |
|---|---|---|
| `bash` | mọi script `scripts/*.sh`, hook | không chạy được gì (Windows: dùng Git Bash) |
| **`jq`** | hook `pre-commit-gate.sh`, `block-dangerous-git.sh` | **hàng rào fail-open: hook cảnh báo ra stderr rồi CHO QUA** — commit khi cổng đỏ, `git push --force` lên `main`, `reset --hard` đều không bị chặn |
| `python3` (≥ 3.7) | 4 engine: `spec-compiler`, `arch-health-radar`, `telemetry-log`, `subagent-dispatch` | các lệnh engine báo lỗi và thoát |
| `git` | toàn bộ quy trình | — |
| `bash` ≥ 4 | `mapfile` trong 3 cổng `check-*.sh` (macOS mặc định bash 3.2 → `brew install bash`) | cổng chết với "mapfile: command not found" |
| `shellcheck`, `radon`, `coverage`, `pwsh` *(tuỳ chọn — chỉ để chạy cổng CI cục bộ)* | ShellCheck, `check-python-complexity.sh`, `test-py-coverage.sh`, bản `.ps1` của copy-framework | các cổng đó ĐỎ RÕ (không skip): `pip install -r scripts/requirements-ci.txt`, `apt/brew install shellcheck` |

> **`jq` là quan trọng nhất.** Hook cố tình fail-open khi thiếu `jq` (fail-closed sẽ chặn oan
> vì không đọc được lệnh từ payload JSON), nên **máy không có `jq` = dự án không có hàng rào**
> dù mọi file vẫn đúng chỗ. Kiểm bằng `bash scripts/test-hooks-gate.sh` — thiếu `jq` thì nó
> báo BỎ QUA kèm cảnh báo thay vì báo xanh giả. Cài: `winget install jqlang.jq` (Windows),
> `brew install jq` (macOS), `apt install jq` (Debian/Ubuntu).

## Bắt đầu từ đâu

Mới dùng lần đầu? Đọc **[`docs/framework/quickstart.md`](docs/framework/quickstart.md)** để chọn
đường Greenfield/Brownfield và hoàn tất adoption preflight. Sau đó đọc
**`docs/framework/standard-delivery.md`** — đây là Standard Delivery Contract và điểm vào duy nhất
cho mọi dự án. Contract sẽ định tuyến tới runbook, feature loop hoặc completion phù hợp; không chọn
một quy trình song song bằng cảm tính.

## File đã sẵn sàng (chỉ cần giải nén)
- `CLAUDE.md` — luật cho AI (Claude Code tự đọc). **Nhớ điền các chỗ `[ĐIỀN: ...]`.**
- `PROJECT.md` — mẫu đặc tả dự án (điền trước khi code).
- `PROGRESS.template.md` — mẫu theo dõi trạng thái (script copy tự tạo thành `PROGRESS.md` sạch ở dự án đích;
  `PROGRESS.md` trong repo này là nhật ký phát triển của chính bộ khung, không copy sang).
- `CHANGELOG.md` — lịch sử thay đổi (Keep a Changelog).
- `.nvmrc`, `.editorconfig` — đồng bộ môi trường cơ bản (dự án chọn stack khác Node thì tự thay).
- `.gitignore`, `.gitattributes` — vệ sinh Git tối thiểu, không phụ thuộc stack.
- `.github/pull_request_template.md`, `.github/ISSUE_TEMPLATE/` (gồm mẫu **sự cố**),
  `.github/dependabot.yml`, `.github/CODEOWNERS`, và các workflow:
  `ci.yml` (7 job tự kiểm chính bộ khung: `framework-lint`, `framework-lint-windows`, `docs-consistency`,
  `copy-framework-smoke`, `progress-freshness`, `protection-guard`, `gate` tổng hợp; dự án đích tự thêm job
  build/test/lint theo stack đã chọn vào cùng file), `codeql.yml`, `scorecard.yml`,
  `secret-scan.yml` (gitleaks), `dependency-review.yml`,
  `pr-policy.yml` (spec/evidence), `release.yml` (release-please),
  `stale-pr-alert.yml` (cảnh báo PR kẹt vì required check không thể xanh),
  `maintenance.yml` (quét bảo trì hằng tuần bằng `scripts/maintenance-sweep.sh` → một issue tổng hợp;
  xử lý bằng `/maintain` hoặc `scripts/maintain-run.sh` với CLI subscription cục bộ của mọi nhà cung cấp AI).
- `LICENSE` (MIT — đổi chủ sở hữu/giấy phép theo dự án), `SECURITY.md`, `CONTRIBUTING.md`,
  `CODE_OF_CONDUCT.md` (Quy tắc ứng xử — Contributor Covenant v2.1 tiếng Việt),
  `SUPPORT.md` + `GOVERNANCE.md` (kênh hỗ trợ + quản trị dự án).
- `docs/framework/standard-delivery.md` — **nguồn vào chuẩn duy nhất**: artifact, Research/Spec gate,
  AI Goal Loop, DoR/DoD/Project Complete và stop conditions.
- `docs/framework/templates/GOAL.template.md` + `FEATURE-SPEC.template.md` — checkpoint nhiều PR và
  đặc tả capability bắt buộc trước code.
- `docs/framework/` — tài liệu chuyên sâu: **01/02/03** (quy trình · luật AI · chọn công nghệ research-first);
  **new-project-runbook** (runbook: trình tự + cấu hình hàng rào *Phần D* + checklist dự án thật *Phần E*);
  **existing-project-adoption** (brownfield); **project-completion** (kế hoạch hoàn thiện + vòng hội tụ);
  **quality-supplements** (Nhóm 1+2 + theme + nâng cao i18n/PWA/Sentry/SEO/analytics).
- `docs/ops/` — repository settings, supply-chain/SBOM/provenance, release readiness, incident response.
- `docs/ops/incident-response.md` — vận hành GĐ 8: xử lý sự cố + **mẫu post-mortem**.
- `docs/adr/0000-template.md` — mẫu ghi quyết định kỹ thuật (ví dụ đã điền: `0001-stack-selection.md`).

## Đã có repo khung này — giờ làm gì?
Bạn đã clone/tải repo khung về máy. Chọn đúng một nhánh:

- **Dự án MỚI (greenfield):** dựng dự án từ khung → theo `docs/framework/new-project-runbook.md` (runbook 0→9).
- **Dự án ĐÃ CÓ (brownfield):** mang khung sang dự án đích rồi mở Claude Code trong đó — các bước bên dưới.

### Bước 1 — Mang khung sang dự án đích (một lệnh)
> Không muốn tự gõ lệnh? Nhờ AI làm thay: nếu AI đang có quyền truy cập cả repo khung và repo đích
> (bash/git, hoặc cả hai repo đã được thêm vào cùng phiên), chỉ cần nói "áp khung ở đây vào dự án đích,
> tự chạy `copy-framework.sh` giúp tôi" — AI tự clone/copy và chạy đúng lệnh dưới đây, không cần bạn tự
> gõ. Chi tiết + giới hạn: `docs/framework/existing-project-adoption.md` (mục "Cách khác — không tự tay
> chạy lệnh").

Đứng **trong repo khung này**, trỏ tới thư mục gốc của dự án đích. Script **không đè** file đang chạy:
tài liệu khung + `.claude/` (commands, settings mặc định Sonnet 5, hooks, agents) + `scripts/` (dev-task, usage-estimate —
hook tự động cần 2 file này) copy thẳng; file gốc (`CLAUDE.md`, `PROJECT.md`…) chỉ copy nếu **chưa có**
(đã có thì để bản `.framework-new` cạnh bên để tự so); file cấu hình/stack đưa vào `_framework-dropins/` để tự merge.

**macOS / Linux (bash):**
```bash
bash copy-framework.sh /đường-dẫn/tới/dự-án
```

**Windows (PowerShell)** — bản `.ps1` hành vi **giống hệt** bản `.sh`:
```powershell
# Windows PowerShell 5.1 có sẵn trên mọi máy Windows — không cần cài gì thêm:
powershell -ExecutionPolicy Bypass -File .\copy-framework.ps1 C:\đường-dẫn\tới\dự-án

# Nếu đã cài PowerShell 7 (lệnh pwsh):
pwsh ./copy-framework.ps1 C:\đường-dẫn\tới\dự-án
```
> **Vì sao có `-ExecutionPolicy Bypass`:** Windows mặc định chặn chạy script `.ps1` chưa ký. Cờ này chỉ nới
> cho đúng lần chạy đó (không đổi cấu hình máy). Nếu muốn nới sẵn cho user hiện tại:
> `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned`.

### Bước 2 — Merge phần CI/quy ước GitHub
Soát thư mục `_framework-dropins/` trong dự án đích: so/merge từng workflow, PR template, dependabot,
CODEOWNERS với cấu hình CI đã có (nếu có) — đừng đè cấu hình đang chạy. Với `ci.yml`: thêm job
build/lint/type/test theo đúng stack đã chọn (research-first, `/consult`) vào file, giữ nguyên các job
tự kiểm của khung (bản kê ở `docs/ops/repository-settings.md`) và thêm job mới vào `needs:` của `gate`. Xong thì xóa `_framework-dropins/`. Với file `*.framework-new`: so với bản gốc
rồi gộp phần cần, sau đó xóa.

### Bước 3 — Mở Claude Code trong dự án đích
AI tự đọc `CLAUDE.md` rồi **research-first** chọn công nghệ (KHUNG-3, `/consult`) nếu là dự án mới,
hoặc chạy **Bước 0** của `docs/framework/existing-project-adoption.md` (tự dò stack qua
`package.json`/config — không cần bạn khai) nếu là dự án có sẵn. Từ đó dựng nền theo đúng hồ sơ đã
chọn: lint/format → type-check nghiêm → hook → CI → lấp lỗ hổng test/a11y/hiệu năng theo hồ sơ.
Muốn **hoàn thiện toàn dự án** (hết lỗi đã biết, tính năng thống nhất, có bằng chứng) → gõ
`/completion` (`docs/framework/project-completion.md`).

> *Vì sao phải copy chứ không "đưa link": một phiên Claude Code chỉ tự nạp luật từ chính repo của nó
> (và `~/.claude/CLAUDE.md`), không đọc được repo khác qua link.* Chi tiết brownfield: `docs/framework/existing-project-adoption.md`.

## Lưu ý
- README này KHÔNG cần commit vào dự án thật — xóa sau khi setup xong nếu muốn.
- Repo khung không kèm scaffold của bất kỳ stack nào — mọi lựa chọn công nghệ đến từ research-first
  (KHUNG-3), không có mặc định để "vừa đủ dùng" thay cho lựa chọn đúng đắn cho dự án của bạn.
