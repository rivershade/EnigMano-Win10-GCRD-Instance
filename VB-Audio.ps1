# Run in an elevated PowerShell session (Run as Administrator)

$ErrorActionPreference = "Stop"

# Temporary workspace for extraction (same as before)
$tempRoot    = "$env:TEMP\VBCABLE45"
$zipPath     = "$tempRoot\VBCABLE.zip"

# Source location in Downloads (we removed the download step)
$downloads   = Join-Path $env:USERPROFILE "Downloads"

# ------------------------------------------------------------
# Clean up any previous workspace and recreate a fresh directory
# ------------------------------------------------------------
if (Test-Path $tempRoot) { Remove-Item -Recurse -Force $tempRoot }
New-Item -ItemType Directory -Path $tempRoot | Out-Null

# ------------------------------------------------------------
# Locate an existing VB-CABLE zip in Downloads and stage it
# Preferred name: VBCABLE.zip; fall back to common VB-Audio pack names
# ------------------------------------------------------------
$candidate = $null
$preferred = Join-Path $downloads "VBCABLE.zip"
if (Test-Path -LiteralPath $preferred) {
    $candidate = $preferred
}
else {
    $alts = Get-ChildItem -Path $downloads -File -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -match '^VBCABLE(\.zip|_Driver_Pack.*\.zip)$' } |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1
    if ($alts) { $candidate = $alts.FullName }
}

if (-not $candidate) {
    throw "Expected archive not found. Place 'VBCABLE.zip' in your Downloads folder and re-run."
}

Write-Host "Using archive: $candidate"
Copy-Item -LiteralPath $candidate -Destination $zipPath -Force

# ------------------------------------------------------------
# Extract the archive into the temporary directory
# -Force ensures existing files are overwritten if present
# ------------------------------------------------------------
Expand-Archive -Path $zipPath -DestinationPath $tempRoot -Force

# ------------------------------------------------------------
# Choose the correct installer executable based on OS architecture
# - 64-bit OS -> use x64 installer, otherwise use 32-bit installer
# - Search recursively for the expected installer filename inside the extracted files
# ------------------------------------------------------------
$is64 = [Environment]::Is64BitOperatingSystem
$exeName = if ($is64) { "VBCABLE_Setup_x64.exe" } else { "VBCABLE_Setup.exe" }
$installer = Get-ChildItem -Path $tempRoot -Recurse -Include $exeName -ErrorAction SilentlyContinue | Select-Object -First 1

# If no installer is found, fail early with an error
if (-not $installer) {
    Write-Error "Installer not found in package."
    exit 1
}

Write-Host "Installer: $($installer.FullName)"

# ------------------------------------------------------------
# Change current directory to the installer's folder so relative
# operations (if any) behave as expected. We will restore later.
# ------------------------------------------------------------
Push-Location $installer.DirectoryName

# ------------------------------------------------------------
# Prepare and start the installer process with elevated verb ("runas")
# - Arguments "-i -h" indicate install and hidden/silent mode (per VB-Audio installer)
# - Keep UseShellExecute=$false as in the previous working script
# ------------------------------------------------------------
$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName = $installer.FullName
$psi.WorkingDirectory = $installer.DirectoryName
$psi.Arguments = "-i -h"   # -i = install, -h = hide/silent (supported by VB-Audio installers)
$psi.Verb = "runas"
$psi.UseShellExecute = $false
$psi.CreateNoWindow = $true

$process = [System.Diagnostics.Process]::Start($psi)
$process.WaitForExit()
$exitCode = $process.ExitCode
Write-Host "Installer exit code: $exitCode"

# ------------------------------------------------------------
# Restore the original working directory
# ------------------------------------------------------------
Pop-Location

# ------------------------------------------------------------
# Give services a moment to settle, then attempt to restart audio services
# - Restarting audio services helps the OS pick up newly installed virtual audio devices
# - Use SilentlyContinue on errors to avoid noisy failures on systems where service names differ
# ------------------------------------------------------------
Start-Sleep -Seconds 2
try { Restart-Service -Name "Audiosrv" -Force -ErrorAction Stop; Write-Host "Restarted service: Audiosrv" } catch { Write-Verbose $_ }
try { Restart-Service -Name "AudioEndpointBuilder" -Force -ErrorAction Stop; Write-Host "Restarted service: AudioEndpointBuilder" } catch { Write-Verbose $_ }

Start-Sleep -Seconds 2

# ------------------------------------------------------------
# Quick verification: enumerate sound devices and look for VB/Cable names
# - If found, report success; otherwise warn that a reboot may be needed
#   (Avoid using .Count to prevent 'Count' property errors when a single object returns)
# ------------------------------------------------------------
$soundDevices = $null
try {
    $soundDevices = Get-CimInstance Win32_SoundDevice | Where-Object { $_.Name -match "VB|Cable" }
} catch {
    # Best-effort; do not fail the phase due to enumeration issues
}

if ($soundDevices) {
    Write-Host "Audio installed successfully."
} else {
    Write-Warning "Audio device not detected. A reboot may be required."
}
