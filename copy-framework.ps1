#!/usr/bin/env pwsh
#
# copy-framework.ps1 — Mang bộ khung sang một DỰ ÁN KHÁC (kể cả dự án đã có sẵn).
#   → Bản PowerShell của copy-framework.sh, dùng cho Windows PowerShell / PowerShell 7+.
#     Hành vi giống hệt bản .sh (3 lớp: copy thẳng / copy nếu chưa có / đưa vào _framework-dropins).
#
# LƯU Ý MÃ HÓA: file này PHẢI được lưu dưới dạng UTF-8 CÓ BOM. Windows PowerShell 5.1 mặc định
#   đọc script theo ANSI; thiếu BOM sẽ làm hỏng ký tự tiếng Việt và gây lỗi parse
#   ("Missing closing '}'"). PowerShell 7 (pwsh) đọc UTF-8 không BOM vẫn được. Đừng lưu lại thành
#   "UTF-8 no BOM" khi chỉnh file này.
#
# Cách dùng:
#   1) Clone repo khung này về máy (hoặc bạn đang đứng sẵn trong nó).
#   2) Chạy (một trong hai):
#        pwsh ./copy-framework.ps1 C:\đường-dẫn\tới\dự-án-đích
#        powershell -ExecutionPolicy Bypass -File .\copy-framework.ps1 C:\đường-dẫn\tới\dự-án-đích
#   3) Mở phiên Claude Code TRONG dự án đích → AI tự đọc CLAUDE.md và tự dò stack.
#
# An toàn cho dự án đã có sẵn (brownfield):
#   - Tài liệu khung (docs/framework, mẫu ADR)  → copy thẳng (chỉ là tài liệu tham khảo mới).
#   - File gốc (CLAUDE.md, PROJECT.md...)        → chỉ copy nếu CHƯA có; nếu đã có thì để bản
#                                                  khung cạnh bên dưới đuôi .framework-new để bạn tự so.
#   - Cấu hình Claude Code (.claude/settings.json, .claude/hooks, .claude/agents,
#     scripts/dev-task.sh, scripts/usage-estimate.sh, 2 file .claude/*.example.sh)
#                                                  → chỉ copy nếu CHƯA có; nếu đã có thì để bản
#                                                  khung cạnh bên (đuôi .framework-new) để bạn tự so.
#   - File CI/quy ước GitHub (workflows, PR template, dependabot...) → KHÔNG đè; đưa vào
#     _framework-dropins/ để bạn tự so/merge với cấu hình CI đã có (nếu có).
#
[CmdletBinding()]
param(
  [switch] $Upgrade,
  [Parameter(Position = 0)]
  [string] $Target
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Ép console xuất UTF-8 để chữ tiếng Việt trong thông báo hiển thị đúng trên Windows PowerShell 5.1
# (mặc định in theo code page hệ thống). Bọc try/catch để không bao giờ làm script dừng.
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch { }

$Src = $PSScriptRoot
$Sep = [System.IO.Path]::DirectorySeparatorChar

if ($Upgrade) {
  # DEBT: --upgrade (merge 3 chiều + manifest) chỉ có ở copy-framework.sh | trần: bản .ps1 vẫn ghi đè Lớp 1 | xem lại khi: có người dùng Windows không có Git Bash cần nâng bản
  Write-Host "Nâng bản (-Upgrade) chưa hỗ trợ ở bản .ps1 — dùng Git Bash (có sẵn với Git for Windows):"
  Write-Host "  bash copy-framework.sh '$Target' --upgrade"
  exit 2
}
if ([string]::IsNullOrWhiteSpace($Target)) {
  Write-Host "Lỗi: thiếu đường dẫn dự án đích."
  Write-Host "Dùng:  pwsh ./copy-framework.ps1 /đường-dẫn/tới/dự-án-đích"
  exit 1
}
if (-not (Test-Path -LiteralPath $Target -PathType Container)) {
  Write-Host "Lỗi: '$Target' không phải thư mục."
  exit 1
}
if (-not (Test-Path -LiteralPath (Join-Path $Target '.git'))) {
  Write-Host "Cảnh báo: '$Target' không có .git — chắc đây là gốc repo dự án chứ?"
}

# ── Trợ giúp ──────────────────────────────────────────────
# Copy "src thành dest": thư mục → copy toàn bộ nội dung vào dest; file → copy file.
# Xác định theo dest, không tạo thư mục lồng thừa (khác cp -R vào dir có sẵn).
function Copy-Tree {
  param([string] $SrcFull, [string] $DestFull)
  if (Test-Path -LiteralPath $SrcFull -PathType Container) {
    New-Item -ItemType Directory -Force -Path $DestFull | Out-Null
    Get-ChildItem -LiteralPath $SrcFull -Force | ForEach-Object {
      Copy-Item -LiteralPath $_.FullName -Destination $DestFull -Recurse -Force
    }
  }
  else {
    $parent = Split-Path -Parent $DestFull
    if ($parent) { New-Item -ItemType Directory -Force -Path $parent | Out-Null }
    Copy-Item -LiteralPath $SrcFull -Destination $DestFull -Force
  }
}

function Resolve-Rel { param([string] $Rel) return $Rel.Replace('/', $Sep) }

function Copy-Into {            # copy thẳng (tạo thư mục cha)
  param([string] $Rel)
  $relN = Resolve-Rel $Rel
  $srcFull = Join-Path $Src $relN
  if (-not (Test-Path -LiteralPath $srcFull)) { return }
  Copy-Tree -SrcFull $srcFull -DestFull (Join-Path $Target $relN)
  Write-Host "  + $Rel"
}

function Copy-IfAbsent {        # chỉ copy nếu đích chưa có; nếu có thì để bản .framework-new
  param([string] $Rel)
  $relN = Resolve-Rel $Rel
  $srcFull = Join-Path $Src $relN
  if (-not (Test-Path -LiteralPath $srcFull)) { return }
  $destFull = Join-Path $Target $relN
  if (Test-Path -LiteralPath $destFull) {
    Copy-Tree -SrcFull $srcFull -DestFull ($destFull + '.framework-new')
    Write-Host "  ~ $Rel đã tồn tại → bản khung để ở $Rel.framework-new (tự so/merge)"
  }
  else {
    Copy-Tree -SrcFull $srcFull -DestFull $destFull
    Write-Host "  + $Rel"
  }
}

function Add-Dropin {           # đưa vào _framework-dropins/ (không đụng file đang chạy)
  param([string] $Rel)
  $relN = Resolve-Rel $Rel
  $srcFull = Join-Path $Src $relN
  if (-not (Test-Path -LiteralPath $srcFull)) { return }
  Copy-Tree -SrcFull $srcFull -DestFull (Join-Path (Join-Path $Target '_framework-dropins') $relN)
  Write-Host "  → _framework-dropins/$Rel"
}

Write-Host ""
Write-Host "Nguồn:  $Src"
Write-Host "Đích:   $Target"
Write-Host ""

# ── LỚP 1 — Quy trình & tiêu chuẩn (áp mọi stack): copy thẳng ──
Write-Host "[1/4] Tài liệu khung (Lớp 1 — dùng được ngay, mọi stack):"
Copy-Into "docs/framework"
# docs/ops: chỉ copy TÀI LIỆU hướng dẫn; *-PLAN/*-LOG/*-STATUS là trạng thái nội bộ của repo khung —
# copy sang là nhiễu và chạy lại sẽ đè mất nhật ký thật của dự án đích (khớp copy-framework.sh).
Get-ChildItem -LiteralPath (Join-Path $Src 'docs/ops') -Filter '*.md' | ForEach-Object {
  if ($_.Name -notmatch '-(PLAN|LOG|STATUS)\.md$') { Copy-Into ("docs/ops/" + $_.Name) }
}
Copy-IfAbsent "docs/specs/README.md"                # pr-policy.yml (Lớp 2) đòi docs/specs/ tồn tại cho PR feat
Copy-IfAbsent "docs/goals/README.md"
Copy-Into ".claude/commands"                   # slash commands của khung: /consult /bootstrap /auto /gate /adr /ui-ux /audit-optimize /audit-full /completion /incident /grill /debug
Copy-IfAbsent "docs/adr/0000-template.md"

# ── Dấu bản khung (luôn ghi đè — phản ánh LẦN COPY GẦN NHẤT) ──
# Để dự án đích biết mình đang dùng khung bản nào; muốn cập nhật thì so CHANGELOG.md
# của repo khung từ commit này trở đi, rồi chạy lại copy-framework.ps1.
$FrameworkCommit = 'khong-ro'
try {
  $c = (git -C $Src rev-parse --short HEAD 2>$null)
  if ($LASTEXITCODE -eq 0 -and $c) { $FrameworkCommit = $c.Trim() }
} catch { }
@(
  "# FRAMEWORK-VERSION — dấu bản khung đã copy (sinh tự động bởi copy-framework.ps1 — đừng sửa tay)"
  "commit-nguon: $FrameworkCommit"
  "ngay-copy: $(Get-Date -Format 'yyyy-MM-dd')"
  "# Cách cập nhật: trong repo khung, xem CHANGELOG.md (hoặc git log $FrameworkCommit..HEAD) rồi chạy lại copy-framework.ps1"
) | Set-Content -LiteralPath (Join-Path $Target 'docs/framework/FRAMEWORK-VERSION') -Encoding UTF8
Write-Host "  + docs/framework/FRAMEWORK-VERSION (bản khung: $FrameworkCommit)"

# ── File gốc dự án: chỉ copy nếu chưa có ──
Copy-IfAbsent "CLAUDE.md"
Copy-IfAbsent "AGENTS.md"                     # chuẩn mở agents.md — cho AI agent ngoài Claude Code (Cursor/Codex/Copilot...)
# File cầu nối sang AGENTS.md cho công cụ CHƯA tự đọc agents.md — không lặp nội dung, chỉ trỏ sang.
Copy-IfAbsent "GEMINI.md"                     # Gemini CLI
# (Codex CLI đọc thẳng AGENTS.md — không cần file cầu nối riêng.)
Copy-IfAbsent ".clinerules"                   # Cline / Roo Code
Copy-IfAbsent ".windsurfrules"                # Windsurf
Copy-IfAbsent ".cursor/rules"                 # Cursor
Copy-IfAbsent ".github/copilot-instructions.md"  # GitHub Copilot
Copy-IfAbsent "PROJECT.md"
# PROGRESS.md: dự án đích nhận bản MẪU SẠCH (PROGRESS.template.md) — KHÔNG nhận
# nhật ký phát triển của chính repo khung (PROGRESS.md ở repo khung là log của khung).
$progressDest = Join-Path $Target 'PROGRESS.md'
if (Test-Path -LiteralPath $progressDest) {
  Write-Host "  ~ PROGRESS.md đã tồn tại → giữ nguyên"
}
else {
  Copy-Item -LiteralPath (Join-Path $Src 'PROGRESS.template.md') -Destination $progressDest
  Write-Host "  + PROGRESS.md (từ mẫu sạch PROGRESS.template.md)"
}
Copy-IfAbsent "CHANGELOG.md"
Copy-IfAbsent "CONTRIBUTING.md"
Copy-IfAbsent "SECURITY.md"
# Quy tắc ứng xử: bản Contributor Covenant chung (SUPPORT/GOVERNANCE của khung KHÔNG copy —
# dự án đích tự sinh từ docs/framework/templates/).
Copy-IfAbsent "CODE_OF_CONDUCT.md"
Copy-IfAbsent ".editorconfig"
Copy-IfAbsent ".nvmrc"
Copy-IfAbsent ".mcp.json"                     # MCP Context7 — tài liệu đúng phiên bản cho research-first (KHUNG-3)
Copy-IfAbsent ".mcp.json.example"             # mẫu MCP server phổ biến (github/filesystem/postgres) — dự án tự bật khi cần
Copy-IfAbsent ".claude/settings.local.json.example"  # mẫu permission cá nhân, không dùng chung nhóm
# LICENSE KHÔNG copy: mỗi dự án tự chọn giấy phép + chủ sở hữu riêng.

# ── Cấu hình Claude Code + script tự động: copy thẳng (KHÔNG đè cấu hình đã có) ──
Write-Host ""
Write-Host "[2/4] Cấu hình Claude Code (model tiêu chuẩn Sonnet 5 — tối ưu token) + script tự động (hook gọi qua dev-task.sh):"
$claudeDir = Join-Path $Target '.claude'
New-Item -ItemType Directory -Force -Path $claudeDir | Out-Null

$settingsDest = Join-Path $claudeDir 'settings.json'
if (Test-Path -LiteralPath $settingsDest) {
  Copy-Tree -SrcFull (Join-Path $Src '.claude/settings-shared-default.json') -DestFull ($settingsDest + '.framework-new')
  Write-Host "  ~ .claude/settings.json đã tồn tại → bản khung để ở settings.json.framework-new (tự so/merge)"
}
else {
  Copy-Tree -SrcFull (Join-Path $Src '.claude/settings-shared-default.json') -DestFull $settingsDest
  Write-Host "  + .claude/settings.json (Sonnet 5; fallback Sonnet 5 → Haiku 4.5)"
}

Copy-IfAbsent ".claude/hooks"
Copy-IfAbsent ".claude/agents"
# Hook phụ thuộc các script này — thiếu thì hook no-op (mất auto-format + cổng chặn commit đỏ + nhắc quota):
Copy-IfAbsent "scripts/dev-task.sh"
Copy-IfAbsent "scripts/_stack-detect.sh"          # dev-task.sh + maintenance-sweep.sh source file này
Copy-IfAbsent "scripts/githooks/pre-commit"       # hàng rào harness-agnostic: git config core.hooksPath scripts/githooks
Copy-IfAbsent "scripts/usage-estimate.sh"
Copy-IfAbsent "scripts/test-usage-estimate.sh"
Copy-IfAbsent "scripts/subagent-dispatch.py"
# Helper dung chung — PHAI phat truoc cac script source/exec chung (xem TRAPS.md muc 19).
Copy-IfAbsent "scripts/_python-exec.sh"
Copy-IfAbsent "scripts/_test-lib.sh"
Copy-IfAbsent "scripts/subagent-dispatch.sh"
Copy-IfAbsent "scripts/model-rates.json"
Copy-IfAbsent "scripts/model-capability-tiers.json"
Copy-IfAbsent "scripts/telemetry-log.py"
Copy-IfAbsent "scripts/telemetry-log.sh"
Copy-IfAbsent "scripts/spec-compiler.py"
Copy-IfAbsent "scripts/spec-compiler.sh"
Copy-IfAbsent "scripts/arch-health-radar.py"
Copy-IfAbsent "scripts/arch-health-radar.sh"
Copy-IfAbsent "scripts/test-telemetry-and-dispatch.sh"
Copy-IfAbsent "tests/test_telemetry_integrity.py"  # required by the shipped telemetry self-test
Copy-IfAbsent "tests/test_runtime_safety.py"  # required by the CI drop-in; copy-only cases are template-scoped
Copy-IfAbsent "scripts/test-next-gen-engines.sh"
# Agent bảo trì toàn diện (spec 2026-09-14): engine quét + runner đa-provider + 2 self-test
Copy-IfAbsent "scripts/maintenance-sweep.sh"
Copy-IfAbsent "scripts/maintain-run.sh"
Copy-IfAbsent "scripts/test-maintenance-sweep.sh"
Copy-IfAbsent "scripts/test-maintain-run.sh"
Copy-IfAbsent "scripts/maintain-cron.sh"
Copy-IfAbsent "scripts/test-maintain-cron.sh"
# Test chứng minh hook cổng CHẶN thật (audit 2026-09-12, F-002) — đi cùng .claude/hooks ở trên.
Copy-IfAbsent "scripts/test-hooks-gate.sh"
Copy-IfAbsent "scripts/requirements-ci.txt"       # ghim radon/coverage cho ci.yml dropin (Dependabot pip theo dõi)
# 2 file mẫu để dự án tự điền (bản điền thật .claude/*.sh đã nằm trong .gitignore của khung):
Copy-IfAbsent ".claude/project-commands.example.sh"
Copy-IfAbsent ".claude/usage-budget.example.sh"

Write-Host ""
Write-Host "[3/4] File CI/quy ước GitHub (Lớp 2 — KHÔNG đè; để bạn tự so/merge với CI đã có):"
$dropins = @(
  '.github/workflows/ci.yml', '.github/workflows/stale-pr-alert.yml', '.github/workflows/maintenance.yml',
  '.github/workflows/secret-scan.yml', '.github/workflows/dependency-review.yml',
  '.github/workflows/pr-policy.yml', '.github/workflows/release.yml',
  '.github/workflows/codeql.yml', '.github/workflows/scorecard.yml',
  '.github/pull_request_template.md', '.github/dependabot.yml', '.github/ISSUE_TEMPLATE', '.github/CODEOWNERS',
  '.github/rulesets/main.json',
  'scripts/ci-workflow-policy.test.ts',
  '.gitignore', '.gitattributes'
)
foreach ($f in $dropins) { Add-Dropin $f }

Write-Host ""
Write-Host "[4/4] Xong. Tiếp theo trong dự án đích:"
Write-Host @'

  1) Cấu hình Claude Code đã sẵn sàng: .claude/settings.json dùng model tiêu chuẩn Sonnet 5.
     → Việc lập kế hoạch lớn: chủ động /model sang model cao cấp nhất đang sẵn có, xong tự /model
       claude-sonnet-5 quay lại — không còn chế độ opusplan tự chuyển (ADR-0007, CLI đã ngừng hỗ trợ).
     → Hook tự động (auto-format + chặn commit đỏ + nhắc quota) chạy qua scripts/dev-task.sh
       (tự dò stack). Dự án có lệnh riêng → copy .claude/project-commands.example.sh
       thành .claude/project-commands.sh rồi điền.
     ✅ Dự án rất phức tạp: nâng riêng lúc cần bằng /model claude-opus-5 (hoặc claude-fable-5-1).

  2) Mở phiên Claude Code NGAY TRONG dự án đích.
     → AI tự đọc CLAUDE.md + .claude/settings.json (model tiêu chuẩn sẵn sàng).
     → Chạy Bước 0 của docs/framework/existing-project-adoption.md
       (tự dò stack bằng cách đọc package.json/config — không cần bạn khai stack).

  3) Soát thư mục _framework-dropins/ : so/merge các file CI (.github/workflows/*,
     PR template, dependabot, CODEOWNERS, .gitignore, .gitattributes) với cấu hình
     CI đã có (nếu có) rồi merge cho khớp dự án. Xong thì có thể xóa _framework-dropins/.

  4) Commit, rồi áp khung tăng dần theo existing-project-adoption.md
     (Prettier → ESLint → TS strict → hook → CI → lấp lỗ hổng test/a11y/hiệu năng).

  5) Muốn hoàn thiện toàn dự án (hết lỗi đã biết, tính năng thống nhất, có bằng chứng):
     gõ /completion — audit 12 nhóm → kế hoạch chi tiết (duyệt) → sửa từng đợt → quét lại đến khi sạch.

  (Tùy chọn) Muốn luật áp cho MỌI dự án trên máy: chép CLAUDE.md vào ~/.claude/CLAUDE.md.
'@
Write-Host ""
