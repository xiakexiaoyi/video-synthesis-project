#!/bin/bash

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "启动所有服务..."
echo "项目根目录: $PROJECT_ROOT"

# 切换到 services 目录
cd "$SCRIPT_DIR"

# 创建日志目录
mkdir -p "$PROJECT_ROOT/logs"

# 启动GPT-SoVITS
if [ -f "gpt-sovits/start_service.sh" ]; then
    echo "启动GPT-SoVITS..."
    cd gpt-sovits
    nohup ./start_service.sh > "$PROJECT_ROOT/logs/gpt-sovits.log" 2>&1 &
    echo $! > "$PROJECT_ROOT/logs/gpt-sovits.pid"
    cd ..
else
    echo "警告: 未找到 GPT-SoVITS 启动脚本"
fi

# 启动MuseTalk
if [ -f "musetalk/start_service.sh" ]; then
    echo "启动MuseTalk..."
    cd musetalk
    nohup ./start_service.sh > "$PROJECT_ROOT/logs/musetalk.log" 2>&1 &
    echo $! > "$PROJECT_ROOT/logs/musetalk.pid"
    cd ..
else
    echo "警告: 未找到 MuseTalk 启动脚本"
fi

# 等待服务启动
echo "等待 AI 服务启动..."
sleep 10

# 服务启动完成
echo ""
echo "AI 服务已启动"
echo "查看日志:"
echo "  - GPT-SoVITS: tail -f $PROJECT_ROOT/logs/gpt-sovits.log"
echo "  - MuseTalk: tail -f $PROJECT_ROOT/logs/musetalk.log"
# End of script
