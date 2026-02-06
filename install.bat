@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion

:: ============================================================
:: Open WebUI Windows 一键安装脚本
:: ============================================================

title Open WebUI 安装程序

echo.
echo ╔══════════════════════════════════════════════════════════╗
echo ║         Open WebUI Windows 一键安装程序                  ║
echo ║                                                          ║
echo ║  将安装: Open WebUI + Ollama + Embedding Proxy           ║
echo ║  模型: qwen2.5:7b (推理) + qwen3-embedding:latest (RAG)  ║
echo ╚══════════════════════════════════════════════════════════╝
echo.

:: ------------------------------------------------------------
:: 检查安装目录（由 Inno Setup 传入或使用默认值）
:: ------------------------------------------------------------
if "%INSTALL_DIR%"=="" (
    set "INSTALL_DIR=%~dp0"
)
:: 移除末尾的反斜杠
if "%INSTALL_DIR:~-1%"=="\" set "INSTALL_DIR=%INSTALL_DIR:~0,-1%"

set "APP_DIR=%INSTALL_DIR%\app"
set "DATA_DIR=%INSTALL_DIR%\data"
set "VENV_DIR=%APP_DIR%\.venv"
set "LOGS_DIR=%APP_DIR%\logs"

echo [信息] 安装目录: %INSTALL_DIR%
echo [信息] 程序目录: %APP_DIR%
echo [信息] 数据目录: %DATA_DIR%
echo.

:: ------------------------------------------------------------
:: 创建目录结构
:: ------------------------------------------------------------
echo [1/7] 创建目录结构...
if not exist "%APP_DIR%" mkdir "%APP_DIR%"
if not exist "%DATA_DIR%" mkdir "%DATA_DIR%"
if not exist "%DATA_DIR%\cache" mkdir "%DATA_DIR%\cache"
if not exist "%DATA_DIR%\uploads" mkdir "%DATA_DIR%\uploads"
if not exist "%DATA_DIR%\vector_db" mkdir "%DATA_DIR%\vector_db"
if not exist "%LOGS_DIR%" mkdir "%LOGS_DIR%"
echo       ✓ 目录创建完成
echo.

:: ------------------------------------------------------------
:: 检查 Python（需要 3.10 或 3.11）
:: ------------------------------------------------------------
echo [2/7] 检查 Python 环境...

set "PYTHON_CMD="

:: 优先查找 py launcher（Windows Python 官方安装器会安装）
where py >nul 2>&1
if %errorlevel% equ 0 (
    :: 尝试 Python 3.11
    py -3.11 --version >nul 2>&1
    if !errorlevel! equ 0 (
        set "PYTHON_CMD=py -3.11"
        goto :python_found
    )
    :: 尝试 Python 3.10
    py -3.10 --version >nul 2>&1
    if !errorlevel! equ 0 (
        set "PYTHON_CMD=py -3.10"
        goto :python_found
    )
)

:: 查找 python 命令
where python >nul 2>&1
if %errorlevel% equ 0 (
    for /f "tokens=2" %%i in ('python --version 2^>^&1') do set "PY_VER=%%i"
    
    :: 检查是否是 3.10 或 3.11
    echo !PY_VER! | findstr /r "^3\.1[01]\." >nul
    if !errorlevel! equ 0 (
        set "PYTHON_CMD=python"
        goto :python_found
    )
    
    echo       ⚠ 检测到 Python !PY_VER!，但 Open WebUI 需要 Python 3.10 或 3.11
)

:: Python 未找到或版本不对
echo       ✗ 未找到合适的 Python 版本！
echo.
echo       Open WebUI 需要 Python 3.10 或 3.11
echo       请从以下地址下载安装 Python 3.11：
echo       https://www.python.org/downloads/release/python-3119/
echo.
echo       ╔════════════════════════════════════════════════════╗
echo       ║  安装时请务必勾选：                                ║
echo       ║  [√] Add python.exe to PATH                        ║
echo       ║  [√] Use admin privileges when installing py.exe  ║
echo       ╚════════════════════════════════════════════════════╝
echo.
pause
exit /b 1

