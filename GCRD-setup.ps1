<#
 EnigMano GCRD Host Automation
 Role: Fortress Commander
 Objective: Install Chrome Remote Desktop host from %USERPROFILE%\Downloads and enroll it under command.

 CI Usage:
   pwsh -ExecutionPolicy Bypass -File .\EnigMano-GCRD-Auto.ps1 -Code "$env:RAW_CODE" -Pin "$env:PIN_INPUT" -Retries "$env:RETRIES_INPUT"

 Local Usage:
   pwsh -ExecutionPolicy Bypass -File .\EnigMano-GCRD-Auto.ps1 -Code '4/xxxxxxxxxxx' -Pin '123456' -Retries 3

 Doctrine:
   - Precision over guesswork
   - Containment over chaos
   - Auditability over ambiguity
#>

[CmdletBinding()]
param(
  [string]$Code,     # Operator authorization code or headless token
  [string]$Pin,      # Enrollment PIN for CRD host
  [int]$Retries = 3  # Registration retry budget
)

$ErrorActionPreference = 'Stop'  # Fail fast to preserve integrity

# --- Utility functions ------------------------------------------------------
function Timestamp { (Get-Date).ToString('yyyy-MM-dd_HH-mm-ss') } # Deterministic clock for logs

function Log([string]$msg)  { Write-Host "[ENIGMANO $(Timestamp)] $msg" }  # EnigMano console voice
function GLog([string]$msg) { Write-Host "[GCRD $(Timestamp)] $msg" }      # GCRD-specific channel
function Fail([string]$msg) { Write-Error "[ENIGMANO-ERROR $(Timestamp)] $msg"; exit 1 } # Single fatal exit

# Mask sensitive strings for CI surfaces without altering runtime state
function Mask([string]$s) {
  if ([string]::IsNullOrWhiteSpace($s)) { return $s }
  try { if ($env:GITHUB_ACTIONS -eq 'true') { Write-Host "::add-mask::$s" } } catch {}
}

# Pull a valid headless token from flexible input formats
function Extract-HeadlessToken([string]$raw) {
  if ([string]::IsNullOrWhiteSpace($raw)) { return $null }
  if ($raw -match '--code\s*=\s*"([^"]+)"')         { return $Matches[1] }
  elseif ($raw -match "--code\s*=\s*'([^']+)'")     { return $Matches[1] }
  elseif ($raw -match '--code\s*=\s*([^\s"''\)]+)') { return $Matches[1] }
  elseif ($raw -match '4\/[A-Za-z0-9_\-\.\~]+')     { return $Matches[0] }
  return $null
}

# Escape quotes for safe command construction
function Escape-Arg([string]$s) {
  if ($null -eq $s) { return "" }
  return $s -replace '"','\"'
}

# --- Resolve Downloads folder robustly --------------------------------------
function Get-DownloadsPath {
  # Primary: USERPROFILE\Downloads
  if ($env:USERPROFILE) {
    $p = Join-Path $env:USERPROFILE 'Downloads'
    if (Test-Path $p) { return $p }
  }
  # Secondary: HOME\Downloads
  if ($HOME) {
    $p = Join-Path $HOME 'Downloads'
    if (Test-Path $p) { return $p }
  }
  # Fallback: KnownFolder via shell
  try {
    $shell = New-Object -ComObject Shell.Application
    $downloads = [Environment]::GetFolderPath('UserProfile')
    if ($downloads) {
      $p = Join-Path $downloads 'Downloads'
      if (Test-Path $p) { return $p }
    }
  } catch {}
  Fail "Downloads directory could not be resolved. Abort."
}

# --- Inputs (prefer parameters, fallback to environment) --------------------
if (-not $Code)   { $Code   = $env:RAW_CODE }
if (-not $Pin)    { $Pin    = $env:PIN_INPUT }
if ($PSBoundParameters.Keys -notcontains 'Retries' -and $env:RETRIES_INPUT) {
  try { if ([int]$env:RETRIES_INPUT -gt 0) { $Retries = [int]$env:RETRIES_INPUT } } catch {}
}

# Conceal early
Mask $Code
Mask $Pin

