@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion

:: ============================================================
:: Open WebUI 启动脚本
:: ============================================================

title Open WebUI

echo.
echo ╔══════════════════════════════════════════════════════════╗
echo ║              Open WebUI 启动中...                        ║
echo ╚══════════════════════════════════════════════════════════╝
echo.

:: ------------------------------------------------------------
:: 加载配置
:: ------------------------------------------------------------
set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

:: 检查配置文件位置
if exist "%SCRIPT_DIR%\app\config.bat" (
    call "%SCRIPT_DIR%\app\config.bat"
) else (
    :: 使用默认路径（脚本所在目录）
    set "INSTALL_DIR=%SCRIPT_DIR%"
    set "APP_DIR=%SCRIPT_DIR%\app"
    set "DATA_DIR=%SCRIPT_DIR%\data"
    set "VENV_DIR=%SCRIPT_DIR%\app\.venv"
    set "LOGS_DIR=%SCRIPT_DIR%\app\logs"
    set "OLLAMA_CMD=ollama"
)

echo [信息] 安装目录: %INSTALL_DIR%
echo [信息] 数据目录: %DATA_DIR%
echo.

:: 确保目录存在
if not exist "%LOGS_DIR%" mkdir "%LOGS_DIR%"
if not exist "%DATA_DIR%" mkdir "%DATA_DIR%"

:: ------------------------------------------------------------
:: 设置 Open WebUI 环境变量（运行时设置，不修改系统变量）
:: ------------------------------------------------------------

:: 离线模式配置（禁用自动更新）
set "OFFLINE_MODE=true"
set "RAG_EMBEDDING_MODEL_AUTO_UPDATE=false"
set "RAG_RERANKING_MODEL_AUTO_UPDATE=false"
set "WHISPER_MODEL_AUTO_UPDATE=false"
set "DISABLE_UPDATE_CHECK=true"
set "ENABLE_PERSISTENT_CONFIG=False"

:: 数据目录配置（关键！确保数据保存到指定位置）
set "DATA_DIR=%DATA_DIR%"

:: Ollama 配置
set "OLLAMA_BASE_URL=http://localhost:11434"

:: RAG Embedding 配置（使用本地 embedding 代理）
set "RAG_EMBEDDING_ENGINE=openai"
set "RAG_EMBEDDING_MODEL=qwen3-embedding:latest"
set "RAG_OPENAI_API_BASE_URL=http://127.0.0.1:8001/v1"
set "RAG_OPENAI_API_KEY=dummy"

:: OpenAI 兼容配置
set "OPENAI_API_BASE_URL=http://127.0.0.1:8001/v1"
set "OPENAI_API_URL=http://127.0.0.1:8001/v1"
set "OPENAI_API_BASE=http://127.0.0.1:8001/v1"
set "OPENAI_API_KEY=dummy"

:: ------------------------------------------------------------
:: 查找 Ollama
:: ------------------------------------------------------------
if "%OLLAMA_CMD%"=="" set "OLLAMA_CMD=ollama"
if not exist "%OLLAMA_CMD%" (
    where ollama >nul 2>&1
    if %errorlevel% equ 0 (
        set "OLLAMA_CMD=ollama"
    ) else if exist "%LOCALAPPDATA%\Programs\Ollama\ollama.exe" (
        set "OLLAMA_CMD=%LOCALAPPDATA%\Programs\Ollama\ollama.exe"
    )
)

:: ------------------------------------------------------------
:: 启动 Ollama 服务
:: ------------------------------------------------------------
echo [1/3] 启动 Ollama 服务...