:python_found
for /f "tokens=*" %%i in ('!PYTHON_CMD! --version 2^>^&1') do set PYTHON_VERSION=%%i
echo       ✓ 使用 !PYTHON_CMD! (!PYTHON_VERSION!)
echo.

:: ------------------------------------------------------------
:: 检查/安装 Ollama
:: ------------------------------------------------------------
echo [3/7] 检查 Ollama...

:: 检查多个可能的 Ollama 路径
set "OLLAMA_CMD="
where ollama >nul 2>&1
if %errorlevel% equ 0 (
    set "OLLAMA_CMD=ollama"
    goto :ollama_found
)

:: 检查常见安装路径
if exist "%LOCALAPPDATA%\Programs\Ollama\ollama.exe" (
    set "OLLAMA_CMD=%LOCALAPPDATA%\Programs\Ollama\ollama.exe"
    goto :ollama_found
)
if exist "%ProgramFiles%\Ollama\ollama.exe" (
    set "OLLAMA_CMD=%ProgramFiles%\Ollama\ollama.exe"
    goto :ollama_found
)

:: Ollama 未安装，下载安装
echo       未检测到 Ollama，正在下载安装...
echo.

set "OLLAMA_INSTALLER=%TEMP%\OllamaSetup.exe"

:: 使用 PowerShell 下载
echo       下载 Ollama 安装程序...
powershell -Command "& {[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; $ProgressPreference = 'SilentlyContinue'; Invoke-WebRequest -Uri 'https://ollama.com/download/OllamaSetup.exe' -OutFile '%OLLAMA_INSTALLER%'}"

if not exist "%OLLAMA_INSTALLER%" (
    echo       ✗ Ollama 下载失败！
    echo       请手动从 https://ollama.com/download 下载安装
    pause
    exit /b 1
)

echo       正在安装 Ollama（请在弹出的安装窗口中完成安装）...
start /wait "" "%OLLAMA_INSTALLER%"

:: 安装后再次检查
if exist "%LOCALAPPDATA%\Programs\Ollama\ollama.exe" (
    set "OLLAMA_CMD=%LOCALAPPDATA%\Programs\Ollama\ollama.exe"
    goto :ollama_found
)

echo       ⚠ Ollama 安装完成，但需要重启电脑才能生效
echo       请重启电脑后重新运行此安装程序
pause
exit /b 1

:ollama_found
echo       ✓ Ollama 已安装
echo.

:: ------------------------------------------------------------
:: 创建 Python 虚拟环境
:: ------------------------------------------------------------
echo [4/7] 创建 Python 虚拟环境...
if not exist "%VENV_DIR%\Scripts\python.exe" (
    !PYTHON_CMD! -m venv "%VENV_DIR%"
    if %errorlevel% neq 0 (
        echo       ✗ 虚拟环境创建失败！
        pause
        exit /b 1
    )
)
echo       ✓ 虚拟环境就绪
for /f "tokens=*" %%i in ('"%VENV_DIR%\Scripts\python.exe" --version 2^>^&1') do (
    echo       %%i
)
echo.

:: ------------------------------------------------------------
:: 安装 Python 依赖
:: ------------------------------------------------------------
echo [5/7] 安装 Python 依赖（可能需要 5-10 分钟）...
echo       正在升级 pip...
"%VENV_DIR%\Scripts\python.exe" -m pip install --upgrade pip -q

echo       正在安装依赖包...
"%VENV_DIR%\Scripts\pip.exe" install -r "%APP_DIR%\requirements.txt"
if %errorlevel% neq 0 (
    echo       ✗ 依赖安装失败！
    echo       请检查网络连接后重试
    pause
    exit /b 1
)
echo       ✓ Python 依赖安装完成
echo.

