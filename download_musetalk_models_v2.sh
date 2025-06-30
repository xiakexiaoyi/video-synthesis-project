#!/bin/bash

# MuseTalk 模型下载脚本 v2 - 修正版

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
mkdir -p models/musetalkV15
mkdir -p models/dwpose
mkdir -p models/face-parse-bisent
mkdir -p models/sd-vae-ft-mse
mkdir -p models/whisper

echo ""
echo "================================================"
echo "       MuseTalk 模型下载工具 v2"
echo "================================================"
echo ""

# 选择版本
echo "请选择 MuseTalk 版本："
echo "1. MuseTalk v1.0 (经典版本)"
echo "2. MuseTalk v1.5 (推荐，性能更好)"
echo ""
read -p "请选择 [1-2] (默认: 2): " version_choice
version_choice=${version_choice:-2}

# 下载函数
download_file() {
    local url=$1
    local output_file=$2
    local description=$3
    
    if [ -f "$output_file" ]; then
        print_info "$description 已存在，跳过下载"
        return 0
    fi
    
    # 尝试使用镜像
    local mirror_url=$(echo "$url" | sed 's/huggingface.co/hf-mirror.com/g')
    
    print_info "下载 $description..."
    
    # 先尝试镜像
    if wget -c -O "$output_file" "$mirror_url" 2>/dev/null; then
        print_info "✓ $description 下载成功 (镜像)"
        return 0
    fi
    
    # 镜像失败，尝试原始链接
    print_warning "镜像下载失败，尝试原始链接..."
    if wget -c -O "$output_file" "$url"; then
        print_info "✓ $description 下载成功"
        return 0
    else
        print_error "✗ $description 下载失败"
        rm -f "$output_file"
        return 1
    fi
}

# 下载 MuseTalk 主模型
if [ "$version_choice" = "1" ]; then
    print_info "下载 MuseTalk v1.0 模型..."
    cd models/musetalk
    
    download_file \
        "https://huggingface.co/TMElyralab/MuseTalk/resolve/main/musetalk/pytorch_model.bin" \
        "pytorch_model.bin" \
        "MuseTalk v1.0 主模型 (3.4GB)"
    
    download_file \
        "https://huggingface.co/TMElyralab/MuseTalk/resolve/main/musetalk/musetalk.json" \
        "musetalk.json" \
        "MuseTalk v1.0 配置文件"
else
    print_info "下载 MuseTalk v1.5 模型..."
    cd models/musetalkV15
    
    download_file \
        "https://huggingface.co/TMElyralab/MuseTalk/resolve/main/musetalkV15/unet.pth" \
        "unet.pth" \
        "MuseTalk v1.5 主模型 (3.4GB)"
    
    download_file \
        "https://huggingface.co/TMElyralab/MuseTalk/resolve/main/musetalkV15/musetalk.json" \
        "musetalk.json" \
        "MuseTalk v1.5 配置文件"
fi

cd ../..

# 下载 SD-VAE-FT-MSE 模型
print_info "下载 SD-VAE-FT-MSE 模型..."
cd models/sd-vae-ft-mse

download_file \
    "https://huggingface.co/stabilityai/sd-vae-ft-mse/resolve/main/diffusion_pytorch_model.bin" \
    "diffusion_pytorch_model.bin" \
    "SD-VAE 模型 (335MB)"

download_file \
    "https://huggingface.co/stabilityai/sd-vae-ft-mse/resolve/main/config.json" \
    "config.json" \
    "SD-VAE 配置文件"

cd ../..

# 下载 Whisper 模型
print_info "下载 Whisper 模型..."
cd models/whisper

download_file \
    "https://openaipublic.azureedge.net/main/whisper/models/65147644a518d12f04e32d6f3b26facc3f8dd46e5390956a9424a650c0ce22b9/tiny.pt" \
    "tiny.pt" \
    "Whisper Tiny 模型 (39MB)"

cd ../..

