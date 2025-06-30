#!/bin/bash

# 模型下载脚本 - 支持多种下载方式

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 打印函数
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# 创建模型目录
MODEL_BASE_DIR="$(dirname "$0")/models"
GPT_SOVITS_MODEL_DIR="$MODEL_BASE_DIR/gpt-sovits"
MUSETALK_MODEL_DIR="$MODEL_BASE_DIR/musetalk"

mkdir -p "$GPT_SOVITS_MODEL_DIR"
mkdir -p "$MUSETALK_MODEL_DIR"

echo ""
echo "================================================"
echo "          AI 模型下载工具"
echo "================================================"
echo ""

# 检查下载工具
check_download_tools() {
    if command -v wget >/dev/null 2>&1; then
        DOWNLOAD_CMD="wget -c"
        return 0
    elif command -v curl >/dev/null 2>&1; then
        DOWNLOAD_CMD="curl -L -C - -o"
        return 0
    else
        print_error "未找到 wget 或 curl，请先安装下载工具"
        return 1
    fi
}

# 下载文件函数
download_file() {
    local url=$1
    local output_path=$2
    local description=$3
    
    if [ -f "$output_path" ]; then
        print_info "$description 已存在，跳过下载"
        return 0
    fi
    
    print_info "下载 $description..."
    print_info "URL: $url"
    print_info "保存到: $output_path"
    
    # 尝试直接下载
    if $DOWNLOAD_CMD "$output_path" "$url"; then
        print_info "✓ $description 下载成功"
        return 0
    else
        print_error "✗ $description 下载失败"
        return 1
    fi
}

# 使用 Python 下载（备选方案）
python_download() {
    local url=$1
    local output_path=$2
    
    python3 << EOF
import urllib.request
import sys
import os

url = "$url"
output_path = "$output_path"

try:
    print(f"使用 Python 下载: {url}")
    
    # 创建请求，添加 User-Agent
    req = urllib.request.Request(url)
    req.add_header('User-Agent', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36')
    
    with urllib.request.urlopen(req) as response:
        total_size = int(response.headers.get('Content-Length', 0))
        downloaded = 0
        block_size = 8192
        
        with open(output_path, 'wb') as f:
            while True:
                buffer = response.read(block_size)
                if not buffer:
                    break
                    
                downloaded += len(buffer)
                f.write(buffer)
                
                if total_size > 0:
                    progress = downloaded / total_size * 100
                    print(f"\r进度: {progress:.1f}%", end='')
            
            print("\n下载完成")
            
except Exception as e:
    print(f"下载失败: {e}")
    sys.exit(1)
EOF
}

# 主下载函数
download_with_retry() {
    local url=$1
    local output_path=$2
    local description=$3
    local mirror_url=$4
    
    # 如果文件已存在，跳过
    if [ -f "$output_path" ]; then
        print_info "$description 已存在，跳过下载"
        return 0
    fi
    
    # 尝试主URL
    print_info "正在下载 $description..."
    if download_file "$url" "$output_path" "$description"; then
        return 0
    fi
    
    # 如果有镜像URL，尝试镜像
    if [ -n "$mirror_url" ]; then
        print_warning "主URL下载失败，尝试镜像源..."
        if download_file "$mirror_url" "$output_path" "$description"; then
            return 0
        fi
    fi
    
    # 尝试Python下载
    print_warning "尝试使用 Python 下载..."
    if python_download "$url" "$output_path"; then
        print_info "✓ 使用 Python 下载成功"
        return 0
    fi
    
    print_error "所有下载方式均失败"
    return 1
}

# 检查下载工具
if ! check_download_tools; then
    exit 1
fi

# GPT-SoVITS 模型定义
echo ""
print_info "开始下载 GPT-SoVITS 模型..."
echo ""

# GPT-SoVITS 模型列表
declare -A gpt_sovits_models=(
    ["s1bert25hz-5kh-longer-epoch=12-step=369668.ckpt"]="https://huggingface.co/lj1995/GPT-SoVITS/resolve/main/gsv-v2final-pretrained/s1bert25hz-5kh-longer-epoch=12-step=369668.ckpt"
    ["s2D2333k.pth"]="https://huggingface.co/lj1995/GPT-SoVITS/resolve/main/gsv-v2final-pretrained/s2D2333k.pth"
    ["s2G2333k.pth"]="https://huggingface.co/lj1995/GPT-SoVITS/resolve/main/gsv-v2final-pretrained/s2G2333k.pth"
)

# 下载 GPT-SoVITS 模型
cd "$GPT_SOVITS_MODEL_DIR"
for model_name in "${!gpt_sovits_models[@]}"; do
    url="${gpt_sovits_models[$model_name]}"
    download_with_retry "$url" "$model_name" "GPT-SoVITS: $model_name"
done

# MuseTalk 模型定义
echo ""
print_info "开始下载 MuseTalk 模型..."
echo ""

# MuseTalk 模型列表
declare -A musetalk_models=(
    ["sd-vae-ft-mse.ckpt"]="https://huggingface.co/stabilityai/sd-vae-ft-mse/resolve/main/sd-vae-ft-mse.ckpt"
    ["whisper_tiny.pt"]="https://huggingface.co/openai/whisper-tiny/resolve/main/pytorch_model.bin"
)

# 下载 MuseTalk 模型
cd "$MUSETALK_MODEL_DIR"
for model_name in "${!musetalk_models[@]}"; do
    url="${musetalk_models[$model_name]}"
    download_with_retry "$url" "$model_name" "MuseTalk: $model_name"
done

# 检查下载结果
echo ""
echo "================================================"
echo "              下载完成检查"
echo "================================================"
echo ""

# 检查 GPT-SoVITS 模型
print_info "GPT-SoVITS 模型："
cd "$GPT_SOVITS_MODEL_DIR"
for model_name in "${!gpt_sovits_models[@]}"; do
    if [ -f "$model_name" ]; then
        size=$(ls -lh "$model_name" | awk '{print $5}')
        print_info "  ✓ $model_name ($size)"
    else
        print_error "  ✗ $model_name 缺失"
    fi
done

# 检查 MuseTalk 模型
echo ""
print_info "MuseTalk 模型："
cd "$MUSETALK_MODEL_DIR"
for model_name in "${!musetalk_models[@]}"; do
    if [ -f "$model_name" ]; then
        size=$(ls -lh "$model_name" | awk '{print $5}')
        print_info "  ✓ $model_name ($size)"
    else
        print_error "  ✗ $model_name 缺失"
    fi
done

echo ""
echo "================================================"
echo "              下载完成"
echo "================================================"
echo ""

# 提供手动下载说明
cat << EOF
如果自动下载失败，您可以：

1. 手动下载模型文件：
   
   GPT-SoVITS 模型：
   - https://huggingface.co/lj1995/GPT-SoVITS/tree/main/gsv-v2final-pretrained
   
   MuseTalk 模型：
   - https://huggingface.co/stabilityai/sd-vae-ft-mse
   - https://huggingface.co/openai/whisper-tiny

2. 使用代理下载：
   export https_proxy=http://your-proxy:port
   ./download_models.sh

3. 使用 HuggingFace 镜像（如果可用）：
   将 huggingface.co 替换为镜像域名

4. 将下载好的文件放到对应目录：
   - GPT-SoVITS: $GPT_SOVITS_MODEL_DIR
   - MuseTalk: $MUSETALK_MODEL_DIR

EOF

print_info "提示：模型文件较大，请确保有足够的磁盘空间和稳定的网络连接"