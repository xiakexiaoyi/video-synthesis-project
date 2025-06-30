#!/bin/bash

# 使用 aria2 + HF-Mirror 镜像站高速下载

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
    print_error "未安装 aria2，正在尝试使用 wget..."
    exec ./download_models_mirror.sh
fi

# 创建目录
mkdir -p models/gpt-sovits
mkdir -p models/musetalk

echo ""
echo "================================================"
echo "  使用 aria2 + HF-Mirror 镜像站高速下载"
echo "================================================"
echo ""
print_info "使用 16 线程并行下载，速度更快！"
echo ""

# aria2 镜像下载函数
download_with_aria2_mirror() {
    local original_url=$1
    local output_dir=$2
    local output_file=$3
    local description=$4
    
    # 替换为镜像站
    local mirror_url=$(echo "$original_url" | sed 's/huggingface.co/hf-mirror.com/g')
    
    cd "$output_dir"
    
    if [ -f "$output_file" ]; then
        print_info "$description 已存在，跳过"
        cd - > /dev/null
        return 0
    fi
    
    print_info "下载 $description..."
    echo "  镜像 URL: $mirror_url"
    
    if aria2c \
        -x 16 \
        -s 16 \
        -k 1M \
        -j 1 \
        --file-allocation=none \
        --console-log-level=warn \
        --summary-interval=1 \
        --allow-overwrite=true \
        --auto-file-renaming=false \
        -o "$output_file" \
        "$mirror_url"; then
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

download_with_aria2_mirror \
    "https://huggingface.co/lj1995/GPT-SoVITS/resolve/main/gsv-v2final-pretrained/s1bert25hz-5kh-longer-epoch=12-step=369668.ckpt" \
    "models/gpt-sovits" \
    "s1bert25hz-5kh-longer-epoch=12-step=369668.ckpt" \
    "GPT-SoVITS 主模型 (1.9GB)"

download_with_aria2_mirror \
    "https://huggingface.co/lj1995/GPT-SoVITS/resolve/main/gsv-v2final-pretrained/s2D2333k.pth" \
    "models/gpt-sovits" \
    "s2D2333k.pth" \
    "GPT-SoVITS s2D 模型"

download_with_aria2_mirror \
    "https://huggingface.co/lj1995/GPT-SoVITS/resolve/main/gsv-v2final-pretrained/s2G2333k.pth" \
    "models/gpt-sovits" \
    "s2G2333k.pth" \
    "GPT-SoVITS s2G 模型"

# MuseTalk 模型
echo ""
print_info "下载 MuseTalk 模型..."

download_with_aria2_mirror \
    "https://huggingface.co/stabilityai/sd-vae-ft-mse/resolve/main/sd-vae-ft-mse.ckpt" \
    "models/musetalk" \
    "sd-vae-ft-mse.ckpt" \
    "MuseTalk VAE 模型 (335MB)"

download_with_aria2_mirror \
    "https://huggingface.co/openai/whisper-tiny/resolve/main/pytorch_model.bin" \
    "models/musetalk" \
    "whisper_tiny.pt" \
    "MuseTalk Whisper 模型 (39MB)"

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
print_info "使用了 aria2 + HF-Mirror，下载速度应该很快！"