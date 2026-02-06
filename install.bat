@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion

:: ============================================================
:: Open WebUI Windows 一键安装脚本
:: 使用内置的嵌入式 Python，无需用户预装
:: ============================================================

:: 检查是否为静默安装模式（由 Inno Setup 调用）
set "SILENT_MODE=0"
if "%1"=="--silent" set "SILENT_MODE=1"
if defined INSTALL_DIR set "SILENT_MODE=1"

if "%SILENT_MODE%"=="0" (
    title Open WebUI 安装程序
    echo.
    echo ============================================================
    echo          Open WebUI Windows 一键安装程序
    echo.
    echo   将安装: Open WebUI + Ollama + Embedding Proxy
    echo   模型: qwen2.5:7b + qwen3-embedding:latest
    echo ============================================================
    echo.
)

:: ------------------------------------------------------------
:: 检查安装目录
:: ------------------------------------------------------------
if "%INSTALL_DIR%"=="" (
    set "INSTALL_DIR=%~dp0"
)
if "%INSTALL_DIR:~-1%"=="\" set "INSTALL_DIR=%INSTALL_DIR:~0,-1%"

set "APP_DIR=%INSTALL_DIR%\app"
set "DATA_DIR=%INSTALL_DIR%\data"
set "PYTHON_DIR=%INSTALL_DIR%\python"
set "LOGS_DIR=%APP_DIR%\logs"

:: Python 可执行文件路径
set "PYTHON_EXE=%PYTHON_DIR%\python.exe"

echo [INFO] Install directory: %INSTALL_DIR%
echo [INFO] App directory: %APP_DIR%
echo [INFO] Data directory: %DATA_DIR%
echo [INFO] Python directory: %PYTHON_DIR%
echo.

:: ------------------------------------------------------------
:: 创建目录结构
:: ------------------------------------------------------------
echo [1/6] Creating directory structure...
if not exist "%APP_DIR%" mkdir "%APP_DIR%"
if not exist "%DATA_DIR%" mkdir "%DATA_DIR%"
if not exist "%DATA_DIR%\cache" mkdir "%DATA_DIR%\cache"
if not exist "%DATA_DIR%\uploads" mkdir "%DATA_DIR%\uploads"
if not exist "%DATA_DIR%\vector_db" mkdir "%DATA_DIR%\vector_db"
if not exist "%LOGS_DIR%" mkdir "%LOGS_DIR%"
echo       Done.
echo.

:: ------------------------------------------------------------
:: 检查内置 Python
:: ------------------------------------------------------------
echo [2/6] Checking Python...

if not exist "%PYTHON_EXE%" (
    echo       ERROR: Built-in Python not found!
    echo       The installer may be corrupted. Please re-download.
    if "%SILENT_MODE%"=="0" pause
    exit /b 1
)

for /f "tokens=*" %%i in ('"%PYTHON_EXE%" --version 2^>^&1') do set PYTHON_VERSION=%%i
echo       Found: %PYTHON_VERSION%
echo.

:: ------------------------------------------------------------
:: 检查/安装 Ollama
:: ------------------------------------------------------------
echo [3/6] Checking Ollama...

set "OLLAMA_CMD="
where ollama >nul 2>&1
if %errorlevel% equ 0 (
    set "OLLAMA_CMD=ollama"
    goto :ollama_found
)

if exist "%LOCALAPPDATA%\Programs\Ollama\ollama.exe" (
    set "OLLAMA_CMD=%LOCALAPPDATA%\Programs\Ollama\ollama.exe"
    goto :ollama_found
)
if exist "%ProgramFiles%\Ollama\ollama.exe" (
    set "OLLAMA_CMD=%ProgramFiles%\Ollama\ollama.exe"
    goto :ollama_found
)

echo       Ollama not found, downloading...
echo.

set "OLLAMA_INSTALLER=%TEMP%\OllamaSetup.exe"

echo       Downloading Ollama installer...
powershell -Command "& {[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; $ProgressPreference = 'SilentlyContinue'; Invoke-WebRequest -Uri 'https://ollama.com/download/OllamaSetup.exe' -OutFile '%OLLAMA_INSTALLER%'}"

if not exist "%OLLAMA_INSTALLER%" (
    echo       ERROR: Failed to download Ollama!
    echo       Please manually download from https://ollama.com/download
    if "%SILENT_MODE%"=="0" pause
    exit /b 1
)

