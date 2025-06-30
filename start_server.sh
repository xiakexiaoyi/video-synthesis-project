#!/bin/bash

# 视频合成服务智能启动脚本
# 自动检测环境并根据需要安装服务

set -e

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

# 检查命令是否存在
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# 检查端口是否被占用
check_port() {
    local port=$1
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# 等待服务启动
wait_for_service() {
    local url=$1
    local service_name=$2
    local max_attempts=30
    local attempt=0
    
    print_info "等待 $service_name 启动..."
    while [ $attempt -lt $max_attempts ]; do
        if curl -s "$url" > /dev/null 2>&1; then
            print_info "✓ $service_name 已启动"
            return 0
        fi
        sleep 1
        attempt=$((attempt + 1))
    done
    
    print_error "✗ $service_name 启动超时"
    return 1
}

# 启动标题
echo ""
echo "================================================"
echo "          视频合成服务 - 智能启动"
echo "================================================"
echo ""

# 检查基础环境
print_info "检查基础环境..."

if ! command_exists python3; then
    print_error "未找到 Python3，请先安装 Python 3.8+"
    exit 1
fi

if ! command_exists pip3; then
    print_error "未找到 pip3，请先安装 pip"
    exit 1
fi

# 创建必要的目录
mkdir -p logs
mkdir -p temp
mkdir -p output
mkdir -p models

# 检查服务端依赖
print_info "检查服务端依赖..."
cd server
if ! python3 -c "import fastapi" 2>/dev/null; then
    print_warning "服务端依赖未安装，正在安装..."
    pip3 install -r requirements.txt
    print_info "✓ 服务端依赖安装完成"
else
    print_info "✓ 服务端依赖已安装"
fi
cd ..

# 检查 GPT-SoVITS 和 MuseTalk 服务
print_info "检查 AI 服务安装状态..."

# 检查是否已安装真实服务
if [ -d "services/gpt-sovits" ] && [ -d "services/musetalk" ]; then
    print_info "✓ 检测到已安装 GPT-SoVITS 和 MuseTalk"
else
    print_warning "未检测到 GPT-SoVITS 和 MuseTalk 安装"
    
    # 询问是否安装
    echo ""
    echo "需要安装 AI 服务才能运行（需要 GPU，下载约 10GB）"
    read -p "是否现在安装？[Y/n] " -n 1 -r
    echo ""
    
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        print_info "开始安装 AI 服务..."
        if [ -f "install.sh" ]; then
            ./install.sh
            if [ $? -eq 0 ]; then
                print_info "✓ AI 服务安装完成"
            else
                print_error "AI 服务安装失败"
                exit 1
            fi
        else
            print_error "找不到 install.sh 脚本"
            exit 1
        fi
    else
        print_error "需要安装 AI 服务才能运行"
        print_info "请运行 ./install.sh 安装服务"
        exit 1
    fi
fi

# 停止可能正在运行的服务
print_info "检查并停止旧服务..."

# 停止主服务
if [ -f "logs/main.pid" ]; then
    OLD_PID=$(cat logs/main.pid)
    if kill -0 $OLD_PID 2>/dev/null; then
        print_info "停止旧的主服务 (PID: $OLD_PID)"
        kill $OLD_PID
        sleep 2
    fi
fi

# 启动服务
print_info "启动 AI 服务..."

# 启动真实服务
if [ -f "services/start_all.sh" ]; then
    ./services/start_all.sh
    
    # 等待真实服务启动
    wait_for_service "http://localhost:9880" "GPT-SoVITS"
    wait_for_service "http://localhost:9881" "MuseTalk"
else
    print_error "找不到 services/start_all.sh"
    exit 1
fi

# 启动主服务
print_info "启动主服务..."
cd server
nohup python3 main.py > ../logs/main.log 2>&1 &
echo $! > ../logs/main.pid
cd ..

# 等待主服务启动
wait_for_service "http://localhost:6006/health" "主服务"

# 显示服务状态
echo ""
echo "================================================"
echo "              服务状态检查"
echo "================================================"

# 检查各个服务
if curl -s http://localhost:6006/health > /dev/null 2>&1; then
    print_info "✓ 主服务 (端口 6006) - 运行中"
else
    print_error "✗ 主服务 (端口 6006) - 未运行"
fi

if curl -s http://localhost:9880 > /dev/null 2>&1; then
    print_info "✓ GPT-SoVITS (端口 9880) - 运行中"
else
    print_error "✗ GPT-SoVITS (端口 9880) - 未运行"
fi

if curl -s http://localhost:9881 > /dev/null 2>&1; then
    print_info "✓ MuseTalk (端口 9881) - 运行中"
else
    print_error "✗ MuseTalk (端口 9881) - 未运行"
fi

# 显示使用说明
echo ""
echo "================================================"
echo "              服务已启动！"
echo "================================================"
echo ""
echo "服务地址："
echo "  - 主服务: http://localhost:6006"
echo "  - API文档: http://localhost:6006/docs"
echo ""
echo "下一步操作："
echo "  1. 启动客户端: ./start_client.sh"
echo "  2. 或在 Windows 上双击: Windows用户点我启动.bat"
echo ""
echo "常用命令："
echo "  - 查看日志: tail -f logs/*.log"
echo "  - 停止服务: ./stop_server.sh"
echo "  - 测试服务: python test_client.py --quick"
echo ""
print_info "提示：服务将在后台持续运行"