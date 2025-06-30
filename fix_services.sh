#!/bin/bash

# 修复服务安装脚本

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
echo "          修复服务安装"
echo "================================================"
echo ""

# 检查是否需要完整安装
need_full_install=false

if [ ! -f "services/gpt-sovits/start_api.py" ]; then
    print_warning "GPT-SoVITS API 脚本缺失"
    need_full_install=true
fi

if [ ! -f "services/musetalk/start_api_simple.py" ]; then
    print_warning "MuseTalk API 脚本缺失"
    need_full_install=true
fi

if [ "$need_full_install" = true ]; then
    echo ""
    echo "需要重新运行安装脚本来创建 API 服务文件"
    echo ""
    echo "选项："
    echo "1. 重新安装 GPT-SoVITS"
    echo "2. 重新安装 MuseTalk"
    echo "3. 安装两个服务"
    echo "4. 跳过，只启动主服务"
    echo ""
    read -p "请选择 [1-4]: " choice
    
    case $choice in
        1)
            print_info "重新安装 GPT-SoVITS..."
            ./services/gpt_sovits_setup.sh
            ;;
        2)
            print_info "重新安装 MuseTalk..."
            ./services/musetalk_setup.sh
            ;;
        3)
            print_info "安装两个服务..."
            ./services/gpt_sovits_setup.sh
            ./services/musetalk_setup.sh
            ;;
        4)
            print_info "跳过 AI 服务，只启动主服务..."
            ;;
    esac
else
    print_info "服务文件已存在"
fi

# 确保启动脚本存在
if [ ! -f "services/gpt-sovits/start_service.sh" ]; then
    print_error "GPT-SoVITS 启动脚本仍然缺失"
    print_info "请运行: ./services/gpt_sovits_setup.sh"
fi

if [ ! -f "services/musetalk/start_service.sh" ]; then
    print_error "MuseTalk 启动脚本仍然缺失"
    print_info "请运行: ./services/musetalk_setup.sh"
fi

echo ""
echo "================================================"
echo "              下一步"
echo "================================================"
echo ""
echo "1. 启动所有服务："
echo "   ./start_server.sh"
echo ""
echo "2. 或只启动主服务："
echo "   ./start_server_simple.sh"
echo ""
echo "3. 检查安装状态："
echo "   ./check_installation.sh"