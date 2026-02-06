@echo off
chcp 65001 >nul 2>&1
setlocal EnableDelayedExpansion

echo ============================================================
echo   Open WebUI - Uninstall AI Models
echo ============================================================
echo.
echo This tool helps you free up disk space by removing AI models.
echo.
echo Current models installed:
echo.

:: 检查 Ollama 是否可用
where ollama >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo [ERROR] Ollama is not installed or not in PATH.
    echo.
    pause
    exit /b 1
)

:: 显示当前模型列表
ollama list
echo.

:: 显示模型占用空间
echo Model storage location: %USERPROFILE%\.ollama\models
echo.

:: 计算大小
for /f "tokens=3" %%a in ('dir /s "%USERPROFILE%\.ollama\models" 2^>nul ^| findstr "File(s)"') do set SIZE=%%a
echo Total models size: approximately %SIZE% bytes
echo.

echo ============================================================
echo   Options:
echo ============================================================
echo.
echo [1] Delete qwen2.5:7b model only (~4.7GB)
echo [2] Delete qwen3-embedding:latest model only (~4.7GB)
echo [3] Delete ALL models (~10GB)
echo [4] Cancel
echo.

set /p CHOICE="Enter your choice (1-4): "

if "%CHOICE%"=="1" (
    echo.
    echo Deleting qwen2.5:7b...
    ollama rm qwen2.5:7b
    echo Done!
) else if "%CHOICE%"=="2" (
    echo.
    echo Deleting qwen3-embedding:latest...
    ollama rm qwen3-embedding:latest
    echo Done!
) else if "%CHOICE%"=="3" (
    echo.
    echo Deleting all models...
    ollama rm qwen2.5:7b 2>nul
    ollama rm qwen3-embedding:latest 2>nul
    echo.
    echo All models deleted!
    echo.
    echo Note: To completely remove all Ollama data, you can manually delete:
    echo   %USERPROFILE%\.ollama
    echo.
) else if "%CHOICE%"=="4" (
    echo.
    echo Cancelled.
) else (
    echo.
    echo Invalid choice.
)

echo.
echo ============================================================
echo   Remaining models:
echo ============================================================
ollama list

echo.
pause
