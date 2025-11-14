$ErrorActionPreference = "Stop"

$tempRoot = "$env:TEMP\VBCABLE45"
$zipPath  = "$tempRoot\VBCABLE.zip"
$downloads = "$env:USERPROFILE\Downloads"

if (Test-Path $tempRoot) { Remove-Item -Recurse -Force $tempRoot }
New-Item -ItemType Directory -Path $tempRoot | Out-Null

$candidate = Get-Item "$downloads\VBCABLE.zip" -ErrorAction SilentlyContinue
if (!$candidate) {
    $candidate = Get-ChildItem $downloads -File -ErrorAction SilentlyContinue |
                 Where-Object { $_.Name -match '^VBCABLE.*\.zip$' } |
                 Sort-Object LastWriteTime -Descending | Select-Object -First 1
}
if (!$candidate) { throw "VBCABLE.zip not found in Downloads." }

Write-Host "Using: $($candidate.Name)"
Copy-Item $candidate.FullName $zipPath -Force

Expand-Archive -Path $zipPath -DestinationPath $tempRoot -Force

$exe = if ([Environment]::Is64BitOperatingSystem) { "VBCABLE_Setup_x64.exe" } else { "VBCABLE_Setup.exe" }
$installer = Get-ChildItem -Path $tempRoot -Recurse -Include $exe -ErrorAction Stop | Select-Object -First 1
if (!$installer) { throw "Installer not found: $exe" }

Write-Host "Running: $($installer.Name)"

Push-Location $installer.DirectoryName
$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName = $installer.FullName
$psi.Arguments = "-i -h"
$psi.Verb = "runas"
$psi.UseShellExecute = $false
$psi.CreateNoWindow = $true
$p = [System.Diagnostics.Process]::Start($psi)
$p.WaitForExit()
Pop-Location

Write-Host "Installer exit code: $($p.ExitCode)"

Start-Sleep 2
@("Audiosrv", "AudioEndpointBuilder") | ForEach-Object {
    try { Restart-Service $_ -Force -ErrorAction Stop; Write-Host "Restarted: $_" } catch {}
}
Start-Sleep 2

$device = Get-CimInstance Win32_SoundDevice | Where-Object { $_.Name -match "VB|Cable" }
if ($device) {
    Write-Host "VB-CABLE installed and detected."
} else {
    Write-Warning "VB-CABLE not detected. Reboot may be required."
}
