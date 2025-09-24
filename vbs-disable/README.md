# VBS Disable Tools

Automated tools to disable Virtualization Based Security (VBS) on Windows 11 23H2+ and restore VirtualBox/VMware hardware acceleration.

## Problem Description

Starting with Windows 11 23H2, Microsoft automatically enables Virtualization Based Security (VBS) and Device Guard by default. This causes performance issues with virtualization software:

- **VirtualBox**: Green turtle icon appears in VM status bar, indicating lack of hardware acceleration
- **VMware**: Significantly slower performance due to inability to use hardware virtualization features
- **Performance Impact**: VMs run in software emulation mode instead of using CPU virtualization extensions

## Quick Start

### Automated Solution (Recommended)

1. **Run PowerShell as Administrator**
2. **Install the automated VBS disabling:**
   ```powershell
   .\install_vbs_disable_task.ps1
   ```
3. **Restart your computer**

This creates a scheduled task that automatically disables VBS on every boot, handling Windows updates that re-enable it.

### Manual Solution

If you prefer to run Microsoft's tool directly:

1. **Download the DG Readiness Tool:**
   - Visit: https://www.microsoft.com/en-us/download/details.aspx?id=53337
   - Or direct download: https://download.microsoft.com/download/b/d/8/bd821b1f-05f2-4a7e-aa03-df6c4f687b07/dgreadiness_v3.6.zip

2. **Extract the downloaded zip file** to a folder (e.g., `C:\Tools\DGReadiness`)

3. **Run PowerShell as Administrator**

4. **Disable VBS using Microsoft's tool:**
   ```powershell
   C:\Tools\DGReadiness\dgreadiness_v3.6\DG_Readiness_Tool_v3.6.ps1 -Disable
   ```

5. **Restart your computer**

## Scripts Included

- **`install_vbs_disable_task.ps1`** - Downloads Microsoft DG tool and creates scheduled task
- **`vbs_disable_task.ps1`** - Core script that disables VBS using Microsoft's official tool
- **`remove_vbs_disable_task.ps1`** - Removes the scheduled task

## How to Check VBS Status

**Easy Method:**
1. Press `Win + R`, type `msinfo32` and press Enter
2. Look for "Virtualization-based security" in the system summary
3. If it shows "Running" - VBS is enabled and will cause slow virtualization
4. If it shows "Not enabled" - VBS is disabled and virtualization will work normally

## What These Tools Do

The scripts use Microsoft's official Device Guard and Credential Guard hardware readiness tool to:
- Remove VBS-related registry keys
- Disable Hyper-V hypervisor via DISM
- Remove Device Guard policies
- Clean up Credential Guard configuration

## Important Notes

- **Administrator privileges required** for all operations
- **Restart required** after VBS changes
- **Windows Updates** may re-enable VBS (automated task handles this)
- **Security Impact**: Disabling VBS reduces some security features but improves virtualization performance

## Troubleshooting

### VBS Keeps Re-enabling
If VBS re-enables after Windows updates, it may be due to:
- Group Policy enforcement
- Enterprise management policies
- Windows Update resetting configuration

**Solution**: Use the automated task (`install_vbs_disable_task.ps1`) which runs on every boot.

### Error Messages During Disable
Registry error messages like "unable to find specified registry key" are normal - they indicate the keys were already removed or never existed.

### VirtualBox Still Shows Green Turtle
1. Verify VBS is disabled using `msinfo32`
2. Completely restart VirtualBox
3. If issues persist, try disabling Hyper-V manually:
   ```powershell
   bcdedit /set hypervisorlaunchtype off
   ```

## Removal

To remove the automated VBS disabling:
```powershell
.\remove_vbs_disable_task.ps1
```

## References

- [Microsoft DG Readiness Tool](https://www.microsoft.com/en-us/download/details.aspx?id=53337)
- [Windows VBS Documentation](https://docs.microsoft.com/en-us/windows/security/threat-protection/device-guard/)