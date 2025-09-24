#Requires -RunAsAdministrator

Write-Host "VBS Disable Task Remover" -ForegroundColor Green

if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Error "This script must be run as Administrator."
    exit 1
}

$taskName = "DisableVBSOnStartup"

# Check if task exists
$existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue

if ($existingTask) {
    Write-Host "Found scheduled task: $taskName" -ForegroundColor Yellow
    Write-Host "Task Status: $($existingTask.State)" -ForegroundColor Yellow

    try {
        Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
        Write-Host "Scheduled task removed successfully!" -ForegroundColor Green
    } catch {
        Write-Error "Failed to remove scheduled task: $($_.Exception.Message)"
        exit 1
    }
} else {
    Write-Host "No scheduled task found with name: $taskName" -ForegroundColor Yellow
}

# Optionally remove the installation directory
$installPath = "C:\Tools\DGReadiness"
if (Test-Path $installPath) {
    $remove = Read-Host "Do you want to remove the DG Readiness Tool directory ($installPath)? (y/N)"
    if ($remove -eq 'y' -or $remove -eq 'Y') {
        try {
            Remove-Item -Path $installPath -Recurse -Force
            Write-Host "Installation directory removed successfully!" -ForegroundColor Green
        } catch {
            Write-Error "Failed to remove installation directory: $($_.Exception.Message)"
        }
    }
}

Write-Host "Task removal completed!" -ForegroundColor Green