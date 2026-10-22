<#
.SYNOPSIS
    Spentee AI Secure Proxy Launcher & Health Verifier
.DESCRIPTION
    Starts the Spentee AI Node.js backend proxy, configures ADB reverse for Android,
    and validates health status with automatic polling.
#>

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$BackendDir = Join-Path $ScriptDir "backend"
if (-not (Test-Path (Join-Path $BackendDir "server.js"))) {
    $BackendDir = $ScriptDir
}

Write-Host "===================================================" -ForegroundColor Cyan
Write-Host "    Spentee AI Secure Proxy - Service Launcher     " -ForegroundColor Cyan
Write-Host "===================================================" -ForegroundColor Cyan

# 1. Check Node.js
if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
    Write-Host "[ERROR] Node.js was not found in PATH. Install Node.js from https://nodejs.org/" -ForegroundColor Red
    exit 1
}

# 2. Check Port 3000
$portActive = Get-NetTCPConnection -LocalPort 3000 -ErrorAction SilentlyContinue
if ($portActive) {
    Write-Host "[INFO] Port 3000 is currently listening. Verifying service health..." -ForegroundColor Yellow
} else {
    Write-Host "[INFO] Starting Spentee AI backend proxy on port 3000..." -ForegroundColor Green
    Start-Process -FilePath "cmd.exe" -ArgumentList "/k", "title Spentee AI Backend Proxy && cd /d `"$BackendDir`" && node server.js" -WindowStyle Minimized
    Write-Host "[INFO] Waiting for service to initialize..." -ForegroundColor Gray
}

# 3. Poll /health endpoint up to 8 seconds
$healthOk = $false
$healthData = $null

for ($i = 1; $i -le 8; $i++) {
    try {
        $res = Invoke-RestMethod -Uri "http://localhost:3000/health" -Method Get -TimeoutSec 2 -ErrorAction Stop
        if ($res.status -eq "ok") {
            $healthOk = $true
            $healthData = $res
            break
        }
    } catch {
        Start-Sleep -Seconds 1
    }
}

if (-not $healthOk) {
    Write-Host "`n[ERROR] Health check failed on http://localhost:3000/health" -ForegroundColor Red
    Write-Host "Check the Spentee AI Backend console window for errors.`n" -ForegroundColor Red
    exit 1
}

# 4. Configure ADB reverse
$adbPath = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
if (-not (Test-Path $adbPath)) {
    $adbCmd = Get-Command adb -ErrorAction SilentlyContinue
    if ($adbCmd) { $adbPath = $adbCmd.Source } else { $adbPath = $null }
}

if ($adbPath -and (Test-Path $adbPath)) {
    $devices = & $adbPath devices 2>&1
    if ($devices -match "(?m)^\S+\s+device\b") {
        & $adbPath reverse tcp:3000 tcp:3000 2>&1 | Out-Null
        Write-Host "[OK] ADB reverse port forwarding active (tcp:3000 -> tcp:3000)." -ForegroundColor Green
    }
}

# 5. Service details
Write-Host "`n===================================================" -ForegroundColor Green
Write-Host " SUCCESS: Spentee AI Backend is Online and Healthy!" -ForegroundColor Green
Write-Host "===================================================" -ForegroundColor Green
Write-Host "  - Local Host URL:        http://localhost:3000"
Write-Host "  - Android Emulator URL:  http://10.0.2.2:3000"
Write-Host "  - Physical Device (USB): http://localhost:3000 (via ADB reverse)"
Write-Host "  - Health Check:          http://localhost:3000/health [200 OK]"
Write-Host "  - API Key Status:        $($healthData.configured ? 'Configured [OK]' : 'Unconfigured [Setup Required]')"
Write-Host "  - Active Model:          $($healthData.model)"
Write-Host "===================================================`n"
