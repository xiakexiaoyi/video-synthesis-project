#!/bin/bash

# 使用 aria2 高速下载模型

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

# 检查 aria2
if ! command -v aria2c >/dev/null 2>&1; then
    print_error "未安装 aria2，请先安装："
    echo "  Ubuntu/Debian: sudo apt-get install aria2"
    echo "  CentOS/RHEL: sudo yum install aria2"
    echo "  macOS: brew install aria2"
    exit 1
fi

# 创建目录
mkdir -p models/gpt-sovits
mkdir -p models/musetalk

echo ""
echo "================================================"
echo "      使用 aria2 高速下载 AI 模型"
echo "================================================"
echo ""

# aria2 下载函数
download_with_aria2() {
    local url=$1
    local output_dir=$2
    local output_file=$3
    local description=$4
    
    cd "$output_dir"
    
    if [ -f "$output_file" ]; then
        print_info "$description 已存在，跳过"
        cd - > /dev/null
        return 0
    fi
    
    print_info "下载 $description..."
    
    # aria2 参数说明：
    # -x 16: 最多使用16个连接
    # -s 16: 将文件分成16段
    # -k 1M: 每段最小1MB
    # -j 1: 同时下载1个文件
    # --file-allocation=none: 不预分配磁盘空间（更快）
    # --console-log-level=warn: 只显示警告和错误
    # --summary-interval=1: 每秒更新一次进度
    
    if aria2c \
        -x 16 \
        -s 16 \
        -k 1M \
        -j 1 \
        --file-allocation=none \
        --console-log-level=warn \
        --summary-interval=1 \
        -o "$output_file" \
        "$url"; then
        print_info "✓ $description 下载成功"
    else
        print_error "✗ $description 下载失败"
        cd - > /dev/null
        return 1
    fi
    
    cd - > /dev/null
}

# GPT-SoVITS 模型
print_info "下载 GPT-SoVITS 模型..."

download_with_aria2 \
    "https://huggingface.co/lj1995/GPT-SoVITS/resolve/main/gsv-v2final-pretrained/s1bert25hz-5kh-longer-epoch=12-step=369668.ckpt" \
    "models/gpt-sovits" \
    "s1bert25hz-5kh-longer-epoch=12-step=369668.ckpt" \
    "GPT-SoVITS 主模型 (1.9GB)"

download_with_aria2 \
    "https://huggingface.co/lj1995/GPT-SoVITS/resolve/main/gsv-v2final-pretrained/s2D2333k.pth" \
    "models/gpt-sovits" \
    "s2D2333k.pth" \
    "GPT-SoVITS s2D 模型"

download_with_aria2 \
    "https://huggingface.co/lj1995/GPT-SoVITS/resolve/main/gsv-v2final-pretrained/s2G2333k.pth" \
    "models/gpt-sovits" \
    "s2G2333k.pth" \
    "GPT-SoVITS s2G 模型"

# MuseTalk 模型
echo ""
print_info "下载 MuseTalk 模型..."

download_with_aria2 \
    "https://huggingface.co/stabilityai/sd-vae-ft-mse/resolve/main/sd-vae-ft-mse.ckpt" \
    "models/musetalk" \
    "sd-vae-ft-mse.ckpt" \
    "MuseTalk VAE 模型"

download_with_aria2 \
    "https://huggingface.co/openai/whisper-tiny/resolve/main/pytorch_model.bin" \
    "models/musetalk" \
    "whisper_tiny.pt" \
    "MuseTalk Whisper 模型"

# 显示结果
echo ""
echo "================================================"
echo "              下载完成"
echo "================================================"
echo ""

print_info "已下载的模型文件："
echo ""
echo "GPT-SoVITS:"
ls -lh models/gpt-sovits/*.{ckpt,pth} 2>/dev/null || echo "  无文件"
echo ""
echo "MuseTalk:"
ls -lh models/musetalk/*.{ckpt,pt} 2>/dev/null || echo "  无文件"

echo ""
print_info "提示：aria2 支持断点续传，如果下载中断可以重新运行脚本继续下载"