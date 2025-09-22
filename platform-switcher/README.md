# WSL2 Platform Switcher

Scripts to easily switch between WSL2 and VirtualBox development environments.

## Quick Start

**Check current status:**
```cmd
switch-platform.bat
```

**Switch to WSL2 mode:**
```cmd
switch-platform.bat wsl2
```

**Switch to VirtualBox mode:**
```cmd
switch-platform.bat virtualbox
```

## Important Notes

**WARNING: WSL2 and VirtualBox cannot run simultaneously** due to Hyper-V conflicts.

- **WSL2 mode**: Enables Hyper-V, disables VirtualBox
- **VirtualBox mode**: Disables Hyper-V, enables VirtualBox

**System restart is required** when switching between modes.

## Available Scripts

### `switch-platform.bat`
Easy-to-use batch wrapper for the PowerShell scripts.

### `switch-platform.ps1`
Main PowerShell script with full functionality:
```powershell
# Check status
.\switch-platform.ps1

# Switch platforms
.\switch-platform.ps1 wsl2
.\switch-platform.ps1 virtualbox

# Advanced options
.\switch-platform.ps1 wsl2 -Force
```

### Individual Scripts
- `check-wsl2-status.ps1` - Detailed status check
- `enable-wsl2.ps1` - Enable WSL2 mode only
- `disable-wsl2.ps1` - Disable WSL2 mode only

## Usage Examples

**Developer workflow:**
1. Check current mode: `switch-platform.bat`
2. Switch to desired platform: `switch-platform.bat wsl2`
3. Restart when prompted
4. Verify: `switch-platform.bat`

**VirtualBox to WSL2:**
```cmd
switch-platform.bat wsl2
# Restart system
wsl --install Ubuntu-22.04
```

**WSL2 to VirtualBox:**
```cmd
switch-platform.bat virtualbox
# Restart system
cd vm && vagrant up
```

## Troubleshooting

**"Access denied" error**: Run as Administrator
**VirtualBox not working**: Check if Hyper-V is disabled
**WSL2 not working**: Check if Hyper-V and VM Platform are enabled

For detailed diagnostics: `.\check-wsl2-status.ps1`