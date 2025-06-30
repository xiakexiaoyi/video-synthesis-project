#!/bin/bash

# 颜色定义
GREEN='\033[0;32m'
NC='\033[0m'

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

echo "======================================"
echo "视频合成项目一键安装脚本"
echo "======================================"

# 检查系统
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    echo "检测到Linux系统"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    echo "检测到macOS系统"
elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
    echo "检测到Windows系统"
    echo "建议在WSL2中运行此脚本"
fi

# 检查Python
echo -e "\n检查Python环境..."
if ! command -v python3 &> /dev/null; then
    echo "错误: 未找到Python3"
    echo "请先安装Python 3.8或更高版本"
    echo "访问 https://www.python.org/downloads/ 下载安装"
    exit 1
fi

python_version=$(python3 -c 'import sys; print(".".join(map(str, sys.version_info[:2])))')
echo "Python版本: $python_version"

# 检查pip
if ! command -v pip3 &> /dev/null; then
    echo "安装pip..."
    python3 -m ensurepip --default-pip
fi

# 检查Git
echo -e "\n检查Git..."
if ! command -v git &> /dev/null; then
    echo "错误: 未找到Git"
    echo "请先安装Git"
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "运行: sudo apt-get install git"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "运行: brew install git"
    fi
    exit 1
fi

# 检查FFmpeg
echo -e "\n检查FFmpeg..."
if ! command -v ffmpeg &> /dev/null; then
    echo "警告: 未找到FFmpeg，尝试安装..."
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        sudo apt-get update && sudo apt-get install -y ffmpeg
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        if command -v brew &> /dev/null; then
            brew install ffmpeg
        else
            echo "请先安装Homebrew，然后运行: brew install ffmpeg"
        fi
    else
        echo "请手动安装FFmpeg: https://ffmpeg.org/download.html"
    fi
fi

# 检查CUDA（可选）
echo -e "\n检查CUDA..."
if command -v nvidia-smi &> /dev/null; then
    echo "检测到NVIDIA GPU"
    nvidia-smi --query-gpu=name,driver_version --format=csv,noheader
    echo "将安装CUDA版本的PyTorch"
    PYTORCH_CUDA="1"
else
    echo "未检测到NVIDIA GPU，将安装CPU版本的PyTorch"
    PYTORCH_CUDA="0"
fi

# 设置安装选项
echo -e "\n=== 安装选项 ==="
echo "1. 完整安装（GPT-SoVITS + MuseTalk + 主程序）"
echo "2. 仅安装主程序（需要已有GPT-SoVITS和MuseTalk服务）"
echo "3. 仅安装GPT-SoVITS"
echo "4. 仅安装MuseTalk"
read -p "请选择安装选项 [1-4]: " install_option

# 创建服务管理脚本
cat > services/start_all.sh << 'EOF'
#!/bin/bash
echo "启动所有服务..."

# 启动GPT-SoVITS
if [ -f "gpt-sovits/start_service.sh" ]; then
    echo "启动GPT-SoVITS..."
    nohup ./gpt-sovits/start_service.sh > ../logs/gpt-sovits.log 2>&1 &
    echo $! > ../logs/gpt-sovits.pid
fi

# 启动MuseTalk
if [ -f "musetalk/start_service.sh" ]; then
    echo "启动MuseTalk..."
    nohup ./musetalk/start_service.sh > ../logs/musetalk.log 2>&1 &
    echo $! > ../logs/musetalk.pid
fi

# 等待服务启动
sleep 10

# 启动主服务
echo "启动主服务..."
cd ../server
nohup python main.py > ../logs/main.log 2>&1 &
echo $! > ../logs/main.pid

echo "所有服务已启动"
echo "查看日志: tail -f logs/*.log"
EOF

cat > services/stop_all.sh << 'EOF'
#!/bin/bash
echo "停止所有服务..."

# 停止主服务
if [ -f "../logs/main.pid" ]; then
    kill $(cat ../logs/main.pid) 2>/dev/null
    rm ../logs/main.pid
fi

# 停止GPT-SoVITS
if [ -f "../logs/gpt-sovits.pid" ]; then
    kill $(cat ../logs/gpt-sovits.pid) 2>/dev/null
    rm ../logs/gpt-sovits.pid
fi

# 停止MuseTalk  
if [ -f "../logs/musetalk.pid" ]; then
    kill $(cat ../logs/musetalk.pid) 2>/dev/null
    rm ../logs/musetalk.pid
fi

echo "所有服务已停止"
EOF

chmod +x services/start_all.sh services/stop_all.sh

# 创建日志目录
mkdir -p logs

# 执行安装
case $install_option in
    1)
        echo -e "\n开始完整安装..."
        
        # 先下载模型
        echo -e "\n[1/4] 下载AI模型..."
        chmod +x download_models_mirror.sh
        print_info "使用 HF-Mirror 镜像站下载模型..."
        ./download_models_mirror.sh
        
        # 安装GPT-SoVITS
        echo -e "\n[2/4] 安装GPT-SoVITS..."
        chmod +x services/gpt_sovits_setup.sh
        ./services/gpt_sovits_setup.sh
        
        # 安装MuseTalk
        echo -e "\n[3/4] 安装MuseTalk..."
        chmod +x services/musetalk_setup.sh
        ./services/musetalk_setup.sh
        
        # 安装主程序
        echo -e "\n[4/4] 安装主程序..."
        cd server
        pip3 install -r requirements.txt
        cd ../client
        pip3 install -r requirements.txt
        cd ..
        ;;
        
    2)
        echo -e "\n安装主程序..."
        cd server
        pip3 install -r requirements.txt
        cd ../client
        pip3 install -r requirements.txt
        cd ..
        ;;
        
    3)
        echo -e "\n安装GPT-SoVITS..."
        chmod +x services/gpt_sovits_setup.sh
        ./services/gpt_sovits_setup.sh
        ;;
        
    4)
        echo -e "\n安装MuseTalk..."
        chmod +x services/musetalk_setup.sh
        ./services/musetalk_setup.sh
        ;;
        
    *)
        echo "无效的选项"
        exit 1
        ;;
esac

echo -e "\n======================================"
echo "安装完成！"
echo "======================================"
echo ""
echo "使用说明："
echo "1. 启动所有服务: ./services/start_all.sh"
echo "2. 启动客户端: ./start_client.sh"
echo "3. 停止所有服务: ./services/stop_all.sh"
echo ""
echo "单独启动服务："
echo "- GPT-SoVITS: ./services/gpt-sovits/start_service.sh"
echo "- MuseTalk: ./services/musetalk/start_service.sh"
echo "- 主服务: ./start_server.sh"
echo ""
echo "提示："
echo "- 首次运行可能需要下载模型文件，请耐心等待"
echo "- 查看日志: tail -f logs/*.log"
echo "- 默认端口: GPT-SoVITS(9880), MuseTalk(9881), 主服务(6006)"

echo ""
echo "如果模型下载失败："
echo "1. 运行 ./install_models.sh 选择其他下载方式"
echo "2. 使用 aria2 加速: ./download_aria2_mirror.sh"
echo "3. 或手动下载模型文件到 models/ 目录"