# --- Token parse and validation ---------------------------------------------
if (-not $Code) { Fail "Access gate: missing Code. Provide -Code or set RAW_CODE." }
$token = Extract-HeadlessToken $Code
if (-not $token) { Fail "Access gate: no 4/... headless token could be extracted from Code." }
$token = $token.Trim('"').Trim("'").Trim()
Mask $token

# --- PIN normalization (>= 6 digits). Safe default if invalid/missing -------
if ($Pin) { $Pin = $Pin.Trim() }
if ([string]::IsNullOrWhiteSpace($Pin) -or ($Pin -notmatch '^\d{6,}$')) {
  $Pin = "123456"
  GLog "PIN policy: input missing or invalid; assigning controlled default (hidden)."
} else {
  GLog "PIN policy: input accepted (hidden)."
}
Mask $Pin

# --- Derived identity --------------------------------------------------------
$timestamp = Get-Date -Format 'yyyy-MM-dd_HH-mm-ss'
$display   = "EnigMano $timestamp"

# --- Network probes (non-fatal) ---------------------------------------------
$oldEAP = $ErrorActionPreference
$ErrorActionPreference = 'Continue'
foreach ($h in @("remotedesktop-pa.googleapis.com","oauth2.googleapis.com","remotedesktop.google.com")) {
  try {
    $ok = Test-NetConnection -ComputerName $h -Port 443 -WarningAction SilentlyContinue
    $status = if ($ok.TcpTestSucceeded) { "netprobe 443 reachable" } else { "netprobe cannot reach 443" }
    Write-Host "$h : $status"
  } catch {
    Write-Host "$h : netprobe error : $($_.Exception.Message)"
  }
}
$ErrorActionPreference = $oldEAP

# ============================================================================
# INSTALL VECTOR: %USERPROFILE%\Downloads\crdhost.msi
# Purpose: Land the CRD host silently with signature check and logs.
# Also emits explicit installation status logs: success/failure.
# ============================================================================
$downloads = Get-DownloadsPath
GLog "Staging area: $downloads"

# Expected installer name
$expected = Join-Path $downloads 'crdhost.msi'

# Select MSI payload
$msiPath = $null
if (Test-Path -LiteralPath $expected) {
  $msiPath = $expected
  GLog "Installer: expected payload located -> $(Split-Path $msiPath -Leaf)"
} else {
  GLog "Installer: expected payload not found; scanning for Chrome Remote Desktop MSI candidates"
  $candidate = Get-ChildItem -Path $downloads -Filter *.msi -File -ErrorAction SilentlyContinue |
               Where-Object { $_.Name -match '(?i)(chrome|crd).*remote.*desktop|chromeremotedesktop' } |
               Sort-Object LastWriteTime -Descending |
               Select-Object -First 1
  if ($candidate) {
    $msiPath = $candidate.FullName
    GLog "Installer: selected candidate -> $(Split-Path $msiPath -Leaf)"
  }
}

# Enforce presence
if (-not $msiPath) { 
  GLog "Install: status=failure reason=no_msi_found path=$downloads"
  Fail "Installer: no suitable MSI found in $downloads. Place crdhost.msi and re-run."
}

# Integrity and signer posture
try {
  $size = (Get-Item $msiPath).Length
  if ($size -le 0) { 
    GLog "Install: status=failure reason=empty_payload file=$msiPath"
    Fail "Installer: payload appears empty -> $msiPath" 
  }
  $sig = Get-AuthenticodeSignature -FilePath $msiPath
  if ($sig.Status -ne 'Valid') {
    GLog "Signer: signature status '$($sig.Status)'; proceed only if source is trusted."
  } else {
    GLog "Signer: certificate accepted -> $($sig.SignerCertificate.Subject)"
  }
  GLog "Payload: size $size bytes"
} catch {
  GLog "Install: status=failure reason=verify_error file=$msiPath"
  Fail "Installer: read/verify failure for '$msiPath'. $_"
}

