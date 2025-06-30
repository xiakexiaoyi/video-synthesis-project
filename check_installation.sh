#!/bin/bash

# 安装状态检查脚本

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
echo "          安装状态检查"
echo "================================================"
echo ""

# 检查目录结构
print_info "检查目录结构..."
echo ""

# 检查服务目录
echo "服务目录:"
if [ -d "services/gpt-sovits" ]; then
    echo "  ✓ services/gpt-sovits"
    if [ -f "services/gpt-sovits/start_service.sh" ]; then
        echo "    ✓ start_service.sh"
    else
        echo "    ✗ start_service.sh 缺失"
    fi
else
    echo "  ✗ services/gpt-sovits 不存在"
fi

if [ -d "services/musetalk" ]; then
    echo "  ✓ services/musetalk"
    if [ -f "services/musetalk/start_service.sh" ]; then
        echo "    ✓ start_service.sh"
    else
        echo "    ✗ start_service.sh 缺失"
    fi
else
    echo "  ✗ services/musetalk 不存在"
fi

# 检查模型目录
echo ""
echo "模型目录:"
if [ -d "models/gpt-sovits" ]; then
    echo "  ✓ models/gpt-sovits"
    count=$(find models/gpt-sovits -name "*.ckpt" -o -name "*.pth" | wc -l)
    echo "    模型文件: $count 个"
else
    echo "  ✗ models/gpt-sovits 不存在"
fi

if [ -d "models/musetalk" ] || [ -d "models/musetalkV15" ]; then
    echo "  ✓ models/musetalk 或 musetalkV15"
    count1=$(find models/musetalk* -name "*.bin" -o -name "*.pth" 2>/dev/null | wc -l)
    echo "    模型文件: $count1 个"
else
    echo "  ✗ models/musetalk 不存在"
fi

# 检查日志目录
echo ""
echo "日志目录:"
if [ -d "logs" ]; then
    echo "  ✓ logs/"
    ls -la logs/*.log 2>/dev/null || echo "    无日志文件"
else
    echo "  ✗ logs/ 不存在"
fi

# 检查端口
echo ""
print_info "检查端口占用..."
echo ""

check_port() {
    local port=$1
    local service=$2
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
        echo "  ✓ 端口 $port ($service) - 已占用"
        lsof -i :$port | grep LISTEN
    else
        echo "  ✗ 端口 $port ($service) - 未使用"
    fi
}

check_port 6006 "主服务"
check_port 9880 "GPT-SoVITS"
check_port 9881 "MuseTalk"

# 提供建议
echo ""
echo "================================================"
echo "              建议"
echo "================================================"
echo ""

if [ ! -d "services/gpt-sovits" ] || [ ! -d "services/musetalk" ]; then
    print_warning "AI 服务尚未安装"
    echo ""
    echo "请运行以下命令安装："
    echo "  ./install.sh"
    echo "  选择 1 - 完整安装"
    echo ""
    echo "或单独安装服务："
    echo "  ./services/gpt_sovits_setup.sh"
    echo "  ./services/musetalk_setup.sh"
fi

if [ ! -d "models/gpt-sovits" ] || [ -z "$(find models/gpt-sovits -name "*.ckpt" -o -name "*.pth" 2>/dev/null)" ]; then
    print_warning "模型文件缺失"
    echo ""
    echo "请运行以下命令下载模型："
    echo "  ./download_models_mirror.sh      # GPT-SoVITS 模型"
    echo "  ./download_musetalk_models_v2.sh # MuseTalk 模型"
fi

echo ""
print_info "完整安装命令："
echo "  ./install.sh"
echo ""
print_info "查看日志："
echo "  tail -f logs/*.log"