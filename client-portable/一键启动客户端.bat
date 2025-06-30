@echo off
chcp 65001 >nul
title 视频合成客户端 - 启动器

cls
echo.
echo   ██╗   ██╗██╗██████╗ ███████╗ ██████╗ 
echo   ██║   ██║██║██╔══██╗██╔════╝██╔═══██╗
echo   ██║   ██║██║██║  ██║█████╗  ██║   ██║
echo   ╚██╗ ██╔╝██║██║  ██║██╔══╝  ██║   ██║
echo    ╚████╔╝ ██║██████╔╝███████╗╚██████╔╝
echo     ╚═══╝  ╚═╝╚═════╝ ╚══════╝ ╚═════╝ 
echo.
echo        视频合成客户端 v1.0 - 一键启动
echo ================================================
echo.

:: 设置变量
set CURRENT_DIR=%~dp0
set PYTHON_PORTABLE=%CURRENT_DIR%python-portable\python.exe
set CLIENT_MAIN=%CURRENT_DIR%..\client\main.py

:: 检查是否需要安装Python
if not exist "%PYTHON_PORTABLE%" (
    echo [!] 首次运行，需要配置环境
    echo.
    echo 即将：
    echo   1. 下载Python便携版（约25MB）
    echo   2. 安装必要的依赖包
    echo   3. 配置运行环境
    echo.
    echo 整个过程大约需要3-5分钟，取决于网络速度
    echo.
    echo 提示：此过程只需要执行一次
    echo ================================================
    echo.
    choice /C YN /M "是否继续？(Y/N)"
    if errorlevel 2 exit /b
    
    echo.
    call "%CURRENT_DIR%setup_python.bat"
    if errorlevel 1 (
        echo.
        echo [错误] 环境配置失败！
        pause
        exit /b 1
    )
    cls
    goto :start_client
)

:start_client
echo.
echo   ██╗   ██╗██╗██████╗ ███████╗ ██████╗ 
echo   ██║   ██║██║██╔══██╗██╔════╝██╔═══██╗
echo   ██║   ██║██║██║  ██║█████╗  ██║   ██║
echo   ╚██╗ ██╔╝██║██║  ██║██╔══╝  ██║   ██║
echo    ╚████╔╝ ██║██████╔╝███████╗╚██████╔╝
echo     ╚═══╝  ╚═╝╚═════╝ ╚══════╝ ╚═════╝ 
echo.
echo        视频合成客户端 v1.0 - 启动中...
echo ================================================
echo.

:: 检查客户端文件
if not exist "%CLIENT_MAIN%" (
    echo [错误] 客户端文件缺失！
    echo.
    echo 请确保以下文件存在：
    echo %CLIENT_MAIN%
    echo.
    pause
    exit /b 1
)

:: 检查服务器连接（可选）
echo [*] 检查服务器连接...
powershell -Command "try { $response = Invoke-WebRequest -Uri 'http://localhost:6006/health' -UseBasicParsing -TimeoutSec 2; Write-Host '[√] 服务器连接正常' -ForegroundColor Green } catch { Write-Host '[!] 警告：无法连接到服务器 (http://localhost:6006)' -ForegroundColor Yellow; Write-Host '    请确保服务器已启动' -ForegroundColor Yellow }"

echo.
echo [*] 启动客户端界面...
echo.

:: 启动客户端
cd /d "%CURRENT_DIR%..\client"
"%PYTHON_PORTABLE%" main.py

:: 检查退出代码
if errorlevel 1 (
    echo.
    echo ================================================
    echo [错误] 客户端异常退出！
    echo.
    echo 可能的原因：
    echo   1. 依赖包未正确安装
    echo   2. 客户端代码有错误
    echo   3. PyQt5组件问题
    echo.
    echo 解决方案：
    echo   1. 删除 python-portable 文件夹
    echo   2. 重新运行此脚本
    echo ================================================
    echo.
    pause
) else (
    echo.
    echo [√] 客户端已正常关闭
    timeout /t 2 >nul
)