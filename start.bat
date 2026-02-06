@echo off
setlocal EnableDelayedExpansion

:: ============================================================
:: Open WebUI Startup Script
:: ============================================================

title Open WebUI

echo.
echo ============================================================
echo              Open WebUI Starting...
echo ============================================================
echo.

:: ------------------------------------------------------------
:: Load Configuration
:: ------------------------------------------------------------
set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

if exist "%SCRIPT_DIR%\app\config.bat" (
    call "%SCRIPT_DIR%\app\config.bat"
) else (
    set "INSTALL_DIR=%SCRIPT_DIR%"
    set "APP_DIR=%SCRIPT_DIR%\app"
    set "DATA_DIR=%SCRIPT_DIR%\data"
    set "PYTHON_DIR=%SCRIPT_DIR%\python"
    set "PYTHON_EXE=%SCRIPT_DIR%\python\python.exe"
    set "LOGS_DIR=%SCRIPT_DIR%\app\logs"
    set "OLLAMA_CMD="
)

echo [INFO] Install directory: %INSTALL_DIR%
echo [INFO] Data directory: %DATA_DIR%
echo.

if not exist "%LOGS_DIR%" mkdir "%LOGS_DIR%"
if not exist "%DATA_DIR%" mkdir "%DATA_DIR%"

:: ------------------------------------------------------------
:: Set Open WebUI Environment Variables
:: ------------------------------------------------------------
set "OFFLINE_MODE=true"
set "RAG_EMBEDDING_MODEL_AUTO_UPDATE=false"
set "RAG_RERANKING_MODEL_AUTO_UPDATE=false"
set "WHISPER_MODEL_AUTO_UPDATE=false"
set "DISABLE_UPDATE_CHECK=true"
set "ENABLE_PERSISTENT_CONFIG=False"

set "DATA_DIR=%DATA_DIR%"
set "OLLAMA_BASE_URL=http://localhost:11434"

set "RAG_EMBEDDING_ENGINE=openai"
set "RAG_EMBEDDING_MODEL=qwen3-embedding:latest"
set "RAG_OPENAI_API_BASE_URL=http://127.0.0.1:8001/v1"
set "RAG_OPENAI_API_KEY=dummy"

set "OPENAI_API_BASE_URL=http://127.0.0.1:8001/v1"
set "OPENAI_API_URL=http://127.0.0.1:8001/v1"
set "OPENAI_API_BASE=http://127.0.0.1:8001/v1"
set "OPENAI_API_KEY=dummy"

:: ------------------------------------------------------------
:: Find Ollama
:: ------------------------------------------------------------
echo [1/3] Starting Ollama service...

:: Try to find Ollama in various locations
set "OLLAMA_FOUND=0"

:: Check if OLLAMA_CMD is set and valid
if defined OLLAMA_CMD (
    if exist "!OLLAMA_CMD!" (
        set "OLLAMA_FOUND=1"
        goto :ollama_check_done
    )
)

:: Check PATH
where ollama.exe >nul 2>&1
if %errorlevel% equ 0 (
    set "OLLAMA_CMD=ollama.exe"
    set "OLLAMA_FOUND=1"
    goto :ollama_check_done
)

:: Check common install locations
if exist "%LOCALAPPDATA%\Programs\Ollama\ollama.exe" (
    set "OLLAMA_CMD=%LOCALAPPDATA%\Programs\Ollama\ollama.exe"
    set "OLLAMA_FOUND=1"
    goto :ollama_check_done
)

if exist "%USERPROFILE%\AppData\Local\Programs\Ollama\ollama.exe" (
    set "OLLAMA_CMD=%USERPROFILE%\AppData\Local\Programs\Ollama\ollama.exe"
    set "OLLAMA_FOUND=1"
    goto :ollama_check_done
)

if exist "%ProgramFiles%\Ollama\ollama.exe" (
    set "OLLAMA_CMD=%ProgramFiles%\Ollama\ollama.exe"
    set "OLLAMA_FOUND=1"
    goto :ollama_check_done
)

