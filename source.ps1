# ============================================================
# ENIGMANO: WINDOWS 10 FORTRESS DEPLOYMENT PROTOCOL
# Role      : Fortress Commander
# Doctrine  : Precision - Containment - Auditability
# Essence   : The Hand of Mystery — silent, exact, decisive
# ============================================================

param(
    [Parameter(Mandatory)] [string]$Code,
    [string]$Pin = "123456",
    [string]$Retries = "3"
)

# ============================================================
# CORE DIRECTIVE: SYSTEM INTEGRITY LOCKDOWN
# Fail immediately on unhandled errors.
# ============================================================
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

# ============================================================
# CHRONOMARK SYNCHRONIZER
# Unified timestamps for logs.
# ============================================================
function Timestamp { (Get-Date).ToString("yyyy-MM-dd HH:mm:ss") }

# ============================================================
# TELEMETRY CONDUIT
# All messages go through EnigMano console.
# ============================================================
function Log($msg)  { Write-Host "[ENIGMANO $(Timestamp)] $msg" }

# ============================================================
# TERMINUS GATE
# Critical failure handler.
# ============================================================
function Fail($msg) { Write-Error "[ENIGMANO-ERROR $(Timestamp)] $msg"; Exit 1 }

# ============================================================
# BOOT IDENT SEQUENCE
# Declare intent and initiation.
# ============================================================
$now = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
Write-Host @"
------------------------------------------------------------
                ENIGMANO // FORTRESS ONLINE
------------------------------------------------------------
  STATUS    : Deployment matrix initializing
  TIME      : $now
  ARCHITECT : https://www.youtube.com/@ShahzaibYT-itxsb
  PROFILE   : Windows 10 Tactical Workstation (Sound-Enabled)
  DOCTRINE  : Precision - Containment - Auditability
------------------------------------------------------------
"@

# ============================================================
# INPUT VALIDATION
# ============================================================
if (-not $Code) { Fail "Missing required -Code parameter." }
if ($Code.Trim().Length -lt 10) { Fail "Invalid CODE: too short. Must be full headless command or 4/... token." }
if ($Pin.Length -lt 6) { $Pin = "123456" }
try { [int]$Retries = [int]$Retries } catch { $Retries = 3 }

Log "Input validated: Code=***, PIN=$Pin, Retries=$Retries"

# ============================================================
# PRIMARY DEPLOYMENT: SYSTEM FORGE
# Each phase is a tactical operation.
# ============================================================

try {
    Log "Node LTS (~45s)"
    Invoke-WebRequest "https://gitlab.com/Shahzaib-YT/enigmano-win10-gcrd-instance/-/raw/main/Node-LTS.ps1" -OutFile "Node-LTS.ps1" -TimeoutSec 120
    & .\Node-LTS.ps1
    Log "Node LTS - Forge completed."
} catch { Fail "Node LTS failed: $($_.Exception.Message)" }

try {
    Log "Visual Studio Code (~45s)"
    Invoke-WebRequest "https://gitlab.com/Shahzaib-YT/enigmano-win10-gcrd-instance/-/raw/main/Visual-Code.ps1" -OutFile "Visual-Code.ps1" -TimeoutSec 120
    & .\Visual-Code.ps1
    Log "Visual Studio Code - Installed."
} catch { Fail "VS Code failed: $($_.Exception.Message)" }

try {
    Log "Phase Persona - Environment (~15s)"
    Invoke-WebRequest "https://gitlab.com/Shahzaib-YT/enigmano-win10-gcrd-instance/-/raw/main/Env-Personalization.ps1" -OutFile "Env-Personalization.ps1" -TimeoutSec 120
    & .\Env-Personalization.ps1
    Log "Persona - Hardened."
} catch { Fail "Persona failed: $($_.Exception.Message)" }

try {
    Log "Brave Browser (~40s)"
    Invoke-WebRequest "https://gitlab.com/Shahzaib-YT/enigmano-win10-gcrd-instance/-/raw/main/Brave-Browser.ps1" -OutFile "Brave-Browser.ps1" -TimeoutSec 120
    & .\Brave-Browser.ps1
    Log "Brave - Operational."
} catch { Fail "Brave failed: $($_.Exception.Message)" }

try {
    Log "Browser Extensions (~25s)"
    Invoke-WebRequest "https://gitlab.com/Shahzaib-YT/enigmano-win10-gcrd-instance/-/raw/main/Browser-Extensions.ps1" -OutFile "Browser-Extensions.ps1" -TimeoutSec 120
    & .\Browser-Extensions.ps1
    Log "Extensions - Injected."
} catch { Fail "Extensions failed: $($_.Exception.Message)" }

