param(
    [Parameter(Mandatory)]$Code,
    $Pin = "123456",
    $Retries = "3"
)
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"
function T { (Get-Date).ToString("HH:mm:ss") }
function L($m) { Write-Host "[$(T)] $m" }
function F($m) { Write-Error "[$(T)] $m"; exit 1 }

if ($Code.Length -lt 10) { F "Invalid CODE" }
if ($Pin.Length -lt 6) { $Pin = "123456" }
try { [int]$Retries = $Retries } catch { $Retries = 3 }

Invoke-WebRequest "https://raw.githubusercontent.com/rivershade/EnigMano-Win10-GCRD-Instance/refs/heads/main/VB-Audio.ps1" -OutFile "VB-Audio.ps1" -TimeoutSec 120
& .\VB-Audio.ps1

Write-Host "Using: crdhost.msi"
Write-Host "Running: msiexec.exe /i crdhost.msi /qn /norestart"
Invoke-WebRequest "https://raw.githubusercontent.com/rivershade/EnigMano-Win10-GCRD-Instance/refs/heads/main/GCRD.ps1" -OutFile "GCRD.ps1" -TimeoutSec 120
& .\GCRD.ps1 -Code $Code -Pin $Pin -Retries $Retries
Write-Host "Registered: Chrome Remote Desktop"
$hostJson = "$env:ProgramData\Google\Chrome Remote Desktop\host.json"
if (Test-Path $hostJson) {
    $id = (Get-Content $hostJson -Raw | ConvertFrom-Json).host_id
    Write-Host "Host ID: $($id.Substring(0,3))...$($id.Substring($id.Length-3))"
}

Invoke-WebRequest "https://github.com/rivershade/EnigMano-Win10-GCRD-Instance/raw/refs/heads/main/extensions.ps1" -OutFile "extensions.ps1" -TimeoutSec 120
& .\extensions.ps1
Write-Host "SUCCESS: 2 extensions force-installed."
Write-Host " * uBlock Origin Lite"
Write-Host " * SponsorBlock for YouTube - Skip Sponsorships"
Write-Host "Extensions will install on next Chrome launch."

Write-Host "Launching: Google Chrome"
& "${env:ProgramFiles}\Google\Chrome\Application\chrome.exe"

Write-Host "Using: IDM installer"
Invoke-WebRequest "https://raw.githubusercontent.com/rivershade/EnigMano-Win10-GCRD-Instance/refs/heads/main/IDM.ps1" -OutFile "IDM.ps1" -TimeoutSec 120
& .\IDM.ps1
Write-Host "Installed: Internet Download Manager"

$end = (Get-Date).AddMinutes(360)
while ((Get-Date) -lt $end) {
    $r = [math]::Round(($end - (Get-Date)).TotalMinutes, 1)
    L "Remaining: $r minutes"
    Start-Sleep -Seconds (Get-Random -Minimum 300 -Maximum 800)
}
if ($env:RUNNER_ENV -eq "self-hosted") { Stop-Computer -Force } else { exit 0 }
