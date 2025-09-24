#Requires -RunAsAdministrator

param(
    [string]$InstallPath = "C:\Tools\DGReadiness",
    [string]$DownloadUrl = "https://download.microsoft.com/download/b/d/8/bd821b1f-05f2-4a7e-aa03-df6c4f687b07/dgreadiness_v3.6.zip"
)

Write-Host "VBS Disable Task Installer" -ForegroundColor Green

if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Error "This script must be run as Administrator."
    exit 1
}

# Create installation directory
if (!(Test-Path $InstallPath)) {
    New-Item -ItemType Directory -Path $InstallPath -Force | Out-Null
}

# Download DG Readiness Tool
$zipPath = Join-Path $InstallPath "dgreadiness_v3.6.zip"
Write-Host "Downloading DG Readiness Tool..."

try {
    Invoke-WebRequest -Uri $DownloadUrl -OutFile $zipPath -UseBasicParsing
    Write-Host "Download completed" -ForegroundColor Green
} catch {
    Write-Error "Failed to download: $($_.Exception.Message)"
    exit 1
}

# Extract
try {
    Expand-Archive -Path $zipPath -DestinationPath $InstallPath -Force
    Remove-Item $zipPath -Force
    Write-Host "Extraction completed" -ForegroundColor Green
} catch {
    Write-Error "Failed to extract: $($_.Exception.Message)"
    exit 1
}

# Copy the VBS disable script to install path
$checkerSource = Join-Path $PSScriptRoot "vbs_disable_task.ps1"
$checkerDest = Join-Path $InstallPath "vbs_disable_task.ps1"

if (Test-Path $checkerSource) {
    Copy-Item $checkerSource $checkerDest -Force
    Write-Host "Copied VBS disable script" -ForegroundColor Green
} else {
    Write-Error "vbs_disable_task.ps1 not found in script directory"
    exit 1
}

# Create the scheduled task
$taskName = "DisableVBSOnStartup"
Write-Host "Creating scheduled task: $taskName"

# Remove existing task if it exists
$existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
if ($existingTask) {
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
}

# Create new task
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File `"$checkerDest`""
$trigger = New-ScheduledTaskTrigger -AtStartup
$trigger.Delay = "PT2M"
$principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -RunLevel Highest
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

try {
    Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Description "Smart VBS disabler with reboot loop prevention"
    Write-Host "Task created successfully!" -ForegroundColor Green
} catch {
    Write-Error "Failed to create task: $($_.Exception.Message)"
    exit 1
}

Write-Host "Installation completed!" -ForegroundColor Green