#!/usr/bin/env pwsh
#
# copy-framework.ps1 — Mang bộ khung sang một DỰ ÁN KHÁC (kể cả dự án đã có sẵn).
#   → Bản PowerShell của copy-framework.sh, dùng cho Windows PowerShell / PowerShell 7+.
#     Hành vi giống bản .sh (trừ --upgrade, xem DEBT bên dưới).
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
# An toàn cho dự án đã có sẵn (brownfield): danh sách file và cách copy từng nhóm (copy thẳng / chỉ copy
#   nếu CHƯA có, đã có mà khác thì để cạnh <file>.framework-new, giống hệt thì bỏ qua / đưa vào
#   _framework-dropins/) nằm ở copy-framework.manifest — một nguồn cho cả .sh và .ps1.
#
# Đích có .git và chưa đặt core.hooksPath → đặt scripts/githooks (cổng commit cho harness ngoài Claude Code);
#   đã đặt giá trị khác thì giữ nguyên + cảnh báo; -NoHooks bỏ bước này. Bản stage của CODEOWNERS
#   đổi @seeker19110 → @OWNER-CHANGE-ME (khớp copy-framework.sh).
#
[CmdletBinding()]
param(
  [switch] $Upgrade,
  [switch] $NoHooks,
  [Parameter(Position = 0)]
  [string] $Target
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Ép console xuất UTF-8 để chữ tiếng Việt trong thông báo hiển thị đúng trên Windows PowerShell 5.1
# (mặc định in theo code page hệ thống). Bọc try/catch để không bao giờ làm script dừng.
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch { }
# Chuỗi pipe vào lệnh ngoài (git hash-object --stdin-paths) cũng phải là UTF-8 (5.1 mặc định ASCII).
$OutputEncoding = New-Object System.Text.UTF8Encoding $false

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

function Test-SameFile {         # cùng byte (như cmp -s)
  param([string] $A, [string] $B)
  if ((Get-Item -LiteralPath $A -Force).Length -ne (Get-Item -LiteralPath $B -Force).Length) { return $false }
  return (Get-FileHash -LiteralPath $A).Hash -eq (Get-FileHash -LiteralPath $B).Hash
}

function Get-RelFileList {       # mọi file trong thư mục (kể cả ẩn), đường dẫn tương đối, sắp xếp ordinal
  param([string] $Dir)
  $base = (Get-Item -LiteralPath $Dir -Force).FullName.TrimEnd('\', '/')
  [string[]] $list = @(Get-ChildItem -LiteralPath $Dir -Recurse -File -Force | ForEach-Object { $_.FullName.Substring($base.Length + 1) })
  [Array]::Sort($list, [StringComparer]::Ordinal)
  return ,$list
}

function Test-SameContent {     # file → như cmp -s; thư mục → như diff -rq (đích thừa/thiếu file = khác)
  param([string] $SrcFull, [string] $DestFull)
  if (-not (Test-Path -LiteralPath $SrcFull -PathType Container)) {
    return (Test-Path -LiteralPath $DestFull -PathType Leaf) -and (Test-SameFile $SrcFull $DestFull)
  }
  if (-not (Test-Path -LiteralPath $DestFull -PathType Container)) { return $false }
  $a = Get-RelFileList $SrcFull
  $b = Get-RelFileList $DestFull
  if (($a -join "`n") -cne ($b -join "`n")) { return $false }
  foreach ($r in $a) { if (-not (Test-SameFile (Join-Path $SrcFull $r) (Join-Path $DestFull $r))) { return $false } }
  return $true
}

function Copy-OrAside {         # chưa có → copy; giống hệt → bỏ qua (= REL); khác → để bản .framework-new
  param([string] $SrcFull, [string] $Rel, [string] $Note = '')
  $destFull = Join-Path $Target (Resolve-Rel $Rel)
  if (-not (Test-Path -LiteralPath $destFull)) {
    Copy-Tree -SrcFull $SrcFull -DestFull $destFull
    Write-Host ("  + $Rel" + $(if ($Note) { " $Note" } else { '' }))
  }
  elseif (Test-SameContent $SrcFull $destFull) {
    Write-Host "  = $Rel"   # chạy lại trên đích chưa sửa: không rải bản trùng (F-Q7)
  }
  else {
    Copy-Tree -SrcFull $SrcFull -DestFull ($destFull + '.framework-new')
    Write-Host "  ~ $Rel đã tồn tại → bản khung để ở $Rel.framework-new (tự so/merge)"
  }
}

function Copy-IfAbsent {        # chỉ copy nếu đích chưa có; có mà khác thì để bản .framework-new
  param([string] $Rel)
  $srcFull = Join-Path $Src (Resolve-Rel $Rel)
  if (-not (Test-Path -LiteralPath $srcFull)) { return }
  Copy-OrAside -SrcFull $srcFull -Rel $Rel
}

function Test-HasGit { return [bool](Get-Command git -ErrorAction SilentlyContinue) }

function Invoke-Git {           # chạy git, trả $true nếu exit 0; không bao giờ ném lỗi (stderr bị nuốt)
  param([string[]] $GitArgs, $StdIn = $null)
  # Windows PowerShell 5.1 + 'Stop' biến MỌI dòng stderr của lệnh ngoài (vd cảnh báo "LF will be replaced
  # by CRLF") thành lỗi dừng dù exit 0 → hạ xuống 'Continue' trong phạm vi hàm, chỉ tin $LASTEXITCODE.
  $ErrorActionPreference = 'Continue'
  try {
    if ($null -ne $StdIn) { $script:GitOut = @($StdIn | & git @GitArgs 2>$null) }
    else { $script:GitOut = @(& git @GitArgs 2>$null) }
    return ($LASTEXITCODE -eq 0)
  } catch { return $false }
}

function Get-Layer1Files {      # đúng tập Lớp 1 như layer1_files của copy-framework.sh, đường dẫn tương đối '/' , sắp xếp ordinal
  $out = New-Object System.Collections.Generic.List[string]
  foreach ($d in @('docs/framework', '.claude/commands')) {
    foreach ($r in (Get-RelFileList (Join-Path $Src $d))) { $out.Add($d + '/' + $r.Replace('\', '/')) }
  }
  Get-ChildItem -LiteralPath (Join-Path $Src 'docs/ops') -Filter '*.md' -File -Force | ForEach-Object {
    if ($_.Name -notmatch '-(PLAN|LOG|STATUS)\.md$') { $out.Add('docs/ops/' + $_.Name) }
  }
  [string[]] $arr = $out.ToArray()
  [Array]::Sort($arr, [StringComparer]::Ordinal)
  return ,$arr
}

function Get-ManifestLines {    # "manifest: HASH FILE" cho từng file Lớp 1 (HASH = git hash-object, như .sh)
  if (-not (Test-HasGit)) {
    Write-Host "  ! không có git → FRAMEWORK-VERSION thiếu dòng manifest (bash copy-framework.sh --upgrade sẽ coi mọi file là đã sửa)"
    return @()
  }
  $files = Get-Layer1Files
  $abs = ($files | ForEach-Object { Join-Path $Src (Resolve-Rel $_) }) -join "`n"
  if (-not (Invoke-Git -GitArgs @('hash-object', '--stdin-paths') -StdIn $abs) -or $script:GitOut.Count -ne $files.Count) {
    Write-Host "  ! git hash-object lỗi → FRAMEWORK-VERSION thiếu dòng manifest"
    return @()
  }
  for ($i = 0; $i -lt $files.Count; $i++) { "manifest: $($script:GitOut[$i].Trim()) $($files[$i])" }
}

function Set-ExecBit {          # Windows không có chmod: ghi mode 100755 vào index git của đích (F-Q8)
  if (-not (Test-Path -LiteralPath (Join-Path $Target '.git'))) {
    Write-Host "  ! exec-bit chưa đặt: đích không có .git — sau git init chạy  git update-index --add --chmod=+x <script .sh>"
    return
  }
  # Đúng tập `chmod +x` của copy-framework.sh + mọi .claude/hooks/*.sh.
  $rels = @('scripts/dev-task.sh', 'scripts/githooks/pre-commit', 'scripts/usage-estimate.sh', 'scripts/test-hooks-gate.sh',
            'scripts/maintenance-sweep.sh', 'scripts/maintain-run.sh', 'scripts/maintain-cron.sh')
  $hooksDir = Join-Path $Target '.claude/hooks'
  if (Test-Path -LiteralPath $hooksDir -PathType Container) {
    $rels += @(Get-ChildItem -LiteralPath $hooksDir -Filter '*.sh' -File | ForEach-Object { '.claude/hooks/' + $_.Name })
  }
  [string[]] $existing = @($rels | Where-Object { Test-Path -LiteralPath (Join-Path $Target (Resolve-Rel $_)) -PathType Leaf })
  if ($existing.Count -eq 0) { return }
  if ((Test-HasGit) -and (Invoke-Git -GitArgs (@('-C', $Target, 'update-index', '--add', '--chmod=+x', '--') + $existing))) {
    Write-Host "  + exec-bit (git index 100755): $($existing.Count) script"
  }
  else {
    Write-Host "  ! exec-bit chưa đặt: git update-index lỗi/không có git — tự chạy  git update-index --add --chmod=+x <script .sh>"
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
  $destFull = Join-Path (Join-Path $Target '_framework-dropins') $relN
  Copy-Tree -SrcFull $srcFull -DestFull $destFull
  if ($Rel -eq '.github/CODEOWNERS') {   # owner của khung không được rò sang đích (F-A5); LF + UTF-8 không BOM như bản .sh
    $txt = [System.IO.File]::ReadAllText($destFull) -replace '@seeker19110', '@OWNER-CHANGE-ME'
    [System.IO.File]::WriteAllText($destFull, $txt, (New-Object System.Text.UTF8Encoding $false))
  }
  Write-Host "  → _framework-dropins/$Rel"
}

function Enable-HooksPath {     # đặt core.hooksPath=scripts/githooks ở đích nếu chưa đặt (F-A7); không bao giờ ghi đè giá trị đã có
  if ($NoHooks) { Write-Host "  ~ -NoHooks: không đặt core.hooksPath"; return }
  if (-not (Test-Path -LiteralPath (Join-Path $Target '.git'))) {
    Write-Host "  ! đích chưa có .git → chưa đặt core.hooksPath; sau git init chạy: git config core.hooksPath scripts/githooks"
    return
  }
  $cur = ''
  if ((Test-HasGit) -and (Invoke-Git -GitArgs @('-C', $Target, 'config', 'core.hooksPath')) -and $script:GitOut.Count -gt 0) { $cur = ([string]$script:GitOut[0]).Trim() }
  if ($cur -eq 'scripts/githooks') { Write-Host "  = core.hooksPath=scripts/githooks" }
  elseif ($cur) { Write-Host "  ~ core.hooksPath đã đặt '$cur' → giữ nguyên (muốn cổng commit của khung: git config core.hooksPath scripts/githooks)" }
  elseif ((Test-HasGit) -and (Invoke-Git -GitArgs @('-C', $Target, 'config', 'core.hooksPath', 'scripts/githooks'))) { Write-Host "  + core.hooksPath=scripts/githooks" }
  else { Write-Host "  ! không đặt được core.hooksPath — tự chạy: git config core.hooksPath scripts/githooks" }
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
# Cùng khuôn với copy-framework.sh: version + commit + ngày + manifest hash từng file Lớp 1, để
# `bash copy-framework.sh <đích> --upgrade` sau này biết file nào đích đã sửa tay (F-D-05).
$FrameworkCommit = 'khong-ro'
if ((Test-HasGit) -and (Invoke-Git -GitArgs @('-C', $Src, 'rev-parse', '--short', 'HEAD')) -and $script:GitOut.Count -gt 0) {
  $FrameworkCommit = $script:GitOut[0].Trim()
}
$FrameworkVer = '0.0.0'
$versionFile = Join-Path $Src 'VERSION'
if (Test-Path -LiteralPath $versionFile -PathType Leaf) { $FrameworkVer = (Get-Content -LiteralPath $versionFile -Raw) -replace '\s', '' }
[string[]] $manifestLines = @(Get-ManifestLines)
$stampLines = @(
  "# FRAMEWORK-VERSION — dấu bản khung đã copy (sinh tự động bởi copy-framework.ps1 — đừng sửa tay)"
  "version: $FrameworkVer"
  "commit-nguon: $FrameworkCommit"
  "ngay-copy: $(Get-Date -Format 'yyyy-MM-dd')"
  "# Nâng bản: clone repo khung mới nhất rồi chạy  bash copy-framework.sh <đích> --upgrade  (giữ chỉnh sửa cục bộ; xem CHANGELOG.md từ ${FrameworkCommit}..HEAD)"
  "# manifest: <git hash-object> <file> — file đích có hash KHÁC dòng này = đã sửa tay (--upgrade sẽ merge/để cạnh, không ghi đè)"
) + $manifestLines
# LF + UTF-8 không BOM: bản .sh đọc stamp bằng grep/awk — CRLF làm `commit-nguon`/hash dính '\r'.
[System.IO.File]::WriteAllText((Join-Path $Target 'docs/framework/FRAMEWORK-VERSION'), (($stampLines -join "`n") + "`n"), (New-Object System.Text.UTF8Encoding $false))
Write-Host "  + docs/framework/FRAMEWORK-VERSION (bản khung: v$FrameworkVer @ $FrameworkCommit, manifest $($manifestLines.Count) file)"

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

Copy-OrAside -SrcFull (Join-Path $Src '.claude/settings-shared-default.json') -Rel '.claude/settings.json' -Note '(Sonnet 5; fallback Sonnet 5 → Haiku 4.5)'

foreach ($e in Get-ManifestSection scripts) { Copy-IfAbsent $e[0] }
Set-ExecBit
Enable-HooksPath

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
     → CODEOWNERS trong đó mang placeholder @OWNER-CHANGE-ME: thay bằng chủ repo/team thật
       trước khi dùng (maintenance-sweep sẽ nhắc 🟡 nếu còn sót).
     → core.hooksPath đã đặt scripts/githooks (nếu đích có .git và chưa đặt) để mọi harness đi qua
       cổng commit; không muốn thì chạy lại với -NoHooks hoặc git config --unset core.hooksPath.

  4) Commit, rồi áp khung tăng dần theo existing-project-adoption.md
     (Prettier → ESLint → TS strict → hook → CI → lấp lỗ hổng test/a11y/hiệu năng).

  5) Muốn hoàn thiện toàn dự án (hết lỗi đã biết, tính năng thống nhất, có bằng chứng):
     gõ /completion — audit 12 nhóm → kế hoạch chi tiết (duyệt) → sửa từng đợt → quét lại đến khi sạch.

  (Tùy chọn) Muốn luật áp cho MỌI dự án trên máy: chép CLAUDE.md vào ~/.claude/CLAUDE.md.
'@
Write-Host ""
