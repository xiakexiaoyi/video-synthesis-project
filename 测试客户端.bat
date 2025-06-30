@echo off
chcp 65001 >nul
title 视频合成服务测试客户端

echo ========================================
echo     视频合成服务测试客户端
echo ========================================
echo.

:: 检查Python
python --version >nul 2>&1
if errorlevel 1 (
    echo [错误] 未找到Python，请先安装Python 3.x
    pause
    exit /b 1
)

:: 安装依赖（如果需要）
if not exist ".test_deps_installed" (
    echo [*] 首次运行，安装测试依赖...
    pip install requests -q
    echo. > .test_deps_installed
)

echo 请选择测试模式:
echo   1. 快速测试（使用默认测试数据）
echo   2. 自定义测试（指定文件和文本）
echo   3. 交互式测试（逐步输入）
echo   4. 测试服务器连接
echo.

choice /C 1234 /M "请选择 (1-4)"

if errorlevel 4 goto test_connection
if errorlevel 3 goto interactive
if errorlevel 2 goto custom
if errorlevel 1 goto quick

:quick
echo.
echo [*] 快速测试模式
echo.
echo 请确保以下测试文件存在:
echo   - test_data\test_video.mp4
echo.
python test_client.py --quick
goto end

:custom
echo.
echo [*] 自定义测试模式
echo.
set /p VIDEO_PATH="请输入视频文件路径: "
set /p TEXTS="请输入测试文本（用空格分隔多段）: "
set /p AUDIO_PATH="参考音频路径（可选，直接回车跳过）: "
set /p REF_TEXT="参考文本（可选，直接回车跳过）: "

set CMD=python test_client.py --video "%VIDEO_PATH%" --texts %TEXTS%
if not "%AUDIO_PATH%"=="" set CMD=%CMD% --audio "%AUDIO_PATH%"
if not "%REF_TEXT%"=="" set CMD=%CMD% --ref-text "%REF_TEXT%"

%CMD%
goto end

:interactive
echo.
echo [*] 交互式测试模式
echo.
python test_client.py
goto end

:test_connection
echo.
echo [*] 测试服务器连接
echo.
python -c "import requests; r=requests.get('http://localhost:6006/health'); print(f'服务器状态: {r.json() if r.status_code==200 else r.status_code}')"
goto end

:end
echo.
pause