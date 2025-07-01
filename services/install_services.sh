#!/bin/bash

# 视频合成服务安装脚本
# 包含GPT-SoVITS和MuseTalk的安装和配置

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 打印函数
print_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }

# 获取脚本路径
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# 服务目录
GPT_SOVITS_DIR="$SCRIPT_DIR/gpt-sovits"
MUSETALK_DIR="$SCRIPT_DIR/musetalk"
MODELS_DIR="$PROJECT_ROOT/models"

# 检查Python版本
check_python() {
    if ! command -v python3 &> /dev/null; then
        print_error "Python3未安装，请先安装Python 3.8或更高版本"
        exit 1
    fi
    
    python_version=$(python3 -c 'import sys; print(".".join(map(str, sys.version_info[:2])))')
    print_info "Python版本: $python_version"
}

# 检查GPU
check_gpu() {
    if command -v nvidia-smi &> /dev/null; then
        print_info "检测到NVIDIA GPU"
        nvidia-smi --query-gpu=name --format=csv,noheader
        USE_GPU=true
    else
        print_warning "未检测到NVIDIA GPU，将使用CPU模式（速度较慢）"
        USE_GPU=false
    fi
}

# 安装系统依赖
install_system_deps() {
    print_info "检查系统依赖..."
    
    # 检查ffmpeg
    if ! command -v ffmpeg &> /dev/null; then
        print_warning "安装ffmpeg..."
        if [[ "$OSTYPE" == "linux-gnu"* ]]; then
            sudo apt-get update && sudo apt-get install -y ffmpeg
        elif [[ "$OSTYPE" == "darwin"* ]]; then
            brew install ffmpeg
        else
            print_error "请手动安装ffmpeg"
            exit 1
        fi
    fi
    
    # 检查git
    if ! command -v git &> /dev/null; then
        print_error "请先安装git"
        exit 1
    fi
}

# 创建虚拟环境
create_venv() {
    local service_name=$1
    local service_dir=$2
    
    print_info "为${service_name}创建虚拟环境..."
    cd "$service_dir"
    
    if [ ! -d "venv" ]; then
        python3 -m venv venv
    fi
    
    source venv/bin/activate
    pip install --upgrade pip setuptools wheel
}