# Silent install with repair fallback
try {
  GLog "Install: initiating silent deployment"
  $logPath = Join-Path $env:TEMP "CRD_install_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
  $installArgs = "/i `"$msiPath`" /qn /norestart /L*v `"$logPath`""
  $proc = Start-Process msiexec.exe -ArgumentList $installArgs -Wait -PassThru
  if ($proc.ExitCode -ne 0) {
    GLog "Install: initial failure code=$($proc.ExitCode); entering repair path"
    $repArgs = "/fvomus `"$msiPath`" /qn /norestart /L*v `"$logPath`""
    $rep = Start-Process msiexec.exe -ArgumentList $repArgs -Wait -PassThru
    if ($rep.ExitCode -ne 0) { 
      GLog "Install: status=failure code=$($rep.ExitCode) log=$logPath"
      GLog "Install: see log -> $logPath"
      Fail "Install: repair failed with code $($rep.ExitCode)"
    }
  }
  GLog "Install: status=success log=$logPath"
} catch {
  GLog "Install: status=failure reason=msi_execution_error message=$($_.Exception.Message)"
  Fail "Install: MSI execution error. $($_.Exception.Message)"
}

# --- Locate remoting_start_host.exe -----------------------------------------
GLog "Locator: searching for remoting_start_host.exe"
$pf86 = ${env:ProgramFiles(x86)}
$pf64 = ${env:ProgramFiles}
$candidates = @()
if ($pf86) { $candidates += (Join-Path $pf86 'Google\Chrome Remote Desktop\CurrentVersion\remoting_start_host.exe') }
if ($pf64) { $candidates += (Join-Path $pf64 'Google\Chrome Remote Desktop\CurrentVersion\remoting_start_host.exe') }
$found = $candidates | Where-Object { Test-Path -LiteralPath $_ }

# Fallback recursive search if direct paths fail
if (-not $found -or $found.Count -eq 0) {
  $roots = @()
  if ($pf86) { $roots += (Join-Path $pf86 'Google\Chrome Remote Desktop') }
  if ($pf64) { $roots += (Join-Path $pf64 'Google\Chrome Remote Desktop') }
  if ($roots.Count -gt 0) {
    $found = Get-ChildItem -Path $roots -Filter 'remoting_start_host.exe' -Recurse -ErrorAction SilentlyContinue |
             Select-Object -ExpandProperty FullName
  }
}
if (-not $found -or $found.Count -eq 0) { Fail "Locator: remoting_start_host.exe not found." }

$exePath = ($found | Sort-Object Length | Select-Object -First 1)
GLog "Locator: using -> $exePath"

# --- Skip registration if already present -----------------------------------
$baseCRD   = Join-Path $env:ProgramData 'Google\Chrome Remote Desktop'
$hostJson  = Join-Path $baseCRD 'host.json'
$hostUn    = Join-Path $baseCRD 'host_unprivileged.json'
$already   = Test-Path -LiteralPath $hostJson

if ($already) {
  GLog "Enroll: existing host.json detected; registration skipped by policy"
  exit 0
}

# --- Registration output filter ---------------------------------------------
function Show-FilteredStderr {
  param([string]$stderr, [int]$exitCode)
  # Quiet the benign noise when success; show all when failure.
  if ([string]::IsNullOrWhiteSpace($stderr)) { Write-Host "---- STDERR ---- (empty)"; return }
  $lines = $stderr -split "`r?`n"
  if ($exitCode -eq 0) {
    $filtered = $lines | Where-Object { ($_ -notmatch 'INFO:') -and ($_ -notmatch '^\s*$') }
    if ($filtered.Count -gt 0) { Write-Host "---- STDERR (filtered) ----"; $filtered | ForEach-Object { Write-Host $_ } }
    else { Write-Host "---- STDERR ---- (only benign INFO lines suppressed)" }
  } else {
    Write-Host "---- STDERR ----"; $lines | ForEach-Object { Write-Host $_ }
  }
}

# Reinforce secrecy before execution
Mask $token
Mask $Pin

# Prepare registration command line
$codeEsc    = Escape-Arg $token
$displayEsc = Escape-Arg $display
$pinEsc     = Escape-Arg $Pin
$redirectUrl = "https://remotedesktop.google.com/_/oauthredirect"

