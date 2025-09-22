# Disable WSL2 (Enable VirtualBox compatibility)
# This script disables Hyper-V to allow VirtualBox to work properly

param(
    [switch]$Force,
    [switch]$NoRestart,
    [switch]$KeepWSL
)

Write-Host "=== Disable WSL2 Mode (Enable VirtualBox) ===" -ForegroundColor Cyan

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

# Warning about WSL2
if (-not $Force) {
    Write-Host "`nWARNING: This will disable WSL2 functionality!" -ForegroundColor Red
    Write-Host "Your WSL2 distributions will be preserved but won't run until you enable WSL2 again." -ForegroundColor Yellow
    Write-Host "This will allow VirtualBox to work properly." -ForegroundColor Green
    $confirm = Read-Host "`nDo you want to continue? (y/N)"
    if ($confirm -notmatch "^[Yy]") {
        Write-Host "Operation cancelled" -ForegroundColor Yellow
        exit 0
    }
}

# Disable Hyper-V (main conflict with VirtualBox)
if ($hyperV -and $hyperV.State -eq "Enabled") {
    Write-Host "Disabling Hyper-V (to enable VirtualBox)..." -ForegroundColor Green
    try {
        Disable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All -NoRestart -WarningAction SilentlyContinue | Out-Null
        $changes += "Hyper-V (disabled)"
        $needsRestart = $true
    } catch {
        Write-Host "Failed to disable Hyper-V: $($_.Exception.Message)" -ForegroundColor Red
    }
} else {
    Write-Host "Hyper-V is already disabled" -ForegroundColor Green
}

# Optionally keep WSL (version 1) and Virtual Machine Platform for future use
if ($KeepWSL) {
    Write-Host "Keeping WSL and Virtual Machine Platform (as requested)" -ForegroundColor Yellow
} else {
    # Disable Virtual Machine Platform
    if ($vmPlatform -and $vmPlatform.State -eq "Enabled") {
        Write-Host "Disabling Virtual Machine Platform..." -ForegroundColor Green
        try {
            Disable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -NoRestart -WarningAction SilentlyContinue | Out-Null
            $changes += "Virtual Machine Platform (disabled)"
            $needsRestart = $true
        } catch {
            Write-Host "Failed to disable Virtual Machine Platform: $($_.Exception.Message)" -ForegroundColor Red
        }
    } else {
        Write-Host "Virtual Machine Platform is already disabled" -ForegroundColor Green
    }

    # Disable Windows Subsystem for Linux
    if ($wslFeature -and $wslFeature.State -eq "Enabled") {
        Write-Host "Disabling Windows Subsystem for Linux..." -ForegroundColor Green
        try {
            Disable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -NoRestart -WarningAction SilentlyContinue | Out-Null
            $changes += "Windows Subsystem for Linux (disabled)"
            $needsRestart = $true
        } catch {
            Write-Host "Failed to disable WSL: $($_.Exception.Message)" -ForegroundColor Red
        }
    } else {
        Write-Host "Windows Subsystem for Linux is already disabled" -ForegroundColor Green
    }
}

# Summary
if ($changes.Count -gt 0) {
    Write-Host "`n=== Changes Made ===" -ForegroundColor Cyan
    foreach ($change in $changes) {
        Write-Host "* $change" -ForegroundColor Green
    }

    if ($needsRestart) {
        Write-Host "`n=== Restart Required ===" -ForegroundColor Yellow
        Write-Host "A system restart is required to complete the changes." -ForegroundColor Yellow
        Write-Host "After restart, VirtualBox should work properly." -ForegroundColor Green

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
    Write-Host "`nVirtualBox mode is already enabled on this system" -ForegroundColor Green
}

Write-Host "`nAfter restart, VirtualBox should work without conflicts" -ForegroundColor Cyan