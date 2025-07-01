#!/bin/bash
cd "$(dirname "$0")"

# 检查是否有虚拟环境
if [ -d "GPT-SoVITS/venv" ]; then
    echo "激活虚拟环境..."
    source GPT-SoVITS/venv/bin/activate
fi

# 启动API
echo "启动GPT-SoVITS API..."
python3 start_api.py