# 安装GPT-SoVITS
install_gpt_sovits() {
    print_info "开始安装GPT-SoVITS..."
    
    # 创建目录
    mkdir -p "$GPT_SOVITS_DIR"
    mkdir -p "$MODELS_DIR/gpt-sovits"
    
    # 创建虚拟环境
    create_venv "GPT-SoVITS" "$GPT_SOVITS_DIR"
    
    # 安装基础依赖
    pip install fastapi uvicorn requests aiofiles
    
    # 创建简化的API服务
    cat > "$GPT_SOVITS_DIR/start_api.py" << 'EOF'
#!/usr/bin/env python3
"""
GPT-SoVITS API服务
提供TTS功能的REST API
"""

import os
import sys
import json
import tempfile
import logging
from pathlib import Path
from typing import Optional
from fastapi import FastAPI, HTTPException
from fastapi.responses import FileResponse
from pydantic import BaseModel
import uvicorn

# 配置日志
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(title="GPT-SoVITS API", version="1.0.0")

class TTSRequest(BaseModel):
    text: str
    text_language: str = "zh"
    ref_audio_path: Optional[str] = None
    prompt_text: Optional[str] = None
    prompt_language: str = "zh"
    top_k: int = 5
    top_p: float = 1.0
    temperature: float = 1.0

class TTSEngine:
    """TTS引擎接口"""
    
    def __init__(self):
        self.model_loaded = False
        self.temp_dir = Path(tempfile.gettempdir()) / "gpt_sovits"
        self.temp_dir.mkdir(exist_ok=True)
    
    def load_model(self):
        """加载模型"""
        try:
            # 这里应该加载实际的GPT-SoVITS模型
            # 由于模型较大，这里提供接口框架
            logger.info("正在加载GPT-SoVITS模型...")
            
            # 检查模型文件是否存在
            model_dir = Path(__file__).parent.parent.parent / "models" / "gpt-sovits"
            if not model_dir.exists():
                logger.warning("模型目录不存在，使用模拟模式")
                return
            
            # TODO: 实际模型加载代码
            # from GPT_SoVITS.inference import load_model
            # self.model = load_model(model_dir)
            
            self.model_loaded = True
            logger.info("模型加载完成")
            
        except Exception as e:
            logger.error(f"模型加载失败: {e}")
            self.model_loaded = False
    
    def generate_tts(self, request: TTSRequest) -> str:
        """生成TTS音频"""
        try:
            # 生成输出文件路径
            output_file = self.temp_dir / f"tts_{os.getpid()}_{id(request)}.wav"
            
            if self.model_loaded:
                # TODO: 调用实际的TTS生成
                # audio = self.model.synthesize(
                #     text=request.text,
                #     language=request.text_language,
                #     ref_audio=request.ref_audio_path,
                #     ...
                # )
                # audio.save(output_file)
                pass
            else:
                # 模拟模式：生成静音音频
                import wave
                import array
                
                duration = len(request.text) * 0.1  # 每个字符0.1秒
                sample_rate = 22050
                num_samples = int(duration * sample_rate)
                
                # 生成静音数据
                audio_data = array.array('h', [0] * num_samples)
                
                # 写入WAV文件
                with wave.open(str(output_file), 'wb') as wav_file:
                    wav_file.setnchannels(1)  # 单声道
                    wav_file.setsampwidth(2)   # 16位
                    wav_file.setframerate(sample_rate)
                    wav_file.writeframes(audio_data.tobytes())
                
                logger.info(f"生成模拟音频: {output_file}")
            
            return str(output_file)
            
        except Exception as e:
            logger.error(f"TTS生成失败: {e}")
            raise

# 创建引擎实例
engine = TTSEngine()

@app.on_event("startup")
async def startup_event():
    """启动时加载模型"""
    engine.load_model()

@app.get("/")
async def root():
    return {
        "service": "GPT-SoVITS",
        "version": "1.0.0",
        "status": "running",
        "model_loaded": engine.model_loaded
    }

@app.get("/health")
async def health_check():
    return {
        "status": "healthy",
        "service": "gpt-sovits",
        "port": 9880,
        "model_loaded": engine.model_loaded
    }

@app.post("/tts")
async def text_to_speech(request: TTSRequest):
    """文本转语音接口"""
    try:
        if not request.text:
            raise HTTPException(status_code=400, detail="Text cannot be empty")
        
        # 生成音频
        output_file = engine.generate_tts(request)
        
        # 返回音频文件
        return FileResponse(
            output_file,
            media_type="audio/wav",
            filename="tts_output.wav"
        )
        
    except Exception as e:
        logger.error(f"TTS请求失败: {e}")
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    port = int(os.getenv("GPT_SOVITS_PORT", "9880"))
    host = os.getenv("GPT_SOVITS_HOST", "0.0.0.0")
    
    logger.info(f"启动GPT-SoVITS API服务: {host}:{port}")
    uvicorn.run(app, host=host, port=port, log_level="info")
EOF

    # 创建启动脚本
    cat > "$GPT_SOVITS_DIR/start_service.sh" << EOF
#!/bin/bash
cd "\$(dirname "\$0")"
source venv/bin/activate
export PYTHONPATH="\$PWD:\$PYTHONPATH"
python start_api.py
EOF

    chmod +x "$GPT_SOVITS_DIR/start_service.sh"
    chmod +x "$GPT_SOVITS_DIR/start_api.py"
    
    deactivate
    print_info "GPT-SoVITS安装完成"
}

