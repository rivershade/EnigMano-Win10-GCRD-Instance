# ============================================================
# ENIGMANO: WINDOWS 10 FORTRESS DEPLOYMENT PROTOCOL
# Role      : Fortress Commander
# Doctrine  : Precision - Containment - Auditability
# Essence   : The Hand of Mystery — silent, exact, decisive
# ============================================================

param(
    [string]$GateSecret  # Optional: pass as -GateSecret or via env:EnigMano_Access_Token
)

# ============================================================
# CORE DIRECTIVE: SYSTEM INTEGRITY LOCKDOWN
# Fail immediately on unhandled errors. No deviation. No mercy.
# ============================================================
$ErrorActionPreference = "Stop"

# ============================================================
# CHRONOMARK SYNCHRONIZER
# Generates unified timestamps for deterministic event chains.
# ============================================================
function Timestamp { (Get-Date).ToString("yyyy-MM-dd HH:mm:ss") }

# ============================================================
# TELEMETRY CONDUIT
# Each message passes through the EnigMano console matrix.
# ============================================================
function Log($msg)  { Write-Host "[ENIGMANO $(Timestamp)] $msg" }

# ============================================================
# TERMINUS GATE
# All unrecoverable faults converge here for controlled collapse.
# ============================================================
function Fail($msg) { Write-Error "[ENIGMANO-ERROR $(Timestamp)] $msg"; Exit 1 }

# ============================================================
# CRYPTIC HASH ENGINE
# SHA-256 integrity seal generator. Local-only. Untouchable.
# ============================================================
function Get-Sha256([Parameter(Mandatory)] [string]$Text) {
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($Text)
    $sha   = [System.Security.Cryptography.SHA256]::Create()
    ($sha.ComputeHash($bytes) | ForEach-Object { $_.ToString("x2") }) -join ""
}

# ============================================================
# BOOT IDENT SEQUENCE
# Declare intent, provenance, and initiation timestamp.
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
# CONTEXT SNAPSHOT
# Record non-sensitive runtime state for audit and replay.
# ============================================================
$RUNNER_ENV     = $env:RUNNER_ENV
$RAW_CODE       = $env:RAW_CODE
$PIN_INPUT      = $env:PIN_INPUT
$RETRIES_INPUT  = $env:RETRIES_INPUT

# ============================================================
# ACCESS CONTROL: GATE VERIFICATION
# Purpose : Authenticate operator through EnigMano Key Seal.
# Policy  : Token must resolve to approved cryptographic fingerprint.
# ============================================================
$GATE_SECRET = if ($PSBoundParameters.ContainsKey('GateSecret')) { $GateSecret } else { $env:EnigMano_Access_Token }

if ($GATE_SECRET) { Write-Host "::add-mask::$GATE_SECRET" }
$ExpectedSecretSHA256 = '9963bc90438cdc994401dec1010f4907ca2523eba67216f8c82ee8027b0ee230'

if (-not $GATE_SECRET -or [string]::IsNullOrWhiteSpace($GATE_SECRET)) {
    Fail "Access Gate Denied: Missing EnigMano_Access_Token. Configure repository secret and retry."
}

$actual = Get-Sha256 $GATE_SECRET
if ($actual -ne $ExpectedSecretSHA256) {
    Fail "Access Gate Denied: Token fingerprint mismatch. Lockdown enforced."
}
Log "Access Gate: Operator authentication verified and validated."

# ============================================================
# PRIMARY DEPLOYMENT: SYSTEM FORGE
# Each phase is a tactical operation. Each failure is terminal.
# ============================================================

try {
    Log "Node LTS (~45s)"
    Invoke-WebRequest "https://gitlab.com/Shahzaib-YT/enigmano-win10-gcrd-instance/-/raw/main/Node-LTS.ps1" -OutFile Node-LTS.ps1
    .\Node-LTS.ps1
    Log "Node LTS - Forge completed successfully."
} catch { Fail "Node LTS - Forge sequence failure. $_" }

try {
    Log "Visual Studio Code (~45s)"
    Invoke-WebRequest "https://gitlab.com/Shahzaib-YT/enigmano-win10-gcrd-instance/-/raw/main/Visual-Code.ps1" -OutFile Visual-Code.ps1
    .\Visual-Code.ps1
    Log "Visual Studio Code - Operator Core installed and aligned."
} catch { Fail "Visual Studio Code - Core installation failure. $_" }

try {
    Log "Phase Persona - Engaging Environment Protocols (~15s)"
    Invoke-WebRequest "https://gitlab.com/Shahzaib-YT/enigmano-win10-gcrd-instance/-/raw/main/Env-Personalization.ps1" -OutFile Env-Personalization.ps1
    .\Env-Personalization.ps1
    Log "Phase Persona - Visual and ergonomic hardening complete."
} catch { Fail "Phase Persona - Execution failure. $_" }

