#!/bin/bash

# GPT-SoVITS 服务启动脚本

cd "$(dirname "$0")"

# 检查虚拟环境
if [ ! -d "GPT-SoVITS/venv" ]; then
    echo "错误: 未找到虚拟环境，请先运行安装脚本"
    echo "运行: ../gpt_sovits_setup.sh"
    exit 1
fi

# 检查 API 脚本
if [ ! -f "start_api.py" ]; then
    echo "错误: 未找到 start_api.py"
    echo "GPT-SoVITS 可能未正确安装"
    exit 1
fi

echo "启动 GPT-SoVITS 服务..."
source GPT-SoVITS/venv/bin/activate
python start_api.py