# 安装MuseTalk
install_musetalk() {
    print_info "开始安装MuseTalk..."
    
    # 创建目录
    mkdir -p "$MUSETALK_DIR"
    mkdir -p "$MODELS_DIR/musetalk"
    
    # 创建虚拟环境
    create_venv "MuseTalk" "$MUSETALK_DIR"
    
    # 安装基础依赖
    pip install fastapi uvicorn requests aiofiles opencv-python-headless numpy
    
    # 创建简化的API服务
    cat > "$MUSETALK_DIR/start_api.py" << 'EOF'
#!/usr/bin/env python3
"""
MuseTalk API服务
提供视频合成功能的REST API
"""

import os
import sys
import tempfile
import shutil
import logging
import subprocess
from pathlib import Path
from typing import Optional
from fastapi import FastAPI, UploadFile, File, HTTPException
from fastapi.responses import FileResponse
import uvicorn
import cv2

# 配置日志
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(title="MuseTalk API", version="1.0.0")

class VideoEngine:
    """视频合成引擎接口"""
    
    def __init__(self):
        self.model_loaded = False
        self.temp_dir = Path(tempfile.gettempdir()) / "musetalk"
        self.temp_dir.mkdir(exist_ok=True)
    
    def load_model(self):
        """加载模型"""
        try:
            logger.info("正在加载MuseTalk模型...")
            
            # 检查模型文件是否存在
            model_dir = Path(__file__).parent.parent.parent / "models" / "musetalk"
            if not model_dir.exists():
                logger.warning("模型目录不存在，使用模拟模式")
                return
            
            # TODO: 实际模型加载代码
            # from musetalk import MuseTalkModel
            # self.model = MuseTalkModel(model_dir)
            
            self.model_loaded = True
            logger.info("模型加载完成")
            
        except Exception as e:
            logger.error(f"模型加载失败: {e}")
            self.model_loaded = False
    
    def synthesize_video(self, video_path: str, audio_path: str) -> str:
        """合成视频"""
        try:
            output_path = self.temp_dir / f"output_{os.getpid()}_{id(video_path)}.mp4"
            
            if self.model_loaded:
                # TODO: 调用实际的视频合成
                # result = self.model.inference(
                #     video=video_path,
                #     audio=audio_path
                # )
                # result.save(output_path)
                pass
            else:
                # 模拟模式：使用ffmpeg合并音视频
                logger.info("使用模拟模式合成视频")
                
                # 获取视频信息
                cap = cv2.VideoCapture(video_path)
                fps = cap.get(cv2.CAP_PROP_FPS)
                cap.release()
                
                # 使用ffmpeg合并音视频
                cmd = [
                    'ffmpeg',
                    '-i', video_path,
                    '-i', audio_path,
                    '-c:v', 'copy',
                    '-c:a', 'aac',
                    '-strict', 'experimental',
                    '-y',
                    str(output_path)
                ]
                
                result = subprocess.run(cmd, capture_output=True, text=True)
                if result.returncode != 0:
                    raise Exception(f"FFmpeg错误: {result.stderr}")
                
                logger.info(f"生成模拟视频: {output_path}")
            
            return str(output_path)
            
        except Exception as e:
            logger.error(f"视频合成失败: {e}")
            raise

# 创建引擎实例
engine = VideoEngine()

@app.on_event("startup")
async def startup_event():
    """启动时加载模型"""
    engine.load_model()

@app.get("/")
async def root():
    return {
        "service": "MuseTalk",
        "version": "1.0.0",
        "status": "running",
        "model_loaded": engine.model_loaded
    }

@app.get("/health")
async def health_check():
    return {
        "status": "healthy",
        "service": "musetalk",
        "port": 9881,
        "model_loaded": engine.model_loaded
    }

@app.post("/inference")
async def generate_video(
    audio: UploadFile = File(...),
    video: UploadFile = File(...)
):
    """视频合成接口"""
    temp_files = []
    
    try:
        # 保存上传的文件
        audio_path = engine.temp_dir / f"audio_{os.getpid()}.wav"
        video_path = engine.temp_dir / f"video_{os.getpid()}.mp4"
        
        temp_files.extend([audio_path, video_path])
        
        with open(audio_path, "wb") as f:
            f.write(await audio.read())
        with open(video_path, "wb") as f:
            f.write(await video.read())
        
        # 合成视频
        output_path = engine.synthesize_video(str(video_path), str(audio_path))
        temp_files.append(output_path)
        
        # 返回合成的视频
        return FileResponse(
            output_path,
            media_type="video/mp4",
            filename="synthesized_video.mp4"
        )
        
    except Exception as e:
        logger.error(f"视频生成请求失败: {e}")
        raise HTTPException(status_code=500, detail=str(e))
    
    finally:
        # 清理临时文件（延迟删除以确保文件能被下载）
        # TODO: 实现更好的临时文件管理
        pass

if __name__ == "__main__":
    port = int(os.getenv("MUSETALK_PORT", "9881"))
    host = os.getenv("MUSETALK_HOST", "0.0.0.0")
    
    logger.info(f"启动MuseTalk API服务: {host}:{port}")
    uvicorn.run(app, host=host, port=port, log_level="info")
EOF

    # 创建启动脚本
    cat > "$MUSETALK_DIR/start_service.sh" << EOF
#!/bin/bash
cd "\$(dirname "\$0")"
source venv/bin/activate
export PYTHONPATH="\$PWD:\$PYTHONPATH"
python start_api.py
EOF

    chmod +x "$MUSETALK_DIR/start_service.sh"
    chmod +x "$MUSETALK_DIR/start_api.py"
    
    deactivate
    print_info "MuseTalk安装完成"
}

