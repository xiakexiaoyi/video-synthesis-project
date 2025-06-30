@echo off
chcp 65001 >nul
title 视频合成客户端

:: 设置路径
set CURRENT_DIR=%~dp0
set PYTHON_DIR=%CURRENT_DIR%python-portable
set PYTHON_EXE=%PYTHON_DIR%\python.exe
set CLIENT_DIR=%CURRENT_DIR%client

:: 检查Python环境
if not exist "%PYTHON_EXE%" (
    echo ======================================
    echo   首次运行需要配置Python环境
    echo ======================================
    echo.
    echo 即将自动下载并配置Python环境...
    echo 这可能需要几分钟时间，请耐心等待
    echo.
    pause
    call "%CURRENT_DIR%setup_python.bat"
    if errorlevel 1 exit /b 1
)

:: 检查客户端文件
if not exist "%CLIENT_DIR%\main.py" (
    echo [错误] 未找到客户端文件！
    echo 请确保 client\main.py 存在
    pause
    exit /b 1
)

:: 启动客户端
echo ======================================
echo   视频合成客户端 v1.0
echo ======================================
echo.
echo 正在启动客户端...
echo.

cd "%CLIENT_DIR%"
"%PYTHON_EXE%" main.py

if errorlevel 1 (
    echo.
    echo [错误] 客户端启动失败！
    echo.
    echo 可能的原因：
    echo 1. 服务器未启动（默认地址: http://localhost:8000）
    echo 2. 依赖包未正确安装
    echo 3. 防火墙阻止了连接
    echo.
    echo 请查看错误信息并解决问题后重试
    pause
)