try {
    Log "Browser Environment (~55s)"
    Invoke-WebRequest "https://gitlab.com/Shahzaib-YT/enigmano-win10-gcrd-instance/-/raw/main/Browser-Env-Setup.ps1" -OutFile "Browser-Env-Setup.ps1" -TimeoutSec 120
    & .\Browser-Env-Setup.ps1
    Log "Browser Env - Stabilized."
} catch { Fail "Browser Env failed: $($_.Exception.Message)" }

try {
    Log "VB-Audio Virtual Cable (~120s)"
    Invoke-WebRequest "https://gitlab.com/Shahzaib-YT/enigmano-win10-gcrd-instance/-/raw/main/VB-Audio.ps1" -OutFile "VB-Audio.ps1" -TimeoutSec 120
    & .\VB-Audio.ps1
    Log "Audio - Synchronized."
} catch { Fail "Audio failed: $($_.Exception.Message)" }

try {
    Log "Google CRD Setup (~120s)"
    Invoke-WebRequest "https://gitlab.com/Shahzaib-YT/enigmano-win10-gcrd-instance/-/raw/main/GCRD-setup.ps1" -OutFile "GCRD-setup.ps1" -TimeoutSec 120
    & .\GCRD-setup.ps1 -Code $Code -Pin $Pin -Retries $Retries
    Log "GCRD - Remote channel established."
} catch { Fail "GCRD failed: $($_.Exception.Message)" }

# ============================================================
# DATA VAULT
# Persistent storage on desktop.
# ============================================================
try {
    $desktopPath = [Environment]::GetFolderPath("Desktop")
    $dataFolderPath = Join-Path $desktopPath "Data"
    if (-not (Test-Path $dataFolderPath)) {
        New-Item -Path $dataFolderPath -ItemType Directory | Out-Null
        Log "Vault - Created at $dataFolderPath"
    } else {
        Log "Vault - Already exists."
    }
} catch { Fail "Vault creation failed: $($_.Exception.Message)" }

# ============================================================
# AUXILIARY SYSTEMS (Optional)
# ============================================================

try {
    Log "Cloudflare WARP (~60s)"
    Invoke-WebRequest "https://gitlab.com/Shahzaib-YT/enigmano-win10-gcrd-instance/-/raw/main/Cloudflare-WARP.ps1" -OutFile "Cloudflare-WARP.ps1" -TimeoutSec 120
    & .\Cloudflare-WARP.ps1
    Log "WARP - Edge routing active."
} catch {
    Log "WARP - Skipped (non-critical): $($_.Exception.Message)"
}

try {
    Log "Internet Download Manager (~20s)"
    Invoke-WebRequest "https://gitlab.com/Shahzaib-YT/enigmano-win10-gcrd-instance/-/raw/main/Download_Manager.ps1" -OutFile "Download_Manager.ps1" -TimeoutSec 120
    & .\Download_Manager.ps1
    Log "IDM - Ready."
} catch {
    Log "IDM - Skipped (non-critical): $($_.Exception.Message)"
}

# ============================================================
# EXECUTION WINDOW
# Keep alive for ~5h 35m with randomized pulses.
# ============================================================
$totalMinutes = 335
$startTime = Get-Date
$endTime = $startTime.AddMinutes($totalMinutes)

function ClampMinutes([TimeSpan]$ts) {
    $mins = [math]::Round($ts.TotalMinutes, 1)
    if ($mins -lt 0) { return 0 }
    return $mins
}

Log "Execution window: ${totalMinutes} minutes. Entering sustain mode."

while ((Get-Date) -lt $endTime) {
    $now = Get-Date
    $elapsed = [math]::Round(($now - $startTime).TotalMinutes, 1)
    $remaining = ClampMinutes ($endTime - $now)
    Log "Uptime: ${elapsed}m | Remaining: ${remaining}m"
    Start-Sleep -Seconds (Get-Random -Minimum 300 -Maximum 800)
}

Log "Mission duration ${totalMinutes}m achieved. Decommissioning."

# ============================================================
# TERMINATION SEQUENCE
# Graceful exit or forced shutdown.
# ============================================================
Log "Initiating final shutdown protocol."

# Only self-hosted runners can shutdown
if ($env:RUNNER_ENV -eq "self-hosted") {
    Log "Self-hosted environment detected. Forcing shutdown."
    Stop-Computer -Force
} else {
    Log "GitHub-hosted runner. Exiting gracefully."
    Exit 0
}

# ============================================================
# END OF PROTOCOL
# ============================================================
