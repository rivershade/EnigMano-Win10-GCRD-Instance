# ============================================================
# ENIGMANO: MINIMAL GCRD + AUDIO DEPLOYMENT
# Only: Chrome Remote Desktop + VB-CABLE Audio
# All Node.js, VS Code, Brave, Persona removed
# ============================================================

param(
    [Parameter(Mandatory)] [string]$Code,
    [string]$Pin = "123456",
    [string]$Retries = "3"
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

function Timestamp { (Get-Date).ToString("yyyy-MM-dd HH:mm:ss") }
function Log($msg)  { Write-Host "[ENIGMANO $(Timestamp)] $msg" }
function Fail($msg) { Write-Error "[ENIGMANO-ERROR $(Timestamp)] $msg"; Exit 1 }

# Boot banner
$now = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
Write-Host @"
------------------------------------------------------------
                ENIGMANO // GCRD + AUDIO
------------------------------------------------------------
  STATUS    : Initializing
  TIME      : $now
  ARCHITECT : https://www.youtube.com/@ShahzaibYT-itxsb
  PROFILE   : Minimal Remote Desktop (Sound Enabled)
------------------------------------------------------------
"@

# Input validation
if (-not $Code) { Fail "Missing -Code parameter." }
if ($Code.Trim().Length -lt 10) { Fail "Invalid CODE: too short." }
if ($Pin.Length -lt 6) { $Pin = "123456" }
try { [int]$Retries = [int]$Retries } catch { $Retries = 3 }

Log "Input: Code=***, PIN=$Pin, Retries=$Retries"

# ============================================================
# 1. VB-AUDIO (Sound in RDP)
# ============================================================
try {
    Log "VB-Audio Virtual Cable (~120s)"
    Invoke-WebRequest "https://gitlab.com/Shahzaib-YT/enigmano-win10-gcrd-instance/-/raw/main/VB-Audio.ps1" -OutFile "VB-Audio.ps1" -TimeoutSec 120
    & .\VB-Audio.ps1
    Log "Audio - Virtual cable installed."
} catch { Fail "Audio failed: $($_.Exception.Message)" }

# ============================================================
# 2. GOOGLE CRD SETUP
# ============================================================
try {
    Log "Google CRD Setup (~120s)"
    Invoke-WebRequest "https://gitlab.com/Shahzaib-YT/enigmano-win10-gcrd-instance/-/raw/main/GCRD-setup.ps1" -OutFile "GCRD-setup.ps1" -TimeoutSec 120
    & .\GCRD-setup.ps1 -Code $Code -Pin $Pin -Retries $Retries
    Log "GCRD - Remote access ready."
} catch { Fail "GCRD failed: $($_.Exception.Message)" }

# ============================================================
# 3. DATA FOLDER (Optional)
# ============================================================
try {
    $desktop = [Environment]::GetFolderPath("Desktop")
    $dataPath = Join-Path $desktop "Data"
    if (-not (Test-Path $dataPath)) {
        New-Item -Path $dataPath -ItemType Directory | Out-Null
        Log "Vault - Created at $dataPath"
    } else {
        Log "Vault - Already exists."
    }
} catch { Log "Vault skipped: $($_.Exception.Message)" }

# ============================================================
# 4. EXECUTION WINDOW (335 minutes)
# ============================================================
$totalMinutes = 335
$startTime = Get-Date
$endTime = $startTime.AddMinutes($totalMinutes)

function ClampMinutes([TimeSpan]$ts) {
    $mins = [math]::Round($ts.TotalMinutes, 1)
    if ($mins -lt 0) { return 0 }
    return $mins
}

Log "Sustain mode: ${totalMinutes} minutes."

while ((Get-Date) -lt $endTime) {
    $now = Get-Date
    $elapsed = [math]::Round(($now - $startTime).TotalMinutes, 1)
    $remaining = ClampMinutes ($endTime - $now)
    Log "Uptime: ${elapsed}m | Remaining: ${remaining}m"
    Start-Sleep -Seconds (Get-Random -Minimum 300 -Maximum 800)
}

Log "Mission complete."

# ============================================================
# 5. TERMINATION
# ============================================================
Log "Shutting down..."
if ($env:RUNNER_ENV -eq "self-hosted") {
    Stop-Computer -Force
} else {
    Log "Hosted runner: exiting."
    Exit 0
}
