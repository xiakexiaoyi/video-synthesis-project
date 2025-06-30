@echo off
chcp 65001 >nul
title Python便携版安装程序

echo ======================================
echo   视频合成客户端 - Python环境配置
echo ======================================
echo.

:: 设置路径
set CURRENT_DIR=%~dp0
set PYTHON_DIR=%CURRENT_DIR%python-portable
set PYTHON_EXE=%PYTHON_DIR%\python.exe
set PIP_EXE=%PYTHON_DIR%\Scripts\pip.exe
set PYTHON_VERSION=3.10.11

:: 检查是否已有Python
if exist "%PYTHON_EXE%" (
    echo [√] 检测到Python环境已存在
    goto :check_deps
)

echo [1/4] 下载便携版Python...
echo.

:: 创建目录
if not exist "%PYTHON_DIR%" mkdir "%PYTHON_DIR%"

:: 下载Python embeddable包
set PYTHON_URL=https://www.python.org/ftp/python/%PYTHON_VERSION%/python-%PYTHON_VERSION%-embed-amd64.zip
set PYTHON_ZIP=%CURRENT_DIR%python-embed.zip

echo 正在下载Python %PYTHON_VERSION%...
echo URL: %PYTHON_URL%
powershell -Command "& { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri '%PYTHON_URL%' -OutFile '%PYTHON_ZIP%' -UseBasicParsing }"

if not exist "%PYTHON_ZIP%" (
    echo [错误] Python下载失败！
    echo.
    echo 请手动下载：%PYTHON_URL%
    echo 并保存为：%PYTHON_ZIP%
    pause
    exit /b 1
)

echo [2/4] 解压Python...
powershell -Command "Expand-Archive -Path '%PYTHON_ZIP%' -DestinationPath '%PYTHON_DIR%' -Force"
del "%PYTHON_ZIP%"

:: 下载get-pip.py
echo [3/4] 安装pip...
set GET_PIP_URL=https://bootstrap.pypa.io/get-pip.py
set GET_PIP=%CURRENT_DIR%get-pip.py

powershell -Command "& { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri '%GET_PIP_URL%' -OutFile '%GET_PIP%' -UseBasicParsing }"

:: 修改python._pth文件以支持pip
echo python%PYTHON_VERSION:.=%.zip > "%PYTHON_DIR%\python310._pth"
echo . >> "%PYTHON_DIR%\python310._pth"
echo import site >> "%PYTHON_DIR%\python310._pth"
echo Lib >> "%PYTHON_DIR%\python310._pth"
echo Lib\site-packages >> "%PYTHON_DIR%\python310._pth"

:: 安装pip
"%PYTHON_EXE%" "%GET_PIP%"
del "%GET_PIP%"

:check_deps
echo.
echo [4/4] 安装依赖包...

:: 升级pip
"%PYTHON_EXE%" -m pip install --upgrade pip

:: 安装依赖
echo 正在安装PyQt5...
"%PIP_EXE%" install PyQt5==5.15.9

echo 正在安装requests...
"%PIP_EXE%" install requests==2.31.0

echo 正在安装其他依赖...
"%PIP_EXE%" install aiohttp==3.9.1

echo.
echo ======================================
echo   [√] Python环境配置完成！
echo ======================================
echo.
echo Python路径: %PYTHON_EXE%
echo.

:: 创建启动脚本
echo 正在创建启动脚本...
copy "%~f0\..\start_client.bat" "%CURRENT_DIR%\" >nul 2>&1

echo 配置完成！请运行 start_client.bat 启动客户端
echo.
pause