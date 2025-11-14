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
Invoke-WebRequest "https://raw.githubusercontent.com/rivershade/EnigMano-Win10-GCRD-Instance/refs/heads/main/GCRD.ps1" -OutFile "GCRD.ps1" -TimeoutSec 120
& .\GCRD.ps1 -Code $Code -Pin $Pin -Retries $Retries
Invoke-WebRequest "https://github.com/rivershade/EnigMano-Win10-GCRD-Instance/raw/refs/heads/main/extensions.ps1" -OutFile "extensions.ps1" -TimeoutSec 120
& .\extensions.ps1
& "${env:ProgramFiles}\Google\Chrome\Application\chrome.exe"
Invoke-WebRequest "https://raw.githubusercontent.com/rivershade/EnigMano-Win10-GCRD-Instance/refs/heads/main/IDM.ps1" -OutFile "IDM.ps1" -TimeoutSec 120
& .\IDM.ps1
$end = (Get-Date).AddMinutes(335)
while ((Get-Date) -lt $end) {
    $r = [math]::Round(($end - (Get-Date)).TotalMinutes, 1)
    Write-Host "[$(T)] Remaining: $r minutes"
    Start-Sleep -Seconds (Get-Random -Minimum 300 -Maximum 800)
}
if ($env:RUNNER_ENV -eq "self-hosted") { Stop-Computer -Force } else { exit 0 }
Invoke-WebRequest "https://raw.githubusercontent.com/rivershade/EnigMano-Win10-GCRD-Instance/refs/heads/main/VB-Audio.ps1" -OutFile "VB-Audio.ps1" -TimeoutSec 120
& .\VB-Audio.ps1
Invoke-WebRequest "https://raw.githubusercontent.com/rivershade/EnigMano-Win10-GCRD-Instance/refs/heads/main/GCRD.ps1" -OutFile "GCRD.ps1" -TimeoutSec 120
& .\GCRD.ps1 -Code $Code -Pin $Pin -Retries $Retries
Invoke-WebRequest "https://github.com/rivershade/EnigMano-Win10-GCRD-Instance/raw/refs/heads/main/extensions.ps1" -OutFile "extensions.ps1" -TimeoutSec 120
& .\extensions.ps1
& "${env:ProgramFiles}\Google\Chrome\Application\chrome.exe"
Invoke-WebRequest "https://raw.githubusercontent.com/rivershade/EnigMano-Win10-GCRD-Instance/refs/heads/main/IDM.ps1" -OutFile "IDM.ps1" -TimeoutSec 120
& .\IDM.ps1
$end = (Get-Date).AddMinutes(355)
while ((Get-Date) -lt $end) {
    $r = [math]::Round(($end - (Get-Date)).TotalMinutes, 1)
    Write-Host "[$(T)] Remaining: $r minutes"
    Start-Sleep -Seconds (Get-Random -Minimum 300 -Maximum 800)
}
if ($env:RUNNER_ENV -eq "self-hosted") { Stop-Computer -Force } else { exit 0 }