try {
    Log "Phase Browser-Core - Manifesting Brave Shell (~40s)"
    Invoke-WebRequest "https://gitlab.com/Shahzaib-YT/enigmano-win10-gcrd-instance/-/raw/main/Brave-Browser.ps1" -OutFile Brave-Browser.ps1
    .\Brave-Browser.ps1
    Log "Phase Browser-Core - Brave aligned and operational."
} catch { Fail "Phase Browser-Core - Operation failure. $_" }

try {
    Log "Phase Browser-Extensions - Injecting augmentation suite (~25s)"
    Invoke-WebRequest "https://gitlab.com/Shahzaib-YT/enigmano-win10-gcrd-instance/-/raw/main/Browser-Extensions.ps1" -OutFile Browser-Extensions.ps1
    .\Browser-Extensions.ps1
    Log "Phase Browser-Extensions - Augmentation sequence complete."
} catch { Fail "Phase Browser-Extensions - Failure detected. $_" }

try {
    Log "Phase Browser-Env - Establishing runtime matrix (~55s)"
    Invoke-WebRequest "https://gitlab.com/Shahzaib-YT/enigmano-win10-gcrd-instance/-/raw/main/Browser-Env-Setup.ps1" -OutFile Browser-Env-Setup.ps1
    .\Browser-Env-Setup.ps1
    Log "Phase Browser-Env - Runtime context stabilized."
} catch { Fail "Phase Browser-Env - Failure encountered. $_" }

try {
    Log "Phase Audio - Assembling virtual drivers (~120s)"
    Invoke-WebRequest "https://gitlab.com/Shahzaib-YT/enigmano-win10-gcrd-instance/-/raw/main/VB-Audio.ps1" -OutFile VB-Audio.ps1
    .\VB-Audio.ps1
    Log "Phase Audio - Sound layer secured and synchronized."
} catch { Fail "Phase Audio - Driver deployment failure. $_" }

try {
    Log "Phase GCRD - Preflight initiation (~120s)"
    Invoke-WebRequest "https://gitlab.com/Shahzaib-YT/enigmano-win10-gcrd-instance/-/raw/main/GCRD-setup.ps1" -OutFile GCRD-setup.ps1
    .\GCRD-setup.ps1
    Log "Phase GCRD - Remote command channel established."
} catch { Fail "Phase GCRD - Setup failure. $_" }

# ============================================================
# DATA VAULT
# Establishes a local artifact sanctuary. Persistent and secure.
# ============================================================
try {
    $desktopPath = [Environment]::GetFolderPath("Desktop")
    $dataFolderPath = Join-Path $desktopPath "Data"

    if (-not (Test-Path $dataFolderPath)) {
        New-Item -Path $dataFolderPath -ItemType Directory | Out-Null
        Log "Vault - Created tactical data sanctuary at $dataFolderPath"
    } else {
        Log "Vault - Existing artifact chamber detected."
    }
} catch { Fail "Vault - Creation anomaly. $_" }

# ============================================================
# SECONDARY OPERATIONS: AUXILIARY SYSTEMS
# Optional deployments for egress control and throughput mastery.
# ============================================================

try {
    Log "Phase WARP - Engaging edge routing client (~60s)"
    Invoke-WebRequest "https://gitlab.com/Shahzaib-YT/enigmano-win10-gcrd-instance/-/raw/main/Cloudflare-WARP.ps1" -OutFile Cloudflare-WARP.ps1
    .\Cloudflare-WARP.ps1
    Log "Phase WARP - Edge layer operational."
} catch { Fail "Phase WARP - Edge client failure. $_" }

try {
    Log "Phase IDM (~20s)"
    Invoke-WebRequest "https://gitlab.com/Shahzaib-YT/enigmano-win10-gcrd-instance/-/raw/main/Download_Manager.ps1" -OutFile Download_Manager.ps1
    .\Download_Manager.ps1
    Log "Phase IDM - ready."
} catch { Fail "Phase IDM - Installation failure. $_" }

# ============================================================
# EXECUTION WINDOW
# The Fortress remains awake for a fixed duration.
# Temporal stability maintained through randomized pulse cycles.
# ============================================================
$totalMinutes = 335
$startTime    = Get-Date
$endTime      = $startTime.AddMinutes($totalMinutes)

function ClampMinutes([TimeSpan]$ts) {
    $mins = [math]::Round($ts.TotalMinutes, 1)
    if ($mins -lt 0) { return 0 }
    return $mins
}

while ((Get-Date) -lt $endTime) {
    $now       = Get-Date
    $elapsed   = [math]::Round(($now - $startTime).TotalMinutes, 1)
    $remaining = ClampMinutes ($endTime - $now)
    Log "Window - Operational Uptime ${elapsed}m | Remaining ${remaining}m"
    Start-Sleep -Seconds ((Get-Random -Minimum 300 -Maximum 800))
}

Log "Window - Mission duration ${totalMinutes}m achieved. Preparing for decommission."

# ============================================================
# TERMINATION SEQUENCE
# Controlled power-down or release of command chain.
# ============================================================
Log "Decommission - Initiating final shutdown protocol."

if ($RUNNER_ENV -eq "self-hosted") {
    Stop-Computer -Force
} else {
    Log "Decommission - Hosted environment detected. Exiting gracefully."
    Exit
}
