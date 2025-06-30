#!/bin/bash

# MuseTalk 服务启动脚本

cd "$(dirname "$0")"

# 检查虚拟环境
if [ ! -d "MuseTalk/venv" ]; then
    echo "错误: 未找到虚拟环境，请先运行安装脚本"
    echo "运行: ../musetalk_setup.sh"
    exit 1
fi

# 检查 API 脚本
if [ ! -f "start_api_simple.py" ]; then
    echo "错误: 未找到 start_api_simple.py"
    echo "MuseTalk 可能未正确安装"
    exit 1
fi

echo "启动 MuseTalk 服务..."
source MuseTalk/venv/bin/activate
export PYTHONPATH="$PWD/MuseTalk:$PYTHONPATH"
python start_api_simple.py