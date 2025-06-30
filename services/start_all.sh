#!/bin/bash
echo "启动所有服务..."

# 启动GPT-SoVITS
if [ -f "gpt-sovits/start_service.sh" ]; then
    echo "启动GPT-SoVITS..."
    nohup ./gpt-sovits/start_service.sh > ../logs/gpt-sovits.log 2>&1 &
    echo $! > ../logs/gpt-sovits.pid
fi

# 启动MuseTalk
if [ -f "musetalk/start_service.sh" ]; then
    echo "启动MuseTalk..."
    nohup ./musetalk/start_service.sh > ../logs/musetalk.log 2>&1 &
    echo $! > ../logs/musetalk.pid
fi

# 等待服务启动
sleep 10

# 启动主服务
echo "启动主服务..."
cd ../server
nohup python main.py > ../logs/main.log 2>&1 &
echo $! > ../logs/main.pid

echo "所有服务已启动"
echo "查看日志: tail -f logs/*.log"