:: 检查 Ollama 是否已在运行
powershell -Command "try { $r = Invoke-WebRequest -Uri 'http://localhost:11434/api/tags' -TimeoutSec 2 -UseBasicParsing; exit 0 } catch { exit 1 }" >nul 2>&1
if %errorlevel% equ 0 (
    echo       ✓ Ollama 服务已在运行
) else (
    start /b "" "!OLLAMA_CMD!" serve >"%LOGS_DIR%\ollama.log" 2>&1
    
    :: 等待 Ollama 启动
    echo       等待 Ollama 启动...
    set "OLLAMA_READY=0"
    for /L %%i in (1,1,30) do (
        if !OLLAMA_READY! equ 0 (
            timeout /t 1 /nobreak >nul
            powershell -Command "try { $r = Invoke-WebRequest -Uri 'http://localhost:11434/api/tags' -TimeoutSec 2 -UseBasicParsing; exit 0 } catch { exit 1 }" >nul 2>&1
            if !errorlevel! equ 0 (
                set "OLLAMA_READY=1"
                echo       ✓ Ollama 服务已启动
            )
        )
    )
    
    if !OLLAMA_READY! equ 0 (
        echo       ✗ Ollama 启动超时！
        echo       请检查 %LOGS_DIR%\ollama.log
        pause
        exit /b 1
    )
)
echo.

:: ------------------------------------------------------------
:: 启动 Embedding 代理
:: ------------------------------------------------------------
echo [2/3] 启动 Embedding 代理...

:: 检查端口 8001 是否已占用
netstat -ano | findstr ":8001.*LISTENING" >nul 2>&1
if %errorlevel% equ 0 (
    echo       ✓ Embedding 代理已在运行 (端口 8001)
) else (
    :: 切换到 app 目录启动（确保能找到 embed_proxy.py）
    pushd "%APP_DIR%"
    start /b "" "%VENV_DIR%\Scripts\pythonw.exe" -m uvicorn embed_proxy:app --host 127.0.0.1 --port 8001 >"%LOGS_DIR%\embed-proxy.log" 2>&1
    popd
    
    :: 等待代理启动
    echo       等待 Embedding 代理启动...
    set "PROXY_READY=0"
    for /L %%i in (1,1,30) do (
        if !PROXY_READY! equ 0 (
            timeout /t 1 /nobreak >nul
            powershell -Command "try { $r = Invoke-WebRequest -Uri 'http://127.0.0.1:8001/v1/embeddings' -Method Post -Body '{\"model\":\"test\",\"input\":\"ping\"}' -ContentType 'application/json' -TimeoutSec 2 -UseBasicParsing; exit 0 } catch { exit 1 }" >nul 2>&1
            if !errorlevel! equ 0 (
                set "PROXY_READY=1"
                echo       ✓ Embedding 代理已启动 (端口 8001)
            )
        )
    )
    
    if !PROXY_READY! equ 0 (
        echo       ⚠ Embedding 代理启动超时
        echo       RAG 功能可能不可用，但不影响基本对话
        echo       请检查 %LOGS_DIR%\embed-proxy.log
    )
)
echo.

:: ------------------------------------------------------------
:: 启动 Open WebUI
:: ------------------------------------------------------------
echo [3/3] 启动 Open WebUI...
echo.
echo ╔══════════════════════════════════════════════════════════╗
echo ║                                                          ║
echo ║  Open WebUI 正在启动...                                  ║
echo ║                                                          ║
echo ║  请在浏览器中访问: http://localhost:8080                 ║
echo ║                                                          ║
echo ║  首次访问需要注册管理员账号                              ║
echo ║                                                          ║
echo ║  ┌────────────────────────────────────────────────────┐  ║
echo ║  │  关闭方式:                                         │  ║
echo ║  │    - 直接关闭此窗口 (会自动清理后台服务)           │  ║
echo ║  │    - 或按 Ctrl+C                                   │  ║
echo ║  │    - 或运行 stop.bat                               │  ║
echo ║  └────────────────────────────────────────────────────┘  ║
echo ║                                                          ║
echo ╚══════════════════════════════════════════════════════════╝
echo.

:: 切换到 app 目录
cd /d "%APP_DIR%"

:: 前台启动 Open WebUI
"%VENV_DIR%\Scripts\open-webui.exe" serve

:: ------------------------------------------------------------
:: 当 Open WebUI 退出时（窗口关闭或 Ctrl+C），自动清理
:: ------------------------------------------------------------
echo.
echo [清理] Open WebUI 已退出，正在停止后台服务...
call "%INSTALL_DIR%\stop.bat" --no-pause
