#!/bin/bash

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "停止所有服务..."

# 停止GPT-SoVITS
if [ -f "$PROJECT_ROOT/logs/gpt-sovits.pid" ]; then
    PID=$(cat "$PROJECT_ROOT/logs/gpt-sovits.pid")
    if kill -0 $PID 2>/dev/null; then
        echo "停止 GPT-SoVITS (PID: $PID)..."
        kill $PID
        rm "$PROJECT_ROOT/logs/gpt-sovits.pid"
    else
        echo "GPT-SoVITS 未运行"
        rm "$PROJECT_ROOT/logs/gpt-sovits.pid"
    fi
else
    echo "未找到 GPT-SoVITS PID 文件"
fi

# 停止MuseTalk  
if [ -f "$PROJECT_ROOT/logs/musetalk.pid" ]; then
    PID=$(cat "$PROJECT_ROOT/logs/musetalk.pid")
    if kill -0 $PID 2>/dev/null; then
        echo "停止 MuseTalk (PID: $PID)..."
        kill $PID
        rm "$PROJECT_ROOT/logs/musetalk.pid"
    else
        echo "MuseTalk 未运行"
        rm "$PROJECT_ROOT/logs/musetalk.pid"
    fi
else
    echo "未找到 MuseTalk PID 文件"
fi

echo "AI 服务已停止"