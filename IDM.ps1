[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole("Administrators")) {
    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

$WorkRoot = "$env:TEMP\IDMLauncher"
New-Item -ItemType Directory -Force -Path $WorkRoot | Out-Null

$IDMURL = "https://mirror2.internetdownloadmanager.com/idman642build42.exe"
$IDMInstaller = "$WorkRoot\IDM_Setup.exe"
Invoke-WebRequest -Uri $IDMURL -OutFile $IDMInstaller -UseBasicParsing

Start-Process -FilePath $IDMInstaller
