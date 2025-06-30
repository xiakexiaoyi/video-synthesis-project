@echo off
chcp 65001 >nul
title 离线安装包制作工具

echo ======================================
echo   离线安装包制作工具
echo ======================================
echo.
echo 此工具用于制作离线安装包，方便在没有
echo 网络的环境中部署客户端
echo.

set CURRENT_DIR=%~dp0
set OFFLINE_DIR=%CURRENT_DIR%offline-package
set PYTHON_VERSION=3.10.11

:: 创建离线包目录
if not exist "%OFFLINE_DIR%" mkdir "%OFFLINE_DIR%"

echo [1/3] 准备Python安装包...
echo.
echo 请手动下载以下文件：
echo.
echo 1. Python %PYTHON_VERSION% embeddable包
echo    URL: https://www.python.org/ftp/python/%PYTHON_VERSION%/python-%PYTHON_VERSION%-embed-amd64.zip
echo    保存为: %OFFLINE_DIR%\python-embed.zip
echo.
echo 2. get-pip.py
echo    URL: https://bootstrap.pypa.io/get-pip.py
echo    保存为: %OFFLINE_DIR%\get-pip.py
echo.
pause

:: 检查文件
if not exist "%OFFLINE_DIR%\python-embed.zip" (
    echo [错误] 未找到 python-embed.zip
    pause
    exit /b 1
)

if not exist "%OFFLINE_DIR%\get-pip.py" (
    echo [错误] 未找到 get-pip.py
    pause
    exit /b 1
)

echo.
echo [2/3] 创建离线安装脚本...

:: 创建离线安装脚本
(
echo @echo off
echo chcp 65001 ^>nul
echo title 视频合成客户端 - 离线安装
echo.
echo echo ======================================
echo echo   视频合成客户端 - 离线安装程序
echo echo ======================================
echo echo.
echo.
echo set CURRENT_DIR=%%~dp0
echo set PYTHON_DIR=%%CURRENT_DIR%%python-portable
echo set OFFLINE_DIR=%%CURRENT_DIR%%offline-package
echo.
echo :: 解压Python
echo echo [1/3] 安装Python...
echo if not exist "%%PYTHON_DIR%%" mkdir "%%PYTHON_DIR%%"
echo powershell -Command "Expand-Archive -Path '%%OFFLINE_DIR%%\python-embed.zip' -DestinationPath '%%PYTHON_DIR%%' -Force"
echo.
echo :: 配置Python
echo echo python310.zip ^> "%%PYTHON_DIR%%\python310._pth"
echo echo . ^>^> "%%PYTHON_DIR%%\python310._pth"
echo echo import site ^>^> "%%PYTHON_DIR%%\python310._pth"
echo echo Lib ^>^> "%%PYTHON_DIR%%\python310._pth"
echo echo Lib\site-packages ^>^> "%%PYTHON_DIR%%\python310._pth"
echo.
echo :: 安装pip
echo echo [2/3] 安装pip...
echo "%%PYTHON_DIR%%\python.exe" "%%OFFLINE_DIR%%\get-pip.py" --no-index --find-links "%%OFFLINE_DIR%%\packages"
echo.
echo :: 安装依赖
echo echo [3/3] 安装依赖包...
echo "%%PYTHON_DIR%%\Scripts\pip.exe" install --no-index --find-links "%%OFFLINE_DIR%%\packages" PyQt5==5.15.9 requests==2.31.0 aiohttp==3.9.1
echo.
echo echo.
echo echo ======================================
echo echo   [√] 安装完成！
echo echo ======================================
echo echo.
echo echo 请运行"一键启动客户端.bat"启动程序
echo pause
) > "%OFFLINE_DIR%\install.bat"

echo.
echo [3/3] 下载依赖包...
echo.
echo 请在有网络的环境中运行以下命令下载依赖包：
echo.
echo pip download -d "%OFFLINE_DIR%\packages" PyQt5==5.15.9 requests==2.31.0 aiohttp==3.9.1
echo.
echo 完成后，将整个 offline-package 文件夹复制到目标电脑即可
echo.
pause