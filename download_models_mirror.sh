#!/bin/bash

# 使用 HF 镜像站下载模型

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

# 创建目录
mkdir -p models/gpt-sovits
mkdir -p models/musetalk

echo ""
echo "================================================"
echo "    使用 HF-Mirror 镜像站下载 AI 模型"
echo "================================================"
echo ""
print_info "镜像站: https://hf-mirror.com/"
echo ""

# 下载函数
download_from_mirror() {
    local original_url=$1
    local output_file=$2
    local description=$3
    
    # 将 huggingface.co 替换为 hf-mirror.com
    local mirror_url=$(echo "$original_url" | sed 's/huggingface.co/hf-mirror.com/g')
    
    if [ -f "$output_file" ]; then
        print_info "$description 已存在，跳过下载"
        return 0
    fi
    
    print_info "下载 $description..."
    print_info "镜像 URL: $mirror_url"
    
    # 使用 wget 下载，支持断点续传
    if command -v wget >/dev/null 2>&1; then
        if wget -c -O "$output_file" "$mirror_url"; then
            print_info "✓ $description 下载成功"
            return 0
        else
            print_error "✗ $description 下载失败"
            rm -f "$output_file"
            return 1
        fi
    # 如果没有 wget，使用 curl
    elif command -v curl >/dev/null 2>&1; then
        if curl -L -C - -o "$output_file" "$mirror_url"; then
            print_info "✓ $description 下载成功"
            return 0
        else
            print_error "✗ $description 下载失败"
            rm -f "$output_file"
            return 1
        fi
    else
        print_error "未找到 wget 或 curl，请先安装下载工具"
        return 1
    fi
}

# 下载 GPT-SoVITS 模型
print_info "开始下载 GPT-SoVITS 模型..."
cd models/gpt-sovits

# GPT-SoVITS 模型列表
download_from_mirror \
    "https://huggingface.co/lj1995/GPT-SoVITS/resolve/main/gsv-v2final-pretrained/s1bert25hz-5kh-longer-epoch=12-step=369668.ckpt" \
    "s1bert25hz-5kh-longer-epoch=12-step=369668.ckpt" \
    "GPT-SoVITS 主模型 (约 1.9GB)"

download_from_mirror \
    "https://huggingface.co/lj1995/GPT-SoVITS/resolve/main/gsv-v2final-pretrained/s2D2333k.pth" \
    "s2D2333k.pth" \
    "GPT-SoVITS s2D 模型"

download_from_mirror \
    "https://huggingface.co/lj1995/GPT-SoVITS/resolve/main/gsv-v2final-pretrained/s2G2333k.pth" \
    "s2G2333k.pth" \
    "GPT-SoVITS s2G 模型"

cd ../..

# 下载 MuseTalk 模型
echo ""
print_info "开始下载 MuseTalk 模型..."
cd models/musetalk

download_from_mirror \
    "https://huggingface.co/stabilityai/sd-vae-ft-mse/resolve/main/sd-vae-ft-mse.ckpt" \
    "sd-vae-ft-mse.ckpt" \
    "MuseTalk VAE 模型 (约 335MB)"

download_from_mirror \
    "https://huggingface.co/openai/whisper-tiny/resolve/main/pytorch_model.bin" \
    "whisper_tiny.pt" \
    "MuseTalk Whisper 模型 (约 39MB)"

cd ../..

# 检查下载结果
echo ""
echo "================================================"
echo "              下载完成检查"
echo "================================================"
echo ""

# 检查文件
check_files() {
    local dir=$1
    local name=$2
    
    print_info "$name 模型文件："
    if ls -lh "$dir"/*.{ckpt,pth,pt} 2>/dev/null; then
        return 0
    else
        echo "  未找到模型文件"
        return 1
    fi
}

check_files "models/gpt-sovits" "GPT-SoVITS"
echo ""
check_files "models/musetalk" "MuseTalk"

echo ""
echo "================================================"
echo "              下载完成"
echo "================================================"
echo ""
print_info "提示："
echo "  - 使用了 HF-Mirror 镜像站，速度应该会更快"
echo "  - 如果下载中断，可以重新运行脚本继续下载"
echo "  - 所有文件都支持断点续传"

# 如果还是失败，提供备选方案
echo ""
print_warning "如果镜像站也无法下载，可以尝试："
echo ""
echo "1. 使用其他镜像站："
echo "   - https://huggingface.co 替换为其他可用镜像"
echo ""
echo "2. 使用下载工具加速："
echo "   aria2c -x 16 -s 16 -c -o models/gpt-sovits/s2G2333k.pth \\"
echo "     https://hf-mirror.com/lj1995/GPT-SoVITS/resolve/main/gsv-v2final-pretrained/s2G2333k.pth"
echo ""
echo "3. 手动下载后放入对应目录"