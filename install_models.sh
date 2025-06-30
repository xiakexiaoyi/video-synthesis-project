#!/bin/bash

# AI 模型安装脚本 - 使用改进的下载方式

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
echo "          AI 模型安装向导"
echo "================================================"
echo ""

# 选择下载方式
echo "请选择模型下载方式："
echo ""
echo "1. 自动下载（需要稳定的网络连接）"
echo "2. 手动下载（提供下载链接和说明）"
echo "3. 使用已下载的模型（指定本地路径）"
echo ""
read -p "请选择 [1-3]: " choice

case $choice in
    1)
        print_info "开始自动下载模型..."
        ./download_models.sh
        ;;
    2)
        echo ""
        echo "================================================"
        echo "          手动下载说明"
        echo "================================================"
        echo ""
        echo "请手动下载以下模型文件："
        echo ""
        echo "【GPT-SoVITS 模型】"
        echo "下载地址: https://huggingface.co/lj1995/GPT-SoVITS/tree/main/gsv-v2final-pretrained"
        echo ""
        echo "需要下载的文件："
        echo "  1. s1bert25hz-5kh-longer-epoch=12-step=369668.ckpt"
        echo "  2. s2D2333k.pth"
        echo "  3. s2G2333k.pth"
        echo ""
        echo "保存到目录: $(pwd)/models/gpt-sovits/"
        echo ""
        echo "【MuseTalk 模型】"
        echo "需要下载的文件："
        echo "  1. sd-vae-ft-mse.ckpt"
        echo "     下载地址: https://huggingface.co/stabilityai/sd-vae-ft-mse"
        echo "  2. whisper_tiny.pt"
        echo "     下载地址: https://huggingface.co/openai/whisper-tiny"
        echo ""
        echo "保存到目录: $(pwd)/models/musetalk/"
        echo ""
        echo "================================================"
        echo ""
        echo "提示："
        echo "1. 可以使用浏览器、迅雷、IDM 等工具下载"
        echo "2. 如果 HuggingFace 无法访问，可以寻找国内镜像"
        echo "3. 下载完成后，将文件放到对应目录"
        echo "4. 然后重新运行 ./install.sh"
        echo ""
        read -p "按回车键继续..."
        ;;
    3)
        echo ""
        read -p "请输入模型文件所在的目录路径: " model_path
        
        if [ ! -d "$model_path" ]; then
            print_error "目录不存在: $model_path"
            exit 1
        fi
        
        print_info "复制模型文件..."
        
        # 创建目标目录
        mkdir -p models/gpt-sovits
        mkdir -p models/musetalk
        
        # 复制 GPT-SoVITS 模型
        for file in "s1bert25hz-5kh-longer-epoch=12-step=369668.ckpt" "s2D2333k.pth" "s2G2333k.pth"; do
            if [ -f "$model_path/$file" ]; then
                print_info "复制 $file..."
                cp "$model_path/$file" models/gpt-sovits/
            else
                print_warning "未找到 $file"
            fi
        done
        
        # 复制 MuseTalk 模型
        for file in "sd-vae-ft-mse.ckpt" "whisper_tiny.pt"; do
            if [ -f "$model_path/$file" ]; then
                print_info "复制 $file..."
                cp "$model_path/$file" models/musetalk/
            else
                print_warning "未找到 $file"
            fi
        done
        
        print_info "模型复制完成"
        ;;
    *)
        print_error "无效的选择"
        exit 1
        ;;
esac

# 检查模型是否完整
echo ""
print_info "检查模型文件..."

missing_models=0

# 检查 GPT-SoVITS
for file in "s1bert25hz-5kh-longer-epoch=12-step=369668.ckpt" "s2D2333k.pth" "s2G2333k.pth"; do
    if [ ! -f "models/gpt-sovits/$file" ]; then
        print_error "缺失: models/gpt-sovits/$file"
        missing_models=$((missing_models + 1))
    fi
done

# 检查 MuseTalk
for file in "sd-vae-ft-mse.ckpt" "whisper_tiny.pt"; do
    if [ ! -f "models/musetalk/$file" ]; then
        print_error "缺失: models/musetalk/$file"
        missing_models=$((missing_models + 1))
    fi
done

if [ $missing_models -gt 0 ]; then
    print_error "有 $missing_models 个模型文件缺失"
    echo ""
    echo "请选择："
    echo "1. 重新下载缺失的模型"
    echo "2. 稍后手动补充"
    echo ""
    read -p "请选择 [1-2]: " fix_choice
    
    if [ "$fix_choice" = "1" ]; then
        ./download_models.sh
    fi
else
    print_info "✓ 所有模型文件已就绪"
fi

echo ""
print_info "模型安装脚本执行完成"