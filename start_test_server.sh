#!/bin/bash

# 测试服务器 - 不依赖 AI 服务

echo ""
echo "================================================"
echo "          启动测试服务器"
echo "================================================"
echo ""
echo "警告：这将启动一个测试模式的服务器"
echo "GPT-SoVITS 和 MuseTalk 将使用模拟响应"
echo ""

# 设置环境变量为测试模式
export TEST_MODE=true
export MOCK_AI_SERVICES=true

# 创建必要目录
mkdir -p logs
mkdir -p temp
mkdir -p output

# 启动主服务
cd server

# 安装依赖（如果需要）
if ! python3 -c "import fastapi" 2>/dev/null; then
    echo "安装依赖..."
    pip3 install -r requirements.txt
fi

# 启动服务
echo "启动测试服务器..."
python3 -c "
import os
os.environ['TEST_MODE'] = 'true'
os.environ['MOCK_AI_SERVICES'] = 'true'
import main
" 2>&1 | tee ../logs/test_server.log