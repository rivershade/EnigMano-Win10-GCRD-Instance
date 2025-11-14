[CmdletBinding()]
param(
  [string]$Code,
  [string]$Pin,
  [int]$Retries = 3
)
$ErrorActionPreference = 'Stop'
function Timestamp { (Get-Date).ToString('yyyy-MM-dd_HH-mm-ss') }
function Log([string]$msg) { Write-Host "[$(Timestamp)] $msg" }
function Fail([string]$msg) { Write-Error "[$(Timestamp)] $msg"; exit 1 }
function Mask([string]$s) {
  if ([string]::IsNullOrWhiteSpace($s)) { return }
  try { if ($env:GITHUB_ACTIONS -eq 'true') { Write-Host "::add-mask::$s" } } catch {}
}
function Extract-HeadlessToken([string]$raw) {
  if ([string]::IsNullOrWhiteSpace($raw)) { return $null }
  if ($raw -match '--code\s*=\s*"([^"]+)"') { return $Matches[1] }
  if ($raw -match "--code\s*=\s*'([^']+)'") { return $Matches[1] }
  if ($raw -match '--code\s*=\s*([^\s"''\)]+)') { return $Matches[1] }
  if ($raw -match '4\/[A-Za-z0-9_\-\.\~]+') { return $Matches[0] }
  return $null
}
function Escape-Arg([string]$s) {
  if ($null -eq $s) { return "" }
  return $s -replace '"','\"'
}
if (-not $Code) { $Code = $env:RAW_CODE }
if (-not $Pin) { $Pin = $env:PIN_INPUT }
if ($PSBoundParameters.Keys -notcontains 'Retries' -and $env:RETRIES_INPUT) {
  try { if ([int]$env:RETRIES_INPUT -gt 0) { $Retries = [int]$env:RETRIES_INPUT } } catch {}
}
Mask $Code
Mask $Pin
if (-not $Code) { Fail "Missing Code. Provide -Code or set RAW_CODE." }
$token = Extract-HeadlessToken $Code
if (-not $token) { Fail "No valid 4/... token found in Code." }
$token = $token.Trim('"').Trim("'").Trim()
Mask $token
if ($Pin) { $Pin = $Pin.Trim() }
if ([string]::IsNullOrWhiteSpace($Pin) -or ($Pin -notmatch '^\d{6,}$')) {
  $Pin = "123456"
} else {
  Log "PIN accepted."
}
Mask $Pin
$timestamp = Get-Date -Format 'yyyy-MM-dd_HH-mm-ss'
$display = "Windows Server 2022 $timestamp"
$oldEAP = $ErrorActionPreference
$ErrorActionPreference = 'Continue'
foreach ($h in @("remotedesktop-pa.googleapis.com","oauth2.googleapis.com","remotedesktop.google.com")) {
  try {
    $ok = Test-NetConnection -ComputerName $h -Port 443 -WarningAction SilentlyContinue
    Write-Host "$h : $(if ($ok.TcpTestSucceeded) { 'reachable' } else { 'unreachable' })"
  } catch { Write-Host "$h : error" }
}
$ErrorActionPreference = $oldEAP
function Get-DownloadsPath {
  $p = Join-Path $env:USERPROFILE 'Downloads'
  if (Test-Path $p) { return $p }
  $p = Join-Path $HOME 'Downloads'
  if (Test-Path $p) { return $p }
  try {
    $shell = New-Object -ComObject Shell.Application
    $p = Join-Path ([Environment]::GetFolderPath('UserProfile')) 'Downloads'
    if (Test-Path $p) { return $p }
  } catch {}
  Fail "Downloads folder not found."
}
$downloads = Get-DownloadsPath
$expected = Join-Path $downloads 'crdhost.msi'
$msiPath = $null
if (Test-Path -LiteralPath $expected) {
  $msiPath = $expected
} else {
  $candidate = Get-ChildItem -Path $downloads -Filter *.msi -File -ErrorAction SilentlyContinue |
               Where-Object { $_.Name -match '(?i)(chrome|crd).*remote.*desktop|chromeremotedesktop' } |
               Sort-Object LastWriteTime -Descending | Select-Object -First 1
  if ($candidate) { $msiPath = $candidate.FullName }
}
if (-not $msiPath) { Fail "No CRD MSI found in Downloads. Place crdhost.msi there." }
try {
  $size = (Get-Item $msiPath).Length
  if ($size -le 0) { Fail "MSI file is empty." }
  $sig = Get-AuthenticodeSignature -FilePath $msiPath
  if ($sig.Status -ne 'Valid') { Log "Signature: $($sig.Status)" } else { Log "Signed: $($sig.SignerCertificate.Subject)" }
} catch { Fail "Failed to verify MSI: $_" }
$logPath = Join-Path $env:TEMP "CRD_install_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
$installArgs = "/i `"$msiPath`" /qn /norestart /L*v `"$logPath`""
$proc = Start-Process msiexec.exe -ArgumentList $installArgs -Wait -PassThru -ErrorAction Stop
if ($proc.ExitCode -ne 0) {
  $repArgs = "/fvomus `"$msiPath`" /qn /norestart /L*v `"$logPath`""
  $rep = Start-Process msiexec.exe -ArgumentList $repArgs -Wait -PassThru -ErrorAction Stop
  if ($rep.ExitCode -ne 0) { Fail "Install failed (code $($rep.ExitCode)). Log: $logPath" }
}
Log "Installed. Log: $logPath"
$candidates = @()
if (${env:ProgramFiles(x86)}) { $candidates += Join-Path ${env:ProgramFiles(x86)} 'Google\Chrome Remote Desktop\CurrentVersion\remoting_start_host.exe' }
if (${env:ProgramFiles}) { $candidates += Join-Path ${env:ProgramFiles} 'Google\Chrome Remote Desktop\CurrentVersion\remoting_start_host.exe' }
$found = $candidates | Where-Object { Test-Path -LiteralPath $_ }
if (-not $found) {
  $roots = @()
  if (${env:ProgramFiles(x86)}) { $roots += Join-Path ${env:ProgramFiles(x86)} 'Google\Chrome Remote Desktop' }
  if (${env:ProgramFiles}) { $roots += Join-Path ${env:ProgramFiles} 'Google\Chrome Remote Desktop' }
  $found = Get-ChildItem -Path $roots -Filter 'remoting_start_host.exe' -Recurse -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName
}
if (-not $found) { Fail "remoting_start_host.exe not found." }
$exePath = $found | Sort-Object Length | Select-Object -First 1
Log "Host executable: $exePath"
$hostJson = Join-Path $env:ProgramData 'Google\Chrome Remote Desktop\host.json'
if (Test-Path -LiteralPath $hostJson) {
  Log "Already registered. Skipping."
  exit 0
}
Mask $token
Mask $Pin
$codeEsc = Escape-Arg $token
$displayEsc = Escape-Arg $display
$pinEsc = Escape-Arg $Pin
$args = "--code=`"$codeEsc`" --redirect-url=`"https://remotedesktop.google.com/_/oauthredirect`" --display-name=`"$displayEsc`" --pin=`"$pinEsc`" --disable-crash-reporting"
$Attempts = [Math]::Max(1, $Retries)
$success = $false
for ($i = 1; $i -le $Attempts; $i++) {
  Log "Registration attempt $i/$Attempts"
  try {
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $exePath
    $psi.Arguments = $args
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
    $p = [System.Diagnostics.Process]::Start($psi)
    $stdout = $p.StandardOutput.ReadToEnd()
    $stderr = $p.StandardError.ReadToEnd()
    $p.WaitForExit()
    Write-Host "ExitCode: $($p.ExitCode)"
    if ($p.ExitCode -eq 0) {
      $success = $true
      Log "Registered successfully on attempt $i"
      break
    }
    if ($stderr -match 'authorization_code|OAuth error|invalid_grant') {
      Log "Token invalid or expired. Aborting."
      break
    }
    $sleep = 5 * ($i * $i)
    Log "Retrying in $sleep seconds..."
    Start-Sleep -Seconds $sleep
  } catch {
    Log "Error: $($_.Exception.Message)"
    if ($i -ge $Attempts) { Fail "All attempts failed." }
    $sleep = 5 * ($i * $i)
    Start-Sleep -Seconds $sleep
  }
}
if (-not $success) { Fail "Registration failed after $Attempts attempts." }
$limit = (Get-Date).AddSeconds(20)
while (-not (Test-Path $hostJson) -and (Get-Date) -lt $limit) { Start-Sleep -Milliseconds 500 }
try {
  if (Test-Path $hostJson) {
    $json = Get-Content $hostJson -Raw | ConvertFrom-Json -ErrorAction Stop
    if ($json.host_id) {
      $id = $json.host_id
      $mask = if ($id.Length -gt 6) { $id.Substring(0,3) + "..." + $id.Substring($id.Length-3) } else { $id }
      Write-Host "Host ID: $mask"
    }
  }
} catch {}
Log "Setup complete."
exit 0
