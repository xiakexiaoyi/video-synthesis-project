#!/bin/bash

# MuseTalk 模型专用下载脚本

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

# 创建目录结构
print_info "创建 MuseTalk 模型目录..."
mkdir -p models/musetalk
mkdir -p models/dwpose
mkdir -p models/face-parse-bisent
mkdir -p models/sd-vae-ft-mse
mkdir -p models/whisper

echo ""
echo "================================================"
echo "          MuseTalk 模型下载工具"
echo "================================================"
echo ""

# 使用镜像下载函数
download_with_mirror() {
    local url=$1
    local output_file=$2
    local description=$3
    local use_mirror=${4:-true}
    
    if [ -f "$output_file" ]; then
        print_info "$description 已存在，跳过下载"
        return 0
    fi
    
    # 如果使用镜像，替换域名
    if [ "$use_mirror" = true ] && [[ "$url" == *"huggingface.co"* ]]; then
        local mirror_url=$(echo "$url" | sed 's/huggingface.co/hf-mirror.com/g')
        print_info "下载 $description (使用镜像)..."
        print_info "URL: $mirror_url"
        
        if wget -c -O "$output_file" "$mirror_url"; then
            print_info "✓ $description 下载成功"
            return 0
        else
            print_warning "镜像下载失败，尝试原始链接..."
        fi
    fi
    
    # 使用原始链接
    print_info "下载 $description..."
    print_info "URL: $url"
    
    if wget -c -O "$output_file" "$url"; then
        print_info "✓ $description 下载成功"
        return 0
    else
        print_error "✗ $description 下载失败"
        return 1
    fi
}

# 下载主要 MuseTalk 模型
print_info "下载 MuseTalk 主模型..."
cd models/musetalk

download_with_mirror \
    "https://huggingface.co/TMElyralab/MuseTalk/resolve/main/pytorch_model.bin" \
    "pytorch_model.bin" \
    "MuseTalk 主模型"

download_with_mirror \
    "https://huggingface.co/TMElyralab/MuseTalk/resolve/main/musetalk.json" \
    "musetalk.json" \
    "MuseTalk 配置文件"

cd ../..

# 下载 SD-VAE-FT-MSE 模型
print_info "下载 SD-VAE-FT-MSE 模型..."
cd models/sd-vae-ft-mse

download_with_mirror \
    "https://huggingface.co/stabilityai/sd-vae-ft-mse/resolve/main/diffusion_pytorch_model.bin" \
    "diffusion_pytorch_model.bin" \
    "SD-VAE 模型"

download_with_mirror \
    "https://huggingface.co/stabilityai/sd-vae-ft-mse/resolve/main/config.json" \
    "config.json" \
    "SD-VAE 配置文件"

cd ../..

# 下载 Whisper 模型
print_info "下载 Whisper 模型..."
cd models/whisper

# Whisper 使用官方链接，不使用镜像
download_with_mirror \
    "https://openaipublic.azureedge.net/main/whisper/models/65147644a518d12f04e32d6f3b26facc3f8dd46e5390956a9424a650c0ce22b9/tiny.pt" \
    "tiny.pt" \
    "Whisper Tiny 模型" \
    false

cd ../..

# 下载 DWPose 模型
print_info "下载 DWPose 模型..."
cd models/dwpose

download_with_mirror \
    "https://huggingface.co/yzd-v/DWPose/resolve/main/dw-ll_ucoco_384.pth" \
    "dw-ll_ucoco_384.pth" \
    "DWPose 模型"

cd ../..

# 下载 Face Parsing 模型
print_info "下载 Face Parsing 模型..."
cd models/face-parse-bisent

# ResNet18 使用 PyTorch 官方链接
download_with_mirror \
    "https://download.pytorch.org/models/resnet18-5c106cde.pth" \
    "resnet18-5c106cde.pth" \
    "ResNet18 预训练模型" \
    false

# Face parsing 模型需要特殊处理
if [ ! -f "79999_iter.pth" ]; then
    print_warning "Face parsing 模型 (79999_iter.pth) 需要手动下载"
    echo "  请访问: https://github.com/zllrunning/face-parsing.PyTorch"
    echo "  或联系项目维护者获取此文件"
fi

cd ../..

# 检查下载结果
echo ""
echo "================================================"
echo "              下载完成检查"
echo "================================================"
echo ""

print_info "MuseTalk 模型文件："
echo ""

# 检查各个目录的文件
check_dir() {
    local dir=$1
    local name=$2
    echo "$name:"
    if ls -la "$dir" 2>/dev/null | grep -v "^total" | grep -v "^d"; then
        return 0
    else
        echo "  [空目录]"
        return 1
    fi
    echo ""
}

check_dir "models/musetalk" "主模型"
check_dir "models/sd-vae-ft-mse" "SD-VAE"
check_dir "models/whisper" "Whisper"
check_dir "models/dwpose" "DWPose"
check_dir "models/face-parse-bisent" "Face Parsing"

echo ""
echo "================================================"
echo "              下载完成"
echo "================================================"
echo ""

# 如果有文件缺失，提供帮助
if [ ! -f "models/face-parse-bisent/79999_iter.pth" ]; then
    print_warning "部分模型需要手动下载："
    echo ""
    echo "1. Face parsing 模型 (79999_iter.pth):"
    echo "   - 访问 https://github.com/zllrunning/face-parsing.PyTorch"
    echo "   - 下载后放到 models/face-parse-bisent/ 目录"
    echo ""
fi

print_info "提示："
echo "  - 大部分模型已使用 HF-Mirror 镜像加速"
echo "  - 如果下载失败，可以手动访问对应的 HuggingFace 页面"
echo "  - 参考: https://github.com/TMElyralab/MuseTalk"