if exist "C:\Program Files\Ollama\ollama.exe" (
    set "OLLAMA_CMD=C:\Program Files\Ollama\ollama.exe"
    set "OLLAMA_FOUND=1"
    goto :ollama_check_done
)

:ollama_check_done

if "%OLLAMA_FOUND%"=="0" (
    echo.
    echo ============================================================
    echo  ERROR: Ollama not found!
    echo ============================================================
    echo.
    echo  Ollama is required to run Open WebUI.
    echo.
    echo  Please install Ollama manually:
    echo    1. Download from: https://ollama.com/download
    echo    2. Run the installer
    echo    3. Restart this script
    echo.
    echo ============================================================
    pause
    exit /b 1
)

echo       Ollama found: !OLLAMA_CMD!

:: ------------------------------------------------------------
:: Start Ollama Service
:: ------------------------------------------------------------
:: Check if Ollama is already running
powershell -Command "try { $r = Invoke-WebRequest -Uri 'http://localhost:11434/api/tags' -TimeoutSec 2 -UseBasicParsing; exit 0 } catch { exit 1 }" >nul 2>&1
if %errorlevel% equ 0 (
    echo       Ollama service is already running.
) else (
    echo       Starting Ollama service...
    start /b "" "!OLLAMA_CMD!" serve >"%LOGS_DIR%\ollama.log" 2>&1
    
    echo       Waiting for Ollama to start...
    set "OLLAMA_READY=0"
    for /L %%i in (1,1,30) do (
        if !OLLAMA_READY! equ 0 (
            timeout /t 1 /nobreak >nul
            powershell -Command "try { $r = Invoke-WebRequest -Uri 'http://localhost:11434/api/tags' -TimeoutSec 2 -UseBasicParsing; exit 0 } catch { exit 1 }" >nul 2>&1
            if !errorlevel! equ 0 (
                set "OLLAMA_READY=1"
                echo       Ollama service started.
            )
        )
    )
    
    if !OLLAMA_READY! equ 0 (
        echo       ERROR: Ollama failed to start!
        echo       Please check: %LOGS_DIR%\ollama.log
        pause
        exit /b 1
    )
)
echo.

:: ------------------------------------------------------------
:: Start Embedding Proxy
:: ------------------------------------------------------------
echo [2/3] Starting Embedding proxy...

netstat -ano | findstr ":8001.*LISTENING" >nul 2>&1
if %errorlevel% equ 0 (
    echo       Embedding proxy is already running (port 8001).
) else (
    pushd "%APP_DIR%"
    start /b "" "%PYTHON_EXE%" -m uvicorn embed_proxy:app --host 127.0.0.1 --port 8001 >"%LOGS_DIR%\embed-proxy.log" 2>&1
    popd
    
    echo       Waiting for Embedding proxy to start...
    set "PROXY_READY=0"
    for /L %%i in (1,1,30) do (
        if !PROXY_READY! equ 0 (
            timeout /t 1 /nobreak >nul
            netstat -ano | findstr ":8001.*LISTENING" >nul 2>&1
            if !errorlevel! equ 0 (
                set "PROXY_READY=1"
                echo       Embedding proxy started (port 8001).
            )
        )
    )
    
    if !PROXY_READY! equ 0 (
        echo       WARNING: Embedding proxy may not have started.
        echo       RAG features may not work, but chat will still function.
        echo       Check: %LOGS_DIR%\embed-proxy.log
    )
)
echo.

:: ------------------------------------------------------------
:: Start Open WebUI
:: ------------------------------------------------------------
echo [3/3] Starting Open WebUI...
echo.
echo ============================================================
echo.
echo   Open WebUI is starting...
echo.
echo   Access URL: http://localhost:8080
echo.
echo   First-time users need to register an admin account.
echo.
echo   To stop: Close this window or press Ctrl+C
echo.
echo ============================================================
echo.

cd /d "%APP_DIR%"

:: Run open-webui with embedded Python
"%PYTHON_EXE%" -m open_webui serve

:: ------------------------------------------------------------
:: Cleanup on exit
:: ------------------------------------------------------------
echo.
echo [CLEANUP] Open WebUI stopped, cleaning up background services...
call "%INSTALL_DIR%\stop.bat" --no-pause
