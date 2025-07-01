#!/bin/bash
cd "$(dirname "$0")"

# 检查是否有虚拟环境
if [ -d "MuseTalk/venv" ]; then
    echo "激活虚拟环境..."
    source MuseTalk/venv/bin/activate
fi

# 启动API
echo "启动MuseTalk API..."
python3 start_api.py