echo       Installing Ollama silently...
start /wait "" "%OLLAMA_INSTALLER%" /VERYSILENT /SUPPRESSMSGBOXES /NORESTART

:: 等待安装完成
timeout /t 5 /nobreak >nul

if exist "%LOCALAPPDATA%\Programs\Ollama\ollama.exe" (
    set "OLLAMA_CMD=%LOCALAPPDATA%\Programs\Ollama\ollama.exe"
    goto :ollama_found
)

:: 再检查一次常见安装位置
if exist "%USERPROFILE%\AppData\Local\Programs\Ollama\ollama.exe" (
    set "OLLAMA_CMD=%USERPROFILE%\AppData\Local\Programs\Ollama\ollama.exe"
    goto :ollama_found
)

echo       WARNING: Ollama installation may require restart.
echo       Please restart your computer if Ollama doesn't work.
set "OLLAMA_CMD=ollama"

:ollama_found
echo       Ollama OK: !OLLAMA_CMD!
echo.

:: ------------------------------------------------------------
:: 安装 Python 依赖
:: ------------------------------------------------------------
echo [4/6] Installing Python dependencies (this may take 5-10 minutes)...

echo       Upgrading pip...
"%PYTHON_EXE%" -m pip install --upgrade pip -q 2>nul

echo       Installing packages...
"%PYTHON_EXE%" -m pip install -r "%APP_DIR%\requirements.txt" --no-warn-script-location -q
if %errorlevel% neq 0 (
    echo       ERROR: Failed to install dependencies!
    echo       Please check your network connection.
    if "%SILENT_MODE%"=="0" pause
    exit /b 1
)
echo       Done.
echo.

:: ------------------------------------------------------------
:: 启动 Ollama 服务并下载模型
:: ------------------------------------------------------------
echo [5/6] Downloading AI models (this will take a while for first time)...
echo.
echo       Will download approximately 10GB of model files:
echo       - qwen3-embedding:latest (~4.7GB) - Embedding model
echo       - qwen2.5:7b (~4.7GB) - Inference model
echo.

echo       Starting Ollama service...
start /b "" "!OLLAMA_CMD!" serve >nul 2>&1

echo       Waiting for Ollama service...
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
    echo       WARNING: Ollama service timeout.
    echo       You may need to manually run these commands later:
    echo         ollama pull qwen3-embedding:latest
    echo         ollama pull qwen2.5:7b
    goto :skip_model_download
)

echo.
echo       [Model 1/2] Downloading qwen3-embedding:latest ...
"!OLLAMA_CMD!" pull qwen3-embedding:latest
if %errorlevel% neq 0 (
    echo       WARNING: qwen3-embedding:latest download failed
    echo       Please run later: ollama pull qwen3-embedding:latest
)

echo.
echo       [Model 2/2] Downloading qwen2.5:7b ...
"!OLLAMA_CMD!" pull qwen2.5:7b
if %errorlevel% neq 0 (
    echo       WARNING: qwen2.5:7b download failed
    echo       Please run later: ollama pull qwen2.5:7b
)

echo.
echo       Model download completed.

:skip_model_download
echo.

:: ------------------------------------------------------------
:: 创建配置文件
:: ------------------------------------------------------------
echo [6/6] Creating configuration file...

(
echo @echo off
echo :: ============================================================
echo :: Open WebUI Configuration - Auto-generated, do not edit
echo :: ============================================================
echo set "INSTALL_DIR=%INSTALL_DIR%"
echo set "APP_DIR=%APP_DIR%"
echo set "DATA_DIR=%DATA_DIR%"
echo set "PYTHON_DIR=%PYTHON_DIR%"
echo set "PYTHON_EXE=%PYTHON_EXE%"
echo set "LOGS_DIR=%LOGS_DIR%"
echo set "OLLAMA_CMD=!OLLAMA_CMD!"
) > "%APP_DIR%\config.bat"

echo       Done.
echo.

:: ------------------------------------------------------------
:: 安装完成
:: ------------------------------------------------------------
echo ============================================================
echo                    Installation Complete!
echo ============================================================
echo.
echo   To start: Double-click start.bat or desktop shortcut
echo   To stop:  Close the window or run stop.bat
echo   Access:   http://localhost:8080
echo.
echo   First time access requires admin account registration.
echo.
echo ============================================================

:: 只在非静默模式下暂停
if "%SILENT_MODE%"=="0" (
    echo.
    echo Press any key to exit...
    pause >nul
)

exit /b 0
