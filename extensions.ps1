# ===========================================
# EnigMano – Chrome: Install 2 Extensions Only
# ===========================================

$ErrorActionPreference = "Stop"

function Timestamp { (Get-Date).ToString("HH:mm:ss") }
function Success($m) { Write-Host "[$(Timestamp)] SUCCESS: $m" -ForegroundColor Green }
function Fail($m) { Write-Error "[$(Timestamp)] FAILED: $m"; Exit 1 }

# --- 1. Must be Administrator ---
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole("Administrators")) {
    Fail "Run as Administrator."
}

# --- 2. Find Chrome ---
$chromePath = @(
    "$env:ProgramFiles\Google\Chrome\Application\chrome.exe",
    "$env:ProgramFiles(x86)\Google\Chrome\Application\chrome.exe"
) | Where-Object { Test-Path $_ } | Select-Object -First 1

if (-not $chromePath) { Fail "Google Chrome not found." }

# --- 3. Apply Extension Policies Only ---
$policyRoot = "HKLM:\SOFTWARE\Policies\Google\Chrome\ExtensionSettings"
New-Item -Path $policyRoot -Force | Out-Null

$updateUrl = "https://clients2.google.com/service/update2/crx"
$extensions = @(
    "ddkjiahejlhfcafbddmgiahcphecmpfh",  # uBlock Origin Lite
    "mnjggcdmjocbbbhaepdhchncahnbgone"   # Sponsorblock
)

foreach ($id in $extensions) {
    $json = @{ installation_mode = "normal_installed"; update_url = $updateUrl } | ConvertTo-Json -Compress
    New-ItemProperty -Path $policyRoot -Name $id -Value $json -PropertyType String -Force | Out-Null
}

# Allow manual installation of any other extension
New-ItemProperty -Path $policyRoot -Name "*" -Value '{"installation_mode":"allowed"}' -PropertyType String -Force | Out-Null

# --- 4. Done ---
Success "2 extensions force-installed via policy:"
Success "   • uBlock Origin Lite"
Success "   • Sponsorblock"
Write-Host "`n   Extensions will auto-install next time Chrome starts." -ForegroundColor Yellow
