# install.ps1
# One-click installer: VC++ Redistributable + latest ChatGPT (Codex) from Microsoft Store
# Repo: https://github.com/xinCodes/codex-install
# Usage:
#   irm https://cdn.jsdelivr.net/gh/xinCodes/codex-install@main/install.ps1 | iex
#   irm https://raw.githubusercontent.com/xinCodes/codex-install/main/install.ps1 | iex

$ErrorActionPreference = 'Stop'
$repo = 'xinCodes/codex-install'
$vcAsset = 'VC_redist.x64.exe'
$storeId = '9PLM9XGG6VKS' # Microsoft Store ChatGPT app (PackageFamilyName: OpenAI.Codex_2p2nqsd0c76g0)
$pkgName = 'OpenAI.Codex'

function Test-VcRedistInstalled {
    $paths = @(
        'HKLM:\SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x64',
        'HKLM:\SOFTWARE\WOW6432Node\Microsoft\VisualStudio\14.0\VC\Runtimes\x64'
    )
    foreach ($p in $paths) {
        if (Test-Path $p) {
            $v = (Get-ItemProperty $p -Name Installed -ErrorAction SilentlyContinue).Installed
            if ($v -eq 1) { return $true }
        }
    }
    return $false
}

Write-Host ''
Write-Host '============================================' -ForegroundColor Cyan
Write-Host '  ChatGPT (Codex) One-click Installer' -ForegroundColor Cyan
Write-Host '============================================' -ForegroundColor Cyan

# ---------- [1/3] VC++ Redistributable ----------
Write-Host '[1/3] Checking Visual C++ x64 Redistributable...' -ForegroundColor Yellow
if (Test-VcRedistInstalled) {
    Write-Host '  [OK] Already installed, skip' -ForegroundColor Green
} else {
    Write-Host '  Downloading VC++ Redistributable from GitHub Releases...'
    $release = Invoke-RestMethod "https://api.github.com/repos/$repo/releases/latest"
    $asset = $release.assets | Where-Object { $_.name -eq $vcAsset } | Select-Object -First 1
    if (-not $asset) { throw "Asset not found in latest release: $vcAsset" }
    $tmp = Join-Path $env:TEMP $vcAsset
    Write-Host "  Downloading $vcAsset (~18MB)..."
    Invoke-WebRequest $asset.browser_download_url -OutFile $tmp
    Write-Host '  Installing silently (click YES if UAC prompts)...'
    $p = Start-Process -FilePath $tmp -ArgumentList '/install', '/quiet', '/norestart' -Verb RunAs -Wait -PassThru
    Remove-Item $tmp -Force -ErrorAction SilentlyContinue
    # 0=success  3010=success, reboot required  1638=already installed (newer)
    if ($p.ExitCode -notin @(0, 3010, 1638)) { throw "VC++ install failed (exit code $($p.ExitCode))" }
    Write-Host '  [OK] VC++ Redistributable installed' -ForegroundColor Green
}

# ---------- [2/3] Latest ChatGPT from Microsoft Store ----------
Write-Host ''
Write-Host '[2/3] Getting latest ChatGPT package from Microsoft Store (winget msstore)...' -ForegroundColor Yellow
$wingetVer = (winget --version) 2>$null
$wingetMajor = 0
if ($wingetVer -match 'v?(\d+)\.') { $wingetMajor = [int]$Matches[1] }
Write-Host "  winget version: $wingetVer"

$existing = Get-AppxPackage -Name $pkgName -ErrorAction SilentlyContinue
if ($existing) {
    Write-Host "  Installed version: $($existing.Version), upgrading to latest..."
}

function Invoke-Winget {
    param([string[]]$ArgsList, [int]$TimeoutSec = 300)
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = 'winget'
    $psi.Arguments = ($ArgsList -join ' ')
    $psi.UseShellExecute = $false
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.CreateNoWindow = $true
    $p = [System.Diagnostics.Process]::Start($psi)
    $outTask = $p.StandardOutput.ReadToEndAsync()
    $errTask = $p.StandardError.ReadToEndAsync()
    if (-not $p.WaitForExit($TimeoutSec * 1000)) {
        try { $p.Kill() } catch { }
        Write-Host "  [WARN] winget timed out after ${TimeoutSec}s, killed" -ForegroundColor Yellow
        return -1
    }
    $stdout = $outTask.Result
    $stderr = $errTask.Result
    if ($stdout) { Write-Host $stdout.TrimEnd() }
    if ($stderr) { Write-Host $stderr.TrimEnd() }
    return $p.ExitCode
}

$msstoreArgs = @('install', '--id', $storeId, '--source', 'msstore', '--accept-package-agreements', '--accept-source-agreements')
$code = Invoke-Winget -ArgsList $msstoreArgs
Write-Host "  msstore exit code: $code"
if ($code -notin @(0, -1978335189) -and $wingetMajor -lt 2) {
    Write-Host '  msstore source failed, trying to upgrade winget first...' -ForegroundColor Yellow
    $upgradeCode = Invoke-Winget -ArgsList @('install', '--id', 'Microsoft.AppInstaller', '--source', 'winget', '--accept-package-agreements', '--accept-source-agreements') -TimeoutSec 420
    Write-Host "  winget upgrade exit code: $upgradeCode"
    if ($upgradeCode -eq 0) {
        Write-Host '  winget upgraded, retrying msstore install...'
        $code = Invoke-Winget -ArgsList $msstoreArgs
        Write-Host "  msstore retry exit code: $code"
    }
}
if ($code -notin @(0, -1978335189)) {
    Write-Host '  [WARN] Could not install via winget, opening Microsoft Store page for manual install...' -ForegroundColor Yellow
    Start-Process "ms-windows-store://pdp/?ProductId=$storeId"
    throw "winget msstore failed (exit code $code). Complete the install in the Microsoft Store window, then rerun to verify."
}
if ($code -eq -1978335189) { Write-Host '  [OK] Already up to date' -ForegroundColor Green }

# ---------- [3/3] Verify ----------
Write-Host ''
Write-Host '[3/3] Verifying installation...' -ForegroundColor Yellow
$pkg = Get-AppxPackage -Name $pkgName -ErrorAction SilentlyContinue
if ($pkg) {
    Write-Host "  [OK] $($pkg.Name) version $($pkg.Version) installed" -ForegroundColor Green
} else {
    Write-Host '  [WARN] Package not detected, check Start Menu or Microsoft Store' -ForegroundColor Yellow
}

Write-Host ''
Write-Host '============================================' -ForegroundColor Cyan
Write-Host '  Done' -ForegroundColor Cyan
Write-Host '============================================' -ForegroundColor Cyan
