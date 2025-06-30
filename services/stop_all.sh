#!/bin/bash
echo "停止所有服务..."

# 停止主服务
if [ -f "../logs/main.pid" ]; then
    kill $(cat ../logs/main.pid) 2>/dev/null
    rm ../logs/main.pid
fi

# 停止GPT-SoVITS
if [ -f "../logs/gpt-sovits.pid" ]; then
    kill $(cat ../logs/gpt-sovits.pid) 2>/dev/null
    rm ../logs/gpt-sovits.pid
fi

# 停止MuseTalk  
if [ -f "../logs/musetalk.pid" ]; then
    kill $(cat ../logs/musetalk.pid) 2>/dev/null
    rm ../logs/musetalk.pid
fi

echo "所有服务已停止"