$args = @(
  "--code=`"$codeEsc`"",
  "--redirect-url=`"$redirectUrl`"",
  "--display-name=`"$displayEsc`"",
  "--pin=`"$pinEsc`"",
  "--disable-crash-reporting"
) -join ' '

# --- Registration loop with controlled backoff ------------------------------
$Attempts = [math]::Max(1, $Retries)
$success = $false

for ($i = 1; $i -le $Attempts; $i++) {
  Log "Attempt: begin index=$i of $Attempts"
  try {
    # Launch registration
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $exePath
    $psi.Arguments = $args
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError  = $true
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true

    $p = [System.Diagnostics.Process]::Start($psi)
    if (-not $p) { throw "process launch refused" }

    # Gather output
    $stdout = $p.StandardOutput.ReadToEnd()
    $stderr = $p.StandardError.ReadToEnd()
    $p.WaitForExit()

    Write-Host "---- STDOUT ----"
    if ([string]::IsNullOrWhiteSpace($stdout)) { Write-Host "(empty)" } else { Write-Host $stdout }

    Show-FilteredStderr -stderr $stderr -exitCode $p.ExitCode
    Write-Host "ExitCode: $($p.ExitCode)"

    if ($p.ExitCode -eq 0) {
      Log "Attempt: status=success index=$i code=0"
      $success = $true
      break
    } else {
      Log "Attempt: status=failure index=$i code=$($p.ExitCode)"
    }

    # Do not retry when the token is clearly invalid or expired
    if ($stderr -match 'Failed to exchange the authorization_code' -or
        $stderr -match 'OAuth error' -or
        $stderr -match 'invalid_grant') {
      Log "Attempt: terminal_failure reason=oauth_exchange index=$i"
      break
    }

    # Exponential backoff
    $sleep = [int](5 * ($i * $i))
    Log "Attempt: retry_scheduled in ${sleep}s index=$i"
    Start-Sleep -Seconds $sleep
  } catch {
    $err = $_.Exception.Message
    Log "Attempt: status=failure index=$i exception=$err"
    if ($i -ge $Attempts) { 
      Fail "Enroll: all attempts exhausted. Last error: $err" 
    }
    $sleep = [int](5 * ($i * $i))
    Log "Attempt: retry_scheduled in ${sleep}s index=$i"
    Start-Sleep -Seconds $sleep
  }
}

# Fail after all retries
if (-not $success) { 
  Log "Attempt: summary status=failure total=$Attempts"
  Fail "Enroll: remoting_start_host.exe did not return success after $Attempts attempt(s)." 
}

# --- Host confirmation with masked identity ---------------------------------
$limit = (Get-Date).AddSeconds(20)
while (-not (Test-Path -LiteralPath $hostJson) -and (Get-Date) -lt $limit) { Start-Sleep -Milliseconds 500 }
while (-not (Test-Path -LiteralPath $hostUn)   -and (Get-Date) -lt $limit) { Start-Sleep -Milliseconds 500 }

# Attempt to surface masked host_id for audit
try {
  if (Test-Path -LiteralPath $hostJson) {
    $rawJSON = Get-Content -LiteralPath $hostJson -Raw -ErrorAction Stop
    try {
      $j = $rawJSON | ConvertFrom-Json -ErrorAction Stop
      if ($j.host_id) {
        $id = [string]$j.host_id
        $mask = if ($id.Length -gt 6) { $id.Substring(0,3) + "..." + $id.Substring($id.Length-3) } else { $id }
        Write-Host ("Enroll: registered host_id -> {0}" -f $mask)
      } else {
        Write-Host "Enroll: host.json present; host_id not populated yet"
      }
    } catch {
      Write-Host "Enroll: host.json present but not yet valid JSON"
    }
  } else {
    Write-Host "Enroll: host.json not present yet"
  }
} catch {
  Write-Host "Enroll: host.json read skipped due to error -> $($_.Exception.Message)"
}

# --- Mission complete -------------------------------------------------------
Log "Install: summary status=success"  # explicit installation summary (success already guaranteed here)
Log "Attempt: summary status=success total=$Attempts"
Log "Enroll: completed successfully"
exit 0
