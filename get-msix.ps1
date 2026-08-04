# get-msix.ps1
# Download the latest ChatGPT (Codex) MSIX package from the Microsoft Store CDN.
# Resolves the official download link via the store.rg-adguard.net API
# (works without cookies when a full browser User-Agent + ring=RP is sent).
#
# Usage:
#   powershell -ExecutionPolicy Bypass -File .\get-msix.ps1
#   powershell -ExecutionPolicy Bypass -File .\get-msix.ps1 -Arch arm64 -OutDir D:\downloads
#   powershell -ExecutionPolicy Bypass -File .\get-msix.ps1 -ListOnly   # print link only

param(
    [ValidateSet('x64', 'arm64')]
    [string]$Arch = 'x64',
    [string]$OutDir = (Get-Location).Path,
    [switch]$ListOnly
)

$ErrorActionPreference = 'Stop'
$productId = '9PLM9XGG6VKS'
$pkgSuffix = "_$Arch" + '__2p2nqsd0c76g0.msix'

Write-Host 'Querying Microsoft Store CDN for the latest package...'
$headers = @{
    'User-Agent'   = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36'
    'Referer'      = 'https://store.rg-adguard.net/'
    'Origin'       = 'https://store.rg-adguard.net'
    'Content-Type' = 'application/x-www-form-urlencoded'
}
$body = "type=ProductId&url=$productId&ring=RP&lang=zh-CN"
$resp = Invoke-WebRequest -Uri 'https://store.rg-adguard.net/api/GetFiles' -Method Post -Headers $headers -Body $body -UseBasicParsing
$html = $resp.Content

$pattern = '<a[^>]*href="([^"]+)"[^>]*>([^<]+\.msix)</a>'
$target = $null
foreach ($m in [regex]::Matches($html, $pattern)) {
    $text = $m.Groups[2].Value.Trim()
    if ($text -like '*BlockMap*') { continue }
    if ($text -like "*$pkgSuffix") {
        $target = @{
            Name = $text
            Url  = [System.Net.WebUtility]::HtmlDecode($m.Groups[1].Value)
        }
        break
    }
}
if (-not $target) { throw "No $Arch MSIX found in the response" }

Write-Host "Latest package: $($target.Name)"
Write-Host "URL: $($target.Url)"
if ($ListOnly) { exit 0 }

$outFile = Join-Path $OutDir $target.Name
Write-Host "Downloading to: $outFile"
Invoke-WebRequest -Uri $target.Url -OutFile $outFile -UseBasicParsing
Write-Host "Done: $outFile"
