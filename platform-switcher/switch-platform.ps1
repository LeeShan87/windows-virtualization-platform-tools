# Platform Switcher - Toggle between WSL2 and VirtualBox modes
# This script helps switch between development platforms

param(
    [Parameter(Position=0)]
    [ValidateSet("wsl2", "virtualbox", "vbox", "check", "status", "help", "-help", "--help", "/?", "-?")]
    [string]$Platform = "check",

    [switch]$Force,
    [switch]$NoRestart
)

$ErrorActionPreference = "Stop"

function Show-Usage {
    Write-Host "=== DevEnv Platform Switcher ===" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Usage: .\switch-platform.ps1 [PLATFORM] [OPTIONS]" -ForegroundColor White
    Write-Host ""
    Write-Host "PLATFORMS:" -ForegroundColor Yellow
    Write-Host "  wsl2        - Enable WSL2 mode (disables VirtualBox)"
    Write-Host "  virtualbox  - Enable VirtualBox mode (disables WSL2)"
    Write-Host "  vbox        - Alias for virtualbox"
    Write-Host "  check       - Check current platform status (default)"
    Write-Host "  status      - Alias for check"
    Write-Host ""
    Write-Host "OPTIONS:" -ForegroundColor Yellow
    Write-Host "  -Force      - Skip confirmation prompts"
    Write-Host "  -NoRestart  - Don't automatically restart after changes"
    Write-Host ""
    Write-Host "EXAMPLES:" -ForegroundColor Green
    Write-Host "  .\switch-platform.ps1                 # Check current status"
    Write-Host "  .\switch-platform.ps1 wsl2            # Switch to WSL2 mode"
    Write-Host "  .\switch-platform.ps1 virtualbox      # Switch to VirtualBox mode"
    Write-Host "  .\switch-platform.ps1 vbox -Force     # Force switch to VirtualBox"
    Write-Host ""
}

function Get-CurrentPlatformStatus {
    Write-Host "=== Current Platform Status ===" -ForegroundColor Cyan

    # Check if running as Administrator
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")

    if (-not $isAdmin) {
        Write-Host "Note: Running without Administrator privileges - some checks may be limited" -ForegroundColor Yellow
        Write-Host ""
    }

    # Check features
    $hyperV = $null
    $vmPlatform = $null
    $wslFeature = $null

    if ($isAdmin) {
        $hyperV = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All -ErrorAction SilentlyContinue
        $vmPlatform = Get-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -ErrorAction SilentlyContinue
        $wslFeature = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -ErrorAction SilentlyContinue
    }

    # Determine current mode
    $currentMode = "Unknown"
    $modeColor = "Gray"

    if ($hyperV -and $hyperV.State -eq "Enabled") {
        $currentMode = "WSL2 Mode"
        $modeColor = "Green"
    } elseif ($hyperV -and $hyperV.State -eq "Disabled") {
        $currentMode = "VirtualBox Mode"
        $modeColor = "Blue"
    } elseif (-not $isAdmin) {
        $currentMode = "Unknown (requires admin to check)"
        $modeColor = "Yellow"
    } else {
        $currentMode = "Neither WSL2 nor VirtualBox mode detected"
        $modeColor = "Gray"
    }

    Write-Host "Current Mode: " -NoNewline
    Write-Host $currentMode -ForegroundColor $modeColor
    Write-Host ""

    if ($isAdmin) {
        # Detailed status
        Write-Host "Windows Features:" -ForegroundColor Yellow
        if ($hyperV) {
            $color = if ($hyperV.State -eq "Enabled") { "Red" } else { "Green" }
            Write-Host "  Hyper-V: $($hyperV.State)" -ForegroundColor $color
        }
        if ($vmPlatform) {
            $color = if ($vmPlatform.State -eq "Enabled") { "Yellow" } else { "Gray" }
            Write-Host "  Virtual Machine Platform: $($vmPlatform.State)" -ForegroundColor $color
        }
        if ($wslFeature) {
            $color = if ($wslFeature.State -eq "Enabled") { "Green" } else { "Gray" }
            Write-Host "  Windows Subsystem for Linux: $($wslFeature.State)" -ForegroundColor $color
        }
        Write-Host ""
    }

    # Check WSL2 availability
    try {
        $wslStatus = wsl --status 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "WSL2 Status: Available and working" -ForegroundColor Green
        } else {
            Write-Host "WSL2 Status: Not available" -ForegroundColor Gray
        }
    } catch {
        Write-Host "WSL2 Status: Not installed" -ForegroundColor Gray
    }

    # Check VirtualBox availability
    $vboxPaths = @(
        "${env:ProgramFiles}\Oracle\VirtualBox\VBoxManage.exe",
        "${env:ProgramFiles(x86)}\Oracle\VirtualBox\VBoxManage.exe",
        "${env:ProgramW6432}\Oracle\VirtualBox\VBoxManage.exe"
    )

    $vboxFound = $false
    $vboxPath = $null

    # First try PATH
    try {
        $vboxPath = Get-Command "VBoxManage" -ErrorAction SilentlyContinue
        if ($vboxPath) {
            $vboxFound = $true
        }
    } catch { }

    # If not in PATH, try common installation paths
    if (-not $vboxFound) {
        foreach ($path in $vboxPaths) {
            if (Test-Path $path) {
                $vboxPath = $path
                $vboxFound = $true
                break
            }
        }
    }

    if ($vboxFound) {
        try {
            if ($vboxPath.GetType().Name -eq "String") {
                & $vboxPath list vms 2>$null | Out-Null
            } else {
                & $vboxPath.Source list vms 2>$null | Out-Null
            }

            if ($LASTEXITCODE -eq 0) {
                Write-Host "VirtualBox Status: Available and working" -ForegroundColor Green
            } else {
                Write-Host "VirtualBox Status: Installed but not working (likely Hyper-V conflict)" -ForegroundColor Red
            }
        } catch {
            Write-Host "VirtualBox Status: Installed but not working (likely Hyper-V conflict)" -ForegroundColor Red
        }
    } else {
        Write-Host "VirtualBox Status: Not installed" -ForegroundColor Gray
    }

    return $currentMode
}