:: ------------------------------------------------------------
:: 启动 Ollama 服务并下载模型
:: ------------------------------------------------------------
echo [6/7] 下载 AI 模型（首次运行需要较长时间）...
echo.
echo       ╔════════════════════════════════════════════════════╗
echo       ║  需要下载约 10GB 的模型文件                        ║
echo       ║  qwen3-embedding:latest  (~4.7GB) - Embedding 模型 ║
echo       ║  qwen2.5:7b              (~4.7GB) - 推理模型       ║
echo       ║                                                    ║
echo       ║  请保持网络连接，耐心等待...                       ║
echo       ╚════════════════════════════════════════════════════╝
echo.

:: 先启动 Ollama 服务
echo       启动 Ollama 服务...
start /b "" "!OLLAMA_CMD!" serve >nul 2>&1

:: 等待服务启动（使用 PowerShell 检测）
echo       等待 Ollama 服务就绪...
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
    echo       ⚠ Ollama 服务启动超时
    echo       请稍后手动运行以下命令下载模型:
    echo         ollama pull qwen3-embedding:latest
    echo         ollama pull qwen2.5:7b
    goto :skip_model_download
)

:: 下载 embedding 模型
echo.
echo       [模型 1/2] 下载 qwen3-embedding:latest ...
"!OLLAMA_CMD!" pull qwen3-embedding:latest
if %errorlevel% neq 0 (
    echo       ⚠ qwen3-embedding:latest 下载失败
    echo       请稍后手动运行: ollama pull qwen3-embedding:latest
)

:: 下载推理模型
echo.
echo       [模型 2/2] 下载 qwen2.5:7b ...
"!OLLAMA_CMD!" pull qwen2.5:7b
if %errorlevel% neq 0 (
    echo       ⚠ qwen2.5:7b 下载失败
    echo       请稍后手动运行: ollama pull qwen2.5:7b
)

echo.
echo       ✓ 模型下载完成

:skip_model_download
echo.

:: ------------------------------------------------------------
:: 创建配置文件
:: ------------------------------------------------------------
echo [7/7] 生成配置文件...

:: 生成 config.bat（保存安装路径，供 start.bat 使用）
(
echo @echo off
echo :: ============================================================
echo :: Open WebUI 配置文件 - 自动生成，请勿手动修改
echo :: ============================================================
echo set "INSTALL_DIR=%INSTALL_DIR%"
echo set "APP_DIR=%APP_DIR%"
echo set "DATA_DIR=%DATA_DIR%"
echo set "VENV_DIR=%VENV_DIR%"
echo set "LOGS_DIR=%LOGS_DIR%"
echo set "OLLAMA_CMD=!OLLAMA_CMD!"
) > "%APP_DIR%\config.bat"

echo       ✓ 配置文件生成完成
echo.

:: ------------------------------------------------------------
:: 安装完成
:: ------------------------------------------------------------
echo ╔══════════════════════════════════════════════════════════╗
echo ║                    安装完成！                            ║
echo ╠══════════════════════════════════════════════════════════╣
echo ║                                                          ║
echo ║  目录结构:                                               ║
echo ║    %INSTALL_DIR%
echo ║    ├── app\          程序文件                            ║
echo ║    │   ├── .venv\    Python 虚拟环境                     ║
echo ║    │   └── logs\     运行日志                            ║
echo ║    ├── data\         用户数据                            ║
echo ║    │   ├── uploads\  上传的文档                          ║
echo ║    │   └── vector_db\ 向量数据库                         ║
echo ║    ├── start.bat     启动脚本                            ║
echo ║    └── stop.bat      停止脚本                            ║
echo ║                                                          ║
echo ║  启动方式：                                              ║
echo ║    双击运行 start.bat 或桌面快捷方式                     ║
echo ║                                                          ║
echo ║  停止方式：                                              ║
echo ║    关闭启动窗口（会自动清理）或运行 stop.bat             ║
echo ║                                                          ║
echo ║  访问地址：                                              ║
echo ║    http://localhost:8080                                 ║
echo ║                                                          ║
echo ║  首次访问需要注册管理员账号                              ║
echo ║                                                          ║
echo ║  详细说明请查看安装目录下的 README.md                    ║
echo ║                                                          ║
echo ╚══════════════════════════════════════════════════════════╝
echo.
pause
