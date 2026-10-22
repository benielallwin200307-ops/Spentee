@echo off
setlocal enabledelayedexpansion

echo ===================================================
echo     Spentee AI Secure Proxy - Service Launcher
echo ===================================================
echo.

set "SCRIPT_DIR=%~dp0"
if exist "%SCRIPT_DIR%backend\server.js" (
    cd /d "%SCRIPT_DIR%backend"
) else if exist "%SCRIPT_DIR%server.js" (
    cd /d "%SCRIPT_DIR%"
) else (
    echo [ERROR] Could not locate backend/server.js.
    exit /b 1
)

:: 1. Verify Node.js is installed
where node >nul 2>nul
if errorlevel 1 (
    echo [ERROR] Node.js was not found in PATH.
    echo Please install Node.js from https://nodejs.org/
    pause
    exit /b 1
)

:: 2. Check if .env file exists
if not exist ".env" (
    if exist ".env.example" (
        echo [WARN] .env not found. Creating from .env.example...
        copy /y ".env.example" ".env" >nul
        echo [INFO] Please edit backend\.env and insert your GEMINI_API_KEY.
    ) else (
        echo [WARN] No .env file found in backend directory.
    )
)

:: 3. Check if port 3000 is already active
set "PORT_IN_USE=0"
netstat -ano | findstr /C:":3000 " | findstr /I "LISTENING" >nul 2>nul
if not errorlevel 1 (
    set "PORT_IN_USE=1"
    echo [INFO] Port 3000 is currently listening. Verifying service health...
)

:: 4. Start backend if not already listening
if "!PORT_IN_USE!"=="0" (
    echo [INFO] Starting Spentee AI backend proxy on port 3000...
    start "Spentee-AI-Backend" node server.js
    echo [INFO] Waiting for service to initialize...
)

:: 5. Poll health endpoint up to 8 seconds
set "ATTEMPT=0"
:poll_loop
set /a ATTEMPT+=1
node check_health.js >nul 2>nul
if not errorlevel 1 goto :health_ready
if !ATTEMPT! geq 8 goto :health_failed
timeout /t 1 /nobreak >nul 2>nul
goto :poll_loop

:health_failed
echo.
echo [ERROR] Backend health check failed on http://localhost:3000/health
echo Please verify port 3000 is not blocked and check the Spentee AI Backend console window.
echo.
exit /b 1

:health_ready
:: 6. Configure ADB reverse port forwarding for attached Android devices/emulators
set "ADB_PATH=%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe"
if not exist "!ADB_PATH!" (
    where adb >nul 2>nul
    if not errorlevel 1 set "ADB_PATH=adb"
)

if defined ADB_PATH (
    "!ADB_PATH!" devices 2>nul | findstr /V "List of devices" | findstr /R "[a-zA-Z0-9]" >nul 2>nul
    if not errorlevel 1 (
        "!ADB_PATH!" reverse tcp:3000 tcp:3000 >nul 2>nul
        if not errorlevel 1 (
            echo [OK] ADB reverse port forwarding active: tcp:3000 to tcp:3000
        )
    )
)

:: 7. Output detailed service diagnostic summary
echo.
echo ===================================================
echo  SUCCESS: Spentee AI Backend is Online and Healthy!
echo ===================================================
echo   - Local Host URL:        http://localhost:3000
echo   - Android Emulator URL:  http://10.0.2.2:3000
echo   - Physical Device (USB): http://localhost:3000 (via ADB reverse)
echo   - Health Check:          http://localhost:3000/health [200 OK]
node check_health.js --summary
echo ===================================================
echo.
