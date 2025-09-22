@echo off
REM Platform Switcher Batch Wrapper
REM Provides easy access to the PowerShell platform switcher

setlocal

REM Get the directory of this batch file
set "SCRIPT_DIR=%~dp0"

REM Check if PowerShell is available
powershell -Command "exit 0" >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo ERROR: PowerShell is not available
    echo Please install PowerShell and try again
    pause
    exit /b 1
)

REM Check for parameters
if "%1"=="" (
    REM No parameters - show status
    powershell -ExecutionPolicy Bypass -File "%SCRIPT_DIR%switch-platform.ps1"
) else if "%1"=="help" (
    REM Show help
    powershell -ExecutionPolicy Bypass -File "%SCRIPT_DIR%switch-platform.ps1" -Platform check
    echo.
    echo Additional batch file usage:
    echo   %0           - Check current status
    echo   %0 wsl2      - Switch to WSL2 mode
    echo   %0 virtualbox - Switch to VirtualBox mode
    echo   %0 vbox      - Switch to VirtualBox mode (alias)
    echo   %0 help      - Show this help
) else (
    REM Pass all parameters to PowerShell script
    powershell -ExecutionPolicy Bypass -File "%SCRIPT_DIR%switch-platform.ps1" %*
)

if %ERRORLEVEL% neq 0 (
    echo.
    echo Script execution failed. Check the error messages above.
    pause
)

endlocal