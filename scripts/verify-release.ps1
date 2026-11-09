# Verify downloaded release files before installing (Windows 10/11, built-in OpenSSH).
#   powershell -ExecutionPolicy Bypass -File scripts\verify-release.ps1 -Dir C:\Users\me\Downloads\keystead-v0.9.0 [-Version v0.9.0]
# The version written inside SHA256SUMS ("# keystead vX.Y.Z", signed with it) must match -Version (or a folder named
# like keystead-v0.9.0) and every file name, so an older signed release can't be passed off as the latest.
param([string]$Dir = ".", [string]$Version = "")
$ErrorActionPreference = "Stop"
$Signers = Join-Path $PSScriptRoot "..\.github\release-signing\allowed_signers"
$Ns = "securevault-release"

if (-not (Test-Path $Signers)) { Write-Host "공개 키 파일이 없습니다: $Signers"; exit 2 }
Push-Location $Dir
try {
  if (-not ((Test-Path SHA256SUMS) -and (Test-Path SHA256SUMS.sig))) { Write-Host "SHA256SUMS 와 SHA256SUMS.sig 를 같이 내려받으세요."; exit 2 }
  # ssh-keygen -Y needs OpenSSH 8.1+ (Windows 10's built-in one can be 7.7)
  $ver = (cmd /c "ssh -V 2>&1") -join " "
  if ($ver -match "OpenSSH[^0-9]*([0-9]+)\.([0-9]+)" -and ([int]$Matches[1] -lt 8 -or ([int]$Matches[1] -eq 8 -and [int]$Matches[2] -lt 1))) {
    Write-Host "OpenSSH가 오래됐어요($ver). 8.1 이상이 있어야 서명을 확인할 수 있어요: winget install Microsoft.OpenSSH.Beta" -ForegroundColor Yellow; exit 2
  }
  # feed the exact bytes (a PowerShell pipe would add a newline and break the signature)
  cmd /c "ssh-keygen -Y verify -f `"$Signers`" -I $Ns -n $Ns -s SHA256SUMS.sig < SHA256SUMS > NUL 2>&1"
  if ($LASTEXITCODE -ne 0) { Write-Host "서명이 맞지 않습니다. 이 파일들을 설치하지 마세요." -ForegroundColor Red; exit 1 }
  Write-Host "서명 확인: SHA256SUMS 는 Keystead 릴리스 키로 서명됐습니다." -ForegroundColor Green
  $rel = ""
  foreach ($line in Get-Content SHA256SUMS) { if ($line -match '^# keystead (v[0-9][0-9.]*)$') { $rel = $Matches[1]; break } }
  if (-not $Version) {
    $leaf = Split-Path -Leaf (Get-Location).Path
    if ($leaf -match '-v([0-9][0-9.]*)$') { $Version = "v$($Matches[1])"; Write-Host "  (폴더 이름에서 기대 버전 $Version 을 읽었습니다)" }
  }
  if ($rel) { Write-Host "버전: $rel (서명된 목록에 적힌 버전)" -ForegroundColor Green }
  else { Write-Host "목록에 버전이 없는 예전 릴리스입니다(0.8.x 이전). 릴리스 페이지의 최신 판인지 확인하세요." -ForegroundColor Yellow }
  if ($Version -and $rel -and ("v" + $Version.TrimStart("v")) -ne $rel) {
    Write-Host "기대한 버전(v$($Version.TrimStart('v')))이 아니라 $rel 입니다. 예전 판을 최신으로 속인 것일 수 있어요. 설치하지 마세요." -ForegroundColor Red; exit 1
  }
  $want = if ($Version) { $Version.TrimStart("v") } else { $rel.TrimStart("v") }
  $bad = 0; $checked = 0; $listed = @()
  foreach ($line in Get-Content SHA256SUMS) {
    if ($line.StartsWith("#")) { continue }
    $sum, $name = $line -split '\s+', 2
    $listed += $name
    # an old release has no version line, but its file names still give it away
    if ($want -and -not $name.Contains($want)) { Write-Host "BAD $name 은 v$want 파일이 아닙니다" -ForegroundColor Red; $bad = 1 }
    if (-not (Test-Path -LiteralPath $name)) { continue }
    $checked++
    $got = (Get-FileHash -Algorithm SHA256 -LiteralPath $name).Hash.ToLower()
    if ($got -eq $sum) { Write-Host "OK  $name" } else { Write-Host "BAD $name 해시가 다릅니다" -ForegroundColor Red; $bad = 1 }
  }
  # a Keystead file SHA256SUMS doesn't list (renamed "(1)" copy, swapped installer) fails
  foreach ($f in Get-ChildItem -File | Where-Object { $_.Name -match "keystead|securevault" -and $_.Name -notin @("SHA256SUMS", "SHA256SUMS.sig") }) {
    if ($listed -notcontains $f.Name) { Write-Host "BAD $($f.Name) 는 SHA256SUMS 에 없는 파일입니다" -ForegroundColor Red; $bad = 1 }
  }
  if ($checked -eq 0) { Write-Host "확인한 파일이 없습니다. 설치 파일을 SHA256SUMS 와 같은 폴더에 두세요." -ForegroundColor Red; exit 1 }
  if ($bad -eq 0) { Write-Host "모두 확인했습니다." } else { Write-Host "표시된 파일은 설치하지 마세요." }
  exit $bad
} finally { Pop-Location }
