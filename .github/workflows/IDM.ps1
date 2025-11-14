# Enforce TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Relaunch as Admin if needed
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole("Administrators")) {
    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# Temp workspace
$WorkRoot = "$env:TEMP\IDMLauncher"
New-Item -ItemType Directory -Force -Path $WorkRoot | Out-Null

# Download IDM
$IDMURL = "https://mirror2.internetdownloadmanager.com/idman642build42.exe"
$IDMInstaller = "$WorkRoot\IDM_Setup.exe"
Invoke-WebRequest -Uri $IDMURL -OutFile $IDMInstaller -UseBasicParsing

# Launch installer
Start-Process -FilePath $IDMInstaller

# Optional: Remove-Item $WorkRoot -Recurse -Force
