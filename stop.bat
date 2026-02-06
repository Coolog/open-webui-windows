@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion

:: ============================================================
:: Open WebUI 停止脚本
:: ============================================================

title 停止 Open WebUI

echo.
echo ╔══════════════════════════════════════════════════════════╗
echo ║              停止 Open WebUI 服务...                     ║
echo ╚══════════════════════════════════════════════════════════╝
echo.

:: ------------------------------------------------------------
:: 停止端口 8080 上的进程 (Open WebUI)
:: ------------------------------------------------------------
echo [1/3] 停止 Open WebUI (端口 8080)...
set "FOUND_8080=0"
for /f "tokens=5" %%a in ('netstat -ano ^| findstr ":8080.*LISTENING" 2^>nul') do (
    set "PID=%%a"
    if defined PID (
        if "!PID!" neq "0" (
            taskkill /PID !PID! /F >nul 2>&1
            echo       ✓ 已停止进程 PID !PID!
            set "FOUND_8080=1"
        )
    )
)
if "!FOUND_8080!"=="0" echo       ✓ 端口 8080 未在使用
echo.

:: ------------------------------------------------------------
:: 停止端口 8001 上的进程 (Embedding Proxy)
:: ------------------------------------------------------------
echo [2/3] 停止 Embedding 代理 (端口 8001)...
set "FOUND_8001=0"
for /f "tokens=5" %%a in ('netstat -ano ^| findstr ":8001.*LISTENING" 2^>nul') do (
    set "PID=%%a"
    if defined PID (
        if "!PID!" neq "0" (
            taskkill /PID !PID! /F >nul 2>&1
            echo       ✓ 已停止进程 PID !PID!
            set "FOUND_8001=1"
        )
    )
)
if "!FOUND_8001!"=="0" echo       ✓ 端口 8001 未在使用
echo.

:: ------------------------------------------------------------
:: 按进程名停止 (兜底)
:: ------------------------------------------------------------
echo [3/3] 清理残留进程...

:: 停止 open-webui 相关进程
taskkill /IM "open-webui.exe" /F >nul 2>&1

:: 停止 uvicorn 相关进程（embed_proxy）
taskkill /FI "IMAGENAME eq python.exe" /FI "WINDOWTITLE eq *uvicorn*" /F >nul 2>&1

:: 注意：默认不停止 Ollama，因为用户可能还需要它
:: 如需停止 Ollama，取消下面的注释：
:: taskkill /IM "ollama.exe" /F >nul 2>&1

echo       ✓ 清理完成
echo.

:: ------------------------------------------------------------
:: 检查结果
:: ------------------------------------------------------------
echo ┌────────────────────────────────────────────────────────┐
echo │ 端口状态检查                                          │
echo ├────────────────────────────────────────────────────────┤

netstat -ano | findstr ":8080.*LISTENING" >nul 2>&1
if %errorlevel% equ 0 (
    echo │   端口 8080: ⚠ 仍在使用                              │
) else (
    echo │   端口 8080: ✓ 已释放                                │
)

netstat -ano | findstr ":8001.*LISTENING" >nul 2>&1
if %errorlevel% equ 0 (
    echo │   端口 8001: ⚠ 仍在使用                              │
) else (
    echo │   端口 8001: ✓ 已释放                                │
)

echo └────────────────────────────────────────────────────────┘
echo.
echo ╔══════════════════════════════════════════════════════════╗
echo ║                    服务已停止                            ║
echo ╚══════════════════════════════════════════════════════════╝
echo.

:: 如果是被 start.bat 调用的，不暂停
if "%1"=="--no-pause" exit /b 0

timeout /t 3
