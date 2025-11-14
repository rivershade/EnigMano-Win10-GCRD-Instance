$ErrorActionPreference = "Stop"

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole("Administrators")) {
    Write-Error "Run as Administrator."; exit 1
}

$chromePath = @(
    "$env:ProgramFiles\Google\Chrome\Application\chrome.exe",
    "$env:ProgramFiles(x86)\Google\Chrome\Application\chrome.exe"
) | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $chromePath) { Write-Error "Chrome not found."; exit 1 }

$policyRoot = "HKLM:\SOFTWARE\Policies\Google\Chrome\ExtensionSettings"
New-Item -Path $policyRoot -Force | Out-Null

$updateUrl = "https://clients2.google.com/service/update2/crx"
$extensions = @(
    "ddkjiahejlhfcafbddmgiahcphecmpfh", # uBlock Origin Lite
    "mnjggcdmjocbbbhaepdhchncahnbgone"  # SponsorBlock for YouTube - Skip Sponsorships
)

foreach ($id in $extensions) {
    $json = @{ installation_mode = "normal_installed"; update_url = $updateUrl } | ConvertTo-Json -Compress
    New-ItemProperty -Path $policyRoot -Name $id -Value $json -PropertyType String -Force | Out-Null
}

New-ItemProperty -Path $policyRoot -Name "*" -Value '{"installation_mode":"allowed"}' -PropertyType String -Force | Out-Null

Write-Host "SUCCESS: 2 extensions force-installed."
Write-Host "- uBlock Origin Lite"
Write-Host "- SponsorBlock for YouTube - Skip Sponsorships"
Write-Host "Extensions will install on next Chrome launch."
