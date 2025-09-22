# WSL2 Status Checker
# Checks if WSL2 is enabled and VirtualBox compatibility status

Write-Host "=== WSL2 & VirtualBox Status Check ===" -ForegroundColor Cyan

# Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
if (-not $isAdmin) {
    Write-Host "WARNING: Not running as Administrator. Some checks may be limited." -ForegroundColor Yellow
}

# Check WSL2 status
Write-Host "`n1. WSL2 Status:" -ForegroundColor Green
try {
    $wslStatus = wsl --status 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "WSL2 is installed and available" -ForegroundColor Green
        Write-Host $wslStatus

        # List installed distributions
        $distros = wsl -l -v 2>$null
        if ($distros) {
            Write-Host "`nInstalled distributions:" -ForegroundColor Yellow
            Write-Host $distros
        }
    } else {
        Write-Host "WSL2 is not properly installed or enabled" -ForegroundColor Red
    }
} catch {
    Write-Host "WSL2 is not installed" -ForegroundColor Red
}

# Check Hyper-V status (affects VirtualBox)
Write-Host "`n2. Hyper-V Status:" -ForegroundColor Green
if ($isAdmin) {
    $hyperV = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All -ErrorAction SilentlyContinue
    if ($hyperV) {
        if ($hyperV.State -eq "Enabled") {
            Write-Host "Hyper-V is ENABLED (VirtualBox may not work properly)" -ForegroundColor Red
        } else {
            Write-Host "Hyper-V is DISABLED (VirtualBox should work)" -ForegroundColor Green
        }
    } else {
        Write-Host "Could not check Hyper-V status" -ForegroundColor Yellow
    }

    # Check Virtual Machine Platform
    $vmPlatform = Get-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -ErrorAction SilentlyContinue
    if ($vmPlatform) {
        Write-Host "Virtual Machine Platform: $($vmPlatform.State)" -ForegroundColor $(if ($vmPlatform.State -eq "Enabled") { "Yellow" } else { "Gray" })
    }

    # Check Windows Subsystem for Linux
    $wslFeature = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -ErrorAction SilentlyContinue
    if ($wslFeature) {
        Write-Host "Windows Subsystem for Linux: $($wslFeature.State)" -ForegroundColor $(if ($wslFeature.State -eq "Enabled") { "Green" } else { "Gray" })
    }
} else {
    Write-Host "Run as Administrator to check Windows features" -ForegroundColor Yellow
}

# Check VirtualBox status
Write-Host "`n3. VirtualBox Status:" -ForegroundColor Green

# Common VirtualBox installation paths
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
    Write-Host "VirtualBox is installed at: $($vboxPath)" -ForegroundColor Green

    # Try to list VMs to test if VirtualBox is working
    try {
        if ($vboxPath.GetType().Name -eq "String") {
            $vms = & $vboxPath list vms 2>$null
        } else {
            $vms = & $vboxPath.Source list vms 2>$null
        }

        if ($LASTEXITCODE -eq 0) {
            Write-Host "VirtualBox is working properly" -ForegroundColor Green
            if ($vms) {
                Write-Host "Available VMs:"
                Write-Host $vms -ForegroundColor Gray
            } else {
                Write-Host "No VMs found" -ForegroundColor Gray
            }
        } else {
            Write-Host "VirtualBox may not be working (likely due to Hyper-V conflict)" -ForegroundColor Red
        }
    } catch {
        Write-Host "VirtualBox may not be working (likely due to Hyper-V conflict)" -ForegroundColor Red
    }
} else {
    Write-Host "VirtualBox is not installed or not found in common locations" -ForegroundColor Yellow
}

# Recommendations
Write-Host "`n=== Recommendations ===" -ForegroundColor Cyan
$hyperVEnabled = $false
if ($isAdmin -and $hyperV -and $hyperV.State -eq "Enabled") {
    $hyperVEnabled = $true
}

if ($hyperVEnabled) {
    Write-Host " Hyper-V is enabled - WSL2 will work, but VirtualBox may have issues" -ForegroundColor Yellow
    Write-Host " Use 'disable-wsl2.ps1' to switch to VirtualBox mode" -ForegroundColor Yellow
} else {
    Write-Host " Hyper-V is disabled - VirtualBox should work properly" -ForegroundColor Green
    Write-Host " Use 'enable-wsl2.ps1' to switch to WSL2 mode" -ForegroundColor Green
}

Write-Host "`nNote: Switching between modes requires a system restart" -ForegroundColor Cyan