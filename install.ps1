# install.ps1
# ChatGPT (Codex) 一键安装：VC++ 运行库 + 微软商店最新 ChatGPT 包
#
# 仓库: https://github.com/xinCodes/codex-install
# 用法:
#   irm https://raw.githubusercontent.com/xinCodes/codex-install/main/install.ps1 | iex

$ErrorActionPreference = 'Stop'
$repo = 'xinCodes/codex-install'
$vcAsset = 'VC_redist.x64.exe'
$storeId = '9PLM9XGG6VKS' # 微软商店 ChatGPT 官方应用（PackageFamilyName: OpenAI.Codex_2p2nqsd0c76g0）
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
Write-Host '  ChatGPT (Codex) 一键安装' -ForegroundColor Cyan
Write-Host '============================================' -ForegroundColor Cyan

# ---------- [1/3] VC++ 运行库 ----------
Write-Host '[1/3] 检查 Visual C++ x64 运行库...' -ForegroundColor Yellow
if (Test-VcRedistInstalled) {
    Write-Host '  [OK] 已安装，跳过' -ForegroundColor Green
} else {
    Write-Host '  从 GitHub Releases 获取 VC++ 运行库...'
    $release = Invoke-RestMethod "https://api.github.com/repos/$repo/releases/latest"
    $asset = $release.assets | Where-Object { $_.name -eq $vcAsset } | Select-Object -First 1
    if (-not $asset) { throw "Release 中找不到 $vcAsset，请先在仓库 Releases 上传该文件" }
    $tmp = Join-Path $env:TEMP $vcAsset
    Write-Host "  下载 $vcAsset (约 18MB)..."
    Invoke-WebRequest $asset.browser_download_url -OutFile $tmp
    Write-Host '  静默安装（如弹出 UAC 请点"是"）...'
    $p = Start-Process -FilePath $tmp -ArgumentList '/install', '/quiet', '/norestart' -Verb RunAs -Wait -PassThru
    Remove-Item $tmp -Force -ErrorAction SilentlyContinue
    # 0=成功  3010=成功需重启  1638=已存在更高版本
    if ($p.ExitCode -notin @(0, 3010, 1638)) { throw "VC++ 运行库安装失败（退出码 $($p.ExitCode)）" }
    Write-Host '  [OK] VC++ 运行库安装完成' -ForegroundColor Green
}

# ---------- [2/3] 微软商店获取最新 ChatGPT 包 ----------
Write-Host ''
Write-Host '[2/3] 从微软商店获取最新 ChatGPT 包（winget msstore 官方源）...' -ForegroundColor Yellow
$existing = Get-AppxPackage -Name $pkgName -ErrorAction SilentlyContinue
if ($existing) {
    Write-Host "  本机已装版本 $($existing.Version)，将更新到商店最新版"
}
winget install --id $storeId --source msstore --accept-package-agreements --accept-source-agreements --disable-interactivity
# 0=成功；-1978335189 = msstore 源"无可用升级"（本机已是最新），同样视为成功
if ($LASTEXITCODE -notin @(0, -1978335189)) { throw "winget 安装失败（退出码 $LASTEXITCODE）" }
if ($LASTEXITCODE -eq -1978335189) { Write-Host '  [OK] 本机已是最新版本，无需更新' -ForegroundColor Green }

# ---------- [3/3] 验证 ----------
Write-Host ''
Write-Host '[3/3] 验证安装...' -ForegroundColor Yellow
$pkg = Get-AppxPackage -Name $pkgName -ErrorAction SilentlyContinue
if ($pkg) {
    Write-Host "  [OK] $($pkg.Name) 版本 $($pkg.Version) 已安装" -ForegroundColor Green
} else {
    Write-Host '  [!] 未检测到已安装的包，请到"开始菜单"或 Microsoft Store 检查' -ForegroundColor Yellow
}

Write-Host ''
Write-Host '============================================' -ForegroundColor Cyan
Write-Host '  流程完成' -ForegroundColor Cyan
Write-Host '============================================' -ForegroundColor Cyan
