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

function Get-ManifestSection {  # các dòng của mục [Name] trong copy-framework.manifest (một nguồn cho .sh và .ps1)
  param([string] $Name)
  $on = $false
  foreach ($line in Get-Content -LiteralPath (Join-Path $Src 'copy-framework.manifest') -Encoding UTF8) {
    $t = $line.Trim()
    if ($t.StartsWith('[')) { $on = ($t -eq "[$Name]"); continue }
    if ($on -and $t -and -not $t.StartsWith('#')) { ,@($t -split '\s+', 2) }
  }
}

function Add-Dropin {           # đưa vào _framework-dropins/ (không đụng file đang chạy)
  param([string] $Rel, [string] $SourceRel = $Rel)
  $relN = Resolve-Rel $Rel
  $srcFull = Join-Path $Src (Resolve-Rel $SourceRel)
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
Copy-Into ".claude/commands"                   # slash commands của khung (khớp copy-framework.sh)
foreach ($e in Get-ManifestSection docs) { Copy-IfAbsent $e[0] }

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
foreach ($e in Get-ManifestSection root) { Copy-IfAbsent $e[0] }
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

foreach ($e in Get-ManifestSection scripts) { Copy-IfAbsent $e[0] }

Write-Host ""
Write-Host "[3/4] File CI/quy ước GitHub (Lớp 2 — KHÔNG đè; để bạn tự so/merge với CI đã có):"
foreach ($e in Get-ManifestSection dropins) { if ($e.Count -gt 1) { Add-Dropin $e[0] $e[1] } else { Add-Dropin $e[0] } }

Write-Host ""
Write-Host "[4/4] Xong. Tiếp theo trong dự án đích:"
Write-Host @'

  1) Cấu hình Claude Code đã sẵn sàng: .claude/settings.json dùng model tiêu chuẩn Sonnet 5.
     → Việc lập kế hoạch lớn: chủ động /model sang model cao cấp nhất đang sẵn có, xong tự /model
       claude-sonnet-5 quay lại — không còn chế độ opusplan tự chuyển (ADR-0007, CLI đã ngừng hỗ trợ).
     → Hook tự động (auto-format + chặn commit đỏ + nhắc quota) chạy qua scripts/dev-task.sh
       (tự dò stack). Dự án có lệnh riêng → copy .claude/project-commands.example.sh
       thành .claude/project-commands.sh rồi điền.
     → Nếu CI cần file lệnh này: rà không có secret rồi `git add -f .claude/project-commands.sh`;
       file được ignore mặc định nên checkout CI sẽ không thấy nếu chưa track có chủ đích.
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
