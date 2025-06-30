#!/bin/bash

# 简化版模型下载脚本

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

# 创建目录
mkdir -p models/gpt-sovits
mkdir -p models/musetalk

echo ""
echo "================================================"
echo "          AI 模型下载工具（简化版）"
echo "================================================"
echo ""

# 使用 Python 下载文件
download_with_python() {
    local url=$1
    local output_file=$2
    local description=$3
    
    if [ -f "$output_file" ]; then
        print_info "$description 已存在，跳过下载"
        return 0
    fi
    
    print_info "下载 $description..."
    
    python3 << EOF
import urllib.request
import sys
import os
import time

url = "$url"
output_file = "$output_file"
description = "$description"

def download_with_progress(url, output_file):
    try:
        # 创建请求
        req = urllib.request.Request(url)
        req.add_header('User-Agent', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36')
        
        print(f"连接到: {url}")
        
        with urllib.request.urlopen(req, timeout=30) as response:
            total_size = int(response.headers.get('Content-Length', 0))
            downloaded = 0
            block_size = 8192
            
            print(f"文件大小: {total_size / 1024 / 1024:.2f} MB")
            
            with open(output_file, 'wb') as f:
                start_time = time.time()
                while True:
                    buffer = response.read(block_size)
                    if not buffer:
                        break
                    
                    downloaded += len(buffer)
                    f.write(buffer)
                    
                    # 显示进度
                    if total_size > 0:
                        progress = downloaded / total_size * 100
                        speed = downloaded / (time.time() - start_time) / 1024 / 1024
                        print(f"\r进度: {progress:.1f}% - {downloaded/1024/1024:.1f}/{total_size/1024/1024:.1f} MB - 速度: {speed:.1f} MB/s", end='', flush=True)
            
            print("\n下载完成！")
            return True
            
    except Exception as e:
        print(f"\n下载失败: {e}")
        if os.path.exists(output_file):
            os.remove(output_file)
        return False

# 执行下载
success = download_with_progress(url, output_file)
sys.exit(0 if success else 1)
EOF
    
    if [ $? -eq 0 ]; then
        print_info "✓ $description 下载成功"
        return 0
    else
        print_error "✗ $description 下载失败"
        return 1
    fi
}

# 下载 GPT-SoVITS 模型
print_info "开始下载 GPT-SoVITS 模型..."
cd models/gpt-sovits

download_with_python \
    "https://huggingface.co/lj1995/GPT-SoVITS/resolve/main/gsv-v2final-pretrained/s1bert25hz-5kh-longer-epoch=12-step=369668.ckpt" \
    "s1bert25hz-5kh-longer-epoch=12-step=369668.ckpt" \
    "GPT-SoVITS 主模型"

download_with_python \
    "https://huggingface.co/lj1995/GPT-SoVITS/resolve/main/gsv-v2final-pretrained/s2D2333k.pth" \
    "s2D2333k.pth" \
    "GPT-SoVITS s2D 模型"

download_with_python \
    "https://huggingface.co/lj1995/GPT-SoVITS/resolve/main/gsv-v2final-pretrained/s2G2333k.pth" \
    "s2G2333k.pth" \
    "GPT-SoVITS s2G 模型"

cd ../..

# 下载 MuseTalk 模型
print_info "MuseTalk 模型较复杂，请使用专用脚本下载："
print_info "运行: ./download_musetalk_models.sh"

# 检查结果
echo ""
echo "================================================"
echo "              下载完成检查"
echo "================================================"
echo ""

# 列出已下载的文件
print_info "已下载的文件："
echo ""
echo "GPT-SoVITS 模型："
ls -lh models/gpt-sovits/ | grep -E "\.(ckpt|pth)$" || echo "  无文件"
echo ""
echo "MuseTalk 模型："
ls -lh models/musetalk/ | grep -E "\.(ckpt|pt)$" || echo "  无文件"

echo ""
echo "================================================"
echo "              下载完成"
echo "================================================"
echo ""

# 如果下载失败的备选方案
cat << 'EOF'
如果自动下载失败，请尝试以下方法：

1. 使用代理：
   export https_proxy=http://your-proxy:port
   export http_proxy=http://your-proxy:port
   ./download_models_simple.sh

2. 使用 aria2 下载（速度更快）：
   aria2c -x 16 -s 16 -k 1M -o models/gpt-sovits/s2G2333k.pth \
     "https://huggingface.co/lj1995/GPT-SoVITS/resolve/main/gsv-v2final-pretrained/s2G2333k.pth"

3. 手动下载：
   - 在浏览器中打开上述 URL
   - 使用下载工具（如 IDM、迅雷）
   - 将文件保存到对应的 models/ 子目录

4. 使用镜像站（如果有）：
   - 搜索 HuggingFace 镜像站
   - 替换 URL 中的域名

EOF