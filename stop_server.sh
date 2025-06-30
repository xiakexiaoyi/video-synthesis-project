#!/bin/bash

# 视频合成服务停止脚本

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 打印带颜色的消息
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
echo "          停止视频合成服务"
echo "================================================"
echo ""

# 停止主服务
if [ -f "logs/main.pid" ]; then
    PID=$(cat logs/main.pid)
    if kill -0 $PID 2>/dev/null; then
        print_info "停止主服务 (PID: $PID)..."
        kill $PID
        rm -f logs/main.pid
        print_info "✓ 主服务已停止"
    else
        print_warning "主服务未运行"
        rm -f logs/main.pid
    fi
else
    print_warning "未找到主服务 PID 文件"
fi

# 停止真实服务
if [ -f "services/stop_all.sh" ]; then
    print_info "停止 AI 服务..."
    ./services/stop_all.sh
fi

# 检查端口是否已释放
sleep 2
echo ""
print_info "检查端口状态..."

# 检查端口是否被占用的函数
check_port() {
    local port=$1
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# 检查各个端口
if check_port 6006; then
    print_warning "端口 6006 仍被占用"
    lsof -i :6006
else
    print_info "✓ 端口 6006 已释放"
fi

if check_port 9880; then
    print_warning "端口 9880 仍被占用"
    lsof -i :9880
else
    print_info "✓ 端口 9880 已释放"
fi

if check_port 9881; then
    print_warning "端口 9881 仍被占用"
    lsof -i :9881
else
    print_info "✓ 端口 9881 已释放"
fi

echo ""
echo "================================================"
echo "              服务停止完成"
echo "================================================"
echo ""
print_info "提示：可以运行 ./start_server.sh 重新启动服务"