# Main logic
try {
    # Handle help requests
    if ($Platform -in @("help", "-help", "--help", "/?", "-?")) {
        Show-Usage
        exit 0
    }

    # Handle platform parameter
    if ($Platform -in @("check", "status")) {
        Get-CurrentPlatformStatus
        exit 0
    }

    if ($Platform -eq "vbox") {
        $Platform = "virtualbox"
    }

    # Check admin privileges for switching
    if ($Platform -in @("wsl2", "virtualbox")) {
        $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
        if (-not $isAdmin) {
            Write-Host "ERROR: Administrator privileges required for platform switching" -ForegroundColor Red
            Write-Host "Please run PowerShell as Administrator and try again" -ForegroundColor Yellow
            exit 1
        }
    }

    # Show current status first
    $currentMode = Get-CurrentPlatformStatus
    Write-Host ""

    # Execute platform switch
    switch ($Platform) {
        "wsl2" {
            Write-Host "=== Switching to WSL2 Mode ===" -ForegroundColor Cyan
            if ($currentMode -match "WSL2") {
                Write-Host "Already in WSL2 mode!" -ForegroundColor Green
            } else {
                $scriptPath = Join-Path $PSScriptRoot "enable-wsl2.ps1"
                $params = @()
                if ($Force) { $params += "-Force" }
                if ($NoRestart) { $params += "-NoRestart" }

                & $scriptPath @params
            }
        }

        "virtualbox" {
            Write-Host "=== Switching to VirtualBox Mode ===" -ForegroundColor Cyan
            if ($currentMode -match "VirtualBox") {
                Write-Host "Already in VirtualBox mode!" -ForegroundColor Green
            } else {
                $scriptPath = Join-Path $PSScriptRoot "disable-wsl2.ps1"
                $params = @()
                if ($Force) { $params += "-Force" }
                if ($NoRestart) { $params += "-NoRestart" }

                & $scriptPath @params
            }
        }

        default {
            Show-Usage
            exit 1
        }
    }

} catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}