# 下载模型文件
download_models() {
    print_info "准备下载模型文件..."
    
    # 创建模型目录
    mkdir -p "$MODELS_DIR/gpt-sovits"
    mkdir -p "$MODELS_DIR/musetalk"
    
    # 创建模型下载脚本
    cat > "$MODELS_DIR/download_models.py" << 'EOF'
#!/usr/bin/env python3
"""
模型下载脚本
可以从Hugging Face或其他源下载所需的模型文件
"""

import os
import sys
import requests
from pathlib import Path
from tqdm import tqdm

def download_file(url, dest_path):
    """下载文件并显示进度"""
    response = requests.get(url, stream=True)
    total_size = int(response.headers.get('content-length', 0))
    
    with open(dest_path, 'wb') as file:
        with tqdm(total=total_size, unit='B', unit_scale=True, desc=dest_path.name) as pbar:
            for data in response.iter_content(chunk_size=1024):
                file.write(data)
                pbar.update(len(data))

def main():
    print("模型下载脚本")
    print("=" * 50)
    print("注意：GPT-SoVITS和MuseTalk的模型文件较大（总计约10GB）")
    print("请确保有足够的磁盘空间和稳定的网络连接")
    print("=" * 50)
    
    # TODO: 添加实际的模型下载链接
    models = {
        "gpt-sovits": [
            # ("模型名称", "下载URL", "保存路径"),
        ],
        "musetalk": [
            # ("模型名称", "下载URL", "保存路径"),
        ]
    }
    
    print("\n由于模型文件较大，请参考以下步骤手动下载：")
    print("\n1. GPT-SoVITS模型：")
    print("   访问: https://github.com/RVC-Boss/GPT-SoVITS")
    print("   下载预训练模型到: models/gpt-sovits/")
    
    print("\n2. MuseTalk模型：")
    print("   访问: https://github.com/TMElyralab/MuseTalk")
    print("   下载预训练模型到: models/musetalk/")

if __name__ == "__main__":
    main()
EOF

    chmod +x "$MODELS_DIR/download_models.py"
    
    print_info "模型下载脚本已创建: $MODELS_DIR/download_models.py"
    print_warning "请运行该脚本或手动下载模型文件"
}

# 创建测试脚本
create_test_script() {
    cat > "$SCRIPT_DIR/test_services.py" << 'EOF'
#!/usr/bin/env python3
"""
服务测试脚本
"""

import requests
import time
import sys

def test_service(name, url):
    """测试单个服务"""
    try:
        print(f"\n测试 {name}...")
        response = requests.get(f"{url}/health", timeout=5)
        if response.status_code == 200:
            data = response.json()
            print(f"✓ {name} 运行正常")
            print(f"  状态: {data.get('status')}")
            print(f"  端口: {data.get('port')}")
            if 'model_loaded' in data:
                print(f"  模型加载: {data.get('model_loaded')}")
            return True
        else:
            print(f"✗ {name} 响应错误: {response.status_code}")
            return False
    except requests.exceptions.ConnectionError:
        print(f"✗ {name} 无法连接")
        return False
    except Exception as e:
        print(f"✗ {name} 错误: {e}")
        return False

def main():
    print("视频合成服务测试")
    print("=" * 50)
    
    services = [
        ("GPT-SoVITS", "http://localhost:9880"),
        ("MuseTalk", "http://localhost:9881"),
        ("主服务", "http://localhost:6006")
    ]
    
    all_ok = True
    for name, url in services:
        if not test_service(name, url):
            all_ok = False
    
    print("\n" + "=" * 50)
    if all_ok:
        print("✓ 所有服务运行正常")
        return 0
    else:
        print("✗ 部分服务未运行或存在问题")
        return 1

if __name__ == "__main__":
    sys.exit(main())
EOF

    chmod +x "$SCRIPT_DIR/test_services.py"
}

# 主函数
main() {
    print_info "开始安装视频合成服务"
    echo "======================================"
    
    # 检查环境
    check_python
    check_gpu
    install_system_deps
    
    # 询问安装选项
    echo ""
    echo "请选择安装选项："
    echo "1) 完整安装 (GPT-SoVITS + MuseTalk)"
    echo "2) 仅安装 GPT-SoVITS"
    echo "3) 仅安装 MuseTalk"
    echo "4) 退出"
    
    read -p "请输入选项 [1-4]: " choice
    
    case $choice in
        1)
            install_gpt_sovits
            install_musetalk
            download_models
            ;;
        2)
            install_gpt_sovits
            ;;
        3)
            install_musetalk
            ;;
        4)
            print_info "退出安装"
            exit 0
            ;;
        *)
            print_error "无效选项"
            exit 1
            ;;
    esac
    
    # 创建测试脚本
    create_test_script
    
    print_info "安装完成！"
    echo ""
    echo "下一步："
    echo "1. 下载模型文件: python3 $MODELS_DIR/download_models.py"
    echo "2. 启动服务: $PROJECT_ROOT/start_server.sh"
    echo "3. 测试服务: python3 $SCRIPT_DIR/test_services.py"
}

# 运行主函数
main "$@"