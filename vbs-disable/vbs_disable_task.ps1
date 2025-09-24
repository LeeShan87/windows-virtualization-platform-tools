$logFile = "C:\Tools\DGReadiness\vbs_disable.log"
$installPath = "C:\Tools\DGReadiness"

function Write-Log($message) {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - $message" | Out-File -FilePath $logFile -Append
    Write-Host $message
}

Write-Log "=== VBS Disable Script Started ==="

# Find DG Readiness Tool
try {
    $dgScript = Get-ChildItem -Path $installPath -Name "DG_Readiness_Tool_v3.6.ps1" -Recurse | Select-Object -First 1

    if (!$dgScript) {
        Write-Log "ERROR: Could not find DG_Readiness_Tool_v3.6.ps1 in $installPath"
        exit 1
    }

    $dgScriptPath = Join-Path $installPath $dgScript
    Write-Log "Found DG tool at: $dgScriptPath"

    # Run the DG Readiness Tool to disable VBS
    Write-Log "Running DG tool with -Disable flag..."

    Set-Location $installPath

    # Just run the tool normally - let it output to console naturally
    & $dgScriptPath -Disable

    # Log that we ran it
    Write-Log "DG tool execution completed"
    Write-Log "DG Tool exit code: $LASTEXITCODE"

    if ($LASTEXITCODE -eq 0) {
        Write-Log "DG tool completed successfully"
    } else {
        Write-Log "DG tool completed with exit code: $LASTEXITCODE"
    }

} catch {
    Write-Log "ERROR running DG Readiness Tool: $($_.Exception.Message)"
    exit 1
}

Write-Log "=== VBS Disable Script Completed ==="