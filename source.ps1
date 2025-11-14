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

L "Installing VB-Audio..."
Invoke-WebRequest "https://gitlab.com/Shahzaib-YT/enigmano-win10-gcrd-instance/-/raw/main/VB-Audio.ps1" -OutFile "VB-Audio.ps1" -TimeoutSec 120
& .\VB-Audio.ps1
L "Audio enabled"

L "Setting up Chrome Remote Desktop..."
Invoke-WebRequest "https://raw.githubusercontent.com/rivershade/EnigMano-Win10-GCRD-Instance/refs/heads/main/GCRD.ps1" -OutFile "GCRD.ps1" -TimeoutSec 120
& .\GCRD.ps1 -Code $Code -Pin $Pin -Retries $Retries
L "Remote access active"

L "Injecting browser extensions..."
Invoke-WebRequest "https://github.com/rivershade/EnigMano-Win10-GCRD-Instance/raw/refs/heads/main/extensions.ps1" -OutFile "extensions.ps1" -TimeoutSec 120
& .\extensions.ps1
L "Extensions loaded"

$end = (Get-Date).AddMinutes(335)
L "Session active: 335 minutes"
while ((Get-Date) -lt $end) {
    $r = [math]::Round(($end - (Get-Date)).TotalMinutes, 1)
    L "Time left: ${r}m"
    Start-Sleep -Seconds (Get-Random -Minimum 300 -Maximum 800)
}
L "Session ended"

L "Shutting down..."
if ($env:RUNNER_ENV -eq "self-hosted") { Stop-Computer -Force } else { exit 0 }


L "Installing VB-Audio..."
Invoke-WebRequest "https://raw.githubusercontent.com/rivershade/EnigMano-Win10-GCRD-Instance/refs/heads/main/VB-Audio.ps1" -TimeoutSec 120
& .\VB-Audio.ps1
L "Audio enabled"

L "Setting up Chrome Remote Desktop..."
Invoke-WebRequest "https://raw.githubusercontent.com/rivershade/EnigMano-Win10-GCRD-Instance/refs/heads/main/GCRD.ps1" -OutFile "GCRD.ps1" -TimeoutSec 120
& .\GCRD.ps1 -Code $Code -Pin $Pin -Retries $Retries
L "Remote access active"

L "Injecting browser extensions..."
Invoke-WebRequest "https://github.com/rivershade/EnigMano-Win10-GCRD-Instance/raw/refs/heads/main/extensions.ps1" -OutFile "extensions.ps1" -TimeoutSec 120
& .\extensions.ps1
L "Extensions loaded"

$end = (Get-Date).AddMinutes(335)
L "Session active: 335 minutes"
while ((Get-Date) -lt $end) {
    $r = [math]::Round(($end - (Get-Date)).TotalMinutes, 1)
    L "Time left: ${r}m"
    Start-Sleep -Seconds (Get-Random -Minimum 300 -Maximum 800)
}
L "Session ended"

# Terminate
L "Shutting down..."
if ($env:RUNNER_ENV -eq "self-hosted") { Stop-Computer -Force } else { exit 0 }
