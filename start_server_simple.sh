#!/bin/bash

# 简化的服务启动脚本 - 只启动主服务

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

echo ""
echo "================================================"
echo "          简化服务启动"
echo "================================================"
echo ""

# 创建必要目录
mkdir -p logs
mkdir -p temp
mkdir -p output

# 检查并安装主服务依赖
print_info "检查主服务依赖..."
cd server
if ! python3 -c "import fastapi" 2>/dev/null; then
    print_warning "安装服务端依赖..."
    pip3 install -r requirements.txt
fi
cd ..

# 停止旧的主服务
if [ -f "logs/main.pid" ]; then
    OLD_PID=$(cat logs/main.pid)
    if kill -0 $OLD_PID 2>/dev/null; then
        print_info "停止旧服务 (PID: $OLD_PID)"
        kill $OLD_PID
        sleep 2
    fi
fi

# 启动主服务
print_info "启动主服务..."
cd server
nohup python3 main.py > ../logs/main.log 2>&1 &
echo $! > ../logs/main.pid
cd ..

# 等待服务启动
print_info "等待服务启动..."
sleep 5

# 检查服务状态
if curl -s http://localhost:6006/health > /dev/null 2>&1; then
    print_info "✓ 主服务已启动 (端口 6006)"
else
    print_error "✗ 主服务启动失败"
    echo ""
    echo "查看日志："
    echo "  tail -f logs/main.log"
    exit 1
fi

echo ""
echo "================================================"
echo "              服务已启动"
echo "================================================"
echo ""
echo "主服务地址: http://localhost:6006"
echo "API 文档: http://localhost:6006/docs"
echo ""
echo "注意："
echo "  - 这是简化版启动，只启动了主服务"
echo "  - GPT-SoVITS 和 MuseTalk 需要单独启动"
echo ""
echo "查看日志: tail -f logs/main.log"
echo "停止服务: ./stop_server.sh"