# 下载 DWPose 模型
print_info "下载 DWPose 模型..."
cd models/dwpose

download_file \
    "https://huggingface.co/yzd-v/DWPose/resolve/main/dw-ll_ucoco_384.pth" \
    "dw-ll_ucoco_384.pth" \
    "DWPose 模型 (约280MB)"

cd ../..

# 下载 Face Parsing 模型
print_info "下载 Face Parsing 模型..."
cd models/face-parse-bisent

# ResNet18 预训练模型
download_file \
    "https://download.pytorch.org/models/resnet18-5c106cde.pth" \
    "resnet18-5c106cde.pth" \
    "ResNet18 预训练模型 (45MB)"

# Face parsing 模型 - 尝试从备用源下载
if [ ! -f "79999_iter.pth" ]; then
    print_warning "尝试下载 Face parsing 模型..."
    
    # 尝试从 Google Drive (需要手动确认)
    echo ""
    echo "Face parsing 模型 (79999_iter.pth) 需要手动下载："
    echo ""
    echo "选项 1: 从 Google Drive 下载"
    echo "  链接: https://drive.google.com/open?id=154JgKpzCPW82qINcVieuPH3fZ2e0P812"
    echo ""
    echo "选项 2: 从 face-parsing.PyTorch 项目获取"
    echo "  链接: https://github.com/zllrunning/face-parsing.PyTorch"
    echo ""
    echo "下载后将文件放到: $(pwd)/79999_iter.pth"
fi

cd ../..

# 检查下载结果
echo ""
echo "================================================"
echo "              下载完成检查"
echo "================================================"
echo ""

# 检查函数
check_file() {
    local file=$1
    local desc=$2
    if [ -f "$file" ]; then
        local size=$(ls -lh "$file" | awk '{print $5}')
        echo "✓ $desc ($size)"
        return 0
    else
        echo "✗ $desc - 缺失"
        return 1
    fi
}

print_info "模型文件状态："
echo ""

if [ "$version_choice" = "1" ]; then
    echo "MuseTalk v1.0:"
    check_file "models/musetalk/pytorch_model.bin" "主模型"
    check_file "models/musetalk/musetalk.json" "配置文件"
else
    echo "MuseTalk v1.5:"
    check_file "models/musetalkV15/unet.pth" "主模型"
    check_file "models/musetalkV15/musetalk.json" "配置文件"
fi

echo ""
echo "SD-VAE:"
check_file "models/sd-vae-ft-mse/diffusion_pytorch_model.bin" "VAE模型"
check_file "models/sd-vae-ft-mse/config.json" "配置文件"

echo ""
echo "其他模型:"
check_file "models/whisper/tiny.pt" "Whisper"
check_file "models/dwpose/dw-ll_ucoco_384.pth" "DWPose"
check_file "models/face-parse-bisent/resnet18-5c106cde.pth" "ResNet18"
check_file "models/face-parse-bisent/79999_iter.pth" "Face Parsing"

echo ""
echo "================================================"
echo "              下载完成"
echo "================================================"
echo ""

# 统计
total_files=0
missing_files=0

for dir in models/musetalk models/musetalkV15 models/sd-vae-ft-mse models/whisper models/dwpose models/face-parse-bisent; do
    if [ -d "$dir" ]; then
        count=$(find "$dir" -type f | wc -l)
        total_files=$((total_files + count))
    fi
done

if [ ! -f "models/face-parse-bisent/79999_iter.pth" ]; then
    missing_files=$((missing_files + 1))
fi

print_info "总计: $total_files 个文件已下载"

if [ $missing_files -gt 0 ]; then
    print_warning "有 $missing_files 个文件需要手动下载"
else
    print_info "所有必需文件已就绪！"
fi

echo ""
print_info "提示："
echo "  - 如果下载失败，可以使用 aria2 重试"
echo "  - 参考: https://github.com/TMElyralab/MuseTalk"
echo "  - 镜像站: https://hf-mirror.com/"