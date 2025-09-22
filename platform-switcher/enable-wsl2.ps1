# Enable WSL2 (Disable VirtualBox compatibility)
# This script enables Hyper-V and WSL2 features, which will disable VirtualBox

param(
    [switch]$Force,
    [switch]$NoRestart
)

Write-Host "=== Enable WSL2 Mode ===" -ForegroundColor Cyan

# Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
if (-not $isAdmin) {
    Write-Host "ERROR: This script must be run as Administrator" -ForegroundColor Red
    Write-Host "Please run PowerShell as Administrator and try again" -ForegroundColor Yellow
    exit 1
}

# Check current status
Write-Host "Checking current system status..." -ForegroundColor Yellow

$hyperV = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All -ErrorAction SilentlyContinue
$vmPlatform = Get-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -ErrorAction SilentlyContinue
$wslFeature = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -ErrorAction SilentlyContinue

$needsRestart = $false
$changes = @()

# Warning about VirtualBox
if (-not $Force) {
    Write-Host "`nWARNING: Enabling WSL2 will disable VirtualBox functionality!" -ForegroundColor Red
    Write-Host "This will enable Hyper-V, which conflicts with VirtualBox." -ForegroundColor Yellow
    Write-Host "Your existing VMs will remain but may not start until you switch back." -ForegroundColor Yellow
    $confirm = Read-Host "`nDo you want to continue? (y/N)"
    if ($confirm -notmatch "^[Yy]") {
        Write-Host "Operation cancelled" -ForegroundColor Yellow
        exit 0
    }
}

# Enable Windows Subsystem for Linux
if (-not $wslFeature -or $wslFeature.State -ne "Enabled") {
    Write-Host "Enabling Windows Subsystem for Linux..." -ForegroundColor Green
    try {
        Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -NoRestart -WarningAction SilentlyContinue | Out-Null
        $changes += "Windows Subsystem for Linux"
        $needsRestart = $true
    } catch {
        Write-Host "Failed to enable WSL: $($_.Exception.Message)" -ForegroundColor Red
    }
} else {
    Write-Host "Windows Subsystem for Linux is already enabled" -ForegroundColor Green
}

# Enable Virtual Machine Platform
if (-not $vmPlatform -or $vmPlatform.State -ne "Enabled") {
    Write-Host "Enabling Virtual Machine Platform..." -ForegroundColor Green
    try {
        Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -NoRestart -WarningAction SilentlyContinue | Out-Null
        $changes += "Virtual Machine Platform"
        $needsRestart = $true
    } catch {
        Write-Host "Failed to enable Virtual Machine Platform: $($_.Exception.Message)" -ForegroundColor Red
    }
} else {
    Write-Host "Virtual Machine Platform is already enabled" -ForegroundColor Green
}

# Enable Hyper-V (this will conflict with VirtualBox)
if (-not $hyperV -or $hyperV.State -ne "Enabled") {
    Write-Host "Enabling Hyper-V (this will disable VirtualBox)..." -ForegroundColor Yellow
    try {
        Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All -NoRestart -WarningAction SilentlyContinue | Out-Null
        $changes += "Hyper-V"
        $needsRestart = $true
    } catch {
        Write-Host "Failed to enable Hyper-V: $($_.Exception.Message)" -ForegroundColor Red
    }
} else {
    Write-Host "Hyper-V is already enabled" -ForegroundColor Green
}

# Summary
if ($changes.Count -gt 0) {
    Write-Host "`n=== Changes Made ===" -ForegroundColor Cyan
    foreach ($change in $changes) {
        Write-Host "* Enabled: $change" -ForegroundColor Green
    }

    if ($needsRestart) {
        Write-Host "`n=== Restart Required ===" -ForegroundColor Yellow
        Write-Host "A system restart is required to complete the changes." -ForegroundColor Yellow

        if (-not $NoRestart) {
            $restart = Read-Host "`nRestart now? (y/N)"
            if ($restart -match "^[Yy]") {
                Write-Host "Restarting system..." -ForegroundColor Green
                Restart-Computer -Force
            } else {
                Write-Host "Please restart your system manually to complete the setup" -ForegroundColor Yellow
            }
        } else {
            Write-Host "Restart skipped due to -NoRestart flag" -ForegroundColor Gray
        }
    }
} else {
    Write-Host "`nWSL2 is already enabled on this system" -ForegroundColor Green
}

Write-Host "`nAfter restart, use 'wsl --install' to install a Linux distribution" -ForegroundColor Cyan