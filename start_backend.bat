@echo off
setlocal enabledelayedexpansion

echo ===================================================
echo     Spentee AI Secure Proxy — Service Launcher
echo ===================================================
echo.

set "SCRIPT_DIR=%~dp0"
cd /d "%SCRIPT_DIR%backend" 2>nul || cd /d "%SCRIPT_DIR%"

where node >nul 2>nul
if %ERRORLEVEL% neq 0 (
    echo [ERROR] Node.js was not found in PATH. Please install Node.js.
    pause
    exit /b 1
)

:: Check if port 3000 is already listening
netstat -ano | findstr /R /C:":3000 .*LISTENING" >nul 2>nul
if %ERRORLEVEL% equ 0 (
    echo [INFO] Port 3000 is already active.
) else (
    echo [INFO] Starting Spentee AI backend proxy on port 3000...
    start "Spentee-AI-Backend" /min node server.js
    ping -n 3 127.0.0.1 >nul
)

:: Configure ADB Reverse for connected Android devices/emulators
set "ADB_PATH=%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe"
if exist "%ADB_PATH%" (
    "%ADB_PATH%" reverse tcp:3000 tcp:3000 >nul 2>nul
    if %ERRORLEVEL% equ 0 (
        echo [OK] ADB reverse port forwarding active (tcp:3000 -^> tcp:3000^).
    )
) else (
    where adb >nul 2>nul
    if %ERRORLEVEL% equ 0 (
        adb reverse tcp:3000 tcp:3000 >nul 2>nul
        if %ERRORLEVEL% equ 0 (
            echo [OK] ADB reverse port forwarding active (tcp:3000 -^> tcp:3000^).
        )
    )
)

:: Verify Health endpoint
echo [INFO] Verifying backend health...
node -e "fetch('http://localhost:3000/health').then(r => r.json()).then(d => { console.log('[OK] Health status: ' + d.status + ' | Service: ' + d.service + ' | Key configured: ' + d.configured); process.exit(0); }).catch(e => { console.log('[ERROR] Health check failed: ' + e.message); process.exit(1); })"

if errorlevel 1 (
    echo.
    echo [WARN] Backend did not respond on localhost:3000. Check logs for details.
) else (
    echo.
    echo ===================================================
    echo  SUCCESS: Spentee AI Backend is Online and Ready!
    echo   - Host URL: http://localhost:3000
    echo   - Android Emulator URL: http://10.0.2.2:3000 (and localhost:3000 via ADB)
    echo ===================================================
)

echo.
